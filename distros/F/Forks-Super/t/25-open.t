use Forks::Super ':test';
use Test::More tests => 37;
use strict;
use warnings;

if ($^O eq 'MSWin32') {
    Forks::Super::Config::CONFIG_module("Win32::API");
    if ($Win32::API::VERSION && $Win32::API::VERSION < 0.71) {
	warn qq[

Win32::API v$Win32::API::VERSION found. v>=0.71 may be required
to pass this test and use the features exercised by this test.

];
    }
}

for my $stdfh (*STDOUT, *STDERR) {
    binmode $stdfh, $^O eq 'MSWin32' ? ':utf8' : ':encoding(UTF-8)';
}

my @cmd = ($^X, "t/external-command.pl",
	   "-e=Hello", "-s=4", "-y=1", "-e=whirled");

my ($fh_in, $fh_out, $pid, $job) = Forks::Super::open2(@cmd);

ok(defined($fh_in) && defined($fh_out), "open2: child fh available");
ok(isValidPid($pid), "open2: valid pid $pid");
sleep 2;
ok(defined($job), "open2: received job object");
ok($job->{state} eq 'ACTIVE', "open2: job is active " . $job->{state});

my $msg = sprintf "%05x", rand() * 99999;
my $z = print {$fh_in} "$msg\n";
Forks::Super::close_fh($pid,'stdin');
ok($z > 0, "open2: print to input handle ok = $z");
for (1..10) {
    Forks::Super::Util::pause(1);
    last if $job->{state} eq 'COMPLETE';
}

my @out = Forks::Super::read_stdout($pid);
Forks::Super::close_fh($pid, 'stdout');
ok(@out == 2,                                                      ### 6 ###
   "open2: got right number of output lines 2 == " . scalar @out)
  or diag("Output was:\n@out\nExpected 2 lines");
ok($out[0] eq "Hello $msg\n", "got right output")                  ### 7 ###
  or diag("Got \"$out[0]\", expected \"Hello $msg\\n\"");
Forks::Super::pause();
ok($job->{state} eq 'COMPLETE', "job complete");
ok($pid == waitpid($pid,0), "job reaped");

######################################################

my $fh_err;
@cmd = ($^X, "t/external-command.pl",
	   "-e=Hello", "-s=4", "-y=3", "-e=whirled");
($fh_in, $fh_out, $fh_err, $pid, $job) = Forks::Super::open3(@cmd);
ok(defined($fh_in) && defined($fh_out) && defined($fh_err),
   "open3: child fh available");
ok(isValidPid($pid), "open3: valid pid $pid");
sleep 1;
ok(defined($job), "open3: received job object");
ok($job->{state} eq 'ACTIVE', "open3: job is active " . $job->{state});

$msg = sprintf "%05x", rand() * 99999;
$z = print $fh_in "$msg\n";
Forks::Super::close_fh($pid,'stdin');
ok($z > 0, "open3: print to input handle ok = $z");
for (1..10) {
    Forks::Super::Util::pause(1.0);
    last if $job->is_complete;
}

@out = Forks::Super::read_stdout($pid);
Forks::Super::close_fh($pid, 'stdout');

my @err = Forks::Super::read_stderr($pid);

if (!Forks::Super::Config::CONFIG('filehandles')) {
    @err = grep { !/set_signal_pid/ } @err;
}

Forks::Super::close_fh($pid, 'stderr');
ok(@out == 4, "open3: got right number of output lines")            ### 15 ###
  or diag("open3 output was:\n@out\nExpected 4 lines");
ok(@out>0 && $out[0] eq "Hello $msg\n", "got right output (1)")     ### 16 ###
  or diag("First output was \"$out[0]\", expected \"Hello $msg\\n\"");
ok(@out>1 && $out[1] eq "$msg\n", "got right output (2)")           ### 17 ###
  or diag("2nd output was \"$out[1]\", expected \"$msg\\n\"");
ok(@err == 1, "open3: got right error lines");                      ### 18 ###
ok(@err>0 && $err[0] eq "received message $msg\n",                  ### 19 ###
   "open3: got right error")
  or diag("Error was \"$err[0]\",\n",
	  "Expected \"received message $msg\\n\"");
