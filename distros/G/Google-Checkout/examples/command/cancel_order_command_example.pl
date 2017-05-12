#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::CancelOrder;

use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 0;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Create a cancel order command. Note that a reason is required.
#--
my $cancel_order = Google::Checkout::Command::CancelOrder->new(
                   order_number => 955329663857037,
                   amount       => 23.33,
                   reason       => "Cancel test order");
my $response = $gco->command($cancel_order, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
