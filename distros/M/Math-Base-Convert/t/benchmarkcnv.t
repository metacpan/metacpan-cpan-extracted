BEGIN { $| = 1; print "1..157\n"; }
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

use strict;
#use diagnostics;
use Math::Base::Convert qw(:all);

my $benchmark = 0;

# test plan;
#
# using dec as a non-tested source/destination,
# benchmark:
# From all bases to dec
# from dec TO all bases
#

my @bas32	= ('a'..'z',3,2,6,4,1,8);
my @bas128      = (@{&b85},':',' ',('.') x (128 - 87));	# dummy base's
my @bas256      = (@{&b85},':',' ',('.') x (256 - 87));

my %bas128 = (		# alter 128 base so characters mapped into null upper half
			# are replaced with unused chars in lower half for this test
        84	=> 126,
        82	=> 123,
        78	=> 121,
        76	=> 120,
        75	=> 118,
        74	=> 117,
        73	=> 115,
        71	=> 114,
        70	=> 113,
        69	=> 112,
        67	=> 111,
        66	=> 110,
        65	=> 106,
        64	=> 104,
        63	=> 103,
        62	=> 102,
        60	=> 100,
        59	=>  96,
        58	=>  94,
	57	=>  89,
	56	=>  86,
);


while (my($unused,$replace) = each %bas128) {
  my $tmp = $bas128[$replace];
  $bas128[$replace] = $bas128[$unused];
  $bas128[$unused] = $tmp;
}

my %bas256 = (
        85      => 254,
        83      => 240,
        82      => 222,
        81      => 220,
        80      => 188,
        79      => 186,
        78      => 154,
        77      => 152,
        76      => 120,
        75      => 118,
        74      => 86,
);

while (my($unused,$replace) = each %bas256) {
  my $tmp = $bas256[$replace];
  $bas256[$replace] = $bas256[$unused];
  $bas256[$unused] = $tmp;
}

sub bas32  { \@bas32  }
sub bas128 { \@bas128 }
sub bas256 { \@bas256 }

# only test powers of two (2)
my @bases = ( \@{&bin}, \@{&dna}, \@{&oct}, \@{&dec}, \@{&hex}, \@{&bas32}, \@{&b62}, \@{&b64}, \@{&bas128}, \@{&bas256} );
my @bnams = qw(   bin       dna       oct       dec      hex       bas32        b62      b64       bas128       bas256  );

my %in = (
  bin => [qw(
	100100011010001010110
	10010001101000101011001111000100110101011110011011110
	100100011010001010110011110001001101010111100110111101111000000010010001101000101011001111000100110101011110011011110
	1001000110100010101100111100010011010101111001101111011110000000100100011010001010110011110001001101010111100110111101111111011011100101110101001100001110110010101000011001000010000
 )],
  dna => [qw(
	catagcaccct
	catagcaccctcgtatctttggagcgt
	catagcaccctcgtatctttggagcgtggaaacatagcaccctcgtatctttggagcgt
	catagcaccctcgtatctttggagcgtggaaacatagcaccctcgtatctttggagcgtgggtgcgatgtttctacgctcccaagatacaa
 )],
  oct => [qw(
	4432126
	221505317046536336
	443212636115274675700221505317046536336
	1106425474232571573600443212636115274675773345651416625031020
 )],
  dec => [qw(
	1193046
	5124095576030430
	94522879700260683065598897150409950
	1743639370940744633935561489495120884528376069578043920
 )],
  hex => [qw(
	123456
	123456789abcde
	123456789abcdef0123456789abcde
	123456789abcdef0123456789abcdefedcba9876543210
 )],
  b62 => [qw(
	50mG
	nt2zIAA8u
	8jNYV0IWlg3SwHNKpVtY
	2WQLMo2pQMbq1zeL2FCZdyOFilbPFZK
 )],
  b64 => [qw(
	4ZHM
	ID5PuchpU
	4ZHMU9gytl0ID5PuchpU
	18qLdYQlDxm4ZHMU9gytlxSkfXsL38G
 )],
  b85 => [
	'1`A-',
	'1=-W5GUc>',
	'1$%ENQ_e^wm5RL(?XZo',
	'1tR@^OA7H9k~6zWw%G;~G$1<z~@gP',
  ],
  bas32 => [qw(
	bencw
	erukz6jvpg1
	ci3fm1e3xtppaerukz6jvpg1
	bencwpcnlzxxqci3fm1e3xtpp4xf3tb2fimqq
 )],
  bas128 => [
	';$u',
	'9DA#)%^w',
	'IQL_9:<z*9DA#)%^w',
	'aqhUJh!|xIQL_9:<z~&k}7o`yG',
  ],
  bas256 => [
	'Iq=',
	'Iq=?^`|',
	'Iq=?^`|}Iq=?^`|',
	'Iq=?^`|}Iq=?^`|:{_@>~oG',
  ],
  m64 => [qw(
	EjRW
	SNFZ4mrze
	EjRWeJq83vASNFZ4mrze
	BI0VniavN7wEjRWeJq83v7cuph2VDIQ
  )]
);

