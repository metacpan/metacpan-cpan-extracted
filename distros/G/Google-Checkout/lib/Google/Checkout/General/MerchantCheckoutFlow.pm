package Google::Checkout::General::MerchantCheckoutFlow;

=head1 NAME

Google::Checkout::General::MerchantCheckoutFlow

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::MerchantCheckoutFlow;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      shipping_method       => [$method],
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      buyer_phone           => "true",
                      tax_table             => [$table1, $table2],
                      merchant_calculation  => $merchant_calculation,
		                  analytics_data        => "SW5zZXJ0IDxhbmFseXRpY3MtZGF0YT4gdmFsdWUgaGVyZS4=",
		                  parameterized_urls    => [$purl1, $purl2]);

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

This module is responsible for writing the <merchant-checkout-flow-support> XML.

=over 4

=item new HASH

Constructor. The following arguments (passed in as hash) are supported: 
SHIPPING_METHOD, an array reference of C<Google::Checkout::General::Shipping>
or it's sub-class objects; TAX_TABLE, an array reference of 
C<Google::Checkout::General::TaxTable> objects; EDIT_CART_URL, an edit cart URL; 
CONTINUE_SHOPPING_URL, a continue shopping URL; BUYER_PHONE, the buyer's phone; 
MERCHANT_CALCULATION, a C<Google::Checkout::General::MerchantCalculations> object;
PARAMETERIZED_URLS, an array reference of C<Google::Checkout::General::ParameterizedUrl>

=item get_shipping_method

Returns the shipping methods as array reference.

=item add_shipping_method SHIPPING_METHOD

Adds another shipping method. SHIPPING_METHOD should be an object
or one of its  sub-class of C<Google::Checkout::General::Shipping>.

=item get_tax_table

Returns the tax tables as array reference.

=item add_tax_table TAX_TABLE

Adds another tax table. TAX_TABLE should be an object of 
C<Google::Checkout::General::TaxTable>.

=item get_edit_cart_url

Returns the edit cart URL.

=item set_edit_cart_url URL

Sets the edit cart URL.

=item get_continue_shopping_url

Returns the continue shopping URL.

=item set_continue_shopping_url

Sets the continue shopping URL.

=item get_buyer_phone

Gets weather or not you are requesting the buyers phone number

=item set_buyer_phone BOOLEAN

Sets weather or not you need the buyers phone number

=item get_merchant_calculation

Returns the C<Google::Checkout::General::MerchantCalculations> object.

=item set_merchant_calculation MERCHANT_CALCULATION

Sets the C<Google::Checkout::General::MerchantCalculations> object to MERCHANT_CALCULATION.

=item get_analytics_data

Returns the analytics data.

=item set_analytics_data

Sets the analytics data.

=item get_parameterized_url

Returns the C<Google::Checkout::General::ParameterizedUrls> object.

=item set_parameterzied_url

Sets the C<Google::Checkout::General::ParameterizedUrls> object.

=item get_platform_id

Returns the platform ID

=item set_platform_id ID

Sets the platform ID

=item get_parameterized_urls

Return parameterized urls as array reference

=item add_parameterized_url

Adds another parameterized url. PARAMETERIZED_URL should be an object of 
C<Google::Checkout::General::ParameterizedUrl>.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::Shipping
Google::Checkout::General::TaxTable
Google::Checkout::General::MerchantCalculations

=cut

#--
#--   <merchant-checkout-flow-support></merchant-checkout-flow-support>
#--

use strict;
use warnings;

use Google::Checkout::General::Util qw/is_shipping_method is_tax_table is_parameterized_url/;

