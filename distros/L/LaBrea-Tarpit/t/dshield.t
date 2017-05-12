# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..133\n"; }
END {print "not ok 1\n" unless $loaded;}

require LaBrea::Tarpit;
import LaBrea::Tarpit qw(log2_mem cull_threads recurse_hash2txt timezone);

$loaded = 1;
print "ok 1\n";

$test = 2;

umask 027;
if (-d 'tmp') {         # clean up previous test runs
  opendir(T,'tmp');
  @_ = grep(!/^\./, readdir(T));
  closedir T;
  foreach(@_) {
    unlink "tmp/$_";
  }
} else {
  mkdir 'tmp', 0750 unless (-e 'tmp' && -d 'tmp');
}

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

sub recurse {
  my ($tp) = @_;
  &recurse_hash2txt(@_);
  my @txt = split('\n',$$tp);
  @_ = sort @txt;
  $$tp = join("\n",@_,'');
}

sub ds_recurse {
  my $match = shift;
  my ($tp) = @_;
  &recurse_hash2txt(@_);
  my @txt = split('\n',$$tp);
  @_ = sort grep(/$match/o,@txt);
  $$tp = join("\n",@_,'');
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
Persist Activity: 216.82.114.82 3126 -> 63.77.172.50 80			40
## double hit pst=1 ct!=lc						41
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

my %ansa;			# answer array
sub setnow {
  $tarpit{now} = $ansa{now} = $basetime;
}

# input:	\%tarpit,\%ansa,$cull,\@lines,$chktm,$ds
#
#	$cull true = keep cull answers else don't
#

sub loadT {
  my ($tp,$arp,$cull,$ary,$ck,$ds) = @_;
  foreach my $line (@{$ary}) {
    if ( $line =~
#	 time=$1	      src=$2	      sp=$3		 dest=$4	  dp=$5  tnm=$6
#	/^(\d+)\s+.+\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+.+\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+).+(\d+)$/ ) { 
	/^(\d+)\s+.+\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)[^\d]+(\d+\.\d+\.\d+\.\d+)\s+(\d+)[^\d]+(\d+)$/ ) {
#   ignore comment lines
      my ($time,$src,$sp,$dest,$dp,$tnm) = ($1,$2,$3,$4,$5,$6);
      if ($time > $ck) {
	$arp->{at}->{$src}->{$sp}->{dip} = $dest;
	$arp->{at}->{$src}->{$sp}->{dp}  = $dp;
	$arp->{at}->{$src}->{$sp}->{lc}  = $time;
	$arp->{at}->{$src}->{$sp}->{ct}  = $time unless $arp->{at}->{$src}->{$sp}->{ct};
	$arp->{at}->{$src}->{$sp}->{pst} = ($line =~ /persist/i) ? 1 : 0;
	$arp->{at}->{$src}->{$sp}->{DShield}->{$dest}->{$dp} = $time if $ds && $line =~ /Initial/i;
      } elsif ($cull) {			# if cull test comming
  	$arp->{dt}->{$src}->{dp}	= $dp;
	$arp->{dt}->{$src}->{lc}	= $time;
	$arp->{dt}->{$src}->{pst}	= ($line =~ /persist/i) ? 1 : 0;
      }
    }
    $arp->{now} = $basetime - 30;
    print "failed to load line:\n$line\nnot "
	unless log2_mem($tp,$line,1,0,1) ||
	$line =~ /\d+\s+#/;
    &ok;
  }
  foreach(keys %{$arp->{dt}}) {
    delete $arp->{dt}->{$_} if exists $arp->{at}->{$_};
  }
}

my $dfile = './tmp/dshield.cache';
my $chktim = 0;		# load all lines

&loadT(\%tarpit,\%ansa,'',\@lines,$chktim);	# load all, no DShield
my $clr = '';

&recurse(\$clr,\%ansa,'$tp',1);			# save clear text answer;

%ansa = ();
%tarpit = ();

&loadT(\%tarpit,\%ansa,'',\@lines,$chktim,1);	# load with DShield

## my $txt = '';
## &recurse(\$txt,\%ansa,'$tp',1);
## print $txt;

## test 44
## check log2_mem load with DShield support
$txt = '';
&ds_recurse('DShield',\$txt,\%tarpit,'$tp',1);
my $ans = '';
&ds_recurse('DShield',\$ans,\%ansa,'$tp',1);

print "       response:
${txt}  ne expected:
$ans\nnot " unless $txt eq $ans;
&ok;

## cull with defaults, should clear all DShield entries

&setnow;
&cull_threads(\%tarpit);

print "       response:
${txt}  ne expected:
$ans\nnot " unless $txt eq $ans;
&ok;

#### repeat, should write a DShield cache

$ans = '';
%ansa = ();
%tarpit = ();
&loadT(\%tarpit,\%ansa,'',\@lines,$chktim,1);   # load with DShield

$tarpit{LaBrea} = '2.4b3';
&cull_threads(\%tarpit,0,0,0,$dfile);

&ds_recurse('DShield',\$ans,\%ansa,'$tp',1);

$txt = '';
open (F,$dfile);
while (<F>) {
  $txt .= $_;
}

my @ans = split('\n',$ans);
foreach(0..$#ans) {
#			src	      sp 		dest		    dp	      time
  $ans[$_] =~ /(\d+\.\d+\.\d+\.\d+)[^\d]+(\d+)[^\d]+(\d+\.\d+\.\d+\.\d+)[^\d]+(\d+)[^\d]+(\d+)/;
  my $src	= $1;
  my $sp	= $2;
  my $dest	= $3;
  my $dp	= $4;
  my ($sec,$min,$hr,$md,$mon,$yr) = localtime($5);
  $ans[$_] = join(' ', sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yr+1900,++$mon,$md,$hr,$min,$sec),$src,$sp,$dest,$dp);
}


@_ = split('\n', $txt);
my @txt = sort @_;

print 'response ', scalar @ans, ' different from expected ', scalar @txt, "\nnot "
	unless @ans == @txt;
&ok;

@_ = sort @ans;

foreach(0..$#txt) {
  my ($date,$time,$src,$sp,$dest,$dp) = split(' ',$_[$_],6);
  $txt[$_] =~ s/\s+/ /g;
#		 date       time          tza       tzb        uid              src         sp       dest         dp
  $txt[$_] =~ /([^\s]+)\s+([^\s]+)\s+([\+\-0-9]+):([0-9]+)\s+([^\s]+)\s+\d+\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/;
  print "response\n$txt[$_]\nne expected\n$date $time $tarpit{tz} UserID$tarpit{LaBrea}:${LaBrea::Tarpit::VERSION} 1 $src $sp $dest $dp\nnot "
    unless
	$date eq $1 &&
	$time eq $2 &&
	$tarpit{tz} == ($3.$4) &&
	'UserID' . $tarpit{LaBrea} . ':' . $LaBrea::Tarpit::VERSION eq $5 &&
	$src eq $6 &&
	$sp == $7 &&
	$dest eq $8 &&
	$dp =~ /^$9$/;
  &ok;
}
