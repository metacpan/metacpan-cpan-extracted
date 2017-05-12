package Google::Checkout::Command::AddMerchantOrderNumber;

=head1 NAME

Google::Checkout::Command::AddMerchantOrderNumber

=head1 SYNOPSIS

  use Google::Checkout::General::GCO
  use Google::Checkout::Command::AddMerchantOrderNumber;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $add_merchant_order = Google::Checkout::Command::AddMerchantOrderNumber->new(
                           order_number          => 156310171628413,
                           merchant_order_number => 12345);
  my $response = $gco->command($add_merchant_order, $run_diagnose);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to add custom merchant order number.

=over 4

=item new ORDER_NUMBER => ..., MERCHANT_ORDER_NUMBER=> ...

Constructor. Takes a Google order number and a custom merchant order number.

=item get_merchant_order_number

Returns the merchant order number.

=item set_merchant_order_number MERCHANT_ORDER_NUMBER

Sets the merchant order number.

=item to_xml

Return the XML that will be sent to Google Checkout. Note that this function should
not be used directly. Instead, it's called indirectly by the C<GCO> object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::GCO
Google::Checkout::Command::DeliverOrder

=cut

#--
#-- <add-merchant-order-number> 
#--

use strict;
use warnings;

use utf8;
use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/is_gco_error/;
use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;
use Google::Checkout::XML::Constants;

sub new 
{
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(
               %args, 
               name => Google::Checkout::XML::Constants::ADD_MERCHANT_ORDER_NUMBER);

     $self = bless $self => $class;
     $self->set_merchant_order_number($args{merchant_order_number});

  return $self;
}

sub get_merchant_order_number 
{ 
  my ($self) = @_;

  return $self->{merchant_order_number};
}

sub set_merchant_order_number
{
  my ($self, $merchant_order_number) = @_;

  $merchant_order_number ||= '';

  #--
  #-- limited to 255 characters
  #--
  $merchant_order_number = substr($merchant_order_number,0,255)
    if length($merchant_order_number) > 255;

  $self->{merchant_order_number} = $merchant_order_number;
}

sub to_xml
{
  my ($self, %args) = @_;

  my $order = $self->get_merchant_order_number;

  return Google::Checkout::General::Error->new(
           @{$Google::Checkout::General::Error::ERRORS{MISSING_ORDER_NUMBER}})
    unless $order && length($order);

  my $code = $self->SUPER::to_xml(%args);

  return $code if is_gco_error($code);

  $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_ORDER_NUMBER, 
                     data => $order);

  return $self->done;
}

1;
