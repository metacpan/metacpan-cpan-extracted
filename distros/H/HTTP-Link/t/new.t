#!perl

use Test::More;

BEGIN {
    use_ok('HTTP::Link');
}

is( HTTP::Link->new('')   => '<>' );
is( HTTP::Link->new('A')  => '<A>' );
is( HTTP::Link->new('<>') => '<<>>' );

is( HTTP::Link->new( 'A', relation => 'B' ) => '<A>; rel="B"' );
is( HTTP::Link->new( 'A', relation => [qw[ B C D E F ]] ) =>
      '<A>; rel="B C D E F"' );
is( HTTP::Link->new( 'A', relation => 'B', extension => 'C' ) =>
      '<A>; rel="B C"' );

is( HTTP::Link->new( 'A', anchor   => 'B' ) => '<A>; anchor="B"' );
is( HTTP::Link->new( 'A', hreflang => 'B' ) => '<A>; hreflang="B"' );
is( HTTP::Link->new( 'A', media    => 'B' ) => '<A>; media="B"' );
is( HTTP::Link->new( 'A', title    => 'B' ) => '<A>; title="B"' );
is( HTTP::Link->new( 'A', title => '"' ) => '<A>; title*="=?UTF-8?B?Ig==?="' );
is( HTTP::Link->new( 'A', title => '?' ) => '<A>; title*="=?UTF-8?B?Pw==?="' );
is( HTTP::Link->new( 'A', title => '=' ) => '<A>; title*="=?UTF-8?B?PQ==?="' );

is(
    HTTP::Link->new(
        'A',
        relation  => 'B',
        extension => 'C',
        anchor    => 'C',
        hreflang  => 'E',
        media     => 'F',
        title     => 'G'
    ) => '<A>; rel="B C"; anchor="C"; hreflang="E"; media="F"; title="G"'
);
is(
    HTTP::Link->new(
        'A',
        relation  => 'B',
        extension => 'C',
        anchor    => 'C',
        hreflang  => 'E',
        media     => 'F',
        title     => "\xe6\xa1\x9c"
      ) =>
'<A>; rel="B C"; anchor="C"; hreflang="E"; media="F"; title*="=?UTF-8?B?5qGc?="'
);

done_testing;
