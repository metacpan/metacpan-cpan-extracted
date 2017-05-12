use Test;

BEGIN { plan tests => 15 };

use Lingua::SV::Num2Word;

my $tests = {          7 => "sju",
                      42 => "fyrtiotvå",
	             100 => "etthundra",
	             123 => "etthundratjugotre",
	            1000 => "etttusen",
	            4711 => "fyratusensjuhundraelva",
	           10000 => "tiotusen",	           
		   62144 => "sextiotvåtusenetthundrafyrtiofyra",
	          100000 => "etthundratusen",
	          378842 => "trehundrasjutioåttatusenåttahundrafyrtiotvå", 
	         3425379 => "tre miljoner fyrahundratjugofemtusentrehundrasjutionio",
	        75893657 => "sjutiofem miljoner åttahundranittiotretusensexhundrafemtiosju",
	       531243385 => "femhundratrettioett miljoner tvåhundrafyrtiotretusentrehundraåttiofem",
              1000000000 => "", };

ok(1);

for (keys %$tests) {
    ok($tests->{$_} eq &Lingua::SV::Num2Word::num2sv_cardinal($_));
}



