#!perl -T

use utf8;
use Test::More 'tests' => 11;

use Lingua::RU::Preposition qw/:short/;

ok( izo('всех')    eq 'изо',    'izo: exception' );
ok( nado('мной')   eq 'надо',   'nado: exception' );
ok( ko('мне')      eq 'ко',     'ko: exception' );
ok( ob('ухе')      eq 'об',     'ob: vowel' );
ok( obo('всём')    eq 'обо',    'obo: exception' );
ok( oto('всех')    eq 'ото',    'oto: exception' );
ok( predo('мной')  eq 'предо',  'predo: exception' );
ok( peredo('мной') eq 'передо', 'peredo: exception' );
ok( podo('мной')   eq 'подо',   'podo: exception' );
ok( so('сном')     eq 'со',     'so: s with consonant' );
ok( vo('фраке')    eq 'во',     'vo: f with consonant' );
