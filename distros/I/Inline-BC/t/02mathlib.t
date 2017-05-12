#!/usr/local/bin/perl
# Perform a series of calculations using 12, 25, and 45
# fractional decimal digits of precision.
# For the trigonometric functions, test calculations are
# performed at two arbitrary angles, 0.3rad (~17.2deg)
# and -1.7rad (~-97.4deg). At both angles, a tiny range
# of 20 angles, separated by 1/1000th radian, is used
# as input.

use Test::More tests => 841;

BEGIN {
   diag( "using Test::More ", $Test::More::VERSION, "\n" );
   use_ok( "Inline", (BC => "DATA", MATH_LIB => 1) );
}

sub has_failed {
   $_[0] < 0 ? 1 : 0;
}

# Read all data-lines from the input file whose name is provided
# in the 1st argument. Load each data-line into a hash table
# whose reference value is supplied in the 2nd argument. If the
# hash table was not filled successfully, the subroutine returns
# a negative value.
sub load_exptd_values {
   my ($filename, $evtable) = @_;

   if (! open(FH, $filename)) {
      diag( "$filename: Unable to open datafile of expected values!\n" );
      return(-128);
   }

   while (<FH>) {
      m/<(\w+)>([-.\d]+)/;
      $evtable->{$1} = $2;
   }

   close(FH);
   return(1);
}

my %ev_htable;         # Expected values calculated by GNU bc for all tests
my $ev_filename = "tools/02mathlib-ev.dat";
my @frac_prec   = (12, 25, 45);
my @bgn_angles  = (0.3, -1.7);
my $n_angle_inc = 20;
my $angle_inc   = 0.001;
my $angle;
my $test_n;
my ($rv_inlbc, $rv_gnubc);

die if (has_failed( load_exptd_values($ev_filename,
				      \%ev_htable  )));

#***************************************************************
#       Tests for BC's builtin sine function
#***************************************************************
$test_n = 1;
foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 chomp(
	    $rv_inlbc = bc_sin( $angle, $fprec ));
      
	 my $testname = "T".$test_n."_SIN_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

#***************************************************************
#       Tests for BC's builtin cosine function
#***************************************************************
foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 chomp(
	    $rv_inlbc = bc_cos( $angle, $fprec ));
      
	 my $testname = "T".$test_n."_COS_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

#***************************************************************
#       Tests for BC's builtin arctangent function
#***************************************************************
foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 chomp(
	    $rv_inlbc = bc_atan( $angle, $fprec ));
      
	 my $testname = "T".$test_n."_ATAN_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

#***************************************************************
#     Tests for BC's builtin Bessel functions of the first kind
#***************************************************************
foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 # Evaluate Bessel function of order N=0
	 chomp(
	    $rv_inlbc = bc_bessel( 0, $angle, $fprec ));
      
	 my $testname = "T".$test_n."_BESSEL_J0_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }

	 # Evaluate Bessel function of order N=1
	 $test_n++;
	 chomp(
	    $rv_inlbc = bc_bessel( 1, $angle, $fprec ));
      
	 $testname = "T".$test_n."_BESSEL_J1_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

#***************************************************************
#       Tests for BC's builtin exponential function
#***************************************************************
$bgn_angles[1] = -14.2;

foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 chomp(
	    $rv_inlbc = bc_expl( $angle, $fprec ));
      
	 my $testname = "T".$test_n."_EXP_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

#***************************************************************
#       Tests for BC's builtin natural logarithm function
#***************************************************************
$bgn_angles[0] = 0.0005;
$bgn_angles[1] = 157.3;

foreach my $a0 (@bgn_angles) {
   foreach my $fprec (@frac_prec) {
      $angle = $a0;
      
      for (my $n = 0; $n < $n_angle_inc; $n++,
					 $test_n++,
					 $angle += $angle_inc) {
	 chomp(
	    $rv_inlbc = bc_ln( $angle, $fprec ));
      
	 my $testname = "T".$test_n."_NLOG_FP".$fprec;
	 if (exists( $ev_htable{$testname} )) {
      
	    is( $rv_inlbc, $ev_htable{$testname}, $testname );
	 }
	 else {
	    diag( "$testname: Expected value NOT found for this test!\n" );
	 }
      }
   }
}

__END__
__BC__

/* Function to compute the sine of a radian value
   using the specified fractional precision.
*/
define bc_sin (u, fp) {
   scale = fp
   rv = s(u)
   return (rv)
}

/* Function to compute the cosine of a radian value
   using the specified fractional precision.
*/
define bc_cos (u, fp) {
   scale = fp
   rv = c(u)
   return (rv)
}

/* Function to compute the arctangent of a value, using
   the specified fractional precision, and return the
   radian angle.
*/
define bc_atan (u, fp) {
   scale = fp
   rv = a(u)
   return (rv)
}

/* Function to evaluate the Bessel function of first kind
   for N-th order at the specified value U. The calculation
   is made using the specified fractional precision, and
   the computed value returned.
*/
define bc_bessel (n, u, fp) {
   scale = fp
   rv = j(n, u)
   return (rv)
}

/* Function to evaluate the exponential function of an
   abscissa value using the specified fractional precision.
*/
define bc_expl (u, fp) {
   scale = fp
   rv = e(u)
   return (rv)
}

/* Function to compute the natural logarithm of an
   abscissa value with the specified fractional
   precision.
*/
define bc_ln (u, fp) {
   scale = fp
   rv = l(u)
   return (rv)
}
