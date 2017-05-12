use FindBin;
use Test::More;
use Google::Spreadsheet::Agent::Runner;

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

my $page_name = 'testing';
my $bind_key_fields = { 'testentry' => 'test' };

ok my $agent_runner = Google::Spreadsheet::Agent::Runner->new();
isa_ok $agent_runner => 'Google::Spreadsheet::Agent::Runner';

