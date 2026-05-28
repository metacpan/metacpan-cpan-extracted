# ABSTRACT: A libgit2 credential (passed back from acquire callbacks)

package Git::Native::Credential;
use Moo;
use Carp ();
use Git::Libgit2 qw( check_rc init_lib );
use Git::Libgit2::FFI ();

# Ensure libgit2 FFI is initialised before first use of this module.
init_lib();

has _handle => ( is => 'rw', required => 1 );

# Class-method constructors — each allocates a git_credential* via the
# matching libgit2 helper and wraps it. libgit2 takes ownership of the
# pointer once the acquire-callback returns 0; before that we own it.

sub userpass {
  my ( $class, %args ) = @_;
  my $user = $args{username} // Carp::croak "userpass: 'username' required";
  my $pass = $args{password} // Carp::croak "userpass: 'password' required";
  check_rc Git::Libgit2::FFI::git_credential_userpass_plaintext_new(
    \my $cred, $user, $pass,
  );
  return $class->new( _handle => $cred );
}

sub ssh_key {
  my ( $class, %args ) = @_;
  my $user        = $args{username}    // Carp::croak "ssh_key: 'username' required";
  my $private_key = $args{private_key} // Carp::croak "ssh_key: 'private_key' required";
  my $public_key  = $args{public_key};   # may be undef → libgit2 derives
  my $passphrase  = $args{passphrase} // '';
  check_rc Git::Libgit2::FFI::git_credential_ssh_key_new(
    \my $cred, $user, $public_key, $private_key, $passphrase,
  );
  return $class->new( _handle => $cred );
}

sub ssh_agent {
  my ( $class, %args ) = @_;
  my $user = $args{username} // Carp::croak "ssh_agent: 'username' required";
  check_rc Git::Libgit2::FFI::git_credential_ssh_key_from_agent(
    \my $cred, $user,
  );
  return $class->new( _handle => $cred );
}

sub default {
  my ($class) = @_;
  check_rc Git::Libgit2::FFI::git_credential_default_new( \my $cred );
  return $class->new( _handle => $cred );
}

sub username {
  my ( $class, %args ) = @_;
  my $user = $args{username} // Carp::croak "username: 'username' required";
  check_rc Git::Libgit2::FFI::git_credential_username_new( \my $cred, $user );
  return $class->new( _handle => $cred );
}

# Internal — called by the credential-acquire thunk after handing the
# pointer to libgit2. Prevents DEMOLISH from double-freeing.
sub _disown {
  my $self = shift;
  my $h = $self->_handle;
  $self->_handle(undef);
  return $h;
}

sub DEMOLISH {
  my $self = shift;
  if ( my $h = $self->{_handle} ) {
    Git::Libgit2::FFI::git_credential_free($h);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Credential - A libgit2 credential (passed back from acquire callbacks)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Git::Native::Credential;

  my $cred = Git::Native::Credential->userpass(
    username => 'git',
    password => $ENV{GITHUB_TOKEN},
  );

  # ssh-agent (matches CLI default for git+ssh remotes)
  my $cred = Git::Native::Credential->ssh_agent(username => 'git');

  # explicit key file
  my $cred = Git::Native::Credential->ssh_key(
    username    => 'git',
    public_key  => "$ENV{HOME}/.ssh/id_ed25519.pub",
    private_key => "$ENV{HOME}/.ssh/id_ed25519",
    passphrase  => '',
  );

=head1 DESCRIPTION

Returned from the C<credentials> callback you pass to
L<Git::Native::Remote>'s C<fetch>/C<push>. libgit2 takes ownership of
the credential once the callback returns successfully — the Perl wrapper
is disowned automatically so it won't double-free.

If you construct one without passing it to libgit2, DEMOLISH calls
C<git_credential_free> for you.

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
