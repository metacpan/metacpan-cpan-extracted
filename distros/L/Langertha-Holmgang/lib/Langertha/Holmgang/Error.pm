package Langertha::Holmgang::Error;
# ABSTRACT: A loud refusal of input: the field path and the reason

use Moose;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use overload '""' => sub { $_[0]->field.': '.$_[0]->reason }, fallback => 1;
use namespace::autoclean;

our $VERSION = '0.001';

has field => ( is => 'ro', required => 1 );


has reason => ( is => 'ro', required => 1 );


sub throw {
  my ( $class, $field, $reason ) = @_;
  croak $class->new( field => $field, reason => $reason );
}


sub caught {
  my ( $class, $err ) = @_;
  return blessed $err && $err->isa($class) ? $err : undef;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Error - A loud refusal of input: the field path and the reason

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The refusal the loader, the structure checks and lint throw: not a program
error but input that does not hold, named by its field. Ported from
cai-platform's C<CAI::Platform::Refusal>.

=head2 field

Required. The refused field as a path, e.g. C<cases/c1.yaml: rules[0].regex>
or C<threshold.pass_rate>.

=head2 reason

Required. Why the field was refused, for logs, authors and tests.

=head2 throw

  Langertha::Holmgang::Error->throw( 'cases/c1.yaml: title' => 'text missing' );

Dies with a new refusal. As a string it reads C<field: reason>.

=head2 caught

  my $refusal = Langertha::Holmgang::Error->caught($@) or die $@;

Returns C<$err> when it is a refusal, else C<undef>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
