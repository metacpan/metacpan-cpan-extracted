#!perl
use strict ;

# Initial simple object tests

# change 'tests => 1' to 'tests => last_test_to_print';
use Data::Dumper ;

use Test::More tests => 1;

##### Linux::DVB::DVBT::Advert

## Check module loads ok
BEGIN { use_ok('Linux::DVB::DVBT::TS') };

### Check class method
#Linux::DVB::DVBT->debug(10) ;
#my $debug = Linux::DVB::DVBT->debug() ;
#is($debug, 10);
#Linux::DVB::DVBT->debug(2) ;

