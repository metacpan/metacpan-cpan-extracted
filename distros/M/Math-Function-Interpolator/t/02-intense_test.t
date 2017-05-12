use Test::More;
use Test::FailWarnings;
use Test::Exception;

use Math::Function::Interpolator;
use Math::Function::Interpolator::Linear;
use Math::Function::Interpolator::Quadratic;
use Math::Function::Interpolator::Cubic;

subtest "closest_three_points" => sub {
    plan tests => 9;
    my $o = Math::Function::Interpolator->new(points => {1 => 2});
    my @points = (2, 3, 5, 1, 40, 89, 90, 99, 91);
    my ($first, $second, $third) = $o->closest_three_points(6, \@points);
    is($first,  5,  "first number is correct for seek in_between(@points)");
    is($second, 40, "second number is correct for seek in_between(@points)");
    is($third,  89, "third number is correct for seek in_between(@points)");
    ($first, $second, $third) = $o->closest_three_points(0.2, \@points);
    is($first,  1, "first number is correct for seek smaller than min(@points)");
    is($second, 2, "second number is correct for seek smaller than min(@points)");
    is($third,  3, "third number is correct for seek smaller than min(@points)");
    ($first, $second, $third) = $o->closest_three_points(100, \@points);
    is($first,  90, "first number is correct for seek larger than max(@points)");
    is($second, 91, "second number is correct for seek larger than max(@points)");
    is($third,  99, "third number is correct for seek larger than max(@points)");
};

subtest "general checks for linear" => sub {
    plan tests => 4;
    my $o;
    lives_ok { $o = Math::Function::Interpolator::Linear->new(points => {2 => 3, 4 => 5.5}) } "can instantiate object with 2 points";
    lives_ok { $o->linear(2.4) } "can linear given an X";
    throws_ok { $o->linear('abc') } qr/sought\S+ must be a number/, "dies when X is not a number";
    throws_ok { Math::Function::Interpolator::Linear->new(points => {2 => 3,})->linear(1) } qr/cannot interpolate with fewer than 2 data points/,
        "cannot linear linear equation with one data point";
};

subtest "verify linear interpolation and extrapolation" => sub {
    plan tests => 4;
    my $o = Math::Function::Interpolator::Linear->new(
        points => {
            1 => 3,
            2 => 4.5,
            3 => 6
        });
    is($o->linear(2.4), 5.1,  "correctly interpolate y given x=2.4");
    is($o->linear(1.4), 3.6,  "correctly interpolate y given x=1.4");
    is($o->linear(3.5), 6.75, "correctly extrapolate y given x=3.6");
    is($o->linear(0.5), 2.25, "correctly extrapolate y given x=0.5");
};

subtest "general checks for quadratic" => sub {
    plan tests => 4;
    my $o;
    lives_ok { $o = Math::Function::Interpolator::Quadratic->new(points => {2 => 3, 4 => 5.5, 6 => 8}) } "can instantiate object with 3 points";
    lives_ok { $o->quadratic(2.4) } "can quadratic given an X";
    throws_ok { $o->quadratic('abc') } qr/sought\S+ must be a number/, "dies when X is not a number";
    throws_ok { Math::Function::Interpolator::Quadratic->new(points => {2 => 3, 4 => 5})->quadratic(1) }
    qr/cannot interpolate with fewer than 3 data points/,
        "cannot solve quadratic equation with two data point";
};

subtest "verify quadratic interpolation and extrapolation" => sub {
    plan tests => 2;
    my $points = {
        6  => 11,
        2  => 3,
        -2 => 19,
    };
    my $o = Math::Function::Interpolator::Quadratic->new(points => $points);
    is($o->quadratic(2.4), 2.72, "correctly interpolate y given x=2.4");
    $points->{4} = 7;
    my $o_new = Math::Function::Interpolator::Quadratic->new(points => $points);
    lives_ok { $o_new->quadratic(2.4) } "can solve quadratic equation with 4 data points ";
};

subtest "general checks for cubic" => sub {
    plan tests => 4;
    my $o;
    lives_ok { $o = Math::Function::Interpolator::Cubic->new(points => {2 => 3, 4 => 5.5, 6 => 8, 7 => 9, 10 => 14}) }
    "can instantiate object with 5 points";
    lives_ok { $o->cubic(2.4) } "can cubic given an X";
    throws_ok { $o->cubic('abc') } qr/sought\S+ must be a numeric/, "dies when X is not a number";
    throws_ok { Math::Function::Interpolator::Cubic->new(points => {2 => 3, 4 => 5, 2 => 6, 4 => 11})->cubic(1) }
    qr/cannot interpolate with fewer than 5 data points/, "cannot cubic equation with four data point";
};

subtest "cubic interpolation compared to Bloomberg" => sub {
    plan tests => 8;
    my $points = {
        95    => 0.2780,
        97.5  => 0.2670,
        100   => 0.2563,
        102.5 => 0.2461,
        105   => 0.2364
    };
    my $bb = {
        96  => 0.2736,
        97  => 0.2692,
        98  => 0.2649,
        99  => 0.2606,
        100 => 0.2563,
        101 => 0.2521,
        102 => 0.2481,
        103 => 0.2441,
        104 => 0.2402
    };

    my $o = Math::Function::Interpolator::Cubic->new(points => $points);
    foreach my $num (96 .. 104) {
        next if grep { $_ == $num } keys %$points;
        my $test = $o->cubic($num);
        my $diff = abs($test - $bb->{$num});
        cmp_ok($diff, "<", 0.0001, "match Bloomberg's interpolation for moneyness[$num] on DAX");
    }
};

subtest "cubic extrapolation" => sub {
    plan tests => 6;
    my $points = {
        95    => 0.2780,
        97.5  => 0.2670,
        100   => 0.2563,
        102.5 => 0.2461,
        105   => 0.2364
    };
    my $o = Math::Function::Interpolator::Cubic->new(points => $points);
    lives_ok { $o->cubic(80) } "can extrapolate";
    my $first  = $o->cubic(94);
    my $second = $o->cubic(93);
    my $third  = $o->cubic(90);
    cmp_ok($first,  "<", $second, "linear extrapolation. In this case, linear increment");
    cmp_ok($second, "<", $third,  "linear extrapolation. In this case, linear increment");
    lives_ok { $o->cubic(110) } "can extrapolate";
    $first  = $o->cubic(106);
    $second = $o->cubic(107);
    $third  = $o->cubic(110);
    cmp_ok($first,  ">", $second, "linear extrapolation. In this case, linear decrement");
    cmp_ok($second, ">", $third,  "linear extrapolation. In this case, linear decrement");
};

done_testing;
