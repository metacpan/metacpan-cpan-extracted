# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-btce.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Finance::btce') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#
#These keys are for testing purposes only. No real money is stored in this account.

my %btupublic = %{Finance::btce::BTCtoUSD()};
ok( defined($btupublic{'avg'}), 'BTCtoUSD() works');

my %ltbpublic = %{Finance::btce::LTCtoBTC()};
ok( defined($ltbpublic{'avg'}), 'LTCtoBTC() works');

my %ltupublic = %{Finance::btce::LTCtoUSD()};
ok( defined($ltupublic{'avg'}), 'LTCtoUSD() works');

my $btce = Finance::btce->new({ 'apikey' => "PEMFNC9A-U3E5Y3J5-6V054246-9W3GXUVY-3EJGJZU3", 'secret' => "05f1e5b0a88e16b8b1490732f77a976c68f0fc8243411b6f0fa25fe857792e30",});

ok( defined($btce) && ref $btce eq 'Finance::btce', 'new() works');

my %getinfotest = %{$btce->getInfo()};

ok( $getinfotest{'success'} eq '1');

#my %gettranstest = %{$btce->TransHistory()};

#ok ( $gettranstest{'success'} eq '1');
