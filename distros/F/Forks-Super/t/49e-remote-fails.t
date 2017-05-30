use Forks::Super ':test';
use Test::More;
use strict;
use warnings;

my $ntests = 20;
plan tests => $ntests;

# !!! - the remote feature is difficult to test. Don't sweat it too much
#       if the t/49*.t tests are the only ones that fail.

# test bad usages of  remote  feature

SKIP: {
    if (!Forks::Super::Config::CONFIG_module('Cwd')) {
        skip "sort of required Cwd", $ntests;
    }
    require "t/remote.pl";
    my $sshd = get_test_sshd();
    if (!$sshd) {
        ok(1, "no ssh server available, skipping all tests")
            for 1..$ntests;
        exit;
    }
    my $cwd = Cwd::cwd();
    ($cwd) = $cwd =~ /(.*)/;

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
        remote => { user => $sshd->user, port => $sshd->port },
        child_fh => "out,err",
    };
    ok(!$pid, "fork fails with remote no host specified");

    ### simple  remote => hostname

    $pid = fork {
        sub => sub { print STDOUT "Never"; print STDERR "Mind"; exit 7 },
        remote => $full_remote,
        child_fh => "out,err",
    };
    ok($pid, "fork with remote and sub runs on localhost");
    my $w = wait;
    ok($pid == $w, 'wait on remote cmd ' . __LINE__) or diag($pid,$w);
    my @out = $pid->read_stdout;
    ok(@out > 0, 'got remote output');
    ok("@out" =~ /Never/, 'got expected remote output')   or diag @out;
    my @err = $pid->read_stderr;
    ok(@err > 0, 'got remote error stream');
    ok("@err" =~ /Mind/, 'got expected remote error') or diag @err;
    ok($pid->{status} == 7 * 256, 'got remote status [7]')
        or diag $pid->{status};

    $pid = fork {
        cmd => [ $^X, $xcmd, "-e=squeamish", "-w=ossifrage", "-x=13" ],
        remote => $full_remote2,
        child_fh => "out,err",
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

    # bogus host

    $pid = fork {
        cmd => [ $^X, $xcmd, "-y=4" ],
        remote => { %$full_remote, host => "not-a-real-host" },
        stdin => "foo\n",
        child_fh => "in,join",
    };
    ok($pid, "fork with bogus remote host");
    ok($pid == wait, 'wait on remote cmd ' . __LINE__);
    @err = $pid->read_stderr;
    ok(@err != 0, 'no error stream with join, after out read');
    ok($pid->{status} != 0, 'got remote status non-zero on ssh error');

    # wrong protocol
    $pid = fork {
        cmd => [ $^X, $xcmd, "-e=One", "-n", "-s=1", "-e=Two", "-n",
                             "-s=25", "-e=Three", "-n" ],
        remote => { host => $sshd->host, proto => 'rsh' },
        child_fh => "out",
    };
    ok(!$pid, "fork remote proto=rsh not supported");
}

__END__

external-command.pl covers input, output, error, exit codes, delays.
What else do we need to test?

_X_ throttling
_X_ wait, waitpid
_b_ timeouts
_c_ sockets & pipes
___ queueing
_X_ kill
___ suspend
___ lazy (bg_qx)
___ callbacks


