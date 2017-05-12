use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num1 = '1.23';
    my $num2 = '2.44';

    my $instance1 = Math::FixedPoint->new($num1);
    my $instance2 = Math::FixedPoint->new($num2);

    $instance1 += $instance2;
    is $instance1->[1], 367, "$num1 += $num2 - value";
    is $instance1->[2], 2,   "$num1 += $num2 - radix";
    is $instance1->[0], 1,   "$num1 += $num2 - sign";
}

{
    my $num1 = '1.23';
    my $num2 = 1.23;

    my $instance1 = Math::FixedPoint->new($num1);

    $instance1 += $num2;

    is $instance1->[1], 246, "$num1 += $num2 - value";
    is $instance1->[2], 2,   "$num1 += $num2 - radix";
    is $instance1->[0], 1,   "$num1 += $num2 - sign";
}

{
    my $num1 = '-1.23';
    my $num2 = 1.33;

    my $instance1 = Math::FixedPoint->new($num1);

    $instance1 += $num2;

    is $instance1->[1], 10, "$num1 += $num2 - value";
    is $instance1->[2], 2,  "$num1 += $num2 - radix";
    is $instance1->[0], 1,  "$num1 += $num2 - radix";
}

{
    my $num1 = '-1.23';
    my $num2 = 1.13;

    my $instance1 = Math::FixedPoint->new($num1);

    $instance1 += $num2;

    is $instance1->[1], 10, "$num1 += $num2 - value";
    is $instance1->[2], 2,  "$num1 += $num2 - radix";
    is $instance1->[0], -1, "$num1 += $num2 - radix";
}

done_testing();
