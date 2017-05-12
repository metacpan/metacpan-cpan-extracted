package Google::Checkout::Command::ChargeOrder;

=head1 NAME

Google::Checkout::Command::ChargeOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::ChargeOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $charge_order = Google::Checkout::Command::ChargeOrder->new(
                     order_number => 156310171628413,
                     amount       => 12.34);
  my $response = $gco->command($charge_order);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to charge an order.

=over 4

=item new ORDER_NUMBER => ..., AMOUNT => ...

Constructor. Takes a Google order number and the amount to charge.

=item get_amount

Returns the amount to charge.

=item set_amount AMOUNT

Sets the amount to charge.

=item to_xml

Return the XML that will be sent to Google Checkout. Note that this 
function should not be used directly. Instead, it's called indirectly 
by the C<Google::Checkout::General::GCO> object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Command::GCOCommand

=cut

#--
#--  <charge-order> 
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;

sub new 
{
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(%args, name => Google::Checkout::XML::Constants::CHARGE_ORDER);
     $self->{amount} = $args{amount} || 0;

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

sub to_xml
{
  my ($self, %args) = @_;

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

  return $self->done;
}

1;
