use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 2 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $agent_name = 'instantiate';
my $page_name = 'testing';
my $bind_key_fields = { 'testentry' => 'test' };

ok my $google_agent = Google::Spreadsheet::Agent->new(
                   agent_name => $agent_name,
                   page_name => $page_name,
                   bind_key_fields => $bind_key_fields
                 );
isa_ok $google_agent => 'Google::Spreadsheet::Agent';