sub new 
{
  my ($class, %args) = @_;

  my $self = {};

  if ($args{shipping_method})
  {
    push(@{$self->{shipping_method}}, $_) 
      for grep is_shipping_method($_), @{$args{shipping_method}};
  }
  if ($args{tax_table})
  {
    push(@{$self->{tax_table}}, $_) 
      for grep is_tax_table($_), @{$args{tax_table}};
  }

  $self->{edit_cart_url} = $args{edit_cart_url}
    if defined $args{edit_cart_url};

  $self->{continue_shopping_url} = $args{continue_shopping_url}
    if defined $args{continue_shopping_url};

  $self->{buyer_phone} = $args{buyer_phone}
    if defined $args{buyer_phone};

  $self->{merchant_calculation} = $args{merchant_calculation} 
    if $args{merchant_calculation};

  $self->{analytics_data} = $args{analytics_data}
    if $args{analytics_data};

  # DEPRECATED
  $self->{parameterized_url} = $args{parameterized_url}
    if $args{parameterized_url};
    
  if ($args{parameterized_urls})
  {
    push(@{$self->{parameterized_urls}}, $_) 
      for grep is_parameterized_url($_), @{$args{parameterized_urls}};
  }
  
  $self->{platform_id} = $args{platform_id}
    if defined $args{platform_id};

  return bless $self => $class;
}

sub get_shipping_method 
{ 
  my ($self) = @_;
  return $self->{shipping_method}; 
}

sub add_shipping_method
{
  my ($self, $shipping_method) = @_;

  push(@{$self->{shipping_method}}, $shipping_method)
    if is_shipping_method $shipping_method;
}

sub get_tax_table 
{ 
  my ($self) = @_;

  return $self->{tax_table}; 
}

sub add_tax_table
{
  my ($self, $tax_table) = @_;

  push(@{$self->{tax_table}}, $tax_table)
    if is_tax_table $tax_table;
}

sub get_edit_cart_url 
{ 
  my ($self) = @_;

  return $self->{edit_cart_url}; 
}

sub set_edit_cart_url
{
  my ($self, $edit_cart_url) = @_;

  $self->{edit_cart_url} = $edit_cart_url 
    if defined $edit_cart_url;
}

sub get_continue_shopping_url 
{ 
  my ($self) = @_;

  return $self->{continue_shopping_url}; 
}

sub set_continue_shopping_url
{
  my ($self, $continue_shopping_url) = @_;

  $self->{continue_shopping_url} = $continue_shopping_url
    if defined $continue_shopping_url;
}

sub get_buyer_phone 
{ 
  my ($self) = @_;

  return $self->{buyer_phone}; 
}

sub set_buyer_phone
{
  my ($self, $phone) = @_;

  $self->{buyer_phone} = $phone if defined $phone;
}

sub get_merchant_calculation 
{ 
  my ($self) = @_;

  return $self->{merchant_calculation}; 
}

sub set_merchant_calculation
{
  my ($self, $merchant_calculation) = @_;

  $self->{merchant_calculation} = $merchant_calculation 
    if $merchant_calculation;
}

sub get_analytics_data 
{
  my ($self) = @_;

  return $self->{analytics_data};
}

sub set_analytics_data
{
  my ($self, $analytics_data) = @_;

  $self->{analytics_data} = $analytics_data if $analytics_data;
}

# DEPRECATED
sub get_parameterized_url 
{
  my ($self) = @_;
  
  return $self->{parameterized_url};
}

# DEPRECATED
sub set_parameterized_url 
{
  my ($self, $purl) = @_;

  $self->{parameterized_url} = $purl if $purl;
}

sub get_platform_id
{
  my ($self) = @_;

  return $self->{platform_id};
}

sub set_platform_id
{
  my ($self, $platform_id) = @_;

  $self->{platform_id} = $platform_id if defined $platform_id;
}

sub get_parameterized_urls
{
  my ($self) = @_;
  
  return $self->{parameterized_urls};
}

sub add_parameterized_url
{
  my ($self, $parameterized_url) = @_;

  push(@{$self->{parameterized_urls}}, $parameterized_url)
    if is_parameterized_url $parameterized_url;
}

1;
