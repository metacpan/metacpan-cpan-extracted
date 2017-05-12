package Google::Checkout::General::ParameterizedUrl;

=head1 NAME

Google::Checkout::General::ParameterizedUrl

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::ParameterizedUrl;
  use Google::Checkout::General::MerchantCheckoutFlow;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $purls = Google::Checkout::General::ParameterizedUrl->new(
              url => 'http://www.yourcompany.com', #-- Must be properly URI escaped
              url_params => {key1 => 'value1', key2 => 'value2', key3 => 'value3'});

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      shipping_method       => [$method],
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      buyer_phone           => "1-111-111-1111",
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

This module is responsible for supporting parameterized tracking URL.

=over 4

=item new HASH

Constructor. It takes a hash as parameter with `url' being the parameterized
tracking URL. `url_params' (hash reference) supply additional URI parameters
to the tracking URL.

=item get_url

Returns tracking URL.

=item set_url

Sets the tracking URL. Please note that the URL must be properly URI escaped.

=item get_url_params

Returns all the additional tracking params as hash reference.

=item get_url_param

Given a key, returns the corresponding value in the tracking params. If
key is not found, returns an empty string.

=item set_url_param

Given a key / value pair, add them to the tracking params. If the key
already exists, it over writes the old value. Otherwise, it's added.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::MerchantCheckoutFlow

=cut

#--
#--   <parameterized-url></parameterized-url>
#--

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = {};

  #--
  #-- Note that URL *must* be properly URI escaped
  #--
  $self->{url} = $args{url};

  #--
  #-- This should be a hash reference
  #--
  $self->{url_params} = $args{url_params};

  return bless $self => $class;
}

sub get_url {
  my ($self) = @_;
  return $self->{url} || '';
}

sub set_url {
  my ($self, $url) = @_;
  $self->{url} = $url;
}

sub get_url_params {
  my ($self) = @_;
  return $self->{url_params} || {};
}

sub get_url_param {
  my ($self, $key) = @_;
  if ($self->{url_params} && defined $key) {
    if (exists $self->{url_params}->{$key}) {
      return $self->{url_params}->{$key};
    } else {
      return '';
    }
  } else {
    return '';
  }
}

sub set_url_param {
  my ($self, $key, $value) = @_;
  $self->{url_params}->{$key} = $value;
}

1;
