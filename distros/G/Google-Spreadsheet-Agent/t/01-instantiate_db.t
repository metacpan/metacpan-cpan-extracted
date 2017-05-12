use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent::DB;

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

ok my $google_db = Google::Spreadsheet::Agent::DB->new();
isa_ok $google_db => 'Google::Spreadsheet::Agent::DB';
