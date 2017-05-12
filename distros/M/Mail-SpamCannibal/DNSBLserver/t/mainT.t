# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use CTest;

$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 007;
foreach my $dir (qw(tmp tmp.dbhome tmp.bogus)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

my $localdir = cwd();

my $extra;

# input array @_ used in child process after } else {
sub getmaintxt {
  $extra = '';
  if (open(FROMCHILD, "-|")) {
    while (my $record = <FROMCHILD>) { 
      $extra .= $record;
    }
  } else {
# program name is always argv[0]
    unless (open STDERR, '>&STDOUT') {
      print "can't dup STDERR to /dev/null: $!";
      exit;
    }
    &{"${TCTEST}::t_main"}('CTest',@_);
    exit;
  }
  close FROMCHILD;
}

# check contents of extra print variables
sub checkextra {
  my ($x) = @_;
  if($x) {
    print "UNMATCHED RETURN TEXT\n$extra\nnot "
	unless $extra =~ /^$x/;
  } else {
    print "UNEXPECTED RETURN TEXT\n$extra\nnot "
	if $extra;
  }
  &ok;
}

mkdir './tmp',0755;

## test 2 - 
my $expect = q
|dbhome      -r	=> /var/run/dbtarpit
tarpit      -i	=> tarpit
contrib     -j	=> blcontrib
evidence    -k	=> evidence
block		=> 0 AXFR transfers blocked
Limit       -L	=> 200000cps, maximum zonefile build rate
Continuity  -C	=> 0 continuity
eflag		=> no message
qflag		=> 0 append IP address
dflag		=> 1 no daemon
oflag		=> 1 log to stdout
loglvl		=> 0 log enabled > 0
port		=> 53 port number
Tflag		=> 1 test mode
promiscuous	=> 0 reporting enabled
zone		=> foo.bar.com
Zflag		=> 0 Zap zone file TXT records
contact		=> root.foo.bar.com
sflag		=>	0	SOA ttl/negative caching
uflag		=>	43200	SOA update/refresh
yflag		=>	3600	SOA retry
xflag		=>	86400	SOA expires
tflag		=>	10800	SOA ttl/minimum
local records:
NS =>	xx.yy.com
	11.22.33.44
NS =>	ns2.zz.net
	65.43.21.9
|;

my @x = ('-o', '-T',
	'-z', 'foo.bar.com',
	'-n', 'xx.yy.com', '-a', '11.22.33.44', 
	'-n', 'ns2.zz.net', '-a', '65.43.21.9',
	'-e', 'no message', 
);

getmaintxt(@x);
#print $extra;
checkextra($expect);

### tests incomplete but checked by hand
