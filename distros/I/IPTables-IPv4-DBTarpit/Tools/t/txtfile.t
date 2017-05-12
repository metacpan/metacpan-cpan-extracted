# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
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
	txtfile	=> ['txtdatabase'],
	dbhome	=> $dbhome,
);

mkdir 'tmp',0755;
	
## test 2 -  establish DB connections
my $sw = eval {
	new $TPACKAGE(%new);
};
print "failed to open db\nnot " if $@;
&ok;

## test 3 -- txtdatabase created by itself
opendir(D, "$localdir/tmp.dbhome");
@_ = grep(!/^\./ && !/^_/,readdir(D));
closedir D;

print "created more than one database\nnot "
	if @_ > 1;
&ok;

## test 4 -- txtdatabase creation verified
print "failed to create txtdatabase\nnot "
	unless $_[0] eq 'txtdatabase';
&ok;

my %ans2 = (
  inet_aton('0.0.0.1') => 'the quick brown fox jumped
over the lazy dog',
  inet_aton('0.0.0.2') => 'THE QUICK BROWN FOX JUMPED OVER
THE LAZY DOG 1234567890',
);

## test 5 & 6 - add items to 'txtdatabase', make them numeric
print "could not update 'txtdatabase'\nnot "
	if $sw->put('txtdatabase',inet_aton('0.0.0.1'),$ans2{inet_aton('0.0.0.1')});
&ok;
print "could not update 'txtdatabase'\nnot "
	if $sw->put('txtdatabase',inet_aton('0.0.0.2'),$ans2{inet_aton('0.0.0.2')});
&ok;

## test 7 - verify 'txtdatabase' update
my %load;

print "failed to dump 'txtdatabase'\nnot "
	if $sw->dump('txtdatabase',\%load);
&ok;

## test 8 - check size match
$x = keys %ans2;
$y = keys %load;
print "txtdatabase keys do not match, ans=$x, dump=$y\nnot "
	if $x != $y;
&ok;

## test 9 - verify data match
foreach(keys %load) {
  if ($load{$_} ne $ans2{$_}) {
print inet_aton($_)," => $load{$_}\nNE => $ans2{$_}\n";
    print "txtdatabase data does not match\nnot ";
#    last;
  }
}
&ok;

$sw->closedb();
