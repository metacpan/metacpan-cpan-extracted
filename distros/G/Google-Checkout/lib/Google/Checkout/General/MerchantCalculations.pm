package Google::Checkout::General::MerchantCalculations;

=head1 NAME

Google::Checkout::General::MerchantCalculations

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::MerchantCheckoutFlow;
  use Google::Checkout::General::MerchantCalculations;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $merchant_calculation = Google::Checkout::General::MerchantCalculations->new(
                             url          => "http://callback/url",
                             coupons      => 1,
                             certificates => 1);

  my $checkout_flow = Google:::Checkout::General::MerchantCheckoutFlow->new(
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

  $cart->add_item($item1);
  $cart->add_item($item2);

  my $response = Google::Checkout::General::GCO->new->checkout($cart);

  die $response if is_gco_error($response);

  #--
  #-- redirect URL
  #--
  print $response,"\n";

=head1 DESCRIPTION

This module is responsible for writing the <merchant-calculations>
XML element.

=over 4

=item new URL => ..., COUPONS => ..., CERTIFICATES => ...

Constructor. The URL argument should be a link for merchant calculation.
The COUPONS and CERTIFICATES arguments should be either a true or false
value to signal whether coupons and gift certificates are supported or not.

=item get_url

Returns the callback URL.

=item set_url URL

Sets the callback URL.

=item get_coupons

Returns the string "true" if coupons are supported.
Otherwise, returns the string "false".

=item set_coupons FLAG

Enable (if FLAG is true) or disable (if FLAG is false)
coupon support.

=item get_certificates

Returns the string "true" if gift certificates are supported.
Otherwise, returns the string "false".

=item set_certificates FLAG

Enable (if FLAG is true) or disable (if FLAG is false)
gift certificate support.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

#--
#--  <merchant-calculations> 
#--

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = {url          => $args{url} || '',
              coupons      => $args{coupons} ? 'true' : 'false',
              certificates => $args{certificates} ? 'true' : 'false'};

  return bless $self => $class;
}

sub get_url 
{ 
  my ($self) = @_;

  return $self->{url}; 
}

sub set_url
{
  my ($self, $url) = @_;

  $self->{url} = $url if $url;
}

sub get_coupons 
{ 
  my ($self) = @_;

  return $self->{coupons}; 
}

sub set_coupons
{
  my ($self, $coupons) = @_;

  $self->{coupons} = $coupons ? 'true' : 'false';
}

sub get_certificates 
{ 
  my ($self) = @_;

  return $self->{certificates}; 
}

sub set_certificates
{
  my ($self, $certificates) = @_;

  $self->{certificates} = $certificates ? 'true' : 'false';
}

1;
