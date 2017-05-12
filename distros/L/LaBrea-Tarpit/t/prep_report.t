# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..99\n"; }
END {print "not ok 1\n" unless $loaded;}

require LaBrea::Tarpit;
import LaBrea::Tarpit qw(
	log2_mem 
	bandwidth 
	timezone
	cull_threads
	prep_report
	midnight
);

$loaded = 1;
print "ok 1\n";

my $cache_file = './labrea.cache.tmp';

unlink $cache_file if -e $cache_file;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

# wait til beginning of next second
#
sub nextsec {
  my $dAge = time;
  my $time;
  while ( do {$time = time; $dAge == $time} ) {select(undef,undef,undef,0.1);};       # wait for second to tick over
  return $time;
}

my %tarpit;

# load some stuff in memory

my @lines = split(/\n/, q
|## bunch that will be timed out					test
this will timeout: 67.97.64.10 10 -> 29.31.45.100 100			3
this will timeout: 67.97.64.11 11 -> 29.31.45.101 101			4
this will timeout: 67.97.64.12 12 -> 29.31.45.102 102			5
this will timeout: 67.97.64.13 13 -> 29.31.45.103 103			6
this will timeout: 67.97.64.14 14 -> 29.31.45.104 104			7
this will timeout: 67.97.64.15 15 -> 29.31.45.105 105			8
this will timeout: 67.97.64.16 16 -> 29.31.45.106 106			9
this will timeout: 67.97.64.17 17 -> 29.31.45.107 107			10
this will timeout: 67.97.64.18 18 -> 29.31.45.108 108			11
this will timeout: 67.97.64.19 19 -> 29.31.45.109 109			12
this will timeout: 67.97.64.20 20 -> 29.31.45.110 110			13
this will timeout: 67.97.64.21 21 -> 29.31.45.111 111			14
this will timeout: 67.97.64.22 22 -> 29.31.45.112 112			15
this will timeout: 67.97.64.23 23 -> 29.31.45.113 113			16
this will timeout: 67.97.64.24 24 -> 29.31.45.114 114			17
this will timeout: 67.97.64.25 25 -> 29.31.45.115 115			18
this will timeout: 67.97.64.26 26 -> 29.31.45.116 116			19
this will timeout: 67.97.64.27 27 -> 29.31.45.117 117			20
this will timeout: 67.97.64.28 28 -> 29.31.45.118 118			21
this will timeout: 67.97.64.29 29 -> 29.31.45.119 119			22
## single hit, pst=1 ct=lc						23
Persist Activity: 67.97.64.173 61623 -> 63.77.172.50 80			24
## single hit, same IP, different thread				25
Persist Activity: 67.97.64.173 61624 -> 63.77.172.51 80			26
## single hit, same IP, different thread				27
Persist Activity: 67.97.64.173 61625 -> 63.77.172.52 80			28
## double hit, pst=0 ct!=lc						29
Initial Connect (tarpitting): 63.204.44.126 2014 -> 63.77.172.38 80	30
Additional Activity: 63.204.44.126 2014 -> 63.77.172.38 80		31
## single hit, same IP, different thread				32
Additional Activity: 63.204.44.126 2015 -> 63.77.172.39 80		33
## single hit, pst=1 ct=lc						34
Persist Activity: 63.227.234.71 4628 -> 63.77.172.57 80 *		35
## double hit pst=1 ct!=lc						36
Initial Connect (tarpitting): 63.222.243.6 2710 -> 63.77.172.16 80	37
Persist Trapping: 63.222.243.6 2710 -> 63.77.172.16 80			38
## single hit, pst=1 ct=lc						38
need zero pst Activity: 63.14.244.226 3126 -> 63.77.172.50 80		40
## double second thread hit pst=1 ct!=lc				41
Initial Connect (tarpitting): 63.14.244.226 4166 -> 63.77.172.18 80	42
Persist Trapping: 63.14.244.226 4166 -> 63.77.172.18 80 *		43
|);

my $basetime = &nextsec;
my $time =$basetime - 30;			# introduce 30 sec aging

