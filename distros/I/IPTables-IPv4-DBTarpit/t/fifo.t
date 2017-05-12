# Before ake install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use POSIX qw(:errno_h :sys_stat_h);
use Cwd;
use CTest;
use IPTables::IPv4::DBTarpit::Tools qw(db_strerror);

$TCTEST         = 'IPTables::IPv4::DBTarpit::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 007;
foreach my $dir (qw(tmp tmp.dbhome )) {
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

sub ok {
  print "ok $test\n";
  ++$test;
}
my $localdir = cwd();
my $dbhome = "$localdir/tmp.dbhome";

my @etxt = qw(EPIPE ENOSPC EEXIST ENOENT ENOTDIR ENXIO ENODEV);
foreach(@etxt) {
  print "$_ => ", eval "$_()",' ', db_strerror(eval "$_()"), "\n";
}

my $message = qq|The quick brown fox jumped over the lazy dog\n0123456789\n|;
my $fifoname = 'testfifo';
my $fifopath = $dbhome.'/'.$fifoname;
my $S_IFMT  = 0170000;
my $S_IFIFO = 0010000;

## test 2	dbhome directory does not exist
my $ev = eval {
	&{"${TCTEST}::t_LogPrint"}($dbhome,$fifoname,$message,0,0)};
print "got: $ev => ", db_strerror($ev), ' exp: ENOENT => ',db_strerror(ENOENT()),"\nnot "
	if $ev != ENOENT();
&ok;

## test 3
print "failed to make test directory\nnot "
	unless mkdir $dbhome,0755;
&ok;

## test 4
print "failed to make bogus file '$fifopath'\nnot "
	unless open(W,'>',$fifopath);
close W;
&ok;

## test 5	check detection of non-fifo
$ev = eval {
	&{"${TCTEST}::t_LogPrint"}($dbhome,$fifoname,$message,0,0)};
print "got: $ev => ", db_strerror($ev), ' exp: EEXIST =>',db_strerror(EEXIST()),"\nnot "
	if $ev != EEXIST();
&ok;

unlink $fifopath;

## test 6	check for good open, no reader
($ev, my $fd) = eval {
	&{"${TCTEST}::t_LogPrint"}($dbhome,$fifoname,$message,0,0)};
print "got: $ev => ", db_strerror($ev), ' exp: ENXIO => ',db_strerror(ENXIO()),"\nnot "
	if $ev != ENXIO();
&ok;

## test 7	check for fifo present
my $mode = (stat($fifopath))[2];

printf("bad mode: %o, exp: S_IFIFO = %o\nnot ",$mode & $S_IFMT, $S_IFIFO)
	unless ($mode & $S_IFMT) == $S_IFIFO;
&ok;

## test 8	the kernel buffers a small amount of text for a pipe, so
#		open a reader now;

my $rv;
my $pid = fork;
if ($pid) {		# parent
  $rv = eval {	# block here until write to fifo
	local $SIG{ALRM} = sub {die "child timed out"};
	local $/;
	alarm 5;
	open(R,$fifopath) or die "could not open FIFO for read\n";
	$rv = <R>;	# read a line
	alarm 0;
	close R;
	$rv;
  };
} else {	# child
    sleep 2;
    if ($fd > 0) {
      &{"${TCTEST}::t_LogPrint"}($dbhome,$fifoname,$message,0,0,$fd);
    } else {
      ($ev,$fd) = &{"${TCTEST}::t_LogPrint"}($dbhome,$fifoname,$message,0,0);
    } 
    &{"${TCTEST}::t_fifo_close"}();
    exit;
}


print "$@\nnot "
	if $@;
&ok;

print "failed to receive message\ngot: $rv\nexp: $message\nnot "
	unless $rv eq $message;
&ok;

waitpid($pid,0);
unlink $fifopath;
