# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools;
use CTest;
use Socket;

use constant Null => 0;

$TPACKAGE	= 'IPTables::IPv4::DBTarpit::Tools';
$TCTEST		= 'IPTables::IPv4::DBTarpit::CTest';
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

$sw->closedb();

## test 11 - initialize database with 'C'
print "failed to init database with 'C'\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0],Null);
&ok;

## test 12	getrecno 3 => 1.2.3.4
my($netaddr,$val) = &{"${TCTEST}::t_getrecno"}(0,3,1);
print "bad netaddr, exp: 1.2.3.4\nnot "
	unless inet_ntoa($netaddr) eq '1.2.3.4';
&ok;

## test 13	value
print "got: $val, exp: $addrs{'1.2.3.4'}\nnot "
	unless $val == $addrs{'1.2.3.4'};
&ok;

## test 14	get record 12.34.56.78
$val = &{"${TCTEST}::t_get"}(0,inet_aton('12.34.56.78'),1);
print "got: $val, exp: $addrs{'12.34.56.78'}\nnot "
	unless $val == $addrs{'12.34.56.78'};
&ok;

## test 15	get version and stats
my($stats,$major,$minor,$patch) = &{"${TCTEST}::t_libversion"}(0);
print "bad record count = $stats, exp: ",scalar keys %addrs,"\nnot "
	unless $stats == scalar keys %addrs;
print STDERR "\tBerkeley DB version $major.$minor.$patch\n";
&ok;


### close the db with 'C'
&{"${TCTEST}::t_close"}();
