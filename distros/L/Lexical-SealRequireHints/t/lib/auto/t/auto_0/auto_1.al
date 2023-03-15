package t::auto_0;

use warnings;
use strict;

use Test::More ();

BEGIN { Test::More::is $^H{"Lexical::SealRequireHints/test"}, undef; }

sub auto_1 { 42 }

1;
