package Google::Checkout::Command::AddTrackingData;

=head1 NAME

Google::Checkout::Command::AddTrackingData

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::AddTrackingData;
  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  #--
  #-- Create a add trcking data (DHL carrier with tracking number 5678) command
  #--
  my $add_tracking = Google::Checkout::Command::AddTrackingData->new(
                     order_number    => 156310171628413,
                     carrier         => Google::Checkout::XML::Constants::DHL,
                     tracking_number => 5678);
  my $response = $gco->command($add_tracking, $run_diagnose);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::DeliverOrder>. 
This module is used to add tracking data to an order.

=over 4

=item new ORDER_NUMBER => ..., CARRIER => ..., TRACKING_NUMBER => ...

Constructor. Takes a Google order number, a tracking number 
and a carrier.

=item to_xml

Returns the XML that will be sent to Google Checkout. 
Note that this function should not be used directly. Instead, 
it's called indirectly by the C<Google::Checkout::General::GCO> 
object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::GCO
Google::Checkout::Command::DeliverOrder

=cut

#--
#--  <add-tracking-data-order> 
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/get_valid_carrier is_gco_error/;
use Google::Checkout::XML::Constants;
use Google::Checkout::Command::DeliverOrder;
our @ISA = qw/Google::Checkout::Command::DeliverOrder/;

sub new 
{
  my ($class, @args) = @_;

  my $self = $class->SUPER::new(@args);
     $self->set_name(Google::Checkout::XML::Constants::ADD_TRACKING_DATA);

  return bless $self => $class;
}

sub to_xml
{
  my ($self, %args) = @_;

  my $carrier = get_valid_carrier($self->get_carrier);
  my $tracking_number = $self->get_tracking_number;

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_CARRIER}}) 
      if is_gco_error($carrier);

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_TRACKING_NUMBER}}) 
      unless $tracking_number;

  my $code = $self->Google::Checkout::Command::GCOCommand::to_xml(%args);

  return $code if is_gco_error($code);

  $self->add_element(name => Google::Checkout::XML::Constants::TRACKING_DATA);
  $self->add_element(name => Google::Checkout::XML::Constants::CARRIER, 
                     data => $carrier, close => 1);
  $self->add_element(name => Google::Checkout::XML::Constants::TRACKING_NUMBER, 
                     data => $tracking_number, close => 1);

  return $self->done;
}

1;
