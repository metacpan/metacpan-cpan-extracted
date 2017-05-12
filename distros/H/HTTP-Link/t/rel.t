#!perl

use Test::More;

BEGIN {
    use_ok('HTTP::Link');
}

is( HTTP::Link->rel( 'A', 'B' => 'C' ) => '<A>; rel="B C"' );
is(
    HTTP::Link->rel(
        'A',
        'B'      => 'C',
        anchor   => 'C',
        hreflang => 'E',
        media    => 'F',
        title    => 'G'
    ) => '<A>; rel="B C"; anchor="C"; hreflang="E"; media="F"; title="G"'
);

done_testing;
