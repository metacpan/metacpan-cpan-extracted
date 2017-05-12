# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance::RawMaterialPrice.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Finance::RawMaterialPrice') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $gold_EUR_per_gram   = get_gold_price('dollar');
my $silver_EUR_per_gram = get_silver_price();

ok(
    ( $gold_EUR_per_gram > 0 and $gold_EUR_per_gram < 4200 ),
    "\$gold_EUR_per_gram is in the imaginable range ($gold_EUR_per_gram)"
);
ok(
    ( $silver_EUR_per_gram > 0 and $silver_EUR_per_gram < 2300 ),
    "\$silver_EUR_per_gram is in the imaginable range ($silver_EUR_per_gram)"
);
