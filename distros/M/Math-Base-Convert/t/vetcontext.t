# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(dec oct);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

sub ok {
  print "ok $test\n";
  ++$test;
}

$test = 2;

my $class = 'Math::Base::Convert';
*vet = \&Math::Base::Convert::vet;

my $bc;

# test 2 - 10
foreach (8, 'oct', oct) {
  $bc = vet($class,dec,$_);
  print "missing key 'tbase'\nnot "
	unless exists $bc->{tbase};
  &ok;

  my $tbase = $bc->{tbase};
  print "tbase should be: 8, is: $tbase\nnot "
	unless $tbase == 8;
  &ok;

  ref($bc->{to}) =~ /_bs\:\:(.+)$/;
  print "got: $1, exp: 'ocT'\nnot "
	unless $1 eq 'ocT';
  &ok;
}


# check method pointers

# test 11 - 13
{
  bless $bc,'Math::Base::Convert';
  $bc = vet($class,dec,$bc->b64);
  print "missing key 'tbase'\nnot "
	unless exists $bc->{tbase};
  &ok;

  my $tbase = $bc->{tbase};
  print "tbase should be: 64, is: $tbase\nnot "
	unless $tbase == 64;
  &ok;

  ref($bc->{to}) =~ /_bs\:\:(.+)$/;
  print "got: $1, exp: 'b64'\nnot "
	unless $1 eq 'b64';
  &ok;
}

# check empty array if to/from are the same

__END__
# test 14
$bc = vet($class,oct,'oct');

print "'sameness' not identified\nnot "
	if keys %$bc;
&ok;
