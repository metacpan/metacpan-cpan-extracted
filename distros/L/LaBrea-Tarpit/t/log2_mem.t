# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}

use Time::Local;
use lib qw( ./ );
require 'tz_test_adj.pl';
require LaBrea::Tarpit;
import LaBrea::Tarpit qw(log2_mem bandwidth recurse_hash2txt);

my $expect = new LaBrea::Tarpit::tz_test_adj;

$loaded = 1;
print "ok 1\n";

sub recurse {
  my ($tp) = @_;
  &recurse_hash2txt(@_);
  my @txt = split('\n',$$tp);
  @_ = sort @txt;   
  $$tp = join("\n",@_,'');
}

sub ok {
  print "ok $test\n";
  ++$test;
}

sub figure_yr {
  my ($mon) = @_;
  my $now = time;
  my ($nowmo,$nowyr) = (localtime(time))[4,5];
  return ($mon > $nowmo)             # roll over to new year??
	? $nowyr -1
	: $nowyr;
}
  
my %tarpit;
my $year = &figure_yr(10);	# year for month 10 (November, below)

$tarpit{pt} = 3600;		# hourly data collection

my @lines = split(/\n/,q
|Nov 30 14:31:40 h174 /usr/local/bin/LaBrea: Current average bw: 145 (bytes/sec)
Nov 30 14:31:36 h174 /usr/local/bin/LaBrea: Persist Activity: 67.97.64.173 61623 -> 63.77.172.50 80
Nov 30 14:31:39 h174 /usr/local/bin/LaBrea: Initial Connect (tarpitting): 63.204.44.126 2014 -> 63.77.172.39 80
Nov 30 14:31:40 h174 /usr/local/bin/LaBrea: Additional Activity: 63.204.44.126 2014 -> 63.77.172.39 80
Nov 30 14:31:41 h174 /usr/local/bin/LaBrea: Persist Trapping: 63.204.44.126 2014 -> 63.77.172.39 80 *
|);

#### test line addition of syslog
$test = 2;

my $hrs = 24;				# port stat collection interval

## ignore non-LaBrea lines

($_ = $lines[0]) =~ s/LaBrea/RandomStuff/;
print "accepted bad line:\n$_\nnot "
	if log2_mem(\%tarpit,$_) || keys %tarpit > 1;
&ok;

## accept
my $lineno = 0;
## test 3
print "did not accept line:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],'',$hrs) &&
	  $tarpit{bw} == 145;
&ok;

## accept
$lineno = 1;
## test4
my ($src,$sp,$crap,$dest,$dp) = qw(67.97.64.173 61623 -> 63.77.172.50 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],'',$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(36,31,14,30,10,$year) &&
	  $_->{lc} == timelocal(36,31,14,30,10,$year) &&
	  $_->{pst};
&ok;

## accept
$lineno = 2;
## test 5
($src,$sp,$crap,$dest,$dp) = qw(63.204.44.126 2014 -> 63.77.172.39 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],'',$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(39,31,14,30,10,$year) &&
	  $_->{lc} == timelocal(39,31,14,30,10,$year) &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 3;
## test 6
($src,$sp,$crap,$dest,$dp) = qw(63.204.44.126 2014 -> 63.77.172.39 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],'',$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(39,31,14,30,10,$year) &&
	  $_->{lc} == timelocal(40,31,14,30,10,$year) &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 4;
## test 7
($src,$sp,$crap,$dest,$dp) = qw(63.204.44.126 2014 -> 63.77.172.39 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],'',$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(39,31,14,30,10,$year) &&
	  $_->{lc} == timelocal(41,31,14,30,10,$year) &&
	  $_->{pst};
&ok;

#### test line addition of STDOUT log by date

@lines = split(/\n/,q
|Sat Dec  1 13:11:07 2001 Persist Activity: 63.227.234.71 4628 -> 63.77.172.57 81 *
Current average bw: 15 (bytes/sec)
Sat Dec  1 13:12:05 2001 Initial Connect (tarpitting): 63.222.243.6 2710 -> 63.77.172.16 81
Sat Dec  1 13:12:06 2001 Additional Activity: 63.222.243.6 2710 -> 63.77.172.16 81 *
Sat Dec  1 13:12:07 2001 Persist Trapping: 63.222.243.6 2710 -> 63.77.172.16 81
|);

## accept
$lineno = 0;
## test 8
($src,$sp,$crap,$dest,$dp) = qw(63.227.234.71 4628 -> 63.77.172.57 81);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(07,11,13,1,11,101) &&
	  $_->{lc} == timelocal(07,11,13,1,11,101) &&
	  $_->{pst};
&ok;

## accept   
$lineno = 1;   
## test 9
print "failed to accept:\n$lines[$lineno]\nnot "
unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	bandwidth(\%tarpit) == 15;
&ok;

## accept
$lineno = 2;
## test 10
($src,$sp,$crap,$dest,$dp) = qw(63.222.243.6 2710 -> 63.77.172.16 81);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1),$hrs &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(05,12,13,1,11,101) &&
	  $_->{lc} == timelocal(05,12,13,1,11,101) &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 3;
## test 11
($src,$sp,$crap,$dest,$dp) = qw(63.222.243.6 2710 -> 63.77.172.16 81);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(05,12,13,1,11,101) &&
	  $_->{lc} == timelocal(06,12,13,1,11,101) &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 4;
