#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::ProcessOrder;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 1;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Create a process order command
#--
my $process_order = Google::Checkout::Command::ProcessOrder->new(
                    order_number => 156310171628413);
my $response = $gco->command($process_order, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
