use 5.014;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Keyword::TailRecurse 'tailrecurse';

sub testSub1 {
    my $x = 99;
    tailrecurse testSub2 ($x, @_);
}

sub testSub2 {
    return @_;
}

cmp_deeply( [ testSub1(100) ], [99, 100], "tailrecursion test to check that the recursed sub works" ); 

sub testSub3 {
    tailrecurse testSub4;
}

sub testSub4 {
    return caller;
}

is( testSub3(), "main", "The caller should be 'main' not 'testSub3' as we've tailrecursed" );


sub testSub5 {
    my ( $x ) = @_;
    
    if ( $x < 1000000 ) {
        tailrecurse testSub5 ( $x + 1 );
    } else {
        return $x;
    }
}


lives_ok { testSub5( 1 ) } "Should work fine, even if it does take a couple of seconds to run";

done_testing();
