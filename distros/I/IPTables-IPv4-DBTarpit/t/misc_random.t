# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}

use CTest;

$TCTEST		= 'IPTables::IPv4::DBTarpit::CTest';
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

my @expected = (	# we're not going to use these because the differ on different OS's
	1804289383,
	846930886,
	1681692777,
	1714636915,
	1957747793,
	424238335,
	719885386,
	1649760492,
	596516649,
	1189641421,
);

## test 2 - seed random generator, get array size
my $seed = 1;
my ($size,$sv) = &{"${TCTEST}::t_inirand"}($seed);
print "expected size value of 10, got $size\nnot "
	unless $size == 10;
&ok;

## test 3 - get random array
my @array = &{"${TCTEST}::t_fillrand"}();
$_ = @array;
print "expected array size of 10, got $_\nnot "
	unless $_ == 10;
&ok;

## test 4-13 - check array values
my $cksize = (@array < @expected)
	? @array -1
	: @expected -1;

foreach(0..$cksize) {
#"expected $expected[$_], got $array[$_]\nnot "
#	unless $expected[$_] == $array[$_];
#  &ok;
  print "ok $test # skipped... not consistent across OS's\n";
  ++$test;
}

# test 14 - generate some (different) random numbers
my $failsafe = 10;
while ($sv == ($_ = (&{"${TCTEST}::t_inirand"}(0))[1]) && --$failsafe) {
}	# get some different pattern

@array = &{"${TCTEST}::t_fillrand"}();
$_ = @array;
print "expected array size of 10, got $_\nnot "
        unless $_ == 10;
&ok;

## test 15-24 - check that values are different
$cksize = (@array < @expected)
        ? @array -1
        : @expected -1;

foreach(0..$cksize) {
  print "did not expect $expected[$_], got $array[$_]\nnot "
        if $expected[$_] == $array[$_];
  &ok;
}
