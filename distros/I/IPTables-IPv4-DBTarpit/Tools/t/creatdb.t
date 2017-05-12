# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use IPTables::IPv4::DBTarpit::Tools;
$TPACKAGE = 'IPTables::IPv4::DBTarpit::Tools';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp tmp.dbhome)) {
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

my $localdir = cwd();

## test 2 - test that presence of file of same name as dir is detected
# create file of the name 'tmp.dbhome';

my $dbhome = $localdir.'/tmp.dbhome';
print "could not create bogus file $dbhome\nnot "
	unless open(X,'>'.$dbhome);
select X;
$| = 1;
select STDOUT;

print X "\n";
close X;

my %new = (
	dbfile	=> ['tarpit'],
	dbhome	=> $dbhome,
);

my $sw;
eval {
  $sw = new $TPACKAGE(%new);
};
print $@, "not " unless $@ && $@ =~ /is not a directory/;
&ok;

unlink $dbhome;

## test 3 - check for faulty db creation because dbhome is missing and not creatable
my $save = $new{dbhome};
$new{dbhome} .= '/more';

eval {
  $sw = new $TPACKAGE(%new);
};
print $@, "not " unless $@ && $@ =~ m|$localdir/tmp|;
&ok;

## test 4 - create 'tmp.dbhome'
$new{dbhome} = $save;
## for database creation if tmp.dbhome dir's present
eval {
  $sw = new $TPACKAGE(%new);
};
print $@, "not " if $@;
&ok;

## test 5	check for true return ( a real pointer )
print "expected 'true' return, got false\nnot "
	unless $sw;
&ok;

## test 6 - check that db 'tarpit' was created
eval {
  $sw = new $TPACKAGE(%new);
};
print "failed to create '$new{dbfile}->[0]' database\nnot "
	 unless -e $new{dbhome}.'/'.$new{dbfile}->[0];
&ok;

## test 7 - close database
print "should return unconditional 'undef'\nnot "
	if $sw->closedb;
&ok;
