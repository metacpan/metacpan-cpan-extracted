use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num1 = '1.23';
    my $num2 = '2.44';

    my $instance1 = Math::FixedPoint->new($num1);
    my $instance2 = Math::FixedPoint->new($num2);

    my $result = $instance1 + $instance2;

    is $result->[0], 1,   "$num1 + $num2 - sign";
    is $result->[1], 367, "$num1 + $num2 - value";
    is $result->[2], 2,   "$num1 + $num2 - radix";
}

{
    my $num1 = '1.23';
    my $num2 = 2;

    my $instance1 = Math::FixedPoint->new($num1);

    my $result = $instance1 + 2;

    is $result->[0], 1,   "$num1 + $num2 - sign";
    is $result->[1], 323, "$num1 + $num2 - value";
    is $result->[2], 2,   "$num1 + $num2 - radix";
}

{
    my $num1 = '1.23';
    my $num2 = 1.2355;

    my $instance1 = Math::FixedPoint->new($num1);

    my $result = $instance1 + $num2;

    is $result->[0], 1,   "$num1 + $num2 - sign";
    is $result->[1], 247, "$num1 + $num2 - value";
    is $result->[2], 2,   "$num1 + $num2 - radix";
}

{
    my $num1 = '1.23';
    my $num2 = 1.2;

    my $instance1 = Math::FixedPoint->new($num1);

    my $result = $instance1 + $num2;

    is $result->[0], 1,   "$num1 + $num2 - sign";
    is $result->[1], 243, "$num1 + $num2 - value";
    is $result->[2], 2,   "$num1 + $num2 - radix";
}

{
    my $num1 = '-1.23';
    my $num2 = 1.2;

    my $instance1 = Math::FixedPoint->new($num1);

    my $result = $instance1 + $num2;

    is $result->[0], -1, "$num1 + $num2 - sign";
    is $result->[1], 3,  "$num1 + $num2 - value";
    is $result->[2], 2,  "$num1 + $num2 - radix";
}

{
    my $num1 = '-1.23';
    my $num2 = 1.23;

    my $instance1 = Math::FixedPoint->new($num1);

    my $result = $instance1 + $num2;

    is $result->[0], 1, "$num1 + $num2 - sign";
    is $result->[1], 0, "$num1 + $num2 - value";
    is $result->[2], 2, "$num1 + $num2 - radix";
}

done_testing();
