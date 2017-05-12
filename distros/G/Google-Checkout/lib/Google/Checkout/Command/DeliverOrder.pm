package Google::Checkout::Command::DeliverOrder;

=head1 NAME

Google::Checkout::Command::DeliverOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::DeliverOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $deliver_order = Google::Checkout::Command::DeliverOrder->new(
                      order_number => 156310171628413,
                      send_email   => 1);
  my $response = $gco->command($deliver_order);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to deliver an order.

=over 4

=item new ORDER_NUMBER => ..., SEND_EMAIL => ...

Constructor. Takes a Google order number. If SEND_EMAIL is true, an email
will also be sent to the user.

=item get_carrier

Returns the carrier that will be used to deliver the order.

=item set_carrier CARRIER

Sets the carrier that will be used to deliver the order.

=item get_tracking_number

Returns the tracking number provided by the carrier.

=item set_tracking_number TRACKING_NUMBER

Sets the tracking number provided by the carrier.

=item should_send_email

Returns true if email should be sent to user. Otherwise, 
returns false.

=item set_send_email FLAG

Sets the flag to send optional email to user or not.

=item to_xml

Return the XML that will be sent to Google Checkout. Note that 
this function should not be used directly. Instead, it's called 
indirectly by the C<Google::Checkout::General::GCO> object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Command::GCOCommand

=cut

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/get_valid_carrier is_gco_error/;

use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;

sub new 
{
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(%args, name => Google::Checkout::XML::Constants::DELIVER_ORDER);
     $self->{carrier}         = $args{carrier};
     $self->{tracking_number} = $args{tracking_number} || '';
     $self->{send_email}      = $args{send_email} ? 'true' : 'false';

  return bless $self => $class;
}

sub get_carrier 
{ 
  my ($self) = @_;

  return $self->{carrier};
}

sub set_carrier
{
  my ($self, $carrier) = @_;

  $self->{carrier} = $carrier if $carrier;
}

sub get_tracking_number 
{
  my ($self) = @_;
 
  return $self->{tracking_number}; 
}

sub set_tracking_number
{
  my ($self, $tracking_number) = @_;

  $self->{tracking_number} = $tracking_number if $tracking_number;
}

sub should_send_email 
{ 
  my ($self) = @_;

  return $self->{send_email}; 
}

sub set_send_email
{
  my ($self, $should_send_email) = @_;

  $self->{send_email} = $should_send_email ? 'true' : 'false';
}

sub to_xml
{
  my ($self, @args) = @_;

  my $carrier = get_valid_carrier($self->get_carrier || '');
  my $tracking_number = $self->get_tracking_number;

  my $code = $self->SUPER::to_xml(@args);

  return $code if is_gco_error($code);

  $self->add_element(name => Google::Checkout::XML::Constants::SEND_EMAIL, 
                     data => $self->should_send_email, close => 1);

  $self->add_element(name => Google::Checkout::XML::Constants::TRACKING_DATA) 
    if (!is_gco_error($carrier) || $tracking_number);

  $self->add_element(name => Google::Checkout::XML::Constants::CARRIER, 
                     data => $carrier, close => 1) if (!is_gco_error($carrier));

  $self->add_element(name => Google::Checkout::XML::Constants::TRACKING_NUMBER,     
                     data => $self->get_tracking_number,
                     close => 1) 
    if $self->get_tracking_number;

  $self->close_element() if (!is_gco_error($carrier) || $tracking_number);

  return $self->done;
}

1;