my $haveBI = exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 1 && eval {
	require Math::BigInt;
};

my $ptr;
my $src;
my $dest;
my $t1;
my $t2;
my $t3;

		# below as 'init'
my $bc;		# initialize 'bc' for each base to convert
		# this will be used for all further tests

# test 2	Math::BigInt equivalents

if ($haveBI) {
  $t1 = sub {
    my($fbase,$fhsh,$tbase,$to) = @{$bc}{qw( fbase fhsh tbase to)};
    my $bi = new Math::BigInt(0);
    my $str = $in{$src}->[$ptr];
    for(split(//, $str)) {
      while(length($str)) {
        $bi += $fhsh->{substr($str,0,1,'')};
        $bi *= $fbase;
      }
    }
    $bi = $bi / $fbase;
# converted
    $str = '';    
    while(int($bi)) {
      $str = $to->[($bi % $tbase)] . $str;
      $bi = $bi/$tbase;
    }
#    return $str;
    unless ($benchmark) {
      print "got: $str\nexp: $in{$dest}->[$ptr]\nnot "
	unless $str eq $in{$dest}->[$ptr];
      &ok;
    }
    $str;
  };
} else {
  $t1 = sub {
#    skipit(1) unless $benchmark;
    &ok;
  };
}

$ptr	= 3;
$bc	= new Math::Base::Convert($bases[0],$bases[$#bnams]);
$src	= $bnams[0];
$dest	= $bnams[$#bnams];

if ($haveBI) {		# test that it works
  &$t1;
} else {
  skipit(1,'no BigInt or benchmark 1');
}

$t2 = sub {
  my $str = $bc->cnv($in{$src}->[$ptr]);
  unless ($benchmark) {
    print "got: $str\nexp: $in{$dest}->[$ptr]\nnot "
	unless $str eq $in{$dest}->[$ptr];
    &ok;
  }
  $str;
};

$t3 = sub {
#  my $str = $bc->cnv($in{$src}->[$ptr]);
# do it the slow way with function
  my $str = cnvabs($in{$src}->[$ptr],@{$bc}{qw(from to)});
  unless ($benchmark) {
    print "got: $str\nexp: $in{$dest}->[$ptr]\nnot "
	unless $str eq $in{$dest}->[$ptr];
    &ok;
  }
  $str;
};

# test 3	check that method works
&$t2;

# test 4	check that function works
&$t3;

# test 5 - 76	check conversion TO decimal
foreach (0..$#bnams) {
  next if $bnams[$_] eq 'dec' || $bnams[$_] eq 'm64';
  my $i = $_;
  $src	= $bnams[$_];
  $dest	= 'dec';
  foreach (0..$#{$in{$dest}}) {
    $ptr = $_;
    $bc = new Math::Base::Convert($bases[$i],$dest);
    &$t1;
    &$t2;
  }
}

# test 77 - 148	check conversion FROM decimal
foreach (0..$#bnams) {
  next if $bnams[$_] eq 'dec' || $bnams[$_] eq 'm64';
  my $i = $_;
  $dest	= $bnams[$_];
  $src	= 'dec';
  foreach (0..$#{$in{$src}}) {
    $ptr = $_;
    $bc = new Math::Base::Convert($src,$bases[$i]);
    &$t1;
    &$t2;
  }
}

my $fln;
sub formlines {
  my $str  = shift;
  print STDERR $str,"\n";
  if ($haveBI) {
    printf STDERR ("%6s%10.3fms%14.3fms%14.3fms\n",$fln,@_);
  } else {
    printf STDERR ("%6s%10.3fms%14.3fms%14s\n",$fln,@_,'missing');
  }
  $fln = '';
}

$benchmark = eval {
	require Benchmark;
};

if ($benchmark && exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 1) {

  my $format   = 1;
  my $countoff = 1;

#$countoff = 0;

  print STDERR "\n\nmake test BENCHMARK=1    t.benchmarkcnv.t\n\n" unless $format;

# tests 149 - 183	benchmark bases

  my $bm = {
	'cnv-meth'	=> $t2,
	'cnv_func'	=> $t3,
  };

  $bm->{'math::bi'} = $t1 if $haveBI;

#$count = 0;

  my $stderr;

my $sep = '-------------------------------------------------------
';
  if ($format && $countoff) {
    print STDERR q|
  Benchmarks are FROM and TO decimal. The decimal test set is:

|;

  foreach(0..$#{$in{dec}}) {
    print STDERR "\t",$in{dec}->[$_],"\n";
  }
  print STDERR q|

  t/benchmarkcnv.t
  make test BENCHMARK=1		FROM base to 'dec'
             Math::Base::Convert     using Math::BigInt
           method         function       function
         $bc->cnv(n)       cnv(n)        convert(n)
|;
  } else {
    print STDERR "\n\t# benchmark various => decimal\n\n";
  }

  foreach (0..$#bnams) {
    next if $bnams[$_] eq 'dec' || $bnams[$_] eq 'm64';
    print STDERR $sep if $format;
    my $i = $_;
    $fln = $src  = $bnams[$_];
    $dest = 'dec';
    foreach (0..$#{$in{$dest}}) {
      $ptr = $_;
      $bc = new Math::Base::Convert($bases[$i],$dest);
      print STDERR "\t\t$src  # $in{$src}->[$_]\n" unless $format;
      my $bmr = {};
      my @t;
      foreach(sort { $b cmp $a } keys %$bm) {
if ($benchmark && $countoff) {
        $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
} else {
    $bm->{$_}->();
}
if ($benchmark && ! $format) {
        printf STDERR ("\t# %s\t%2.3f ms\n",$_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
} else {
        unshift @t, $bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5] if $countoff;
}
      }
if ($benchmark && $format && $countoff) {
#      $bs = $src;
      formlines($in{$src}->[$ptr],@t);
}

    }
  }

  if ($format && $countoff) {
    print STDERR q|

  t/benchmarkcnv.t
  make test BENCHMARK=1		from 'dec' TO base
             Math::Base::Convert     using Math::BigInt
           method         function       function
         $bc->cnv(n)       cnv(n)        convert(n)
|;
  } else {
    print STDERR "\n\t# benchmark decimal => various bases\n\n";
  }

  foreach (0..$#bnams) {
    next if $bnams[$_] eq 'dec' || $bnams[$_] eq 'm64';
    print STDERR $sep if $format;
    my $i = $_;
    $fln = $dest = $bnams[$_];
    $src  = 'dec';
    foreach (0..$#{$in{$src}}) {
      $ptr = $_;
      $bc = new Math::Base::Convert($src,$bases[$i]);
      print STDERR "\t\t$dest  # $in{$dest}->[$_]\n" unless $format;
      my $bmr = {};
      my @t;
      foreach(sort { $b cmp $a } keys %$bm) {
if ($benchmark && $countoff) {
        $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
} else {
    $bm->{$_}->();
}
if ($benchmark && ! $format) {
        printf STDERR ("\t# %s\t%2.3f ms\n",$_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
} else {
        unshift @t, $bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5] if $countoff;
}
      }
if ($benchmark && $format && $countoff) {
      formlines($in{$dest}->[$ptr],@t);
}

    }
    &ok;
  }
} else {
  skipit(9,'no BigInt or benchmark 1');
}  
