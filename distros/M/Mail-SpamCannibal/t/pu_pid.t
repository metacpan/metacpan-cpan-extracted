# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::PidUtil qw(
	:all
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp)) {
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

my $path = './tmp';
mkdir $path,0755;

$path .= '/';

## test 2	get my name
my $me = get_script_name();
print "got: $me, exp: test.pl or pu_pid.t\nnot "
	unless $me eq 'test.pl' || $me eq 'pu_pid.t';
&ok;

## test 3	make pid file
my $pidfile = $path . $me . '.pid';
my $pid = $$;
print "make_pidfile returned: $_, exp: $pid\nnot "
	unless ($_ = make_pidfile($pidfile)) == $pid;
&ok;

## test 4	see if it's real
print "missing pid file '$pidfile'\nnot "
	unless -e $pidfile;
&ok;

## test 5	open pidfile
print "could not open $pidfile\nnot "
	unless open(F,$pidfile);
&ok;

## test 6	check contents
$_ = <F>;
chomp;
close F;
print "got $_, exp: $pid\nnot "
	unless $_ == $pid;
&ok;

## test 7	check running
print "got: $_, exp: $pid\nnot "
	unless ($_ = is_running($pidfile)) == $pid;
&ok;

## test 8	rewrite pid file with different stuff
my $exp = fork;
exit unless $exp;
waitpid($exp,0);
print "could not open '$pidfile' for write\nnot "
	unless ($_ = make_pidfile($pidfile,$exp)) == $exp;
&ok;

## test 9	check child not running
print "got: $_, exp: 0\nnot "
	if ($_ = is_running($pidfile));
&ok;

## test 10	unlink pid file
print "could not unlink PID file\nnot "
	unless zap_pidfile($path);

&ok;

## test 11	check that it's really gone
print "PID file still exists\nnot "
	if -e $pidfile;
&ok;

## test 12       check nothing is running
print "got: $_, exp: 0\nnot "
        if ($_ = is_running($pidfile));
&ok;

