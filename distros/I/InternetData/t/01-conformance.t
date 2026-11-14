use strict;
use warnings;

use lib 't/lib';

use Scalar::Util ();
use Test::More;
use InternetData;
use InternetData::Error;
use InternetDataTest;
use InternetDataTest::Origin;

# The shared conformance corpus, asserted by every InternetData SDK in the same
# terms, so a Perl-only drift fails here rather than surfacing as two client
# libraries quietly disagreeing about one refusal.
my $corpus = InternetDataTest::corpus();

my $route = {};
my $origin = InternetDataTest::Origin->new(sub {
    my ($c) = @_;
    $c->res->headers->header($_ => $route->{headers}{$_}) for keys %{ $route->{headers} || {} };
    $c->render(json => $route->{body}, status => $route->{status} || 200);
});

sub client {
    return InternetData->new(base_url => $origin->url, api_key => 'k', @_);
}

sub serve {
    ($route) = @_;
    $origin->reset;
}

subtest 'every refusal in the corpus maps the same way here as everywhere else' => sub {
    ok(@{ $corpus->{errors} }, 'the corpus carries error cases at all');

    for my $case (@{ $corpus->{errors} }) {
        # Both call shapes: a JSON endpoint and the redirect endpoint classify
        # their own responses, so a fix applied to one and not the other is
        # exactly the drift this corpus exists to catch.
        for my $call (
            ['lookup', sub { $_[0]->lookup('9.9.9.9') }],
            ['list', sub { $_[0]->database->list }],
            ['download_url', sub { $_[0]->database->download_url('bogon_ip_v1', 'csvgz') }],
        ) {
            my ($name, $run) = @$call;
            serve($case);
            # No retries, so a retryable failure surfaces rather than looping.
            my $answer = eval { $run->(client(retries => 0)) };
            my $error = $@;

            ok(!defined $answer, "$case->{name} via $name: the call failed");
            isa_ok($error, 'InternetData::Error', "$case->{name} via $name: error type");
            is($error->kind, $case->{expect}{kind}, "$case->{name} via $name: kind");
            is($error->retryable, $case->{expect}{retryable} ? 1 : 0,
                "$case->{name} via $name: retryable");
            is($error->status, $case->{status}, "$case->{name} via $name: status");
            # The API says WHICH refusal this is, under `error` for a lookup and
            # `rc` for a database. Falling back to the status means the envelope
            # went unread, and NOT_LICENSED and LICENSE_EXPIRED are both 403.
            is($error->message, $case->{expect}{message}, "$case->{name} via $name: message")
                if defined $case->{expect}{message};
            is($error->retry_after, $case->{expect}{retryAfterSeconds},
                "$case->{name} via $name: retry_after")
                if defined $case->{expect}{retryAfterSeconds};
            is($origin->count, 1, "$case->{name} via $name: asked exactly once");
        }
    }
};

subtest 'a 4xx is never retried and a 5xx is' => sub {
    # The half of the classification a single-attempt test cannot see: `kind` can
    # be right while the retry rule reads something else entirely.
    for my $case (@{ $corpus->{errors} }) {
        serve($case);
        # Retry-After is 2 seconds in the corpus, which would make this test
        # sleep. Retried at all is what is being measured, so the header is
        # overridden to 0 while the classification above keeps the real value.
        $route->{headers} = { 'retry-after' => 0 } if $case->{expect}{retryable}
            && defined $case->{expect}{retryAfterSeconds};

        my $want = $case->{expect}{retryable} ? 3 : 1;
        for my $call (['lookup', sub { $_[0]->lookup('9.9.9.9') }], ['list', sub { $_[0]->database->list }]) {
            $origin->reset;
            eval { $call->[1]->(client(retries => 2)) };
            is($origin->count, $want, "$case->{name} via $call->[0]: $want attempt(s)");
        }
    }
};

