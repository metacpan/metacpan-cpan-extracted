#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use IO::Socket::UNIX;
use Time::HiRes ();
use File::Temp ();
use POSIX ();
use Fcntl ();
use Hyperman;

# Unix-domain listeners and socket activation: a path listener serves with
# no peer address and the path as SERVER_NAME, honours mode, replaces a stale
# socket file and refuses a regular file; LISTEN_FDS hands pre-bound sockets
# to an exec'd server, which adopts them, binds nothing, and scrubs the
# variables so its workers do not see them.

plan skip_all => 'unix-domain sockets need a POSIX box' if $^O eq 'MSWin32';
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $sock = "$dir/s.sock";

my $app = sub {
    my $env = shift;
    [ 200, [ 'Content-Type' => 'text/plain' ],
      [ join '|', $env->{REMOTE_ADDR} // 'none', $env->{SERVER_NAME} // 'none',
                  $env->{SERVER_PORT} // 'none', $ENV{LISTEN_FDS} // 'unset' ] ];
};

sub get_unix {
    my ($path) = @_;
    my $s;
    for (1 .. 50) { $s = IO::Socket::UNIX->new(Peer => $path) and last; Time::HiRes::sleep(0.1) }
    return '' unless $s;
    $s->syswrite("GET / HTTP/1.0\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5;
           while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0 };
    close $s;
    return $buf =~ /\r\n\r\n(.*)\z/s ? $1 : '';
}
sub get_tcp {
    my ($port) = @_;
    my $s;
    for (1 .. 50) { $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") and last; Time::HiRes::sleep(0.1) }
    return '' unless $s;
    $s->syswrite("GET / HTTP/1.0\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5;
           while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0 };
    close $s;
    return $buf =~ /\r\n\r\n(.*)\z/s ? $1 : '';
}

# ---- a path listener --------------------------------------------------------
{
    open my $stale, '>', $sock; close $stale;        # a regular file, not a socket
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDERR, '>', "$dir/file.err"; open STDOUT, '>', '/dev/null';
        eval { Hyperman->run(app => $app, workers => 1, listen => [ { path => $sock } ]) };
        print STDERR "CROAK: $@" if $@;
        exit 3;
    }
    waitpid $pid, 0;
    is $? >> 8, 3, 'a regular file at the path is refused';
    open my $fh, '<', "$dir/file.err"; local $/; my $e = <$fh> // '';
    like $e, qr/bind \Q$sock\E:0: File exists/, '...with EEXIST naming the path';
    unlink $sock;
}
{
    # a stale SOCKET file is replaced
    my $old = IO::Socket::UNIX->new(Local => $sock, Listen => 1) or die "pre-bind: $!";
    close $old;
    ok -S $sock, 'a stale socket file is in the way';
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        Hyperman->run(app => $app, workers => 2, listen => [ { path => $sock, mode => 0600 } ]);
        exit 0;
    }
    is get_unix($sock), "none|$sock|0|unset",
        'served over the unix socket: no REMOTE_ADDR, SERVER_NAME is the path, SERVER_PORT 0';
    is sprintf('%04o', (stat $sock)[2] & 07777), '0600', 'mode 0600 applied to the socket file';
    kill 'TERM', $pid; waitpid $pid, 0;
}

# ---- socket activation ------------------------------------------------------
{
    my ($port) = free_ports(1);
    my $tcp = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $port,
                                    Proto => 'tcp', Listen => 5, ReuseAddr => 1) or die "bind tcp: $!";
    my $usock = "$dir/act.sock";
    my $un = IO::Socket::UNIX->new(Local => $usock, Listen => 5) or die "bind unix: $!";
    my $script = "$dir/server.pl";
    open my $sp, '>', $script or die $!;
    print $sp <<"PL";
use strict; use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Hyperman;
Hyperman->run(app => sub {
    my \$env = shift;
    [ 200, [], [ join '|', \$env->{SERVER_NAME} // 'none', \$env->{SERVER_PORT} // 'none',
                           \$ENV{LISTEN_FDS} // 'unset' ] ] },
    workers => 2, listen_fds => 1,
    listen => [ { host => '127.0.0.1', port => $port }, { path => '$usock' } ]);
PL
    close $sp;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        POSIX::dup2(fileno $tcp, 3) or die "dup2: $!";
        POSIX::dup2(fileno $un, 4)  or die "dup2: $!";
        # dup2 onto a descriptor perl already holds (its own sockets may BE 3
        # and 4) is a no-op that leaves perl's close-on-exec flag in place;
        # clear it, or the server inherits nothing
        my @keep;                       # the handles must outlive the exec: a
                                        # handle freed here would CLOSE the fd
        for my $n (3, 4) {
            open my $h, "<&=", $n or die "fdopen $n: $!";
            fcntl($h, Fcntl::F_SETFD(), 0) or die "fcntl: $!";
            push @keep, $h;
        }
        $ENV{LISTEN_FDS} = 2;
        $ENV{LISTEN_PID} = $$;
        open STDERR, '>', "$dir/act.err"; open STDOUT, '>', '/dev/null';
        exec $^X, $script or die "exec: $!";
    }
    # the test process keeps its own copies; the server must serve on the
    # inherited ones, which share the listen queue
    is get_tcp($port), "127.0.0.1|$port|unset",
        'the inherited TCP listener serves, and the worker sees no LISTEN_FDS';
    is get_unix($usock), "$usock|0|unset", 'the inherited unix listener serves too';
    kill 'TERM', $pid; waitpid $pid, 0;
    open my $fh, '<', "$dir/act.err"; local $/; my $e = <$fh> // '';
    diag "server stderr: $e" if $e =~ /\S/;
    unlike $e, qr/bind/, 'no bind error: the server bound nothing itself';
    close $tcp; close $un;
}
{
    # LISTEN_PID for another process: refused
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $ENV{LISTEN_FDS} = 1; $ENV{LISTEN_PID} = 1;
        open STDERR, '>', "$dir/pid.err"; open STDOUT, '>', '/dev/null';
        eval { Hyperman->run(app => $app, workers => 1, listen_fds => 1,
                             listen => [ { path => "$dir/x.sock" } ]) };
        print STDERR "CROAK: $@" if $@;
        exit 3;
    }
    waitpid $pid, 0;
    is $? >> 8, 3, 'sockets handed to another pid are refused';
    open my $fh, '<', "$dir/pid.err"; local $/; my $e = <$fh> // '';
    like $e, qr/LISTEN_PID is 1, this is \d+/, '...naming both pids';
}

done_testing;
