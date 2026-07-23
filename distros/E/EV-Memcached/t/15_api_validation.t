use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Callback-argument validation: a defined ref that is not CODE croaks;
# undef keeps its legacy meaning (no callback / clear handler).

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    sleep 3;   # accept the connection, never answer
});

my $mc = EV::Memcached->new(path => $srv->path, on_error => sub {});

for my $case (
    ['get',    sub { $mc->get('k', []) }],
    ['gets',   sub { $mc->gets('k', {}) }],
    ['delete', sub { $mc->delete('k', []) }],
    ['append', sub { $mc->append('k', 'v', []) }],
    ['touch',  sub { $mc->touch('k', 10, []) }],
    ['gat',    sub { $mc->gat('k', 10, []) }],
    ['version',sub { $mc->version([]) }],
    ['noop',   sub { $mc->noop([]) }],
    ['quit',   sub { $mc->quit([]) }],
    ['mget',   sub { $mc->mget(['k'], []) }],
    ['mgets',  sub { $mc->mgets(['k'], {}) }],
    ['sasl_auth', sub { $mc->sasl_auth('u', 'p', []) }],
    ['sasl_list_mechs', sub { $mc->sasl_list_mechs([]) }],
    # trailing-arg sniffers
    ['set',    sub { $mc->set('k', 'v', 0, []) }],
    ['add',    sub { $mc->add('k', 'v', []) }],
    ['cas',    sub { $mc->cas('k', 'v', 1, []) }],
    ['incr',   sub { $mc->incr('k', 1, []) }],
    ['decr',   sub { $mc->decr('k', []) }],
    ['flush',  sub { $mc->flush([]) }],
    ['stats',  sub { $mc->stats([]) }],
) {
    my ($name, $code) = @$case;
    eval { $code->() };
    like($@, qr/^callback must be a code reference/, "$name: non-CODE ref cb croaks");
}

# Non-ref trailing args keep their positional meaning (no callback).
eval { $mc->set('k', 'v', 300) };
is($@, '', 'set with numeric expiry and no callback: no croak');

# Handlers: accessors croak on bad refs; undef clears.
eval { $mc->on_error([]) };
like($@, qr/^callback must be a code reference/, 'on_error accessor croaks on bad ref');
$mc->on_error(undef);
is($mc->on_error, undef, 'on_error(undef) clears');
eval { EV::Memcached->new(on_connect => []) };
like($@, qr/^callback must be a code reference/, 'new(on_connect => []) croaks');
my $mc2 = EV::Memcached->new(on_error => undef);
ok($mc2, 'new(on_error => undef) accepted');

# waiting_timeout accessor: setting a value while the wait queue is
# non-empty must schedule the expiry timer (pre-fix: never scheduled).
{
    my $srv2 = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        my $r = $c->read_request;   # get1 arrives; response withheld
        sleep 3;
    });
    my $mc3 = EV::Memcached->new(
        path => $srv2->path, on_error => sub {}, max_pending => 1,
    );
    my @fired;
    $mc3->on_connect(sub {
        # Connected: get1 goes in flight (response withheld), get2 is
        # parked by max_pending=1.
        $mc3->get('k1', sub { push @fired, ['get1', $_[1]] });
        $mc3->get('k2', sub { push @fired, ['get2', $_[1]] });
        is($mc3->waiting_count, 1, 'second get parked in waiting queue');
        $mc3->waiting_timeout(150);   # must schedule the timer NOW
    });
    my $t = EV::timer 1.5, 0, sub { EV::break };
    EV::run;
    is(scalar @fired, 1, 'one callback fired');
    is($fired[0][0], 'get2', 'the waiting one');
    like($fired[0][1], qr/waiting timeout/, 'with "waiting timeout" error');
    $srv2->finish;
}

$srv->finish;
done_testing;
