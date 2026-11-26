use strict;
use warnings;

use lib 't/lib';

use Data::Dumper ();
use Mojo::IOLoop;
use Mojo::JSON ();
use Mojo::UserAgent;
use Scalar::Util ();
use Storable ();
use Test::More;
use Time::HiRes ();
use InternetData;
use InternetDataTest;
use InternetDataTest::Origin;

# The lookups' Perl-specific surface, as distinct from the shared corpus in
# t/01-conformance.t.

sub lookup_body {
    return InternetDataTest::lookup(@_);
}

subtest 'a batch honors the per-call concurrency, measured as peak in flight' => sub {
    # Peak in flight is the only measurement that separates a real ceiling from
    # an option that was accepted and ignored: counting total requests passes
    # either way.
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        InternetDataTest::Origin::slow_json($c, InternetDataTest::Origin::batch_body($c), 0.2);
    });
    # Enough addresses for nine chunks of the batch endpoint's 1000, so a
    # concurrency of six has something to bound: one request per chunk, and only
    # the chunks overlap.
    my @addresses = map { sprintf '9.%d.%d.%d', 1 + int($_ / 65536), int($_ / 256) % 256, $_ % 256 } 0 .. 8000;

    my $client = InternetData->new(base_url => $origin->url, cache_size => 0, concurrency => 2);
    $client->lookup_batch(\@addresses, concurrency => 6);
    is($origin->count, 9, 'one request per chunk of 1000');
    is($origin->peak_in_flight, 6, 'the per-call ceiling was reached and not exceeded');

    $origin->reset;
    $client->lookup_batch(\@addresses);
    is($origin->peak_in_flight, 2, 'without an override the client default applies exactly');

    $origin->reset;
    $client->lookup_batch(\@addresses, concurrency => 1);
    is($origin->peak_in_flight, 1, 'concurrency 1 is genuinely serial');
};

subtest 'a concurrency below 1 is refused before any request' => sub {
    # A batch that can put no chunk in flight never finishes, so this is refused
    # up front rather than discovered by a caller left waiting.
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => {}) });
    my $client = InternetData->new(base_url => $origin->url, cache_size => 0);
    for my $bad (0, -1) {
        # Raced against a timer: accepted, it would be a batch that never ends.
        my $batch = eval { $client->lookup_batch_p(['9.9.9.1', '9.9.9.2'], concurrency => $bad) };
        like($@, qr/concurrency must be a whole number, 1 or more/, "lookup_batch refuses concurrency => $bad");
        Mojo::Promise->race($batch, Mojo::Promise->timer(1))->wait if $batch;
        eval { InternetData->new(concurrency => $bad) };
        like($@, qr/concurrency must be a whole number, 1 or more/, "new refuses concurrency => $bad");
    }
    is($origin->count, 0, 'and not one request was spent finding out');
};

subtest 'a lookup, a batch and the account calls each reach their route' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my $path = $c->req->url->path->to_string;
        return $c->render(json => InternetDataTest::Origin::batch_body($c)) if $path eq '/batch';
        return $c->render(json => InternetDataTest::asn()) if $path =~ m{\A/asn/};
        return $c->render(json => InternetDataTest::domain()) if $path =~ m{\A/domain/};
        $c->render(json => lookup_body());
    });
    my $client = InternetData->new(base_url => $origin->url, cache_size => 0, retries => 0);
    # Each evaluated, so a request sent anywhere else fails at the paths below.
    eval { $client->lookup('9.9.9.9') };
    eval { $client->lookup_batch(['9.9.9.1', '9.9.9.2']) };
    eval { $client->lookup_asn(9009) };
    eval { $client->lookup_asn('AS9009') };
    eval { $client->lookup_domain('example.com') };
    eval { $client->my_ip };

    # The spec names a server per lookup operation, production's; every request
    # goes to the client's base URL instead, or none would have reached this one.
    my @requests = $origin->requests;
    is_deeply([map { $_->{path} } @requests],
        ['/9.9.9.9', '/batch', '/asn/9009', '/asn/AS9009', '/domain/example.com', '/myip'],
        'each on its own route at the base URL, the AS number sent as given');
    is_deeply([map { $_->{query} } @requests], [({}) x 6], 'with no query at all');
};

subtest 'an AS number or a domain is one path segment, whatever it holds' => sub {
    my @paths;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        push @paths, $c->req->url->path->to_string;
        $c->render(json => { error => 'not a valid IP address, AS number or domain' }, status => 400);
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 0);
    for my $target ('a/b', 'x?y=1', 'z#w', '50%', 'b' . chr(0xfc) . 'cher.example') {
        eval { $client->lookup_domain($target) };
        is(ref $@ && $@->kind, 'bad_request', 'the API answers what it cannot read');
    }
    eval { $client->lookup_asn('AS 9009/x') };
    is_deeply(\@paths, [
        '/domain/a%2Fb', '/domain/x%3Fy%3D1', '/domain/z%23w', '/domain/50%25', '/domain/b%C3%BCcher.example',
        '/asn/AS%209009%2Fx',
    ], 'escaped as one segment, a character over its UTF-8 bytes');
    is($origin->count, 6, 'and a 400 is asked once');
};

# This API answers an AS or a domain at an address's path too, as an answer
# lookup cannot read: sent, each would be three retried server_errors, and three
# lookups spent.
subtest 'a lookup refuses what is not an IP address, before sending it' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        return $c->render(json => InternetDataTest::asn()) unless $c->req->url->path->to_string eq '/batch';
        my $refused = { status => 400, error => 'not a valid IP address, AS number or domain' };
        $c->render(json => { results => {}, errors => { map { ($_ => $refused) } @{ $c->req->json->{ips} } } });
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 2);
    for my $target ('example.com', 'AS15169', '9009', '1.2.3', '10.0.0.0/8', '2001:db8::1/64', ' 1.1.1.1', 'notanip') {
        my $error = eval { $client->lookup($target); 1 } ? undef : $@;
        ok(ref $error && $error->isa('InternetData::Error'), "'$target' is refused") or next;
        is($error->kind, 'bad_request', "'$target': as a bad_request");
        is($error->retryable, 0, "'$target': not retried");
        is($error->message, "'$target' is not an IP address: look up an AS with lookup_asn, and a domain with lookup_domain",
            "'$target': naming the calls that take one");
        my ($rejected, $died);
        my $promise = eval { $client->lookup_p($target) } or $died = 1;
        $promise->catch(sub { $rejected = shift })->wait if $promise;
        ok(!$died && ref $rejected && $rejected->kind eq 'bad_request', "'$target': lookup_p rejects with it");
    }
    is($origin->count, 0, 'and not one was sent');
    my $entry = $client->lookup_batch(['notanip'])->{notanip};
    is($origin->count, 1, 'while a batch sends it, for the API to refuse entry by entry');
    is(ref $entry && $entry->status, 400, 'as it does');
};

