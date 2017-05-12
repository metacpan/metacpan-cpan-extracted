package Marketplace::Ebay::Order;

use strict;
use warnings;
use DateTime;
use DateTime::Format::ISO8601;
use Data::Dumper;

use Moo;
use MooX::Types::MooseLike::Base qw(Str HashRef Int Object Bool);
use Marketplace::Ebay::Order::Address;
use Marketplace::Ebay::Order::Item;
use namespace::clean;

=head1 NAME

Marketplace::Ebay::Order

=head1 DESCRIPTION

Class to handle the xml structures found in the GetOrders call.

L<http://developer.ebay.com/devzone/xml/docs/Reference/ebay/GetOrders.html>

The aim is to have a consistent interface with
L<Amazon::MWS::XML::Order> so importing the orders can happens almost
transparently.

=cut

=head1 ACCESSORS/METHODS

=head2 order

The raw structure got from the XML parsing

=head2 shop_type

Always returns C<ebay>

=cut

has order => (is => 'ro', isa => HashRef, required => 1);

sub shop_type {
    return 'ebay';
}

=head2 name_from_shipping_address

By default, lookup the name from the shipping address. Defaults to
true. Otherwise look it up from the first item. Prior to version 0.19,
the name was looked up from the first item only.

=cut

has name_from_shipping_address => (is => 'ro', isa => Bool, default => sub { 1 });

=head2 order_number

read-write accessor for the (shop) order number so you can set this
while importing it.

=head2 payment_status

read-write accessor for the payment status, so the shop can set it
while importing it.

=cut

has order_number => (is => 'rw', isa => Str);
has payment_status => (is => 'rw', isa => Str);

=head2 can_be_imported

Return true if both orderstatus and checkout status are completed

=cut

