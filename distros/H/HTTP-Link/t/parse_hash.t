#!perl

use Test::More;

BEGIN {
    use_ok('HTTP::Link');
}

sub test {
    my %a = HTTP::Link->parse_hash(shift);

    #use Data::Dumper;
    #diag Dumper(\%a);
    my %b = @_;
    @_ = ( \%a, \%b );
    goto &Test::More::is_deeply;
}

test(
    '<A>; rel="B X"; anchor="C"; rev="D"; hreflang="E"; media="F"; title="G"',
    A => {
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
    <<'EOT',
<A>;
rel="B X";
anchor="C";
rev="D";
hreflang="E";
media="F";
title="G";
,
<I>
;rel="J K"
;anchor="L"
;rev="M"
;hreflang="N"
;media="O"
;title="P"
EOT
    A => {
        relation  => 'B',
        extension => 'X',
        anchor    => 'C',
        rev       => 'D',
        hreflang  => 'E',
        media     => 'F',
        title     => 'G',
    },
    I => {
        relation  => 'J',
        extension => 'K',
        anchor    => 'L',
        rev       => 'M',
        hreflang  => 'N',
        media     => 'O',
        title     => 'P',
    }
);

00 && test(<<'EOT');
</TheBook/chapter2>;
rel="previous"; title*=UTF-8'de'letztes%20Kapitel,
</TheBook/chapter4>;
rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel
EOT

done_testing;
