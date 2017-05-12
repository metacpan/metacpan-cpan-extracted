use Test::More;
use Test::Exception;
use Test::Differences;

use Carp;
use Scalar::Util qw( weaken );
use File::Temp qw( tempfile );
use Errno qw( EAGAIN EBADF EPIPE ECONNABORTED );
use Socket;
use Fcntl;
use POSIX qw(locale_h); BEGIN { setlocale(LC_ALL,'en_US.UTF-8') } # avoid UTF-8 in $!

use EV;
use IO::Stream;
use IO::Stream::MatrixSSL;

# Crypt::MatrixSSL3::Open();
# END { Crypt::MatrixSSL3::Close() }

use Carp::Heavy;
$SIG{PIPE}  = 'IGNORE';
$EV::DIED   = sub { diag $@; EV::unloop };

use constant WIN32   => IO::Stream::WIN32;
use constant BUFSIZE => IO::Stream::BUFSIZE;


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
    eq_or_diff([$func, @_], shift @CheckPoint, shift @CheckPoint);
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
    my @e = ($e & RESOLVED, $e & CONNECTED, $e & IN, $e & OUT, $e & EOF, $e & SENT, $e & ~(RESOLVED|CONNECTED|IN|OUT|EOF|SENT));
    my @n = qw(RESOLVED CONNECTED IN OUT EOF SENT unk);
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

sub sockport {
    my ($sock) = @_;
    my ($port) = sockaddr_in(getsockname $sock);
    return $port;
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

sub unix_server {
    my ($path) = @_;
    socket my $sock, AF_UNIX, SOCK_STREAM, 0        or croak qq{socket: $!};
    unlink $path;
    bind $sock, sockaddr_un($path)                  or croak qq{bind: $!};
    listen $sock, SOMAXCONN                         or croak qq{listen: $!};
    nonblocking($sock);
    return $sock;
}

sub unix_client {
    my ($path) = @_;
    socket my $sock, AF_UNIX, SOCK_STREAM, 0        or croak qq{socket: $!};
    nonblocking($sock);
    connect $sock, sockaddr_un($path);
    return $sock;
}

1;
