use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num1 = 1.23;
    my $num2 = -1.23;

    my $instace1 = Math::FixedPoint->new($num1);
    my $instace2 = Math::FixedPoint->new($num2);

    is $instace1 <=> $instace2, 1, "$num1 <=> $num2";
    is $instace1 cmp $instace2, 1, "$num1 cmp $num2";
}

{
    my $num1 = '1.00';
    my $num2 = 1;

    my $instace1 = Math::FixedPoint->new($num1);
    my $instace2 = Math::FixedPoint->new($num2);

    is $instace1 <=> $instace2, 0, "$num1 <=> $num2";
    is $instace1 cmp $instace2, 1, "$num1 cmp $num2";
}

{
    my $num1 = '1.00';
    my $num2 = 1;

    my $instace1 = Math::FixedPoint->new($num1);

    is $instace1 <=> $num2, 0, "$num1 <=> $num2";
    is $instace1 cmp $num2, 1, "$num1 cmp $num2";
}

{
    my $num1 = 2.23;
    my $num2 = '2.230';

    my $instace1 = Math::FixedPoint->new($num1);
    my $instace2 = Math::FixedPoint->new($num2);

    is $instace1 <=> $instace2, 0, "$num1 <=> $num2";
    is $instace1 cmp $instace2, -1, "$num1 cmp $num2";
}

{
    my $num1 = -1.23;
    my $num2 = 1.23;

    my $instace1 = Math::FixedPoint->new($num1);
    my $instace2 = Math::FixedPoint->new($num2);

    is $instace1 <=> $instace2, -1, "$num1 <=> $num2";
    is $instace1 cmp $instace2, -1, "$num1 cmp $num2";
}

done_testing();