subtest 'a lookup refuses arguments it cannot use, before any request' => sub {
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => {}) });
    my $client = InternetData->new(base_url => $origin->url);
    for my $empty (undef, '') {
        eval { $client->lookup($empty) };
        like($@, qr/lookup: expected an IP address/, 'lookup needs an address');
        eval { $client->lookup_asn($empty) };
        like($@, qr/lookup_asn: expected an AS number/, 'lookup_asn needs an AS number');
        eval { $client->lookup_domain($empty) };
        like($@, qr/lookup_domain: expected a domain/, 'lookup_domain needs a domain');
    }
    eval { $client->lookup_batch('9.9.9.9') };
    like($@, qr/lookup_batch: expected an array reference/, 'lookup_batch needs a list');
    for my $call (
        [lookup => sub { $client->lookup('9.9.9.9', concurrency => 2) }],
        [lookup_asn => sub { $client->lookup_asn(9009, concurency => 2) }],
        [lookup_domain => sub { $client->lookup_domain('example.com', concurrency => 2) }],
        [my_ip => sub { $client->my_ip(retires => 2) }],
        [my_entitlement => sub { $client->my_entitlement(cache => 0) }],
        [lookup_batch => sub { $client->lookup_batch(['9.9.9.9'], concurency => 2) }],
    ) {
        eval { $call->[1]->() };
        like($@, qr/InternetData::\Q$call->[0]\E: unknown option/, "$call->[0] refuses an option it does not take");
    }
    is($origin->count, 0, 'and not one request was spent finding out');
};

subtest 'absent and false are different values, natively' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => lookup_body(ip => '9.9.9.5', is_hosting => \0));
    });
    my $result = InternetData->new(base_url => $origin->url)->lookup('9.9.9.5');

    is($result->is_hosting, 0, 'a served false is 0');
    is($result->has('is_hosting'), 1, 'and the plan carries it');
    is($result->is_vpn, undef, 'an unserved field is undef');
    is($result->has('is_vpn'), 0, 'and the plan does not carry it');
    ok(!$result->is_hosting && !$result->is_vpn,
        'both are false in boolean context, which is exactly the trap');
    ok(defined $result->is_hosting, 'a served false is DEFINED');
    ok(!defined $result->is_vpn, 'an absent field is not');
    is($result->is_hosting // 0, 0, 'defined-or reads a served false as false');
    is($result->is_vpn // 0, 0, 'and reads an absent field as false too');
    ok(!exists $result->location->{city}, 'a paid member of a shared object is absent too');
    is_deeply([$result->fields], [qw(
        is_bogon is_tor is_relay is_hosting is_anycast tor relay location asn company hostname abuse
    )], 'fields lists what was served, in wire order');
    is_deeply([sort keys %{ $result->raw }], [sort keys %{ lookup_body(is_hosting => \0) }], 'raw is the wire body');
    # raw keeps the JSON booleans, so it re-encodes to true/false rather than 1/0.
    like(Mojo::JSON::encode_json($result->raw), qr/"is_hosting":false/, 'raw round-trips as JSON');
    eval { $result->has('is_bananas') };
    like($@, qr/unknown field/, 'has croaks on a name that is not a field');
};

# Unlimited answers none of the eight flags a paid plan or the trial adds, so an
# answer without them reads, and each reads as absent where it was never served.
subtest 'the paid flags are absent from an Unlimited answer and present on a paid one' => sub {
    my @paid = @InternetDataTest::PAID_FLAGS;
    my $unlimited = lookup_body();
    my %served_true = map { ($_ => \1) } @paid;
    my %served_false = map { ($_ => \0) } @paid;
    my $body;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        return $c->render(json => { results => { '9.9.9.1' => lookup_body(ip => '9.9.9.1'),
            '9.9.9.2' => lookup_body(ip => '9.9.9.2', %served_true) }, errors => {} })
            if $c->req->url->path->to_string eq '/batch';
        $c->render(json => $body);
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 0, cache_size => 0);

    $body = $unlimited;
    for my $call (['lookup', sub { $client->lookup('9.9.9.9') }], ['my_ip', sub { $client->my_ip }]) {
        my $result = eval { $call->[1]->() };
        ok($result, "$call->[0]: an answer without the eight is read") or do { diag("$@"); next };
        for my $flag (@paid) {
            is($result->has($flag), 0, "$call->[0]: $flag is not in the plan");
            is($result->$flag, undef, "$call->[0]: $flag reads as undef, never as false");
            ok(!exists $result->{$flag}, "$call->[0]: $flag has no key at all");
        }
        is($result->is_anycast, 0, "$call->[0]: what Unlimited serves is read");
        is_deeply([$result->fields], [qw(is_bogon is_tor is_relay is_anycast tor relay location asn company hostname abuse)],
            "$call->[0]: fields lists none of the eight");
    }

    $body = lookup_body(%served_true);
    my $paid = eval { $client->lookup('9.9.9.9') };
    ok($paid, 'an answer carrying the eight is read') or diag("$@");
    for my $flag (@paid) {
        is($paid->has($flag), 1, "$flag served");
        is($paid->$flag, 1, "$flag served true reads as 1");
    }
    $body = lookup_body(%served_false);
    my $false = eval { $client->lookup('9.9.9.9') };
    for my $flag (@paid) {
        is($false->has($flag), 1, "$flag served false is still served");
        is($false->$flag, 0, "$flag served false reads as 0");
    }

    $body = lookup_body(is_bot => \1, bot => { provider => 'p' });
    my $some = eval { $client->lookup('9.9.9.9') };
    is_deeply([map { $some->has($_) } @paid], [1, (0) x 7], 'one served flag leaves the other seven absent');

    my $answers = $client->lookup_batch(['9.9.9.1', '9.9.9.2']);
    is($answers->{'9.9.9.1'}->has('is_bot'), 0, 'a batch entry without the eight is read, and lacks them');
    is($answers->{'9.9.9.2'}->is_web, 1, 'and one with them reads them');

    $body = lookup_body(asn => { map { $_ => $unlimited->{asn}{$_} } qw(asn name domain prefix country) });
    my $untyped = eval { $client->lookup('9.9.9.9') };
    ok($untyped, 'an ASN without its network type is read') or diag("$@");
    ok(!exists $untyped->asn->{type}, 'and has no type');
};

