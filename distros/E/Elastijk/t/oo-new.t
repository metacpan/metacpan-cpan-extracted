use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Elastijk;

my $i = 0;
my $t = time;
while ($i++ <= 99999) {
    my $es = Elastijk->new;
}
my $dt = time - $t;
pass "Spent $dt seconds to construct $i objects.";
done_testing;
