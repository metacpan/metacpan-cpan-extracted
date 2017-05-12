#!/usr/local/bin/perl -I./blib/arch -I./blib/lib -I/usr/local/lib/perl5/next/5.003 -I/usr/local/lib/perl5 -I./tests

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}

use PDL;
# use Meschach;
use PDL::Meschach qw( :All );

my $show_test = ( $ARGV[0] =~ /v/i ) ;
gset_verbose(0);
$loaded = 1;
print "ok 1\n";

# Short hand for print
sub p { print(@_); }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


sub anyeq { ("$_[0]" eq "$_[1]") || ($_[0] == $_[1]); }

$testcnt= 2;

sub ckeq {

my $ckstring = sprintf("%20s","$_[0]");
 	my $ckstring;
 	if($show_test) { 
 		$ckstring = "$_[0]";
 		$ckstring = substr("$ckstring                    ",0,20);
 	} else {
 		$ckstring = " " x 20 ;
 	}
 
	printf "\n$ckstring ";
	
	my $ckeqval = eval("$_[0]");
	my $is_ok = 0;

	if( anyeq( $ckeqval, $_[1] ) ) {

		print "     ok $testcnt ";
		$is_ok = 1;

	} else {

		print 
			" not ok $testcnt : evals to <<$ckeqval>> != <<$_[1]>> "; 
	}
	$testcnt++;
	$is_ok;
}


#################### Matrix / Vector copy ####################

$a = double(ones(3,3));
$a *= 1.25;

# Tests 2 - 3

foreach $coerce (0,1) {

	$b=  double(ones(1,1));
	to_fro_m( $b, $a, $coerce );
	print "$b\n" unless 
		ckeq(' min( $b - 1.25 == 0 )', 1 );
}

# Tests 4 - 5

foreach $coerce (0,1) {

	$b=  byte(ones(1,1));
	to_fro_m( $b, $a, $coerce );
	print $b-1.25 - ($coerce-1)*0.25 unless 
		ckeq(' min( $b - 1.25 == ($coerce-1)*0.25 )', 1 );
}

# Tests 6 - 7
$c = double(ones(9));
foreach $coerce (0,1) {

	$b=  double(ones(1,1));
	to_fro_v( $b, $a, $coerce );

	print "$b\n" unless 
		ckeq(' min( $b - $c == 0.25 )', 1 );
}

# Tests 8 - 9
foreach $coerce (0,1) {

	$b=  short(ones(1,1));
	to_fro_v( $b, $a, $coerce );

	print "$b\n" unless 
		ckeq(' min( $b - $c == $coerce*0.25  )', 1 );
}

# Tests 10 - 11
$c *= 1.25 ;
$a = float(ones(1,9));

foreach $coerce (0,1) {

	$b = ushort(ones(1));
	to_fro_m( $b, $c, $coerce );

	print "$a\n$b\n" unless 
		ckeq(' min( $b - $a == $coerce*0.25 )', 1 );
}

# Tests 12 - 13
$c= 1.25 * float(sequence(7));

foreach $coerce (0,1) {

	$b = long(ones(1));
	to_fro_v( $b, $c, $coerce );

	if( $coerce ) { 
		$d = $c ;
	} else {
		$d = long($c);
	}
	print "$c\n$b\n$d\n" unless 
		ckeq(' min( $b - $d ) == 0 ', 1 );
#		( max( $b - $d ) == 0 );
# 	gset_verbose(0);
}


# Tests 14 15
$c= float(sequence(7));

foreach $coerce (0,1) {

	$b = long(ones(1));
	to_fro_px( $b, $c, $coerce );

	print "coerce $coerce : float to long/ushort\n$c\n$b\n" unless 
		ckeq(' min( $b - $c ) == 0 ', 1 );
}



#################### Matrix Operations ####################

$a= double(ones(1,6));
$b= double(ones(3,3));
$c= double(ones(2,3));
mm_($a,$b,$c,0);
# p($a);

ckeq(' ${$$a{Dims}}[0] ',2);		# 16
ckeq(' ${$$a{Dims}}[1] ',3);		# 17

$a= "toto";

mm_($a,$b,$c,0);

ckeq(' ${$$a{Dims}}[0] ',2);		# 18
ckeq(' ${$$a{Dims}}[1] ',3);		# 19

################## More Matrix Operations ###################
ckeq('do "testpow.pm"',1);			# 20
ckeq('do "testrand.pm"',1);			# 21
ckeq('do "testdiag.pm"',1);			# 22
ckeq('do "testid.pm"',1);				# 23
ckeq('do "testlu.pm"',1);				# 24
ckeq('do "testch.pm"',1);				# 25
ckeq('do "testqr.pm"',1);				# 26
ckeq('do "testeig.pm"',1);			# 27
ckeq('do "testsvd.pm"',1);			# 28

print"\n";
