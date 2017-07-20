package t::seal_1;

use warnings;
use strict;

use Test::More;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, undef; }
main::test_runtime_hint_hash "Lexical::SealRequireHints/test", undef;

sub import {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Lexical::SealRequireHints/test1"}++;
}

1;
