#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Notification::RefundAmount;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User normally gets the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/refund_amount_notification.xml";

my $refund = Google::Checkout::Notification::RefundAmount->new(xml => $xml);
die $refund if is_gco_error $refund;

print <<__REFUND_AMOUNT__;
#-------------------------#
#     Refund amount       #
#-------------------------#
Latest refund amount: @{[$refund->get_latest_refund_amount]}
Total refund amount:  @{[$refund->get_total_refund_amount]}

__REFUND_AMOUNT__
