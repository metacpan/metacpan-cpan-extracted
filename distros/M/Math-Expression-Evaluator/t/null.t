use strict;
use warnings;
use Test::More;
use Data::Dumper;
BEGIN { plan tests => 4 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
	$m->parse(shift);
#	print STDERR Dumper($m->{ast});
	return $m->val();
}

is e('0.0'), 	"0.0", 	"0.0 works" ;
is e('0'), 	0, 	"0 works" ;
is e('1-1'),	0,	'1-1 is 0';
