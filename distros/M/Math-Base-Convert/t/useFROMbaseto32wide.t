# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(dec b62);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

sub ok {
  print "ok $test\n";
  ++$test;
}

my $num = '999999999999999';
my $str = '4zXyLE1Gv';
my $b32str = [
	'2764472319',
	232830
];

$test = 2;

my $bcto = new Math::Base::Convert(dec,b62);
my $bcfrom = new Math::Base::Convert(b62 =>dec);

sub equal {
  my($a,$b) = @_;
  if ($a.$b =~ /\D/) {
    return $a eq $b;
  } else {
    return $a == $b;
  }
}

# test 2	to b63, check b2-32 conversion
$bcfrom->_cnv($str);
print "nstr missing\nnot "
	unless exists $bcfrom->{nstr} && $bcfrom->{nstr} eq $str;
&ok;

$bcfrom->useFROMbaseto32wide;

# test 3	check for b32 conversion vector
print "b32str missing\nnot "
	unless exists $bcfrom->{b32str} && ref $bcfrom->{b32str} eq 'ARRAY';
&ok;

# test 4 - 5	check contents
foreach my $i (0..$#{$b32str}) {
  print "b32 vector mismatch, index '$i', got: ", $bcfrom->{b32str}->[$i], " exp: ", $b32str->[$i], "\nnot "
    unless equal($bcfrom->{b32str}->[$i], $b32str->[$i]);
  &ok;
}

## test 6	check base2-32 value
my $rv = $bcfrom->use32wideTObase;
print "from-tobase conversion error, got: $rv, exp: $num\nnot "
	unless $rv eq $num;
&ok;
