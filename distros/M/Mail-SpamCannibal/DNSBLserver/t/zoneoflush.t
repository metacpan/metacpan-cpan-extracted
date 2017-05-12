# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..135\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Cwd;
use CTest;
use Socket;

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

my $localdir = cwd() .'/tmp';

mkdir $localdir,0755;

my $localstdout = $localdir .'/main.out';

# check contents of print buffer variables
sub checkSTDOUT {
  my ($x) = @_;
  open(MO,$localstdout) or die "can't open $localstdout\n";
  local $/ = undef;
  my $got = <MO>;		# slurp file
  close MO;
  if($x) {
    print "UNMATCHED RETURN TEXT\n$got\nnot "
        unless $got =~ /^$x/;
  } else {
    print "UNEXPECTED RETURN TEXT\n$got\nnot "
        if $got;
  }
  &ok;
}

# save STDOUT and STDERR file handles
local (*SAVEOUT,*SAVEERR);
open SAVEOUT, ">&STDOUT";
open SAVEERR, ">&STDERR";

sub restoreSTD {
  eval {
    close STDOUT;
    close STDERR;
    open STDOUT, ">&SAVEOUT";
    open STDERR, ">&SAVEERR";
  };
  return $@;
}

sub redirectSTD {
  eval {
    open STDOUT, ">$localstdout" or die "can't redirect STDOUT\n";
    open STDERR, ">&STDOUT" or die "can't redirect STDERR\n";
    select STDERR; $| = 1;
    select STDOUT; $| = 1;      # autoflush
  };
  my $rv = $@;
  restoreSTD() if $rv;
  return $rv;
}

sub callSTDOUT {
  my($cb,@args) = @_;
  return $@ if redirectSTD();
  eval { &{$cb}(@args) };
  my $rv = $@;
  restoreSTD();
  return $rv;
}

## test 2
my $expect = q
|dbhome      -r	=> |. $localdir .q|
tarpit      -i	=> tarpit
contrib     -j	=> blcontrib
evidence    -k	=> evidence
block		=> 0 AXFR transfers blocked
eflag		=> no message
dflag		=> 1 no daemon
oflag		=> 1 log to stdout
loglvl		=> 0 log enabled > 0
port		=> 53 port number
Tflag		=> 1 test mode
promiscuous	=> 0 reporting enabled
zone		=> foo.bar.com
Zflag		=> 0 Zap zone file TXT records
contact		=> root.foo.bar.com
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
	'-r', $localdir,
	'-z', 'foo.bar.com',
	'-n', 'xx.yy.com', '-a', '11.22.33.44', 
	'-n', 'ns2.zz.net', '-a', '65.43.21.9',
	'-e', 'no message', 
);

# Something in perl 5.8 does not allow the redirection of
# STDOUT in an eval to a C program. The workaround is
# simply to abort the call to 'main' just prior to issuing
# the print statements since this is all tested elsewhere
#
print "unexpected return value, $_\nnot "
	if &{"${TCTEST}::t_set_stop"}(1);
&ok;

# See comment above
# print "$_\nnot "
#  if $_ = callSTDOUT(\&{"${TCTEST}::t_main"},'CTest',@x);
# &ok;

&{"${TCTEST}::t_main"}('CTest',@x);

# See comments above
## test 3	check returned values
# checkSTDOUT($expect);
&ok;	# dummy

