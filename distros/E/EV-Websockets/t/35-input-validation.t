use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Input validation that used to fail silently or asynchronously:
#   - close($code) passed any int straight to the wire (1005 sent verbatim,
#     70000 wrapped to 4464); RFC 6455 7.4 only permits a few ranges.
#   - an undef string option stringified to "" (with a warning), so
#     name => undef created a vhost named "".
#   - an unparseable port in a URL went through atoi() as 0, surfacing later
#     as an obscure asynchronous connect failure.
#   - a dangling option key (odd argument count) was silently ignored.
#   - adopt() accepted any pollable fd; a pipe was adopted and taken over.

my %cb = (on_connect => sub { }, on_message => sub { }, on_close => sub { });
my $ctx = EV::Websockets::Context->new();

# --- option / URL / fd validation (all synchronous croaks) ------------------
{
    eval { $ctx->listen(port => 0, name => undef, %cb) };
    like($@, qr/must be a defined string/, 'listen(name => undef) croaks');

    eval { $ctx->listen(port => 0, %cb, 'orphan_key') };
    like($@, qr/odd number of options/, 'listen() with a dangling option key croaks');

    eval { $ctx->connect(url => "ws://127.0.0.1:notaport/", %cb, on_error => sub { }) };
    like($@, qr/invalid port/, 'connect() with an unparseable port croaks');

    eval { $ctx->connect(url => "ws://[::1]:notaport/", %cb, on_error => sub { }) };
    like($@, qr/invalid port/, 'connect() with an unparseable IPv6 port croaks');

    pipe(my $pr, my $pw) or die "pipe: $!";
    eval { $ctx->adopt(fh => $pr, %cb) };
    like($@, qr/not a socket/, 'adopt() rejects a non-socket (pipe) handle');

    my $port = eval { $ctx->listen(port => 0, %cb) };
    ok(!$@ && defined $port && $port > 0, 'a well-formed listen() still works');
}

# --- close() code validation (needs a live connection) ----------------------
{
    my (@bad, @good);
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { }, on_close => sub { },
    );
    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            # reserved / out-of-range codes must be refused before the wire
            for my $code (999, 1004, 1005, 1006, 1015, 70000, -1) {
                push @bad, $code if eval { $c->close($code); 1 };
            }
            # permitted ranges must still be accepted
            for my $code (1000, 1011, 1013, 3000, 4999) {
                push @good, $code unless eval { $c->close($code); 1 };
            }
            EV::break;
        },
        on_message => sub { }, on_close => sub { },
        on_error   => sub { EV::break },
    );
    my $watchdog = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is_deeply(\@bad,  [], 'close() rejects reserved/out-of-range codes')
        or diag "wrongly accepted: @bad";
    is_deeply(\@good, [], 'close() accepts RFC-permitted codes')
        or diag "wrongly rejected: @good";
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
