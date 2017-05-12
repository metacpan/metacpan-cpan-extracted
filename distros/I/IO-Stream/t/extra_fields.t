# Client push a lot of data to server, server got several EINBUFLIMIT
# errors, dynamically increase {in_buf_limit}, and finally receive all data.
# - EINBUFLIMIT
# - dynamic tuning of {in_buf_limit}
# - custom fields /^[A-Z]/
# - class/method names instead of CODE ref in {cb}
use warnings;
use strict;
use t::share;

my $SIZE = 204800;

plan tests =>
    1                               # accept client
  + 3*4                             # server got EINBUFLIMIT
  + 5                               # server got EOF
  ;


my $srv_sock = tcp_server('127.0.0.1', 0);
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    if (my $paddr = accept my $sock, $srv_sock) {
        my ($port,$iaddr) = sockaddr_in($paddr);
        my $ip = inet_ntoa($iaddr);
        is($ip, '127.0.0.1', 'ip correct');
        IO::Stream->new({
            fh          => $sock,
            cb          => 'Server',
            wait_for    => EOF,
            in_buf_limit=> 1024,
            Prev_bytes  => 0,
            LimitErrs   => 3,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
});

my $io = IO::Stream->new({
    host        => '127.0.0.1',
    port        => sockport($srv_sock),
    cb          => 'Client',
    method      => 'IO_client',
    wait_for    => SENT,
    out_buf     => 'x' x $SIZE,
    out_pos     => 0,
});

EV::loop();


package Server;
use Test::More;
use IO::Stream;
sub IO {
    my ($self, $io, $e, $err) = @_;
    if ($err) {
        if ($err == EINBUFLIMIT) {
            ok($io->{LimitErrs} > 0, 'got <in_buf_limit reached> error');
            $io->{LimitErrs}--;
            $io->{in_buf_limit} *= 10;
        }
        else {
            die $err;
        }
    }
    ok($io->{in_bytes} > $io->{Prev_bytes},    '  in_bytes incremented, good');
    is(length($io->{in_buf}), $io->{in_bytes}, '  in_bytes correct');
    $io->{Prev_bytes} = $io->{in_bytes};
    if ($io->{in_bytes} < $SIZE) {
        ok(!$io->{is_eof}, 'no eof yet');
    } else {
        ok($io->{LimitErrs} == 0,   'got ALL <in_buf_limit reached> errors');
        ok($io->{is_eof},           'now got {is_eof}!!!');
        is($io->{in_bytes}, $SIZE,  'All data received');
        exit;
    }
}

package Client;
use Test::More;
use IO::Stream;
sub IO_client {
    my ($self, $io, $e, $err) = @_;
    die $err if $err;
    shutdown $io->{fh}, 1;
}

