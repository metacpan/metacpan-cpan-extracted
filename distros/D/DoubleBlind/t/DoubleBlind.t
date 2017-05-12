# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DoubleBlind.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use DoubleBlind;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $o = DoubleBlind::shuffle 4,0;
$o = [sort @$o];
ok("@$o" eq "0 1 2 3");

$o = DoubleBlind::shuffle 6;
$o = [sort @$o];
ok("@$o" eq "1 2 3 4 5 6");

$o = (DoubleBlind::good_number 6, 3)**2;
ok(int($o) =~ /006$/);

sub pr($$$) { my($n,$i,$l) = @_; $l = int($l*$l); ok($l =~ /$i$/) }

DoubleBlind::process_shuffled \&pr, 3, 1;
