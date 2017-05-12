
BEGIN { $| = 1; print "1..133\n"; }
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
use Math::Base::Convert qw(:base);

require './recurse2txt';

my $simulatenew = 0;	# set to 1 for benchmarks

my $benchmark = 0;

# test plan;
#
# setup for numbers of various length for one base
# benchmark conversion times for standard and shortcut
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

my @reg = (
	[533],									# very short
	[0x123456],								# fits in one register
	[0x789abcde, 0x123456],							# two registers
	[0xf0123456, 0x789abcde, 0x123456],					# three
	[0x789abcde, 0xf0123456, 0x789abcde, 0x123456],				# 4
	[0xfedcba98, 0x789abcde, 0xf0123456, 0x789abcde, 0x123456],		# 5
	[0x76543210, 0xfedcba98, 0x789abcde, 0xf0123456, 0x789abcde, 0x123456]	# 6
);

sub bas32  { \@bas32  }
sub bas128 { \@bas128 }
sub bas256 { \@bas256 }

# only test powers of two (2)
my @bases = ( \@{&bin}, \@{&dna}, \@{&oct}, \@{&hex}, \@{&bas32}, \@{&b64}, \@{&bas128}, \@{&bas256} );
my @bnams = qw(   bin       dna       oct       hex       bas32       b64       bas128       bas256  );

my %in = (
  bin => [qw(
	1000010101
	100100011010001010110
	10010001101000101011001111000100110101011110011011110
	1001000110100010101100111100010011010101111001101111011110000000100100011010001010110
	100100011010001010110011110001001101010111100110111101111000000010010001101000101011001111000100110101011110011011110
	10010001101000101011001111000100110101011110011011110111100000001001000110100010101100111100010011010101111001101111011111110110111001011101010011000
	1001000110100010101100111100010011010101111001101111011110000000100100011010001010110011110001001101010111100110111101111111011011100101110101001100001110110010101000011001000010000
 )],
  dna => [qw(
	taccc
	catagcaccct
	catagcaccctcgtatctttggagcgt
	catagcaccctcgtatctttggagcgtggaaacatagcaccct
	catagcaccctcgtatctttggagcgtggaaacatagcaccctcgtatctttggagcgt
	catagcaccctcgtatctttggagcgtggaaacatagcaccctcgtatctttggagcgtgggtgcgatgtttcta
	catagcaccctcgtatctttggagcgtggaaacatagcaccctcgtatctttggagcgtgggtgcgatgtttctacgctcccaagatacaa
 )],
  oct => [qw(
	1025
	4432126
	221505317046536336
	11064254742325715736004432126
	443212636115274675700221505317046536336
	22150531704653633674011064254742325715737667135230
	1106425474232571573600443212636115274675773345651416625031020
 )],
  dec => [qw(
	533
	1193046
	5124095576030430
	22007822920628982378542166
	94522879700260683065598897150409950
	405972677036361916441368285914678332518873752
	1743639370940744633935561489495120884528376069578043920
 )],
  hex => [qw(
	215
	123456
	123456789abcde
	123456789abcdef0123456
	123456789abcdef0123456789abcde
	123456789abcdef0123456789abcdefedcba98
	123456789abcdef0123456789abcdefedcba9876543210
 )],
  b62 => [qw(
	8B
	50mG
	nt2zIAA8u
	1M1s0mWC5r1P9Ay
	8jNYV0IWlg3SwHNKpVtY
	D0aVppMuKI36nsunsAHJ36aSY
	2WQLMo2pQMbq1zeL2FCZdyOFilbPFZK
 )],
  b64 => [qw(
	8L
	4ZHM
	ID5PuchpU
	18qLdYQlDxm4ZHM
	4ZHMU9gytl0ID5PuchpU
	ID5PuchpUy18qLdYQlDx.tBgO
	18qLdYQlDxm4ZHMU9gytlxSkfXsL38G
 )],
  b85 => [
	'6N',
	'1`A-',
	'1=-W5GUc>',
	'1*zQ4qheMgs|qk',
	'1$%ENQ_e^wm5RL(?XZo',
	'1x|h(^RlllR@_dM2+b$su!nC',
	'1tR@^OA7H9k~6zWw%G;~G$1<z~@gP',
  ],
  bas32 => [qw(
	qv
	bencw
	erukz6jvpg1
	sgrlhrgv622ybencw
	ci3fm1e3xtppaerukz6jvpg1
	jdivtytk1n46asgrlhrgv6228nzouy
	bencwpcnlzxxqci3fm1e3xtpp4xf3tb2fimqq
 )],
  bas128 => [
	'4L',
	';$u',
	'9DA#)%^w',
	'1H{i?@lR(0;$u',
	'IQL_9:<z*9DA#)%^w',
	'2ZYv+Qwtw1H{i?@lR(>-=O',
	'aqhUJh!|xIQL_9:<z~&k}7o`yG',
  ],
  bas256 => [
	'2L',
	'Iq=',
	'Iq=?^`|',
	'Iq=?^`|}Iq=',
	'Iq=?^`|}Iq=?^`|',
	'Iq=?^`|}Iq=?^`|:{_@',
	'Iq=?^`|}Iq=?^`|:{_@>~oG',
  ],
  m64 => [qw(
	IV
	EjRW
	SNFZ4mrze
	BI0VniavN7wEjRW
	EjRWeJq83vASNFZ4mrze
	SNFZ4mrze8BI0VniavN7+3LqY
	BI0VniavN7wEjRWeJq83v7cuph2VDIQ
  )]
);

