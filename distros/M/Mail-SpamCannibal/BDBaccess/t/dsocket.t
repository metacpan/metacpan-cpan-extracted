# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..83\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use CTest;
use IPTables::IPv4::DBTarpit::Tools;
use Mail::SpamCannibal::BDBclient qw(
	dataquery
	retrieve
	inet_aton
	inet_ntoa
	INADDR_NONE
);

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
my $db2 = 'rbltxt';
my $unsocket = $dbhome .'/bdbread';

my $cmd = "$localdir/bdbaccess -r $dbhome -f $db1 -f $db2 -d";

my %text = (		# must not be == 4 characters. Real data is not.
        '0.0.0.1'               => 'oohoohoohone',
        '1.0.0.0',              => '1oooh',
        '1.2.3.4',              => 'one.two.three.four',
        '4.3.2.1',              => 'four.three.two.one',
        '12.34.56.78',          => '12dot34.56.78',
        '101.202.33.44',        => '101dot202dot33dot44',
        '254.253.252.251',      => "250's",
);

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
	txtfile	=> $db2,
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

## test 10-16	insert dummy text strings
foreach(sort keys %text) {
  print "failed to insert $db2 record $_\nnot "
	if $sw->put($db2,inet_aton($_),$text{$_});
  &ok;
}

## test 17	dump text data
print "failed to dump database\nnot "
	if $sw->dump($db2,\%dump);
&ok;

## test 18
verify_keys(\%text);

## test 19-25	verify data
verify_data(0,\%text);         # argument 0 or 1 to force printing

## test 26	dump dummy time data
print "failed to dump database\nnot "
        if $sw->dump($db1,\%dump);
&ok;

## test 27
verify_keys(\%addrs);

## test 28-34	verify data
verify_data(0,\%addrs);         # argument 0 or 1 to force printing

$sw->closedb();

&next_sec(time +2);		# wait a bit to let daemon come to life

## test 35	ask for non-existent db
my ($key,$error) = dataquery(1,1,'bogus',$unsocket);
print "returned unknown key\nnot "
	unless $key eq INADDR_NONE;
&ok;

## test 36	check returned error code
$_ = &{"${TCTEST}::t_bdberror"}($error);
print "unexpected error return '$_'\nnot "
	unless $_ =~ /notfound/i;
&ok;

## test 37-43	check values by cursor
# tests = 7 keys
my @keys = sort keys %addrs;
foreach(1..scalar @keys) {
  my $cursor = $_;
  my ($IP,$val) = dataquery(1,$cursor,$db1,$unsocket);
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

## test 44-50	check values by key
foreach(sort keys %addrs) {
  my $netaddr = inet_aton($_);
  my ($IP,$val) = dataquery(0,$netaddr,$db1,$unsocket);
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

## test 51	ask for non-existent record
($key,$error) = dataquery(0,inet_aton('127.1.2.3'),$db1,$unsocket);
print "returned unknown key\nnot "
	unless $key eq INADDR_NONE;
&ok;

## test 52	check returned error code
$_ = &{"${TCTEST}::t_bdberror"}($error);
print "unexpected error return '$_'\nnot "
	unless $_ =~ /notfound/i;
&ok;

#########################
## check ascii records ##
#########################

## test 53-59	check values by cursor
my @orderedlist;	# save records in order for later
@keys = sort keys %text;
foreach(1..scalar @keys) {
  my $cursor = $_;
  my ($IP,$val) = dataquery(1,$cursor,$db2,$unsocket);
  if ($@) {
    print "failed to get data: $@\nnot ";
  } else {
    if ($IP) {
      my $key = inet_ntoa($IP);
      push @orderedlist, $key;
      if (exists $text{$key}) {
	print "VAL: got: $val, exp: $text{$key}\nnot "
	unless $val eq $text{$key};
      } else {
	print "KEY not found: $key\nnot ";
      }
    } else {
      print "DB error: $val\nnot "
    }
  }
  &ok;
}

## test 60-66	check values by key
foreach(sort keys %text) {
  my $netaddr = inet_aton($_);
  my ($IP,$val) = dataquery(0,$netaddr,$db2,$unsocket);
  if ($@) {
    print "failed to get data: $@\nnot ";
  } else {
    if ($IP) {
      my $key = inet_ntoa($IP);
      if (exists $text{$key}) {
	print "VAL: got: $val, exp: $text{$key}\nnot "
	unless $val eq $text{$key};
      } else {
	print "KEY not found: $key\nnot ";
      }
    } else {
      print "DB error: $val\nnot "
    }
  }
  &ok;
}

############ now check for return of number of keys and version number

## test 67	version string
my $version = &{"${TCTEST}::t_bdbversion"}();
$version = '0.'.$version;
my ($IP,$val) = dataquery(1,0,$db1,$unsocket);	# query for record ZERO
if ($@) {
  print "failed to get data: $@\nnot ";
} else {
  if ($IP) {
    if( my $dbversion = inet_ntoa($IP)) {
      print "got version string '$dbversion', exp: $version\nnot "
	unless $dbversion eq $version;
    } else {
      print "invalid version string\nnot ";
    }
  } else {
    print "version string not returned\nnot ";
  }
}
&ok;

## test 68	number of records
print "got: $val, exp: ", scalar keys %addrs, "\nnot "
	unless $val = scalar keys %addrs;
&ok;

############# there are seven keys, retrieve the first 4

## test 69	retrieve some sequential records
my @list;
my $count;
my $want = 4;
my $start = 1;
print "retrieve failed, undefined\nnot "
	unless ($count = retrieve($want,$start+1,$db2,\@list,$unsocket,0));
&ok;

## test 70	check count
print "count is: $count, exp: $want\nnot "
	unless $count == $want;
&ok;

## test 71-74	check content
foreach(0..$#list) {
  $list[$_] = inet_ntoa($list[$_]);
  print "got: $list[$_], exp: $orderedlist[$_+$start]\nnot "
	unless $list[$_] eq $orderedlist[$_+$start];
  &ok;
}

## test 75	retrieve them all
$want = 10;	# there are ONLY 7
$start = 0;
print "retrieve failed, undefined\nnot "
	unless ($count = retrieve($want,$start+1,$db2,\@list,$unsocket,0));
&ok;

## test 76	check count
print "count is: $count, exp: ", scalar @orderedlist, "\nnot "
	unless $count == @orderedlist;
&ok;

## test 77-83	check content
foreach(0..$#orderedlist) {
  $list[$_] = inet_ntoa($list[$_]);
  print "got: $list[$_], exp: $orderedlist[$_+$start]\nnot "
	unless $list[$_] eq $orderedlist[$_+$start];
  &ok;
}

kill 9,$pid;
close Daemon;
