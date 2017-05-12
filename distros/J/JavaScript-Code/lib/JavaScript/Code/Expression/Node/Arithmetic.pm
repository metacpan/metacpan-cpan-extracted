package JavaScript::Code::Expression::Node::Arithmetic;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Expression::Node ];

use JavaScript::Code::Expression::Arithmetic ();

use overload
  '+' => \&addition,
  '-' => \&subtraction,
  '*' => \&multiplication,
  '/' => \&division;

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression::Node::Arithmetic - A Node For JavaScript Arithmetic Expressions

=head1 METHODS

=head2 $self->addition( ... )

=cut

sub addition {
    return JavaScript::Code::Expression::Arithmetic::addition(@_);
}

=head2 $self->subtraction( ... )

=cut

sub subtraction {
    return JavaScript::Code::Expression::Arithmetic::subtraction(@_);
}

=head2 $self->multiplication( ... )

=cut

sub multiplication {
    return JavaScript::Code::Expression::Arithmetic::multiplication(@_);
}

=head2 $self->division( ... )

=cut

sub division {
    return JavaScript::Code::Expression::Arithmetic::division(@_);
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

