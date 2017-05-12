
use Test::More;
use LaTeX::Recode
	encode_set => 'full',
	decode_set => 'full';
use utf8;
use Unicode::Normalize;

my @tests = do "t/tests.pl";

plan tests => scalar(@tests);

my $i = 0;
for my $t (@tests) {	
	++$i;
	my $latex_string = latex_decode($t->[1]);
	is $latex_string => NFD($t->[0]), "Test $i";
}