## test 12
($src,$sp,$crap,$dest,$dp) = qw(63.222.243.6 2710 -> 63.77.172.16 81);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == timelocal(05,12,13,1,11,101) &&
	  $_->{lc} == timelocal(07,12,13,1,11,101) &&
	  $_->{pst};
&ok;

#### test line addition of STDOUT log by time

@lines = split(/\n/,q
|1007243462 Persist Activity: 216.82.114.82 3126 -> 63.77.172.50 80
1007243495 Initial Connect (tarpitting): 63.14.244.226 4166 -> 63.77.172.18 80
1007243499 Additional Activity: 63.14.244.226 4166 -> 63.77.172.18 80
1007243541 Persist Trapping: 63.14.244.226 4166 -> 63.77.172.18 80 *
Current average bw: 8 (bytes/sec)
|);

## accept
$lineno = 0;
## test 13
($src,$sp,$crap,$dest,$dp) = qw(216.82.114.82 3126 -> 63.77.172.50 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == 1007243462 &&
	  $_->{lc} == 1007243462 &&
	  $_->{pst};
&ok;

## accept
$lineno = 1;
## test 14
($src,$sp,$crap,$dest,$dp) = qw(63.14.244.226 4166 -> 63.77.172.18 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == 1007243495 &&
	  $_->{lc} == 1007243495 &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 2;
## test 15
($src,$sp,$crap,$dest,$dp) = qw(63.14.244.226 4166 -> 63.77.172.18 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == 1007243495 &&
	  $_->{lc} == 1007243499 &&
	  ! $_->{pst};
&ok;

## accept
$lineno = 3;
## test 16
($src,$sp,$crap,$dest,$dp) = qw(63.14.244.226 4166 -> 63.77.172.18 80);
print "failed to accept:\n$lines[$lineno]\nnot "
	unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	  ($_ = $tarpit{at}->{$src}->{$sp}) &&
	  $_->{dip} eq $dest &&
	  $_->{dp} == $dp &&
	  $_->{ct} == 1007243495 &&
	  $_->{lc} == 1007243541 &&
	  $_->{pst};
&ok;

## accept   
$lineno = 4;
## test 17
print "failed to accept:\n$lines[$lineno]\nnot "
unless log2_mem(\%tarpit,$lines[$lineno],1,$hrs) &&
	bandwidth(\%tarpit) == 8;
&ok;

#### check collection of port statistics
## test 18

my $max = (1007243541 > $expect->{1007159501})
	? 1007243541
	: $expect->{1007159501};

my $txt = qq
|\$tp->{at}->{216.82.114.82}->{3126}->{ct} = 1007243462
\$tp->{at}->{216.82.114.82}->{3126}->{dip} = 63.77.172.50
\$tp->{at}->{216.82.114.82}->{3126}->{dp} = 80
\$tp->{at}->{216.82.114.82}->{3126}->{lc} = 1007243462
\$tp->{at}->{216.82.114.82}->{3126}->{pst} = 6
\$tp->{at}->{63.14.244.226}->{4166}->{ct} = 1007243495
\$tp->{at}->{63.14.244.226}->{4166}->{dip} = 63.77.172.18
\$tp->{at}->{63.14.244.226}->{4166}->{dp} = 80
\$tp->{at}->{63.14.244.226}->{4166}->{lc} = 1007243541
\$tp->{at}->{63.14.244.226}->{4166}->{pst} = 6
\$tp->{at}->{63.204.44.126}->{2014}->{ct} = $expect->{1007159499}
\$tp->{at}->{63.204.44.126}->{2014}->{dip} = 63.77.172.39
\$tp->{at}->{63.204.44.126}->{2014}->{dp} = 80
\$tp->{at}->{63.204.44.126}->{2014}->{lc} = $expect->{1007159501}
\$tp->{at}->{63.204.44.126}->{2014}->{pst} = 6
\$tp->{at}->{63.222.243.6}->{2710}->{ct} = $expect->{1007241125}
\$tp->{at}->{63.222.243.6}->{2710}->{dip} = 63.77.172.16
\$tp->{at}->{63.222.243.6}->{2710}->{dp} = 81
\$tp->{at}->{63.222.243.6}->{2710}->{lc} = $expect->{1007241127}
\$tp->{at}->{63.222.243.6}->{2710}->{pst} = 6
\$tp->{at}->{63.227.234.71}->{4628}->{ct} = $expect->{1007241067}
\$tp->{at}->{63.227.234.71}->{4628}->{dip} = 63.77.172.57
\$tp->{at}->{63.227.234.71}->{4628}->{dp} = 81
\$tp->{at}->{63.227.234.71}->{4628}->{lc} = $expect->{1007241067}
\$tp->{at}->{63.227.234.71}->{4628}->{pst} = 6
\$tp->{at}->{67.97.64.173}->{61623}->{ct} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{dip} = 63.77.172.50
\$tp->{at}->{67.97.64.173}->{61623}->{dp} = 80
\$tp->{at}->{67.97.64.173}->{61623}->{lc} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{pst} = 6
\$tp->{bw} = 8
\$tp->{now} = $max
\$tp->{pt} = 3600
|;

delete $tarpit{ph};	# not testing this right now

my $ans = '';
&recurse(\$ans,\%tarpit,'$tp',1);
print "       response:
${ans}  ne expected:
$txt\nnot " unless $txt eq $ans;
&ok;

