package Marketplace::Rakuten::Order;

use strict;
use warnings;
use Data::Dumper;
use DateTime;
use DateTime::Format::ISO8601;

use Moo;
use MooX::Types::MooseLike::Base qw(Str HashRef Int Object);
use Marketplace::Rakuten::Order::Address;
use Marketplace::Rakuten::Order::Item;
use Marketplace::Rakuten::Utils;

use namespace::clean;

=head1 NAME

=encoding utf8

Marketplace::Rakuten::Order

=head1 DESCRIPTION

Class to handle the xml structures returned by
L<http://webservice.rakuten.de/documentation/method/get_orders>

The aim is to have a consistent interface with
L<Amazon::MWS::XML::Order> so importing the orders can happens almost
transparently.

=cut

=head1 ACCESSORS/METHODS

=head2 order

The raw structure got from the XML parsing

=head2 shop_type

Always returns C<rakuten>

=cut

has order => (is => 'ro', isa => HashRef, required => 1);

sub shop_type {
    return 'rakuten';
}

=head2 order_number

read-write accessor for the (shop) order number so you can set this
while importing it.

=cut

has order_number => (is => 'rw', isa => Str);

=head2 payment_status

read-write accessor for the payment status, so the shop can set it
while importing it.

=cut

has payment_status => (is => 'rw', isa => Str);

=head2 order_status

Unclear (for now) what to do here. List of statuses:
 	
=over 4

=item pending

 Bestellung ist neu eingegangen

=item editable

Bestellung ist zur Bearbeitung freigegeben

=item shipped

Bestellung ist versendet

=item payout

Bestellung ist ausbezahlt

=item cancelled

Bestellung ist storniert

=back 

=head2 can_be_imported

It returns true if the status is pending or editable or payout.

=cut

sub can_be_imported {
    my $self = shift;
    my %map = (
               pending => 1,
               editable => 1,
               payout => 1,
               cancelled => 0,
              );
    return $map{$self->order_status} || 0;
}

sub order_status {
    return shift->order->{status};
}

=head2 remote_shop_order_id

The Rakuten order id.

=cut

sub remote_shop_order_id {
    return shift->order->{order_no};
}

has shipping_address => (is => 'lazy');

sub _build_shipping_address {
    my $self = shift;
    my $address = $self->order->{delivery_address};
    my $billing = $self->order->{client};
    my %args;
    if ($address) {
        %args = %$address;
        # populate the object with billing data as well
        if ($billing) {
            foreach my $k (qw/client_id email phone/) {
                $args{$k} = $billing->{$k};
            }
        }
        return $self->_address_building_routine(%args);
    }
    return;
}

has billing_address => (is => 'lazy');

sub _build_billing_address {
    my $self = shift;
    my $billing = $self->order->{client};
    if ($billing) {
        return $self->_address_building_routine(%$billing);
    }
    return undef;
}

has items_ref => (is => 'lazy');

sub _address_building_routine {
    my ($self, %params) = @_;
    my %args = %params;
    Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings(\%args);
    return Marketplace::Rakuten::Order::Address->new(%args);
}


sub _build_items_ref {
    my ($self) = @_;
    my @items;
    my $order_num = $self->remote_shop_order_id;
    if ($self->order->{items}) {
        if (my $item = $self->order->{items}->{item}) {
            if (ref($item) eq 'HASH') {
                Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($item);
                push @items,
                  Marketplace::Rakuten::Order::Item
                    ->new(struct => $item,
                          order_number => $order_num,
                         );
            }
            elsif (ref($item) eq 'ARRAY') {
                foreach my $i (@$item) {
                    Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($i);
                    push @items,
                      Marketplace::Rakuten::Order::Item
                        ->new(struct => $i,
                              order_number => $order_num,
                             );
                }
            }
            else {
                die "Unexpected orderline" . Dumper($item);
            }
        }
    }
    return \@items;
}

=head2 items

Returns a list of L<Marketplace::Rakuten::Order::Item> objects.

=cut

sub items {
    return @{ shift->items_ref };
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

=head2 email

The billing address' email

=cut

sub email {
    return shift->billing_address->email;
}

=head2 first_name

The billing address' first name

=cut

sub first_name {
    return shift->billing_address->first_name;
}

=head2 last_name

The billing address' last name

=cut

sub last_name {
    return shift->billing_address->last_name;
}

=head2 comments

The buyer's comments.

=cut

sub comments {
    return shift->order->{comment_client};
}

=head2 order_date

Return a DateTime object with the creation time of the order.

=cut

sub order_date {
    my $self = shift;
    if (my $date = $self->order->{created}) {
        $date =~ s/ /T/; # eh
        return DateTime::Format::ISO8601->parse_datetime($date);
    }
    return;

}

=head2 shipping_method

It always returns nothing. The data is not provided by the remote
service.

=cut

sub shipping_method {
    return;
}

=head2 shipping_cost

The shipping costs of the order.

=cut

sub shipping_cost {
    return shift->order->{shipping} || 0;
}

=head2 subtotal

Subtotal of the order, implemented as total cost minus the shipping
cost.

=cut

sub subtotal {
    my $self = shift;
    # coupons are not handled yet
    my $subtotal = $self->total_cost - $self->shipping_cost;
    return sprintf('%.2f', $subtotal);
}

=head2 total_cost

The total cost as provided by Rakuten.

=cut

sub total_cost {
    return shift->order->{total} || 0;
}

=head2 payment_method

Mapping:


  PP 	= 	Vorauskasse
  CC 	= 	Kreditkarte
  ELV 	= 	Lastschrift
  ELV-AT 	= 	Lastschrift Österreich
  SUE 	= 	Sofortüberweisung
  CB 	= 	ClickAndBuy
  INV 	= 	Rechnung
  INV-AT 	= 	Rechnung Österreich
  PAL 	= 	Paypal
  GP 	= 	giropay
  KLA 	= 	Klarna
  MPA 	= 	mpass
  BAR 	= 	Barzahlen
  YAP 	= 	YAPITAL

=cut

sub payment_method {
    return shift->order->{payment};
}


1;