subtest 'an AS or a domain answer keeps absent apart from false too' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        return $c->render(json => InternetDataTest::asn(trial_expired => \1)) if $c->req->url->path->to_string =~ m{^/asn/};
        $c->render(json => InternetDataTest::domain(is_disposable => \0, has_mx => \1));
    });
    my $client = InternetData->new(base_url => $origin->url);
    my $as = $client->lookup_asn(9009);
    my $domain = $client->lookup_domain('example.com');

    is($as->asn, 9009, 'the AS number comes back');
    is($as->type, undef, 'a paid member reads as undef');
    is($as->has('type'), 0, 'and the plan does not carry it');
    is($as->trial_expired, 1, 'the trial marker reads as 1');
    is_deeply([$as->fields], [qw(name country registry allocated domain trial_expired)], 'fields lists what was served');
    is($domain->is_disposable, 0, 'a served false is 0');
    is($domain->has('is_disposable'), 1, 'and served');
    is($domain->has_mx, 1, 'a served true is 1');
    is($domain->has('dns'), 0, 'the paid records are absent');
    is($domain->raw->{domain}, 'example.com', 'raw is the wire body');
    for my $case ([$as, 'InternetData::AsnResult'], [$domain, 'InternetData::DomainResult']) {
        my ($answer, $class) = @$case;
        isa_ok($answer, $class);
        eval { $answer->has('ip') };
        like($@, qr/\Q$class\E::has: unknown field 'ip'/, "$class: has croaks on a name that is not a field");
    }
};

subtest 'presence is exists, not defined' => sub {
    # An explicit null is a field the API DID serve, so the plan carries it and
    # `has` must say so. Testing `defined` instead would report it as missing,
    # and no other case separates the two because the API sends no nulls today.
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my $body = Mojo::JSON::encode_json(lookup_body(ip => '9.9.9.10'));
        $body =~ s/\}\z/,"vpn":null,"is_hosting":null,"trial_expired":null}/;
        $c->res->headers->content_type('application/json');
        $c->render(data => $body);
    });
    my $result = InternetData->new(base_url => $origin->url)->lookup('9.9.9.10');

    is($result->has('vpn'), 1, 'a served null is still a served field');
    ok(!defined $result->vpn, 'even though its value is undef');
    is($result->has('hosting'), 0, 'an unserved field is still absent');
    # A null flag or marker read as 0 would say no hosting server, or a trial
    # that lasts, which nothing served said.
    for my $flag (qw(is_hosting trial_expired)) {
        is($result->has($flag), 1, "a served null $flag is a served field");
        ok(!defined $result->$flag, "and reads as undef, never 0");
    }
};

subtest 'an IPv6 address reaches the API with its colons intact' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => lookup_body(ip => '2606:4700:4700::1111'));
    });
    InternetData->new(base_url => $origin->url)->lookup('2606:4700:4700::1111');

    # A colon is legal in a path segment, and production answers a literal one.
    # Percent-escaping it would be a silent behavior change on every v6 lookup.
    my ($request) = $origin->requests;
    is($request->{path}, '/2606:4700:4700::1111', 'the path is not over-escaped');
};

subtest 'the cache expires and evicts' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->render(json => lookup_body(ip => substr($c->req->url->path->to_string, 1)));
    });

    my $stale = InternetData->new(base_url => $origin->url, cache_ttl => 0.05);
    $stale->lookup('9.9.9.6');
    Time::HiRes::sleep(0.1);
    $stale->lookup('9.9.9.6');
    is($origin->count, 2, 'an expired answer is fetched again');

    $origin->reset;
    my $small = InternetData->new(base_url => $origin->url, cache_size => 2);
    $small->lookup($_) for qw(9.9.9.6 9.9.9.7 9.9.9.8 9.9.9.6);
    is($origin->count, 4, 'the least recently used address was evicted');
};

subtest 'concurrent misses for one address share one request' => sub {
    # Twenty concurrent lookups of one address are one request. The origin holds
    # each answer, so the calls genuinely overlap, and records what each batch
    # asked for.
    my @batches;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        if ($c->req->url->path->to_string eq '/batch') {
            push @batches, [sort @{ $c->req->json->{ips} }];
            InternetDataTest::Origin::slow_json($c, InternetDataTest::Origin::batch_body($c, 1), 0.2);
            return;
        }
        my ($ip) = $c->req->url->path->to_string =~ m{^/(.+)$};
        return $c->render(status => 500, json => { error => 'boom' }) if $ip eq '9.9.9.9';
        InternetDataTest::Origin::slow_json($c, lookup_body(ip => $ip, is_anycast => \1), 0.2);
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 0);

    my @results;
    Mojo::Promise->all(map { $client->lookup_p('9.9.9.1') } 1 .. 20)
        ->then(sub { @results = map { $_->[0] } @_ })->wait;
    is($origin->count, 1, 'twenty concurrent lookups of one address send one request');
    is(scalar(grep { $_->is_anycast } @results), 20, 'and every caller gets its answer');

    # A batch waits for a lookup already in flight instead of sending it.
    $origin->reset;
    my ($single, $batch);
    Mojo::Promise->all(
        $client->lookup_p('9.9.9.2')->then(sub { $single = shift }),
        $client->lookup_batch_p(['9.9.9.2', '9.9.9.3'])->then(sub { $batch = shift }),
    )->wait;
    is_deeply([sort $origin->paths], ['/9.9.9.2', '/batch'], 'the lookup and the batch each sent once');
    is_deeply($batches[-1], ['9.9.9.3'], 'the batch left out the address the lookup was fetching');
    is($batch->{'9.9.9.2'}, $single, 'and took the lookup\'s answer for it');

    # A lookup waits for a batch that boarded its address before sending.
    $origin->reset;
    my ($late, $first);
    Mojo::Promise->all(
        $client->lookup_batch_p(['9.9.9.4', '9.9.9.5'])->then(sub { $first = shift }),
        $client->lookup_p('9.9.9.5')->then(sub { $late = shift }),
    )->wait;
    is_deeply([$origin->paths], ['/batch'], 'a lookup of an address a batch is fetching sends nothing');
    is($late, $first->{'9.9.9.5'}, 'and takes the batch\'s answer');

    # A failure reaches every waiter, and is cached for none.
    $origin->reset;
    my @failed;
    Mojo::Promise->all(map {
        $client->lookup_p('9.9.9.9')->then(sub { push @failed, 'resolved' }, sub { push @failed, shift })
    } 1 .. 5)->wait;
    is($origin->count, 1, 'five concurrent lookups of a failing address send one request');
    is(scalar(grep { ref $_ && $_->kind eq 'server_error' } @failed), 5, 'and all five fail with its error');
    eval { $client->lookup('9.9.9.9') };
    is($origin->count, 2, 'the failure was not cached');

    # Without a cache every lookup is served, so nothing is shared.
    $origin->reset;
    my $uncached = InternetData->new(base_url => $origin->url, cache_size => 0);
    Mojo::Promise->all(map { $uncached->lookup_p('9.9.9.6') } 1 .. 5)->wait;
    is($origin->count, 5, 'a client with no cache shares nothing');
};

