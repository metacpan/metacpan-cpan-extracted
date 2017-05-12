package Google::Checkout::Notification::RefundAmount;

=head1 NAME

Google::Checkout::Notification::RefundAmount

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Notification::RefundAmount;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $xml = "/xml/refund_amount_notification.xml";

  #--
  #-- $xml can either be a file or a complete XML doc string
  #--
  my $refund = Google::Checkout::Notification::RefundAmount->new(xml => $xml);
  die $refund if is_gco_error $refund;

  print $refund->get_latest_refund_amount, "\n",
        $refund->get_total_refund_amount, "\n";

=head1 DESCRIPTION

Sub-class of C<Google::Checkout::Notification::GCONotification>. 
This module can be used to extract various refund information when 
the refund amount notification is received.

=over 4

=item new XML => ...
  
Constructor. Takes either a XML file or XML doc as data string. If
the XML is invalid (syntax error for example), C<Google::Checkout::General::Error> 
is returned.

=item type

Always return C<Google::Checkout::XML::Constants::REFUND_AMOUNT_NOTIFICATION>.

=item get_latest_refund_amount

Returns the latest refund amount.

=item get_total_refund_amount

Returns the total refund amount.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::GCONotification

=cut

#--
#--   <refund-amount-notification>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;

use Google::Checkout::Notification::GCONotification;
our @ISA = qw/Google::Checkout::Notification::GCONotification/;

sub type
{
  return Google::Checkout::XML::Constants::REFUND_AMOUNT_NOTIFICATION;
}

sub get_latest_refund_amount
{
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::LATEST_REFUND_AMOUNT;

  return $self->get_data->{$sstring}->{content} || 0;
}

sub get_total_refund_amount
{
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::TOTAL_REFUND_AMOUNT;

  return $self->get_data->{$sstring}->{content} || 0;
}

1;
