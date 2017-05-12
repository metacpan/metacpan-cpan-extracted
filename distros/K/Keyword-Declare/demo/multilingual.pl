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

push @word_list, @word_list;

for my $n (1..3) {
    use List::Util 'shuffle';
    my @words = shuffle (@word_list) x $n;
    PYTHON {
        import itertools
        print 'n =', $n, ' -->', [k for k,g in itertools.groupby(sorted(@word_list))]
    }
}

say "GCD is: ", gcd(35, 49);

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