# test 2 - 12	create input for other base's
{
  no strict;
  foreach my $base (sort keys %in) {
    next if $base eq 'hex';	# skip, it is our template
#next unless $base eq 'bas128';
#print "BASE $base\n";  
    my $bc = new Math::Base::Convert(hex => &{$base});
    foreach (0..$#{$in{hex}}) {
      my $str = $bc->_cnvtst($in{hex}->[$_]);
      print 'got: ', $str, "\nexp: ", $in{$base}->[$_], "\nnot "
	unless $str eq $in{$base}->[$_];
    }
    &ok;
#last if $base eq 'bas128';
  }
}

my $haveBI = exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 2 && eval {
	require Math::BigInt;
};

my $ptr;
my $indx;
my $t3;		# BigInt front end
my $t4;

		# below as 'init'
my @bc;		# initialize 'bc' for each base to convert "from" to default
		# this will be used for all further tests

# test 13	Math::BigInt equivalents

if ($haveBI) {
  $t3 = sub {		# convert base to decimal
    my($str,$base,$fhsh) = @{$bc[$ptr]}{qw( nstr fbase fhsh )};
    my $bi = new Math::BigInt(0);
    for(split(//, $str)) {
      while(length($str)) {
        $bi += $fhsh->{substr($str,0,1,'')};
        $bi *= $base;
      }
    }
    $bc[$ptr]->{BigInt} = (''. $bi / $base);
  };

  $t4 = sub {	# BigInt back end
    my($base,$to,$n) = @{$bc[$ptr]}{qw( tbase to BigInt )};
    my $bi = Math::BigInt->new($n);
    my $str = '';    
    while(int($bi)) {
      $str = $to->[($bi % $base)] . $str;
      $bi = $bi/$base;
    }
#    return $str;
    unless ($benchmark) {
      print "got: $str\nexp: $in{$bnams[$indx]}->[$ptr]\nnot "
	unless $str eq $in{$bnams[$indx]}->[$ptr];
      &ok;
    }
$str;
  };
} else {
  skipit(1,'no BigInt or benchmark 2');
}

if ($haveBI) {		# test that it works
  $ptr  = 3;
  $indx = 3;
  $bc[$ptr] = {
	nstr	=> $in{m64}->[$indx],
	fbase	=> scalar(@{&m64}),
	fhsh	=> &basemap(&m64),
	tbase	=> scalar(@{&hex}),
	to	=> &hex,
  };

  &$t3;
  &$t4;
} else {
  skipit(1,'no BigInt or benchmark 2');
}

################### creation verification complete ##################


sub init {
  foreach(0..$#reg) {					# set up conversion numbers
    $bc[$_] = new Math::Base::Convert('m64',$bases[$indx],);
    @{$bc[$_]->{b32str}} = @{$reg[$_]};
#print hexDumper($bc[$_]->{b32str});
    $bc[$_]->{nstr} = $in{m64}->[$_];
    $ptr = $_;
    &$t3 if $haveBI;
#print $bc[$_]->{BigInt},"\n";
  }
}

sub do_a_new {
  my($from,$to) = @{$_[0]}{qw( from to )};
  my $bc = new Math::Base::Convert($from => $to);
  return;
}

my $t1 = sub {
  do_a_new($bc[$ptr]) if $simulatenew;
  my $got = $bc[$ptr]->use32wideTObase;
  unless ($benchmark) {
    print "got: $got\nexp: $in{$bnams[$indx]}->[$ptr]\nnot "
	unless $got eq $in{$bnams[$indx]}->[$ptr];
    &ok;
  }
$got;
};

my $t2 = sub {
  do_a_new($bc[$ptr]) if $simulatenew;
  my $got = $bc[$ptr]->useTObaseShortcuts;
  unless ($benchmark) {
    print "got: $got\nexp: $in{$bnams[$indx]}->[$ptr]\nnot "
	unless $got eq $in{$bnams[$indx]}->[$ptr];
    &ok;
  }
$got;
};

foreach(0..$#bnams) {
  $indx = $_;
  init();						# init this base
  $ptr = 0;
  foreach(0..$#reg) {					# do all numbers for each base
# test 15 - 125 odd
    &$t1;
# test 16 - 126 even
    &$t2;
    $ptr++;
  }
}
$benchmark = eval {
	require Benchmark;
};

if ($benchmark && exists $ENV{BENCHMARK} && $ENV{BENCHMARK} == 2) {

print STDERR "\n\nmake test BENCHMARK=2    t.backend.t\n\n";

  $simulatenew = 1;	# closer to reality, BigInt must do this;

# tests 127 - 133	benchmark bases 2,4,8,16,32,64

  my $bm = {
	'mbc::calcPP'	=> $t1,
	 mbcshortcut	=> $t2
  };

  $bm->{math_bigint} = $t3 if $haveBI;

  my $bmr = {};
#$benchmark = 0;
  print STDERR "\t# benchmark TO base from internal format\n";
  foreach(0..$#bnams) {
    $indx = $_;
    init();
    $ptr = $ptr = 0;
    print STDERR "\t\t  # $bnams[$_]\n";
    foreach(0..$#reg) {
      print STDERR "\t\t\t\t\  # ",$in{hex}->[$_], "\n";
      foreach(sort keys %$bm) {
if ($benchmark) {
        $bmr->{$_} = Benchmark::countit(3,$bm->{$_});
        printf STDERR ("\t# %s\t%2.3f ms\n",$_,$bmr->{$_}->[1] * 1000 / $bmr->{$_}->[5]);
} else {
	&{$bm->{$_}};
}
      }
      $ptr++
    }
    &ok;
  }
} else {
  skipit(7,'no BigInt or benchmark 2');
}  