subtest 'the non-blocking API works where the blocking one cannot' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my $path = $c->req->url->path->to_string;
        return $c->render(json => InternetDataTest::asn()) if $path =~ m{^/asn/};
        return $c->render(json => InternetDataTest::domain()) if $path =~ m{^/domain/};
        $c->render(json => lookup_body(is_anycast => \1));
    });
    my $client = InternetData->new(base_url => $origin->url);

    my ($seen, $as, $domain);
    Mojo::Promise->all(
        $client->lookup_p('9.9.9.9')->then(sub { $seen = shift }),
        $client->lookup_asn_p(9009)->then(sub { $as = shift }),
        $client->lookup_domain_p('example.com')->then(sub { $domain = shift }),
    )->wait;
    is($seen->is_anycast, 1, 'lookup_p resolves with a result');
    is($as->name, 'M247 Europe SRL', 'lookup_asn_p with an AS answer');
    is($domain->is_registered, 1, 'lookup_domain_p with a domain answer');

    # Inside a running loop the blocking form cannot block, so it says so
    # instead of returning undef, and before a request is spent.
    $origin->reset;
    my %croaked;
    Mojo::IOLoop->next_tick(sub {
        for my $call (
            [lookup => sub { $client->lookup('1.2.3.4') }],
            [lookup_asn => sub { $client->lookup_asn(9009) }],
            [lookup_domain => sub { $client->lookup_domain('example.com') }],
            [lookup_batch => sub { $client->lookup_batch(['1.2.3.4']) }],
            [my_ip => sub { $client->my_ip }],
            [my_entitlement => sub { $client->my_entitlement }],
        ) {
            eval { $call->[1]->() };
            $croaked{ $call->[0] } = $@;
        }
        Mojo::IOLoop->stop;
    });
    Mojo::IOLoop->start;
    like($croaked{$_}, qr/call ${_}_p instead/, "$_ inside a running loop points at its promise form")
        for sort keys %croaked;
    is($origin->count, 0, 'and costs no request finding out');
};

subtest 'my_ip looks up the calling address and is never cached' => sub {
    # The cache is keyed by address, and which address this is IS the question:
    # a machine that moves between networks would otherwise be told where it
    # used to be.
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        is($c->req->url->path->to_string, '/myip', 'asked for the myip route');
        $c->render(json => lookup_body(ip => '45.83.91.1', is_anycast => \1));
    });
    my $client = InternetData->new(base_url => $origin->url);

    my $result = $client->my_ip;
    isa_ok($result, 'InternetData::Result');
    is($result->ip, '45.83.91.1', 'answers the observed address');
    ok($result->is_anycast, 'and looks it up');

    $client->my_ip;
    is($origin->count, 2, 'a second call goes to the network again');
};

subtest 'my_entitlement reports the plan and the usage, and is never cached' => sub {
    # The whole point is what has been spent, so a cached answer is a wrong one
    # within seconds of the next request.
    my $body = {
        org_id => '85bb51e4-2eb6-4a31-8e4d-02ba8b98fe61',
        apikey => { id => '0ab424cc-7619-4dad-b027-afacdc2cedb0', expires => undef, allowed_cidrs => [] },
        plan => { key => 'free', name => 'Unlimited', tier => 'free' },
        usage => {
            requests => 4, quota => 100, hard_limit => undef,
            window_start => '2026-11-13T00:00:00Z', window_end => '2026-11-14T00:00:00Z',
        },
    };
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        is($c->req->url->path->to_string, '/api/v1/entitlement', 'asked for the account route');
        $c->render(json => $body);
    });
    my $client = InternetData->new(base_url => $origin->url);

    my $account = $client->my_entitlement;
    is($account->{plan}{key}, 'free', 'reports the plan');
    is($account->{plan}{tier}, 'free', 'and the field tier');
    is($account->{plan}{name}, 'Unlimited', 'and the name to show');
    is($account->{usage}{requests}, 4, 'and what has been spent');
    is($account->{usage}{quota}, 100, 'and what the plan includes');
    # Undef means NEVER stop, which is not the same as a limit of zero.
    is($account->{usage}{hard_limit}, undef, 'a null hard limit stays null');
    is_deeply($account->{apikey}{allowed_cidrs}, [], 'an empty allowlist means unrestricted');

    $client->my_entitlement;
    is($origin->count, 2, 'a second call goes to the network again');
};

subtest 'my_entitlement surfaces an unauthorized key' => sub {
    # Unlike a lookup there is no useful unauthenticated answer.
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { error => 'an API key is required' }, status => 401);
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 0);

    eval { $client->my_entitlement };
    isa_ok($@, 'InternetData::Error', 'refused');
    is($@->kind, 'unauthorized', 'and says why');
    is($@->message, 'an API key is required', 'in the words of its error member');
};

