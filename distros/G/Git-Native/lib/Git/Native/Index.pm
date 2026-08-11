# ABSTRACT: A libgit2 index (the staging area), read-only

package Git::Native::Index;
use Moo;
use Carp ();
use Git::Libgit2 qw( GIT_ENOTFOUND );
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );

# The argument guards below croak rather than throwing a Git::Native::Error -
# they never reach libgit2, so there is no ->code to report (same rule as
# Git::Native::Oid->from_hex and Repository->object_by_prefix). @CARP_NOT keeps
# the blame on the caller's line if the argument arrived through another
# wrapper instead of directly.
our @CARP_NOT = qw( Git::Native::Repository );

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );   # Repository

sub entrycount { Git::Libgit2::FFI::git_index_entrycount( $_[0]->_handle ) }

# find($path): the 0-based position of the exact path, or undef when the index
# has no such entry. Only GIT_ENOTFOUND maps to undef; every other negative rc
# throws via check_rc, so a broken index is never reported as "untracked".
sub find {
  my ( $self, $path ) = @_;
  _need_arg( 'find', 'path', $path );
  my $rc = Git::Libgit2::FFI::git_index_find( \my $pos, $self->_handle, $path );
  return undef if $rc == GIT_ENOTFOUND;
  check_rc $rc;
  return $pos;
}

# find_prefix($prefix): position of the first entry whose path STARTS WITH
# $prefix - a raw string prefix, no path semantics ('tasks' matches
# 'tasksfoo.txt'). undef when nothing matches. For the directory question use
# is_tracked_under.
sub find_prefix {
  my ( $self, $prefix ) = @_;
  _need_arg( 'find_prefix', 'prefix', $prefix );
  my $rc = Git::Libgit2::FFI::git_index_find_prefix( \my $pos, $self->_handle, $prefix );
  return undef if $rc == GIT_ENOTFOUND;
  check_rc $rc;
  return $pos;
}

sub has_path {
  my ( $self, $path ) = @_;
  _need_arg( 'has_path', 'path', $path );
  return defined $self->find($path) ? 1 : 0;
}

sub has_prefix {
  my ( $self, $prefix ) = @_;
  _need_arg( 'has_prefix', 'prefix', $prefix );
  return defined $self->find_prefix($prefix) ? 1 : 0;
}

# is_tracked_under($path): the `git ls-files -- $path` question - is this exact
# path tracked, or is anything tracked below it as a directory?
#
# Not has_prefix: a string prefix answers yes for 'tasks' against
# 'tasksfoo.txt'. Appending the separator makes the directory case a path
# question again, and the exact-path check keeps a tracked file answering for
# itself.
sub is_tracked_under {
  my ( $self, $path ) = @_;
  _need_arg( 'is_tracked_under', 'path', $path );
  ( my $dir = $path ) =~ s{/+\z}{};
  Carp::croak
    "Git::Native::Index->is_tracked_under requires a non-empty path, got '$path'"
    unless length $dir;
  return 1 if $self->has_path($dir);
  return $self->has_prefix("$dir/");
}

# reload(force => 0): re-read the index file from disk. force = 0 re-reads only
# when the file changed (libgit2 compares stat data), force = 1 unconditionally.
sub reload {
  my ( $self, %args ) = @_;
  check_rc Git::Libgit2::FFI::git_index_read( $self->_handle, $args{force} ? 1 : 0 );
  return $self;
}

# An empty path or prefix would match entry 0 rather than nothing, so it is
# rejected instead of silently answering yes.
sub _need_arg {
  my ( $method, $name, $value ) = @_;
  return if defined $value && length $value;
  Carp::croak sprintf 'Git::Native::Index->%s requires a non-empty %s, got %s',
    $method, $name, ( defined $value ? "''" : 'undef' );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_index_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Index - A libgit2 index (the staging area), read-only

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $index = $repo->index;

  if ( $index->is_tracked_under('tasks') ) { ... }   # the path question
  if ( $index->has_path('tasks/1.md') )    { ... }   # one exact entry
  say $index->entrycount;

=head1 DESCRIPTION

The repository's index — git's staging area, the list of tracked paths.
Wraps C<git_index*>; freed automatically.

Read-only on purpose. The questions this answers are "does the index know
this path" and "is anything tracked under this directory"; there is no
C<add> / C<remove> / C<write>, so nothing here can stage or unstage
anything.

Get one from L<Git::Native::Repository/index>, which re-reads the index
file before handing it over. What you hold afterwards carries no freshness
guarantee in either direction: it does not refresh itself, and it is not a
frozen snapshot of the moment you took it either. libgit2 keeps one
C<git_index*> per repository and hands that same one to every caller, so
any other C<< $repo->index >> in the process re-reads the file underneath
it. Call L</reload> when you want the current state; there is no way to
pin a past one.

Paths are index paths: relative to the working directory root, with C</>
separators and no leading C<./>, exactly as C<git ls-files> prints them.

=head2 entrycount

  say $index->entrycount;

Number of entries in the index, i.e. how many paths git currently tracks.

=head2 find

  my $pos = $index->find('lib/Git/Native.pm');

The 0-based position of the entry for exactly C<$path>, or C<undef> when the
index has no such entry. Positions are into libgit2's sorted entry list and
change whenever the index does — useful to tell "found at 0" from "not
found", not as a durable handle. Croaks on an undefined or empty path.

Only "not found" comes back C<undef>; any other libgit2 failure throws a
L<Git::Native::Error>, so an unreadable index is never mistaken for an
untracked path.

=head2 find_prefix

  my $pos = $index->find_prefix('tasks');

The 0-based position of the first entry whose path B<starts with the string>
C<$prefix>, or C<undef> when none does.

This is a raw string prefix with B<no path semantics>: C<'tasks'> matches
C<'tasks/1.md'> and equally matches C<'tasksfoo.txt'>, because both begin
with those five characters. For "is anything tracked under the directory
C<tasks>" use L</is_tracked_under>, which is the path-aware question.
Croaks on an undefined or empty prefix — an empty prefix matches the first
entry of any non-empty index, which is never the question being asked.

=head2 has_path

  if ( $index->has_path('README.md') ) { ... }

1 or 0: is exactly C<$path> tracked? The boolean form of L</find>, and the
equivalent of C<git ls-files --error-unmatch $path> succeeding.

=head2 has_prefix

  $index->has_prefix('tasks');    # true for 'tasksfoo.txt' too

1 or 0 for L</find_prefix> — again a B<string> prefix, not a path. Reach for
L</is_tracked_under> unless you specifically want string matching.

=head2 is_tracked_under

  if ( $index->is_tracked_under('tasks') ) { ... }

1 or 0: is anything tracked at or below C<$path>? The same question
C<git ls-files -- $path> answers, for a file and a directory alike.

A trailing slash on C<$path> is ignored, then the answer is true when
C<$path> is itself a tracked file, or when any tracked path begins with
C<$path/>. So C<'tasks'> is true for a repository tracking C<tasks/1.md>,
and false for one tracking only C<tasksfoo.txt> — the trap
L</has_prefix> walks into. Croaks on an undefined or empty path, and on a
path that is nothing but slashes.

=head2 reload

  $index->reload;
  $index->reload( force => 1 );

Re-read the index file from disk and return the index. By default libgit2
re-reads only if the file actually changed; C<force =E<gt> 1> re-reads
unconditionally. This is how a long-lived Index picks up work another
process committed or staged in the meantime.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Tree>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
