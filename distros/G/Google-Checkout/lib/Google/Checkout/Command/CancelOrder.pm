package Google::Checkout::Command::CancelOrder;

=head1 NAME

Google::Checkout::Command::CancelOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::CancelOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $cancel_order = Google::Checkout::Command::CancelOrder->new(
                     order_number => 156310171628413,
                     reason       => "This is a test order");
  my $response = $gco->command($cancel_order);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. This module 
is used to cancel an order. Please note that depends on what states 
the order is in, a merchant may or may not be able to cancel the order.

=over 4

=item new ORDER_NUMBER => ..., REASON => ...

Constructor. Takes a Google order number and reason of cancelling the order.

=item get_comment 

Returns the comment of cancelling the order.

=item get_comment COMMENT

Sets the comment of cancelling the order.

=item get_reason

Returns the reason of cancelling the order.

=item set_reason

Sets the reason of cancelling the order.

=item to_xml

Return the XML that will be sent to Google Checkout. Note that this function should
not be used directly. Instead, it's called indirectly by the C<Google::Checkout::General::GCO> 
object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Command::GCOCommand

=cut

#--
#-- <cancel-order> 
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

  my $self = $class->SUPER::new(%args, name => Google::Checkout::XML::Constants::CANCEL_ORDER);
     $self->{comment} = $args{comment} || '';
     $self->{reason}  = $args{reason} || '';

  return bless $self => $class;
}

sub get_comment 
{ 
  my ($self) = @_;

  return $self->{comment};
}

sub set_comment
{
  my ($self, $comment) = @_;

  $self->{comment} = $comment if $comment;
}

sub get_reason 
{ 
  my ($self) = @_;

  return $self->{reason}; 
}

sub set_reason
{
  my ($self, $reason) = @_;

  $self->{reason} = $reason if $reason;
}

sub to_xml
{
  my ($self, %args) = @_;

  return Google::Checkout::General::Error(
    @{$Google::Checkout::General::Error::ERRORS{REQUIRE_REASON_FOR_CANCEL}}) 
      unless $self->get_reason;

  my $code = $self->SUPER::to_xml(%args);

  return $code if is_gco_error($code);

  if ($self->get_comment)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::COMMENT,
                       data => $self->get_comment,
                       close => 1);
  }

  $self->add_element(name => Google::Checkout::XML::Constants::REASON,
                     data => $self->get_reason,
                     close => 1);

  return $self->done;
}

1;
