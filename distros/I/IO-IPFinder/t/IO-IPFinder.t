# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-IPFinder.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::Exception;

use Test::Exception;

# or if you don't need Test::More


use Test::More tests => 7;

BEGIN {
    use_ok('IO::IPFinder')

};

my $ipfinder;

$ipfinder = IO::IPFinder->new();

dies_ok {$ipfinder->getAddressInfo("1.1.1.1..1.1")} 'expecting to die';
dies_ok {$ipfinder->getAsn("as")} 'Invalid ASN number';
dies_ok {$ipfinder->getFirewall('DZ','adasd')} 'Invalid Format supported format https://ipfinder.io/docs/?shell#firewall';
dies_ok {$ipfinder->getFirewall('asdasd','adasd')} 'Invalid Firewall string please use AS number or ISO 3166-1 alpha-2 country';
dies_ok {$ipfinder->getDomain('as')} 'Invalid Domain name';
dies_ok {$ipfinder->getDomainHistory('as')} 'Invalid Domain name';


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

