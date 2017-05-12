# $Id$
package Handel::Schema::RDBO::Cart;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Schema::RDBO::Object/;
};

__PACKAGE__->meta->setup(
    table   => 'cart',
    columns => [
        id          => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},
        shopper     => {type => 'varchar', length => 36, not_null => 1},
        type        => {type => 'boolean', default => 0, not_null => 1},
        name        => {type => 'varchar', length => 50, not_null => 0},
        description => {type => 'varchar', length => 255, not_null => 0}
    ],
    relationships => [
        items => {
            type       => 'one to many',
            class      => 'Handel::Schema::RDBO::Cart::Item',
            column_map => {id => 'cart'}
        }
    ]
);

1;
__END__

=head1 NAME

Handel::Schema::RDBO::Cart - RDBO schema class for the cart table

=head1 SYNOPSIS

    use Handel::Schema::RDBO::Cart;
    use strict;
    use warnings;

    my $cart = Handel::Schema::RDBO::Cart->new(id => '12345678-9098-7654-3212-345678909876');
    $cart->load;

=head1 DESCRIPTION

Handel::Schema::RDBO::Cart is loaded by Handel::Storage::RDBO::Cart to
read/write data to the cart table.

=head1 COLUMNS

=head2 id

Contains the primary key for each cart record. By default, this is a uuid
string.

    id => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},

=head2 shopper

Contains the keys used to tie each cart to a specific shopper. By default, this
is a uuid string.

    shopper => {type => 'varchar', length => 36, not_null => 1},

=head2 type

Contains the type for this shopping cart. The current values are
C<CART_TYPE_TEMP> and C<CART_TYPE_SAVED> from
L<Handel::Constants|Handel::Constants>.

    type => {type => 'boolean', default => 0, not_null => 1},

=head2 name

Contains the name of the current cart.

    name => {type => 'varchar', length => 50, not_null => 0},

=head2 description

Contains the description of the current cart.

    description => {type => 'varchar', length => 255, not_null => 0}

=head1 SEE ALSO

L<Handel::Schema::RDBO::Cart::Item>, L<Rose::DB::Object>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
