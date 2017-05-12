# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}

use IPTables::IPv4::DBTarpit::Tools qw(inet_aton);
$TPACKAGE	= 'IPTables::IPv4::DBTarpit::Tools';
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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

### database loader
# takes one test cycle
#
# input:	sw,db,\%hash
#
sub dbinsert {
  my($sw,$db,$hp) = @_;
  my $err;
  while(my($k,$v) = each %$hp) {
    if ($err = $sw->put($db,$k,$v,)) {
      print "insert failure, database '$db'\nnot ";
      last;
    }
  }
  &ok;
}

my $dbprimary = 'tarpit';
my $localdir = cwd();
my $dbhome = "$localdir/tmp.dbhome";


## database checker
# takes 3 test cycles
#
# input:	sw,db,\%hash
#
sub dbcheck {
  my($sw,$db,$hp) = @_;
  my($err,%copy);
#  &{"${TCTEST}::t_init"}($dbhome,$dbprimary);
# dump database to %copy
  my $cursor = 1;	# NOTE: cursor starts a 0 for perl, 1 for 'C'
  my $which = ($db eq $dbprimary) ? 0:1;
  while(@_ = &{"${TCTEST}::t_getrecno"}($which, $cursor++)) {
#  while(@_ = $sw->getrecno($db, $cursor++)) {
    my ($k,$v) = @_;
    $copy{$k} = $v;
  }
#  &{"${TCTEST}::t_close"}();
  print "failed to dump '$db'\nnot "
	unless keys %copy;
  &ok;
# check keys
  my $x = keys %$hp;
  my $y = keys %copy;
  print "bad key count ans=$x, db=$y\nnot "
	if $x != $y;
  &ok;
# check data content
  foreach(keys %copy) {
    if ($hp->{$_} !~ /^$copy{$_}$/) {
      print "data mismatch in '$db'\nnot ";
      last;
    }
  }
  &ok;
}

my %new = (
	dbfile	=> $dbprimary,
	dbhome	=> $dbhome,
);

mkdir 'tmp.dbhome',0755;
	
## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

## test 3	set up database connection using 'C'
print "failed to init databases\nnot "
        if &{"${TCTEST}::t_init"}($dbhome,$dbprimary);
&ok;

###
### preliminary's finished
###

## test 4

my $time = &next_sec();
my %tarpit = (
	inet_aton('0.0.0.1') => $time -20,
	inet_aton('0.0.0.2') => $time -10,
	inet_aton('0.0.0.3') => $time -5,
	inet_aton('0.0.0.4') => $time -1,
	inet_aton('0.0.0.5') => $time,
);
dbinsert($sw,'tarpit',\%tarpit);

## test 5-7 - verify tarpit data
dbcheck($sw,'tarpit',\%tarpit);

my %removedkeys;

## test 8 - cull, no data removal
print "shouldn't removed $_ keys\nnot "
	if ($_ = $sw->cull('tarpit',20,\%removedkeys));
&ok;

## test 9-11 - verify tarpit data
dbcheck($sw,'tarpit',\%tarpit); 

## test 12 - removed keys should be zero
print "removed keys should be zero\nnot "
	if keys %removedkeys;
&ok;

$time = &next_sec($time);

## test 13 - dummy remove of 2 records
my $nop = 1;
my %chkrmv = (
	inet_aton('0.0.0.1') => $tarpit{inet_aton('0.0.0.1')},
	inet_aton('0.0.0.2') => $tarpit{inet_aton('0.0.0.2')},
);
print "bad reported key count, ans=2, rmv=$_\nnot "
	unless ($_ = $sw->cull('tarpit',10,\%removedkeys,$nop));
&ok;

## test 14 - check real key count
my $y = keys %removedkeys;
print "bad real key count, ans=2, rmv = $y\nnot "
	if $y != 2;
&ok;

## test 15 - verify removed data
foreach(keys %removedkeys) {
  if ($removedkeys{$_} !~ /^$chkrmv{$_}$/) {
    print "removed data mismatch\nnot ";
    last;
  }
}
&ok;

## test 16-18 - verify tarpit data
dbcheck($sw,'tarpit',\%tarpit); 


## test 19 - real remove of 2 records
undef %removedkeys;
print "bad reported key count, ans=2, rmv=$_\nnot "
	unless ($_ = $sw->cull('tarpit',10,\%removedkeys));
&ok;

## test 20 - check real key count
$y = keys %removedkeys;
print "bad real key count, ans=2, rmv = $y\nnot "
	if $y != 2;
&ok;

## test 21 - verify removed data
foreach(keys %removedkeys) {
  if ($removedkeys{$_} !~ /^$chkrmv{$_}$/) {
    print "removed data mismatch\nnot ";
    last;
  }
}
&ok;

## test 22-24 - verify tarpit data
delete $tarpit{inet_aton('0.0.0.1')};
delete $tarpit{inet_aton('0.0.0.2')};
dbcheck($sw,'tarpit',\%tarpit); 

$sw->closedb();
&{"${TCTEST}::t_close"}();
