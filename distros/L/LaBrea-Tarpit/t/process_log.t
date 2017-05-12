# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

use lib qw( ./ );
require 'tz_test_adj.pl';
require LaBrea::Tarpit;
import LaBrea::Tarpit qw(process_log recurse_hash2txt);

my $expect = new LaBrea::Tarpit::tz_test_adj;

$loaded = 1;
print "ok 1\n";
$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

#### CHECK ALL THE UTILITY FUNCTIONS

my %tarpit;
my @logs = qw(./labrea_time.log ./labrea_syslog.log ./labrea_date.log);
my @isdaemon = (1,0,1);

my @response = (qq
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
\$tp->{bw} = 8
\$tp->{now} = 1007243541
|,qq
|\$tp->{at}->{222.205.44.126}->{2014}->{ct} = $expect->{1007163099}
\$tp->{at}->{222.205.44.126}->{2014}->{dip} = 63.77.172.49
\$tp->{at}->{222.205.44.126}->{2014}->{dp} = 123
\$tp->{at}->{222.205.44.126}->{2014}->{lc} = $expect->{1007163099}
\$tp->{at}->{222.205.44.126}->{2014}->{pst} = 0
\$tp->{at}->{63.204.44.126}->{2014}->{ct} = $expect->{1007159499}
\$tp->{at}->{63.204.44.126}->{2014}->{dip} = 63.77.172.39
\$tp->{at}->{63.204.44.126}->{2014}->{dp} = 80
\$tp->{at}->{63.204.44.126}->{2014}->{lc} = $expect->{1007159510}
\$tp->{at}->{63.204.44.126}->{2014}->{pst} = 6
\$tp->{at}->{67.97.64.173}->{61623}->{ct} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{dip} = 63.77.172.50
\$tp->{at}->{67.97.64.173}->{61623}->{dp} = 80
\$tp->{at}->{67.97.64.173}->{61623}->{lc} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{pst} = 6
\$tp->{bw} = 145
\$tp->{now} = $expect->{1007163099}
|,qq
|\$tp->{at}->{222.205.44.126}->{2014}->{ct} = $expect->{1007163099}
\$tp->{at}->{222.205.44.126}->{2014}->{dip} = 63.77.172.49
\$tp->{at}->{222.205.44.126}->{2014}->{dp} = 123
\$tp->{at}->{222.205.44.126}->{2014}->{lc} = $expect->{1007163099}
\$tp->{at}->{222.205.44.126}->{2014}->{pst} = 0
\$tp->{at}->{63.204.44.126}->{2014}->{ct} = $expect->{1007159499}
\$tp->{at}->{63.204.44.126}->{2014}->{dip} = 63.77.172.39
\$tp->{at}->{63.204.44.126}->{2014}->{dp} = 80
\$tp->{at}->{63.204.44.126}->{2014}->{lc} = $expect->{1007159510}
\$tp->{at}->{63.204.44.126}->{2014}->{pst} = 6
\$tp->{at}->{63.222.243.6}->{2710}->{ct} = $expect->{1007241125}
\$tp->{at}->{63.222.243.6}->{2710}->{dip} = 63.77.172.16
\$tp->{at}->{63.222.243.6}->{2710}->{dp} = 80
\$tp->{at}->{63.222.243.6}->{2710}->{lc} = $expect->{1007241126}
\$tp->{at}->{63.222.243.6}->{2710}->{pst} = 0
\$tp->{at}->{63.227.234.71}->{4628}->{ct} = $expect->{1007241067}
\$tp->{at}->{63.227.234.71}->{4628}->{dip} = 63.77.172.57
\$tp->{at}->{63.227.234.71}->{4628}->{dp} = 80
\$tp->{at}->{63.227.234.71}->{4628}->{lc} = $expect->{1007241067}
\$tp->{at}->{63.227.234.71}->{4628}->{pst} = 6
\$tp->{at}->{63.87.135.216}->{3204}->{ct} = $expect->{1007241123}
\$tp->{at}->{63.87.135.216}->{3204}->{dip} = 63.77.172.35
\$tp->{at}->{63.87.135.216}->{3204}->{dp} = 80
\$tp->{at}->{63.87.135.216}->{3204}->{lc} = $expect->{1007241123}
\$tp->{at}->{63.87.135.216}->{3204}->{pst} = 6
\$tp->{at}->{67.97.64.173}->{61623}->{ct} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{dip} = 63.77.172.50
\$tp->{at}->{67.97.64.173}->{61623}->{dp} = 80
\$tp->{at}->{67.97.64.173}->{61623}->{lc} = $expect->{1007159496}
\$tp->{at}->{67.97.64.173}->{61623}->{pst} = 6
\$tp->{bw} = 234
\$tp->{now} = | . (($expect->{1007163099} > $expect->{1007241126})
	? $expect->{1007163099}
	: $expect->{1007241126}) . "\n");

## fail to open
print "opened RANDOM NAME\nnot "
	if process_log(\%tarpit,'./someRandomCrapName');
&ok;

# input:	txt out pointer, pointer to hash, keys so far, dump | debug
# 		if the dod flag is 0, this is normal dump mode
#		else it's the fancy debug mode

sub recurse {
  my ($tp) = @_;
  &recurse_hash2txt(@_);
  my @txt = split('\n',$$tp);
  @_ = sort @txt;   
  $$tp = join("\n",@_,'');
}

my $zapped_once = 0;
foreach my $x (0..$#logs) {
# note that 'isdaemon' from an array
# and is zero only for 'labrea_syslog.log'
  print "failed to open $logs[$x]\nnot "
	unless process_log(\%tarpit,$logs[$x],$isdaemon[$x]);
  &ok;
  my $txt = '';
  &recurse(\$txt,\%tarpit, '$tp',1);
  print "	response:
${txt}	ne expected:
$response[$x]\nnot " unless $txt eq $response[$x];
  &ok;
  undef %tarpit unless $zapped_once;
  $zapped_once = 1;
}
