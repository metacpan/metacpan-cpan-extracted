
BEGIN { $| = 1; print "1..69\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(:base);

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

my @lowbase = ( \@bas2, \@bas4, \@bas8 );

my $Lexp = q|0x4        = [0xdeadbeef,0x23456789,0xadbeef01,0xde,];
|;

my $ShortConvert_number = '12345';

# test 11 - 13  generate base number for next test sequence
my @exp = (
  q|yyxxxxxxyyyxxy|,
  q|zwwwzyx|,
  q|daazb|   
);

# test 2 - 4	setup for short, low base test/benchmark
my @Sbc;
foreach(0..$#lowbase) {
  $Sbc[$_] = new Math::Base::Convert(dec =>$lowbase[$_]);
  my $rv = $Sbc[$_]->_cnvtst($ShortConvert_number);
  print "got: $rv\nexp: $exp[$_]\nnot "
        unless $rv eq $exp[$_];
  &ok;
}

my @testbc = @Sbc;

my $t1 = sub {
  foreach(0..$#lowbase) {
    my $rv = $testbc[$_]->use32wideTObase;
    unless ($benchmark) {
      print "R got: $rv\n  exp: $exp[$_]\nnot "
        unless $exp[$_] eq $rv;
      &ok;
    }   
  }
};

my $t2 = sub {
  foreach (0..$#lowbase) {
    my $got = $testbc[$_]->useTObaseShortcuts;
    unless ($benchmark) {
      print "W got: $got\n  exp: $exp[$_]\nnot "
        unless $exp[$_] eq $got;
      &ok;
    }
  }  
};   

# test 5 - 7	duplicates test 2 - 4 from the standard internal register half-way-point
&$t1;

# test 8 - 10	check shortcut 32wide -> base
&$t2;

# test 11 - 13	setup for long, low base test/benchmark
@exp = (
  q|yyxyyyyxyxyxyyxyyxyyyyyxyyyxyyyyxxxxxxxyxxyxxxyyxyxxxyxyxyyxxyyyyxxxyxxyyyxyyyyxyxyxyyxyyxyyyyyxyyyxyyyy|,
  q|zxzyyyzxyzzyzyzzwwwxwywzxwxxxyxzywyxzxzyyyzxyzzyzyzz|,
  q|ddyxdddzdxzaaccbxaxdbzawzdyxdddzdxz|
);

my $BaseConvert_number = '17642423809438080123524818517743';
my @Lbc;
foreach(0..$#lowbase) {
  $Lbc[$_] = new Math::Base::Convert(dec =>$lowbase[$_]);
  my $rv = $Lbc[$_]->_cnvtst($BaseConvert_number);
  print "got: $rv\nexp: $exp[$_]\nnot "
        unless $rv eq $exp[$_];
  &ok;
}

@testbc = @Lbc;

# test 14 - 16	duplicates test 2 - 4 from the standard internal register half-way-point
&$t1;

# test 17 - 19	check shortcut 32wide -> base
&$t2;

# ==================

my $commonstring = '183deadbeef2feed1baddad123468';
#
# base 16       decimal is 7866934940423497751608207554524264
#		LSB				MSB
#my $b32str = [0xad123468,0xeed1badd,0xadbeef2f,0x183de,];

my @common = ( \@bas16, \@bas32, \@bas64, \@bas128, \@bas256 );

my @starters = (
  [
# base        183deadbeef2feed1baddad123468
# to decimal
	'7866934940423497751608207554524264',
	'43199659972086582067436706122106865662654367',
	'20185480588568783073476025771304392678392993115246268',
	'106731002248906537881566885134755281972276190436002074002184',
	'27803742051471350500322413252999924537290117412683890126949076698632'
  ],
  [
# base123468
# to decimal
	'1193064',
	'1035827103',
	'57828937404',
	'34902967048',
	'1108152157704'
  ],
  [
# base f2feed1baddad123468',
# to decimal
	'71719702955621440697448',
	'7240412717070196058997225375',
	'10336381493601060622710739350556348',
	'3489438008472462688744320966690059911944',
	'914518782666265638208644233257663391844271624'
  ]
);

my @answers = qw(
        183deadbeef2feed1baddad123468
        123468
        f2feed1baddad123468
);

my $ai;
my @bc;

sub init {
  foreach (0..$#common) {
    $bc[$_] = new Math::Base::Convert(dec,$common[$_]);     # do this separately to facilitate benchmark testing
    my $rv = $bc[$_]->_cnvtst($starters[$ai]->[$_]);
    unless ($benchmark) {
      print "got: $rv\nexp: $answers[$ai]\nnot "
	unless $rv eq $answers[$ai];
      &ok;
    }
  }
}

my $t3 = sub {
  foreach (0..$#common) {
    my $got = $bc[$_]->use32wideTObase;
    unless ($benchmark) {
      print "R got: $got\n  exp: $answers[$ai]\nnot "
        unless $answers[$ai] eq $got;
      &ok;
    }
  }
};

my $t4 = sub {
  foreach (0..$#common) {
    $got = $bc[$_]->useTObaseShortcuts;
    unless ($benchmark) {
      print "W got: $got\n  exp: $answers[$ai]\nnot "
        unless $answers[$ai] eq $got;
      &ok;
    }
  }  
};

#        183deadbeef2feed1baddad123468
#        123468
#        f2feed1baddad123468
foreach (0..$#answers) { # x3
  $ai = $_;
# tests	x5	20-24, 35-39, 50-54
  &init;
# tests x5	25-29, 40-44, 55-59
  &$t3;
# tests x5	30-34, 45-49, 60-64
  &$t4
}

$benchmark = eval {
        require Benchmark;
};

if ($benchmark && exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 3) {

print STDERR "\n\nmake test BENCHMARK=3    t/useTObaseShortcuts.t\n\n";

# tests 65 - 66	benchmark bases 2,4,8

  my $bmr;
  my $bm = {
	'b2->b8_divideTObase'	=> $t1,
	'b2->b8-wide32->base'	=> $t2
  };

# test 65	short
  @testbc = @Sbc;

  print STDERR "\n";
  foreach(sort keys %$bm) {
    $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
    printf STDERR ("\t# %s\t%2.3f ms\n",'short '. $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
  }   
  &ok;
  sleep 1;

# test 66	long
  @testbc = @Lbc;  

  print STDERR "\n";
  foreach(sort keys %$bm) {
    $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
    printf STDERR ("\t# %s\t%2.3f ms\n",'long  '. $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
  }   
  &ok;

# test 67 - 69	benchmark base's 16,32,64,128,256
  $bm = {
	'b16->256_divideTObase'	=> $t3,
	'b16->256-wide32->base'	=> $t4
  };
  foreach (0..$#answers) { # x3
    $ai = $_;
    &init;   
    print STDERR "\n";
    foreach(sort keys %$bm) {
      $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
      printf STDERR ("\t# %s\t%2.3f ms\n",'benchmark '. $answers[$ai] ."\n\t# ". $_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
    }   
    &ok;
  }
} else {
  skipit(5,'benchmark 3');
}  
