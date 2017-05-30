use Forks::Super ':test';
use Test::More;
use strict;
use warnings;

my $ntests = 33;
plan tests => $ntests;

# !!! - the remote feature is difficult to test. Don't sweat it too much
#       if the t/49*.t tests are the only ones that fail.

SKIP: {
    if (!Forks::Super::Config::CONFIG_module('Cwd')) {
        skip "sort of required Cwd", $ntests;
    }

    require "t/remote.pl";
    my $sshd = get_test_sshd();
    if (!$sshd) {
        ok(1, "no ssh server available, skipping all test");
        skip "test ssh server not available", $ntests-1;
    }
    my $cwd = Cwd::cwd();
    ($cwd) = $cwd =~ /(.*)/;

    if (!Forks::Super::Config::CONFIG_module('Net::OpenSSH')) {
        skip "remote with socket requires Net::OpenSSH", $ntests;
    }
    if (!Forks::Super::Config::CONFIG_module('Test::SSH')) {
        skip "remote with socket requires Test::SSH", $ntests;
    }

    my $xcmd = "$cwd/t/external-command.pl";
    if (! -r $xcmd) {
        skip "can't find external command for test", $ntests;
    }

    my $rhost = $sshd->host;
    my $ruser = $sshd->user;
    my $rport = $sshd->port;
    my $rhostx = $ruser . '@' . $rhost . ":" . $rport;;
    my $rpwd = $sshd->password;
    my $ids = $sshd->key_path;

    ### fully specified %remote_opts
    my $full_remote = { host => $rhost, user => $ruser, port => $rport,
                        proto => 'ssh' };

    if ($rpwd && $sshd->auth_method =~ /password/) {
        $full_remote->{password} = $sshd->password;
    } elsif ($ids && $sshd->auth_method =~ /publickey/) {
        $full_remote->{key_path} = $ids;
    }

    # remote => \@hosts
    my $full_remote2 = { %$full_remote };
    $full_remote2->{host} = [ $full_remote->{host} ];

    my $pid = fork {
        cmd => [ $^X, $xcmd, "-e=Hello", "-w=World", "-x=4" ],
        remote => $full_remote,
        child_fh => "socket,out,err",
    };
    ok($pid, "fork with rhost $pid->{remote}{host}");
    ok($pid == waitpid($pid,0), 'waitpid on remote cmd');
    my @out = $pid->read_stdout;
    ok(@out > 0, 'got remote output');
    ok("@out" =~ /Hello/, 'got expected remote output');
    my @err = $pid->read_stderr;
    ok(@err > 0, 'got remote error stream');
    ok("@err" =~ /World/, 'got expected remote error') or diag @err;
    ok($pid->{status} == 4 * 256, 'got remote status [4]');

    ### simple  remote => hostname

    $pid = fork {
        cmd => [ $^X, $xcmd, "-e=Never", "-w=Mind", "-x=7" ],
        remote => $full_remote,
        child_fh => "pipe,out,err",
    };
    ok($pid, "fork with rhost $pid->{remote}{host}");
    my $w = wait;
    ok($pid == $w, 'wait on remote cmd ' . __LINE__) or diag($pid,$w);
    @out = $pid->read_stdout;
    ok(@out > 0, 'got remote output');
    ok("@out" =~ /Never/, 'got expected remote output')   or diag @out;
    @err = $pid->read_stderr;
    ok(@err > 0, 'got remote error stream');
    ok("@err" =~ /Mind/, 'got expected remote error') or diag @err;
    ok($pid->{status} == 7 * 256, 'got remote status [7]')
        or diag $pid->{status};

    $pid = fork {
        cmd => [ $^X, $xcmd, "-e=squeamish", "-w=ossifrage", "-x=13" ],
        remote => $full_remote2,
        child_fh => "socket,out,err",
    };
    ok($pid, "fork with array rhost $pid->{remote}{host}");
    ok($pid == wait, 'wait on remote cmd ' . __LINE__);
    @out = $pid->read_stdout;
    ok(@out > 0, 'got remote output');
    ok("@out" =~ /squeamish/, 'got expected remote output')  or diag @out;
    @err = $pid->read_stderr;
    ok(@err > 0, 'got remote error stream')                  or diag @err;
    ok("@err" =~ /ossifrage/, 'got expected remote error');
    ok($pid->{status} == 13 * 256, 'got remote status [13]');

    # with  stdin

    $pid = fork {
        cmd => [ $^X, $xcmd, "-y=4" ],
        remote => $full_remote,
        stdin => "foo\n",
        child_fh => "pipe,join",
    };
    ok($pid, "fork with rhost/stdin $pid->{remote}{host}");
    ok($pid == wait, 'wait on remote cmd ' . __LINE__);
    @out = $pid->read_stdout;
    ok(@out > 4, 'got remote output');
    ok("@out" =~ /(foo.*){5}/s,
       'got expected remote output')  or diag "OUT:@out";
    @err = $pid->read_stderr;
    ok(@err == 0,
       'no error stream with join, after out read') or diag "ERR:@err";
    ok($pid->{status} == 0, 'got remote status');

    # monitor and kill a long running process
    $pid = fork {
        cmd => [ $^X, $xcmd, "-e=One", "-n", "-s=1", "-e=Two", "-n",
                             "-s=25", "-e=Three", "-n" ],
        remote => $full_remote2,
        child_fh => "socket,out",
    };
    ok($pid, "fork long running remote cmd $pid->{remote}{host}");
    sleep 8;
    ok($pid->is_active, "remote cmd is active after 20s")
        or diag "state is ",$pid->{state};
    Forks::Super::kill('INT', $pid);
    ok($pid == waitpid($pid,0,5), "remote cmd reaped");
    ok(!$pid->is_active, "remote cmd terminated");
    @out = $pid->read_stdout;
    diag "Output is @out";
    ok("@out" =~ /One/ && "@out" =~ /Two/,
       'intermediate output received from remote cmd');
    ok("@out" !~ /Three/, 'incomplete output recevied from remote cmd');
    @err = $pid->read_stderr;
    diag "Error is @err";
}

__END__

external-command.pl covers input, output, error, exit codes, delays.
What else do we need to test?

_X_ throttling
_X_ wait, waitpid
_b_ timeouts
___ sockets & pipes
___ queueing
_X_ kill
___ suspend
___ lazy (bg_qx)
___ callbacks