## add time tags for realtime cache aging
for(my $i=$#lines; $i>=0; $i--) {
  $lines[$i] = $time . ' ' . $lines[$i];
  $time -= 60;		# one minute log intervals
}

# input:	\%tarpit,\%ansa,$cull,\@lines,$chktm
#
#	$cull true = keep cull answers else don't
#

foreach my $line (@lines) {
  print "failed to load line:\n$line\nnot "
  unless log2_mem(\%tarpit,$line,1) ||
	$line =~ /\d+\s+#/;
  &ok;
}

## cull with defaults
## test 44
$tarpit{now} = $basetime;
&cull_threads(\%tarpit,'',1000);

=pod

 Prepare arrays of report values from the tarpit memory cache.
 Only the values requested will be filled.

 %hash values:		times in seconds since epoch
 {
 #	teergrubed hosts
	'tg_srcIP'  => \@tgsip,	# b<REQUIRED>
	'tg_sPORT'  => \@tgsp,	# b<REQUIRED>
	'tg_dstIP'  => \@tgdip,
	'tg_dPORT'  => \@tgdp,
	'tg_captr'  => \@tgcap,	# capture epoch time
	'tg_last'   => \@tglst,	# last contact
	'tg_prst'   => \@tgpst,	# persistent [true|false]
 #
 #	threads per teergrubed host
	'th_srcIP'  => \@thsip,	# b<REQUIRED>
	'th_numTH'  => \@thnum,	# number threads this IP
 #
 #	capture statistics	# all fields b<REQUIRED>
	'cs_days'  => number of days to show,
	'cs_date'  => \@csdate,	# epoch midnight of capt date
	'cs_ctd'   => \@csctd,	# captured this date
 #
 #	phantom IP's used (from our IP block)
	'ph_dstIP' => \@phdip,	# b<REQUIRED>
	'ph_prst'  => \@phpst,	# persistent [true|false]
 #
 #	scanning hosts lost
	'sc_srcIP' => \@scsip,	# b<REQUIRED>
	'sc_dPORT' => \@scdp,	# attacked port
	'sc_prst'  => \@scpst,	# persistent [true|false]
	'sc_last'  => \@sclst,	# last contact
 
 # always returned
        $hash{tz}         = timezone, always filled if not present
        $hash{$now}       = epoch time of last load from cache
        $hash{bw}         = bandwidth always filled
        $hash{total_IPs}  = total teergrubed hosts
        $hash{phantoms}   = total phantoms
 # conditionally returned
        $hash{tg_capt}    = active hard captured (need tg_prst)
        $hash{sc_total}   = total dropped scans  
        $hash{sc_capt}    = dropped hard capture (need sc_prst)
}

=cut

my (	@tgsip,@tgsp,@tgdip,@tgdp,@tgcap,@tglst,@tgpst,
	@thsip,@thnum,
	@csdate,@csctd,
	@phdip,@phpst,
	@scsip,@scdp,@scpst,@sclst);

## test 44 is first real test

# basics only, teergrubed hosts
my $out = {
	'tg_srcIP'	=> \@tgsip,
};
# should return empty array
prep_report(\%tarpit,$out);
print "why is tg_srcIP present?\nnot "
	if @tgsip;
&ok;

## test 45
$out = {
	'tg_sPORT'	=> \@tgsp,
};
# should return empty array
prep_report(\%tarpit,$out);
print "why is th_sPORT present?\nnot "
	if @tgsp;
&ok;

## test 46
$out = {
	'tg_dstIP'	=> \@tgdip,
	'tg_dPORT'	=> \@tgdp,
	'tg_captr'	=> \@tgcap, # capture epoch time
	'tg_last'	=> \@tglst, # last contact
	'tg_prst'	=> \@tgpst, # persistent [true|false]
};
prep_report(\%tarpit,$out);
# should return empty lists
print "illegal list present\nnot "
	if	@tgdip ||
		@tgdp ||
		@tgcap ||
		@tglst ||
		@tgpst;
&ok;

## test 47
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
};
prep_report(\%tarpit,$out);
# should return list
print "missing \@tgsip\nnot "
	unless @tgsip;
