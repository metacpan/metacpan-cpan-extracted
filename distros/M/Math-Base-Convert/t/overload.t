use diagnostics;
BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub skipit {
  my($skipcount,$reason) = @_;
  $skipcount = 1 unless $skipcount;
  $reason = $reason ? ":\t$reason" : '';
  foreach (1..$skipcount) {
    print "ok $test	# skipped$reason\n";
    ++$test;
  }
}

use strict;
#use diagnostics;
use Math::Base::Convert qw(oct hex);

require './recurse2txt';

my $bc = new Math::Base::Convert();

my $bi = eval {		# try stripped bigint
	$bc->newb10(8);
};

my $benchmark = exists $ENV{BENCHMARK} && $ENV{BENCHMARK} > 0 && eval {
	require Benchmark;
};


unless ($bi || $benchmark) {	# else enabled and real BigInt
  $bi = eval {
	require Math::BigInt;
	new Math::BigInt(8);
  };
}

#$bi = new Math::BigInt(8) if $bi;

# test 2
if ($bi) {
  $bi += 2;
  print "got: $bi, exp: 10\nnot "
	unless $bi == 10;
  &ok;
} else {
  skipit(1,'no BigInt');
}

# hex thinks any string it gets is hex
# with any arguments, return hex value

# hex or octal called with arguments or with a BI pointer 
# should alway use CORE::xxx. It will return a ref pointer otherwise

# test 3
my $rv = hex 10; $rv = ref($rv) if ref $rv;
print "got: $rv, exp: 'a'\nnot "
	unless $rv eq '16';
&ok;

# test 4
$rv = hex(10); $rv = ref($rv) if ref $rv;
print "got: $rv, exp: '16'\nnot "
	unless $rv eq '16';
&ok;

# test 5
if ($bi) {
  (my $biv = "$bi") =~ s/\+//;	# strip objectionable + sign
  $rv = hex $biv; $rv = ref($rv) if ref $rv;
  print "got: $rv, exp: '16'\nnot "
	unless $rv eq '16';
  &ok;

# test 6
  $rv = hex($biv); $rv = ref($rv) if ref $rv;
  print "got: $rv, exp: '16'\nnot "
	unless $rv eq '16';
  &ok;

  unless (ref($bi) =~ /Math\:\:BigInt/) {
# test 7
    $rv = $bi->hex; $rv = ref($rv) if ref $rv;
    print "got: $rv, exp: '16'\nnot "
	unless $rv eq '16';
    &ok;

# test 8
    $rv = $bi->hex; $rv = ref($rv) if ref $rv;
    print "got: $rv, exp: '16'\nnot "
	unless $rv eq '16';
    &ok;
  } else {
    skipit(2,'removed');
  }
} else {
  skipit(4,'no BigInt');
}

# ============= check for proper detection of internal hex function =========

# test 9
$rv = hex;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;

# test 10	check that we got an array pointer for hex
my $exp = q|16	= [0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f',];
|;
my $got = Dumper($rv);

print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 11
$rv = &hex;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;

# test 12
$rv = $bc->hex;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;

# test 13

$rv = oct 12; $rv = ref($rv) if ref $rv;
print "got: $rv, exp: 'a'\nnot "
	unless $rv eq '10';
&ok;

# test 14
$rv = oct(12); $rv = ref($rv) if ref $rv;
print "got: $rv, exp: '10'\nnot "
	unless $rv eq '10';
&ok;

if ($bi) {
# test 15
  $bi += 3;
  print "got: $bi, exp: 10\nnot "
	unless $bi == 13;
  &ok;

# test 16
  (my $biv = "$bi") =~ s/\+//;	# strip + sign
  $rv = oct $biv; $rv = ref($rv) if ref $rv;
  print "got: $rv, exp: '11'\nnot "
	unless $rv eq '11';
  &ok;

# test 17
  $rv = oct($biv); $rv = ref($rv) if ref $rv;
  print "got: $rv, exp: '11'\nnot "
	unless $rv eq '11';
  &ok;
  unless (ref($bi) =~ /Math\:\:BigInt/) {
# test 18
    $rv = $bi->oct; $rv = ref($rv) if ref $rv;
    print "got: $rv, exp: '11'\nnot "
	unless $rv eq '11';
    &ok;

# test 19
    $rv = $bi->oct; $rv = ref($rv) if ref $rv;
    print "got: $rv, exp: '11'\nnot "
	unless $rv eq '11';
    &ok;
  } else {
    skipit(2,'removed');
  }
} else {
  skipit(5,'no BigInt');
}

# ============= check for proper detection of internal oct function =========

# test 20
$rv = oct;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;

# test 21	check that we got an array pointer for oct
$exp = q|8	= [0,1,2,3,4,5,6,7,];
|;
$got = Dumper($rv);

print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 22
$rv = &oct;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;

# test 23
$rv = $bc->oct;
print "got: $rv, exp: ref\nnot "
	unless ref $rv;
&ok;
