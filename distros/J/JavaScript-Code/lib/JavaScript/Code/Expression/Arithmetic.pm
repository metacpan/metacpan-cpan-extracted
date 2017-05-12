package JavaScript::Code::Expression::Arithmetic;

use strict;
use vars qw[ $VERSION @EXPORT_OK ];
use base qw[
  JavaScript::Code::Expression
  JavaScript::Code::Expression::Node::Arithmetic
  Exporter
];

@EXPORT_OK = qw[ ADD SUB MUL DIV ];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression::Arithmetic - A JavaScript Arithmetic Expression

=head1 METHODS

=cut

=head2 $self->addition( ... )

=cut

sub addition {
    my $e = __PACKAGE__->new;
    $e->command( 'Addition', @_ );
    return $e;
}

=head2 $self->subtraction( ... )

=cut

sub subtraction {
    my $e = __PACKAGE__->new;
    $e->command( 'Subtraction', @_ );
    return $e;
}

=head2 $self->multiplication( ... )

=cut

sub multiplication {
    my $e = __PACKAGE__->new;
    $e->command( 'Multiplication', @_ );
    return $e;
}

=head2 $self->division( ... )

=cut

sub division {
    my $e = __PACKAGE__->new;
    $e->command( 'Division', @_ );
    return $e;
}

=head2 ADD

=head2 SUB

=head2 MUL

=head2 DIV

sub ADD { &addition }
sub SUB { &subtraction }
sub MUL { &multiplication }
sub DIV { &division }

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
