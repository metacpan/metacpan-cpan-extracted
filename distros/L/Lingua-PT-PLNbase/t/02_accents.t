# -*- cperl -*-

use Test::More tests => 1 + 10 * 6;

use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

use locale;

$a = 'Çáé';

SKIP: {
  skip "not a good locale", 10 * 6 unless $a =~ m!^\w{3}$!;

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
    is(remove_accents(uc($_)), uc($words{$_}));
  }

}

1;


