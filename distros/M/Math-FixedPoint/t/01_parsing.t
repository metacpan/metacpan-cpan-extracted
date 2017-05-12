use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num = '1.23';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,   "$num - sign";
    is $fp->[1], 123, "$num - value";
    is $fp->[2], 2,   "$num - radix";
}

{
    my $num = '123';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,   "$num - sign";
    is $fp->[1], 123, "$num - value";
    is $fp->[2], 0,   "$num - radix";
}

{
    my $num = '.23';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,  "$num - sign";
    is $fp->[1], 23, "$num - value";
    is $fp->[2], 2,  "$num - radix";
}

{
    my $num = '9.23e1';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,   "$num - sign";
    is $fp->[1], 923, "$num - value";
    is $fp->[2], 1,   "$num - radix";
}

{
    my $num = '9.23e-1';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,   "$num - sign";
    is $fp->[1], 923, "$num - value";
    is $fp->[2], 3,   "$num - radix";
}

{
    my $num = '-123e-2';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], -1,  "$num - sign";
    is $fp->[1], 123, "$num - value";
    is $fp->[2], 2,   "$num - radix";
}

{
    my $num = '0.00';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], 1,   "$num - sign";
    is $fp->[1], 000, "$num - value";
    is $fp->[2], 2,   "$num - radix";
}

{
    my $num = '1.1243';
    my $fp = Math::FixedPoint->new( $num, 3 );
    is $fp->[1], 1124, "$num - value";
    is $fp->[2], 3,    "$num - radix";
}

{
    my $num = '1.12451';
    my $fp = Math::FixedPoint->new( $num, 3 );
    is $fp->[0], 1,    "$num - sign";
    is $fp->[1], 1125, "$num - value";
    is $fp->[2], 3,    "$num - radix";
}

{
    my $num = '1e6';
    my $fp = Math::FixedPoint->new( $num, 2 );
    is $fp->[0], 1,         "$num - sign";
    is $fp->[1], 100000000, "$num - value";
    is $fp->[2], 2,         "$num - radix";
}

{
    my $num = '-1e-2';
    my $fp  = Math::FixedPoint->new($num);
    is $fp->[0], -1, "$num - sign";
    is $fp->[1], 1,  "$num - value";
    is $fp->[2], 2,  "$num - radix";
}

done_testing();
