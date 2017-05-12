#!/usr/bin/perl -w
use strict;

use Google::Checkout::Notification::ChargebackAmount;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User noramlly gets the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/chargeback_amount_notification.xml";

my $chargeback = Google::Checkout::Notification::ChargebackAmount->new(xml => $xml);
die $chargeback if is_gco_error $chargeback;

print <<__CHARGE_BACK__;
#-------------------------#
#      charge back        #
#-------------------------#
Latest chargeback amount: @{[$chargeback->get_latest_chargeback_amount]}
Total chargeback amount:  @{[$chargeback->get_total_chargeback_amount]}


__CHARGE_BACK__
