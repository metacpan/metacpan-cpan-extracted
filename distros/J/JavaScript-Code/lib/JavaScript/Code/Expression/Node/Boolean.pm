package JavaScript::Code::Expression::Node::Boolean;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Expression::Node ];

use JavaScript::Code::Expression::Boolean ();

use overload
  '<' => \&less,
  '<=' => \&less_equal,
  '>' => \&greater,
  '>=' => \&greater_equal,
  '==' => \&equal,
  '!=' => \&not_equal;

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression::Node::Boolean - A Node For JavaScript Boolean Expressions

=head1 METHODS

=head2 $self->less( ... )

=cut

sub less {
    return JavaScript::Code::Expression::Boolean::less( @_ );
}

=head2 $self->less_equal( ... )

=cut

sub less_equal {
    return JavaScript::Code::Expression::Boolean::less_equal( @_ );
}

=head2 $self->greater( ... )

=cut

sub greater {
    return JavaScript::Code::Expression::Boolean::greater( @_ );
}

=head2 $self->greater_equal( ... )

=cut

sub greater_equal {
    return JavaScript::Code::Expression::Boolean::greater_equal( @_ );
}

=head2 $self->equal( ... )

=cut

sub equal {
    return JavaScript::Code::Expression::Boolean::equal( @_ );
}

=head2 $self->not_equal( ... )

=cut

sub not_equal {
    return JavaScript::Code::Expression::Boolean::not_equal( @_ );
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
