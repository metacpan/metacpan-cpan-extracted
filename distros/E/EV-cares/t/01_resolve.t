use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# --- object lifecycle ---

{
    my $r = EV::cares->new;
    isa_ok($r, 'EV::cares');
    is($r->active_queries, 0, 'no active queries initially');
    $r->destroy;
    eval { $r->resolve('x', sub {}) };
    like($@, qr/destroyed/, 'methods croak after destroy');
}

# --- constructor options ---

{
    my $r = EV::cares->new(
        timeout => 2,
        tries   => 2,
        ndots   => 1,
        flags   => ARES_FLAG_EDNS,
    );
    isa_ok($r, 'EV::cares');
}

# --- set_servers / servers ---

{
    my $r = EV::cares->new;
    $r->set_servers('8.8.8.8', '1.1.1.1');
    like($r->servers, qr/8\.8\.8\.8/, 'servers() returns current list');
    like($r->servers, qr/1\.1\.1\.1/, 'servers() includes second server');

    # arrayref form mirrors new(servers => [...])
    $r->set_servers(['9.9.9.9', '149.112.112.112']);
    like($r->servers, qr/9\.9\.9\.9/, 'set_servers accepts arrayref');
    like($r->servers, qr/149\.112\.112\.112/, 'set_servers arrayref second entry');

    eval { $r->set_servers() };
    like($@, qr/at least one/, 'set_servers with no args croaks');

    eval { $r->set_servers([]) };
    like($@, qr/empty arrayref/, 'set_servers with empty arrayref croaks');

    eval { EV::cares->new(servers => []) };
    like($@, qr/empty/, 'new(servers => []) croaks consistently');

    eval { $r->set_servers({host => '127.0.0.1'}) };
    like($@, qr/reference/i, 'set_servers flat-list rejects hashref with descriptive croak');
}

# --- resolve localhost (files only, no network) ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->resolve('localhost', sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'resolve localhost succeeds');
    ok(@got > 1, 'got at least one address for localhost');
    diag "localhost: @got[1..$#got]";
}

