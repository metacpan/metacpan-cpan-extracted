package Google::Checkout::General::MerchantCalculationResults;

=head1 NAME

Google::Checkout::General::MerchantCalculationResults

=head1 SYNOPSIS

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::XML::Writer>. This module can be use to
write the <merchant-calculation-results> XML after a 
<merchant-calculation-callback> is received. 

=over 4

=item new GCO => ..., MERCHANT_CALCULATION_RESULT => ...

Constructor. The GCO argument should be an object of C<Google::Checkout::General::GCO>
and MERCHANT_CALCULATION_RESULT should be an array reference
of C<Google::Checkout::General::MerchantCalculationResult> objects.

=item get_merchant_calculation_result

Returns the array reference of C<Google::Checkout::General::MerchantCalculationResult>.

=item add_merchant_calculation_result MCRESULT

Adds another MCRESULT (C<Google::Checkout::General::MerchantCalculationResult>).

=item done

Returns the XML.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::XML::Writer
Google::Checkout::General::MerchantCalculationResult

=cut

#--
#--   <merchant-calculation-results>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/format_tax_rate/;

use Google::Checkout::XML::Writer;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new
{
  my ($class, %args) = @_;

  delete $args{root};

  my $self = $class->SUPER::new(%args);

  $self->{gco} = $args{gco};

  my $schema = Google::Checkout::XML::Constants::XML_SCHEMA;

  my $xml_schema = '';
  if ($args{gco}->reader()) {
    $xml_schema = $args{gco}->reader()->get($schema);
  } else {
    $xml_schema = $args{gco}->{__xml_schema};
  }

  $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_CALCULATION_RESULTS,
                     attr => [xmlns => $xml_schema]);
  $self->add_element(name => Google::Checkout::XML::Constants::RESULTS);

  #--
  #-- If there is any merchant calculation result, add them now
  #-- This should be an array reference because we can have multiple result
  #--
  $self->{merchant_calculation_result} = $args{merchant_calculation_result}
    if $args{merchant_calculation_result};

  return bless $self => $class;
}

sub get_merchant_calculation_result 
{ 
  my ($self) = @_;

  return $self->{merchant_calculation_result} || []; 
}

sub add_merchant_calculation_result
{
  my ($self, $result) = @_;

  push(@{$self->{merchant_calculation_result}}, $result) if $result;
}

sub done
{
  my ($self) = @_;

  my $currency = Google::Checkout::XML::Constants::CURRENCY_SUPPORTED;

  my $currency_supported = '';
  if ($self->{gco}->reader()) {
    $currency_supported = $self->{gco}->reader->get($currency);
  } else {
    $currency_supported = $self->{gco}->{__currency_supported};
  }

  for my $result (@{$self->get_merchant_calculation_result})
  {
    $self->add_element(
      name => Google::Checkout::XML::Constants::RESULT,
      attr => [Google::Checkout::XML::Constants::SHIPPING_NAME => $result->get_shipping_name,
               Google::Checkout::XML::Constants::ADDRESS_ID => $result->get_address_id ]);

    if ($result->has_total_tax)
    {
      $self->add_element(
         name => Google::Checkout::XML::Constants::TOTAL_TAX,
         attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY =>
                  $currency_supported],
         data => $result->get_total_tax, close => 1);
    }

    if ($result->has_shipping_rate)
    {
      $self->add_element(
         name => Google::Checkout::XML::Constants::SHIPPING_RATE,
         attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY => 
                  $currency_supported],
         data => $result->get_shipping_rate, close => 1);
    }

    if ($result->has_shippable)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::SHIPPALBE,
                         data => $result->is_shippable, close => 1);
    }

    if ($result->has_merchant_code_result)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_CODE_RESULTS);

      $self->_handle_coupon_certificate($result, 1) 
        if $result->has_coupon_result;

      $self->_handle_coupon_certificate($result, 0) 
        if $result->has_certificate_result;

      $self->close_element();
    }

    $self->close_element();
  }

  return $self->SUPER::done;
}

#-- PRIVATE --#

sub _handle_coupon_certificate
{
  my ($self, $result, $for_coupon) = @_;

  $self->add_element(
           name => $for_coupon ? Google::Checkout::XML::Constants::COUPON_RESULT :
                                 Google::Checkout::XML::Constants::GIFT_CERTIFICATE_RESULT);

  $self->add_element(name => Google::Checkout::XML::Constants::VALID,
                     data => $for_coupon ? $result->is_coupon_valid :
                                           $result->is_certificate_valid, 
                     close => 1);

  $self->add_element(name => Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CODE,
                     data => $for_coupon ? $result->get_coupon_code :
                                           $result->get_certificate_code, 
                     close => 1);

  my $currency_supported = $self->{gco}->reader() ?
                           $self->{gco}->reader()->get(Google::Checkout::XML::Constants::CURRENCY_SUPPORTED) :
                           $self->{gco}->{__currency_supported};

  if ($for_coupon && $result->has_coupon_calculated_amount)
  {
    $self->add_element(
      name => Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CALCULATED_AMOUNT,
      attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY => $currency_supported],
      data => $result->get_coupon_amount, close => 1);
  }
  elsif ($result->has_certificate_calculated_amount)
  {
    $self->add_element(
      name => Google::Checkout::XML::Constants::GIFT_CERTIFICATE_CALCULATED_AMOUNT,
      attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY => $currency_supported],
      data => $result->get_certificate_amount, close => 1);
  }

  if ($for_coupon && $result->has_coupon_message)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::MESSAGE,
                       data => $result->get_coupon_message, close => 1);
  }
  elsif ($result->has_certificate_message)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::MESSAGE,
                       data => $result->get_certificate_message, close => 1);
  }

  $self->close_element();

}

1;