subtest 'a 2xx a lookup cannot read as its answer is a retried server_error' => sub {
    my ($body, $type);
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->res->headers->content_type($type);
        $c->render(data => $body);
    });
    my $client = InternetData->new(base_url => $origin->url, retries => 0, cache_size => 0);
    my %calls = (
        lookup => sub { $client->lookup('9.9.9.9') },
        lookup_asn => sub { $client->lookup_asn(9009) },
        lookup_domain => sub { $client->lookup_domain('example.com') },
        my_ip => sub { $client->my_ip },
        my_entitlement => sub { $client->my_entitlement },
        lookup_batch => sub {
            my $answer = $client->lookup_batch(['9.9.9.9'])->{'9.9.9.9'};
            die $answer if Scalar::Util::blessed($answer) && $answer->isa('InternetData::Error');
            return $answer;
        },
    );
    for my $case (['<html>gateway</html>', 'text/html'], ['{"ip":', 'application/json'],
        ['', 'application/json'], ['[]', 'application/json'], ['null', 'application/json'],
        ['{}', 'application/json']) {
        ($body, $type) = @$case;
        for my $name (sort keys %calls) {
            my $error = eval { $calls{$name}->(); 1 } ? undef : $@;
            ok(ref $error && $error->isa('InternetData::Error'), "$name, '$body': raised an InternetData::Error")
                or next;
            is($error->kind, 'server_error', "$name, '$body': server_error");
            is($error->status, 200, "$name, '$body': carrying the status");
        }
    }
};

