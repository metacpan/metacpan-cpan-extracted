# $Id$
package Handel::Schema::RDBO::Order;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Schema::RDBO::Object/;
    use DateTime;
};

__PACKAGE__->meta->setup(
    auto_load_related_classes => 0,
    table   => 'orders',
    columns => [
        id          => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},
        shopper     => {type => 'varchar', length => 36, not_null => 1},
        type        => {type => 'boolean', default => 0, not_null => 1},
        number      => {type => 'varchar', length => 20, not_null => 0},
        created     => {type => 'datetime', not_null => 0},
        updated     => {type => 'datetime', not_null => 0},
        comments    => {type => 'varchar', length => 100, not_null => 0},
        shipmethod  => {type => 'varchar', length => 20, not_null => 0},
        shipping    => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        handling    => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        tax         => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        subtotal    => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        total       => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},
        billtofirstname  => {type => 'varchar', length => 25, not_null => 0},
        billtolastname   => {type => 'varchar', length => 25, not_null => 0},
        billtoaddress1   => {type => 'varchar', length => 50, not_null => 0},
        billtoaddress2   => {type => 'varchar', length => 50, not_null => 0},
        billtoaddress3   => {type => 'varchar', length => 50, not_null => 0},
        billtocity       => {type => 'varchar', length => 50, not_null => 0},
        billtostate      => {type => 'varchar', length => 50, not_null => 0},
        billtozip        => {type => 'varchar', length => 10, not_null => 0},
        billtocountry    => {type => 'varchar', length => 25, not_null => 0},
        billtodayphone   => {type => 'varchar', length => 25, not_null => 0},
        billtonightphone => {type => 'varchar', length => 25, not_null => 0},
        billtofax        => {type => 'varchar', length => 25, not_null => 0},
        billtoemail      => {type => 'varchar', length => 50, not_null => 0},
        shiptosameasbillto => {type => 'boolean', default => 0, not_null => 1},
        shiptofirstname  => {type => 'varchar', length => 25, not_null => 0},
        shiptolastname   => {type => 'varchar', length => 25, not_null => 0},
        shiptoaddress1   => {type => 'varchar', length => 50, not_null => 0},
        shiptoaddress2   => {type => 'varchar', length => 50, not_null => 0},
        shiptoaddress3   => {type => 'varchar', length => 50, not_null => 0},
        shiptocity       => {type => 'varchar', length => 50, not_null => 0},
        shiptostate      => {type => 'varchar', length => 50, not_null => 0},
        shiptozip        => {type => 'varchar', length => 10, not_null => 0},
        shiptocountry    => {type => 'varchar', length => 25, not_null => 0},
        shiptodayphone   => {type => 'varchar', length => 25, not_null => 0},
        shiptonightphone => {type => 'varchar', length => 25, not_null => 0},
        shiptofax        => {type => 'varchar', length => 25, not_null => 0},
        shiptoemail      => {type => 'varchar', length => 50, not_null => 0},
    ],
    relationships => [
        items => {
            type       => 'one to many',
            class      => 'Handel::Schema::RDBO::Order::Item',
            column_map => {id => 'orderid'}
        }
    ]
);

1;
__END__

=head1 NAME

Handel::Schema::RDBO::Order - RDBO schema class for order table

=head1 SYNOPSIS

    use Handel::Schema::RDBO::Order;
    use strict;
    use warnings;

    my $order = Handel::Schema::RDBO::Order->new(id => '12345678-9098-7654-3212-345678909876');
    $order->load;

=head1 DESCRIPTION

Handel::Schema::RDBO::Order is loaded by Handel::Storage::RDBO::Order to
read/write data to the order table.

=head1 COLUMNS

=head2 id

Contains the primary key for each order record. By default, this is a uuid string.

    id => {type => 'varchar', primary_key => 1, length => 36, not_null => 1},

=head2 shopper

Contains the keys used to tie each order to a specific shopper. By default,
this is a uuid string.

    shopper => {type => 'varchar', length => 36, not_null => 1},

=head2 type

Contains the type for this order. The current values are ORDER_TYPE_TEMP and
ORDER_TYPE_SAVED from Handel::Constants.

    type => {type => 'boolean', default => 0, not_null => 1},

