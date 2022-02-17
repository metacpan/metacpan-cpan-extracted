# -*- cperl -*-

use Test::More tests => 1 + 10 * 6;

use utf8;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

  my %words = qw/má ma
		 ré re
		 coração coracao
		 bébé bebe
		 há ha
		 à a
		 centrífoga centrifoga
		 cócaras cocaras
		 cúmulo cumulo
		 caça caca/;
  for (keys %words) {
    ok(has_accents($_));
    ok(!has_accents($words{$_}));
    ok(has_accents(uc($_)));

    is(remove_accents($_), $words{$_});
    is(remove_accents($words{$_}), $words{$_});
    { use utf8::all;
      is(remove_accents(uc($_)), uc($words{$_}));
    }

  }

1;


