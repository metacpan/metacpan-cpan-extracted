package Google::Checkout::Notification::NewOrder;

=head1 NAME

Google::Checkout::Notification::NewOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Notification::NewOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $xml = "/xml/new_order_notification.xml";

  #--
  #-- $xml can either be a file or a complete XML doc string
  #--
  my $new_order = Google::Checkout::Notification::NewOrder->new(xml => $xml);
  die $new_order if is_gco_error $new_order;

  my $items = $new_order->get_items();

  for my $item (@$items)
  {
    print $item->get_merchant_item_id,"\n",
          $item->get_name,"\n",
          $item->get_description,"\n",
          $item->get_price,"\n",
          $item->get_quantity,"\n";
  }

=head1 DESCRIPTION

Sub-class of C<Google::Checkout::Notification::GCONotification>. 
When a new order notification is received, this module can be used 
to extract various information about the new order.

=over 4

=item new XML => ...

Constructor. Takes either a XML file or XML doc as data string. If
the XML is invalid (syntax error for example), C<Google::Checkout::General::Error> 
is returned.

=item type

Always return C<Google::Checkout::XML::Constants::NEW_ORDER_NOTIFICATION>.

=item get_order_total

Returns the total of the order.

=item get_buyer_id 

Returns the buyer ID.

=item get_fulfillment_state

Returns the fulfillment state. Since this is a new order, this will
most likely be 'NEW'.

=item get_financial_state

Returns the financial state. Since this is a new order, this will
most likely be 'REVIEWING'.

=item marketing_email_allowed

Returns the string 'true' if marketing email is allowed. Otherwise,
returns the string 'false'.

=item get_buyer_info SHIPPING_OR_BILLING, WHICH_DATA

Returns various buyer info. SHIPPING_OR_BILLING can either be
C<Google::Checkout::XML::Constants::GET_SHIPPING> or 
C<Google::Checkout::XML::Constants::GET_BILLING> 
to get buyer's shipping or billing data respectively. WHICH_DATA can be 
C<Google::Checkout::XML::Constants::BUYER_CONTACT_NAME>, 
C<Google::Checkout::XML::Constants::BUYER_COMPANY_NAME>, 
C<Google::Checkout::XML::Constants::BUYER_EMAIL>, 
C<Google::Checkout::XML::Constants::BUYER_PHONE>, 
C<Google::Checkout::XML::Constants::BUYER_FAX>, 
C<Google::Checkout::XML::Constants::BUYER_ADDRESS1>, 
C<Google::Checkout::XML::Constants::BUYER_ADDRESS2>, 
C<Google::Checkout::XML::Constants::BUYER_CITY>, 
C<Google::Checkout::XML::Constants::BUYER_REGION>, 
C<Google::Checkout::XML::Constants::BUYER_POSTAL_CODE>, 
C<Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE>.

=item merchant_calculation_successful

Returns the string 'true' is merchant calculation is successful. Returns
the string 'false' otherwise.

=item get_total_tax

Returns the total tax applied to the new order.

=item get_adjustment_total

Returns the adjustment total.

=item get_gift_certificate_calculated_amount

Returns the gift certificate calculated amount.

=item get_gift_certificate_applied_amount

Returns the amount actually applied from using the gift
certificate.

=item get_gift_certificate_code

Returns the gift certificate code.

=item get_gift_certificate_pin

Returns the gift certificate PIN.

=item get_gift_certificate_message

Returns the gift certificate message.

=item get_coupon_calculated_amount

Returns the coupon calculated amount.

=item get_coupon_applied_amount

Returns the amount actually applied from using the coupon.

=item get_coupon_code

Returns the coupon code.

=item get_coupon_message

Returns the coupon message.

=item get_shipping_method

Returns the shipping method. If no shipping method is found,
returns C<Google::Checkout::General::Error> instead.

=item get_shipping_name

Returns the shipping name.

=item get_shipping_cost

Returns the shipping cost.

=item get_cart_expiration

Returns the expiration date of the shopping cart.

=item get_merchant_private_data

Returns the merchant private data.

=item get_items

Returns all items in the order. The items are returned as
an array reference with each element a C<Google::Checkout::General::MerchantItem>
object.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::GCONotification

=cut

#--
#-- <new-order-notification>
#--

use strict;
use warnings;

use Google::Checkout::General::MerchantItem;
use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error is_valid_buyer_info/;

