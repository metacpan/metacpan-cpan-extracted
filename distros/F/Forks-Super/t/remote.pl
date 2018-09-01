use strict;
use warnings;

# common setup for Forks::Super remote tests (t/49*.t)
#
# we must connect to a server (which may be the current host) through ssh
# and run some remote test commands
#
# this script used to be complicated, seeing if various modules were
# available and environment variables were set and how to make use
# of them. Now all we will do is see if we can easily make a basic,
# passwordless ssh connection to the current host, and if we can't,
# we will punt.
#

use Forks::Super::SysInfo;

if ($INC{"Test/SSH.pm"}) {
    Forks::Super::POSTFORK_CHILD {
        # RT#117025 for Test::SSH workaround. Otherwise, the server
        # closes at the end of each child process.
        *Test::SSH::Backend::OpenSSH::_run_dir = sub { };
    };
}

if ($ENV{CRIPPLE_TEST_SSH}) {
    $Forks::Super::Config::CONFIG{"Test::SSH"} = 0;
    $Forks::Super::Config::CONFIG{"Net::OpenSSH"} = 0;
}

# returns an object (Test::SSH or a mock) that
# describes an ssh server that our tests can access.
sub get_test_sshd {

    print STDERR "Identifying ssh connection\n";

    my $template = $Forks::Super::SysInfo::TEST_SSH_TEMPLATE;
    return if !$template;

    my $sshd = bless {}, 'Mock::Test::SSH';

    my $env_host = $ENV{HOSTNAME};
    chomp(my $hostname = qx(hostname));
    my $ip = eval "use Sys::HostAddr;1" ? Sys::HostAddr->new->main_ip : "";
    my $env_user = $ENV{USER};

    if ($template =~ /\$ENV_HOST/) {
        $sshd->{host} = $env_host || $hostname || $ip || "localhost";
    } elsif ($template =~ /\$ip/) {
        $sshd->{host} = $ip || $env_host || $hostname || "localhost";
    } elsif ($template =~ /\$hostname/) {
        $sshd->{host} = $hostname || $env_host || $ip || "localhost";
    } elsif ($template =~ /localhost/) {
        $sshd->{host} = "localhost";
    } else {
        warn "No hostname specification in ",
             "\$Forks::Super::SysInfo::TEST_SSH_TEMPLATE";
        return;
    }
    $sshd->{port} = 22;

    if ($template =~ /\$ENV_USER/) {
        $sshd->{user} = $env_user;  # || some other way to get userid
    }
    $sshd->{auth_method} = "publickey";
    bless $sshd, 'Mock::Test::SSH';
    if ($sshd->test("echo foo", "foo", 0)) {
        return $sshd;
    }
    return;
}

sub Mock::Test::SSH::AUTOLOAD {
    my $self = shift;
    my $key = $Mock::Test::SSH::AUTOLOAD;
    $key =~ s/.*:://;
    return if $key eq 'DESTROY';
    return $self->{$key};
}

sub Mock::Test::SSH::test {
    my ($sshd, $cmd, $xp_output, $xp_status) = @_;
    my $sshx = qx(which ssh) || "ssh";
    chomp($sshx);
    if (!$sshx || ! -x $sshx) {
        warn "could not find ssh executable for test";
        return;
    }
    my $sshcmd = "\"$sshx\"";
    if ($sshd->{user}) {
        $sshcmd .= " -l \"$sshd->{user}\"";
    }
    if ($sshd->{host}) {
        $sshcmd .= " \"$sshd->{host}\"";
    }
    $sshcmd .= " $cmd";
    if ($^O eq 'MSWin32') {
        $sshcmd .= " < nul 2> nul";
    } else {
        $sshcmd .= " < /dev/null 2> /dev/null";
    }
    my $ssh_output = qx($sshcmd);
    my $ssh_status = $?;
    chomp($ssh_output);

    if ($ssh_output ne $xp_output) {
        warn "test output '$ssh_output' did not match expected output ",
             "'$xp_output'";
        return;
    }
    if ($ssh_status != $xp_status) {
        warn "test status '$ssh_status' did not match expected status ",
             "'$xp_status'";
        return;
    }
    return 1;
}

1;
