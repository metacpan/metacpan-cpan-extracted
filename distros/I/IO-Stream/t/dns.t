# DNS error.
use warnings;
use strict;
use t::share;

@CheckPoint = (
    {
        normal => [
            [ 'client', 0,          IO::Stream::EDNS    ], 'no such host',
        ],
        misconfigured => [ # some systems are configured to resolve anything, just deal with it!
            [ 'client', RESOLVED,   undef               ], 'resolve junk',
        ],
    },
);
plan tests => checkpoint_count();

IO::Stream->new({
    host        => 'no.such.host.q1w2e3',
    port        => 80,
    cb          => \&client,
    wait_for    => IN|EOF|OUT|SENT|CONNECTED|RESOLVED,
});

EV::loop;

sub client {
    my ($io, $e, $err) = @_;
  # &diag_event;
    checkpoint($e, $err);
    EV::unloop;
}

