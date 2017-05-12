use strict;
use warnings;

# common setup for Forks::Super remote tests (t/49*.t)
#
# we must connect to a server (which may be the current host) through ssh
# and run some remote test commands
#
# options are, in order of preference:
#
#    1. $ENV{TEST_SSH_TARGET} = <uri>
#       URI to specify a server in an environment variable. Expects to use
#       passwordless, pubic key authentication, and expects to find the same
#       filesystem on the remote host that exists on the local host to build
#       this module.  t/forked_harness.pl , which is run if you 
#       'make fasttest', may set this variable.
#
#    2. Test::SSH module
#       constructs a local, temporary ssh server for the tests.
#       May require Net::OpenSSH
#
#    3. $ENV{TEST_SSH} = user@hostname
#       $ENV{TEST_SSH} = user:password@hostname
#       $ENV{TEST_SSH} = 1
#       Try to connect to host with user specified in environment variable.
#       When the variable value is '1', treat it as $ENV{USER} @ $ENV{HOSTNAME}
#
#    4. if local machines is running sshd and user has an .ssh dir,
#       try to connect to local server with default publickey credentials
#

Forks::Super::POSTFORK_CHILD {
    # RT#117025 for Test::SSH workaround. Otherwise, the server
    # closes at the end of each child process.
    *Test::SSH::Backend::OpenSSH::_run_dir = sub { };
};

if ($ENV{CRIPPLE_TEST_SSH}) {
    $Forks::Super::Config::CONFIG{"Test::SSH"} = 0;
    $Forks::Super::Config::CONFIG{"Net::OpenSSH"} = 0;
}


# returns an object (Test::SSH or a mock) that
# describes an ssh server that our tests can access.
sub get_test_sshd {

    print STDERR "Identifying ssh connection\n";

    if ($ENV{TEST_SSH_TARGET}) {
        if (eval "use URI; 1") {
            my $uri = URI->new($ENV{TEST_SSH_TARGET});
            my $sshd = { host => $uri->host, uri => "$uri" };
            $sshd->{port} = $uri->port if $uri->port;
            if ($uri->password) {
                $sshd->{password} = $uri->password;
                $sshd->{auth_method} = 'password';
            } else {
                $sshd->{auth_method} = 'publickey';
            }

            my @u = split /;/, $uri->user;
            $sshd->{user} = shift @u;
            foreach my $u (@u) {
                my ($k,$v) = split /=/, $u, 2;
                $sshd->{$k} = $v;
            }
            bless $sshd, 'Mock::Test::SSH';
            return $sshd;
        }
        return;
    }

    if (Forks::Super::Config::CONFIG_module('Test::SSH')) {
        my %opts = (
            logger => sub { warn "Test::SSH > @_\n" if "@_"=~/connection uri/; }
            );
        my $sshd = eval 'use Test::SSH; Test::SSH->new(%opts);';
        if ($sshd) {
            print STDERR " ... Test::SSH available\n";
            return $sshd;
        }
    }
    print STDERR " ... Test::SSH not available\n";
    if ($ENV{NO_SSHD}) {
        print STDERR " ... requested not to look for local ssh server\n";
        return;
    }

    my $sshd = {
        host => $ENV{HOSTNAME},
        user => $ENV{USER},
        password => '',
        auth_method => 'publickey',
    };
    bless $sshd, 'Mock::Test::SSH';
    if (!$sshd->{host}) {
        chomp($sshd->{host} = `hostname`);
    }

    if ($ENV{TEST_SSH}) {
        if ($ENV{TEST_SSH} eq '1') {
            $ENV{TEST_SSH} = join '@', $ENV{USER}, $ENV{HOSTNAME};
        }
        $Forks::Super::Config::CONFIG{"Net::OpenSSH"} = 0;
        my @uph = split /\@/, $ENV{TEST_SSH};
        $sshd->{host} = pop @uph;
        my $user = join '@', @uph;
        if ($user =~ /:/) {
            my @up = split /:/, $user;
            $sshd->{password} = pop @up;
            $sshd->{auth_method} = 'password';
            $user = join ':', @up;
        }
        $sshd->{user} = $user;
        print STDERR "... extracted credentials from ENV{TEST_SSH}\n";
    } else {
        # try passwordless authentication on current host. Only proceed
        # if we can detect a local ssh server
        my @ps = grep /\bsshd\b/, `ps -ef`;
        if (@ps == 0) {
            print STDERR "... no sshd found in process table\n";
            return;
        }
    }

    # if publickey authentication is requested, only proceed if we
    # can determine identity and set key_path
    if ($sshd->{auth_method} eq 'publickey') {
        my $sshdir = $ENV{HOME} . "/.ssh";
        if (! -d $sshdir) {
            print STDERR " ... no user .ssh dir found\n";
            return;
        }
        my (@cfg,@syscfg);
        if (-f "$sshdir/config") {
            open my $fh, '<', "$sshdir/config";
            @cfg = <$fh>;
            close $fh;
        }
        if (-f "/etc/ssh/ssh_config") {
            open my $fh, '<', "/etc/ssh/ssh_config";
            @syscfg = <$fh>;
            close $fh;
        }
        my @id = grep /IdentityFile/, @cfg;
        if (!@id) {
            @id = grep /IdentityFile/, @syscfg;
        }
        if (!@id) {
            print STDERR " ... no identity files for publickey auth found\n";
        }
        s/^\s*IdentityFile\s*//, s/\s+$//, s/~\/.ssh/$sshdir/ for @id;
        @id = grep { -f $_ } @id;
        if (@id) {
            $sshd->{key_path} = [ @id ];
        } else {
            print STDERR " ... identity files for publickey auth not found\n";
        }
    }

    # try a test command.
    my $host = $sshd->{host};
    my $job = { cmd => ["true"] };
    my $test_cmd = Forks::Super::Job::__build_ssh_command($host, $sshd, $job);
    print STDERR " ... test command is  '$test_cmd'\n";

    my $c1 = system($test_cmd);
    if ($c1) {
        print STDERR " ... test command failed: rc=$c1\n";
        return;
    }
    print STDERR
        " ... test command ok. We have a valid ssh server for testing\n";
    return $sshd;
}

sub Mock::Test::SSH::AUTOLOAD {
    my $self = shift;
    my $key = $Mock::Test::SSH::AUTOLOAD;
    $key =~ s/.*:://;
    return if $key eq 'DESTROY';
    return $self->{$key};
}

1;

