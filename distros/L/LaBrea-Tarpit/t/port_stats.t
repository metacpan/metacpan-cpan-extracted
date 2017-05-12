# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..46\n"; }
END {print "not ok 1\n" unless $loaded;}

require LaBrea::Tarpit;
import LaBrea::Tarpit qw(
	log2_mem
	cull_threads
	recurse_hash2txt
	prep_report
	);

$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub recurse {
  my ($tp) = @_;
  &recurse_hash2txt(@_);
  my @txt = split('\n',$$tp);
  @_ = sort @txt;   
  $$tp = join("\n",@_,'');
}

my %tarpit = ( 'pt'	=> 3600 );		# collect data hourly

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

my $time = 1018031772;		# Fri Apr  5 10:36:12 2002
my $t = $time;
## add time tags for realtime cache aging
for(my $i=$#lines; $i>=0; $i--) {
  $lines[$i] = $t . ' ' . $lines[$i];
  $t -= 900;		# one 1/4 hour log intervals
}

foreach my $line (@lines) {
  print "failed to load line:\n$line\nnot "
	unless  log2_mem(\%tarpit,$line,1,1) ||	# note hours need only be true here
		$line =~ /\d+\s+#/;
  &ok;
}

# strip all but $tp->{ph} and $tp->{now}lines from string
#
# input:	txt
# return:	stripped txt
sub strip {
  my ($in) = @_;
  @_ = split('\n',$in);
  my $out = '';
  foreach (@_) {
    next unless $_ =~ /\{ph\}|\{now\}/;
    $out .= $_ . "\n";
  }
  return $out;
}

## check load
## test 44
my $txt = q
|$tp->{now} = 1018031772
$tp->{ph}->{1017993600}->{100} = 1
$tp->{ph}->{1017993600}->{101} = 1
$tp->{ph}->{1017997200}->{102} = 1
$tp->{ph}->{1017997200}->{103} = 1
$tp->{ph}->{1017997200}->{104} = 1
$tp->{ph}->{1017997200}->{105} = 1
$tp->{ph}->{1018000800}->{106} = 1
$tp->{ph}->{1018000800}->{107} = 1
$tp->{ph}->{1018000800}->{108} = 1
$tp->{ph}->{1018000800}->{109} = 1
$tp->{ph}->{1018004400}->{110} = 1
$tp->{ph}->{1018004400}->{111} = 1
$tp->{ph}->{1018004400}->{112} = 1
$tp->{ph}->{1018004400}->{113} = 1
$tp->{ph}->{1018008000}->{114} = 1
$tp->{ph}->{1018008000}->{115} = 1
$tp->{ph}->{1018008000}->{116} = 1
$tp->{ph}->{1018008000}->{117} = 1
$tp->{ph}->{1018011600}->{118} = 1
$tp->{ph}->{1018011600}->{119} = 1
$tp->{ph}->{1018011600}->{80} = 1
$tp->{ph}->{1018015200}->{80} = 2
$tp->{ph}->{1018018800}->{80} = 2
$tp->{ph}->{1018022400}->{80} = 2
$tp->{ph}->{1018026000}->{80} = 3
$tp->{ph}->{1018029600}->{80} = 2
|;

my $ans = '';
&recurse(\$ans,\%tarpit,'$tp',1);
$ans = &strip($ans);
print "       response:
${ans}  ne expected:
$txt\nnot " unless $txt eq $ans;
&ok;

## cull with defaults
## test 45
$ans = q
|$tp->{now} = 1018031772
$tp->{ph}->{1018004400}->{110} = 1
$tp->{ph}->{1018004400}->{111} = 1
$tp->{ph}->{1018004400}->{112} = 1
$tp->{ph}->{1018004400}->{113} = 1
$tp->{ph}->{1018008000}->{114} = 1
$tp->{ph}->{1018008000}->{115} = 1
$tp->{ph}->{1018008000}->{116} = 1
$tp->{ph}->{1018008000}->{117} = 1
$tp->{ph}->{1018011600}->{118} = 1
$tp->{ph}->{1018011600}->{119} = 1
$tp->{ph}->{1018011600}->{80} = 1
$tp->{ph}->{1018015200}->{80} = 2
$tp->{ph}->{1018018800}->{80} = 2
$tp->{ph}->{1018022400}->{80} = 2
$tp->{ph}->{1018026000}->{80} = 3
$tp->{ph}->{1018029600}->{80} = 2
|;
## cull_threads(\%tarpit,timeout_in_seconds,scanners,port_hrs)

my $hrs = 8;			# keep N hours of port stats

$tarpit{now} = $time;
&cull_threads(\%tarpit,0,0,$hrs);
$txt = '';
&recurse(\$txt,\%tarpit,'$tp',1);
$txt = &strip($txt);
print "       response:
${txt}  ne expected:   
$ans\nnot " unless $txt eq $ans;
&ok;

## check output of prep report
## test 46
my (@ports, @stats);
my $report = {
	'port_intvls'	=> 7,
	'ports'		=> \@ports,
	'portstats'	=> \@stats,
};
&prep_report(\%tarpit,$report);

$txt = q
|port 80 -> 2 3 2 2 2 1 0 
port 114 -> 0 0 0 0 0 0 1 
port 115 -> 0 0 0 0 0 0 1 
port 116 -> 0 0 0 0 0 0 1 
port 117 -> 0 0 0 0 0 0 1 
port 118 -> 0 0 0 0 0 1 0 
port 119 -> 0 0 0 0 0 1 0 
|;

$ans = '';
my $c = 0;
foreach my $port(@ports) {
  $ans .= "port $port -> ";
  my $n = $report->{port_intvls};
  do {
	$ans .= $stats[$c++]. ' ';
    } while --$n > 0;
  $ans .= "\n";
}

print "       response:
${txt}  ne expected:   
$ans\nnot " unless $txt eq $ans;
&ok;
