# ABSTRACT: Exception class for Git::Native

package Git::Native::Error;
use Moo;
extends 'Throwable::Error';

has code    => ( is => 'ro', required => 1 );
has klass   => ( is => 'ro', default  => 0 );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] ? %{ $args[0] } : @args;
  $args{message} //= '<unknown libgit2 error>';
  return $class->$orig(\%args);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Error - Exception class for Git::Native

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Git::Native::Error;
  Git::Native::Error->throw(
    code    => -3,
    klass   => 11,
    message => 'object not found',
  );

=head1 DESCRIPTION

Throwable exception used by L<Git::Native> when libgit2 reports an error.
Attributes mirror the C C<git_error> struct plus the return code.

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
