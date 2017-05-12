package Google::Checkout::Notification::ChargebackAmount;

=head1 NAME

Google::Checkout::Notification::ChargebackAmount

=head1 SYNOPSIS

  use Google::Checkout::Notification::ChargebackAmount;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $xml = "/xml/chargeback_amount_notification.xml";

  #--
  #-- $xml can either be a file or a complete XML doc string
  #--
  my $charge_amount = Google::Checkout::Notification::ChargebackAmount->new(xml => $xml);
  die $charge_amount if is_gco_error $charge_amount;

  print $charge_amount->get_latest_chargeback_amount,"\n",
        $charge_amount->get_total_chargeback_amount,"\n";

=head1 DESCRIPTION

Sub-class of C<Google::Checkout::Notification::GCONotification>. 
This module can be used to extract the latest and the total charge 
back amount when the chargeback amount notification is received.

=over 4

=item new XML => ...

Constructor. Takes either a XML file or XML doc as data string. If
the XML is invalid (syntax error for example), C<Google::Checkout::General::Error> 
is returned.

=item type

Always return C<Google::Checkout::XML::Constants::CHARGE_BACK_NOTIFICATION>.

=item get_latest_chargeback_amount

Returns the latest charge back amount.

=item get_total_chargeback_amount

Returns the total charge back amount.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::GCONotification

=cut

#--
#--   <chargeback-amount-notification>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;

use Google::Checkout::Notification::GCONotification;
our @ISA = qw/Google::Checkout::Notification::GCONotification/;

sub type
{
  return Google::Checkout::XML::Constants::CHARGE_BACK_NOTIFICATION;
}

#--
#-- <latest-chargeback-amount> ... </latest-chargeback-amount>
#--
sub get_latest_chargeback_amount
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::LATEST_CHARGEBACK_AMOUNT}
                        ->{content} || 0;
}

#--
#-- <total-chargeback-amount> ... </total-chargeback-amount>
#--
sub get_total_chargeback_amount
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::TOTAL_CHARGEBACK_AMOUNT}
                        ->{content} || 0;
}

1;
