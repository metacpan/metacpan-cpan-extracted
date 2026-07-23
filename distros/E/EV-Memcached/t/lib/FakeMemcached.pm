package FakeMemcached;
use strict;
use warnings;
use IO::Socket::UNIX;
use File::Temp ();

# Scripted fake binary-protocol memcached on a unix socket, so tests can
# exercise server behavior without a real memcached.
#
#   my $srv = FakeMemcached->new(script => sub {
#       my $listen = shift;
#       my $c = FakeMemcached->accept($listen);
#       my $req = $c->read_request;           # [opcode, opaque, body, key_len, extras_len]
#       $c->respond(op => $req->[0], opaque => $req->[1]);
#       $c->respond_hit(opaque => $req->[1], value => 'V');
#   });
#   $mc = EV::Memcached->new(path => $srv->path, ...);
#   ...
#   $srv->finish;   # kill child, unlink socket
#
# The script coderef runs in the forked child. The listen socket is created
# before forking, so ->path is connectable as soon as new() returns.

sub new {
    my ($class, %arg) = @_;
    my $script = $arg{script} or die "FakeMemcached: script required";
    my ($path, $dir) = ($arg{path});
    if (!defined $path) {
        # no CLEANUP: its END hook would also fire in the forked child
        # and remove the dir while the parent still uses it
        $dir = File::Temp::tempdir('evmc-XXXXXX', TMPDIR => 1);
        $path = "$dir/mc.sock";
        die "FakeMemcached: socket path too long for sun_path: $path"
            if length($path) > 100;
    }
    unlink $path;
    my $listen = IO::Socket::UNIX->new(Local => $path, Listen => 5, Type => SOCK_STREAM)
        or die "FakeMemcached: listen $path: $!";
    my $pid = fork // die "FakeMemcached: fork: $!";
    if (!$pid) {
        $script->($listen);
        $listen->close;
        exit 0;
    }
    $listen->close;
    return bless { path => $path, dir => $dir, pid => $pid }, $class;
}

sub path { $_[0]{path} }

sub accept {
    my ($class, $listen) = @_;
    my $sock = $listen->accept or die "FakeMemcached: accept: $!";
    return FakeMemcached::Conn->new($sock);
}

sub finish {
    my ($self) = @_;
    if (my $pid = delete $self->{pid}) {
        kill 'KILL', $pid;
        waitpid $pid, 0;
    }
    if (my $path = delete $self->{path}) {
        unlink $path;
    }
    if (my $dir = delete $self->{dir}) {
        rmdir $dir;
    }
}

sub DESTROY { shift->finish }

package FakeMemcached::Conn;
use strict;
use warnings;

sub new {
    my ($class, $sock) = @_;
    return bless { sock => $sock }, $class;
}

sub sock { $_[0]{sock} }

sub _read_n {
    my ($self, $len) = @_;
    my $buf = '';
    while (length($buf) < $len) {
        my $n = sysread($self->{sock}, $buf, $len - length($buf), length($buf));
        return undef unless defined $n && $n > 0;
    }
    return $buf;
}

# Returns [opcode, opaque, body, key_len, extras_len, cas] or undef on EOF.
sub read_request {
    my ($self) = @_;
    my $hdr = $self->_read_n(24) // return undef;
    my ($magic, $op, $klen, $xlen, undef, undef, $blen, $opaque, $cas_hi, $cas_lo)
        = unpack 'C C n C C n N N N N', $hdr;
    die sprintf "FakeMemcached: bad request magic 0x%02x", $magic
        unless $magic == 0x80;
    my $body = $blen ? $self->_read_n($blen) : '';
    return undef unless defined $body;
    return [$op, $opaque, $body, $klen, $xlen, ($cas_hi << 32) | $cas_lo];
}

# Generic response. %r: op, opaque, status (0), key (''), value (''),
# extras (''), cas (0).
sub respond {
    my ($self, %r) = @_;
    my $extras = $r{extras} // '';
    my $key    = $r{key}    // '';
    my $value  = $r{value}  // '';
    my $cas    = $r{cas}    // 0;
    my $body   = $extras . $key . $value;
    my $pkt = pack('C C n C C n N N N N',
        0x81, $r{op}, length($key), length($extras), 0, $r{status} // 0,
        length($body), $r{opaque}, ($cas >> 32) & 0xFFFFFFFF, $cas & 0xFFFFFFFF)
        . $body;
    my $off = 0;
    while ($off < length $pkt) {
        my $n = syswrite($self->{sock}, $pkt, length($pkt) - $off, $off);
        die "FakeMemcached: write: $!" unless defined $n;
        $off += $n;
    }
}

# GET-family hit: 4-byte flags extras + value.
sub respond_hit {
    my ($self, %r) = @_;
    $r{extras} = pack('N', $r{flags} // 0);
    $r{status} = 0;
    $self->respond(%r);
}

1;
