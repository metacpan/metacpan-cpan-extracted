use strict;
use warnings;
use Test::More;
use Math::FixedPoint;

{
    my $num      = '1.23';
    my $instance = Math::FixedPoint->new($num);
    is '' . $instance, '1.23', "stringify $num";
}

{
    my $num      = '0e0';
    my $instance = Math::FixedPoint->new($num);
    is '' . $instance, '0', "stringify $num";
}

{
    my $num = '1.236';
    my $instance = Math::FixedPoint->new( $num, 2 );
    is '' . $instance, '1.24', "stringify $num";
}

{
    my $num      = '.27';
    my $instance = Math::FixedPoint->new($num);
    is '' . $instance, '0.27', "stringify $num";
}

{
    my $num      = '-.27';
    my $instance = Math::FixedPoint->new($num);
    is '' . $instance, '-0.27', "stringify $num";
}

{
    my $num      = '-1.27';
    my $instance = Math::FixedPoint->new($num);
    is '' . $instance, '-1.27', "stringify $num";
}

{
    my $num = '0';
    my $instance = Math::FixedPoint->new( $num, 2 );
    is '' . $instance, '0.00', "stringify $num";
}

{
    my $num = '1e6';
    my $instance = Math::FixedPoint->new( $num, 2 );
    is '' . $instance, '1000000.00', "stringify $num";
}

done_testing();
