#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::AddMerchantOrderNumber;

use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 1;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Create and send the add merchant order number command
#--
my $add_merchant_order = Google::Checkout::Command::AddMerchantOrderNumber->new(
                         order_number          => 566858445838220,
                         merchant_order_number => 12345);
my $response = $gco->command($add_merchant_order, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
