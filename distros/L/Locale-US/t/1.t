# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Locale::US;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $u = new Locale::US;

use Data::Dumper;
#warn Dumper ( [ $u->all_state_codes ], [ $u->all_state_names ] );


my $code  = 'AL';
my $state = 'ALABAMA';

ok (
    $u->{code2state}{$code}, $state
   );

ok (
    $u->{state2code}{$state}, $code
   );


