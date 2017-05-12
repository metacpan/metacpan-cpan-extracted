#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Command::AddTrackingData;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- Turns it on or off to run diagnose test
#--
my $run_diagnose = 1;

my $config_path = $ARGV[0] || '../conf/GCOSystemGlobal.conf';

my $gco = Google::Checkout::General::GCO->new(config_path => $config_path);

#--
#-- Create a add trcking data command
#--
my $add_tracking = Google::Checkout::Command::AddTrackingData->new(
                   order_number    => 566858445838220,
                   carrier         => Google::Checkout::XML::Constants::DHL, 
                   tracking_number => 5678);
my $response = $gco->command($add_tracking, $run_diagnose);
die $response if is_gco_error($response);
print $response,"\n\n";
