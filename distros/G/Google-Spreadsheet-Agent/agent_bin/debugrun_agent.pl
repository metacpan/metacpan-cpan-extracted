#!/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $agent = Google::Spreadsheet::Agent->new(
                                             page_name => 'testing',
                                             agent_name => 'debugrun',
                                             bind_key_fields => { 'testentry' => 'debugtest' },
                                             );
$agent->run_my(sub { return 1 });
exit;
