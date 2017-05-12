#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::ChargeOrder;

use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 0;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Send the charge order command.
#--
my $charge_order = Google::Checkout::Command::ChargeOrder->new(
                   order_number => 955329663857037,
                   amount       => 23.33);
my $response = $gco->command($charge_order, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
