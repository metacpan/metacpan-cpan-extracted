# ABSTRACT: Walk commits in topological / time order

package Git::Native::Revwalker;
use Moo;
use Carp ();
use Git::Libgit2 qw(
  GIT_ITEROVER
  GIT_SORT_NONE GIT_SORT_TOPOLOGICAL GIT_SORT_TIME GIT_SORT_REVERSE
);
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use Git::Native::Oid ();

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );

sub push_oid {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_revwalk_push( $self->_handle, $oid->ptr );
  return $self;
}

sub push_head { check_rc Git::Libgit2::FFI::git_revwalk_push_head( $_[0]->_handle ); $_[0] }
sub push_ref  { check_rc Git::Libgit2::FFI::git_revwalk_push_ref(  $_[0]->_handle, $_[1] ); $_[0] }
sub push_glob { check_rc Git::Libgit2::FFI::git_revwalk_push_glob( $_[0]->_handle, $_[1] ); $_[0] }
sub push_range { check_rc Git::Libgit2::FFI::git_revwalk_push_range( $_[0]->_handle, $_[1] ); $_[0] }

sub hide_oid {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_revwalk_hide( $self->_handle, $oid->ptr );
  return $self;
}

sub hide_head { check_rc Git::Libgit2::FFI::git_revwalk_hide_head( $_[0]->_handle ); $_[0] }
sub hide_ref  { check_rc Git::Libgit2::FFI::git_revwalk_hide_ref(  $_[0]->_handle, $_[1] ); $_[0] }
sub hide_glob { check_rc Git::Libgit2::FFI::git_revwalk_hide_glob( $_[0]->_handle, $_[1] ); $_[0] }

sub sorting {
  my ( $self, $mode ) = @_;
  check_rc Git::Libgit2::FFI::git_revwalk_sorting( $self->_handle, $mode );
  return $self;
}

sub reset { check_rc Git::Libgit2::FFI::git_revwalk_reset( $_[0]->_handle ); $_[0] }
sub simplify_first_parent {
  check_rc Git::Libgit2::FFI::git_revwalk_simplify_first_parent( $_[0]->_handle );
  $_[0];
}

sub next {
  my $self = shift;
  my $raw = "\0" x 20;
  my ($p) = scalar_to_buffer($raw);
  my $rc  = Git::Libgit2::FFI::git_revwalk_next( $p, $self->_handle );
  return undef if $rc == GIT_ITEROVER;
  check_rc $rc;
  return Git::Native::Oid->from_raw($raw);
}

sub all {
  my $self = shift;
  my @out;
  while ( defined( my $o = $self->next ) ) { push @out, $o }
  return \@out;
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_revwalk_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Revwalker - Walk commits in topological / time order

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $walker = $repo->revwalker;
  $walker->push_head;
  $walker->sorting( Git::Native::Revwalker::GIT_SORT_TIME );
  while ( my $oid = $walker->next ) {
    say $oid->hex;
  }

=head1 DESCRIPTION

Wraps libgit2's C<git_revwalk*>. Push starting points (commits, refs,
globs), optionally hide commits to exclude, then iterate with C<next>.

B<Seeding is mandatory.> A walker that has had no C<push_*> call has no
starting point and therefore yields nothing at all: C<next> returns
C<undef> straight away and C<all> gives an empty arrayref. There is no
implicit "walk HEAD" — say C<< $walker->push_head >> for that.

The walk goes from the pushed commits towards their ancestors, so a child
always comes out before its parents. Every C<push_*> and C<hide_*> returns
the walker, so seeding chains.

A walker keeps its repository alive for as long as it is in scope.

=head2 push_oid

  $walker->push_oid($oid);
  $walker->push_oid('35104eb6815e52f24b06c95cbc53e95943cb532b');

Add a commit as a starting point. C<$oid> is a L<Git::Native::Oid> or a
40-character hex string, and must resolve to something committish — a blob
OID throws a L<Git::Native::Error> ("object is not a committish").

=head2 push_head

  $walker->push_head;

Start from whatever HEAD resolves to.

=head2 push_ref

  $walker->push_ref('refs/heads/topic');

Start from the commit a reference points at. Throws if the ref does not
exist.

=head2 push_glob

  $walker->push_glob('refs/heads/*');

Start from every reference matching the pattern at once — the union of all
those histories.

=head2 push_range

  $walker->push_range("$old..$new");

Push C<B> and hide C<A> for a range written C<"A..B">, the same spelling
C<git log> takes.

=head2 hide_oid / hide_head / hide_ref / hide_glob

  $walker->push_head->hide_ref('refs/heads/main');

Exclude a commit B<and all of its ancestors> from the walk — what makes
"on this branch but not on main" expressible. Same argument forms as the
matching C<push_*>.

=head2 sorting

  $walker->sorting(
    Git::Native::Revwalker::GIT_SORT_TIME | Git::Native::Revwalker::GIT_SORT_REVERSE
  );

Set the ordering: a bitfield of C<GIT_SORT_NONE> (libgit2's default walk
order), C<GIT_SORT_TOPOLOGICAL>, C<GIT_SORT_TIME> and C<GIT_SORT_REVERSE>,
which are constants in this package and not exported.

Set it B<before the first C<next>>: changing the sorting mode of a walk
already in progress resets the walker, which drops the pushed starting
points along with it and leaves you iterating nothing.

=head2 reset

  $walker->reset->push_ref('refs/heads/other');

Return the walker to its just-created state so it can be used for a
different walk. This clears the pushed and hidden commits as well as the
sorting mode — re-seed before iterating again, or the walk is empty.

=head2 simplify_first_parent

  $walker->push_head->simplify_first_parent;

Follow only the first parent of each commit, so a merge does not pull the
merged-in side branch into the walk. Applies to the walking still to come.

=head2 next

  while ( defined( my $oid = $walker->next ) ) { ... }

The next L<Git::Native::Oid>, or C<undef> once the walk is exhausted —
libgit2's C<GIT_ITEROVER> is the normal end of iteration and is
B<not> raised as an error. Real failures still throw a
L<Git::Native::Error>.

=head2 all

  my $oids = $walker->all;

Drain the walker from where it stands into an arrayref of
L<Git::Native::Oid>. It consumes the same iterator C<next> does, so a
second C<all> without a C<reset> and fresh C<push_*> comes back empty.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Commit>, L<Git::Native::Oid>

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
