#!/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $testentry = shift or die $0.' entry_value '."\n";

my $agent = Google::Spreadsheet::Agent->new(
                                             page_name => 'testing',
                                             agent_name => 'sleepbetween',
                                             bind_key_fields => { 'testentry' => $testentry },
                                             );
$agent->run_my(sub { return 1 });
exit;