subtest 'a listing survives every standing, right and format the API publishes' => sub {
    my @families;
    for my $standing (@{ $corpus->{standings} }) {
        for my $right (@{ $corpus->{license_type} }) {
            push @families, InternetDataTest::family(
                base => "${standing}_${right}",
                standing => $standing,
                license_type => $standing eq 'unlicensed' ? undef : $right,
                versions => [{
                    id => "${standing}_${right}_v1", version => 1, summary => 'x',
                    formats => $corpus->{formats},
                }],
            );
        }
    }
    serve({ body => { databases => \@families } });

    my $databases = client()->database->list;

    is_deeply($databases, \@families, 'the catalog arrives exactly as served');
    is(scalar @$databases, scalar @families, 'nothing was dropped');
    for my $db (@$databases) {
        ok(grep({ $_ eq $db->{standing} } @{ $corpus->{standings} }),
            "$db->{base}: standing survived");
        is_deeply($db->{versions}[0]{formats}, $corpus->{formats},
            "$db->{base}: the formats it is built in survived");
    }
    # An unlicensed family has no license, so it has no license_type right;
    # inventing one would tell a caller they may redistribute something they do
    # not hold.
    my ($unlicensed) = grep { $_->{standing} eq 'unlicensed' } @$databases;
    is($unlicensed->{license_type}, undef, 'an unlicensed family carries no right');
};

