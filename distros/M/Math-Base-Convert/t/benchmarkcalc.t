# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..70\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(dec b62);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

my $benchmark = 0;

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

my @short = qw(
999999999999999
88888888888888
7777777777777
666666666666
55555555555
4444444444
333333333
22222222
1111111
121212
23232
3434
454
56
6
);

my @shortexp = qw(
4zXyLE1Gv
peWcv72o
2cVN8VbP
bJHboo2
YDLrRF
4QMr1O
myDe5
1vf0W
4F39
vx2
62I
To
7k
U
6
);

my @long = qw(
10000000000000001000000000000000
1234567890123456712345678901234567
111111111111111111111111111111111111
22222222222222222222222222222222222222
3333333333333333333333333333333333333333
444444444444444444444444444444444444444444
55555555555555555555555555555555555555555555
6666666666666666666666666666666666666666666666
777777777777777777777777777777777777777777777777
88888888888888888888888888888888888888888888888888
9999999999999999999999999999999999999999999999999999
121212121212121212121212121121212121212121212121212121
23232323232323232323232323232323232323232323232323232323
3434343434343434343434343434334343434343434343434343434343
454545454545454545454545454545454545454545454545454545454545
56565656565656565656565656565655656565656565656565656565656565
6767676767676767676767676767676767676767676767676767676767676767
787878787878787878787878787878787787878787878787878787878787878787
89898989898989898989898989898989898989898989898989898989898989898989
);

my @longexp = qw(
3nLqycrSaCzgSYXTTG
6JGUpwFOWWt2Q9OAcD5
9MkhUm3ZJsNRLe45h167
vxTrLNaT8EURqlnb0TxIW
1ek09bCYloWZzfJI4EanAIR
2E8lEql96GZx4tQiMF2ZoYtm
5kUPEv6DmuG3G2arS6L1NlVcf
aktZYocQbxnp7mcdWJ51twqHI6
jrd7hDyacntngvLFzQa7rymfAkx
zPAsR5bPEOHi1RHAm49vIN310Y9G
1316FmjUYeyZydnWAt2xg3LZYlg9Aj
cI5Uo7wTx5zfeyuQLGh0vEs9Bd5vp7
DijBjTWH0CSCLkEp7It3YXhxLv9h9E7
1vGT5fbUIYYm4fsNTNCteIMfs9JAD20w7
3e0ntjunknzy3bIy3DS0zKglcBBO5lk2jv
6trEdWTDusEf0QppURuThYQ73pntZfCWHfT
cuG8H3RVZzhEGyHUe5Yl5ljTjaJ4RcpXahT9
nsCAz0upn2A8zJCpHh1MZ6O8AYiLaG7GdFPMf
Hb298A1UABPtSWFP8FlWXAU4PvH5T5mSPu9AzH
);

$test = 2;

my $bcto = new Math::Base::Convert(dec,b62);
my $bcfrom = new Math::Base::Convert(b62,dec);

sub equal {
  my($a,$b) = @_;
  if ($a.$b =~ /\D/) {
    return $a eq $b;
  } else {
    return $a == $b;
  }
}

my $tshortfrom = sub {
  foreach(0..$#short) {
    my $bc = $bcto->_cnv($short[$_]);
    $bc->useFROMbaseto32wide;
    my $str = $bc->use32wideTObase;
    unless ($benchmark) {
      print "got: $str\nexp: $shortexp[$_]\nnot "
	unless equal($str, $shortexp[$_]);
      &ok;
    }
  }
};

my $tshortto = sub {
  foreach(0..$#shortexp) {
    my $bc = $bcfrom->_cnv($shortexp[$_]);
    $bc->useFROMbaseto32wide;
    my $num = $bc->use32wideTObase;
    unless ($benchmark) {
      print "got: $num\nexp: $short[$_]\nnot "
	unless equal($num, $short[$_]);
      &ok;
    }

  }
};

my $tlongfrom = sub {
  foreach(0..$#long) {
    my $bc = $bcto->_cnv($long[$_]);
    $bc->useFROMbaseto32wide;
    my $str = $bc->use32wideTObase;
    unless ($benchmark) {
      print "got: $str\nexp: $longexp[$_]\nnot "
	unless equal($str, $longexp[$_]);
      &ok;
    }
  }
};

my $tlongto = sub {
  foreach(0..$#longexp) {
    my $bc = $bcfrom->_cnv($longexp[$_]);
    $bc->useFROMbaseto32wide;
    my $num = $bc->use32wideTObase;
    unless ($benchmark) {
      print "got: $num\nexp: $long[$_]\nnot "
	unless equal($num, $long[$_]);
      &ok;
    }
  }
};

&$tshortfrom;		# test 2 - 16
&$tshortto;		# test 17 - 31
&$tlongfrom;		# test 32 - 50
&$tlongto;		# test 51 - 69

$benchmark = eval {
	require Benchmark;
};

if ($benchmark && exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 3) {

print STDERR "\n\nmake test BENCHMARK=3     t.benchmarkcalc.t\n\n";

  my $bm = {
	_4long_from	=> $tlongfrom,
	_3long_to	=> $tlongto,
	_2short_from	=> $tshortfrom,
	_1short_to	=> $tshortto
  };

  my $bmr = {};
  print STDERR "\n";
  foreach(sort keys %$bm) {
    $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
    $_ =~ /([a-z]+)_+([a-z]+)/;
    my $title = "$1 $2";
    my $len = $title =~ /short/ ? @short : @long;
    printf STDERR ("\t# %s\t%2.3f ms\n",$title,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5] / $len);
  }

  &ok;

} else {
  &skipit(1,'benchmark 3');
}

