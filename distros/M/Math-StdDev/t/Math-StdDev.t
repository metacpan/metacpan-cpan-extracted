# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-Uncompress-Untar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Math::StdDev') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $d=new Math::StdDev(10, 12, 23, 23, 16, 23, 21, 16);

ok($d->mean()==18, "Mean OK");
ok((($d->variance()-4.89897948556636)**2<0.00000000001), "variance sensibleish");
ok((($d->variance()!=$d->sampleVariance)) , "sampleVariance sensibleish");

my $d2=new Math::StdDev(10, 12, 23, 23, 16, 23, 21);
$d2->Update(16);

ok((($d2->mean()-18)**2<0.00000000001), "Mean 2 OK at:" . $d2->mean());
ok((($d2->variance()-4.89897948556636)**2<0.00000000001), "variance 2 sensibleish");
ok((($d2->variance()!=$d->sampleVariance)) , "sampleVariance 2 sensibleish");

#warn $d2->mean();
#warn $d2->variance();
#warn $d2->sampleVariance();
#warn (($d2->variance()-4.89897948556636)**2);


done_testing();

  # or
  #          use Test::More;   # see done_testing()
  #
  #                   require_ok( 'Some::Module' );
  #
  #                            # Various ways to say "ok"
  #                                     ok($got eq $expected, $test_name);
