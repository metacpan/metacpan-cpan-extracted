#!/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $conf_file = $FindBin::Bin.'/../../config/agent.conf.yml';
die "No conf_file ${conf_file}\n" unless (-e $conf_file);

my $agent = Google::Spreadsheet::Agent->new(
                                            config_file => $conf_file,
                                            page_name => 'testing',
                                            agent_name => 'agentbinrun',
                                            bind_key_fields => { 'testentry' => 'agentbintest' },
                                            );
$agent->run_my(sub { return 1 });
exit;
