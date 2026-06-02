use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Connect a client to an echo-capturing server, run $setup->($cli), and return
# what the server captured. Generic harness for the data round-trips below.
sub round_trip {
    my ($send_cb, $capture) = @_;
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { my ($c, $d, $bin) = @_; $capture->($d, $bin); $c->send("ack") },
        on_close   => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $send_cb->($_[0]) },
        on_message => sub { $_[0]->close(1000) },        # got the ack -> done
        on_close   => sub {
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { diag "error: $_[1]"; delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(15, 0, sub { diag "Timeout"; EV::break });
    EV::run;
}

# 1. A Perl string with wide characters is sent as its UTF-8 bytes (send() uses
#    SvPV; the peer receives bytes, not a UTF8-flagged string). This documents
#    the byte-oriented contract: encode/decode is the caller's responsibility.
{
    my $wide   = "snow \x{2603} grin \x{1F600} caf\x{e9}";
    my $expect = $wide;
    utf8::encode($expect);                                # the UTF-8 octets
    my ($got, $got_utf8_flag);
    round_trip(sub { $_[0]->send($wide) },
               sub { $got = $_[0]; $got_utf8_flag = utf8::is_utf8($_[0]) });
    ok(defined $got, "utf8: server received the message");
    ok(!$got_utf8_flag, "utf8: received data is bytes (no UTF8 flag)");
    is($got, $expect, "utf8: wide string arrives as its UTF-8 octets");
}

# 2. A message larger than the lws rx buffer (65536) reassembles intact,
#    exercising the recv_buf doubling/grow path across multiple fragments.
{
    my $big = ("0123456789" x 4) x 6554;                 # 40 * 6554 = 262160 bytes
    cmp_ok(length($big), '>', 65536, "large: payload exceeds the 64K rx buffer");
    my ($len, $eq);
    round_trip(sub { $_[0]->send($big) },
               sub { $len = length($_[0]); $eq = ($_[0] eq $big) });
    is($len, length($big), "large: full length reassembled ($len bytes)");
    ok($eq, "large: content intact across fragments");
}

# (A standalone zero-length message is intentionally not tested: lws does not
# deliver an empty frame as an on_message event, which is its own behaviour to
# define, not this module's. The recv-side zero-length guard still matters for
# empty *fragments* within a larger message.)

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
