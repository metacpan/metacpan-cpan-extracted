package Google::Checkout::Command::SendBuyerMessage;

=head1 NAME

Google::Checkout::Command::SendBuyerMessage

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::SendBuyerMessage;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $send_message = Google::Checkout::Command::SendBuyerMessage->new(
                     order_number => 156310171628413,
                     message      => "Message to buyer",
                     send_email   => 1);
  my $response = $gco->command($send_message);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to send messages to buyer.

=over 4

=item new ORDER_NUMBER => ..., MESSAGE => ..., SEND_EMAIL => ...

Constructor. Takes a Google order number, message to send to user and
whether or not email should also be sent to the buyer as well.

=item get_message

Returns the message.

=item set_message MESSAGE

Sets the message to be sent to the buyer.

=item should_send_email

Returns whether or not email should also be sent to the buyer.

=item set_send_email FLAG

Sets the flag to send email to the buyer.

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

#--
#--  <send-buyer-message> 
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;

use Google::Checkout::General::Error;

sub new 
{
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(
               %args, 
               name => Google::Checkout::XML::Constants::SEND_BUYER_MESSAGE);

  $self = bless $self => $class;
  $self->set_message($args{message});
  $self->set_send_email($args{send_email});

  return $self;
}

sub get_message 
{ 
  my ($self) = @_;

  return $self->{message}; 
}

sub set_message
{
  my ($self, $message) = @_;

  $self->{message} = $message if $message;
}

sub should_send_email 
{ 
  my ($self) = @_;

  return $self->{should_send_email}; 
}

sub set_send_email
{
  my ($self, $should_send_email) = @_;

  $self->{should_send_email} = $should_send_email ? 'true' : 'false';
}

sub to_xml
{
  my ($self, @args) = @_;

  my $message = $self->get_message;

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_MESSAGE}}) unless $message;

  my $code = $self->SUPER::to_xml(@args);

  return $code if is_gco_error($code);

  $self->add_element(name => Google::Checkout::XML::Constants::MESSAGE, 
                     data => $message, close => 1);

  $self->add_element(name => Google::Checkout::XML::Constants::SEND_EMAIL, 
                     data => $self->should_send_email, close => 1);

  return $self->done;
}

1;
