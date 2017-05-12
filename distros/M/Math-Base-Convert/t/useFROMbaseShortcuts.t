
BEGIN { $| = 1; print "1..37\n"; }
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
    print "ok $test     # skipped$reason\n";
    ++$test;
  }
}

#use diagnostics;
use Math::Base::Convert qw(:base);

require './recurse2txt';

my $benchmark = 0;

my @bas2	= ('x','y');				# w1
my @bas4	= ('w','x','y','z');			# w2
my @bas8	= ('a'..'d','w'..'z');			# w3
my @bas16	= @{&hex};				# w4
my @bas32	= ('a'..'z',3,2,6,4,1,8);		# w5
my @bas64	= @{&m64};				# w6
# use unpopulated b85 for base 128, 256
my @bas128	= (@{&b85},':',' ',('.') x (128 - 87));	# w7
my @bas256	= (@{&b85},':',' ',('.') x (256 - 87));	# w8

my @common = ( \@bas16, \@bas32, \@bas64, \@bas128, \@bas256 );

sub alwayslongconvert {
  my $bc = &Math::Base::Convert::_cnv;
  $bc->useFROMbaseto32wide;
  $bc->use32wideTObase;
}

my $BaseConvert_number = '17642423809438080123524818517743';
# test 2	generate dead beef
my $exp = $BaseConvert_number;
my $bc16to10 = new Math::Base::Convert(hex =>dec);
my $decDEADBEEF = alwayslongconvert($bc16to10,'DEADBEEF0123456789deadbeef');
print "got: $decDEADBEEF, exp: $exp\nnot "
	unless $decDEADBEEF == $exp;
&ok;

# test 3	verify base 32 values - these are always without shortcuts
$exp = q|4	= [3735928559,591751049,2914971393,222,];
|;
my $got = Dumper($bc16to10->{b32str});
print "got: $got\nexp: $exp\nnot "
	unless $exp eq $got;
&ok;

# test 4	verify base 32 values from shortcut
delete $bc16to10->{b32str};
$bc16to10->useFROMbaseShortcuts;
$got = Dumper($bc16to10->{b32str});
print "got: $got\nexp: $exp\nnot "
	unless $exp eq $got;
&ok;

# test 5 - 7	generate base number for next test sequence
my @exp = (
  q|yyxyyyyxyxyxyyxyyxyyyyyxyyyxyyyyxxxxxxxyxxyxxxyyxyxxxyxyxyyxxyyyyxxxyxxyyyxyyyyxyxyxyyxyyxyyyyyxyyyxyyyy|,
  q|zxzyyyzxyzzyzyzzwwwxwywzxwxxxyxzywyxzxzyyyzxyzzyzyzz|,
  q|ddyxdddzdxzaaccbxaxdbzawzdyxdddzdxz|
);
my @lowbase = ( \@bas2, \@bas4, \@bas8 );
foreach (0..$#lowbase) {
  my $bc = new Math::Base::Convert(dec,$lowbase[$_]);
  my $str = $bc->_cnvtst($BaseConvert_number);
  print "got: $str\nexp: $exp[$_]\nnot "
	unless $str eq $exp[$_];
  &ok;
}

my $Lexp = q|0x4	= [0xdeadbeef,0x23456789,0xadbeef01,0xde,];
|;

# test 8 - 10	convert back to decimal with shortcut
# setup for low base benchmarks with long number
my @Lbc;
foreach(0..$#lowbase) {
  $Lbc[$_] = new Math::Base::Convert($lowbase[$_] =>dec);
  my $num = $Lbc[$_]->_cnvtst($exp[$_]);
  print "got: $num\nexp: $BaseConvert_number\nnot "
	unless $num eq $BaseConvert_number;
  &ok;
}

my $ShortConvert_number = '12345';

# test 11 - 13	generate base number for next test sequence
@exp = (
  q|yyxxxxxxyyyxxy|,
  q|zwwwzyx|,
  q|daazb|
);

foreach (0..$#lowbase) {
  my $bc = new Math::Base::Convert(dec,$lowbase[$_]);
  my $str = $bc->_cnvtst($ShortConvert_number);
  print "got: $str\nexp: $exp[$_]\nnot "
	unless $str eq $exp[$_];
  &ok;
}

# test 14 - 16	convert back to decimal with shortcut
# setup for low base benchmarks with short number
my @Sbc;
foreach(0..$#lowbase) {
  $Sbc[$_] = new Math::Base::Convert($lowbase[$_] =>dec);
  my $num = $Sbc[$_]->_cnvtst($exp[$_]);
  print "got: $num\nexp: $ShortConvert_number\nnot "
	unless $num eq $ShortConvert_number;
  &ok;
}

my @testbc;
my $testexp;
my $Sexp = q|0x1	= [0x3039,];
|;

my $t1 = sub {
  foreach(0..$#lowbase) {
    $testbc[$_]->useFROMbaseto32wide;
    unless ($benchmark) {
      $got = hexDumper($testbc[$_]->{b32str});
      print "got: ${got}exp: $testexp\nnot "
	unless $testexp eq $got;
      &ok;
    }
  }
};

