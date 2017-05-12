#!/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $testentry = shift or die $0.' entry_value '."\n";
my $page_name = (split /\./, $testentry)[0];

my $agent = Google::Spreadsheet::Agent->new(
                                             page_name => $page_name,
                                             agent_name => 'defaultrun',
                                             bind_key_fields => { 'testentry' => $testentry },
                                             );
$agent->run_my(sub { return 1 });
exit;
