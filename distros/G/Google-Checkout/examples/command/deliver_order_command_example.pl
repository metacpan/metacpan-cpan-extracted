#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::DeliverOrder;

use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 1;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Create a deliver order command. Note that we 
#-- specify email should also be sent to the user.
#--
my $deliver_order = Google::Checkout::Command::DeliverOrder->new(
                    order_number => 156310171628413,
                    send_email   => 1);
my $response = $gco->command($deliver_order, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
