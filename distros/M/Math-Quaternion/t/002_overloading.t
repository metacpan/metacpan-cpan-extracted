use Test::More tests => 25;
use strict;
use Carp;
use Math::Quaternion;

# Maybe I should roll these into the main module. Then again,
# putting floating-point fuzz correction into '==' might not
# be the Right Thing to do.

my $epsilon = 1e-10; # Precision to which I can be bothered with worrying.
my $pi = 3.1459265358979323846;

sub equal_fuzz {
	croak("Wrong number of args") unless (2==@_);
	my ($a,$b)=@_;
	if (0==$a) {
		if (abs($b)<$epsilon) {
			return 1;
		} else { 
			return undef;
		}
	}
	if (0==$b) {
		if (abs($a)<$epsilon) {
			return 1;
		} else { 
			return undef;
		}
	}
	if (abs(($a-$b)/$a) < $epsilon) {
		return 1;
	} else {
		return undef;
	}
}


# Take 5 args: a quat and four numbers. Return 1 if the quat is really a quat,
# and equal to the four numbers.

sub checkquat {
	croak("Wrong number of args") unless (5==@_);
	my ($q,@nos) = @_;
	if ("Math::Quaternion" ne ref $q) {
		return undef;
	}

	if (
		    equal_fuzz ($q->[0] , $nos[0])
		 && equal_fuzz ($q->[1] , $nos[1])
		 && equal_fuzz ($q->[2] , $nos[2])
		 && equal_fuzz ($q->[3] , $nos[3])
	) {
		return 1;
	} else { 
		return undef;
	}
}

sub quatequal_fuzz {
	my ($q1,$q2) = @_;

	if (
		    equal_fuzz ($q1->[0] , $q2->[0])
		 && equal_fuzz ($q1->[1] , $q2->[1])
		 && equal_fuzz ($q1->[2] , $q2->[2])
		 && equal_fuzz ($q1->[3] , $q2->[3])
	) {
		return 1;
	} else {
		return undef;
	}

}


my ($a,$b,$c,$d,$e,$f,$g,$h) = map { rand } 1..8;
my $q1 = new Math::Quaternion($a,$b,$c,$d);
my $q2 = new Math::Quaternion($e,$f,$g,$h);
my $q3 = new Math::Quaternion(rand,rand,rand);


ok(defined($q1) && defined($q2), "Sanity check: can make random quaternions");
ok($q1,"Quaternions evaluate to true");
ok(new Math::Quaternion(0,0,0,0),"...even the zero quaternion.");

my $q1q2 = undef;
my $q1c = $q1->conjugate;
my $q1i = $q1->inverse;

ok( $q1q2 = $q1 + $q2, "'+' is defined");

ok( quatequal_fuzz($q1+$q2,$q2+$q1), "'+' commutes");

ok( quatequal_fuzz( $q1->conjugate, ~$q1 ), "'~' conjugates");

ok( checkquat($q1+$q2,$a+$e,$b+$f,$c+$g,$d+$h),"'+' adds");

ok( $q1q2 = $q1 - $q2, "'-' is defined");

ok( checkquat($q1-$q2,$a-$e,$b-$f,$c-$g,$d-$h),"'-' subtracts");

ok( checkquat(-$q1,-$a,-$b,-$c,-$d),"Unary '-' negates");



ok( $q1q2= $q1 * $q2, "'*' is defined");
ok( checkquat($q1*$q1c,$q1->squarednorm,0,0,0),
	"'*'ing with a conjugate gives the squared norm");

ok(	checkquat($q1*$q1i,
		1,0,0,0),
	"'*'ing with inverse gives unit quaternion");


ok(	quatequal_fuzz(
		$q1* ( $q2 + $q3) , 
		($q1*$q2) + ($q1 * $q3)
	),
	"'*' is left-distributive");

ok(	quatequal_fuzz(
		($q1 + $q2) * $q3,
		($q1*$q3 + $q2*$q3)
	),
	"'*' is right-distributive");


ok(	checkquat($q1*$q2,
		$a*$e - $b*$f - $c*$g - $d*$h,
		$a*$f + $e*$b + $c*$h - $d*$g,
		$a*$g + $e*$c + $d*$f - $b*$h,
		$a*$h + $e*$d + $b*$g - $c*$f
	),
	"'*' multiplies.");

my $s = rand;
ok(	checkquat($q1*$s,
		$a*$s,$b*$s,$c*$s,$d*$s),
	"Scalar left-multiplication works");
ok(	checkquat($s*$q1,
		$a*$s,$b*$s,$c*$s,$d*$s),
	"Scalar right-multiplication works");

ok(	equal_fuzz(abs($q1),sqrt($a*$a+$b*$b+$c*$c+$d*$d)),
	"abs() gives the norm");

my $q = new Math::Quaternion(1,2,3,4);
ok(	"$q" eq "( 1 2 3 4 )","Stringification works");

ok(quatequal_fuzz(Math::Quaternion::exp($q1),exp($q1)),
	"Exponentiation works");
ok(quatequal_fuzz(Math::Quaternion::log($q2),log($q2)),
	"Logarithm works");
ok(quatequal_fuzz($q1**$s,Math::Quaternion::power($q1,$s)),
	"a**b works for quaternion a, scalar b");
ok(quatequal_fuzz($s**$q2,Math::Quaternion::power($s,$q2)),
	"a**b works for scalar a, quaternion b");
ok(quatequal_fuzz($q1**$q2,Math::Quaternion::power($q1,$q2)),
	"a**b works for quaternion a,b");

