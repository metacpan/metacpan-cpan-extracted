#!/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $input = shift or die $0.' <entry>'."\n";
my ($page, $entry) = split /\./, $input;

my $agent = Google::Spreadsheet::Agent->new(
                                            page_name => $page,
                                            agent_name => 'dryrun',
                                            bind_key_fields => { 'testentry' => $entry },
                                            );
$agent->run_my(sub { return 1 });
exit;
