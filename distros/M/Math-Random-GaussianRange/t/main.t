use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok( 'Math::Random::GaussianRange' );

{

    my $rh = {
        min   => 0,    
        max   => 1000,
        n     => 100, 
        round => 0, 
    };

    my $ra = generate_normal_range( $rh );

    ok( $ra );
    
    is( scalar(@$ra), 100 );

}

{
    
    my $rh = {
        min   => 0,    
        max   => 1000,
        n     => 100, 
        round => 1, 
    };

    my $ra = generate_normal_range( $rh );

    ok( $ra );    
    
    is( scalar(@$ra), 100 );
    
}

{
    
    my $rh = {
        min   => 100,    
        max   => 0,
        n     => 100, 
    };

    throws_ok    {
        my $ra = generate_normal_range( $rh );
    } 
    qr/The minimum cannot exceeed the maximum/;

    
}

{
    
    my $rh = {
        min   => 100,    
        n     => 100, 
    };

    throws_ok    {
        my $ra = generate_normal_range( $rh );
    } 
    qr/Specify a range using the min and max parameters./;

    
}

{
    
    my $rh = {
        max   => 0,
        n     => 100, 
    };

    throws_ok    {
        my $ra = generate_normal_range( $rh );
    } 
    qr/Specify a range using the min and max parameters./;

    
}

{
    
    my $rh = {
        min   => -100,
        max   => 100,
        n     => 100, 
    };

    throws_ok    {
        my $ra = generate_normal_range( $rh );
    } 
    qr/Median and SD are both null./;

    
}



done_testing();