my $t2 = sub {
  foreach (0..$#lowbase) {
#print $testbc[$_]->{nstr},"\n";
    delete $testbc[$_]->{b32str};
    $testbc[$_]->useFROMbaseShortcuts($testbc[$_]);
    unless ($benchmark) {
      $got = hexDumper($testbc[$_]->{b32str});
      print "got: ${got}exp: $testexp\nnot "
	unless $testexp eq $got;
      &ok;
    }
  }
};

# test 17 - 19	base to decimal, check short b32str
@testbc = @Sbc;
$testexp = $Sexp;

&$t1;

@testbc = @Lbc;
$testexp = $Lexp;

# test 20 - 22	shortcut short base to decimal
&$t2;

# test 23 - 32	check all base 2 conversions using both alpha and numeric
@exp = ( #	input   is 183deadbeef2feed1baddad123468
# Math::BaseConvert 	is 7866934940423497751608207554524264
# base 16	decimal is 7866934940423497751608207554524264
  q|0x4	= [0xad123468,0xeed1badd,0xadbeef2f,0x183de,];
|,
# base 32
  q|0x5	= [0xfdbd779f,0xe0806300,0x17652107,0x6400c242,0x1efe8,];
|,
# base 64
  q|0x6	= [0x76df8ebc,0xa75d69dd,0x79e7756d,0xde79fd9f,0x775e69d6,0x35f3,];
|,
# base 128
  q|0x7	= [0x20610308,0xa7489c08,0x3814a913,0x412950a1,0x9d2a850a,0xd3a848,0x11,];
|,
# base 256
  q|0x8	= [0x3040608,0x24270102,0x25242727,0x28282701,0x28290229,0x24272528,0x8032728,0x1,];
|
);

#my $commonstring = '183deadbeef2feed1baddad123468';
# $commonstring = 'daaaaamaaaaaaaaaaaa';

my $commontest;
my @bc;

sub init {
  foreach (0..$#common) {
  #foreach (1..1) {
    $bc[$_] = new Math::Base::Convert($common[$_] =>dec);	# do this separately to facilitate benchmark testing
    $bc[$_]->_cnvtst($commontest);
  #print scalar(@{$common[$_]}),'  ',ref($bc[$_]->{from}),'  ',ref($bc[$_]->{fhsh}),'  ', $bc[$_]->{fbase},"\n";
  #print hexDumper($bc[$_]->{b32str});
  }
}

# test 23 - 27	regular
my $t3 = sub {
  foreach (0..$#common) {
    $bc[$_]->useFROMbaseto32wide;
    unless ($benchmark) {
      $got = hexDumper($bc[$_]->{b32str});
      print "got: ${got}exp: $exp[$_]\nnot "
	unless $exp[$_] eq $got;
      &ok;
#print hexDumper($bc[$_]->{b32str});
#print $bc[$#common]->{nstr},"\n";
    }
  }
};

# test 28 - 32	shortcut
my $t4 = sub {
  foreach (0..$#common) {
    delete $bc[$_]->{b32str};
    $bc[$_]->useFROMbaseShortcuts;
    unless ($benchmark) {
      $got = hexDumper($bc[$_]->{b32str});
      print "got: ${got}exp: $exp[$_]\nnot "
	unless $exp[$_] eq $got;
      &ok;
#print hexDumper($bc[$_]->{b32str});
#print $bc[$#common]->{nstr},"\n";
#print "----\n";
#last if $_ == 1;
    }
  }
};

my $commonstring = '183deadbeef2feed1baddad123468';
# $commonstring = '123468';
# $commonstring = 'f2feed1baddad123468';
# $commonstring = 'daaaaamaaaaaaaaaaaa';

  $commontest = $commonstring;
  &init;
  &$t3;
  &$t4;

# test 33 - 37	run benchmarks

$benchmark = eval {
	require Benchmark;
};

if ($benchmark && exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 3) {

print STDERR "\n\nmake test BENCHMARK=3    t.useFROMbaseShortcuts.t\n\n";

# test 33 - 34	bench mark base's 2,4,8
  my $bm = {
	'b2->b8_multiplyTo_b32'	=> $t1,
	'b2->b8_directTObase32'	=> $t2
  };

  my $bmr;
# test 33	short
  @testbc = @Sbc;
  $testexp = $Sexp;

  print STDERR "\n";
  foreach(sort keys %$bm) {
    $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
    printf STDERR ("\t# %s\t%2.3f ms\n",'short '. $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
  }
  &ok;
  sleep 1;
# test 34	long
  @testbc = @Lbc;
  $testexp = $Lexp;

  print STDERR "\n";
  foreach(sort keys %$bm) {
    $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
    printf STDERR ("\t# %s\t%2.3f ms\n",'long  '. $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
  }
  &ok;

# test 35 - 37	benchmark base's 16,32,64,128,256
  $bm = {
	'b16->256_multiplyTo_b32'	=> $t3,
	'b16->256_directTObase32'	=> $t4
  };

  foreach(qw(
	183deadbeef2feed1baddad123468
	123468
	f2feed1baddad123468
  )) {
    $commontest = $_;
    &init;
    my $bmr = {};
    print STDERR "\n";
    foreach(sort keys %$bm) {
      $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
      printf STDERR ("\t# %s\t%2.3f ms\n",'benchmark '. $commontest ."\n\t# ". $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
    }
    &ok;
  }
} else {
  skipit(5,'benchmark 3');
}
