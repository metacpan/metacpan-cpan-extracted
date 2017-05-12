# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

$| = 1;
END {print "1..0 # Skipping... dbtarpit not supported by this OS\n"
	unless $os_supported;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools;
use CTest;
use Socket;

use constant Null => 0;

$TPACKAGE	= 'IPTables::IPv4::DBTarpit::Tools';
$TCTEST		= 'IPTables::IPv4::DBTarpit::CTest';

$os_supported = ((do 'supported_os.h') eq 'LINUX')
	? 1:0;
if ($os_supported) {
  print "1..90\n";
} else {
  exit 0;
}

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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

my $localdir = cwd();
my $dbhome = "$localdir/tmp.dbhome";
mkdir $dbhome,0755 unless -e $dbhome && -d $dbhome;

my $time = &next_sec();

my %addrs = (
	'0.0.0.1'		=> $time--,
	'1.0.0.0',		=> $time--,
	'1.2.3.4',		=> $time--,
	'4.3.2.1',		=> $time--,
	'12.34.56.78',		=> $time--,
	'101.202.33.44',	=> $time--,
	'254.253.252.251',	=> $time--,
);

my %archs = (
	'0.0.0.10'		=> $time--,
	'10.0.0.1'		=> $time--,
	'10.2.3.4'		=> $time--,
	'4.3.2.10'		=> $time--,
	'87.65.43.21'		=> $time--,
	'44.33.202.101'		=> $time--,
	'251.242.253.254'	=> $time--,
);

my %new = (
	dbfile  => ['tarpit','archive'],
	dbhome  => $dbhome,
);

my %partial = (
	dbfile  => ['tarpit'],
	dbhome  => $dbhome,
);

my %dump;

# usage:
# verify_keys(\%archs);

sub verify_keys {
  my($ap) = @_;
  my $x = keys %$ap;
  my $y = keys %dump;
  print "bad key count, in=$x, out=$y\nnot "
	unless $x == $y;
  &ok;
#print "verified key count\n";
}

# usage:
# verify_data(0,\%archs);		# argument 0 or 1 to force printing

sub verify_data {
  my($Force, $ap) = @_;
  while(my($key,$val) = each %dump) {
    $key = inet_ntoa($key) unless length($key) > 4;
    print $key, " => $val ne exp  $ap->{$key}\nnot "
	unless ! $Force &&
	  exists $ap->{$key} && $ap->{$key} == $val;
    &ok;
  }
}

# usage:
# c_dump(1);	# 0 => tarpit, 1 => archive
# verify_keys(\%archs);

sub c_dump {
  my($which) = @_;
  %dump = ();
  if (open(FROMCHILD, "-|")) {		# parent
    while (my $record = <FROMCHILD>) { 
      $record =~ /(\d[^\s]+)[^\d]+(\d+)/;
      $dump{$1} = $2;
    }
  } else {				# child
    my $rv;
    ($rv = &{"${TCTEST}::t_dump"}($which))
	&& die "BerkeleyDB read FAILED, status=$rv\n";
    exit;
  }
  close FROMCHILD;
}

## test 2 -  establish DB connections
my $sw = eval {
        new $TPACKAGE(%new);
};
print "failed to open db with perl \nnot " if $@;
&ok;

## test 3-9 insert addrs + value's
while(my($key,$val) = each %addrs) {
  if ($sw->touch('tarpit',inet_aton($key),$val)) {
    print "failed to insert tarpit $key => $val\nnot ";
  }
  &ok;
}

## test 10-16 insert archs + value's
while(my($key,$val) = each %archs) {
  if ($sw->touch('archive',inet_aton($key),$val)) {
    print "failed to insert archive $key => $val\nnot ";   
  }
  &ok;
}

# close perl connection
$sw->closedb();

## test 17 - initialize database with 'C'
print "failed to init database with 'C'\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0],$new{dbfile}->[1]);
&ok;

## test 18 - check initial value of "trace"
print "bad initial trace value\nnot "
	if &{"${TCTEST}::t_chk_trace"}();
&ok;

$time = next_sec($time);

## test 19 - get IPPROTO_TCP number
my $protocol = &{"${TCTEST}::t_ret_IPPTCP"}()
	or print 'failed to retrieve IPPROTO_TCP\nnot ';
&ok;

## test 20 - check initial value of "trace"
print "non-zero trace from check_4_tarpit\nnot "
	if &{"${TCTEST}::t_chk_trace"}();
&ok;

## test 21 - check for skip, not TCPIP
my ($addr) = sort keys %addrs;
my $saddr = inet_aton($addr);
my $xflag = 0;
my $tpresp = 33;
print "non-zero response from check_4_tarpit\nnot "
	if &{"${TCTEST}::t_check"}($saddr, $time -1000, $xflag, $protocol + 1, $tpresp);
&ok;

## test 22 - check that archive is untouched
c_dump(1);
verify_keys(\%archs);

## test 23 - check that trace is untouched
print "non-zero trace from check_4_tarpit\nnot "
        if &{"${TCTEST}::t_chk_trace"}();
&ok;

## test 24 - verify that it was IPPROTO_TCP
print "invalid response ($_) from check_4_tarpit\nnot "
	unless ($_ = &{"${TCTEST}::t_check"}($saddr, $time -5000, $xflag, $protocol, $tpresp));
&ok;

## test 25 - verify that tarpit is updated
$addrs{$addr} = $time - 5000;
c_dump(0);
verify_keys(\%addrs);

## test 26 - verify that tarpit was executed
print "tarpit failed to execute\n"
	unless &{"${TCTEST}::t_chk_trace"}() == $tpresp;
&ok;

## test 27-33 - verify data and time update
verify_data(0,\%addrs);

## test 34 - verify that xflag turns off tarpitting
$time = next_sec(time);
$xflag = 1;
my $trepsav = $tpresp;
$tpresp += 1;
print "invalid response ($_) from check_4_tarpit\nnot "
        unless ($_ = &{"${TCTEST}::t_check"}($saddr, $time -750, $xflag, $protocol, $tpresp));
&ok;

## test 35-41 - verify data and NO time update
verify_data(0,\%addrs);

## test 42 - verify that tarpit did not execute
print "tarpit executed abnormally\nexpected: $trepsav, got: $_\nnot "
        if ($_ = &{"${TCTEST}::t_chk_trace"}()) != $trepsav;
&ok;

## test 43 - check for new address insertion
$addr = '66.77.88.99';
$saddr = inet_aton($addr);
$xflag = 0;
print "non-zero response from check_4_tarpit ($_)\nnot "
	if ($_ = &{"${TCTEST}::t_check"}($saddr, $time -750, $xflag, $protocol, $tpresp));
&ok;

## test 44 - check key count
$archs{$addr} = $time -750;
c_dump(1);
verify_keys(\%archs);

## test 45-52 - check data
verify_data(0,\%archs);

### close the db with 'C'
&{"${TCTEST}::t_close"}();

## test 53 - re-open db with no archive
print "failed to init database with 'C'\nnot "
        if ($_ = &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0]));
