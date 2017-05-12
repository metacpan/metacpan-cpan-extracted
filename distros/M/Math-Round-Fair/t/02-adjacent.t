#!perl
use warnings;
use strict;
use Test::More tests => 2;

BEGIN { $ENV{MATH_ROUND_FAIR_DEBUG} = 1 }

BEGIN { use_ok 'Math::Round::Fair', qw/round_fair/ }

my @w = (0.95, 0.65, 0.41, 0.99);
my $ok=1;
for(1..50){
    my @a = round_fair(3, @w);
    if($a[3] > 1.5){
	undef $ok;
	last;
    }
}
ok($ok);

