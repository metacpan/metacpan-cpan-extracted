#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::Util qw/is_gco_error/;
use Google::Checkout::Notification::Factory qw/get_notification_object/;

#--
#-- Test for all notification
#--
my @notification_xml = 
     ("xml/charge_amount_notification.xml",
      "xml/chargeback_amount_notification.xml",
      "xml/merchant_calculation_callback.xml",
      "xml/new_order_notification.xml",
      "xml/order_state_change_notification.xml",
      "xml/refund_amount_notification.xml",
      "xml/risk_information_notification.xml");

my $xml_header = '<?xml version="1.0" encoding="UTF-8"?>';
#--
#-- Memory test cases. This is normal usage as the 
#-- XML normally comes from Checkout as post param
#--
push(@notification_xml, $xml_header .
                        '<charge-amount-notification xmlns="">' .
                        '</charge-amount-notification>');
push(@notification_xml, $xml_header .
                        '<chargeback-amount-notification xmlna="">' .
                        '</chargeback-amount-notification>');
push(@notification_xml, $xml_header .
                        '<merchant-calculation-callback xmlns="">' .
                        '</merchant-calculation-callback>');
push(@notification_xml, $xml_header .
                        '<new-order-notification xmlns="">' .
                        '</new-order-notification>');
push(@notification_xml, $xml_header .
                        '<order-state-change-notification xmlns="">' .
                        '</order-state-change-notification>');
push(@notification_xml, $xml_header .
                        '<refund-amount-notification xmlns="">' .
                        '</refund-amount-notification>');
push(@notification_xml, $xml_header .
                        '<risk-information-notification xmlns="">' .
                        '</risk-information-notification>');

for my $xml (@notification_xml)
{
  my $object = get_notification_object(xml => $xml);

  die $object if is_gco_error $object;

  print "$xml => " . $object->type . "\n";
}
