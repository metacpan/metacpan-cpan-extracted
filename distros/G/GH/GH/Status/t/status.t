# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use GH::Status ':all';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub Not {
  print "not ";
}

sub Ok {
  my($i) = @_;
  print "ok $i\n";
}
  
$i = 2;

# it's a good thing for STAT_OK to be zero...
Not() if (STAT_OK != 0); Ok($i++);

# likewise, general failure should be non-zero...
Not() if (STAT_FAIL == 0); Ok($i++);

# and make sure that they're differential (implied by above, but...)
Not() if (STAT_FAIL == STAT_OK); Ok($i++);

# it's a good thing for STAT_OK to be zero...
Not() if (STAT_FAIL != -1); Ok($i++);
Not() if (STAT_EOF != -2); Ok($i++);
Not() if (STAT_NULL_PTR != -3); Ok($i++);
Not() if (STAT_NO_MEM != -4); Ok($i++);
Not() if (STAT_BAD_ARGS != -5); Ok($i++);
Not() if (STAT_BOUND_TOO_TIGHT != -6); Ok($i++);
Not() if (STAT_NOT_OPTIMAL != -7); Ok($i++);
