# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}

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

sub ok {
  print "ok $test\n";
  ++$test;
}

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
  unlink $dir if -e $dir;       # remove files of this name as well
}

mkdir 'tmp',0755;

my $localdir = cwd();

my $expect = '/var/run/dbtarpit/dnsbls.pid';
my $expchild = '/var/run/dbtarpit/dnsbls.'. $$ .'.pid';
 
# initialize since 'main' is not called
&{"${TCTEST}::t_set_parent"}(1);

## test 2 - retrieve default path
my $path =  &{"${TCTEST}::t_pidpath"}();
print "exp: $expect\ngot: $path\nnot "
	unless $path eq $expect;
&ok;

$expect = $localdir .'/tmp/testpid.pid';

## test 3 - return expected path if pid file is missing
$path = &{"${TCTEST}::t_chk4pid"}($expect);
print print "exp: $expect\ngot: $path\nnot "  
        unless $path && $path eq $expect;
&ok;

## test 4 - double check that 'expected' is really not there
print "did not expect to find $expect\nnot "
	if -e $expect;
&ok;

## test 5 - "pidrun" should contain "0"
my $pidexp = 0;
my $pid = &{"${TCTEST}::t_pidrun"}();
print "found pid $pid, expected $pidexp\nnot "
	unless $pidexp == $pid;
&ok;

## test 6 - create valid pid file
print "could not open pid file $expect\nnot "
	unless open(F,'>'. $expect);
&ok;

$pidexp = $$;
print F "$pidexp\n";
close F;

## test 7 - reject because pid is running
print "did not reject running pid\nnot "
	if &{"${TCTEST}::t_chk4pid"}($expect);
&ok;

## test 8 - pidrun should contain $$
$pid = &{"${TCTEST}::t_pidrun"}();
print "found pid $pid, expected $pidexp\nnot "
        unless $pidexp = $pid;
&ok;

# create dead pid by forking a kid
my $deadpid;
if($deadpid = fork) {
  waitpid($deadpid,0);
} else {
  exit;		# kill the kid
}

$pidexp = $deadpid;

## test 9 - create valid pid file with dead pid
print "could not open pid file $expect\nnot "
        unless open(F,'>'. $expect);
&ok;

print F "$deadpid\n";
close F;

## test 10 - return expected path if pid is unused
$path = &{"${TCTEST}::t_chk4pid"}($expect);
print print "exp: $expect\ngot: $path\nnot "
        unless $path && $path eq $expect;   
&ok;

## test 11 - pidrun should contain $deadpid
$pid = &{"${TCTEST}::t_pidrun"}();  
print "found pid $pid, expected $pidexp\nnot "
        unless $pidexp = $pid;
&ok;

## test 12 - validate that pid file really contains $deadpid
print "could not open pid file $expect\nnot "
        unless open(F,$expect);
&ok;

$_ = <F>;
chop;
close F;

##test 13 - validate pid values
print "retrieved PID value: $_ ne expected: $deadpid\nnot "
	unless $_ == $deadpid;
&ok;

## test 14 - overwrite deadpid value with current value
&{"${TCTEST}::t_savpid"}($expect);
print "could not open pid file $expect\nnot "
        unless open(F,$expect);
&ok;

$_ = <F>;
chop;
close F;

##test 15 - validate pid values
print "retrieved PID value: $_ ne expected: $$\nnot "
        unless $_ == $$;
&ok;

$pidexp = $$;

## test 16 - pidrun should contain $$
$pid = &{"${TCTEST}::t_pidrun"}();  
print "found pid $pid, expected $pidexp\nnot "
        unless $pidexp = $pid;
&ok;

## test 17	check child functions
print "got: $_, exp: 1\nnot "
	unless ($_ = &{"${TCTEST}::t_set_parent"}(0)) == 1;
&ok;

## test 18	check that pid filename is correct
print "got: $_, exp: $expchild\nnot "
	unless $expchild eq ($_ = &{"${TCTEST}::t_pidpath"}());
&ok;
