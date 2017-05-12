package Google::Checkout::Command::RefundOrder;

=head1 NAME

Google::Checkout::Command::RefundOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::RefundOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $refund_order = Google::Checkout::Command::RefundOrder->new(
                     order_number => 156310171628413,
                     amount       => 5,
                     comment      => "Refund to user",
                     reason       => "User wants to refund");
  my $response = $gco->command($refund_order);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to refund an order.

=over 4

=item new ORDER_NUMBER => ..., AMOUNT => ..., COMMENT => ..., REASON => ...

Constructor. Takes a Google order number, amount to refund, comment
and reason for the refund. Please note that a refund might not be
possible depends on what states the order is in.

=item get_amount

Returns the refund amount.

=item set_amount AMOUNT

Sets the refund amount.

=item get_comment

Returns the comment.

=item set_comment COMMENT

Sets the comment.

=item get_reason

Returns the reason for the refund.

=item set_reason REASON

Sets the reason for the refund.

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
#--  <refund-order> 
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;

sub new 
{
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(%args, name => Google::Checkout::XML::Constants::REFUND_ORDER);
     $self->{amount}  = $args{amount}  || 0;
     $self->{comment} = $args{comment} || '';
     $self->{reason}  = $args{reason}  || '';

  return bless $self => $class;
}

sub get_amount 
{ 
  my ($self) = @_;

  return $self->{amount}; 
}

sub set_amount
{
  my ($self, $amount) = @_;

  $self->{amount} = $amount || 0;
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
    @{$Google::Checkout::General::Error::ERRORS{REQUIRE_REASON_FOR_REFUND}}) 
      unless $self->get_reason;

  my $code = $self->SUPER::to_xml(%args);

  return $code if is_gco_error($code);

  if ($self->get_amount)
  {
    my $sstring = Google::Checkout::XML::Constants::CURRENCY_SUPPORTED;

    my $currency_supported = '';
    if ($args{gco}->reader()) {
      $currency_supported = $args{gco}->reader()->get($sstring);
    } else {
      $currency_supported = $args{gco}->{__currency_supported};
    }

    $self->add_element(close => 1,
                       name => Google::Checkout::XML::Constants::AMOUNT, 
                       data => $self->get_amount,
                       attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY,
                                $currency_supported]);
  }
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