&ok;

## test 48
print "missing \@tgsp\nnot "
	unless @tgsp;
&ok;

sub tgtxt {
  my ($op) = @_;
  my $txt = '';
  foreach(0..$#tgsip) {
    $txt .=	$tgsip[$_]. ' '.
		$tgsp[$_]. ' ';
    $txt .= $tgdip[$_]. ' ' if $op->{tg_dstIP};
    $txt .= $tgdp[$_]. ' ' if $op->{tg_dPORT};
    $txt .= $tgcap[$_]. ' ' if $op->{tg_captr};
    $txt .= $tglst[$_]. ' ' if $op->{tg_last};
    $txt .= $tgpst[$_]. ' ' if $op->{tg_prst};
    $txt .= "\n";
  }
  $txt;
}

## test 49
my $expected = q
|63.14.244.226 3126 
63.14.244.226 4166 
63.222.243.6 2710 
63.227.234.71 4628 
|;
$_ = &tgtxt($out);
print "	expected:
$expected	ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 50
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_dstIP'	=> \@tgdip,
};

$expected = q
|63.14.244.226 3126 63.77.172.50 
63.14.244.226 4166 63.77.172.18 
63.222.243.6 2710 63.77.172.16 
63.227.234.71 4628 63.77.172.57 
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print " expected:
$expected       ne response:
$_\nnot " unless $expected eq $_;    
&ok;

## test 51
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_dPORT'	=> \@tgdp,
};

$expected = q
|63.14.244.226 3126 80 
63.14.244.226 4166 80 
63.222.243.6 2710 80 
63.227.234.71 4628 80 
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 52
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_captr'	=> \@tgcap, # capture epoch time
};

$expected = q						# space after each of these lines
|63.14.244.226 3126 | . $tarpit{at}->{'63.14.244.226'}->{3126}->{ct} .' '.q|
63.14.244.226 4166 | . $tarpit{at}->{'63.14.244.226'}->{4166}->{ct} .' '.q|
63.222.243.6 2710 | . $tarpit{at}->{'63.222.243.6'}->{2710}->{ct} .' '.q|
63.227.234.71 4628 | . $tarpit{at}->{'63.227.234.71'}->{4628}->{ct} .' '.q|
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 53
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_last'	=> \@tglst, # last contact
};

$expected = q
|63.14.244.226 3126 | . $tarpit{at}->{'63.14.244.226'}->{3126}->{lc} .' '.q|
63.14.244.226 4166 | . $tarpit{at}->{'63.14.244.226'}->{4166}->{lc} .' '.q|
63.222.243.6 2710 | . $tarpit{at}->{'63.222.243.6'}->{2710}->{lc} .' '.q|
63.227.234.71 4628 | . $tarpit{at}->{'63.227.234.71'}->{4628}->{lc} .' '.q|
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print " expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 54
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_prst'	=> \@tgpst, # persistent [true|false]
};

$expected = q
|63.14.244.226 3126 0 
63.14.244.226 4166 6 
63.222.243.6 2710 6 
63.227.234.71 4628 6 
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print " expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

my $tg_capt = $out->{tg_capt};		# see test 99

## test 55 --- all elements
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
	'tg_dstIP'	=> \@tgdip,
	'tg_dPORT'	=> \@tgdp,
	'tg_captr'	=> \@tgcap, # capture epoch time
	'tg_last'	=> \@tglst, # last contact
	'tg_prst'	=> \@tgpst, # persistent [true|false]
};

$expected = q						# space after each of these lines
|63.14.244.226 3126 63.77.172.50 80 |.
	$tarpit{at}->{'63.14.244.226'}->{3126}->{ct}.' '.
	$tarpit{at}->{'63.14.244.226'}->{3126}->{lc}.' '.q|0 
63.14.244.226 4166 63.77.172.18 80 |.
	$tarpit{at}->{'63.14.244.226'}->{4166}->{ct}.' '.
	$tarpit{at}->{'63.14.244.226'}->{4166}->{lc}.' '.q|6 