## 30 test steps
sub preset_regs {
 ## test 4	initialize internals to zero, check stack nibbles
  &{"${TCTEST}::t_initlb"}();
  print "unexpected initialization values\n$_\nnot "
	unless ($_ = join("\n",&{"${TCTEST}::t_ret_a_nibls"}())) eq
		"0.0.0.0\n0.0.0.0\n0.0.0.0\n0.0.0.0";
  &ok;

 ## test 5	check response stack
  print "unexpected initialization values\n$_\nnot "
	unless ($_ = join("\n",&{"${TCTEST}::t_ret_resp"}())) eq
		"0.0.0.0\n0.0.0.0\n0.0.0.0\n0.0.0.0";
  &ok;

 ## test 6-9	check empty text buffers
  foreach(1..4) {
    print "unexpected initial text buffer value: $_\nnot "
	if $_ = &{"${TCTEST}::t_mybuffer"}($_);
    &ok;
  }

 ## test 10-33	load the first set of registers in the process stack
  my @address	= qw(
	255.22.23.24
	1.2.3.4
	33.22.11.10
	87.43.10.91
  );

  my @response	= qw(
	127.0.0.39
	127.0.0.40
	86.75.43.21
	11.22.33.44
  );
  my @textresp	= (
	'some goofy text here',
	'testing for stuff',
	'third row',
	'fourth row',
  );
  my @stackaddress  = qw(
	0.0.0.0
	0.0.0.0
	0.0.0.0
	0.0.0.0
  );
  my @stackresponse = @stackaddress;
  my @stacktext	  = ('','','','');


  while(my $address = shift @address) {
    my $response = shift @response;
    my $textresp = shift @textresp;
    unshift @stackaddress, $address;
    unshift @stackresponse, $response;
    unshift @stacktext, $textresp;
    pop @stackaddress;
    pop @stackresponse;
    pop @stacktext;

    &{"${TCTEST}::t_iload"}(inet_aton($address),inet_aton($response),$textresp);

 ## test	+1	check nibble stack
    $expect = join("\n",@stackaddress);
    print "got:\n$_\n\nexp:\n$expect\nnot "
	unless ($_ = join("\n",&{"${TCTEST}::t_ret_a_nibls"}())) eq $expect;
    &ok;

 ## test	+2	check response stack
    $expect = join("\n",@stackresponse);
    print "got:\n$_\n\nexp:\n$expect\nnot "
	unless ($_ = join("\n",&{"${TCTEST}::t_ret_resp"}())) eq $expect;
    &ok;

 ## test +3->+6	check txt stack
    foreach(1..4) {
      $expect = $stacktext[$_ -1];
      print "got: $_, exp: $expect\nnot "
	unless ($_ = &{"${TCTEST}::t_mybuffer"}($_)) eq $expect;
      &ok;
    }
  }
}

## test 4-33	preset internal registers
preset_regs();

## test 34	set org 1
print "got: $_, exp: 0\nnot "
	unless ($_ = &{"${TCTEST}::t_set_org"}(1)) == 0;
&ok;

## test 35	check flush 1 - redirect STDOUT
print "$_\nnot "
  if $_ = callSTDOUT(\&{"${TCTEST}::t_oflush"},STDOUT);
&ok;

## test 36	STDOUT file content
$expect = q
|10.11.22.33		A	86.75.43.21
			TXT	"third row"
|;
checkSTDOUT($expect);

## test 37-66	preset internal registers
preset_regs();

## test 67	set org 2
print "got: $_, exp: 0\nnot "
	unless ($_ = &{"${TCTEST}::t_set_org"}(2)) == 0;
&ok;

## test 68	check flush 2 - redirect STDOUT
print "$_\nnot "
  if $_ = callSTDOUT(\&{"${TCTEST}::t_oflush"},STDOUT);
&ok;

## test 69	STDOUT file content
$expect = q
|4.3.2			A	127.0.0.40
			TXT	"testing for stuff"
10.11.22		A	86.75.43.21
			TXT	"third row"
|;
checkSTDOUT($expect);

## test 70-99	preset internal registers
preset_regs();

## test 100	set org to 3
print "got: $_, exp: 0\nnot "
	unless ($_ = &{"${TCTEST}::t_set_org"}(3)) == 0;
&ok;

## test 101	check flush 2 - redirect STDOUT
print "$_\nnot "
  if $_ = callSTDOUT(\&{"${TCTEST}::t_oflush"},STDOUT);
&ok;

## test 102	STDOUT file content
$expect = q
|24.23			A	127.0.0.39
			TXT	"some goofy text here"
4.3			A	127.0.0.40
			TXT	"testing for stuff"
10.11			A	86.75.43.21
			TXT	"third row"
|;
checkSTDOUT($expect);

## test 103-132	preset internal registers
preset_regs();

## test 133	set org to 4
print "got: $_, exp: 0\nnot "
	unless ($_ = &{"${TCTEST}::t_set_org"}(4)) == 0;
&ok;

## test 134	check flush 2 - redirect STDOUT
print "$_\nnot "
  if $_ = callSTDOUT(\&{"${TCTEST}::t_oflush"},STDOUT);
&ok;

## test 135	STDOUT file content
$expect = q
|24			A	127.0.0.39
			TXT	"some goofy text here"
4			A	127.0.0.40
			TXT	"testing for stuff"
10			A	86.75.43.21
			TXT	"third row"
|;
checkSTDOUT($expect);