# Each of these is a member the spec types or requires, served otherwise, and
# every one came back as the answer before the shapes were checked.
subtest 'a member of the wrong type or a null is a retried server_error' => sub {
    my $entitlement = {
        org_id => 'o', apikey => { id => 'k', expires => undef, allowed_cidrs => [] },
        plan => { key => 'max', name => 'Max', tier => 'max' },
        usage => {
            requests => 1, quota => 10, hard_limit => undef,
            window_start => '2026-09-04T00:00:00Z', window_end => '2026-09-05T00:00:00Z',
        },
    };
    my $lookup = lookup_body();
    my %class = (provider => 'p', provider_name => 'P', confidence => 'high', last_seen => '2026-11-13');
    my @cases = (
        ['lookup, a flag of "yes"', 'lookup', { %$lookup, is_hosting => 'yes' }],
        ['lookup, a flag of 1', 'lookup', { %$lookup, is_tor => 1 }],
        ['lookup, is_bogon of null', 'lookup', { %$lookup, is_bogon => undef }],
        ['lookup, no is_anycast', 'lookup', { %$lookup, is_anycast => undef }],
        (map { (["lookup, $_ of null", 'lookup', { %$lookup, $_ => undef }],
            ["lookup, $_ of \"false\"", 'lookup', { %$lookup, $_ => 'false' }],
            ["lookup, $_ of 0", 'lookup', { %$lookup, $_ => 0 }]) } @InternetDataTest::PAID_FLAGS),
        ['lookup, an ASN type of null', 'lookup', { %$lookup, asn => { %{ $lookup->{asn} }, type => undef } }],
        ['lookup, an ASN type of 1', 'lookup', { %$lookup, asn => { %{ $lookup->{asn} }, type => 1 } }],
        ['lookup, an ASN without its prefix', 'lookup', { %$lookup, asn => { map { $_ => $lookup->{asn}{$_} } qw(asn name domain type) } }],
        ['lookup, a bot of "x"', 'lookup', { %$lookup, bot => 'x' }],
        ['lookup, a bot whose agents is a string', 'lookup', { %$lookup, bot => { agents => 'Googlebot' } }],
        ['lookup, a bot verified of "true"', 'lookup', { %$lookup, bot => { verified => 'true' } }],
        ['lookup, an empty object', 'lookup', {}],
        ['lookup, a detail of "x"', 'lookup', { %$lookup, vpn => 'x' }],
        ['lookup, no tor', 'lookup', { %$lookup, tor => undef }],
        ['lookup, a numeric string in a detail', 'lookup', { %$lookup, dcproxy => { %class, hits => '3', first_seen => '2026-11-01', hits_days_pct => 1, providers_num => 1 } }],
        ['lookup, a null protocol', 'lookup', { %$lookup, pubproxy => { entry => \1, exit => \0, protocols => [undef], num_ports => 1, num_proxies => 1, last_seen => '2026-11-13', last_usable => '' } }],
        ['lookup, web as an object', 'lookup', { %$lookup, web => {} }],
        ['lookup, an empty web server', 'lookup', { %$lookup, web => [{}] }],
        ['lookup, an AS number of "9009"', 'lookup', { %$lookup, asn => { %{ $lookup->{asn} }, asn => '9009' } }],
        ['lookup, a location without its country', 'lookup', { %$lookup, location => { continent => 'EU' } }],
        ['lookup, a latitude of "48.2"', 'lookup', { %$lookup, location => { %{ $lookup->{location} }, latitude => '48.2' } }],
        ['lookup, an accuracy radius of 1.5', 'lookup', { %$lookup, location => { %{ $lookup->{location} }, accuracy_radius => 1.5 } }],
        ['lookup, a company of no name', 'lookup', { %$lookup, company => { domain => 'd' } }],
        ['lookup, no hostname', 'lookup', { %$lookup, hostname => undef }],
        ['lookup, abuse validated of "false"', 'lookup', { %$lookup, abuse => { email => 'e', validated => 'false' } }],
        ['lookup, a whois of no asn', 'lookup', { %$lookup, whois => { map { ($_ => '') } qw(id name org country status source domain abuse_email) } }],
        ['lookup, hosted_domains of "3"', 'lookup', { %$lookup, hosted_domains => { total => '3' } }],
        ['lookup, trial_expired of "true"', 'lookup', { %$lookup, trial_expired => 'true' }],
        ['lookup, cap_reached of "true"', 'lookup', { %$lookup, cap_reached => 'true' }],
        ['my_ip, a flag of "yes"', 'my_ip', { %$lookup, is_relay => 'yes' }],
        ['lookup_asn, an AS number of "9009"', 'lookup_asn', InternetDataTest::asn(asn => '9009')],
        ['lookup_asn, no registry', 'lookup_asn', InternetDataTest::asn(registry => undef)],
        ['lookup_asn, num_ips of "1"', 'lookup_asn', InternetDataTest::asn(num_ips => '1')],
        ['lookup_asn, a rank of "341"', 'lookup_asn', InternetDataTest::asn(rank => '341')],
        ['lookup_asn, a tier1 of "false"', 'lookup_asn', InternetDataTest::asn(tier1 => 'false')],
        ['lookup_asn, a cap_reached of 1', 'lookup_asn', InternetDataTest::asn(cap_reached => 1)],
        ['lookup_asn, upstreams of ["174"]', 'lookup_asn', InternetDataTest::asn(upstreams => ['174'])],
        ['lookup_asn, downstreams of [null]', 'lookup_asn', InternetDataTest::asn(downstreams => [undef])],
        ['lookup_asn, hosted_domains without total', 'lookup_asn', InternetDataTest::asn(hosted_domains => { domains => [] })],
        ['lookup_asn, a whois value of 1', 'lookup_asn', InternetDataTest::asn(whois => { handle => 1 })],
        ['lookup_asn, a prefix missing its size', 'lookup_asn', InternetDataTest::asn(prefixes => [{
            prefix => 'p', peer_count => 1, rpki_status => 'valid', first_seen => '2026-10-02', country => 'RO', other_origins => [],
        }])],
        ['lookup_asn, another origin of "1"', 'lookup_asn', InternetDataTest::asn(prefixes => [{
            prefix => 'p', peer_count => 1, rpki_status => 'valid', first_seen => '2026-10-02', country => 'RO', size => 1,
            other_origins => ['1'],
        }])],
        ['lookup_domain, is_registered of null', 'lookup_domain', InternetDataTest::domain(is_registered => undef)],
        ['lookup_domain, has_mx of 1', 'lookup_domain', InternetDataTest::domain(has_mx => 1)],
        ['lookup_domain, a cap_reached of "false"', 'lookup_domain', InternetDataTest::domain(cap_reached => 'false')],
        ['lookup_domain, dns without cname', 'lookup_domain', InternetDataTest::domain(dns => { a => [], aaaa => [], mx => [], ns => [] })],
        ['lookup_domain, a range of no name', 'lookup_domain', InternetDataTest::domain(ip_ranges => {
            domain => 'd', redirects_to => '', total => 1, ipv4 => 256, ranges => [{ range => 'r', country => 'US' }],
        })],
        ['lookup_domain, a host without its asn', 'lookup_domain', InternetDataTest::domain(hosting => [{ ip => '192.0.2.10' }])],
        ['lookup_domain, a host asn of "64496"', 'lookup_domain', InternetDataTest::domain(hosting => [{ ip => '192.0.2.10', asn => '64496' }])],
        ['lookup_domain, hosting of [null]', 'lookup_domain', InternetDataTest::domain(hosting => [undef])],
        ['lookup_domain, a cohosted total of "3"', 'lookup_domain', InternetDataTest::domain(cohosted_domains => { ip => '', total => '3', domains => [] })],
        ['lookup_domain, cohosted domains of null', 'lookup_domain', InternetDataTest::domain(cohosted_domains => { ip => '', total => 3, domains => undef })],
        ['lookup_domain, a web without links', 'lookup_domain', InternetDataTest::domain(web => { url => '', title => '', description => '', last_seen => '' })],
        ['lookup_domain, a web last_seen of 20261118', 'lookup_domain', InternetDataTest::domain(web => {
            url => '', title => '', description => '', last_seen => 20261118, links => { total => 0, hosts => [] },
        })],
        ['lookup_domain, redirects of [1]', 'lookup_domain', InternetDataTest::domain(redirects => { total => 1, domains => [1] })],
        ['lookup_domain, backlinks without total', 'lookup_domain', InternetDataTest::domain(backlinks => { domains => [] })],
        ['my_entitlement, requests of "1"', 'my_entitlement', { %$entitlement, usage => { %{ $entitlement->{usage} }, requests => '1' } }],
        ['my_entitlement, a null CIDR', 'my_entitlement', { %$entitlement, apikey => { %{ $entitlement->{apikey} }, allowed_cidrs => [undef] } }],
        ['my_entitlement, an empty object', 'my_entitlement', {}],
        ['my_entitlement, a plan name of 1', 'my_entitlement', { %$entitlement, plan => { key => 'max', name => 1, tier => 'max' } }],
        ['my_entitlement, a plan without its name', 'my_entitlement', { %$entitlement, plan => { key => 'max', tier => 'max' } }],
    );
    my $body;
    my $origin = InternetDataTest::Origin->new(sub { $_[0]->render(json => $body) });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1, cache_size => 0);
    my %calls = (
        lookup => sub { $client->lookup('9.9.9.9') },
        my_ip => sub { $client->my_ip },
        lookup_asn => sub { $client->lookup_asn(9009) },
        lookup_domain => sub { $client->lookup_domain('example.com') },
        my_entitlement => sub { $client->my_entitlement },
    );
    for my $case (@cases) {
        my ($name, $call);
        ($name, $call, $body) = @$case;
        $origin->reset;
        my $answer = eval { $calls{$call}->() };
        my $error = $@;
        ok(!defined $answer, "$name: no answer");
        is(ref $error && $error->kind, 'server_error', "$name: a server_error");
        is(ref $error && $error->status, 200, "$name: carrying the status");
        is($origin->count, 2, "$name: retried");
    }

    # A detail requires no member, so `{}` under a false flag is an answer, and a
    # paid member may be absent from a shared object.
    $body = { %$lookup, hosting => {}, cdn => { %class }, vpn => { provider => 'p' }, web => [], whois => undef };
    my $read = eval { $client->lookup('9.9.9.9') };
    is($read && $read->cdn->{provider_name}, 'P', 'an empty detail and a whole one read');
    is_deeply($read && $read->vpn, { provider => 'p' }, 'and so does one short of members, as served');
    $body = InternetDataTest::domain(disposable => { confidence => 'high' }, is_disposable => \1);
    is_deeply(eval { $client->lookup_domain('example.com')->disposable }, { confidence => 'high' },
        'a domain detail too');
    $body = { %$lookup, location => { %{ $lookup->{location} }, latitude => 48, longitude => -16.37208 } };
    is(eval { $client->lookup('9.9.9.9')->location->{longitude} }, -16.37208, 'a coordinate is any JSON number');
    $body = InternetDataTest::domain(disposable => {}, is_disposable => \0);
    is(eval { $client->lookup_domain('example.com')->is_disposable }, 0, 'a domain answer reads');
};

