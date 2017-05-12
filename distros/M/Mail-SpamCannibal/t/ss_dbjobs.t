# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Cwd;
use Mail::SpamCannibal::ScriptSupport qw(
	job_died
	dbjob_chk
	dbjob_kill
	dbjob_recover
);
use Mail::SpamCannibal::PidUtil qw(
	make_pidfile
);

use POSIX qw(mkfifo O_WRONLY);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

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

my $path = cwd() .'/tmp';
mkdir $path,0755;

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub makeKids {
  my $path = shift;
  my @kids;
  foreach(0..3) {				# create 3 kids
    next if $kids[$_] = fork;
    make_pidfile($path . '/test.'. $$ .'.pid');
    if ($_ == 3) {
      local $SIG{TERM} = 'IGNORE';	# ignore last child
    }
    sleep 60;				# all sleep a minute
    exit(0);
  }
  return @kids;
}

my @kids = makeKids($path);

next_sec();			# wait for children to get established

my %default = (
	dbhome	=> $path,
	dbfile	=> ['tarpit'],
	umask	=> 07,
);
my $tool = new IPTables::IPv4::DBTarpit::Tools(%default);
$tool->closedb;

# capture and alter environment file mode for testing
opendir(D,$path);
@_ = grep(/^__/,readdir(D));	# get environment files
closedir D;
my $efile = $path .'/'. $_[0];
my($mode,$ctime) = (stat($efile))[2,10];
$mode &= 0777;
#$mode ^= 06;			# flip the world RW mode bits
foreach(@_) {
  chmod $mode, $path .'/'. $_;
}
next_sec();			# wait a little more

## test 2	get array of children that live
my %kids;	
print "dead child found\nnot "
	if job_died(\%kids,$path);
&ok;

## test 3	should be 4 kids
print "got: $_, exp: 4 kids\nnot "
	unless ($_ = keys %kids) == 4;
&ok;

## test 4	should have one dead kid
kill 15, (my $reap = shift @kids);
waitpid($reap,0);
next_sec();
%kids = ();
print "missed dead child\nnot "
	unless job_died(\%kids,$path);
&ok;

## test 5	check for reaped child
my $kid = $path . '/test.'. $reap .'.pid';
print "missing reaped child $kid\nnot "
	unless exists $kids{$kid} &&
		$kids{$kid} == 0;
&ok;

unlink $kid;

## test 6	check for kid race condition
## make kid one
# this kid will respond with a valid pid file and contents 
# then the file and job will disappear 
$kid = $path .'/1test.pid';
mkfifo($kid,0666);
unshift @kids, fork;
unless ($kids[0]) {
  sysopen(FIFO,$kid,O_WRONLY);
  next_sec();			# give the reader time to open the pipe
  rename $kid, $kid .'.pid';	# rename the pipe so it will not be found
  print FIFO 0,"\n";		# say we are not running
  close FIFO;
  unlink $kid.'.pid';		# remove the pipe at our leisure
  exit;
}

## test 6 cont	check for kid race condition
%kids = ();
print "found unexpected dead child\nnot "
	if job_died(\%kids,$path);
&ok;

## test 7	check number of kids
print "got: $_, exp: 3 kids\nnot "
	unless ($_ = keys %kids) == 3;
&ok;

waitpid((shift @kids),0);	# zap pipe kid

## test 8	check for all tasks running
print "found unexpected dead child\nnot "
	unless dbjob_chk(\%default);
&ok;

## test 9	set block
kill 15, ($reap = shift @kids);
waitpid($reap,0);   
my $time = next_sec();
print "dead child not found\nnot "
	if dbjob_chk(\%default);
&ok;

## test 10	verify watcher block file
print "watcher file 'blockedBYwatcher' not found\nnot "
	unless -e $path .'/blockedBYwatcher';
&ok;

## test 11	kill off all jobs
dbjob_kill(\%default,4);
%kids = ();
print "found dead child\nnot "
	if job_died(\%kids,$path);
&ok;

foreach(@kids) {
  no warnings;
  kill 9, $_;				# zap anyone that slipped by
  waitpid($kids[$_],0);			# wait for child to terminate
}

my $me = $path .'/me.pid';
open(ME,'>'. $me) || die "could not open $path/me.pid\n";
print ME $$,"\n";
close ME;

@kids = makeKids($path);
next_sec();
kill 15, $kids[0];
waitpid($kids[0],0);
next_sec();

## test 12	check for 5 jobs (one is me, 4 kids, one is dead)
%kids = ();
print "dead child not found\nnot "
	unless job_died(\%kids,$path);
&ok;

## test 13	check number of jobs
print "got: $_, exp: 5\nnot "
	unless ($_ = keys %kids) == 5;
&ok;

## test 14	place block
print "dead child not found\nnot "
        if dbjob_chk(\%default);  
&ok;

## test 15	kill everyone but me
dbjob_kill(\%default,1);	# should default up to 3 grace period and kill quick
%kids = ();
print "found dead child\nnot "
        if job_died(\%kids,$path);
&ok;

## test 16	should only be ME
print "I'm missing in action or dead\nnot "
	unless keys %kids == 1;
&ok;

## test 17	check that I remain with correct PID. How could I not??
print "I'm not ME, exp: $$, got: $kids{$me}\nnot "
	unless $$ == $kids{$me};
&ok;

## test 18	remove block file and re-init database
dbjob_recover(\%default);
# block should be gone
print "block file remains\nnot "
	if -e $path .'/blockedBYwatcher';
&ok;


my ($newmode,$newtime) = (stat($efile))[2,10];
$newmode &= 0777;
## test 19	check that environment is new
print "environment file is not new, new: $newtime, old: $ctime\nnot "
	if $ctime == $newtime;
&ok;

## test 20	check that mode is restored
printf("bad mode, got: %o, exp: %o\nnot ",$newmode,$mode)
	unless $mode == $newmode;
&ok;

# kill any forgotten children
foreach(@kids) {
  no warnings;
  kill 9, $_;				# zap anyone that slipped by
  waitpid($kids[$_],0);			# wait for child to terminate
}

