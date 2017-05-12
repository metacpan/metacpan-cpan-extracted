package Google::Checkout::General::MerchantCalculationCallback;

=head1 NAME

Google::Checkout::General::MerchantCalculationCallback

=head1 SYNOPSIS

  use Google::Checkout::General::MerchantCalculationCallback;

  my $callback = Google::Checkout::General::MerchantCalculationCallback->new(
                 xml => "XML data from Gcogle Checkout");

  print $callback->get_buyer_id(),
        $callback->get_buyer_language(),"\n";

=head1 DESCRIPTION

Sub-class of C<Google::Checkout::Notification::NewOrder>. This module
can be used to handle merchant calculation callbacks.
When a merchant sets up and receives a merchant calculation
callback, XML data is passed from Google Checkout. The
XML data contains information about the new order
as well as buyer detail, this module can be used to extract
any information from the XML file.

=over 4

=item new XML => ...

Constructor. Takes the XML data passed from Google Checkout.

=item type

Always return C<Google::Checkout::XML::Constants::MERCHANT_CALCULATION_CALLBACK>.

=item get_buyer_id

Returns the buyer ID.

=item get_buyer_language

Returns the buyer language.

=item get_order_number

Returns the Google order number.

=item should_tax

Returns 1 if you should tax. Otherwise, returns 0.

=item get_shipping_methods

Returns an array reference of shipping methods.

=item get_merchant_code_strings

Returns an array reference of merchant code strings.

=item get_merchant_code_strings_with_pin

Same as `get_merchant_code_strings' except this supports the 
new gift certificate format where customers can enter a PIN as well.
It returns the result in an array reference where each element is
a hash reference with `code' being the code string and `pin' being
the PIN # the customer entered during checkout.

=item get_addresses

Returns an array reference of addresses. Each element
of the element in the array is a hash reference with 
keys: 'id' (ID), 'country_code' (Country code),
'city' (City)), 'postal_code' (Postal code), 'region' (Region)

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::NewOrder

=cut

#--
#--   <merchant-calculation-callback>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;

use Google::Checkout::Notification::NewOrder;
our @ISA = qw/Google::Checkout::Notification::NewOrder/;

sub type
{
  return Google::Checkout::XML::Constants::MERCHANT_CALCULATION_CALLBACK;
}

sub get_buyer_id
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::BUYER_ID} || '';
}

sub get_buyer_language
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::BUYER_LANGUAGE} || '';
}

sub should_tax
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::CALCULATE}->
                          {Google::Checkout::XML::Constants::TAX} eq 'true' ? 1 : 0;
}

sub get_shipping_methods
{
  my ($self) = @_;

  my $ref  = $self->get_data->{Google::Checkout::XML::Constants::CALCULATE}->
                              {Google::Checkout::XML::Constants::SHIPPING}->
                              {Google::Checkout::XML::Constants::METHOD} || {};
  return [keys %$ref];
}

sub get_merchant_code_strings
{
  my ($self) = @_;

  my $ref  = $self->get_data->{Google::Checkout::XML::Constants::CALCULATE}->
                              {Google::Checkout::XML::Constants::MERCHANT_CODE_STRINGS}->
                              {Google::Checkout::XML::Constants::MERCHANT_CODE_STRING} || [];

  return [map values %$_, @$ref];
}

sub get_merchant_code_strings_with_pin
{
  my ($self) = @_;

  my $ref  = $self->get_data->{Google::Checkout::XML::Constants::CALCULATE}->
                              {Google::Checkout::XML::Constants::MERCHANT_CODE_STRINGS}->
                              {Google::Checkout::XML::Constants::MERCHANT_CODE_STRING} || [];

  #--
  #-- a little clean up
  #--
  my @result = ();
  for my $i (@$ref) {
    push (@result, {code => defined $i->{code} ? $i->{code} : '', 
                    pin  => defined $i->{pin}  ? $i->{pin}  : ''});
  }

  return \@result;
}

sub get_addresses
{
  my ($self) = @_;

  my $ref  = $self->get_data->{Google::Checkout::XML::Constants::CALCULATE}->
                              {Google::Checkout::XML::Constants::ADDRESSES}->
                              {Google::Checkout::XML::Constants::ANONYMOUS_ADDRESS} || {};

  my @ret;
  while(my($id, $address) = each %$ref)
  {
    my $country_code = $address->{Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE} || '';
    my $city         = $address->{Google::Checkout::XML::Constants::BUYER_CITY}         || '';
    my $postal_code  = $address->{Google::Checkout::XML::Constants::BUYER_POSTAL_CODE}  || '';
    my $region       = $address->{Google::Checkout::XML::Constants::BUYER_REGION}       || '';

    push @ret, {id           => $id,
                country_code => $country_code,
                city         => $city,
                postal_code  => $postal_code,
                region       => $region};
  }
  return \@ret;
}

1;
