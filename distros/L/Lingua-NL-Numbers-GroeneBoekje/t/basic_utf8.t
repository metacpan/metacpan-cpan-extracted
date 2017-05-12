# -*- mode: cperl; coding: utf-8 -*-

BEGIN { 
    eval "use utf8; 1"
    or eval "use Test::More skip_all => 'this perl does not support utf8'"
}

use utf8;

my $tests;
BEGIN {
  $tests = [
          22 => "tweeëntwintig",
	 222 => "tweehonderdtweeëntwintig",
	1022 => "duizend tweeëntwintig",
	1922 => "negentienhonderdtweeëntwintig",
	2022 => "tweeduizend tweeëntwintig",
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