use Google::Checkout::Notification::GCONotification;
our @ISA = qw/Google::Checkout::Notification::GCONotification/;

sub type
{
  return Google::Checkout::XML::Constants::NEW_ORDER_NOTIFICATION;
}

sub get_order_total 
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_TOTAL}->{content} || 0;
}

sub get_buyer_id    
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::BUYER_ID} || '';
}

sub get_fulfillment_state 
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::FULFILLMENT_ORDER_STATE} || 'NEW'; 
}

sub get_financial_state   
{ 
  my ($self) = @_;

  my $state = Google::Checkout::XML::Constants::FINANCIAL_ORDER_STATE;

  return $self->get_data->{$state} || 'REVIEWING';
}

sub marketing_email_allowed
{
  my ($self) = @_;

  my $pstring = Google::Checkout::XML::Constants::BUYER_MARKETING_PERFERENCES;

  my $perferences = $self->get_data->{$pstring};

  return $perferences ? $perferences->{Google::Checkout::XML::Constants::EMAIL_ALLOWED} 
                        : 'false'; 
}

#--
#-- Returns either the shipping or billing information
#-- of the buyer depends on $shipping_billing. $info tells
#-- the API which pieces of information to get. 
#--
sub get_buyer_info
{
  my ($self, $shipping_billing, $info) = @_;

  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[0], 
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[1] . ": $shipping_billing")
    unless $shipping_billing eq Google::Checkout::XML::Constants::GET_SHIPPING or
           $shipping_billing eq Google::Checkout::XML::Constants::GET_BILLING;

  $shipping_billing = $shipping_billing eq Google::Checkout::XML::Constants::GET_SHIPPING ?
                        Google::Checkout::XML::Constants::BUYER_SHIPPING : 
                        Google::Checkout::XML::Constants::BUYER_BILLING;

  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[0],
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[1] . ": $info") 
    unless is_valid_buyer_info $info;

  my $ret = $self->get_data->{$shipping_billing}->{$info};

  if (ref($ret) eq 'HASH') {
    return '';
  } else {
    return $ret;
  }
}

sub merchant_calculation_successful
{ 
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::MERCHANT_CALCULATION_SUCCESSFUL;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}
                        ->{$sstring} || 'false'; 
}

sub get_total_tax
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}->
                          {Google::Checkout::XML::Constants::TOTAL_TAX}->{content} || 0; 
}

sub get_adjustment_total
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}->
                          {Google::Checkout::XML::Constants::ADJUSTMENT_TOTAL}->{content} || 0;
}

sub get_gift_certificate_calculated_amount
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           1, 
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CALCULATED_AMOUNT,
           0);
}
sub get_gift_certificate_applied_amount
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           1, 
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_APPLIED_AMOUNT,
           0);
}
sub get_gift_certificate_code
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           0, 
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CODE, 
           '');
}
sub get_gift_certificate_pin
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           0, 
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_PIN,
           '');
}
sub get_gift_certificate_message
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           0, 
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_ADJUSTMENT,
           Google::Checkout::XML::Constants::MESSAGE, 
           '');
}

sub get_coupon_calculated_amount
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           1, 
           Google::Checkout::XML::Constants::COUPON_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CALCULATED_AMOUNT,
           0);
}
sub get_coupon_applied_amount
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           1, 
           Google::Checkout::XML::Constants::COUPON_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_APPLIED_AMOUNT,
           0);
}
sub get_coupon_code
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           0, 
           Google::Checkout::XML::Constants::COUPON_ADJUSTMENT,
           Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CODE, 
           '');
}
sub get_coupon_message
{
  my ($self) = @_;

  return $self->_get_gift_coupon_info(
           0, 
           Google::Checkout::XML::Constants::COUPON_ADJUSTMENT,
           Google::Checkout::XML::Constants::MESSAGE, 
           '');
}