Forks::Super::pause();
ok($job->{state} eq 'COMPLETE', 
   "job state " . $job->{state} . " == 'COMPLETE'");
ok($pid == waitpid($pid,0), "job reaped");

#############################################################################

sub mswin32diag { diag @_ if $^O eq 'MSWin32'; }

Forks::Super::Debug::use_Carp_Always();

@cmd = ($^X, "t/external-command.pl",
        "-e=Hello", "-s=19", "-y=3", "-e=whirled");
mswin32diag "starting FS::open3";
($fh_in, $fh_out, $fh_err, $pid, $job) 
    = Forks::Super::open3(@cmd, {timeout => 6});
mswin32diag "started FS::open3";    # timeout is Win32 failure point

ok(defined($fh_in) && defined($fh_out) && defined($fh_err),    ### 22 ###
   "open3: child fh available");
ok(defined($job), "open3: received job object");
ok($job->{state} eq 'ACTIVE', "open3: respects additional options");
mswin32diag 'checked job state';
sleep 1;
$msg = sprintf "%05x", rand() * 99999;
$z = print $fh_in "$msg\n";
mswin32diag 'wrote job input, z=', $z;
Forks::Super::close_fh($pid,'stdin');
mswin32diag 'closed job stdin';
ok($z > 0, "open3: print to input handle ok = $z"); 	       ### 25 ###

mswin32diag 'waiting for job to complete';
for (1..30) {
    Forks::Super::Util::pause(1.0);
    last if $job->is_complete;
    if ($_ == 30) {
	diag "open3 command still not complete after 30s";
    }
}
mswin32diag 'job is complete';

@out = <$fh_out>;
mswin32diag 'read stdout';
Forks::Super::close_fh($pid, 'stdout');
mswin32diag 'close stdout';
@err = <$fh_err>;
mswin32diag 'read stderr';
Forks::Super::close_fh($pid, 'stderr');
mswin32diag 'close stderr';
if (!Forks::Super::Config::CONFIG('filehandles')) {
    @err = grep { !/set_signal_pid/ } @err;
}

ok(@out == 1 && $out[0] =~ /^Hello/, 
   "open3: time out  \@out='@out'" . scalar @out);   ### 26 ###
ok(@err == 0 || $err[0] =~ /timeout/, "open3: job timed out")
    or diag("error was @err\n");
waitpid $pid,0;
ok($job->{status} != 0,
   "open3: job timed out status $job->{status}!=0")  ### 28 ###
    or diag("status was $job->{status}, expected ! 0");

#############################################################################

@cmd = ($^X, "t/external command.pl",
	   "-e=Hello", "-s=4", "-y=1", "-e=whirled");

($fh_in, $fh_out, $pid, $job) = Forks::Super::open2(@cmd);

ok(defined($fh_in) && defined($fh_out), "open2: child fh available (cmd w/meta)");
ok(isValidPid($pid), "open2: valid pid $pid (cmd w/meta)");
sleep 2;
ok(defined($job), "open2: received job object (cmd w/meta)");
ok($job->{state} eq 'ACTIVE', "open2: job is active " . $job->{state});

$msg = sprintf "%05x", rand() * 99999;
$z = print {$fh_in} "$msg\n";
Forks::Super::close_fh($pid,'stdin');
ok($z > 0, "open2: print to input handle ok = $z (cmd w/meta)");
for (1..10) {
    Forks::Super::Util::pause(1);
    last if $job->{state} eq 'COMPLETE';
}

@out = Forks::Super::read_stdout($pid);
Forks::Super::close_fh($pid, 'stdout');
ok(@out == 2,                                                      ### 34 ###
   "open2: got right number of output lines 2 == " . scalar @out)
  or diag("Output was:\n@out\nExpected 2 lines");
ok($out[0] eq "Hello $msg\n", "got right output")                  ### 35 ###
  or diag("Got \"$out[0]\", expected \"Hello $msg\\n\"");
Forks::Super::pause();
ok($job->{state} eq 'COMPLETE', "job complete (cmd w/meta)");
ok($pid == waitpid($pid,0), "job reaped (cmd w/meta)");

######################################################
