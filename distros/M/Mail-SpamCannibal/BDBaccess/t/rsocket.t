# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

$| = 1;

END {print "1..0   # Skipping... tests for BDBaccess via network, unsupported on this host\n"
	unless $port;}

use Cwd;
use IO::Socket;
use IPTables::IPv4::DBTarpit::Tools;
use IO::Socket::INET;
use Mail::SpamCannibal::BDBclient qw(
	dataquery
	retrieve
	INADDR_NONE
);

### check if we can use network sockets

my $protoport = 10086;

foreach($protoport..$protoport+10) {
  my $s = IO::Socket::INET::->new(LocalPort	=> $_,
				  Type		=> SOCK_STREAM,
				  Listen	=> 1);
  if ($s) {
    close $s;
    $port = $_;
    last;
  }
}

if ($port) {
  print "1..34\n";
} else {
  exit 0;
}

print "ok 1\n";

######################### End of black magic.

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

my %dump;	# defined here for binding with verify subroutines

sub verify_keys {
  my($ap) = @_;
  my $x = keys %$ap;
  my $y = keys %dump;
  print "bad key count, in=$x, out=$y\nnot "
        unless $x == $y;
  &ok;
#print "verified key count\n";
}

sub verify_data {
  my($Force,$ap) = @_;
  while(my($key,$val) = each %dump) {
    $key = inet_ntoa($key) unless length($key) > 4;
    print $key, " => $val\nnot "
        unless ! $Force &&
          exists $ap->{$key} && $ap->{$key} eq $val;
    &ok;
  }
}

my $localdir = cwd();

my $dbhome = "$localdir/tmp.dbhome";
my $db1	= 'tarpit';

my $cmd = "$localdir/bdbaccess -r $dbhome -f $db1 -d -p $port";
my $sock = 'localhost:'.$port;
my $timeout = 5;	# seconds;

my %addrs = (
        '0.0.0.1'               => 1111,
        '1.0.0.0',              => 1000,
        '1.2.3.4',              => 1234,
        '4.3.2.1',              => 4321,
        '12.34.56.78',          => 12345678,
        '101.202.33.44',        => 1120230344,
        '254.253.252.251',      => 254321,
);

my $sw = new IPTables::IPv4::DBTarpit::Tools(
	dbfile	=> $db1,
	dbhome	=> $dbhome,
);

###########################################################
#### database's created, data loaded, connect C daemon ####
###########################################################

## test 2	open daemon
my $pid;
print "could open not daemon\nnot "
	unless ($pid = open(Daemon,"| $cmd"));
&ok;

## test 3-9	insert dummy time tags
foreach(sort keys %addrs) {
  print "failed to insert $db1 record $_\nnot "
	if $sw->put($db1,inet_aton($_),$addrs{$_});
  &ok;
}

## test 10	dump dummy time data
print "failed to dump database\nnot "
        if $sw->dump($db1,\%dump);
&ok;

## test 11
verify_keys(\%addrs);

## test 12-18	verify data
verify_data(0,\%addrs);         # argument 0 or 1 to force printing

$sw->closedb();

&next_sec(time +2);		# wait a bit to let daemon come to life


## test 19	ask for non-existent db
my ($key,$error) = dataquery(1,1,'bogus',$sock,$timeout);
print "returned unknown key\nnot "
	unless $key eq INADDR_NONE;
&ok;

print $@ if $@;

## test 20-26	check values by cursor
# tests = 7 keys
my @keys = sort keys %addrs;
foreach(1..scalar @keys) {
  my $cursor = $_;
  my ($IP,$val) = dataquery(1,$cursor,$db1,$sock,$timeout);
  if ($@) {
    print "failed to get data: $@\nnot ";
  } else {
    if ($IP) {
      my $key = inet_ntoa($IP);
      if (exists $addrs{$key}) {
	print "VAL: got: $val, exp: $addrs{$key}\nnot "
	unless $val == $addrs{$key};
      } else {
	print "KEY not found: $key\nnot ";
      }
    } else {
      print "DB error: $val\nnot "
    }
  }
  &ok;
}

## test 27-33	check values by key
foreach(sort keys %addrs) {
  my $netaddr = inet_aton($_);
  my ($IP,$val) = dataquery(0,$netaddr,$db1,$sock,$timeout);
  if ($@) {
    print "failed to get data: $@\nnot ";
  } else {
    if ($IP) {
      my $key = inet_ntoa($IP);
      if (exists $addrs{$key}) {
	print "VAL: got: $val, exp: $addrs{$key}\nnot "
	unless $val == $addrs{$key};
      } else {
	print "KEY not found: $key\nnot ";
      }
    } else {
      print "DB error: $val\nnot "
    }
  }
  &ok;
}

## test 34	ask for non-existent record
($key,$error) = dataquery(0,inet_aton('127.1.2.3'),$db1,$sock,$timeout);
print "returned unknown key\nnot "
	unless $key eq INADDR_NONE;
&ok;

kill 9,$pid;
close Daemon;