#--
#-- Return either merchant calculated shipping, flat rate shipping, 
#-- or pick up depends on what the user actually picks
#--
sub get_shipping_method
{
  my ($self) = @_;

  my $data = $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}
                            ->{Google::Checkout::XML::Constants::SHIPPING};

  return Google::Checkout::XML::Constants::MERCHANT_CALCULATED_SHIPPING_ADJUSTMENT 
    if exists $data->{Google::Checkout::XML::Constants::MERCHANT_CALCULATED_SHIPPING_ADJUSTMENT};

  return Google::Checkout::XML::Constants::FLAT_RATE_SHIPPING_ADJUSTMENT
    if exists $data->{Google::Checkout::XML::Constants::FLAT_RATE_SHIPPING_ADJUSTMENT};

  return Google::Checkout::XML::Constants::PICKUP_SHIPPING_ADJUSTMENT
    if exists $data->{Google::Checkout::XML::Constants::PICKUP_SHIPPING_ADJUSTMENT};

  return Google::Checkout::General::Error->new(
           @{$Google::Checkout::General::Error::ERRORS{INVALID_SHIPPING_METHOD}});
}

sub get_shipping_name
{
  my ($self) = @_;

  my $shipping_method = $self->get_shipping_method;

  return $shipping_method if is_gco_error($shipping_method);

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}->
                          {Google::Checkout::XML::Constants::SHIPPING}->
                          {$shipping_method}->
                          {Google::Checkout::XML::Constants::SHIPPING_NAME} || '';
}

sub get_shipping_cost
{
  my ($self) = @_;

  my $shipping_method = $self->get_shipping_method;

  return $shipping_method if is_gco_error $shipping_method;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}->
                          {Google::Checkout::XML::Constants::SHIPPING}->
                          {$shipping_method}->
                          {Google::Checkout::XML::Constants::SHIPPING_COST}->
                          {content} || 0;
}

sub get_cart_expiration
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::SHOPPING_CART}->
                          {Google::Checkout::XML::Constants::EXPIRATION}->
                          {Google::Checkout::XML::Constants::GOOD_UNTIL} || '' 
}

sub get_merchant_private_data
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::SHOPPING_CART}->
                          {Google::Checkout::XML::Constants::MERCHANT_PRIVATE_DATA}->
                          {Google::Checkout::XML::Constants::MERCHANT_PRIVATE_NOTE} || '';
}

sub get_items
{
  my ($self) = @_;

  my $items = $self->get_data->{Google::Checkout::XML::Constants::SHOPPING_CART}->
                               {Google::Checkout::XML::Constants::ITEMS}->
                               {Google::Checkout::XML::Constants::ITEM};

  $items = [$items] if (ref $items eq 'HASH');

  my @item_objects;
  for my $item (@$items)
  {
    my $id          = $item->{Google::Checkout::XML::Constants::MERCHANT_ITEM_ID};
    my $name        = $item->{Google::Checkout::XML::Constants::ITEM_NAME};
    my $price       = $item->{Google::Checkout::XML::Constants::ITEM_PRICE}->{content};
    my $description = $item->{Google::Checkout::XML::Constants::ITEM_DESCRIPTION};
    my $quantity    = $item->{Google::Checkout::XML::Constants::QUANTITY};
    my $tax_table   = $item->{Google::Checkout::XML::Constants::TAX_TABLE_SELECTOR} || '';
    my $item_data   = $item->{Google::Checkout::XML::Constants::ITEM_PRIVATE_DATA}
                           ->{Google::Checkout::XML::Constants::ITEM_DATA} || '';

    #--
    #-- For some reason, Checkout seems to be using both 
    #-- <item-note> and <item-data> as a valid private item note node. 
    #-- Look for item note if item data is missing This could be a 
    #-- bug in the doc or implementation inconsistency - dzhuo
    #--
    $item_data = $item->{Google::Checkout::XML::Constants::ITEM_PRIVATE_DATA}
                      ->{Google::Checkout::XML::Constants::ITEM_PRIVATE_NOTE} 
      unless $item_data;

    $item_data ||= '';

    push(@item_objects, Google::Checkout::General::MerchantItem->new(
                          merchant_item_id   => $id,
                          name               => $name,
                          description        => $description,
                          price              => $price,
                          quantity           => $quantity,
                          private            => $item_data,
                          tax_table_selector => $tax_table));
  } 

  return \@item_objects
}

#-- PRIVATE --#

sub _get_gift_coupon_info
{
  my ($self, $content_meta, $name, $type, $default) = @_;

  my $r = $self->get_data->{Google::Checkout::XML::Constants::ORDER_ADJUSTMENT}
                         ->{Google::Checkout::XML::Constants::MERCHANT_CODES};

  my $v = $r->{$name}->{$type};

  $v = $v->{content} if $content_meta;

  return $v || $default; 
}

1;
