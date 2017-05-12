use FindBin;
use lib $FindBin::Bin.'/../../lib';
use Google::Spreadsheet::Agent;
use strict;
use warnings;

my $conf_file = $FindBin::Bin.'/../../config/agent.conf.yml';
die "No conf_file ${conf_file}\n" unless (-e $conf_file);

my $testentry = shift or die $0.' test_entry_value '."\n";
my $agent = Google::Spreadsheet::Agent->new(
                                             config_file => $conf_file,
                                             page_name => 'testing',
                                             agent_name => 'conflicted',
                                             debug => 1,
                                             bind_key_fields => { 'testentry' => $testentry },
                                            conflicts_with => { 'conflicting' => 1 }
                                             );

$agent->run_my(sub { return 1 }); # This just passes
exit;