63.222.243.6 2710 63.77.172.16 80 |.
	$tarpit{at}->{'63.222.243.6'}->{2710}->{ct}.' '.
	$tarpit{at}->{'63.222.243.6'}->{2710}->{lc}.' '.q|6 
63.227.234.71 4628 63.77.172.57 80 |.
	$tarpit{at}->{'63.227.234.71'}->{4628}->{ct}.' '.
	$tarpit{at}->{'63.227.234.71'}->{4628}->{lc}.' '.q|6 
|;
prep_report(\%tarpit,$out);
$_ = &tgtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 56
print 'bad total threads = ',$out->{threads},"\nnot "
	unless $out->{threads} == 4;
&ok;

###### test threads
#        'th_srcIP'  => \@thsip, # b<REQUIRED>
#        'th_numTH'  => \@thnum, # number threads this IP
#
## test 57
$out = {
#	'th_srcIP'	=> \@thsip,
	'th_numTH'	=> \@thnum,
};
prep_report(\%tarpit,$out);
print "why is th_numTH present\nnot "
	if @thnum;
&ok;

sub thtxt {
  my ($op) = @_;
  my $txt = '';
  foreach(0..$#thsip) {
    $txt .= $thsip[$_] .' ';
    $txt .= $thnum[$_] . ' ' if $op->{th_numTH};
    $txt .= "\n";
  }
  $txt;
}

## test 58
$out = {
	'th_srcIP'	=> \@thsip,
#	'th_numTH'	=> \@thnum,
};
prep_report(\%tarpit,$out);
print "why is th_numTH present\nnot "
	if @thnum;
&ok;

## test 59

print "\@thsip is empty\nnot "
	unless @thsip;
&ok;

## test 60
$expected = q
|63.14.244.226 
63.222.243.6 
63.227.234.71 
|;
$_ = &thtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 61
$out = {
	'th_srcIP'	=> \@thsip,
	'th_numTH'	=> \@thnum,
};
prep_report(\%tarpit,$out);
$expected = q
|63.14.244.226 2 
63.222.243.6 1 
63.227.234.71 1 
|;
$_ = &thtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 62
print 'wrong number of threads, ', $out->{th_tot},"\nnot "
	unless $out->{total_IPs} eq 3;
&ok;

#### test phantoms
#      phantom IP's used (from our IP block)
#      'ph_dstIP' => \@phdip,  # b<REQUIRED>
#      'ph_prst'  => \@phpst,  # persistent [true|false]

## test 63
$out = {
#	'ph_dstIP'	=> \@phdip,
	'ph_prst'	=> \@phpst,
};
prep_report(\%tarpit,$out);
print "why is ph_prst present\nnot "
	if @phpst;
&ok;

sub phtxt {
  my ($op) = @_;
  my $txt = '';
  foreach(0..$#phdip) {
    $txt .= $phdip[$_] .' ';
    $txt .= $phpst[$_] . ' ' if $op->{ph_prst};
    $txt .= "\n";
  }
  $txt;
}

## test 64
$out = {
	'ph_dstIP'	=> \@phdip,
#	'ph_prst'	=> \@phpst,
};
prep_report(\%tarpit,$out);
print "why is ph_prst present\nnot "
	if @phpst;
&ok;

## test 65

print "\@phdip is empty\nnot "
	unless @phdip;
&ok;

## test 66
$expected = q
|63.77.172.16 
63.77.172.18 
63.77.172.50 
63.77.172.57 
|;
$_ = &phtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 67
$out = {
	'ph_dstIP'	=> \@phdip,
	'ph_prst'	=> \@phpst,
};
prep_report(\%tarpit,$out);
$expected = q
|63.77.172.16 6 
63.77.172.18 6 
63.77.172.50 0 
63.77.172.57 6 
|;
$_ = &phtxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 68
print 'wrong number of phantoms, ', $out->{phantoms},"\nnot "
	unless $out->{phantoms} eq 4;
&ok;

#### test for scanners
#      scanning hosts lost
#      'sc_srcIP' => \@scsip,  # b<REQUIRED>
#      'sc_dPORT' => \@scdp,   # attacked port
#      'sc_prst'  => \@scpst,  # persistent [true|false]
#      'sc_last'  => \@sclst,  # last contact