# The visibility contract, as the corpus states it: a family built for a single
# customer is ABSENT from a listing for anyone else, rather than present with an
# `unlicensed` standing. The server enforces that, and the only way a client can
# undermine it is by answering `list` from something other than this key's
# response - a bundled catalog, or a listing held from another key.
#
# The corpus names the rules but deliberately NOT the private IDs, because it is
# committed into public repositories. So each rule ID gets a handler here, and a
# rule with no handler is a failure rather than a silent gap.
my %VISIBILITY = (
    'listing-is-returned-as-served' => sub {
        my @served = (
            InternetDataTest::family(base => 'one'),
            InternetDataTest::family(base => 'two', standing => 'unlicensed', license_type => undef),
        );
        serve({ body => { databases => \@served } });

        my $databases = client()->database->list;

        is_deeply($databases, \@served, 'the listing arrives exactly as served');
        is(scalar @$databases, scalar @served, 'nothing added and nothing dropped');

        # An empty listing is an answer, not a prompt to fill one in.
        serve({ body => { databases => [] } });
        is_deeply(client()->database->list, [], 'and an empty catalog stays empty');
    },

    'no-catalog-is-compiled-into-the-client' => sub {
        # Structural, not behavioural: a client that ships a list of database IDs
        # can answer from it under some future edit, and no request-counting test
        # would see that until it did. The modules as SHIPPED must name none.
        my $loaded = $INC{'InternetData.pm'};
        ok($loaded, 'the module under test was located') or return;
        (my $dir = $loaded) =~ s{\.pm\z}{};

        for my $file ($loaded, sort glob "$dir/*.pm") {
            open my $fh, '<', $file or do { fail("cannot read $file: $!"); next };
            my $line = 0;
            my @found;
            while (my $text = <$fh>) {
                $line++;
                # Documentation may name public examples; only executable code is
                # the claim being made here.
                last if $text =~ /\A__END__/;
                next if $text =~ /\A\s*#/;
                push @found, "$line: $text" if $text =~ /["'][a-z][a-z0-9_]*_v[0-9]+["']/;
            }
            is_deeply(\@found, [], "$file compiles in no database ID");
        }
    },

    'a-listing-is-never-reused-across-clients' => sub {
        serve({ body => { databases => [InternetDataTest::family()] } });

        # Two keys can be on different licenses and entitled to see different
        # families, so a listing held from one is not an answer for the other.
        client(api_key => 'key-a')->database->list;
        client(api_key => 'key-b')->database->list;
        is($origin->count, 2, 'each client asked the server for itself');

        # And a second call on ONE client asks again: a catalog held across a
        # license change is the same disclosure with a slower fuse.
        $origin->reset;
        my $one = client(api_key => 'key-a');
        $one->database->list;
        $one->database->list;
        is($origin->count, 2, 'nothing is cached, so a listing is never stale');
    },
);

subtest 'the catalog is the server answer for THIS key, and nothing else' => sub {
    my @rules = @{ $corpus->{visibility}{clientRules} };
    ok(@rules, 'the corpus states visibility rules at all');

    for my $rule (@rules) {
        # A rule the corpus grew and this suite never noticed would otherwise
        # pass by saying nothing.
        my $handler = $VISIBILITY{$rule};
        ok($handler, "$rule: this suite has a handler for it") or next;
        subtest $rule => $handler;
    }
};

# The lookups, answered from a table of routes keyed by path the way the API
# answers them: a POST /batch answers every address the table knows as a result
# if its route is a 200 and as an entry error otherwise, and an unknown one as
# the 400 the API gives a string it cannot read. One call however many
# addresses, which is what the request counts measure.
my (%routes, @batch_sizes, @batch_sent);
my $lookups = InternetDataTest::Origin->new(sub {
    my ($c) = @_;
    my $path = $c->req->url->path->to_string;
    if ($path eq '/batch') {
        push @batch_sizes, scalar @{ $c->req->json->{ips} || [] };
        push @batch_sent, @{ $c->req->json->{ips} || [] };
        return $c->render(json => batch_answer($c->req->json));
    }
    my $route = $routes{$path};
    return $c->render(json => { error => 'not a valid IP address, AS number or domain' }, status => 400)
        unless $route;
    $c->res->headers->header($_ => $route->{headers}{$_}) for keys %{ $route->{headers} || {} };
    $c->render(json => $route->{body}, status => $route->{status} || 200);
});

sub batch_answer {
    my ($body) = @_;
    my $ips = ref $body eq 'HASH' && ref $body->{ips} eq 'ARRAY' ? $body->{ips} : [];
    my (%results, %errors);
    for my $ip (@$ips) {
        my $route = $routes{"/$ip"};
        if (!$route) {
            $errors{$ip} = { status => 400, error => 'not a valid IP address, AS number or domain' };
        }
        elsif (($route->{status} || 200) == 200) {
            $results{$ip} = $route->{body};
        }
        else {
            $errors{$ip} = { status => $route->{status}, error => $route->{body}{error} };
        }
    }
    return { results => \%results, errors => \%errors };
}

sub lookups {
    return InternetData->new(base_url => $lookups->url, @_);
}

sub answer {
    %routes = ();
    @batch_sizes = ();
    @batch_sent = ();
    for my $route (@_) {
        $routes{ $route->{path} // "/$route->{ip}" } = $route;
    }
    $lookups->reset;
}

sub plain {
    my ($ip) = @_;
    return { ip => $ip, body => InternetDataTest::lookup(ip => $ip) };
}

# A served boolean reads as 1 or 0, as every flag does, and anything else as
# served.
sub reads_as {
    my ($value) = @_;
    return Scalar::Util::blessed($value) && $value->isa('JSON::PP::Boolean') ? ($value ? 1 : 0) : $value;
}

subtest 'a bogon is answered locally in the widest shape' => sub {
    answer();
    # Evaluated, so a bogon that reached the network fails at the count rather
    # than ending the file with the refusal the origin gives it.
    my $result = eval { lookups()->lookup('10.0.0.1') };
    my $bogon = $corpus->{bogonResponse};

    is($lookups->count, 0, 'a bogon must not reach the network');
    ok($result, 'and is answered') or return;
    is($result->ip, '10.0.0.1', 'the address comes back');
    is($result->is_bogon, 1, 'marked as reserved');
    for my $flag (@{ $bogon->{flagsFalse} }) {
        ok($result->has($flag), "$flag is present");
        is($result->$flag, 0, "$flag is false");
    }
    for my $object (@{ $bogon->{emptyObjects} }) {
        ok($result->has($object), "$object is present");
        is_deeply($result->$object, {}, "$object is empty");
    }
    for my $list (@{ $bogon->{emptyLists} }) {
        ok($result->has($list), "$list is present");
        is_deeply($result->$list, [], "$list is empty");
    }
    for my $object (qw(location asn company abuse whois rwhois)) {
        ok($result->has($object), "$object is present");
        is_deeply($result->$object, $bogon->{$object}, "$object carries every key, empty");
    }
    is($result->hostname, $bogon->{hostname}, 'hostname is empty');
    is_deeply($result->hosted_domains, $bogon->{hostedDomains}, 'hosted_domains is 0');
    my %want = map { ($_ => reads_as($bogon->{answer}{$_})) } keys %{ $bogon->{answer} };
    my %got = %$result;
    delete $got{_raw};
    is_deeply(\%got, { %want, ip => '10.0.0.1' }, 'the whole answer is the corpus answer, the address filled in');
};

subtest 'a lookup keeps absent apart from false across every plan shape' => sub {
    my %calls = (
        lookup => ['', sub { $_[0]->lookup($_[1]) }],
        lookupAsn => ['/asn', sub { $_[0]->lookup_asn($_[1]) }],
        lookupDomain => ['/domain', sub { $_[0]->lookup_domain($_[1]) }],
    );
    ok(@{ $corpus->{lookup} }, 'the corpus carries lookup cases at all');
    for my $case (@{ $corpus->{lookup} }) {
        my ($prefix, $run) = @{ $calls{ $case->{call} } || [] };
        ok($run, "$case->{name}: this suite knows the call $case->{call}") or next;
        answer({ path => "$prefix/$case->{target}", status => $case->{status}, body => $case->{body} });
        my $result = eval { $run->(lookups(), $case->{target}) };
        ok($result, "$case->{name}: answered") or do { diag("$@"); next };
        my $expect = $case->{expect};

        is_deeply([$lookups->paths], ["$prefix/$case->{target}"], "$case->{name}: asked once, on its route");
        for my $field (sort keys %{ $expect->{present} || {} }) {
            ok($result->has($field), "$case->{name}: $field was served");
            is($result->$field, reads_as($expect->{present}{$field}), "$case->{name}: $field as served");
        }
        for my $field (@{ $expect->{objects} || [] }) {
            ok($result->has($field), "$case->{name}: $field was served");
            like(ref $result->$field, qr/\A(?:HASH|ARRAY)\z/, "$case->{name}: $field is an object or a list");
        }
        for my $field (@{ $expect->{empty} || [] }) {
            my $value = $result->$field;
            ok(ref $value eq 'HASH' ? !%$value : ref $value eq 'ARRAY' && !@$value,
                "$case->{name}: $field is present and empty");
        }
        for my $field (@{ $expect->{absent} || [] }) {
            is($result->has($field), 0, "$case->{name}: $field is ABSENT, not false");
            is($result->$field, undef, "$case->{name}: $field reads as undef");
            ok(!exists $result->{$field}, "$case->{name}: $field has no key at all");
        }
        for my $object (sort keys %{ $expect->{absentIn} || {} }) {
            for my $member (@{ $expect->{absentIn}{$object} }) {
                ok(!exists $result->$object->{$member}, "$case->{name}: $object.$member is ABSENT, not empty");
            }
        }
        # Nothing served is lost or reshaped on the way to the caller.
        for my $field (sort keys %{ $case->{body} }) {
            is_deeply($result->$field, reads_as($case->{body}{$field}), "$case->{name}: $field reads as served");
        }
    }
};

subtest 'batch dedupes, short-circuits bogons and keys by address' => sub {
    my $case = InternetDataTest::batch_case('dedup-bogon-and-order-free-keying');
    answer(plain('1.1.1.1'), plain('8.8.8.8'));
    my $answers = lookups()->lookup_batch($case->{input});

    # Perl hashes carry no insertion order, so the corpus's key claim is a SET.
    is_deeply([sort keys %$answers], [sort @{ $case->{expect}{keys} }], 'keyed by address');
    is($lookups->count, $case->{expect}{httpRequests}, 'duplicates collapsed to one request');
    # The keys collapse duplicates whatever was sent, and one chunk is one request
    # however many times an address is in it, so only the body shows a duplicate.
    is_deeply([sort @batch_sent], ['1.1.1.1', '8.8.8.8'], 'carrying each servable address once');
    for my $ip (@{ $case->{expect}{bogonKeys} }) {
        is($answers->{$ip}->is_bogon, 1, "$ip was answered locally");
    }
};

subtest 'one bad address does not lose the rest of the batch' => sub {
    my $case = InternetDataTest::batch_case('partial-failure-does-not-fail-the-batch');
    answer(plain('1.1.1.1'));
    my $answers = lookups(retries => 0)->lookup_batch($case->{input});

    is_deeply([sort keys %$answers], [sort @{ $case->{expect}{keys} }], 'every address is keyed');
    for my $ip (@{ $case->{expect}{errorKeys} }) {
        isa_ok($answers->{$ip}, 'InternetData::Error', "$ip carries its error");
        is($answers->{$ip}->kind, $case->{expect}{errorKinds}{$ip}, "$ip is $case->{expect}{errorKinds}{$ip}");
    }
    is($answers->{'1.1.1.1'}->ip, '1.1.1.1', 'the good address still answered');
};

subtest 'a cache hit issues no second request' => sub {
    my $case = InternetDataTest::batch_case('cache-hit-issues-no-second-request');
    answer(plain('1.1.1.1'));
    my $client = lookups();
    $client->lookup_batch($case->{input}) for 1 .. $case->{repeat};

    is($lookups->count, $case->{expect}{httpRequests}, 'the second batch was served from cache');
};

subtest 'a large batch is sent in chunks of a thousand' => sub {
    my $case = InternetDataTest::batch_case('chunks-of-one-thousand');
    answer(map { plain($_) } @{ $case->{input} });
    my $answers = lookups(cache_size => 0)->lookup_batch($case->{input});

    is(scalar keys %$answers, $case->{expect}{keyCount}, 'every address is keyed once');
    is($lookups->count, $case->{expect}{httpRequests}, 'one request per chunk of 1000');
    is($answers->{$_}->ip, $_, "$_ answered for itself") for @{ $case->{input} }[0, 999, 1000];
};

subtest 'an uncapped batch is chunked and answers every address once' => sub {
    # Chunking to the endpoint's 1000 is the library's job, so a batch has no cap
    # of its own: never a refusal, and one POST per chunk.
    my $case = InternetDataTest::batch_case('uncapped-input-is-chunked');
    answer(map { plain($_) } @{ $case->{input} });
    my $answers = eval { lookups(cache_size => 0)->lookup_batch($case->{input}) } || {};

    is($@, '', 'the batch is not refused');
    is_deeply([$lookups->paths], [('/batch') x $case->{expect}{httpRequests}], 'one POST per chunk');
    is_deeply([sort { $a <=> $b } @batch_sizes], [500, 1000, 1000], 'of at most 1000 addresses each');
    is(scalar keys %$answers, $case->{expect}{keyCount}, 'every address is keyed once');
    my @answered = grep {
        ref $answers->{$_} eq 'InternetData::Result' && $answers->{$_}->ip eq $_
    } @{ $case->{input} };
    is(scalar @answered, $case->{expect}{keyCount}, 'each one answered for itself');
};

# A per-entry failure carries no headers, so its 429 can only be a spent
# allowance, and a 500 is the server's; neither is retried per entry, because
# retries belong to the call and the call succeeded.
subtest 'an entry error is classified by its status' => sub {
    my $case = InternetDataTest::batch_case('an-entry-error-is-classified-by-its-status');
    answer(
        plain('1.1.1.1'),
        { ip => '8.8.8.8', status => 429, body => { error => 'overage cap reached; raise or remove it in Billing' } },
        { ip => '9.9.9.9', status => 500, body => { error => 'lookup failed' } },
    );
    my $answers = lookups(retries => 3)->lookup_batch($case->{input});

    is_deeply([sort keys %$answers], [sort @{ $case->{expect}{keys} }], 'every address is keyed');
    for my $ip (sort keys %{ $case->{expect}{errorKinds} }) {
        isa_ok($answers->{$ip}, 'InternetData::Error', "$ip carries its error");
        is($answers->{$ip}->kind, $case->{expect}{errorKinds}{$ip}, "$ip is $case->{expect}{errorKinds}{$ip}");
        is($answers->{$ip}->status, $routes{"/$ip"}{status}, "$ip keeps the status its entry gave");
        is($answers->{$ip}->message, $routes{"/$ip"}{body}{error}, "$ip says why in the entry's words");
    }
    is($lookups->count, $case->{expect}{httpRequests}, 'the call was made once and no entry was retried');
};

subtest 'two clients never share a cached answer' => sub {
    answer(plain('1.1.1.1'));
    lookups(api_key => 'key-a')->lookup('1.1.1.1');
    lookups(api_key => 'key-b')->lookup('1.1.1.1');

    # Two keys can be on different plans and so entitled to different fields; a
    # shared cache would serve one of them the other's shape.
    is($lookups->count, 2, 'each client asked for itself');
};

subtest 'caching can be turned off' => sub {
    answer(plain('1.1.1.1'));
    my $client = lookups(cache_size => 0);
    $client->lookup('1.1.1.1');
    $client->lookup('1.1.1.1');

    is($lookups->count, 2, 'cache_size 0 disables the cache');
};

subtest 'an error is never cached' => sub {
    answer({ ip => '1.1.1.1', status => 500, body => { error => 'lookup failed' } });
    my $client = lookups(retries => 0);
    eval { $client->lookup('1.1.1.1') };
    eval { $client->lookup('1.1.1.1') };

    is($lookups->count, 2, 'the second call asked again');
};

subtest 'an AS or a domain answer is never cached' => sub {
    answer({ path => '/asn/9009', body => InternetDataTest::asn() },
        { path => '/domain/example.com', body => InternetDataTest::domain() });
    my $client = lookups();
    $client->lookup_asn(9009) for 1 .. 2;
    $client->lookup_domain('example.com') for 1 .. 2;

    is_deeply([$lookups->paths], ['/asn/9009', '/asn/9009', '/domain/example.com', '/domain/example.com'],
        'each call asked again');
};

# A server listening on :: sees every IPv4 visitor as ::ffff:a.b.c.d. Read whole
# that is inside ::ffff:0:0/96, so an SDK that did not unmap answered each one
# locally as a bogon and never asked.
subtest 'an IPv4-mapped address is the IPv4 address it carries' => sub {
    for my $case (@{ $corpus->{ipv4Mapped} }) {
        my ($ip, $carries) = @$case{qw(ip carries)};
        answer({ ip => $carries, body => InternetDataTest::lookup(ip => $carries, is_anycast => \1) });
        my $client = lookups();
        is($client->is_bogon($ip), $case->{expect} ? 1 : 0, "$ip: is_bogon ($case->{why})");

        my $result = eval { $client->lookup($ip) };
        is($result && $result->ip, $carries, "$ip: the answer names $carries");
        if ($case->{expect}) {
            is($result && $result->is_bogon, 1, "$ip: answered locally");
            is($lookups->count, 0, "$ip: with no request");
            next;
        }
        is_deeply([$lookups->paths], ["/$carries"], "$ip: sent as $carries");
        $client->lookup($carries);
        is($lookups->count, 1, "$ip: a lookup of $carries is then a cache hit");

        # The mapped form alone: asked beside its plain form, a batch that sent
        # the address as given would still have been answered for the plain one.
        $lookups->reset;
        @batch_sent = ();
        my $answers = lookups(retries => 0)->lookup_batch([$ip]);
        my $answer = $answers->{$ip};
        is_deeply([keys %$answers], [$ip], "$ip: a batch keys the answer as asked");
        is($answer && $answer->can('ip') && $answer->ip, $carries, "$ip: and answers it as $carries");
        is_deeply(\@batch_sent, [$carries], "$ip: the batch sent $carries alone");
    }
};

done_testing();
