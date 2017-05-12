# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..35\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools;
use CTest;
use Socket;

use constant Null => 0;

$TPACKAGE	= 'IPTables::IPv4::DBTarpit::Tools';
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

my $time = &next_sec();

my %addrs = (
	'0.0.0.1'		=> $time++,
	'1.0.0.0',		=> $time++,
	'1.2.3.4',		=> $time++,
	'4.3.2.1',		=> $time++,
	'12.34.56.78',		=> $time++,
	'101.202.33.44',	=> $time++,
	'254.253.252.251',	=> $time++,
);

my %new = (
	dbfile	=> ['tarpit'],
	dbhome	=> $dbhome,
);

## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

## test 3-9 insert addrs + value's
while(my($key,$val) = each %addrs) {
  if ($sw->touch('tarpit',inet_aton($key),$val)) {
    print "failed to insert $key => $val\nnot ";
  }
  &ok;
}

## test 10 - dump database using perl
my %dump;
print "failed to dump database\nnot "
	if $sw->dump('tarpit',\%dump);
&ok;

## test 11 - verify key count
sub verify_keys {
  my $x = keys %addrs;
  my $y = keys %dump;
  print "bad key count, in=$x, out=$y\nnot "
	unless $x == $y;
  &ok;
#print "verified key count\n";
}

verify_keys;

## test 12-18 - verify dump vs addrs
sub verify_data {
  my($Force) = @_;
  while(my($key,$val) = each %dump) {
    $key = inet_ntoa($key) unless length($key) > 4;
    print $key, " => $val\nnot "
	unless ! $Force &&
	  exists $addrs{$key} && $addrs{$key} == $val;
    &ok;
  }
}

verify_data(0);		# argument 0 or 1 to force printing

$sw->closedb();

## test 19 - initialize database with 'C'
print "failed to init database with 'C'\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0],Null);
&ok;

## test 20 - dump database and verify key count

sub c_dump {
  my($which) = @_;
  %dump = ();
  if (open(FROMCHILD, "-|")) {
    while (my $record = <FROMCHILD>) { 
      $record =~ /(\d[^\s]+)[^\d]+(\d+)/;
      $dump{$1} = $2;
    }
  } else {
    my $rv;
    ($rv = &{"${TCTEST}::t_dump"}($which))
	&& die "BerkeleyDB read FAILED, status=$rv\n";
    exit;
  }
  close FROMCHILD;
}

c_dump(0);
verify_keys;

## test 21-27 - verify dump vs addrs
verify_data(0);		# 0 or 1 to force printing

## test 28 - look for bogus IP

my $IP = '111.222.111.222';
my $iprv = &{"${TCTEST}::t_get"}(0,inet_aton($IP));
print "found bogus IP $IP in database, rv = $iprv\nnot "
	if $_;
&ok;

## test 29 - get values from db one at a time
foreach(sort keys %addrs) {
  print "unexpected value: $iprv, expected $addrs{$_}\nnot "
	if ($iprv = &{"${TCTEST}::t_get"}(0,inet_aton($_))) != $addrs{$_};
  &ok;
}
### close the db with 'C'
&{"${TCTEST}::t_close"}();
