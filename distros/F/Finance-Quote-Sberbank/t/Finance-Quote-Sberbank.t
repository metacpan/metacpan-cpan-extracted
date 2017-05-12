# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-Quote-Sberbank.t'

#########################

use encoding 'utf8';
use Test::More;

if(not $ENV{ONLINE_TEST}) {
	plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

plan tests => 5;

use_ok('Finance::Quote');
use_ok('Finance::Quote::Sberbank');

my $quoter = Finance::Quote->new("Sberbank");

ok(defined $quoter, "created");

my %info = $quoter->fetch("sberbank", "SBRF.PD");

ok(%info, "fetched");

ok($info{"SBRF.PD", "name"}, "palladium");

