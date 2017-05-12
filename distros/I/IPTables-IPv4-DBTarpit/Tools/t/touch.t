# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools qw(inet_aton);
$TPACKAGE = 'IPTables::IPv4::DBTarpit::Tools';
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

my %new = (
	dbfile	=> ['tarpit'],
	dbhome	=> $dbhome,
);

mkdir 'tmp',0755;
	
## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

my %ans2 = (
  inet_aton('4.0.0.1') => $test,
  inet_aton('5.0.0.2') => $test + 1,
);

## test 3 & 4 - add items to 'tarpit', make them numeric
print "could not update 'tarpit' $test\nnot "
	if $sw->touch('tarpit',inet_aton('4.0.0.1'),$test);
&ok;
print "could not update 'tarpit' $test\nnot "
	if $sw->touch('tarpit',inet_aton('5.0.0.2'),$test);
&ok;

## test 5 - add real timestamp to 'tarpit'
my $time = &next_sec();		# sync to epoch

$ans2{inet_aton('6.0.0.3')} = $time;
print " could not add 'tarpit' timestamp\nnot "
	if  $sw->touch('tarpit',inet_aton('6.0.0.3'));
&ok;

## test 6 - verify 'tarpit' update
undef %load;

print "failed to dump 'tarpit'\nnot "
	if $sw->dump('tarpit',\%load);
&ok;

## test 7 - check size match
$x = keys %ans2;
$y = keys %load;
print "tarpit keys do not match, ans=$x, dump=$y\nnot "
	if $x != $y;
&ok;

## test 8 - verify data match
foreach(keys %load) {
  if ($load{$_} != $ans2{$_}) {
    print "tarpit data does not match\nnot ";
    last;
  }
}
&ok;

## test 9 - dump entire tarpit db
undef %load;
print "failed to dump 'tarpit'\nnot "
	if $sw->dump('tarpit',\%load);
&ok;

## test 10 - verify dump count
$x = keys %ans2;
$y = keys %load;
print "bad key count, ans=$x, dump=$y\nnot "
	if $x != $y;
&ok;

## test 11 = verify content
foreach(keys %ans2) {
  if($load{$_} != $ans2{$_}) {
    print "dump data mismatch\nnot ";
    last;
  }
}
&ok;

$sw->closedb();

## test 12 - reopen db

$sw = eval {
        new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

## test 13 - re-dump data
undef %load;
print "failed to dump 'tarpit'\nnot "
        if $sw->dump('tarpit',\%load);
&ok;

## test 14 - verify dump count
$x = keys %ans2;
$y = keys %load;
print "bad key count, ans=$x, dump=$y\nnot "
        if $x != $y;
&ok;

## test 15 = verify content
foreach(keys %ans2) {
  if($load{$_} != $ans2{$_}) {
    print "dump data mismatch\nnot ";
    last;
  }
}  
&ok;

$sw->closedb();
