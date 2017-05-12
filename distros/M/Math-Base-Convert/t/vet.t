# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..34\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert;

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

# check vet and _want

######### defaults

# test 2	check that proper keys are returned
my $bc = vet($class);
my $keys = join ' ', sort keys %$bc;
my $exp = 'fbase fhsh from prefix tbase to';
print "got: $keys\nexp: $exp\nnot "
	unless $keys eq $exp;
&ok;

# test 3	check 'to' assignment
ref($bc->{to}) =~ /_bs\:\:(.+)$/g;
my $got = $1;
print "expected to 'HEX', got '$got'\nnot "
	unless $got eq 'HEX';
&ok;

# test 4	check 'from' assignment
ref($bc->{from}) =~ /_bs\:\:(.+)$/;
$got = $1;
print "expected from 'dec', got '$got'\nnot "
	unless $got eq 'dec';
&ok;

# test 5	check dec length
print "got: $bc->{fbase},exp: 10\nnot "
	unless $bc->{fbase} == 10;
&ok;

# test 6	check hex length
print "got: $bc->{tbase},exp: 16\nnot "
	unless $bc->{tbase} == 16;
&ok;

########## from 'm64'

# test 7
$bc = vet($class,'m64');
ref($bc->{from}) =~ /_bs\:\:(.+)$/g;
$got = $1;
print "expected from 'm64', got '$got'\nnot "
	unless $got eq 'm64';
&ok;

# test 8	check base length
print "got: $bc->{fbase},exp: 64\nnot "
	unless $bc->{fbase} == 64;
&ok;

# test 9	check 'from' assignment
ref($bc->{to}) =~ /_bs\:\:(.+)$/;
$got = $1;
print "expected to 'HEX', got '$got'\nnot "
	unless $got eq 'HEX';
&ok;

# test 10	check hex length
print "got: $bc->{fbase},exp: 64\nnot "
	unless $bc->{fbase} == 64;
&ok;

########## from 'hex'

# test 11
$bc = vet($class,'heX','m64');
ref($bc->{from}) =~ /_bs\:\:(.+)$/;
$got = $1;
print "expected from 'heX', got '$got'\nnot "
	unless $got eq 'heX';
&ok;

# test 12	check hex length
print "got: $bc->{fbase},exp: 16\nnot "
	unless $bc->{fbase} == 16;
&ok;

# test 13 - 34	check 'from' hash
my @ary = ('0'..'9','A'..'F');
foreach(0..$#ary) {
  my $char = $ary[$_];
  print "got: $bc->{fhsh}->{$char}, exp: $_\nnot "
	unless $bc->{fhsh}->{$char} == $_;
  &ok;
  if ($char =~ /\D/) {	# if a digit
    $char = lc $char;
    print "got: $bc->{fhsh}->{$char}, exp: $_[$_]\nnot "
	unless $bc->{fhsh}->{$char} == $_;
    &ok;
  }
}

