use Test::More tests => 1;
use Test::FailWarnings;
use Test::Exception;

use Math::Function::Interpolator;

subtest "general checks" => sub {
    plan tests => 4;
    throws_ok { Math::Function::Interpolator->new() } qr/points are required to do interpolation/,
        "cannot create interpolator object without data point";

    my $interpolator = Math::Function::Interpolator->new(
        points => {
            1 => 2,
            2 => 3,
            3 => 4,
            4 => 5,
            5 => 6
        });

    is($interpolator->linear(1.5),    2.5, 'Linear Interpolation');
    is($interpolator->quadratic(2.3), 3.3, 'Quadratic Interpolation');
    is($interpolator->cubic(4.5),     5.5, 'Cubic Interpolation');
};

