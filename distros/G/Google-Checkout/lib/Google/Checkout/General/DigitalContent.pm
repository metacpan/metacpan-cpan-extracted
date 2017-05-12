package Google::Checkout::General::DigitalContent;

=head1 NAME

Google::Checkout::General::DigitalContent

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::MerchantItem;
  use Google::Checkout::General::DigitalContent;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      shipping_method       => [$method],
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      buyer_phone           => "1-111-111-1111",
                      tax_table             => [$table1, $table2],
                      merchant_calculation  => $merchant_calculation);

  my $cart = Google::Checkout::General::ShoppingCart->new(
             expiration    => "+1 month",
             private       => "Private data",
             checkout_flow => $checkout_flow);

  my $item1 = Google::Checkout::General::MerchantItem->new(
              name               => "Test item 1",
              description        => "Test description 1",
              price              => 12.34,
              quantity           => 12,
              private            => "Item #1",
              tax_table_selector => "item");

  #--
  #-- Same as MerchantItem except this is for digital delivery
  #--
  my $item2 = Google::Checkout::General::DigitalContent->new(
              name            => "Digital Content",
              description     => "For digital delivery",
              price           => 19.99,
              quantity        => 1,
              delivery_method => Google::Checkout::General::DigitalContent::EMAIL_DELIVERY
              );
  my $item3 = Google::Checkout::General::DigitalContent->new(
              name            => $item2->get_name,
              description     => $item2->get_description,
              price           => $item2->get_price,
              quantity        => 1,
              delivery_method => Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY,
              download_instruction => "Use key to login and URL to download.",
              key             => "12345",
              url             => "http://abc/download"
              );

  $cart->add_item($item1);
  $cart->add_item($item2);
  $cart->add_item($item3);

  my $response = Google::Checkout::General::GCO->new->checkout($cart);

  die $response if is_gco_error($response);

  #--
  #-- redirect URL
  #--
  print $response,"\n";

=head1 DESCRIPTION

Subclass of C<Google::Checkout::General::MerchantItem> used for digital delivery.

=over 4

=item new HASH

Constructor. Accepts the same parameter as C<Google::Checkout::General::MerchantItem>
with the additional support for digital delivery. `delivery_method' should be either
C<Google::Checkout::General::DigitalContent::EMAIL_DELIVERY> for Email delivery or
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY> for key/URL deliver.
If key/URL delivery, additional parameter for `key' or `url' must be provided.

=item get_delivery_method

Returns delivery method. Either C<Google::Checkout::General::DigitalContent::EMAIL_DELIVERY>
or C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY> or empty string
if the delivery method hasn't been set.

=item set_delivery_method METHOD

Sets the delivery method. Valid method are either C<Google::Checkout::General::DigitalContent::EMAIL_DELIVERY>
or C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>. Any other value
will clear the delivery method to an empty string.

=item get_download_instruction

Returns the download instruction. This is only useful for 
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

=item set_download_instruction INSTRUCTION

Sets the download instruction. This is only useful for
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

=item get_key

Returns key for key/URL delivery. This is only useful for
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

=item set_key

Sets the key for key/URL delivery. This is only useful for
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

Sets the price of the merchant item.

=item get_url

Returns the URL for key/URL delivery. This is only useful for
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

=item set_url URL

Sets the URL for key/URL delivery. This is only useful for
C<Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY>.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::MerchantItem

=cut

#--
#--   <digital-content>...</digital-content> 
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/date_time_string/;

use Google::Checkout::General::MerchantItem;
our @ISA = qw/Google::Checkout::General::MerchantItem/;

use constant EMAIL_DELIVERY   => "email_delivery";
use constant KEY_URL_DELIVERY => "key_url_delivery";

sub new 
{
  my ($class, %args) = @_;

  my $self = Google::Checkout::General::MerchantItem->new(%args);

  $self = bless $self => $class;

  $self->set_delivery_method($args{delivery_method});
  $self->set_download_instruction($args{download_instruction});
  $self->set_key($args{key});
  $self->set_url($args{url});

  return $self;
}

sub get_delivery_method
{
  my ($self) = @_;

  return $self->{delivery_method} || '';
}

sub set_delivery_method
{
  my ($self, $method) = @_;

  if ($method && ($method eq Google::Checkout::General::DigitalContent::EMAIL_DELIVERY ||
                  $method eq Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY)) 
  {
    $self->{delivery_method} = $method;
  }
  else
  {
    $self->{delivery_method} = '';
  }
}

sub get_download_instruction
{
  my ($self) = @_;

  return $self->{download_instruction} || '';
}

sub set_download_instruction
{
  my ($self, $instruction) = @_;

  $self->{download_instruction} = defined $instruction ? $instruction : '';
}

sub get_key
{
  my ($self) = @_;
 
  return $self->{key} || '';
}

sub set_key
{
  my ($self, $key) = @_;

  $self->{key} = defined $key ? $key : '';
}

sub get_url
{
  my ($self) = @_;

  return $self->{url} || '';
}

sub set_url
{
  my ($self, $url) = @_;

  $self->{url} = defined $url ? $url : '';
}

1;
