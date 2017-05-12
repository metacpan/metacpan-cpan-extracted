package Marketplace::Ebay::Order::Item;

=head1 NAME

Marketplace::Ebay::Order::Item.

=head1 DESCRIPTION

Class to handle the xml structures representing a orderline item.

This modules doesn't do much, it just provides an uniform iterface
with other Marketplace modules.

Items must implement the following methods: 

=over 4

=item sku

=item quantity

=item price

From the Ebay documentation:

The price of the order line item (transaction). This amount does not
take into account shipping, sales tax, and other costs related to
the order line item. If multiple units were purchased through a non-
variation, fixed-price listing, consider this value the per-unit
price. In this case, the TransactionPrice would be multiplied by the
Transaction.QuantityPurchased value.

=item subtotal

=item remote_shop_order_item

=item merchant_order_item 

This one should be a read-write accessor, because usually Ebay doesn't
know about it.

=back 

=head1 ACCESSORS

=head2 struct

This hashref must be passed to the constructor, containing the XML
structure.

=head1 OTHER SHORTCUTS

=head2 canonical_sku

The canonical sku.

=head2 variant_sku

The variant sku.

=head2 sku

This return either the variant's SKU, if present, or the canonical SKU.

=cut

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw(HashRef Str);
use Data::Dumper;
use namespace::clean;

has struct => (is => 'ro', isa => HashRef);
has merchant_order_item => (is => 'rw', isa => Str);

sub sku {
    my $self = shift;
    return $self->variant_sku || $self->canonical_sku;
}

sub canonical_sku {
    # Item is always present
    return shift->struct->{Item}->{SKU};
}

sub variant_sku {
    my $self = shift;
    my $struct = $self->struct;
    if ($struct->{Variation}) {
        return $struct->{Variation}->{SKU};
    }
    else {
        return;
    }
}

sub remote_shop_order_item {
    return shift->struct->{OrderLineItemID};
}

# guaranteed to be there  http://developer.ebay.com/devzone/xml/docs/Reference/ebay/GetOrders.html#Response.OrderArray.Order.TransactionArray.Transaction.QuantityPurchased

sub quantity {
    return shift->struct->{QuantityPurchased};
}

sub price {
    my $self = shift;
    return sprintf('%.2f', $self->struct->{TransactionPrice}->{_});
}

sub subtotal {
    my $self = shift;
    return sprintf('%.2f', $self->price * $self->quantity);
}

=head2 shipping

The shipping costs. Always return 0, it's not something available in
the orderline item.

=cut

sub shipping {
    return 0; # not available in the item
}

=head2 is_shipped

Return the shipped time if defined. You should consider this a
boolean.

=cut

sub is_shipped {
    my $self = shift;
    return $self->struct->{ShippedTime};
}

=head2 email

Buyer's email.

=cut

sub email {
    return shift->struct->{Buyer}->{Email};
}

=head2 first_name

Buyer's first name

=cut

sub first_name {
    return shift->struct->{Buyer}->{UserFirstName};
}

=head2 last_name

Buyer's last name.

=cut

sub last_name {
    return shift->struct->{Buyer}->{UserLastName};
}

=head2 ebay_site

The ebay site id.

=cut

sub ebay_site {
    return shift->struct->{Item}->{Site};
}

1;

