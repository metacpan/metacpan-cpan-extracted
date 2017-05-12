# exercise -MForks::Super=cleanse
#
# run some programs that create IPC files
# 1. when the programs run normally, there should be no IPC litter
# 2. when the programs are interrupted, there may be IPC litter
# 3. after we run cleanse, there should be no IPC litter

use Test::More tests => 5;

$ENV{IPC_DIR} = "t/out/ipc_dir.$$";
mkdir $ENV{IPC_DIR};

my @inc = map { "-I$_" } @INC;
if (${^TAINT}) {
    delete $ENV{PATH};
    delete $ENV{ENV};
    use Config;
    $^X = $Config::Config{perlpath};
}

ok(!has_litter(), "no litter initially");

run_jobs(0);
ok(!has_litter(), "no litter after normal run");

run_jobs(1);
ok(has_litter(), "litter after interrupted run");

# the  -e 1  should be optional? But on linux with Perl v5.8 I get a
# << Can't stat script "-" >> error?
$c1 = system($^X, @inc, "-MForks::Super=cleanse,$ENV{IPC_DIR}", '-e', 1);
ok($c1==0, "successfully ran Forks::Super in cleanse mode");

ok(!has_litter(), "no litter after cleanse");

rmdir "t/out/ipc_dir.$$";
unlink "t/out/70.$$.pl";

sub has_litter {
    opendir my $dh, $ENV{IPC_DIR};
    my @files = readdir($dh);
    closedir $dh;
    return @files > 2;
}

sub run_jobs {
    my ($suppress_cleanup) = @_;
    my $script = "t/out/70.$$.pl";

    open T70, '>', $script;
    print T70 <<'__EOF__';
use Forks::Super;
my $job = fork {
    child_fh => "all,block",
    sub => sub {
        my $x = <STDIN>;
        print STDOUT $x;
        print STDERR $x;
	# sleep 2
    },
    timeout => 10
};
print {$job->{child_stdin}} "foo\n";
my $y = $job->read_stdout();
my $z = $job->read_stderr();
$job->wait;
__EOF__
    ;
    close T70;

    # print "program:\n---------------\n$prog\n----------------\n\n";

    my $pid = CORE::fork();
    if ($pid == 0) {
	local $ENV{FORKS_DONT_CLEANUP} = $suppress_cleanup;
	exec($^X, @inc, $script);
	exit 0;
    }

    my $pid2 = wait;
    #print "wait returned $pid2 after ${t}s\n";
    sleep 5; # ipc cleanup may take a short while 
             # even after program ostensibly ends
    return;
}
