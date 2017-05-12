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
$TCTEST		= 'Mail::SpamCannibal::BDBaccess::CTest';
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

my %addrs = (		# this all wants to be text, longer than 4 characters
	'0.0.0.1'		=> 'oohoohoohone',
	'1.0.0.0',		=> 'oneOOO',
	'1.2.3.4',		=> 'one.two.three.four',
	'4.3.2.1',		=> 'four,three,two,one',
	'12.34.56.78',		=> 'one2345678',
	'101.202.33.44',	=> '101.202.33.44',
	'254.253.252.251',	=> 'two54253252251',
);

my %new = (
	dbfile	=> ['tarpit'],
	txtfile	=> ['rbltxt'],
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
  if ($sw->put('rbltxt',inet_aton($key),$val)) {
    print "failed to insert $key => $val\nnot ";
  }
  &ok;
}

## test 10 - dump database using perl
my %dump;
print "failed to dump database\nnot "
	if $sw->dump('rbltxt',\%dump);
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
    $key = inet_ntoa($key) unless length($key) != 4;
    print $key, " => $val\nnot "
	unless ! $Force &&
	  exists $addrs{$key} && $addrs{$key} eq $val;
    &ok;
  }
}

verify_data(0);		# argument 0 or 1 to force printing

$sw->closedb();

## test 19 - initialize database with 'C'
print "failed to init database with 'C'\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$new{dbfile}->[0],$new{txtfile}->[0]);
&ok;

## test 20 - dump database and verify key count

sub c_dump {
  my($which) = @_;
  my $file = ($which) ? $new{txtfile}->[0] : $new{dbfile}->[0];
  %dump = ();
  if (open(FROMCHILD, "-|")) {
    while (my $record = <FROMCHILD>) {
      if ($which) {
        $record =~ /(\d[^\s]+)\s+=>\s+(.+)/;
	$dump{$1} = $2;
      } else {
	$record =~ /(\d[^\s]+)[^\d]+(\d+)/;
	$dump{$1} = $2;
      }
    }
  } else {
    my $rv;
    ($rv = &{"${TCTEST}::t_dump"}($which,$file))
	&& die "BerkeleyDB read FAILED, status=$rv\n";
    exit;
  }
  close FROMCHILD;
}

c_dump(1);
verify_keys;

## test 21-27 - verify dump vs addrs
verify_data(0);		# 0 or 1 to force printing

## test 28 - look for bogus IP

my $IP = '111.222.111.222';
my $iprv = &{"${TCTEST}::t_get"}(1,$new{txtfile}->[0],inet_aton($IP));
print "found bogus IP $IP in database, rv = $iprv\nnot "
	if $_;
&ok;

## test 29 - get values from db one at a time
foreach(sort keys %addrs) {
  print "unexpected value: $iprv, expected $addrs{$_}\nnot "
	if ($iprv = &{"${TCTEST}::t_get"}(1,$new{txtfile}->[0],inet_aton($_))) ne $addrs{$_};
  &ok;
}
### close the db with 'C'
&{"${TCTEST}::t_close"}();