## test 69
$out = {
#	'sc_srcIP'	=> \@scsip,
	'sc_dPORT'	=> \@scdp,
	'sc_prst'	=> \@scpst,
	'sc_last'	=> \@sclst,
};
prep_report(\%tarpit,$out);
print "illegal arrays present present\nnot "
	if @scpst || @sclst || @scdp;
&ok;

sub sctxt {
  my ($op) = @_;
  my $txt = '';
  foreach(0..$#scsip) {
    $txt .= $scsip[$_] .' ';
    $txt .= $scdp[$_] .' ' if $op->{sc_dPORT};
    $txt .= $scpst[$_] . ' ' if $op->{sc_prst};
    $txt .= $sclst[$_] . ' ' if $op->{sc_last};
    $txt .= "\n";
  }
  $txt;
}

## test 70
$out = {
	'sc_srcIP'	=> \@scsip,
#	'sc_dPORT'	=> \@scdp,
#	'sc_prst'	=> \@scpst,
#	'sc_last'	=> \@sclst,
};

prep_report(\%tarpit,$out);
print "\@scsip is empty\nnot "
	unless @scsip;
&ok;

## test 71
$expected = q
|63.204.44.126 
67.97.64.10 
67.97.64.11 
67.97.64.12 
67.97.64.13 
67.97.64.14 
67.97.64.15 
67.97.64.16 
67.97.64.17 
67.97.64.173 
67.97.64.18 
67.97.64.19 
67.97.64.20 
67.97.64.21 
67.97.64.22 
67.97.64.23 
67.97.64.24 
67.97.64.25 
67.97.64.26 
67.97.64.27 
67.97.64.28 
67.97.64.29 
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 72
$out = {
	'sc_srcIP'	=> \@scsip,
	'sc_dPORT'	=> \@scdp,
#	'sc_prst'	=> \@scpst,
#	'sc_last'	=> \@sclst,
};
prep_report(\%tarpit,$out);
$expected = q
|63.204.44.126 80 
67.97.64.10 100 
67.97.64.11 101 
67.97.64.12 102 
67.97.64.13 103 
67.97.64.14 104 
67.97.64.15 105 
67.97.64.16 106 
67.97.64.17 107 
67.97.64.173 80 
67.97.64.18 108 
67.97.64.19 109 
67.97.64.20 110 
67.97.64.21 111 
67.97.64.22 112 
67.97.64.23 113 
67.97.64.24 114 
67.97.64.25 115 
67.97.64.26 116 
67.97.64.27 117 
67.97.64.28 118 
67.97.64.29 119 
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 73
$out = {
	'sc_srcIP'	=> \@scsip,
#	'sc_dPORT'	=> \@scdp,
	'sc_prst'	=> \@scpst,
#	'sc_last'	=> \@sclst,
};
prep_report(\%tarpit,$out);
$expected = q
|63.204.44.126 0 
67.97.64.10 0 
67.97.64.11 0 
67.97.64.12 0 
67.97.64.13 0 
67.97.64.14 0 
67.97.64.15 0 
67.97.64.16 0 
67.97.64.17 0 
67.97.64.173 6 
67.97.64.18 0 
67.97.64.19 0 
67.97.64.20 0 
67.97.64.21 0 
67.97.64.22 0 
67.97.64.23 0 
67.97.64.24 0 
67.97.64.25 0 
67.97.64.26 0 
67.97.64.27 0 
67.97.64.28 0 
67.97.64.29 0 
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

my $sc_capt = $out->{sc_capt};		# see test 98

