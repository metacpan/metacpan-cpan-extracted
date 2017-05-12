use Test::More tests => 6;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

my ($a,$b);
my $eps = 1e-6;
$a = Math::MatrixReal->new_from_cols([[1,2,3]]);

eval { @n = map { $a->norm_p($_) } qw(1 2 3 4 Inf); };

if($@) {
	ok(0,'norm_p doesn\'t seem to work');
} else {
	ok(1,'norm_p seems to work');
}
	
ok(similar($n[0], 6, $eps),'one norm seems cool');
ok(similar($n[1],sqrt(14) , $eps), 'two norm feeling good' );
ok(similar($n[2], 6**(2/3) , $eps), 'three norm is happy' );
ok(similar($n[3], 2**(1/4)*sqrt(7), $eps), 'four norm is kosher' );
ok(similar($n[4], 3, $eps), 'infinity norm is mighty fine' );