&ok;

#print &{"${TCTEST}::t_dberror"}($_),"\n";

## test 54 - attempt another address insertion
$addr = '44.55.77.66';
print "non-zero response from check_4_tarpit ($_)\nnot "
        if ($_ = &{"${TCTEST}::t_check"}($saddr, $time -8888, $xflag, $protocol, $tpresp));
&ok;

### close the db with 'C'
&{"${TCTEST}::t_close"}();

## test 55 -  establish DB connections with perl
$sw = eval {
        new $TPACKAGE(%new);
};
print "failed to open db with perl \nnot " if $@;
&ok;

## test 56 - dump database using perl
%dump = ();
print "failed to dump database\nnot "
        if $sw->dump('archive',\%dump);
&ok;

## test 57 - verify keys are unchanged
verify_keys(\%archs);

## test 58-65 - verify data
verify_data(0,\%archs);   

####################

## test 66	add 127 host to tarpit
$addrs{'0.0.0.1'} = $time - 750;
$addr = '127.0.0.22';
$saddr = inet_aton($addr);
$addrs{$addr} = $time;
if ($sw->touch('tarpit',$saddr,$time)) {
  print "failed to insert tarpit $addr => $time\nnot ";
}
&ok;

## test 67 - dump database using perl
%dump = ();
print "failed to dump database\nnot "
        if $sw->dump('tarpit',\%dump);
&ok;

## test 68	verify keys are unchanged
verify_keys(\%addrs);

## test 69-76	verify data
verify_data(0,\%addrs);

## test 77 - re-open db with no archive
print "failed to init database with 'C'\nnot "
        if ($_ = &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0]));
&ok;

## test 78	verify keys
c_dump(0);
verify_keys(\%addrs);

## test 79-86	verify data
verify_data(0,\%addrs);

# check_4_tarpit returns 1 on a drop, 0 on an accept

$tpresp = 88;
## test 87	normal bypass 127 addess (accept, returns 0)
print "non-zero response from check_4_tarpit, ($_)\nnot "
        if ($_ = &{"${TCTEST}::t_check"}($saddr, $time, $xflag, $protocol, $tpresp));
&ok;

## test 88 - check that trace is untouched 
print "bad trace from check_4_tarpit got: $_, exp: $trepsav\nnot "
        if ($_ = &{"${TCTEST}::t_chk_trace"}()) != $trepsav;
&ok;

## test 89	tarpit 127 address

&{"${TCTEST}::t_Lflag"}(1);		# set Lflag
print "zero ($_) response from check_4_tarpit, exp: 1\nnot "
        unless ($_ = &{"${TCTEST}::t_check"}($saddr, $time, $xflag, $protocol, $tpresp)) == 1;
&ok;

## test 90 - check that trace is untouched
print "bad trace from check_4_tarpit got: $_, exp: $tpresp\nnot "
        if ($_ = &{"${TCTEST}::t_chk_trace"}()) != $tpresp;
&ok;

### close the db with 'C'
&{"${TCTEST}::t_close"}();

### close db with perl
$sw->closedb();
