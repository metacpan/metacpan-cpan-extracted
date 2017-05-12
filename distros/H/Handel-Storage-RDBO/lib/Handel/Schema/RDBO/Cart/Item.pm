# $Id$
package Handel::Schema::RDBO::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Schema::RDBO::Object/;
};

__PACKAGE__->meta->setup(
    table   => 'cart_items',
    columns => [
        id          => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},
        cart        => {type => 'varchar', length => 36, not_null => 1},
        sku         => {type => 'varchar', length => 25, not_null => 1},
        quantity    => {type => 'integer', default => 0, not_null => 1},
        price       => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        description => {type => 'varchar', length => 255, default => undef, not_null => 0}
    ]
);

1;
__END__

=head1 NAME

Handel::Schema::RDBO::Cart::Item - RDBO schema class for cart_items table

=head1 SYNOPSIS

    use Handel::Schema::RDBO::Cart::Item;
    use strict;
    use warnings;
    
    my $item = Handel::Schema::RDBO::Cart::Item->new(id => '12345678-9098-7654-3212-345678909876');
    $item->load;

=head1 DESCRIPTION

Handel::Schema::RDBO::Cart::Item is loaded by Handel::Storage::RDBO::Cart::Item
to read/write data to the cart_items table.

=head1 COLUMNS

=head2 id

Contains the primary key for each cart item record. By default, this is a uuid
string.

    id => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},

=head2 cart

Contains the foreign key to the carts table.

    cart => {type => 'varchar', length => 36, not_null => 1},

=head2 sku

Contains the sku (Stock Keeping Unit), or part number for the current cart item.

    sku => {type => 'varchar', length => 25, not_null => 1},

=head2 quantity

Contains the number of this cart item being ordered.

    quantity => {type => 'integer', default => 0, not_null => 1},

=head2 price

Contains the price if the current cart item.

    price => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 description

Contains the description of the current cart item.

    description => {type => 'varchar', length => 255, default => undef, not_null => 0}

=head1 SEE ALSO

L<Handel::Schema::RDBO::Cart>, L<Rose::DB::Object>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
