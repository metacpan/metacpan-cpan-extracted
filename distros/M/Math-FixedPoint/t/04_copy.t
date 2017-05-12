use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num1 = Math::FixedPoint->new('1.23');
    my $num2 = $num1;
    $num1 += 1;

    is $num1->[0], 1,   'original - sign';
    is $num1->[1], 223, 'original - value';
    is $num1->[2], 2,   'orginal - radix ';

    is $num2->[0], 1,   'copy - sign';
    is $num2->[1], 123, 'copy - value';
    is $num2->[2], 2,   'copy - radix';
}

{
    my $num1 = Math::FixedPoint->new('-1.23');
    my $num2 = $num1;
    $num1 += 2;

    is $num1->[0], 1,  'original - sign';
    is $num1->[1], 77, 'original - value';
    is $num1->[2], 2,  'orginal - radix ';

    is $num2->[0], -1,  'copy - sign';
    is $num2->[1], 123, 'copy - value';
    is $num2->[2], 2,   'copy - radix';
}

done_testing();
