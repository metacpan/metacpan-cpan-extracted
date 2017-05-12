# -*- mode: cperl -*-

my $tests;
BEGIN {
  $tests = [
           0 => "nul",
           2 => "twee",
          10 => "tien",
          12 => "twaalf",
          20 => "twintig",
          22 => "tweeëntwintig",
         100 => "honderd",
         102 => "honderdtwee",
	 120 => "honderdtwintig",
	 200 => "tweehonderd",
	 220 => "tweehonderdtwintig",
	 222 => "tweehonderdtweeëntwintig",
	1000 => "duizend",
	1002 => "duizend twee",
	1020 => "duizend twintig",
	1022 => "duizend tweeëntwintig",
	1900 => "negentienhonderd",
	1902 => "negentienhonderdtwee",
	1920 => "negentienhonderdtwintig",
	1922 => "negentienhonderdtweeëntwintig",
	2000 => "tweeduizend",
	2002 => "tweeduizend twee",
	2020 => "tweeduizend twintig",
	2022 => "tweeduizend tweeëntwintig",
       10000 => "tienduizend",
      100000 => "honderdduizend",
      101000 => "honderdeenduizend",
      110000 => "honderdtienduizend",
     1000000 => "een miljoen",
     2345678 => "twee miljoen driehonderdvijfenveertigduizend zeshonderdachtenzeventig",
  1000000000 => "een miljard",
  ];
}

use Test::More tests => 1+scalar(@$tests)/2;

BEGIN {
    use_ok("Lingua::NL::Numbers::GroeneBoekje");
}

my $o = Lingua::NL::Numbers::GroeneBoekje->new;

for ( my $t = 0; $t < @$tests; $t += 2 ) {
    is($o->parse($tests->[$t]), $tests->[$t+1], "test ".$tests->[$t]);
}
