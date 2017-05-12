use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num1 = '1.23';
    my $num2 = '3.1245';

    my $instance = Math::FixedPoint->new($num1);
    $instance /= $num2;

    is $instance->[0], 1,  "$num1 /= $num2 - sign";
    is $instance->[1], 39, "$num1 /= $num2 - value";
    is $instance->[2], 2,  "$num1 /= $num2 - radix";
}

{
    my $num1 = '-3.1245';
    my $num2 = '1.26';

    my $instance1 = Math::FixedPoint->new($num1);
    my $instance2 = Math::FixedPoint->new($num2);
    $instance1 /= $instance2;

    is $instance1->[0], -1,    "$num1 /= $num2 - sign";
    is $instance1->[1], 24798, "$num1 /= $num2 - value";
    is $instance1->[2], 4,     "$num1 /= $num2 - radix";
}

{
    my $num1 = '-3.1245';
    my $num2 = '0';

    my $instance1 = Math::FixedPoint->new($num1);

    eval { $instance1 /= $num2 };
    like $@, qr/Illegal division by zero at/, "$num1 /= $num2 - value";
}

{
    my $num1 = '-3.1245';
    my $num2 = '0e0';

    my $instance1 = Math::FixedPoint->new($num1);
    my $instance2 = Math::FixedPoint->new($num2);

    eval { $instance1 /= $instance2 };
    like $@, qr/Illegal division by zero at/, "$num1 /= $num2 - value";
}

done_testing();
