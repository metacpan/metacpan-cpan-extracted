use strict;
use Test::More tests => 3;

BEGIN { use_ok('Lingua::LinkParser::Definitions') };

ok(Lingua::LinkParser::Definitions::define("A"));

ok(Lingua::LinkParser::Definitions::define("Dmc+"));