## test 74
$out = {
	'sc_srcIP'	=> \@scsip,
#	'sc_dPORT'	=> \@scdp,
#	'sc_prst'	=> \@scpst,
	'sc_last'	=> \@sclst,
};
prep_report(\%tarpit,$out);
$expected = q
|63.204.44.126 |.$tarpit{dt}->{'63.204.44.126'}->{lc}.' '.q|
67.97.64.10 |.$tarpit{dt}->{'67.97.64.10'}->{lc}.' '.q|
67.97.64.11 |.$tarpit{dt}->{'67.97.64.11'}->{lc}.' '.q|
67.97.64.12 |.$tarpit{dt}->{'67.97.64.12'}->{lc}.' '.q|
67.97.64.13 |.$tarpit{dt}->{'67.97.64.13'}->{lc}.' '.q|
67.97.64.14 |.$tarpit{dt}->{'67.97.64.14'}->{lc}.' '.q|
67.97.64.15 |.$tarpit{dt}->{'67.97.64.15'}->{lc}.' '.q|
67.97.64.16 |.$tarpit{dt}->{'67.97.64.16'}->{lc}.' '.q|
67.97.64.17 |.$tarpit{dt}->{'67.97.64.17'}->{lc}.' '.q|
67.97.64.173 |.$tarpit{dt}->{'67.97.64.173'}->{lc}.' '.q|
67.97.64.18 |.$tarpit{dt}->{'67.97.64.18'}->{lc}.' '.q|
67.97.64.19 |.$tarpit{dt}->{'67.97.64.19'}->{lc}.' '.q|
67.97.64.20 |.$tarpit{dt}->{'67.97.64.20'}->{lc}.' '.q|
67.97.64.21 |.$tarpit{dt}->{'67.97.64.21'}->{lc}.' '.q|
67.97.64.22 |.$tarpit{dt}->{'67.97.64.22'}->{lc}.' '.q|
67.97.64.23 |.$tarpit{dt}->{'67.97.64.23'}->{lc}.' '.q|
67.97.64.24 |.$tarpit{dt}->{'67.97.64.24'}->{lc}.' '.q|
67.97.64.25 |.$tarpit{dt}->{'67.97.64.25'}->{lc}.' '.q|
67.97.64.26 |.$tarpit{dt}->{'67.97.64.26'}->{lc}.' '.q|
67.97.64.27 |.$tarpit{dt}->{'67.97.64.27'}->{lc}.' '.q|
67.97.64.28 |.$tarpit{dt}->{'67.97.64.28'}->{lc}.' '.q|
67.97.64.29 |.$tarpit{dt}->{'67.97.64.29'}->{lc}.' '.q|
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 75
$out = {
	'sc_srcIP'	=> \@scsip,
	'sc_dPORT'	=> \@scdp,
	'sc_prst'	=> \@scpst,
	'sc_last'	=> \@sclst,
};
prep_report(\%tarpit,$out);
$expected = q
|63.204.44.126 80 0 |.$tarpit{dt}->{'63.204.44.126'}->{lc}.' '.q|
67.97.64.10 100 0 |.$tarpit{dt}->{'67.97.64.10'}->{lc}.' '.q|
67.97.64.11 101 0 |.$tarpit{dt}->{'67.97.64.11'}->{lc}.' '.q|
67.97.64.12 102 0 |.$tarpit{dt}->{'67.97.64.12'}->{lc}.' '.q|
67.97.64.13 103 0 |.$tarpit{dt}->{'67.97.64.13'}->{lc}.' '.q|
67.97.64.14 104 0 |.$tarpit{dt}->{'67.97.64.14'}->{lc}.' '.q|
67.97.64.15 105 0 |.$tarpit{dt}->{'67.97.64.15'}->{lc}.' '.q|
67.97.64.16 106 0 |.$tarpit{dt}->{'67.97.64.16'}->{lc}.' '.q|
67.97.64.17 107 0 |.$tarpit{dt}->{'67.97.64.17'}->{lc}.' '.q|
67.97.64.173 80 6 |.$tarpit{dt}->{'67.97.64.173'}->{lc}.' '.q|
67.97.64.18 108 0 |.$tarpit{dt}->{'67.97.64.18'}->{lc}.' '.q|
67.97.64.19 109 0 |.$tarpit{dt}->{'67.97.64.19'}->{lc}.' '.q|
67.97.64.20 110 0 |.$tarpit{dt}->{'67.97.64.20'}->{lc}.' '.q|
67.97.64.21 111 0 |.$tarpit{dt}->{'67.97.64.21'}->{lc}.' '.q|
67.97.64.22 112 0 |.$tarpit{dt}->{'67.97.64.22'}->{lc}.' '.q|
67.97.64.23 113 0 |.$tarpit{dt}->{'67.97.64.23'}->{lc}.' '.q|
67.97.64.24 114 0 |.$tarpit{dt}->{'67.97.64.24'}->{lc}.' '.q|
67.97.64.25 115 0 |.$tarpit{dt}->{'67.97.64.25'}->{lc}.' '.q|
67.97.64.26 116 0 |.$tarpit{dt}->{'67.97.64.26'}->{lc}.' '.q|
67.97.64.27 117 0 |.$tarpit{dt}->{'67.97.64.27'}->{lc}.' '.q|
67.97.64.28 118 0 |.$tarpit{dt}->{'67.97.64.28'}->{lc}.' '.q|
67.97.64.29 119 0 |.$tarpit{dt}->{'67.97.64.29'}->{lc}.' '.q|
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 76
print 'wrong number of scanners, ', $out->{sc_tot},"\nnot "
	unless $out->{sc_total} eq 22;
