# -*- cperl -*-

use Test::More tests => 2;
BEGIN { use_ok( 'Lingua::NATools::Corpus' ) };

is(Lingua::NATools::Corpus->new("/stupid/path/I/hope/not/exist") => undef);
