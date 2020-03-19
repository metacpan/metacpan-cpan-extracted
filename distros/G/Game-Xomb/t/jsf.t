#!perl
#
# bespoke RNG, bespoke tests

use 5.24.0;
use warnings;
use Game::Xomb;
use Test::Most;

plan tests => 1;

# can it at least flip coins to some degree of accuracy?
my $maxerr = 0.1;
my $seeds  = 100;
my $rolls  = 100;
my $true   = 0;
for my $seed (1 .. $seeds) {
    Game::Xomb::init_jsf(int rand 2**32);
    for (1 .. $rolls) {
        $true += Game::Xomb::coinflip;
    }
}
my $total = $seeds * $rolls;
my $offby = abs($true - $total / 2) / $total;
ok $offby < $maxerr or diag "HEADS $true of $total err $offby";
