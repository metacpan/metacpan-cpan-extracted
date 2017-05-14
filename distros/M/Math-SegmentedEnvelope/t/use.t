use strict;
use warnings;
use Math::SegmentedEnvelope;
use Test::More tests => 20;

my $e = Math::SegmentedEnvelope->new;
my $dev = 0.0001; # max error

ok($e->segments > 1, 'create '.$e->segments);
ok(abs($e->at(-0.5) - $e->at(0.5)) < $dev, 'neg fold');
ok(abs($e->at(1.5) - $e->at(0.5)) < $dev, 'over wrap');

ok(abs($e->duration - 1) < $dev, 'duration');

$e->is_hold(1);

ok(abs($e->at(0) - $e->at(-$e->duration-$dev)) < $dev, 'neg hold');
ok(abs($e->at(-$e->duration) - $e->at(-2*$e->duration)) < $dev, 'neg hold every');
ok(abs($e->at($e->duration) - $e->at(2*$e->duration)) < $dev, 'over hold');

ok(abs($e->at(0) - $e->at(-$e->duration - 0.3)) < $dev, 'neg hold min');
ok(abs($e->at($e->duration) - $e->at($e->duration + 0.1)) < $dev, 'over hold min');

my $s = $e->static;
ok(abs($s->(0) - $s->(-$e->duration-$dev)) < $dev, 'st neg hold');
ok(abs($s->(-$e->duration) - $s->(-2*$e->duration)) < $dev, 'st neg hold every');
ok(abs($s->($e->duration) - $s->($e->duration*2)) < $dev, 'st over hold');

ok(abs($s->(0) - $s->(-$e->duration - 0.3)) < $dev, 'st neg hold min');
ok(abs($s->($e->duration) - $s->($e->duration + 0.1)) < $dev, 'st over hold min');


$e->is_hold(0);
$e->is_fold_over(1);

ok(abs($e->at(0.7) - $e->at(1.3)) < $dev, 'over fold');
ok(abs($e->at(-1.3) - $e->at(0.7)) < $dev, 'neg over fold');

$e->is_wrap_neg(1);

ok(abs($e->at(-1.3) - $e->at(0.3)) < $dev, 'neg wrap over fold');

$s = $e->static;
ok(abs($s->(0.3) - $e->at(0.3)) < $dev, 'st eq oo');
ok(abs($s->(-1.3) - $s->(0.3)) < $dev, 'st neg wrap over fold');

$e->segments;
$e->levels(map $_ * 3, $e->levels);
$e->durs(map $_ * 1, $e->durs);
$e->curves(map $_ + 1, $e->curves);
$e->level(
    $e->segments,
    $e->level(0, $e->level(0) - 1)
);
$e->curve(0, 3);
$e->dur(0, 0.2);
$e->duration;
$e->normalize_duration;

$e = Math::SegmentedEnvelope->new(
    [
        [0,1,0.8,0.7,0],
        [0.1,0.2,0.4,0.3],
        [1,2,1,-3]
    ],
    is_morph => 1,
    is_hold => 0,
    is_fold_over => 1,
    is_wrap_neg => 1
);
$e->at(rand);
$e->table(1024);
$s = $e->static;
$s->(rand);

ok(1,'creation');
