# ABSTRACT: A Git author/committer signature

package Git::Native::Signature;
use Moo;
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();

has name  => ( is => 'ro', required => 1 );
has email => ( is => 'ro', required => 1 );
has when  => ( is => 'ro' );                # epoch seconds; default = now
has offset => ( is => 'ro', default => 0 ); # minutes

# Underlying git_signature*; allocated lazily, freed in DESTROY.
has _handle => (
  is      => 'lazy',
  builder => '_build_handle',
  clearer => '_clear_handle',
);

sub _build_handle {
  my $self = shift;
  my $sig;
  if ( defined $self->when ) {
    check_rc Git::Libgit2::FFI::git_signature_new(
      \$sig, $self->name, $self->email, $self->when, $self->offset,
    );
  }
  else {
    check_rc Git::Libgit2::FFI::git_signature_now(
      \$sig, $self->name, $self->email,
    );
  }
  return $sig;
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_signature_free( $self->{_handle} )
    if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Signature - A Git author/committer signature

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $sig = Git::Native::Signature->new(
    name  => 'Test',
    email => 'test@example.invalid',
    when  => time,
    offset => 0,
  );

=head1 DESCRIPTION

A Git signature (name + email + timestamp). Wraps C<git_signature*>;
freed automatically when the object goes out of scope.

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
