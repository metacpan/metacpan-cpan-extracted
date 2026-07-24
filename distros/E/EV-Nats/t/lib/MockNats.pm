package MockNats;
# Forked fake nats-server for the test suite. Listens on an ephemeral
# 127.0.0.1 port; the child speaks just enough protocol (INFO / CONNECT /
# PING / PONG handshake) for the real client to come up, then each test
# scripts the rest via on_accept. No nats-server binary required, and the
# ephemeral port cannot collide with a real server on 4222.
#
#   my $mock = MockNats->new(on_accept => sub {
#       my ($conn, $report) = @_;        # runs in the forked child
#       MockNats->handshake($conn) or return;
#       ...script the conversation...
#       print $report "verdict\n";       # optional, parent reads it back
#   })->start;
#   my $nats = EV::Nats->new(host => '127.0.0.1', port => $mock->port, ...);
#   ...EV::run...
#   is $mock->report(5), 'verdict', '...';
#   $mock->stop;                         # TERM, then KILL; always reaps
#
# The child never returns to Test::More code: its STDOUT/STDERR go to
# /dev/null and it leaves via POSIX::_exit, so no END block can corrupt TAP.
#
# These tests drive the parser, handshake and object-lifetime paths that a
# real nats-server cannot reach, so they are also the memory-safety net.
# To run them under AddressSanitizer:
#
#   mkdir /tmp/asan && git ls-files -z | xargs -0 -I{} cp --parents {} /tmp/asan/
#   cd /tmp/asan && perl Makefile.PL \
#       OPTIMIZE='-g -O0 -fsanitize=address -fno-omit-frame-pointer' \
#       LDDLFLAGS='-shared -fsanitize=address' && make
#   ASAN_OPTIONS=detect_leaks=0 LD_PRELOAD=$(cc -print-file-name=libasan.so) \
#       prove -b t/
use strict;
use warnings;
use IO::Socket::INET;
use JSON::PP ();
use POSIX ();

sub new {
    my ($class, %opt) = @_;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 5,
        ReuseAddr => 1,
        Proto     => 'tcp',
    ) or die "MockNats: listen on 127.0.0.1: $!";
    return bless {
        srv       => $srv,
        port      => $srv->sockport,
        on_accept => $opt{on_accept},   # sub { my ($conn, $report_fh) = @_ }
        run       => $opt{run},         # sub { my ($listen, $report_fh) = @_ }
        pid       => undef,
        rd        => undef,
    }, $class;
}

sub port { $_[0]{port} }

# ---- child-side conversation helpers (class methods) ----

# Send the INFO line. $info is a raw JSON string or a hashref; the default
# is a plain 1 MiB max_payload server.
sub send_info {
    my ($class, $conn, $info) = @_;
    $info = { server_id => 'fake', version => '2.10.0', max_payload => 1048576 }
        unless defined $info;
    my $json = ref $info ? JSON::PP::encode_json($info) : $info;
    syswrite($conn, "INFO $json\r\n");
}

# Accumulate until $re matches, EOF, or the timeout (default 5s) lapses.
# Returns the buffer, or undef if the pattern never matched.
sub read_until {
    my ($class, $conn, $re, $timeout) = @_;
    my $buf = '';
    my $deadline = time + ($timeout // 5);
    while (time < $deadline) {
        return $buf if $buf =~ $re;
        my $rin = '';
        vec($rin, fileno($conn), 1) = 1;
        my $ready = select(my $rout = $rin, undef, undef, 0.2);
        next unless $ready;
        my $n = sysread($conn, my $chunk, 65536);
        return unless $n;
        $buf .= $chunk;
    }
    return $buf =~ $re ? $buf : undef;
}

# INFO -> read CONNECT+PING -> PONG. Returns the handshake buffer.
sub handshake {
    my ($class, $conn, $info) = @_;
    $class->send_info($conn, $info);
    my $buf = $class->read_until($conn, qr/PING\r\n/, 5)
        or return;
    syswrite($conn, "PONG\r\n");
    return $buf;
}

# ---- parent-side lifecycle ----

sub start {
    my ($self) = @_;
    die "MockNats: need on_accept or run"
        unless $self->{on_accept} || $self->{run};
    pipe(my $rd, my $wr) or die "MockNats: pipe: $!";
    my $pid = fork();
    die "MockNats: fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        $wr->autoflush(1);       # POSIX::_exit skips stdio flush
        $SIG{PIPE} = 'IGNORE';   # client may vanish mid-script
        my $ok = eval {
            if (my $run = $self->{run}) {
                $run->($self->{srv}, $wr);
            } else {
                my $conn = $self->{srv}->accept or die "accept: $!";
                $conn->autoflush(1);
                $self->{on_accept}->($conn, $wr);
            }
            1;
        };
        POSIX::_exit($ok ? 0 : 1);
    }
    close $wr;
    $self->{pid} = $pid;
    $self->{rd}  = $rd;
    return $self;
}

# Next report line from the child ('' if it exited without one). Bounded
# by $timeout (default 10s) and by the pipe closing at child exit.
sub report {
    my ($self, $timeout) = @_;
    my $rd = $self->{rd} or return '';
    my $line = '';
    my $deadline = time + ($timeout // 10);
    while (time < $deadline && $line !~ /\n/) {
        my $rin = '';
        vec($rin, fileno($rd), 1) = 1;
        my $ready = select(my $rout = $rin, undef, undef, 0.2);
        next unless $ready;
        my $n = sysread($rd, my $chunk, 4096);
        last unless $n;
        $line .= $chunk;
    }
    chomp $line;
    return $line;
}

# TERM with a bounded wait, KILL as a backstop; the child is always reaped.
sub stop {
    my ($self) = @_;
    if (my $pid = delete $self->{pid}) {
        kill 'TERM', $pid;
        my $reaped = 0;
        my $deadline = time + 5;
        while (time < $deadline) {
            my $r = waitpid $pid, POSIX::WNOHANG();
            if ($r == $pid) { $reaped = 1; last }
            select undef, undef, undef, 0.05;
        }
        if (!$reaped) {
            kill 'KILL', $pid;
            waitpid $pid, 0;
        }
    }
    close $self->{rd}  if $self->{rd};
    close $self->{srv} if $self->{srv};
    return;
}

sub DESTROY { $_[0]->stop }

1;
