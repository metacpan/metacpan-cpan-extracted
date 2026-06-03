# Regression: calling disconnect() from inside an admin-response
# callback must not corrupt the read buffer. The admin parser used to
# adjust rbuf_len after the callback unconditionally; if the callback
# tore the connection down (zeroing rbuf_len), that subtraction
# underflowed (size_t) and the following memmove ran with a huge
# length. This drives that exact path; under ASan it would abort.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $g = EV::Gearman->new(host => $host, port => $port);
my ($got_reply, $cb_err);
$g->on_connect(sub {
    # 'status' is a multi-line admin reply; disconnect from within its
    # callback.
    $g->server_status(sub {
        my ($txt, $err) = @_;
        $got_reply = defined $txt;
        $cb_err = $err;
        $g->disconnect;        # <-- the dangerous moment
        EV::break;
    });
});
my $guard = EV::timer 5, 0, sub { fail 'admin-disconnect timeout'; EV::break };
EV::run;

ok $got_reply, 'admin callback received a reply';
is $cb_err, undef, 'admin reply had no error';
ok !$g->is_connected, 'disconnect from admin callback took effect';

# If we got here the process did not crash on the rbuf bookkeeping.
pass 'survived disconnect-in-admin-callback without buffer corruption';

done_testing;