# A seen day is `format: date`: RFC 3339's full-date on a day that exists. Each
# of these came back as served while the shapes typed it a string.
subtest 'a seen day that is no full-date is a retried server_error' => sub {
    my $lookup = lookup_body();
    my $web = {
        port => 443, tls_ok => \1, session_ok => \1, status_code => 200,
        (map { ($_ => '') } qw(server location title cert_subject_cn cert_subject_o cert_issuer_dn)),
        cert_browser_trusted => \1, tls_version => 'TLSv1.3', first_seen => '2026-02-30', last_seen => '2026-11-12',
    };
    my $prefix = {
        prefix => 'p', peer_count => 1, rpki_status => 'valid', first_seen => '2026-10-2', country => 'RO', size => 1,
        other_origins => [],
    };
    my @cases = (
        ['vpn.last_seen', 'lookup', { %$lookup, vpn => { last_seen => '2026-1-05' } }],
        ['tor.last_seen', 'lookup', { %$lookup, tor => { last_seen => 'tomorrow' } }],
        ['resproxy.first_seen', 'lookup', { %$lookup, resproxy => { first_seen => '2026-11-23T00:00:00Z' } }],
        ['pubproxy.last_seen', 'lookup', { %$lookup, pubproxy => { last_seen => ' 2026-11-12' } }],
        ['bot.last_seen', 'lookup', { %$lookup, bot => { last_seen => "2026-11-12\n" } }],
        ['ssh.first_seen', 'lookup', { %$lookup, ssh => { first_seen => '2026-13-01' } }],
        ['smtp.last_seen', 'lookup', { %$lookup, smtp => { last_seen => '20261112' } }],
        ['web.0.first_seen', 'lookup', { %$lookup, web => [$web] }],
        ['dns_resolver.first_seen', 'lookup', { %$lookup, dns_resolver => { first_seen => "2026-11-1\x{0662}" } }],
        ['bittorrent.last_seen', 'lookup', { %$lookup, bittorrent => { last_seen => '2025-02-29' } }],
        ['my_ip, hosting.last_seen', 'my_ip', { %$lookup, hosting => { last_seen => 'monday' } }],
        ['prefixes.0.first_seen', 'lookup_asn', InternetDataTest::asn(prefixes => [$prefix])],
        ['dns.a.0.last_seen', 'lookup_domain', InternetDataTest::domain(dns => {
            a => [{ ip => '192.0.2.1', last_seen => '2026-11-01T00:00:00Z' }], aaaa => [], mx => [], ns => [], cname => [],
        })],
        ['dns.mx.0.last_seen', 'lookup_domain', InternetDataTest::domain(dns => {
            a => [], aaaa => [], mx => [{ priority => 10, host => 'm', last_seen => 'x' }], ns => [], cname => [],
        })],
        ['disposable.first_seen', 'lookup_domain', InternetDataTest::domain(is_disposable => \1, disposable => { first_seen => '2026-02-29' })],
    );
    my $body;
    my $origin = InternetDataTest::Origin->new(sub { $_[0]->render(json => $body) });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1, cache_size => 0);
    my %calls = (
        lookup => sub { $client->lookup('9.9.9.9') },
        my_ip => sub { $client->my_ip },
        lookup_asn => sub { $client->lookup_asn(9009) },
        lookup_domain => sub { $client->lookup_domain('example.com') },
    );
    for my $case (@cases) {
        my ($name, $call);
        ($name, $call, $body) = @$case;
        $origin->reset;
        my $answer = eval { $calls{$call}->() };
        my $error = $@;
        ok(!defined $answer, "$name: no answer");
        is(ref $error && $error->kind, 'server_error', "$name: a server_error");
        is(ref $error && $error->status, 200, "$name: carrying the status");
        is($origin->count, 2, "$name: retried");
    }

    my $batch = InternetDataTest::Origin->new(sub { $_[0]->render(json => { results => {
        '9.9.9.1' => lookup_body(ip => '9.9.9.1', vpn => { last_seen => '2026-02-30' }),
        '9.9.9.2' => lookup_body(ip => '9.9.9.2', vpn => { last_seen => '2024-02-29' }),
    }, errors => {} }) });
    my $answers = InternetData->new(base_url => $batch->url, retries => 1, cache_size => 0)
        ->lookup_batch(['9.9.9.1', '9.9.9.2']);
    isa_ok($answers->{'9.9.9.1'}, 'InternetData::Error', 'a batch entry with a malformed seen day');
    is($answers->{'9.9.9.2'}->vpn->{last_seen}, '2024-02-29', 'and its neighbor, on a leap day, reads as served');
};

# A batch entry of the wrong type came back as a result, and an error entry whose
# status was "400" as an error of no known kind, until each entry was judged.
subtest 'a batch entry of the wrong type is that address error alone' => sub {
    my %results = (
        '9.9.9.1' => lookup_body(ip => '9.9.9.1', is_cdn => 'yes'),
        '9.9.9.2' => lookup_body(ip => '9.9.9.2', hosted_domains => { total => '3' }),
        '9.9.9.3' => lookup_body(ip => '9.9.9.3', is_bogon => undef),
        '1.1.1.1' => lookup_body(ip => '1.1.1.1', pubproxy => {}),
    );
    my %errors = ('9.9.9.4' => { status => '400', error => 'bad' }, '9.9.9.5' => { status => 400, error => undef });
    my $origin = InternetDataTest::Origin->new(sub { $_[0]->render(json => { results => \%results, errors => \%errors }) });
    my $client = InternetData->new(base_url => $origin->url, retries => 1, cache_size => 0);
    my $answers = $client->lookup_batch([sort(keys %results, keys %errors)]);

    is($answers->{'1.1.1.1'}->ip, '1.1.1.1', 'the readable entry is the answer');
    for my $ip (qw(9.9.9.1 9.9.9.2 9.9.9.3 9.9.9.4 9.9.9.5)) {
        isa_ok($answers->{$ip}, 'InternetData::Error', $ip);
        is($answers->{$ip}->kind, 'server_error', "$ip: a server_error");
        is($answers->{$ip}->status, 200, "$ip: carrying the status");
    }
    is($origin->count, 1, 'one unreadable entry does not retry the chunk');

    my $empty = InternetDataTest::Origin->new(sub { $_[0]->render(json => {}) });
    $answers = InternetData->new(base_url => $empty->url, retries => 1, cache_size => 0)->lookup_batch(['9.9.9.9']);
    is($answers->{'9.9.9.9'}->kind, 'server_error', 'a chunk of {} is unreadable');
    is($empty->count, 2, 'and retried as a whole');
};

