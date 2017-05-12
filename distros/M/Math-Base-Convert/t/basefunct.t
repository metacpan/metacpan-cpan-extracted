# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(:all);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

foreach (qw(bin oct dec hex HEX b62 b64 m64 iru url rex id0 id1 xnt xid b85)) {
  my $ary = &{$_} || 'NOTHING';
# test for ary ref ending in subroutine name
  my $ref = ref $ary;
  $ref =~ s/ocT/oct/;	# special treatment
  $ref =~ s/heX/hex/;
  print "got: $ref, exp: blessing ending in '$_'\nnot "
	unless $ref =~ /_bs\:\:$_$/;
  &ok;
}
