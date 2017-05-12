# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..30\n"; }
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

### database loader
# takes one test cycle
#
# input:	sw,db,\%hash
#
sub dbinsert {
  my($sw,$db,$hp) = @_;
  my $err;
  while(my($k,$v) = each %$hp) {
    if ($err = $sw->put($db,$k,$v)) {
      print "insert failure, database '$db'\nnot ";
      last;
    }
  }
  &ok;
}

## database checker
# takes 3 test cycles
#
# input:	sw,db,\%hash
#
sub dbcheck {
  my($sw,$db,$hp) = @_;
  my($err,%copy);
# dump database to %copy
  print "failed to dump '$db'\nnot "
	if $sw->dump($db,\%copy) ||
		! keys %copy;	# parm $db removed from args
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

my $localdir = cwd();
my $dbhome = "$localdir/tmp.dbhome";

my %new = (
	dbfile	=> ['tarpit','archive'],
	dbhome	=> $dbhome,
);

mkdir 'tmp',0755;
	
## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

###
### preliminary's finished
###

## test 3

my %archive = (
  inet_aton('0.0.0.1') => 111,
  inet_aton('0.0.0.2') => 222,
  inet_aton('0.0.0.3') => 333,
  inet_aton('0.0.0.4') => 444,
);

my %tarpit = (
  inet_aton('0.0.0.1') => 1,
  inet_aton('0.0.0.2') => 2,
  inet_aton('0.0.0.3') => 3,
  inet_aton('0.0.0.4') => 4,
);

## one test cycle, test 3
dbinsert($sw,'tarpit',\%tarpit);

## test 4
dbinsert($sw,'archive',\%archive);

## test 5-7 - verify tarpit data
dbcheck($sw,'tarpit',\%tarpit);

## test 8-10 - verify archive data
dbcheck($sw,'archive',\%archive);

## test 11 - check non-existent data
print "found non-existent data in 'tarpit'\nnot "
	if defined $sw->get('tarpit',inet_aton('1.2.3.4'));
&ok;

## test 12 - check some real data
print "failed to retrieve data '1' from 'tarpit'\nnot "
	unless $sw->get('tarpit',inet_aton('0.0.0.1')) =~ /^1$/;
&ok;

## test 13-15 - verify database integrity
dbcheck($sw,'tarpit',\%tarpit); 

## test 16 - check dummy remove
print "removed non-existent data in 'action'\nnot "
	if defined $sw->remove('tarpit',inet_aton('1.2.3.4'));
&ok;

## test 17-19 - verify database integrity
dbcheck($sw,'tarpit',\%tarpit); 

## test 20 - remove record from tarpit
delete $tarpit{inet_aton('0.0.0.2')};
$_ = $sw->remove('tarpit',inet_aton('0.0.0.2'));
print "failed to delete record from 'tarpit'\nnot "
	unless defined $_ && ! $_;
&ok;

## test 21-23 - verify tarpit database
dbcheck($sw,'tarpit',\%tarpit);

## test 24 - attempt bogus remove from db
print "removed non-existent data\nnot "
	if defined $sw->remove('tarpit',inet_aton('1.2.3.4'));
&ok;

## test 25-27 - verify tarpit database
dbcheck($sw,'tarpit',\%tarpit);

## test 28-30 - verify that archive database is unchanged
dbcheck($sw,'archive',\%archive);
$sw->closedb();
