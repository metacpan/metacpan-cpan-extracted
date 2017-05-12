package Interchange6::Types;

use strict;
use warnings;

use Type::Library -base, -declare => qw( Cart CartCost CartProduct );
use Type::Utils -all;
use Types::Standard -types;

BEGIN {
    extends "Types::Standard", "Types::Common::Numeric",
      "Types::Common::String";
}

class_type Cart, { class => 'Interchange6::Cart' };

class_type CartCost, { class => 'Interchange6::Cart::Cost' };
coerce CartCost, from Any, via { 'Interchange6::Cart::Cost'->new(@_) };

class_type CartProduct, { class => 'Interchange6::Cart::Product' };
coerce CartProduct, from Any, via { 'Interchange6::Cart::Product'->new(@_) };

1;
__END__

=head1 NAME

Interchange6::Types - Type library for Interchange6

=head1 DESCRIPTION

A L<Type::Library> based on L<Type::Tiny> for the Interchange6 shop machine.

Includes all of the types from the following libraries plus some additional
types:

=over

=item * L<Types::Standard>

=item * L<Types::Common::Numeric>

=item * L<Types::Common::String>

=back

=cut

=head1 TYPES

=head2 Cart

InstanceOf['Interchange6::Cart']

=head2 CartCost

InstanceOf['Interchange6::Cart::Cost']

=head2 CartProduct'

InstanceOf['Interchange6::Cart::Product']
