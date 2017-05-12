# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-PigLatin.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Lingua::PigLatin') }

#########################

ok(
    Lingua::PigLatin::piglatin("the quick red fox jumped over the lazy brown cheese ghost") eq
"ethay ickquay edray oxfay umpedjay overway ethay azylay rownbay eesechay ostghay"
);

