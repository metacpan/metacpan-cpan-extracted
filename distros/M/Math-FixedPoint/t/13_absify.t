use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num      = '1.23';
    my $instance = Math::FixedPoint->new($num);
    is abs($instance), '1.23', "absify $num";
}

{
    my $num      = '0e0';
    my $instance = Math::FixedPoint->new($num);
    is abs($instance), '0', "absify $num";
}

{
    my $num      = '-.27';
    my $instance = Math::FixedPoint->new($num);
    is abs($instance), '0.27', "absify $num";
}

{
    my $num      = '-1.27';
    my $instance = Math::FixedPoint->new($num);
    is abs($instance), '1.27', "absify $num";
}

{
    my $num = '-1e-2';
    my $instance = Math::FixedPoint->new( $num, 2 );
    is abs($instance), '0.01', "absify $num";
}

done_testing();
