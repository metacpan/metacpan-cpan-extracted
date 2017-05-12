use utf8;
use Test::More;
use LaTeX::Recode
	encode_set => 'full',
	decode_set => 'full';


my @tests = do "t/tests.pl";

plan tests => scalar(@tests);

my $i = 0;
for my $t (@tests) {	
	++$i;
	my $latex_string = latex_encode($t->[0]);
	is $latex_string => $t->[1], "Test $i";
}

