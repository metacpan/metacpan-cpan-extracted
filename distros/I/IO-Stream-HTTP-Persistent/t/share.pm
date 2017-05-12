use Test::More;

use Carp;
use Scalar::Util qw( weaken );
use File::Temp qw( tempfile );
use Errno qw( EAGAIN );
use Socket;
use Fcntl;
use POSIX qw(locale_h);
setlocale(LC_ALL, 'C');

use EV;
use IO::Stream;
use IO::Stream::HTTP::Persistent;

use Carp::Heavy;
$SIG{PIPE}  = 'IGNORE';
$EV::DIED   = sub { diag $@; EV::unloop };

use constant WIN32   => IO::Stream::WIN32;


### Usage example:
#@CheckPoint = (
#    [ 'listener',   ACCEPTED        ], 'accept incoming connection',
#    [ 'ssl_client', IN              ], 'client: got server banner',
#    [ 'ssl_client', $banner         ], 'client: banner is correct',
#    [ 'ssl_client', SENT            ], 'client: request sent',
#    [ 'ssl_server', EOF             ], 'server: got eof',
#    [ 'ssl_server', $msg            ], 'server: requst is correct',
#    {
#	win32 => [
#	    [ 'ssl_client', EOF             ], 'client: got eof',
#	    [ 'ssl_server', SENT            ], 'server: reply sent',
#	],
#	other => [
#	    [ 'ssl_server', SENT            ], 'server: reply sent',
#	    [ 'ssl_client', EOF             ], 'client: got eof',
#	],
#    },
#    [ 'ssl_client', "echo: $msg"    ], 'client: reply is correct',
#);
#plan tests => checkpoint_count();
#
# NOTE	Alternatives in @CheckPoint must have same amount of tests!
use vars qw( @CheckPoint );
sub _checkpoint_unwrap {
    return @_ if !grep {ref eq 'HASH'} @_;
    return _checkpoint_unwrap(map{ref eq 'HASH' ? @{(values %$_)[0]} : $_}@_);
}
sub checkpoint_count {
    return _checkpoint_unwrap(@CheckPoint)/2;
}
sub checkpoint {
    my ($func) = (caller(1))[3]=~/.*::(.*)/;
    if (ref $CheckPoint[0] eq 'HASH') {
	my %alt = %{ $CheckPoint[0] };
	for my $key (keys %alt) {
	    if (eq_array([$func, @_], $alt{$key}[0])) {
		diag "Alternative match: $key";
		shift @CheckPoint;
		unshift @CheckPoint, @{ $alt{$key} };
		last;
	    }
	}
    }
    if (ref $CheckPoint[0] eq 'HASH') {
	croak("No alternative to match: $func @_");
    }
    is_deeply([$func, @_], shift @CheckPoint, shift @CheckPoint);
    return;
}

### Usage example:
#sub client {
#    my ($io, $e, $err) = @_;
#  &diag_event;
#}
sub diag_event {
    my ($io, $e, $err) = @_;
    my ($func) = (caller(1))[3]=~/.*::(.*)/;
    diag "$func : ".events2str($e, $err);
}

sub events2str {
    my ($e, $err) = @_;
    my @e = ($e & RESOLVED, $e & CONNECTED, $e & IN, $e & OUT, $e & EOF, $e & SENT, $e & HTTP_SENT, $e & HTTP_RECV, $e & ~(RESOLVED|CONNECTED|IN|OUT|EOF|SENT|HTTP_SENT|HTTP_RECV));
    my @n = qw(RESOLVED CONNECTED IN OUT EOF SENT HTTP_SENT HTTP_RECV unk);
    my $s = join q{|}, map {$e[$_] ? $n[$_] : ()} 0 .. $#e;
    return $err ? "$s err=$err" : $s;
}

sub nonblocking {
    my ($fh) = @_;
    if (WIN32) {
        my $nb=1; ioctl $fh, 0x8004667e, \$nb; # FIONBIO
    } else {
        fcntl $fh, F_SETFL, O_NONBLOCK                or croak qq{fcntl: $!};
    }
    return;
}

sub tcp_server {
    my ($host, $port) = @_;
    socket my $sock, AF_INET, SOCK_STREAM, 0        or croak qq{socket: $!};
    setsockopt $sock, SOL_SOCKET, SO_REUSEADDR, 1   or croak qq{setsockopt: $!};
    bind $sock, sockaddr_in($port, inet_aton($host))or croak qq{bind: $!};
    listen $sock, SOMAXCONN                         or croak qq{listen: $!};
    nonblocking($sock);
    return $sock;
}

sub tcp_client {
    my ($host, $port) = @_;
    socket my $sock, AF_INET, SOCK_STREAM, 0        or croak qq{socket: $!};
    nonblocking($sock);
    connect $sock, sockaddr_in($port, inet_aton($host));
    return $sock;
}

sub start_server {
    my ($request, $response) = @_;
    my $srv_sock = tcp_server('127.0.0.1', 0);
    my ($port) = sockaddr_in(getsockname($srv_sock));
    my $srv_w = EV::io($srv_sock, EV::READ, sub {
        if (accept my $sock, $srv_sock) {
            IO::Stream->new({
                fh          => $sock,
                cb          => sub { server(@_, $request, $response) },
                wait_for    => IN|EOF,
                in_buf_limit=> 1024,
            });
        }
        elsif ($! != EAGAIN) {
            die "accept: $!\n";
        }
    });
    return ($srv_w, $port);
}

sub server {
    my ($io, $e, $err, $request, $response) = @_;
    if ($err) {
        die $err;
    }
    if ($e & IN) {
        while ($io->{in_buf} =~ s/\A\Q$request\E//ms) {
            if ($request !~ m{\A[^\n]* HTTP/1[.]1\r?\n}ms && $request !~ m{^Connection:\s*Keep-Alive\n}ms) {
                $io->{wait_for} = SENT;
            }
            $io->{out_buf} .= $response;
        }
        $io->write();
    }
    if ($e & EOF || $e & SENT) {
        $io->close;
    }
}

1;
