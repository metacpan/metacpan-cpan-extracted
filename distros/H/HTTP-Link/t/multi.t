#!perl

use Test::More;

BEGIN {
    use_ok('HTTP::Link');
}

is(
    HTTP::Link->multi(
        A => {
            relation  => 'B',
            extension => 'C',
            anchor    => 'D',
            hreflang  => 'F',
            media     => 'G',
            title     => 'H',
        },
    ) => '<A>; rel="B C"; anchor="D"; hreflang="F"; media="G"; title="H"'
);

is(
    HTTP::Link->multi(
        A => {
            relation  => 'B',
            extension => 'C',
            anchor    => 'D',
            hreflang  => 'F',
            media     => 'G',
            title     => 'H',
        },
        I => {
            relation  => 'J',
            extension => 'K',
            anchor    => 'L',
            hreflang  => 'N',
            media     => 'O',
            title     => 'P',
        },
      ) =>
'<A>; rel="B C"; anchor="D"; hreflang="F"; media="G"; title="H", <I>; rel="J K"; anchor="L"; hreflang="N"; media="O"; title="P"'
);

is(
    HTTP::Link->multi(
        {
            A => {
                relation  => 'B',
                extension => 'C',
                anchor    => 'D',
                hreflang  => 'F',
                media     => 'G',
                title     => 'H',
            },
            I => {
                relation  => 'J',
                extension => 'K',
                anchor    => 'L',
                hreflang  => 'N',
                media     => 'O',
                title     => 'P',
            },
        }
      ) =>
'<A>; rel="B C"; anchor="D"; hreflang="F"; media="G"; title="H", <I>; rel="J K"; anchor="L"; hreflang="N"; media="O"; title="P"'
);

done_testing;
