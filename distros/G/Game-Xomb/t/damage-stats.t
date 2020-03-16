#!perl
#
# how much damage do the damage functions dish out? (this is not a full
# fightsim, it only considers one damage event which could be an attack
# or for acid burn a movevement cost; attacks can miss, etc)
#
#  cpanm App::Prove
#  XOMB_STATS=1 prove t/damage-stats.t

use 5.24.0;
use warnings;
use Game::Xomb;
use Scalar::Util qw(looks_like_number);
use Statistics::Lite qw(statshash);
use Test::Most;

my $trials = 1000;

my $count     = keys %Game::Xomb::Damage_From;
my $testcount = $count * 3 + 9;

plan tests => $testcount;

Game::Xomb::init_jsf(int rand 2**32);

my $hero = Game::Xomb::make_player();

my %args = (
    acidburn => [qw/10/],    # $duration, default
    falling  => [qw//],      # smaller body does not matter to Gravity
    plspash  => [qw//],
);

my @outcomes;

SKIP: {
    skip "no stats without XOMB_STATS set", $testcount
      unless $ENV{XOMB_STATS};

    for my $name (sort { $a cmp $b } keys %Game::Xomb::Damage_From) {
        # duplicates '@' damage stats
        next if $name eq 'attackby';

        my $fn = $Game::Xomb::Damage_From{$name};
        if ($name eq 'plburn') {
            tally($fn, "$name$_", $_) for 1 .. 5;
        } else {
            tally($fn, $name, $args{$name}->@*);
        }
    }
    diag "sample damage - mean sd [min,max]:\n", @outcomes;
}

sub tally {
    my ($fn, $name, @rest) = @_;
    my $ret = $fn->([], @rest);
    # was there somewhat viable output from the fn?
    ok looks_like_number($ret);
    is $ret, int $ret;

    $name = $Game::Xomb::Thingy{$name}->[Game::Xomb::DISPLAY]
      if exists $Game::Xomb::Thingy{$name};

    my @ret   = map { $fn->([], @rest) } 1 .. $trials;
    my %stats = statshash @ret;
    $stats{$_} = sprintf "%.2f", $stats{$_} for qw/mean stddev/;
    push @outcomes,
      sprintf "DAMAGE $name "
      . join(' ', map { "$_ $stats{$_}" } qw/mean stddev min max mode/) . "\n";

    # it isn't good to be negative (because that would heal the target)
    ok $stats{min} >= 0;
}
