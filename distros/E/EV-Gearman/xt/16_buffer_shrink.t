# A single large packet grows the read/write buffers; once it drains
# they must be released back to BUF_INIT_SIZE rather than pinned for
# the life of the connection. Asserts the buf_maybe_shrink path via
# the internal _buf_caps accessor (deterministic, platform-neutral —
# unlike an RSS probe, which the allocator and Perl's own SV arena
# would muddy).
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

my $INIT = 16384;   # BUF_INIT_SIZE

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);
$wkr->register_function('shrink_'.$$ => sub { length $_[0]->workload });
$wkr->work;

# Warm up so both ends are connected and at the initial buffer size.
$cli->submit_job('shrink_'.$$, 'warmup', sub { EV::break });
EV::run;

my ($cr, $cw) = $cli->_buf_caps;
my ($wr, $ww) = $wkr->_buf_caps;
is $cw, $INIT, 'client write buffer starts at init size';
is $wr, $INIT, 'worker read buffer starts at init size';

# 16 MiB job (>> the 1 MiB shrink threshold): the client's write
# buffer and the worker's read buffer both balloon to ~16 MiB.
my $size = 16 * 1024 * 1024;
my $payload = 'z' x $size;
my ($r, $e);
$cli->submit_job('shrink_'.$$, $payload, sub { ($r, $e) = @_; EV::break });
undef $payload;
my $g = EV::timer 30, 0, sub { fail 'shrink job timeout'; EV::break };
EV::run;
is $e, undef,  'large job completed';
is $r, $size,  'worker received the full payload';

# One more tiny round-trip so both shrink points have certainly run
# (wbuf in try_write, rbuf at the tail of process_responses).
$cli->echo('ping', sub { EV::break });
EV::run;

($cr, $cw) = $cli->_buf_caps;
($wr, $ww) = $wkr->_buf_caps;
is $cw, $INIT, 'client write buffer released after large send drained';
is $wr, $INIT, 'worker read buffer released after large recv drained';

done_testing;
