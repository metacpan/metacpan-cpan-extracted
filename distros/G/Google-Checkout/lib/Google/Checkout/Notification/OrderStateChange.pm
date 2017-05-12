package Google::Checkout::Notification::OrderStateChange;

=head1 NAME

Google::Checkout::Notification::OrderStateChange

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Notification::OrderStateChange;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $xml = "/xml/order_state_change_notification.xml";

  #--
  #-- $xml can either be a file or a complete XML doc string
  #--
  my $state_change = Google::Checkout::Notification::OrderStateChange->new(xml => $xml);
  die $state_change if is_gco_error $state_change;

  print $state_change->get_new_fulfillment_order_state, "\n",
        $state_change->get_previous_fulfillment_order_state, "\n",
        $state_change->get_new_financial_order_state, "\n", 
        $state_change->get_previous_financial_order_state, "\n",
        $state_change->get_reason,"\n";

=head1 DESCRIPTION

Sub-class of C<google::Checkout::Notification::GCONotification>. 
This module can be used to extract various state change information 
when the order state change notification is received.

=over 4

=item new XML => ...

Constructor. Takes either a XML file or XML doc as data string. If
the XML is invalid (syntax error for example), C<Google::Checkout::General::Error> 
is returned.

=item type

Always return C<Google::Checkout::XML::Constants::ORDER_STATE_CHANGE_NOTIFICATION>.

=item get_new_fulfillment_order_state

Returns the new fulfillment order state.

=item get_new_financial_order_state

Returns the new financial order state.

=item get_previous_fulfillment_order_state

Returns the previous filfillment order state.

=item get_previous_financial_order_state

Returns the previous financial order state.

=item get_reason

Returns the reason for the state change.

=back

=cut 

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::GCONotification

=cut

#--
#--   <order-state-change-notification>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;

use Google::Checkout::Notification::GCONotification;
our @ISA = qw/Google::Checkout::Notification::GCONotification/;

sub type
{
  return Google::Checkout::XML::Constants::ORDER_STATE_CHANGE_NOTIFICATION;
}

sub get_new_fulfillment_order_state
{
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::NEW_FULFILLMENT_ORDER_STATE;

  return $self->get_data->{$sstring} || '';
}

sub get_new_financial_order_state
{ 
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::NEW_FINANCIAL_ORDER_STATE;

  return $self->get_data->{$sstring} || '';
}

sub get_previous_fulfillment_order_state
{ 
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::PREVIOUS_FULFILLMENT_ORDER_STATE;

  return $self->get_data->{$sstring} || '';
}

sub get_previous_financial_order_state
{
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::PREVIOUS_FINANCIAL_ORDER_STATE;

  return $self->get_data->{$sstring} || '';
}

sub get_reason
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::REASON} || '';
}

1;
