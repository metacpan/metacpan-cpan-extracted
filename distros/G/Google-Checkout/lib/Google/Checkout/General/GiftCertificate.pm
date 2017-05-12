package Google::Checkout::General::GiftCertificate;

=head1 NAME

Google::Checkout::General::GiftCertificate

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::GiftCertificate;
  use Google::Checkout::General::MerchantCalculations;
  use Google::Checkout::General::MerchantCheckoutFlow;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $gift_certificate = Google::Checkout::General::GiftCertificate->new(
                         accepted => 1, name => 'My company', pin => 123456789);

  my $merchant_calculation = Google::Checkout::General::MerchantCalculations->new(
                             url => 'http://callback/url', certificates => $gift_certificate);

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      merchant_calculation  => $merchant_calculation);

  my $cart = Google::Checkout::General::ShoppingCart->new(
             expiration    => "+1 month",
             private       => "Private data",
             checkout_flow => $checkout_flow);

  $cart->add_item($item1);
  $cart->add_item($item2);

  my $response = $gco->checkout($cart);

  die $response if is_gco_error($response);

  #--
  #-- redirect URL
  #--
  print $response,"\n";

=head1 DESCRIPTION

Support gift certificates.

=over 4

=item new accepted => [1 or 0], name => 'name of the gift certificate', pin => [require PIN or not]

Constructor. `accepted' should be a true or false value specifying to support 
gift certificate or not. If `accepted' is false, `name' and `pin' are both ignored.
If `accepted' is true, `name' specify the name of the gift certificate. This is 
what the user will see next to the text field where the customer is expected to 
enter the gift certificate number. If `pin' is true, it tells Checkout that the
customer must enter a PIN with the gift certificate. 

=item set_accepted

Sets to accept gift certification or not.

=item get_accepted

Returns true if gift certificate could be used or false otherwise.

=item set_name

Sets the name of the gift certificate.

=item get_name

Returns the name of the gift certificate.

=item set_pin

Sets the PIN for the gift certificate.

=item get_pin

Returns the PIN of the gift certificate.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

#--
#-- <gift-certificate-support> ... </gift-certificate-support>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;

sub new 
{
  my ($class, %args) = @_;

  my $self = {name     => defined $args{name} ? $args{name} : '',
              pin      => defined $args{pin}  ? $args{pin}  : '',
              accepted => defined $args{accepted} ? $args{accepted} : 0};

  return bless $self => $class;
}

sub get_accepted 
{
  my ($self) = @_;

  return $self->{accepted};
}

sub set_accepted
{
  my ($self, $accepted) = @_;

  $self->{accepted} = defined $accepted ? $accepted : 0;
}

sub get_name 
{
  my ($self) = @_;

  return $self->{name};
}

sub set_name
{
  my ($self, $name) = @_;

  $self->{name} = defined $name ? $name : "";
}

sub get_pin
{
  my ($self) = @_;

  return $self->{pin};
}

sub set_pin
{
  my ($self, $pin) = @_;

  $self->{pin} = defined $pin ? $pin : '';
}

1;