subtest 'an entitlement date-time that is not RFC 3339 is a retried server_error' => sub {
    my $body;
    my $origin = InternetDataTest::Origin->new(sub { $_[0]->render(json => $body) });
    my $entitlement = {
        org_id => 'o', apikey => { id => 'k', expires => '2026-10-05T10:00:00Z', allowed_cidrs => [] },
        plan => { key => 'max', name => 'Max', tier => 'max' },
        usage => {
            requests => 1, quota => 10, hard_limit => undef,
            window_start => '2026-10-05T10:00:00Z', window_end => '2026-10-05T10:00:00Z',
        },
    };
    my @bad = ('x', '2026-02-30T10:00:00Z', '2026-10-05T24:00:00Z', '2026-10-05T10:00:00', '2026-10-05',
        "2026-10-05T10:00:00Z\n", '1759658400');
    my $shown = sub { Data::Dumper->new([shift])->Useqq(1)->Terse(1)->Indent(0)->Dump };
    for my $path (['apikey', 'expires'], ['usage', 'window_start'], ['usage', 'window_end']) {
        for my $value (@bad, '2026-10-05t10:00:00.5z') {
            $body = Storable::dclone($entitlement);
            $body->{ $path->[0] }{ $path->[1] } = $value;
            $origin->reset;
            my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1);
            my $answer = eval { $client->my_entitlement };
            my $error = $@;
            my $good = $value =~ /z\z/;
            my $outcome = $answer ? 'read' : ref $error ? $error->kind . ' ' . $error->status : "$error";
            is("$outcome after " . $origin->count, $good ? 'read after 1' : 'server_error 200 after 2',
                join('.', @$path) . ' of ' . $shown->($value));
        }
    }
};

# Anything that died after an address boarded left its flight on the board, and
# every later lookup of the address would wait forever.
subtest 'a lookup that dies before its request leaves no flight behind' => sub {
    {
        package InternetDataTest::DyingAgent;
        use parent -norequire, 'Mojo::UserAgent';
        sub build_tx { die "no agent\n" }
    }
    my $client = InternetData->new(ua => InternetDataTest::DyingAgent->new, retries => 0);
    ok(!eval { $client->lookup_p('9.9.9.9'); 1 }, 'the first lookup dies');
    my $settled = 0;
    my $second = eval { $client->lookup_p('9.9.9.9') };
    $second->then(sub { $settled = 1 }, sub { $settled = 2 }) if $second;
    Mojo::Promise->timer(0.2)->wait;
    ok(!$second || $settled, 'the second is not left waiting on the first');
};

# NaN compares false with anything, so a NaN retries retried a failing call for
# good and a NaN concurrency put no chunk in flight, spinning the loop forever and
# holding its addresses from every later lookup on the client; a word reads as 0
# and 1.5 as two retries. A bogon, a cache hit and a bogon-only batch must refuse
# them too.
subtest 'a retry count or a concurrency that cannot work is refused where it is set' => sub {
    # A 404 is never retried, so a value that slips through fails its assertion
    # rather than retrying for good.
    my $status = 404;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        return $c->render(json => lookup_body(ip => '9.9.9.8')) if $status == 200;
        $c->render(json => { error => 'gone' }, status => $status);
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0);
    my %calls = (
        lookup => sub { $client->lookup('9.9.9.9', @_) },
        'lookup of a bogon' => sub { $client->lookup('10.0.0.1', @_) },
        'lookup of a cached address' => sub { $client->lookup('9.9.9.8', @_) },
        lookup_asn => sub { $client->lookup_asn(9009, @_) },
        lookup_domain => sub { $client->lookup_domain('example.com', @_) },
        my_ip => sub { $client->my_ip(@_) },
        my_entitlement => sub { $client->my_entitlement(@_) },
        lookup_batch => sub { $client->lookup_batch(['9.9.9.9'], @_) },
        'lookup_batch of a bogon' => sub { $client->lookup_batch(['10.0.0.1'], @_) },
    );
    $status = 200;
    $client->lookup('9.9.9.8');
    $status = 404;
    $origin->reset;

    for my $bad (-1, 'nan', -9**9**9, 1.5, 'two', '', [2]) {
        my $shown = ref $bad ? 'a reference' : "'$bad'";
        for my $name (sort keys %calls) {
            ok(!eval { $calls{$name}->(retries => $bad); 1 }, "$name refuses retries => $shown");
            like($@, qr/retries must be a whole number, 0 or more/, 'naming the cause');
        }
    }
    for my $bad (0, -1, 'nan', 1.5, 'two', '', [2]) {
        my $shown = ref $bad ? 'a reference' : "'$bad'";
        ok(!eval { InternetData->new(concurrency => $bad); 1 }, "new refuses concurrency => $shown");
        like($@, qr/InternetData->new: concurrency must be a whole number, 1 or more/, 'naming the cause');
        for my $ips (['9.9.9.9'], ['10.0.0.1']) {
            # A client of its own, raced against a timer: accepted, NaN would be a
            # batch that never ends, holding its addresses from every later lookup.
            my $batcher = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0);
            my $batch = eval { $batcher->lookup_batch_p($ips, concurrency => $bad) };
            like($@, qr/concurrency must be a whole number, 1 or more/, "lookup_batch of $ips->[0] refuses concurrency => $shown");
            Mojo::Promise->race($batch, Mojo::Promise->timer(1))->wait if $batch;
        }
    }
    is($origin->count, 0, 'and not one request was spent finding out');

    # Inf is no limit, and a whole number in any spelling Perl reads as one is that number.
    my $unbounded = eval { InternetData->new(base_url => $origin->url, retries => 9**9**9, concurrency => 9**9**9) };
    ok($unbounded, 'new takes Inf for both');
    eval { $client->lookup('9.9.9.9', retries => '2') };
    is(ref $@ && $@->kind, 'bad_request', 'a count written as a string reads');
    is($client->lookup_batch(['9.9.9.9', '9.9.9.7'], concurrency => '1e0')->{'9.9.9.9'}->kind, 'bad_request',
        'and so does one written with an exponent');
};

subtest 'the lookups answer on api.internetdata.io unless told otherwise' => sub {
    my @urls;
    my $ua = Mojo::UserAgent->new;
    $ua->on(start => sub { push @urls, $_[1]->req->url->to_string; die "recorded\n" });
    my $client = InternetData->new(ua => $ua, retries => 0, cache_size => 0);
    eval { $client->lookup('9.9.9.9') };
    eval { $client->database->list };
    is_deeply(\@urls, ['https://api.internetdata.io/9.9.9.9', 'https://api.internetdata.io/api/v2/database/list'],
        'the lookups and the database calls alike');
};

done_testing();
