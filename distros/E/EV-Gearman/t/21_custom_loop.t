# loop => $ev_loop: the documented option must actually work. An
# EV::Loop object is a blessed scalar holding the loop pointer in its
# IV slot; reading the (NULL) PV slot used to store a NULL loop and
# segfault at the first ev_io_start. Also: bad values must croak, and
# the client must hold the loop alive.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Scalar::Util qw(weaken);
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)"
    unless $probe;
close $probe;

# --- invalid loop values croak rather than crash ---
{
    my $err = eval { EV::Gearman->new(loop => 'notaloop', host => $host, port => $port); 1 }
        ? '' : $@;
    like $err, qr/EV::Loop/, 'loop => "notaloop" croaks';
}
{
    my $err = eval { EV::Gearman->new(loop => {}, host => $host, port => $port); 1 }
        ? '' : $@;
    like $err, qr/EV::Loop/, 'loop => {} croaks';
}

# --- echo round trip on a custom loop, driven by $loop->run ---
my $loop = EV::Loop->new;
my ($res, $err);
my $g = EV::Gearman->new(loop => $loop, host => $host, port => $port);
$g->echo('custom-loop', sub { ($res, $err) = @_; $loop->break });
my $guard = $loop->timer(5, 0, sub { fail 'custom loop echo timeout'; $loop->break });
$loop->run;
is $err, undef, 'no error on custom loop';
is $res, 'custom-loop', 'echo round trip on custom EV::Loop';

# --- the client holds the loop alive ---
my $weak;
my $g2;
{
    my $l2 = EV::Loop->new;
    $weak = $l2;
    weaken($weak);
    $g2 = EV::Gearman->new(loop => $l2, host => $host, port => $port);
}   # $l2's own strong ref dies here
ok defined($weak), 'loop survives after caller drops the only strong ref';

my ($r2, $e2);
$g2->echo('held', sub { ($r2, $e2) = @_; $weak->break });
my $guard2 = $weak->timer(5, 0, sub { fail 'held loop echo timeout'; $weak->break });
$weak->run;
is $e2, undef, 'no error when client holds the only loop reference';
is $r2, 'held', 'echo works when client holds the only loop reference';

done_testing;
