use Forks::Super ':test';
use Test::More tests => 9;
use strict;
use warnings;

# exercise Forks::Super::Job::dispose method

# disposed jobs:
#    should not have any accessible information
#    should not have any open IPC filehandles
#    temporary IPC files should be deleted.
#    should not be accessible through @ALL_JOBS or %ALL_JOBS

my $j = fork {
    child_fh => "in,out,err,file,block",
    sub => sub {
	# sleep 2;  # sleep not required after 0.55ii
	my $p = <STDIN>;
	print STDOUT $p;
	print STDERR $p;
	exit 4;
    }
};

$j = Forks::Super::Job::get($j);
$j->write_stdin("foo fee\n");
close $j->{child_stdin};

my $f_out = $j->{fh_config}->{f_out};
my $f_err = $j->{fh_config}->{f_err};
my $f_in = $j->{fh_config}->{f_in};

SKIP: {
    skip "No files in use", 1
	if Forks::Super::Config::CONFIG('filehandles') == 0;
    ok(-f $f_out && -f $f_err && -f $f_in,
       "temp IPC files exist before dispose");
}
ok(grep( { $_ eq $j } @Forks::Super::Job::ALL_JOBS),
   "job present in \@ALL_JOBS before dispose");
ok(exists $Forks::Super::Job::ALL_JOBS{$j->{real_pid}},
   "job present in \%ALL_JOBS before dispose");
waitpid $j, 0;
ok(4 << 8 == $j->{status}, "job finished");

#my $q = $j->read_stdout();
my $q = <$j>;
ok($q eq "foo fee\n", "stdout accessible before dispose")
    or diag("\$q = $q");

my $pid = $j->{real_pid};
$j->dispose();

my $r = $j->read_stderr();
ok(!defined($r) || $r eq '', "stderr not accessible after dispose");
ok(! -f $f_out && ! -f $f_err && ! -f $f_in,
   "temp IPC files deleted after dispose");
ok(! grep( { $_ eq $j } @Forks::Super::Job::ALL_JOBS),
   "job not present in \@ALL_JOBS after dispose");
ok(! exists $Forks::Super::Job::ALL_JOBS{$pid},
   "job not present in \%ALL_JOBS after dispose");





