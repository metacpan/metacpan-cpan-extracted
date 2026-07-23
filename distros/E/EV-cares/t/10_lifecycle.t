use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:all);

# recursive callbacks: issuing a query from inside another's callback
# stresses the in_callback / free_pending bracketing
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.0.0.1 outer-host\n10.0.0.2 inner-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my (@outer, @inner);
    my $done;

    $r->resolve('outer-host', sub {
        @outer = @_;
        $r->resolve('inner-host', sub {
            @inner = @_;
            $done = 1;
        });
    });

    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($outer[0], ARES_SUCCESS, 'outer query succeeded');
    is($inner[0], ARES_SUCCESS, 'inner query (recursive) succeeded');
    ok(grep({ $_ eq '10.0.0.1' } @outer[1..$#outer]), 'outer addr');
    ok(grep({ $_ eq '10.0.0.2' } @inner[1..$#inner]), 'inner addr');
}

# reinit: rewrite hosts_file, call reinit, verify the new content is picked up
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.1.1.1 phase1-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);

    my (@p1, @p2);
    my $done;
    $r->resolve('phase1-host', sub { @p1 = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    is($p1[0], ARES_SUCCESS, 'phase 1 lookup succeeded');

    # rewrite hosts file with different content
    open my $fh, '>', $tmp->filename or die $!;
    print $fh "10.2.2.2 phase2-host\n";
    close $fh;

    eval { $r->reinit };
    is($@, '', 'reinit succeeded');

    $done = 0;
    $r->resolve('phase2-host', sub { @p2 = @_; $done = 1 });
    $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    is($p2[0], ARES_SUCCESS, 'phase 2 lookup succeeded after reinit');
    ok(grep({ $_ eq '10.2.2.2' } @p2[1..$#p2]), 'reinit picked up new hosts');
}

# rotate=>1 with multiple servers smoke-tests that the option is accepted
# (we can't easily verify per-query distribution without packet capture)
{
    my $r = EV::cares->new(
        servers => ['127.0.0.1', '127.0.0.2', '127.0.0.3'],
        rotate  => 1,
        timeout => 1,
        tries   => 1,
    );
    isa_ok($r, 'EV::cares', 'rotate=>1 accepted');
    like($r->servers, qr/127\.0\.0\.1/, 'first server present');
    like($r->servers, qr/127\.0\.0\.3/, 'third server present');
}

# cancel before EV::run (not from inside a callback) — c-ares 1.34
# has a known interaction issue when cancel and a follow-up
# ares_getaddrinfo execute on the same channel, so we keep this test
# narrow.
{
    my $r = EV::cares->new(
        servers => ['127.0.0.1:9'],
        timeout => 5,
        tries   => 1,
    );
    my %statuses;
    for my $i (1..3) {
        $r->resolve("h$i.invalid.test", sub { $statuses{$i} = $_[0] });
    }
    $r->cancel;
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;

    is(scalar(keys %statuses), 3, 'all 3 cancelled callbacks fired');
    ok((!grep { $_ == ARES_SUCCESS } values %statuses),
       'no callback got ARES_SUCCESS after cancel');
}

# regression: dropping the last reference inside a callback with queries
# still pending used to UAF/double-free the resolver
{
    my $r = EV::cares->new(servers => '192.0.2.1', timeout => 1, tries => 1);
    my $edestruction = 0;
    # 192.0.2.1 is a blackhole (TEST-NET-1): the queries stay in flight
    $r->resolve('p1.blackhole.example.com',
                sub { $edestruction++ if $_[0] == ARES_EDESTRUCTION });
    $r->resolve('p2.blackhole.example.com',
                sub { $edestruction++ if $_[0] == ARES_EDESTRUCTION });
    is($r->active_queries, 2, 'two blackholed queries in flight');

    my $done;
    # drops the LAST reference from inside a c-ares callback
    $r->resolve('localhost', sub { undef $r; $done = 1 });

    # localhost normally resolves inline via the hosts file; if a future
    # c-ares defers it, pump the loop so the drop still happens inside a
    # c-ares callback through the io/timer bracket (same code path)
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    pass('survived dropping the last reference inside a callback');
    is($edestruction, 2, 'stranded callbacks fired with ARES_EDESTRUCTION');
}

done_testing;
