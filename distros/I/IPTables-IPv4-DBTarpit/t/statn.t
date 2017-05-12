# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools qw(
	inet_aton
	inet_ntoa
);
use CTest;

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
my $now = $time;

my %addrs = (
	'12.34.56.78',		=> $time++,
	'101.202.33.44',	=> $time++,
	'254.253.252.251',	=> $time++,
);

my %archs = (
	'0.0.0.10'		=> $time++,
	'10.0.0.1'		=> $time++,
	'10.2.3.4'		=> $time++,
	'4.3.2.10'		=> $time++,
	'87.65.43.21'		=> $time++,
	'44.33.202.101'		=> $time++,
	'251.242.253.254'	=> $time++,
);

my %new = (
	dbfile	=> ['tarpit','archive'],
	dbhome	=> $dbhome,
);

## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

## test 3-5 insert addrs + value's
while(my($key,$val) = each %addrs) {
  if ($sw->touch('tarpit',inet_aton($key),$val)) {
    print "failed to insert tarpit $key => $val\nnot ";
  }
  &ok;
}

## test 6-12 insert archs + value's
while(my($key,$val) = each %archs) {
  if ($sw->touch('archive',inet_aton($key),$val)) {
    print "failed to insert archive $key => $val\nnot ";   
  }
  &ok;
}

## test 13 - dump archive database using perl
my %dump;
print "failed to dump tarpit database\nnot "
	if $sw->dump('archive',\%dump);
&ok;

## test 14 - verify key count
sub verify_keys {
  my($ap) = @_;
  my $x = keys %$ap;
  my $y = keys %dump;
  print "bad key count, in=$x, out=$y\nnot "
	unless $x == $y;
  &ok;
#print "verified key count\n";
}

verify_keys(\%archs);

## test 15-21 - verify dump vs archs
sub verify_data {
  my($Force, $ap) = @_;
  while(my($key,$val) = each %dump) {
    $key = inet_ntoa($key) unless length($key) > 4;
    print $key, " => $val\nnot "
	unless ! $Force &&
	  exists $ap->{$key} && $ap->{$key} == $val;
    &ok;
  }
}
verify_data(0,\%archs);		# argument 0 or 1 to force printing

$sw->closedb();

## test 22 - initialize database with 'C'
print "failed to init database with 'C'\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0],$new{dbfile}->[1]);
&ok;

## test 23 - verify tarpit key count
my $count = &{"${TCTEST}::t_statn"}($new{dbfile}->[0]);
print "got $count, exp: ",scalar keys %addrs, "\nnot "
	unless $count == scalar keys %addrs;
&ok;

## test 24	verify archive key count
$count = &{"${TCTEST}::t_statn"}($new{dbfile}->[1]);
print "got $count, exp: ",scalar keys %archs, "\nnot "
	unless $count == scalar keys %archs;
&ok;

&{"${TCTEST}::t_close"}();
