package t::seal_d0;

use warnings;
use strict;

use Test::More;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, undef; }
main::test_runtime_hint_hash "Lexical::SealRequireHints/test", undef;

1;
