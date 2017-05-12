# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use CTest;

$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

=pod

This is what we are testing:

/* serial max   = 4294967295
 * rollover     = (1 + max / 2) = 2147483648
 *
 * returns:
 *       0      s1 = s2
 *      -1      s1 < s2
 *       1      s1 > s2
 *      >1      undefined
 */
  
int
cmp_serial(u_int32_t s1, u_int32_t s2)
{
  u_int32_t rollover = 2147483647;

  rollover += 1;        /* silence unsigned integer compiler warning    */
  if (s1 == s2)
    return(0);
  else if ((s1 < s2 && s2 - s1 < rollover) ||
           (s1 > s2 && s1 - s2 > rollover))
    return(-1);
  else if ((s1 < s2 && s2 - s1 > rollover) ||
           (s1 > s2 && s1 - s2 < rollover))
    return(1);
  return(2);
}

=cut

## test 2	check equality
my $s1 = 123456;
my $s2 = $s1;
print "failed s1 == s2, exp: 0, got: $_\nnot "
	if ($_ = &{"${TCTEST}::t_cmp_serial"}($s1,$s2));
&ok;

## test 3	check s1 < s2 && s2 - s1 < rollover
$s1 = 123456;
$s2 = $s1 + 1;
print "failed s1 < s2 && s2 - s1 < rollover, exp: -1, got: $_\nnot "
	unless (($_ = &{"${TCTEST}::t_cmp_serial"}($s1,$s2)) == -1);
&ok;

## test 4	check s1 > s2 && s1 - s2 > rollover
$s1 = 4294967295;
$s2 = 0;
print "failed s1 > s2 && s1 - s2 > rollover, exp: -1, got $_\nnot "
	unless (($_ = &{"${TCTEST}::t_cmp_serial"}($s1,$s2)) == -1);
&ok;

## test 5	check s1 < s2 && s2 - s1 > rollover
$s1 = 0;
$s2 = 4294967295;
print "failed s1 < s2 && s2 - s1 > rollover, exp: 1, got: $_\nnot "
	unless (($_ = &{"${TCTEST}::t_cmp_serial"}($s1,$s2)) == 1);
&ok;

## test 6	check s1 > s2 && s1 - s2 < rollover
$s1 = 123456;
$s2 = $s1 -1;
print "failed s1 > s2 && s1 - s2 < rollover, exp: 1, got: $_\nnot "
	unless (($_ = &{"${TCTEST}::t_cmp_serial"}($s1,$s2)) == 1);
&ok;

