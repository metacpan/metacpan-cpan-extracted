# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mysql-Backup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use LWP::UserAgent;
BEGIN { use_ok('Finance::Currency::Convert::Custom') };

my @currencies = ('EUR','GBP','AUD','CAD','BRL','DKK','HKD','KRW','NOK','SEK','CHF','TWD');

my $converter = new Finance::Currency::Convert::Custom;



foreach my $currency (@currencies){
#warn $currency;
$converter->updateRate($currency, "USD");
my $rate = $converter->convert(1, $currency, "USD"); 
#warn $currency."to USD: ".$rate;
my $ok =0;
$ok = 1 if $rate >0;
ok($ok,$currency."to USD: ".$rate);
}

print "done.\n\n";
 







#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

