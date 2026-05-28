# ABSTRACT: A libgit2 configuration handle

package Git::Native::Config;
use Moo;
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro' );   # Repository (when repo-derived) - keeps it alive

# get_string($key): the value, or undef when the key is unset.
# libgit2 only guarantees git_config_get_string on a *snapshot* config;
# use Repository->config_snapshot / config_string for reads.
sub get_string {
  my ( $self, $key ) = @_;
  my $rc = Git::Libgit2::FFI::git_config_get_string( \my $out, $self->_handle, $key );
  return undef if $rc < 0;   # GIT_ENOTFOUND etc. - treat as "unset"
  return $out;
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

version 0.003

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
