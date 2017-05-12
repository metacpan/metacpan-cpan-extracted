# $Id$
package Handel::Schema::RDBO::Order::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Schema::RDBO::Object/;
};

__PACKAGE__->meta->setup(
    table   => 'order_items',
    columns => [
        id          => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},
        orderid     => {type => 'varchar', length => 36, not_null => 1},
        sku         => {type => 'varchar', length => 25, not_null => 1},
        quantity    => {type => 'integer', default => 0, not_null => 1},
        price       => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        total       => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        description => {type => 'varchar', length => 255, default => undef, not_null => 0}
    ]
);

1;
__END__

=head1 NAME

Handel::Schema::RDBO::Order::Item - RDBO schema class for order_items table

=head1 SYNOPSIS

    use Handel::Schema::RDBO::Order::Item;
    use strict;
    use warnings;
    
    my $item = Handel::Schema::RDBO::Order::Item->new(id => '12345678-9098-7654-3212-345678909876');
    $item->load;

=head1 DESCRIPTION

Handel::Schema::RDBO::Order::Item is loaded by Handel::Storage::RDBO::Order::Item
to read/write data to the cart_items table.

=head1 COLUMNS

=head2 id

Contains the primary key for each order item record. By default, this is a uuid
string.

    id => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},

=head2 orderid

Contains the foreign key to the orders table.

    orderid => {type => 'varchar', length => 36, not_null => 1},

=head2 sku

Contains the sku (Stock Keeping Unit), or part number for the current order item.

    sku => {type => 'varchar', length => 25, not_null => 1},

=head2 quantity

Contains the number of this order item being ordered.

    quantity => {type => 'integer', default => 0, not_null => 1},

=head2 price

Contains the price of the current order item.

    price => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 total

Contains the total cost of the current order item.

    total => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 description

Contains the description of the current order item.

    description => {type => 'varchar', length => 255, default => undef, not_null => 0}

=head1 SEE ALSO

L<Handel::Schema::RDBO::Order>, L<Rose::DB::Object>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