&ok;

#### test capture stats, but first load additional data
#      capture statistics      # all fields b<REQUIRED>
#      'cs_days'  => number of days to show,
#      'cs_date'  => \@csdate, # epoch midnight of capt date
#      'cs_ctd'   => \@csctd,  # captured this date

# add these records back in as current with old capture dates
@lines = split(/\n/,q
|old guys: 67.97.64.10 10 -> 29.31.45.100 100                   3
old guys: 67.97.64.11 11 -> 29.31.45.101 101                   4
old guys: 67.97.64.14 14 -> 29.31.45.104 104                   7
old guys: 67.97.64.15 15 -> 29.31.45.105 105                   8
old guys: 67.97.64.16 16 -> 29.31.45.106 106                   9
old guys: 67.97.64.17 17 -> 29.31.45.107 107                   10
old guys: 67.97.64.20 20 -> 29.31.45.110 110                   13
old guys: 67.97.64.21 21 -> 29.31.45.111 111                   14
old guys: 67.97.64.22 22 -> 29.31.45.112 112                   15
old guys: 67.97.64.23 23 -> 29.31.45.113 113                   16
old guys: 67.97.64.26 26 -> 29.31.45.116 116                   19
old guys: 67.97.64.29 29 -> 29.31.45.119 119                   22
|);

my $day = 86400;
my $half = $day/2;
my @bins = (4,4,2,1,1);		# sum is # of items above
my $i = 0;
my $k = 0;
foreach(0..$#lines) {
  my $line = $lines[$_];
  print "failed to add:\n$line\nnot "
	unless log2_mem(\%tarpit,$basetime - $_ . ' '. $line,1);
  &ok;
  $line =~ /:\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+/;
# src = $1, sp = $2
# alter the capture time, put into 4 bins
  if ( --$i < 1 ) {
    $i = $bins[$k++];
    $k = 0 if $k > $#bins;
  }
  $tarpit{at}->{$1}->{$2}->{ct} = $basetime - ($day * $k) - $half;
}

## this test the ability to delete dead scanners
## test 89
$out = {
	'sc_srcIP'	=> \@scsip,
#	'sc_dPORT'	=> \@scdp,
#	'sc_prst'	=> \@scpst,
#	'sc_last'	=> \@sclst,
};

prep_report(\%tarpit,$out);

$expected = q
|63.204.44.126 
67.97.64.12 
67.97.64.13 
67.97.64.173 
67.97.64.18 
67.97.64.19 
67.97.64.24 
67.97.64.25 
67.97.64.27 
67.97.64.28 
|;
$_ = &sctxt($out);
print "	expected: 
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## check that additions show up as active
## test 90
$out = {
	'tg_srcIP'	=> \@tgsip,
	'tg_sPORT'	=> \@tgsp,
};
prep_report(\%tarpit,$out);

