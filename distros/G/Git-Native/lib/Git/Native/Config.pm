# ABSTRACT: A libgit2 configuration handle

package Git::Native::Config;
use Moo;
use Git::Libgit2::FFI ();
use Git::Libgit2 qw( GIT_ENOTFOUND );
use Git::Native::Error qw( check_rc );

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro' );   # Repository (when repo-derived) - keeps it alive

# get_string($key): the value, or undef when the key is unset. Only
# GIT_ENOTFOUND maps to undef; any other libgit2 failure throws via check_rc
# (matching get_bool) - we don't silently swallow real errors as "unset".
# libgit2 only guarantees git_config_get_string on a *snapshot* config;
# use Repository->config_snapshot / config_string for reads.
sub get_string {
  my ( $self, $key ) = @_;
  my $rc = Git::Libgit2::FFI::git_config_get_string( \my $out, $self->_handle, $key );
  return undef if $rc == GIT_ENOTFOUND;   # unset
  check_rc $rc;
  return $out;
}

# get_bool($key): 1 / 0 for a git-style boolean, or undef when the key is
# unset. libgit2 does the parsing via git_config_get_bool (true/yes/on/1,
# false/no/off/0, integers by non-zero) - we don't reimplement git's bool
# rules in Perl. A present-but-non-boolean value (e.g. "banana") makes
# libgit2 return an error, which check_rc turns into a Git::Native::Error;
# only GIT_ENOTFOUND maps to undef.
sub get_bool {
  my ( $self, $key ) = @_;
  my $rc = Git::Libgit2::FFI::git_config_get_bool( \my $out, $self->_handle, $key );
  return undef if $rc == GIT_ENOTFOUND;   # unset
  check_rc $rc;                           # other negatives (e.g. non-boolean) throw
  return $out ? 1 : 0;
}

# set_string($key, $value): only valid on a live (non-snapshot) config.
sub set_string {
  my ( $self, $key, $value ) = @_;
  check_rc Git::Libgit2::FFI::git_config_set_string( $self->_handle, $key, $value );
  return $self;
}

# snapshot(): a read-only point-in-time copy. Returns a fresh Config.
sub snapshot {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_config_snapshot( \my $snap, $self->_handle );
  return Git::Native::Config->new( _handle => $snap, _owner => $self->_owner );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_config_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Config - A libgit2 configuration handle

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $cfg = $repo->config;                  # live, writable
  $cfg->set_string('user.name', 'Ada');

  say $repo->config_string('user.name');    # 'Ada' (fresh snapshot read)

  my $snap = $repo->config_snapshot;
  say $snap->get_string('user.email');

=head1 DESCRIPTION

A libgit2 configuration handle. Wraps C<git_config*>; freed
automatically when the object goes out of scope.

Reads go through C<get_string>, which libgit2 only supports reliably on a
B<snapshot> config — get one via L<Git::Native::Repository/config_snapshot>
or the L<Git::Native::Repository/config_string> convenience. Writes
(C<set_string>) require a live config from L<Git::Native::Repository/config>.

A repository config sees the merged view git itself would use: the
repository's own C<config> file plus the global and system levels.

=head2 get_string

  my $name = $repo->config_snapshot->get_string('user.name');

The value of C<$key>, or C<undef> when the key is not set anywhere in the
config. Only "not found" becomes C<undef> — any other libgit2 failure
throws a L<Git::Native::Error>, so an unreadable config is never silently
reported as unset.

Call it on a snapshot. On a live config libgit2 refuses the read and this
throws; L<Git::Native::Repository/config_string> takes a snapshot for you.

=head2 get_bool

  if ( $repo->config_snapshot->get_bool('core.bare') ) { ... }

1 or 0 for a git-style boolean, or C<undef> when the key is not set —
which is why the test is C<defined>, not truth, when "unset" and "false"
have to be told apart. libgit2 does the parsing (C<true>/C<yes>/C<on>/1,
C<false>/C<no>/C<off>/0, integers by non-zero), so git's own rules apply.
A key set to something that is not a boolean at all throws a
L<Git::Native::Error> rather than coming back C<undef>.

=head2 set_string

  $repo->config->set_string('user.name', 'Ada');

Write C<$value> under C<$key> and return the config. Needs a live config —
a snapshot is read-only and throws. The write lands in the highest-priority
writable level, i.e. the repository's own config file.

=head2 snapshot

  my $snap = $repo->config->snapshot;

A frozen, read-only copy of the config as it stands right now, returned as
a fresh Config. Later writes through the live config are not visible in it;
take a new snapshot to see them.

=head1 SEE ALSO

L<Git::Native::Repository>

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
