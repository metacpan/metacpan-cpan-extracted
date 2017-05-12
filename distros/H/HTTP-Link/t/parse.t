#!perl

use Test::More;

BEGIN {
    use_ok('HTTP::Link');
}

sub test {
    my @a = HTTP::Link->parse(shift);
    my @b = @_;
    @_ = ( \@a, \@b );
    goto &Test::More::is_deeply;
}

test(
    '<A>; rel="B X"; anchor="C"; rev="D"; hreflang="E"; media="F"; title="G"',
    {
        iri       => 'A',
        relation  => 'B',
        extension => 'X',
        anchor    => 'C',
        rev       => 'D',
        hreflang  => 'E',
        media     => 'F',
        title     => 'G',
    }
);

test(
'<A>; rel="B X"; anchor="C"; rev="D"; hreflang="E"; media="F"; title="G", <I>; rel="J K"; anchor="L"; rev="M"; hreflang="N"; media="O"; title="P"',
    {
        iri       => 'A',
        relation  => 'B',
        extension => 'X',
        anchor    => 'C',
        rev       => 'D',
        hreflang  => 'E',
        media     => 'F',
        title     => 'G',
    },
    {
        iri       => 'I',
        relation  => 'J',
        extension => 'K',
        anchor    => 'L',
        rev       => 'M',
        hreflang  => 'N',
        media     => 'O',
        title     => 'P',
    }
);

test( '<A>; title*="=?UTF-8?B?Ig==?="', { iri => 'A', title => '"' } );
test( '<A>; title*="=?UTF-8?B?Pw==?="', { iri => 'A', title => '?' } );
test( '<A>; title*="=?UTF-8?B?PQ==?="', { iri => 'A', title => '=' } );

done_testing;