$expected = q
|63.14.244.226 3126 
63.14.244.226 4166 
63.222.243.6 2710 
63.227.234.71 4628 
67.97.64.10 10 
67.97.64.11 11 
67.97.64.14 14 
67.97.64.15 15 
67.97.64.16 16 
67.97.64.17 17 
67.97.64.20 20 
67.97.64.21 21 
67.97.64.22 22 
67.97.64.23 23 
67.97.64.26 26 
67.97.64.29 29 
|;

$_ = &tgtxt($out);
print "	expected:
$expected	ne response:
$_\nnot " unless $expected eq $_;
&ok;

##### load complete for "capture" stats
#      capture statistics      # all fields b<REQUIRED>
#      'cs_days'  => number of days to show,
#      'cs_date'  => \@csdate, # epoch midnight of capt date 
#      'cs_ctd'   => \@csctd,  # captured this date

## test 91
$out = {
#	'cs_days'	=> 5,		# show 5 days
	'cs_date'	=> \@csdate,
	'cs_ctd'	=> \@csctd,
};
prep_report(\%tarpit,$out);
print "illegal data present\nnot "
	if @csdate || @csctd;
&ok;

## test 92
$out = {
	'cs_days'	=> 5,		# show 5 days
#	'cs_date'	=> \@csdate,
	'cs_ctd'	=> \@csctd,
};
prep_report(\%tarpit,$out);
print "illegal data present, \@csctd\nnot "
	if @csctd;
&ok;

## test 93
$out = {
	'cs_days'	=> 5,		# show 5 days
	'cs_date'	=> \@csdate,
#	'cs_ctd'	=> \@csctd,
};
prep_report(\%tarpit,$out);
print "illegal data present, \@csdate\nnot "
	if @csdate;
&ok;

## test 94
$out = {
	'cs_days'	=> 1,		# attempt 1 day, min is two
	'cs_date'	=> \@csdate,
	'cs_ctd'	=> \@csctd,
};
prep_report(\%tarpit,$out);
print "array data missing\nnot "
	unless @csdate && @csctd;
&ok;

## test 95
$_ = @csdate;
print "wrong number of days, $_\nnot "
	unless $_ == 2;
&ok;

sub cstxt {
  my ($op) = @_;
  my $txt = '';
  foreach(0..$#csdate) {
    $txt .= 	localtime(${$op->{cs_date}}[$_]) . ' ' . 
		${$op->{cs_ctd}}[$_] . "\n";
  }
  $txt;
}
$i = 0;
my %expected;
my $tz = &timezone($basetime);
foreach my $src (keys %{$tarpit{at}}) {
  foreach my $sp (keys %{$tarpit{at}->{$src}}) {
    my $cpt = midnight($tarpit{at}->{$src}->{$sp}->{ct},$tz);
    if (exists $expected{$cpt}) {
      ++$expected{$cpt};
    } else {
      $expected{$cpt} = 1;
    }
    ++$i;
  }
}

my @expected = sort {$b <=> $a} keys %expected;

sub expc {
  my ($ix) = @_;
  $k += $expected{$expected[$ix]};
  my $rv = localtime($expected[$ix]);
  $rv .= ' ';
  $rv .= $expected{$expected[$ix]} . "\n";;
}

$k = 0;
$expected = &expc(0);
$expected .= localtime($expected[1]);
$expected .= ' '; 
$expected .= $i - $expected{$expected[0]}. "\n";


## test 96
$_ = &cstxt($out);
print " expected:
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 97
$out->{cs_days} = 5;
prep_report(\%tarpit,$out);

$k = 0;
$expected = &expc(0);
$expected .= &expc(1);
$expected .= &expc(2);
$expected .= &expc(3);
$expected .= localtime($expected[4]); 
$expected .= ' ';
$expected .= $i - $k . "\n";

$_ = &cstxt($out);
print " expected:
$expected       ne response:
$_\nnot " unless $expected eq $_;
&ok;

## test 98, from test 73
print "got sc_capt=$sc_capt, expected 1\nnot "
	unless $sc_capt == 1;
&ok;

## test 99, from test 54
print "got tg_capt=$tg_capt, expected 3\nnot "
        unless $tg_capt == 3;
&ok;