=head2 number

The order number for this order.

    number => {type => 'varchar', length => 20, not_null => 0},

=head2 created

The date this order record was created.

    created => {type => 'datetime', not_null => 0},

=head2 updated

The date this order record was last updated.

    updated => {type => 'datetime', not_null => 0},

=head2 comments

Any user comments for this order.

    comments => {type => 'varchar', length => 100, not_null => 0},

=head2 shipmethod

The shipping method for this order.

    shipmethod => {type => 'varchar', length => 20, not_null => 0},

=head2 shipping

The shipping cost for this order.

    shipping => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 handling

The handling charge for this order.

    handling => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 tax

The tax amount for this order.

    tax => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 subtotal

The subtotal of all the items on this order.

    subtotal => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 total

The total cost of the current order.

    total => {type => 'decimal', precision => 9, scale => 2, default => 0, not_null => 1},

=head2 billtofirstname

The first name for the billing address for this order.

    billtofirstname => {type => 'varchar', length => 25, not_null => 0},

=head2 billtolastname

The last name for the billing address for this order.

    billtolastname => {type => 'varchar', length => 25, not_null => 0},

=head2 billtoaddress1

The billing address line 1 for this order.

    billtoaddress1 => {type => 'varchar', length => 50, not_null => 0},

=head2 billtoaddress2

The billing address line 2 for this order.

    billtoaddress2 => {type => 'varchar', length => 50, not_null => 0},

=head2 billtoaddress3

The billing address line 3 for this order.

    billtoaddress3 => {type => 'varchar', length => 50, not_null => 0},

=head2 billtocity

The billing address city for this order.

    billtocity => {type => 'varchar', length => 50, not_null => 0},

=head2 billtostate

The billing address state/province for this order.

    billtostate => {type => 'varchar', length => 50, not_null => 0},

=head2 billtozip

The billing address zip/postal code for this order.

    billtozip => {type => 'varchar', length => 10, not_null => 0},

=head2 billtocountry

The billing address country for this order.

    billtocountry => {type => 'varchar', length => 25, not_null => 0},

=head2 billtodayphone

The billing address daytime phone number for this order.

    billtodayphone => {type => 'varchar', length => 25, not_null => 0},

=head2 billtonightphone

The billing address night time phone number for this order.

    billtonightphone => {type => 'varchar', length => 25, not_null => 0},

=head2 billtofax

The billing address fax number for this order.

    billtofax => {type => 'varchar', length => 25, not_null => 0},

=head2 billtoemail

The billing address email address for this order.

    billtoemail => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptosameasbillto

When set to true, the shipping address is the same as the billing address.

    shiptosameasbillto => {type => 'boolean', default => 0, not_null => 1},

=head2 shiptofirstname

The first name for the shipping address for this order.

    shiptofirstname => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptolastname

The last name for the shipping address for this order.

    shiptolastname => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptoaddress1

The shipping address line 1 for this order.

    shiptoaddress1 => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptoaddress2

The shipping address line 2 for this order.

    shiptoaddress2 => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptoaddress3

The shipping address line 3 for this order.

    shiptoaddress3 => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptocity

The shipping address city for this order.

    shiptocity => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptostate

The shipping address state/province for this order.

    shiptostate => {type => 'varchar', length => 50, not_null => 0},

=head2 shiptozip

The shipping address zip/postal code for this order.

    shiptozip => {type => 'varchar', length => 10, not_null => 0},

=head2 shiptocountry

The shipping address country for this order.

    shiptocountry => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptodayphone

The shipping address daytime phone number for this order.

    shiptodayphone => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptonightphone

The shipping address night time phone number for this order.

    shiptonightphone => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptofax

The shipping address fax number for this order.

    shiptofax => {type => 'varchar', length => 25, not_null => 0},

=head2 shiptoemail

The shipping address email address for this order.

    shiptoemail => {type => 'varchar', length => 50, not_null => 0}

=head1 SEE ALSO

L<Handel::Schema::RDBO::Order::Item>, L<Rose::DB::Object>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
