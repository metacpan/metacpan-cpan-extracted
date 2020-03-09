#!perl
#
# how much damage do the damage functions dish out?
#  cpanm App::Prove
#  XOMB_STATS=1 prove t/damage-stats.t

use 5.24.0;
use warnings;
use Game::Xomb;
use Scalar::Util qw(looks_like_number);
use Test::Most;

my $trials = 1000;

my $count     = keys %Game::Xomb::Damage_From;
my $testcount = $count * 3 + 3;

plan tests => $testcount;

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
            tally($fn, "$name$_", $_) for 1 .. 3;
        } else {
            tally($fn, $name, $args{$name}->@*);
        }
    }
    diag "sample damage - mean sd [min,max]:\n", @outcomes;
}

sub mean {
    my ($ref) = @_;
    my $N     = $ref->@*;
    my $sum   = 0;
    my $min   = ~0;
    my $max   = -1;
    for my $x ($ref->@*) {
        $sum += $x;
        if    ($x < $min) { $min = $x }
        elsif ($x > $max) { $max = $x }
    }
    return $sum / $N, $min, $max;
}

sub sd {
    my ($ref, $mean) = @_;
    return sqrt mean([ map { ($_ - $mean)**2 } $ref->@* ]);
}

sub tally {
    my ($fn, $name, @rest) = @_;
    my $ret = $fn->([], @rest);
    # was there somewhat viable output from the fn?
    ok looks_like_number($ret);
    is $ret, int $ret;

    $name = $Game::Xomb::Thingy{$name}->[Game::Xomb::DISPLAY]
      if exists $Game::Xomb::Thingy{$name};

    my @ret = map { $fn->([], @rest) } 1 .. $trials;
    my ($mean, $min, $max) = mean(\@ret);
    my $sd = sd(\@ret, $mean);
    push @outcomes, sprintf "DAMAGE %s %.2f %.2f [%d,%d]\n", $name, $mean,
      $sd, $min, $max;

    # it isn't good to be negative
    ok $min >= 0;
}
