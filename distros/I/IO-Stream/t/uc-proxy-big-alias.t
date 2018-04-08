# Use case: client connect to tr/x/y/ server and send/recv a lot of data.
# Use case: client connect to tr/x/y/ server using tr/y/z/ proxy and
#           send/recv a lot of data, using Data::Alias to avoid needless
#           data copying in proxy.
use warnings;
use strict;
use lib 't';
use share;
BEGIN {
    eval { require Data::Alias; Data::Alias->VERSION('0.08'); Data::Alias->import(); 1 } or plan skip_all => 'Data::Alias required';
}

my $SIZE = 204800;

use constant ACCEPTED => 123;
@CheckPoint = (
    # first test: client connect to server without proxy
    ['listener_server', ACCEPTED    ],  'server: new client',
  ((
    ['server',          IN          ],  'server: IN',
    ['server',          ('x' x BUFSIZE) ],  '  received "xxx..."',
  ) x ($SIZE/BUFSIZE)),
    ['server',          SENT        ],  'server: SENT',
    ['client',          EOF         ],  'client: EOF',
    ['client',          ('y' x $SIZE)   ],  '  received "yyyyyyyyy..."',
    # second test: client connect to server using proxy
    ['listener_proxy',  ACCEPTED    ],  'proxy: new client',
    { 
	win32_somefreebsd => [
	    ['listener_server', ACCEPTED    ],  'server: new client',
	    ['proxy2server',    CONNECTED   ],  'proxy2server: CONNECTED',
	],
	other => [
	    ['proxy2server',    CONNECTED   ],  'proxy2server: CONNECTED',
	    ['listener_server', ACCEPTED    ],  'server: new client',
	],
    },
  ((
    ['server',          IN          ],  'server: IN',
    ['server',          ('x' x BUFSIZE) ],  '  received "xxx..."',
  ) x ($SIZE/BUFSIZE)),
    ['server',          SENT        ],  'server: SENT',
    ['proxy2server',    EOF         ],  'proxy2server: EOF',
    ['client2',         EOF         ],  'client2: EOF',
    ['client2',         ('z' x $SIZE)   ],  '  received "zzzzzzzzz..."',
);
plan tests => 
    2               # {is_eof} tests in client() and client2()
  + checkpoint_count();


my $srv_sock = tcp_server('127.0.0.1', 0);
my $srv_w = EV::io($srv_sock, EV::READ, \&listener_server);

my $prx_sock = tcp_server('127.0.0.1', 0);
my $prx_w = EV::io($prx_sock, EV::READ, \&listener_proxy);

sub new_client {
    my ($port, $cb) = @_;
    IO::Stream->new({
        host        => '127.0.0.1',
        port        => $port,
        cb          => $cb,
        wait_for    => EOF,
        out_buf     => ('x' x $SIZE),
        in_buf_limit=> 0,
    });
}
new_client(sockport($srv_sock), \&client);

EV::loop;


sub listener_server {
    if (accept my $sock, $srv_sock) {
        checkpoint(ACCEPTED);
        IO::Stream->new({
            fh          => $sock,
            cb          => \&server,
            wait_for    => IN,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
}

sub server {
    my ($io, $e, $err) = @_;
    die "server error: $err\n" if $err;
    checkpoint($e);
    if ($e & IN) {
        checkpoint($io->{in_buf});
        if ($io->{in_bytes} == $SIZE) {
            $io->{wait_for} = SENT;
        }
        $io->write('y' x length $io->{in_buf});
        $io->{in_buf} = q{};
    }
    if ($e & SENT) {
        $io->close();
    }
}

sub listener_proxy {
    if (accept my $sock, $prx_sock) {
        checkpoint(ACCEPTED);
        IO::Stream->new({
            host        => '127.0.0.1',
            port        => sockport($srv_sock),
            cb          => \&proxy2server,
            wait_for    => CONNECTED|IN|EOF,
            Client      => undef,
            ClientSock  => $sock,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
}

sub proxy2server {
    my ($io, $e, $err) = @_;
    die "proxy2server error: $err\n" if $err;
    checkpoint($e)
        if $e != IN && $e != SENT;
    if ($e & CONNECTED) {
        $io->{Client} = IO::Stream->new({
            fh          => $io->{ClientSock},
            cb          => \&proxy2client,
            wait_for    => IN,
            out_pos     => 0,
            Server      => $io,
        });
        weaken($io->{Client}->{Server});
        weaken($io->{Client});
        alias $io->{Client}->{out_buf} = $io->{in_buf};
        alias $io->{out_buf} = $io->{Client}->{in_buf};
    }
    if ($e & SENT) {
        shutdown $io->{fh}, 1;
    }
    if ($e & IN) {
        $io->{in_buf} =~ s/y/z/g;
        if ($io->{in_bytes} == $SIZE) {
            $io->{Client}->{wait_for} |= SENT;
        }
        $io->{Client}->write();
    }
    if ($e & EOF) {
        $io->close();
    }
}

sub proxy2client {
    my ($io, $e, $err) = @_;
    die "proxy2client error: $err\n" if $err;
    checkpoint($e)
        if $e != IN && $e != SENT;
    if ($e & IN) {
        if ($io->{in_bytes} == $SIZE) {
            $io->{Server}->{wait_for} |= SENT;
        }
        $io->{Server}->write();
    }
    if ($e & SENT) {
        $io->close();
    }
}

sub client {
    my ($io, $e, $err) = @_;
    die "client error: $err\n" if $err;
    checkpoint($e);
    checkpoint($io->{in_buf});
    ok($io->{is_eof}, '  {is_eof} set');
    $io->close();
    new_client(sockport($prx_sock), \&client2);
}

sub client2 {
    my ($io, $e, $err) = @_;
    die "client2 error: $err\n" if $err;
    checkpoint($e);
    checkpoint($io->{in_buf});
    ok($io->{is_eof}, '  {is_eof} set');
    $io->close();
    EV::unloop;
}

