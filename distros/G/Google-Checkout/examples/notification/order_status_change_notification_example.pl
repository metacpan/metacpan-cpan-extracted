#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Notification::OrderStateChange;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User will normally get the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/order_state_change_notification.xml";

my $order_state_change = Google::Checkout::Notification::OrderStateChange->new(xml => $xml);
die $order_state_change if is_gco_error $order_state_change;

my $new_ful_state = $order_state_change->get_new_fulfillment_order_state;
my $old_ful_state = $order_state_change->get_previous_fulfillment_order_state;
my $new_fin_state = $order_state_change->get_new_financial_order_state;
my $old_fin_state = $order_state_change->get_previous_financial_order_state;
my $reason        = $order_state_change->get_reason;

print <<__ORDER_STATE_CHANGE__;
#-------------------------#
#   Order state change    #
#-------------------------#
New fulfillment state: $new_ful_state
old fulfillment state: $old_ful_state
New financial state:   $new_fin_state
Old financial state:   $old_fin_state
Reason:                $reason


__ORDER_STATE_CHANGE__