sub can_be_imported {
    my ($self) = @_;
    my $order = $self->order;
    if ($order->{OrderStatus} eq 'Completed' and
        $order->{CheckoutStatus}->{Status} eq 'Complete') {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 order_status

Return the order status and the payment status, separated by a colon.

=cut


sub order_status {
    my ($self) = @_;
    my $order = $self->order;
    my $order_status = $order->{OrderStatus} || 'Unknown';
    my $payment_status = $order->{CheckoutStatus}->{Status} || 'Unknown';
    return "$order_status: $payment_status";
}


=head2 ebay_order_number

Ebay order id.

=head2 remote_shop_order_id

Same as C<ebay_order_number>

=cut

sub ebay_order_number {
    return shift->order->{OrderID};
}

sub remote_shop_order_id {
    return shift->ebay_order_number;
}

has shipping_address => (is => 'lazy');

sub _build_shipping_address {
    my $self = shift;
    my $address = $self->order->{ShippingAddress};
    return Marketplace::Ebay::Order::Address->new(%$address);
}

has items_ref => (is => 'lazy');

sub _build_items_ref {
    my ($self) = @_;
    my $orderline = $self->orderline;
    my @items;
    foreach my $item (@$orderline) {
        # print Dumper($item);
        push @items, Marketplace::Ebay::Order::Item->new(struct => $item);
    }
    return \@items;
}


has number_of_items => (is => 'lazy', isa => Int);

sub _build_number_of_items {
    my $self = shift;
    my @items = $self->items;
    my $total = 0;
    foreach my $i (@items) {
        $total += $i->quantity;
    }
    return $total;
}

has first_item => (is => 'lazy', isa => Object);

sub _build_first_item {
    my $self = shift;
    my ($first, @rest) = $self->items;
    die "Missing items in transaction!" unless $first;
    return $first;
}

=head2 orderline

An arrayref with the TransactionArray.Transaction structure. This is
used internally by C<items>.

=cut

sub orderline {
    return shift->order->{TransactionArray}->{Transaction};
}

=head2 items

Return a list of L<Marketplace::Ebay::Order::Item> objects.

=cut

sub items {
    my $self = shift;
    return @{ $self->items_ref };
}

=head2 order_date

Return a DateTime object with the creation time of the order.

=cut

sub order_date {
    my $self = shift;
    if (my $date = $self->order->{CreatedTime}) {
        return DateTime::Format::ISO8601->parse_datetime($date);
    }
    return;
}

=head2 email

The email of the buyer. Given that this is provided per item, the
first one is used.

=cut

sub email {
    return shift->first_item->email;
}

=head2 first_name

The first name of the buyer, looked up from the first item.

=cut

sub first_name {
    my $self = shift;
    if ($self->name_from_shipping_address) {
        return $self->first_last_from_shipping_address->{first_name};
    }
    else {
        return $self->first_item->first_name || '';
    }
}

=head2 last_name

The last name of the buyer, looked up from the first item.

=cut


sub last_name {
    my $self = shift;
    if ($self->name_from_shipping_address) {
        return $self->first_last_from_shipping_address->{last_name};
    }
    else {
        return $self->first_item->last_name || '';
    }
}

has first_last_from_shipping_address => (is => 'lazy', isa => HashRef);

sub _build_first_last_from_shipping_address {
    my $self = shift;
    my ($first_name, $last_name) = ('', '');
    if (my $name = $self->shipping_address->name) {
        if ($name =~ m/\s*(.+?)\s+([\w-]+)\s*$/) {
            $first_name = $1;
            $last_name = $2;
        }
        elsif ($name =~ m/\s*(.+?)\s*$/) {
            # nothing to split, so this is just the last name
            $last_name = $1;
        }
    }
    return {
            first_name => $first_name,
            last_name => $last_name,
           };
}

=head2 comments

The BuyerCheckoutMessage's field of the order.

=cut

sub comments {
    my $self = shift;
    return $self->order->{BuyerCheckoutMessage};
}

=head2 shipping_method

The order's ShippingServiceSelected.ShippingService value

=cut

sub shipping_method {
    my $self = shift;
    if (my $shipping = $self->order->{ShippingServiceSelected}) {
        if (my $service = $shipping->{ShippingService}) {
            return $service;
        }
    }
    return '';
}

=head2 shipping_additional_costs

The order's ShippingServiceSelected.ShippingServiceAdditionalCost
value. I.e., the cost of the shipping for the other items ordered.

=cut

sub shipping_additional_costs {
    my $self = shift;
    my $cost = 0;
    if (my $shipping = $self->order->{ShippingServiceSelected}) {
        if (my $num = $shipping->{ShippingServiceAdditionalCost}) {
            $cost = $num->{_} || 0;
        }
    }
    return sprintf('%.2f', $cost);
}

=head2 shipping_first_unit

The order's ShippingServiceSelected.ShippingServiceCost value. This is
the cost of the shipping for the first item.

=cut

sub shipping_first_unit {
    my $self = shift;
    my $cost = 0;
    if (my $shipping = $self->order->{ShippingServiceSelected}) {
        if (my $num = $shipping->{ShippingServiceCost}) {
            $cost = $num->{_} || 0;
        }
    }
    return sprintf('%.2f', $cost);
}

=head2 shipping_cost

The total cost of the shipping. It is the C<shipping_first_unit> + the
additional costs multiplied by the number of additional items.

=cut

sub shipping_cost {
    my $self = shift;
    my $item_shipping = $self->shipping_first_unit;
    if (my $additional = $self->shipping_additional_costs) {
        if ($self->number_of_items > 1) {
            my $others = $self->number_of_items - 1;
            $item_shipping = $item_shipping + ($additional * $others);
        }
    }
    return sprintf('%.2f', $item_shipping);
}

=head2 total_cost

The total of the order, as reported by Ebay.

=cut

sub total_cost {
    my $self = shift;
    my $total = 0;
    if (my $amount = $self->order->{Total}) {
        if (my $num = $amount->{_}) {
            $total = $num;
        }
    }
    return sprintf('%.2f', $total);
}

=head2 subtotal

Sum of the subtotal of all items.

=cut

sub subtotal {
    my $self = shift;
    my @items = $self->items;
    my $total = 0;
    foreach my $i (@items) {
        $total += $i->subtotal;
    }
    return sprintf('%.2f', $total);
}

=head2 currency

The currency code of the order (looked up in the total).

=cut

sub currency {
    my $self = shift;
    if (my $currency = $self->order->{Total}->{currencyID}) {
        return $currency;
    }
    else {
        die "Can't find currency total! " . Dumper($self->order);
    }
}

=head2 payment_method

The CheckoutStatus.PaymentMethod value of the order.

=cut

sub payment_method {
    my $self = shift;
    if (my $checkout = $self->order->{CheckoutStatus}) {
        return $checkout->{PaymentMethod};
    }
    return;
}

=head2 order_is_shipped

Return true if all the items are marked as shipped.

=cut

sub order_is_shipped {
    my $self = shift;
    my $shipped;
    foreach my $item ($self->items) {
        if ($item->is_shipped) {
            $shipped = 1;
        }
        else {
            $shipped = 0;
            last;
        }
    }
    return $shipped;
}

=head2 ebay_site

Return the site where the order was placed. We have to loop over all
the items and check if they match. If they don't, we throw an
exception.

=cut

sub ebay_site {
    my $self = shift;
    my $site;
    foreach my $item ($self->items) {
        my $item_site = $item->ebay_site;
        die $item->sku . " has not a Site attached!" unless $item_site;
        # if defined, check, otherwise assign;
        if (defined $site) {
            if ($site ne $item_site) {
                die "Mismatch $site != $item_site on " . Dumper($self);
            }
        }
        else {
            $site = $item_site;
        }
    }
    return $site;
}

=head2 username

The ebay's username of the buyer.

=cut

sub username {
    my $self = shift;
    return $self->order->{BuyerUserID} || '';
}


1;
