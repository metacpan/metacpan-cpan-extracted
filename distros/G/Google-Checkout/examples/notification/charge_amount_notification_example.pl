#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Notification::ChargeAmount;

use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User normally gets the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/charge_amount_notification.xml";

my $charge_amount = Google::Checkout::Notification::ChargeAmount->new(xml => $xml);
die $charge_amount if is_gco_error $charge_amount;

print <<__CHARGE_AMOUNT__;
#-------------------------#
#     Charge amount       #
#-------------------------#
Latest charge amount: @{[$charge_amount->get_latest_charge_amount]}
Total charge amount:  @{[$charge_amount->get_total_charge_amount]}


__CHARGE_AMOUNT__
