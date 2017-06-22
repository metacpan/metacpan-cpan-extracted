#! /usr/bin/env perl

use 5.014; use warnings;
use lib qw< dlib ../dlib >;
use Multilingual::Code;

my @word_list = qw( catalyst catabolism cat dogma catalepsis);

for my $word1 (@word_list) {
    for my $word2 (@word_list) {
        ANSI_C {
            /* Find percentage of vowels to letters */
            char* next1 = $word1;
            char* next2 = $word2;
            while(*next1 && *next2 && *next1 == *next2) {next1++; next2++;}
            printf("%s vs %s --> %s\n", $word1, $word2, strndup($word1, next1 - $word1));
        }
    }
}

say "GCD(35, 49) is: ", gcd(35, 49);

for my $n (2..11) {
    say "$n is prime" if PRIMUM($n);
}

PYTHON {
    def gcd(u, v):
        u, v = abs(u), abs(v) # u >= 0, v >= 0
        if u < v:
            u, v = v, u # u >= v >= 0
        if v == 0:
            return u

        k = 1
        while u & 1 == 0 and v & 1 == 0: # u, v - even
            u >>= 1; v >>= 1
            k <<= 1

        t = -v if u & 1 else u
        while t:
            while t & 1 == 0:
                t >>= 1
            if t > 0:
                u = t
            else:
                v = -t
            t = u - v
        return u * k
}


LATIN {

    PRIMUMERE
        SIC MEO NUMERO DA HIS DECAPITAMENTUM. MEIS LISTIS II TUM CUM
        NUMERUM FODEMENTUM CONSCRIBEMENTA DA. DUM DAMENTUM NEXTO LISTIS
        DECAPITAMENTUM FAC SIC LISTA SIC HOC TUM NEXTUM RECIDEMENTUM CIS
        VANNEMENTA DA LISTIS. SI NUMERUM TUM NEXTUM RECIDEMENTUM TUM
        NULLUM AEQUALITAM FAC SIC NULLUS REDDE CIS CIS UNUM REDDE CIS

}