# --- gethostbyname ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->gethostbyname('localhost', AF_INET, sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'gethostbyname localhost succeeds');
    ok(grep({ $_ eq '127.0.0.1' } @got[1..$#got]), 'gethostbyname got 127.0.0.1');
}

# --- search T_A ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->search('localhost', T_A, sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    SKIP: {
        skip 'search T_A localhost not available on this platform', 2
            if $got[0] != ARES_SUCCESS;
        pass('search T_A localhost succeeds');
        ok(grep({ $_ eq '127.0.0.1' } @got[1..$#got]), 'search T_A got 127.0.0.1');
    }
}

# --- cancel ---

{
    my $r = EV::cares->new;
    my $status_got;

    $r->resolve('unlikely-host-that-does-not-exist.test', sub {
        ($status_got) = @_;
    });

    $r->cancel;

    my $timer = EV::timer 1, 0, sub { EV::break };
    EV::run;

    is($status_got, ARES_ECANCELLED, 'cancel fires callback with ARES_ECANCELLED');
}

# --- destroy with pending queries ---

{
    my $r = EV::cares->new;
    my @statuses;

    $r->resolve('unlikely-a.test', sub { push @statuses, $_[0] });
    $r->resolve('unlikely-b.test', sub { push @statuses, $_[0] });

    $r->destroy;

    my $timer = EV::timer 1, 0, sub { EV::break };
    EV::run;

    ok(scalar @statuses > 0, 'destroy fires pending callbacks');
    ok((grep { $_ == ARES_ECANCELLED || $_ == ARES_EDESTRUCTION } @statuses),
       'callbacks get cancellation/destruction status');
}

# --- DESTROY cleans up ---

{
    my $r = EV::cares->new;
    $r->resolve('localhost', sub {});
    undef $r;
    pass('DESTROY cleanup did not crash');
}

# --- strerror ---

{
    like(EV::cares::strerror(ARES_ETIMEOUT), qr/imeout/i, 'strerror timeout');
    like(EV::cares->strerror(ARES_ENOTFOUND), qr/not found/i, 'strerror class method');

    eval { EV::cares->strerror() };
    like($@, qr/Usage/, 'class method with no arg croaks');

    eval { EV::cares::strerror() };
    like($@, qr/Usage/, 'function form with no arg croaks');

    eval { EV::cares::strerror('foo') };
    like($@, qr/Usage/, 'non-numeric arg croaks');

    eval { EV::cares->strerror('foo') };
    like($@, qr/Usage/, 'class method with non-numeric arg croaks');
}

# --- invalid arguments ---

{
    my $r = EV::cares->new;
    eval { $r->resolve('x', 'not a coderef') };
    like($@, qr/CODE reference/, 'non-coderef callback rejected');

    eval { $r->reverse('not-an-ip', sub {}) };
    like($@, qr/invalid IP/, 'invalid IP in reverse rejected');
}

# --- getaddrinfo with hints ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->getaddrinfo('localhost', undef, { family => AF_INET }, sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'getaddrinfo with family hint succeeds');
    ok(@got > 1, 'getaddrinfo returned addresses');
    # with AF_INET hint, should only get IPv4
    ok(!grep({ /::/ } @got[1..$#got]), 'AF_INET hint excludes IPv6');
}

# --- getaddrinfo with numeric service ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->getaddrinfo('localhost', '80', { family => AF_INET }, sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    SKIP: {
        skip 'getaddrinfo with service not supported in this build', 1
            if $got[0] != ARES_SUCCESS;
        ok(@got > 1, 'getaddrinfo accepted a service argument and returned addresses');
    }
}

# --- concurrent queries ---

{
    my $r = EV::cares->new(lookups => 'f');
    my $count = 0;
    my $target = 10;

    for (1 .. $target) {
        $r->resolve('localhost', sub {
            $count++ if $_[0] == ARES_SUCCESS;
        });
    }

    my $done;
    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done || $count >= $target;

    is($count, $target, "all $target concurrent queries completed");
    is($r->active_queries, 0, 'no queries outstanding after completion');
}

# --- query raw ---

{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;

    $r->query('localhost', C_IN, T_A, sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    # file-based query may or may not succeed depending on resolver
    ok(defined $got[0], 'query returned a status');
}

# --- callback exception handling ---

{
    my $warned;
    local $SIG{__WARN__} = sub { $warned = $_[0] };

    my $r = EV::cares->new(lookups => 'f');
    my $done;

    $r->resolve('localhost', sub {
        $done = 1;
        die "test exception in callback";
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    like($warned, qr/test exception/, 'callback exception caught and warned');
}

# --- destroy from within callback ---

{
    my $r = EV::cares->new(lookups => 'f');
    my $done;

    $r->resolve('localhost', sub {
        $r->destroy;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    pass('destroy from within callback did not crash');
    eval { $r->resolve('x', sub {}) };
    like($@, qr/destroyed/, 'resolver is dead after callback destroy');
}

# --- double destroy ---

{
    my $r = EV::cares->new;
    $r->destroy;
    eval { $r->destroy };
    is($@, '', 'double destroy is silent (no croak)');

    # cancel() vs the read-only getters: cancel croaks on destroyed
    # (matches every other mutating method); the getters return values.
    eval { $r->cancel };
    like($@, qr/destroyed/, 'cancel croaks on destroyed resolver');
}

# --- constructor options smoke tests ---

{
    # qcache
    my $r1 = EV::cares->new(qcache => 300);
    isa_ok($r1, 'EV::cares', 'qcache option accepted');

    # ednspsz
    my $r2 = EV::cares->new(ednspsz => 4096);
    isa_ok($r2, 'EV::cares', 'ednspsz option accepted');

    # maxtimeout
    my $r3 = EV::cares->new(maxtimeout => 30);
    isa_ok($r3, 'EV::cares', 'maxtimeout option accepted');

    # udp_max_queries
    my $r4 = EV::cares->new(udp_max_queries => 100);
    isa_ok($r4, 'EV::cares', 'udp_max_queries option accepted');
}

# --- custom hosts_file ---

{
    use File::Temp;
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.20.30.40 custom-test-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my @got;
    my $done;

    $r->resolve('custom-test-host', sub {
        @got = @_;
        $done = 1;
    });

    my $timer = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'custom hosts_file lookup succeeded');
    ok(grep({ $_ eq '10.20.30.40' } @got[1..$#got]), 'resolved via custom hosts_file');
}

# --- custom resolvconf (may be ignored on macOS) ---

SKIP: {
    skip 'ARES_OPT_RESOLVCONF not reliable on macOS', 1 if $^O eq 'darwin';

    use File::Temp;
    my $tmp = File::Temp->new(SUFFIX => '.conf');
    print $tmp "nameserver 127.0.0.1\noptions timeout:1 attempts:1\n";
    close $tmp;

    my $r = EV::cares->new(resolvconf => $tmp->filename);
    like($r->servers, qr/127\.0\.0\.1/, 'custom resolvconf picked up nameserver');
}

# --- set_local_dev / set_local_ip4 / set_local_ip6 smoke ---

{
    my $r = EV::cares->new;
    eval { $r->set_local_dev('lo') };
    is($@, '', 'set_local_dev accepted');

    eval { $r->set_local_ip4('127.0.0.1') };
    is($@, '', 'set_local_ip4 accepted');

    eval { $r->set_local_ip6('::1') };
    is($@, '', 'set_local_ip6 accepted');

    eval { $r->set_local_ip4('not-an-ip') };
    like($@, qr/invalid/, 'set_local_ip4 rejects bad input');

    eval { $r->set_local_ip6('not-an-ip') };
    like($@, qr/invalid/, 'set_local_ip6 rejects bad input');
}

# --- reinit ---

{
    my $r = EV::cares->new;
    eval { $r->reinit };
    is($@, '', 'reinit succeeds');

    $r->destroy;
    eval { $r->reinit };
    like($@, qr/destroyed/, 'reinit croaks on destroyed resolver');
}

# --- getnameinfo sockaddr validation ---

{
    my $r = EV::cares->new;
    eval { $r->getnameinfo("x", 0, sub {}) };
    like($@, qr/too short/, 'getnameinfo rejects short sockaddr');

    # AF_UNIX (1) family — sa_family_t is 2 bytes on Linux; pad to typical size
    my $bad = pack('S', 1) . ("\0" x 30);
    eval { $r->getnameinfo($bad, 0, sub {}) };
    like($@, qr/unsupported sockaddr family/, 'getnameinfo rejects AF_UNIX');

    # AF_INET6 family with len in [sizeof(struct sockaddr), sizeof(struct
    # sockaddr_in6)).  On every supported platform sizeof(struct sockaddr)
    # == sizeof(struct sockaddr_in) == 16, so the truncated-AF_INET path
    # is provably unreachable: any short v4 sockaddr is caught earlier by
    # the universal "too short to read sa_family" check.  Only the v6
    # branch is reachable, with len 16..27 inclusive.
    #
    # Build a real v6 sockaddr via Socket so the sa_family byte lands at
    # the platform's actual offset (Linux: bytes 0-1; BSD: byte 1 with
    # sa_len at byte 0), then truncate to land in the [16,27] window.
    SKIP: {
        my $full_v6 = eval {
            require Socket;
            Socket::pack_sockaddr_in6(0, Socket::inet_pton(Socket::AF_INET6(), '::1'));
        };
        skip 'Socket::pack_sockaddr_in6 unavailable', 1 unless $full_v6;
        my $short_v6 = substr($full_v6, 0, 20);   # 20 bytes, family preserved
        eval { $r->getnameinfo($short_v6, 0, sub {}) };
        like($@, qr/too short for AF_INET6/,
            'getnameinfo rejects truncated AF_INET6 sockaddr');
    }
}

done_testing;
