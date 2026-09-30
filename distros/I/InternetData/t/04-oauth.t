use strict;
use warnings;

use lib 't/lib';

use Mojo::URL ();
use Mojo::Util ();
use Scalar::Util ();
use Test::More;
use Time::HiRes ();
use InternetData;
use InternetDataTest;
use InternetDataTest::Origin;

# The OAuth accessor against the shared corpus's oauth section, the
# authorization code flow's vectors under oauth.deferred included.
my $corpus = InternetDataTest::corpus()->{oauth};

use constant DEVICE_CODE_GRANT => 'urn:ietf:params:oauth:grant-type:device_code';

# Past this many requests or waits, a loop under test ends the whole PROCESS. A
# die would be caught by the very promise chain it is meant to stop, and a wait
# that never settles would hang, because Mojo::Promise::wait restarts the loop
# until the promise settles.
use constant BOUND => 16;

# Satisfies every operation's required members at once.
my %EVERY_REQUIRED_MEMBER = (
    issuer => 'https://api.example.test',
    authorization_endpoint => 'https://api.example.test/oauth/authorize',
    token_endpoint => 'https://api.example.test/oauth/token',
    device_code => 'mo_dc_x',
    user_code => 'BCDF-GHJK',
    verification_uri => 'https://app.example.test/device',
    expires_in => 900,
    interval => 5,
    access_token => 'mo_at_x',
    token_type => 'Bearer',
);
my %DEVICE = (
    device_code => 'mo_dc_x', user_code => 'BCDF-GHJK',
    verification_uri => 'https://app.example.test/device', expires_in => 900, interval => 1,
);

# Answers in order, repeating the last reply, and records what left the client.
my (@replies, @requests);
my $origin = InternetDataTest::Origin->new(sub {
    my ($c) = @_;
    trip('sent more than ' . BOUND . ' requests') if @requests == BOUND;
    my $req = $c->req;
    push @requests, {
        method => $req->method,
        path => $req->url->path->to_string,
        query => $req->url->query->to_hash,
        url => $req->url->to_abs->to_string,
        headers => { map { lc($_) => $req->headers->header($_) } @{ $req->headers->names } },
        body => $req->body,
    };
    my $reply = $replies[@requests > @replies ? $#replies : $#requests];
    $c->res->headers->content_type('application/json');
    return $c->render(data => $reply->{rawBody}, status => $reply->{status}) if exists $reply->{rawBody};
    $c->render(json => $reply->{body}, status => $reply->{status});
});

sub serve {
    @replies = @_;
    @requests = ();
}

sub client {
    return InternetData->new(base_url => $origin->url, @_);
}

sub trip {
    my ($what) = @_;
    print STDERR "\n$what: the call under test does not end\n";
    exit 97;
}

# Replaces the poll's wait AND its clock, so the deadline reads the time the waits
# spent. Returns the waits, in seconds.
sub fake_clock {
    my ($oauth) = @_;
    my ($elapsed, $reads, @waits) = (0, 0);
    $oauth->{now} = sub {
        trip("read the clock $reads times") if ++$reads > 2 * BOUND;
        return $elapsed;
    };
    $oauth->{sleep_p} = sub {
        trip('waited more than ' . BOUND . ' times') if @waits == BOUND;
        push @waits, $_[0];
        $elapsed += $_[0];
        return Mojo::Promise->resolve;
    };
    return \@waits;
}

# The call's value, or what it died with.
sub settle {
    my ($call) = @_;
    my $value = eval { $call->() };
    return $@ ? $@ : $value;
}

sub call {
    my ($oauth, $operation, $args, %options) = @_;
    return $oauth->metadata(%options) if $operation eq 'metadata';
    if ($operation eq 'deviceAuthorization') {
        my %given = map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(scope resource);
        return $oauth->device_authorization($args->{clientId}, %given, %options);
    }
    return $oauth->exchange_device_code($args->{clientId}, $args->{deviceCode}, %options)
        if $operation eq 'exchangeDeviceCode';
    return $oauth->exchange_refresh_token($args->{clientId}, $args->{refreshToken}, %options)
        if $operation eq 'exchangeRefreshToken';
    return $oauth->revoke($args->{clientId}, $args->{token}, %options) if $operation eq 'revoke';
    return $oauth->exchange_authorization_code(
        $args->{clientId}, $args->{code}, $args->{codeVerifier}, $args->{redirectUri}, %options,
    ) if $operation eq 'exchangeAuthorizationCode';
    die "the corpus names an operation this suite does not know: $operation";
}

# A form body as a field map, decoded the way a server decodes one (+ is a space).
sub form_fields {
    my ($body) = @_;
    my %fields;
    for my $pair (split /&/, $body) {
        my ($name, $value) = map {
            (my $v = $_) =~ tr/+/ /;
            Mojo::Util::decode('UTF-8', Mojo::Util::url_unescape($v));
        } split /=/, $pair, 2;
        ok(!exists $fields{$name}, "$name sent once");
        $fields{$name} = $value;
    }
    return \%fields;
}

# `type` is oauth (the base class exactly), accessDenied, expiredToken, or client:
# the ordinary error, which is never an OauthError. A null in the corpus is undef.
sub is_outcome {
    my ($error, $want, $label) = @_;
    my %class = (
        oauth => 'InternetData::OauthError',
        accessDenied => 'InternetData::OauthAccessDeniedError',
        expiredToken => 'InternetData::OauthExpiredTokenError',
        client => 'InternetData::Error',
    );
    is(ref $error, $class{ $want->{type} }, "$label: type");
    # A mutant can answer a plain hash where an error was due, and ->isa on it would
    # end the whole file rather than fail here.
    return unless Scalar::Util::blessed($error) && $error->isa('InternetData::Error');
    is($error->error_code, $want->{errorCode}, "$label: error_code") if exists $want->{errorCode};
    is($error->error_description, $want->{errorDescription}, "$label: error_description")
        if exists $want->{errorDescription};
    is($error->status, $want->{status}, "$label: status") if exists $want->{status};
    is($error->kind, $want->{kind}, "$label: kind") if exists $want->{kind};
    is($error->retryable, $want->{retryable} ? 1 : 0, "$label: retryable") if exists $want->{retryable};
    is($error->message, $want->{message}, "$label: message") if exists $want->{message};
}

subtest 'no OAuth request carries the API key' => sub {
    my $rule = $corpus->{noCredential};
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    my $oauth = client(api_key => $rule->{apiKey})->oauth;
    fake_clock($oauth);

    my $device = $oauth->device_authorization('internetdata-cli', scope => 'account.read');
    $oauth->metadata;
    $oauth->exchange_device_code('internetdata-cli', 'mo_dc_x');
    $oauth->exchange_refresh_token('internetdata-cli', 'mo_rt_x');
    $oauth->revoke('internetdata-cli', 'mo_rt_x');
    $oauth->poll_device_token('internetdata-cli', $device);
    $oauth->exchange_authorization_code('internetdata-cli', 'mo_ac_x', 'verifier', 'http://127.0.0.1:8765/cb');

    my $url = Mojo::URL->new($oauth->authorization_url('internetdata-cli', 'http://127.0.0.1:8765/cb', 'c',
        scope => 'apikeys.use', state => 's', resource => 'https://x.test/'));
    ok(!exists $url->query->to_hash->{$_}, "the authorization URL carries no $_") for @{ $rule->{forbiddenQuery} };
    is(index("$url", $rule->{apiKey}), -1, 'the authorization URL carries the key nowhere');

    is(scalar @requests, 7, 'every operation was sent');
    for my $req (@requests) {
        my $label = "$req->{method} $req->{path}";
        ok(!exists $req->{headers}{$_}, "$label carried no $_") for @{ $rule->{forbiddenHeaders} };
        ok(!exists $req->{query}{$_}, "$label carried no $_ query key") for @{ $rule->{forbiddenQuery} };
        my @sent = ($req->{url}, $req->{body}, values %{ $req->{headers} });
        my $leaked = grep { index($_, $rule->{apiKey}) >= 0 } @sent;
        is($leaked, 0, "$label carried the key nowhere");
    }
};

# Keyless, because nothing about these operations needs a key. Every call also
# passes a timeout, so an exact field match proves it stays off the wire.
subtest 'each operation requests its endpoint with exactly its form fields' => sub {
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    InternetData->new(base_url => $origin->url . '/')->oauth->metadata(timeout => 5);
    is(scalar @requests, 1, 'metadata sent one request');
    is("$requests[0]{method} $requests[0]{path}",
        "$corpus->{endpoints}{metadata}{method} $corpus->{endpoints}{metadata}{path}",
        'metadata, on a base URL with a trailing slash');

    for my $case (@{ $corpus->{forms}{cases} }, @{ $corpus->{deferred}{forms} }) {
        serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
        call(client()->oauth, $case->{operation}, $case->{args}, timeout => 5);

        is(scalar @requests, 1, "$case->{name}: one request");
        my $want = $corpus->{endpoints}{ $case->{endpoint} };
        my $sent = "$requests[0]{method} $requests[0]{path}";
        is($sent, "$want->{method} $want->{path}", "$case->{name}: endpoint");
        like($requests[0]{headers}{'content-type'}, qr/\A\Q$corpus->{forms}{contentType}\E/,
            "$case->{name}: content type");
        is_deeply(form_fields($requests[0]{body}), $case->{fields}, "$case->{name}: fields");
    }

    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    client()->oauth->device_authorization('internetdata-cli', scope => '', resource => '');
    is_deeply(form_fields($requests[0]{body}), { client_id => 'internetdata-cli' },
        'an empty optional field is left out');
};

subtest 'a 2xx decodes on presence: absent has no key, an empty scope is present' => sub {
    my %operations = (metadata => 'metadata', deviceAuthorization => 'deviceAuthorization',
        token => 'exchangeDeviceCode');
    for my $section (sort keys %operations) {
        for my $case (@{ $corpus->{responses}{$section} }) {
            my $label = "$section: $case->{name}";
            serve($case);
            my $got = call(client()->oauth, $operations{$section},
                { clientId => 'internetdata-cli', deviceCode => 'mo_dc_x' });

            for my $name (sort keys %{ $case->{expect}{present} }) {
                my $want = $case->{expect}{present}{$name};
                $want = $want ? 1 : 0 if ref $want eq 'JSON::PP::Boolean';
                ok(exists $got->{$name}, "$label: $name is present");
                is_deeply($got->{$name}, $want, "$label: $name");
            }
            ok(!exists $got->{$_}, "$label: $_ is ABSENT") for @{ $case->{expect}{absent} };
        }
    }
    for my $case (@{ $corpus->{responses}{revoke} }) {
        serve($case);
        my $outcome = settle(sub { client()->oauth->revoke('internetdata-cli', 'mo_rt_x') });
        # Nothing, rather than not-a-reference: a plain-string die is not a reference.
        is($outcome, undef, "revoke: $case->{name} succeeds");
        is(scalar @requests, 1, "revoke: $case->{name} sent once");
    }
};

subtest 'a 2xx that lacks a required member or does not parse is the ordinary error' => sub {
    my %cases = (
        'missing access_token' => { status => 200, body => { token_type => 'Bearer', expires_in => 3600 } },
        'expires_in as a string' => {
            status => 200,
            body => { access_token => 'mo_at_x', token_type => 'Bearer', expires_in => '3600' },
        },
        'not JSON' => { status => 200, rawBody => '<html>' },
    );
    for my $name (sort keys %cases) {
        serve($cases{$name});
        my $error = settle(sub { client()->oauth->exchange_device_code('internetdata-cli', 'mo_dc_x') });
        is(scalar @requests, 1, "$name: an exchange is never retried");
        is_outcome($error, { type => 'client', kind => 'server_error', status => 200 }, $name);
    }
};

# No corpus case: every response there decodes. One member left out per case,
# since a body missing several at once passes against a decoder that defaults
# any single one of them.
subtest 'an answer missing any one required member is the ordinary error' => sub {
    my %required = (
        metadata => [qw(issuer authorization_endpoint token_endpoint)],
        deviceAuthorization => [qw(device_code user_code verification_uri expires_in interval)],
        exchangeDeviceCode => [qw(access_token token_type expires_in)],
    );
    for my $operation (sort keys %required) {
        for my $member (@{ $required{$operation} }) {
            my %body = %EVERY_REQUIRED_MEMBER;
            delete $body{$member};
            serve({ status => 200, body => \%body });
            my $args = { clientId => 'internetdata-cli', deviceCode => 'mo_dc_x' };
            my $error = settle(sub { call(client()->oauth, $operation, $args) });

            my $label = "$operation without $member";
            is(scalar @requests, 1, "$label: sent once");
            is_outcome($error, { type => 'client', kind => 'server_error', status => 200 }, $label);
        }
    }
};

subtest 'a failed answer is an OAuth refusal only when it is one' => sub {
    for my $case (@{ $corpus->{errors}{cases} }) {
        serve($case);
        my $error = settle(sub { client()->oauth->exchange_device_code('internetdata-cli', 'mo_dc_x') });
        is_outcome($error, $case->{expect}, $case->{name});
    }
};

subtest 'only what consumes nothing is retried, and never an OAuth refusal' => sub {
    for my $case (@{ $corpus->{retries}{cases} }, @{ $corpus->{deferred}{retries} }) {
        serve(@{ $case->{responses} });
        my $outcome = settle(sub { call(client()->oauth, $case->{operation}, $case->{args}) });

        is(scalar @requests, $case->{expect}{requests}, "$case->{name}: requests sent");
        if ($case->{expect}{outcome} eq 'ok') {
            # An answer, or nothing from revoke: a plain-string die is neither.
            ok(!defined $outcome || ref $outcome eq 'HASH', "$case->{name}: succeeds");
            next;
        }
        is_outcome($outcome, { %{ $case->{expect} }, type => $case->{expect}{outcome} }, $case->{name});
    }
};

subtest 'a PKCE pair matches the RFC vector and is never reused' => sub {
    my $vector = $corpus->{deferred}{pkce};
    my $oauth = client()->oauth;
    is($oauth->pkce_challenge($vector->{verifier}), $vector->{challenge}, 'the RFC 7636 challenge');

    my ($first, $second) = ($oauth->create_pkce, $oauth->create_pkce);
    for my $pkce ($first, $second) {
        like($pkce->{verifier}, qr/$vector->{generatedVerifierPattern}/, 'a 43-character base64url verifier');
        is($pkce->{challenge}, $oauth->pkce_challenge($pkce->{verifier}), 'its own challenge');
        is($pkce->{method}, $vector->{method}, 'S256');
        is_deeply([sort keys %$pkce], [qw(challenge method verifier)], 'the three members');
    }
    isnt($first->{verifier}, $second->{verifier}, 'a fresh verifier each time');
};

subtest 'the authorization URL is built exactly, with no request' => sub {
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    for my $case (@{ $corpus->{deferred}{authorizationUrl} }) {
        my %given = map { exists $case->{$_} ? ($_ => $case->{$_}) : () } qw(scope state resource);
        my $url = InternetData->new(base_url => $case->{baseUrl})->oauth->authorization_url(
            $case->{clientId}, $case->{redirectUri}, $case->{codeChallenge}, %given);
        is($url, $case->{expect}, $case->{name});
    }
    client()->oauth->authorization_url('internetdata-cli', 'http://127.0.0.1:8765/cb', 'c');
    is(scalar @requests, 0, 'building the URL sent nothing');
};

subtest 'an empty option is left out, and an empty or unencodable value refused' => sub {
    my $oauth = InternetData->new(base_url => 'https://internetdata.io')->oauth;
    is($oauth->authorization_url('c', 'https://app.example/cb', 'x', scope => '', state => '', resource => ''),
        $oauth->authorization_url('c', 'https://app.example/cb', 'x'), 'empty options are left out');
    for my $args (['', 'r', 'x'], ['c', '', 'x'], ['c', 'r', ''], [undef, 'r', 'x']) {
        eval { $oauth->authorization_url(@$args) };
        like($@, qr/authorization_url: expected \w+ as a string/, 'an empty required value croaks');
    }
    eval { $oauth->authorization_url('c', 'r', 'x', state => "\x{D800}") };
    like($@, qr/authorization_url: state has no UTF-8 form/, 'a lone surrogate croaks');
    eval { $oauth->authorization_url('c', 'r', 'x', timeout => 5) };
    like($@, qr/unknown option\(s\): timeout/, 'a URL takes no timeout');
};

# Waits are asserted exactly, through the seam that replaces the wait AND the
# clock together, so the deadline reads the same time the waits spent.
subtest 'poll_device_token waits, widens and ends as the corpus says' => sub {
    for my $case (@{ $corpus->{poll}{cases} }) {
        serve(@{ $case->{responses} });
        my $oauth = client()->oauth;
        my $waits = fake_clock($oauth);

        my $outcome = settle(sub { $oauth->poll_device_token($case->{clientId}, $case->{device}) });

        my $name = $case->{name};
        is_deeply($waits, $case->{expect}{waits}, "$name: waits, in seconds");
        is(scalar @requests, $case->{expect}{requests}, "$name: requests sent");
        my %form = (
            grant_type => DEVICE_CODE_GRANT, device_code => $case->{device}{device_code},
            client_id => $case->{clientId},
        );
        for my $req (@requests) {
            is("$req->{method} $req->{path}", "POST $corpus->{endpoints}{token}{path}", "$name: endpoint");
            is_deeply(form_fields($req->{body}), \%form, "$name: the exchange form");
        }
        if ($case->{expect}{outcome} eq 'token') {
            is(ref $outcome, 'HASH', "$name: tokens came back");
            is($outcome->{access_token}, $case->{expect}{token}{access_token}, "$name: access_token")
                if $case->{expect}{token};
            next;
        }
        is_outcome($outcome, { %{ $case->{expect} }, type => $case->{expect}{outcome} }, $name);
    }
};

# A deadline already behind the clock leaves a negative remainder, which is never
# the wait: Mojo fires a negative timer at once, but a sleep is asked for 0.
subtest 'a poll past its deadline waits nothing, never a negative time' => sub {
    serve({ status => 400, body => { error => 'authorization_pending' } });
    my $oauth = client()->oauth;
    my $waits = fake_clock($oauth);

    my $outcome = settle(sub { $oauth->poll_device_token('internetdata-cli', { %DEVICE, expires_in => -3 }) });

    is_deeply($waits, [0], 'one wait, of nothing');
    is(scalar @requests, 0, 'and no request');
    is_outcome($outcome, { type => 'expiredToken', status => undef }, 'expires_in -3');
};

# The seam above proves the schedule; this proves the real wait is one.
subtest 'a poll on the real clock waits before its first request' => sub {
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    my $started = Time::HiRes::time();

    client()->oauth->poll_device_token('internetdata-cli', { %DEVICE, interval => 1 });

    my $elapsed = Time::HiRes::time() - $started;
    is(scalar @requests, 1, 'one request');
    cmp_ok($elapsed, '>=', 0.95, 'the first poll waited its interval');
    cmp_ok($elapsed, '<', 2.5, 'and not much longer');
};

my %timed = (
    metadata => sub { $_[0]->metadata(@_[1 .. $#_]) },
    device_authorization => sub { shift->device_authorization('internetdata-cli', @_) },
    exchange_device_code => sub { shift->exchange_device_code('internetdata-cli', 'mo_dc_x', @_) },
    exchange_refresh_token => sub { shift->exchange_refresh_token('internetdata-cli', 'mo_rt_x', @_) },
    revoke => sub { shift->revoke('internetdata-cli', 'mo_rt_x', @_) },
    poll_device_token => sub {
        my $oauth = shift;
        fake_clock($oauth);
        $oauth->poll_device_token('internetdata-cli', \%DEVICE, @_);
    },
);

for my $body (qw(stall_body trickle_body)) {
    subtest "every OAuth call is bounded on a $body, per call and by the client" => sub {
        my $slow = InternetDataTest::Origin->new(\&{"InternetDataTest::Origin::$body"});
        for my $name (sort keys %timed) {
            for my $bound ([3, timeout => 0.25], [0.25]) {
                my ($client_timeout, @options) = @$bound;
                my $label = @options ? "$name, per call" : "$name, by the client";
                my $client = InternetData->new(base_url => $slow->url, retries => 0, timeout => $client_timeout);
                my $oauth = $client->oauth;
                my $started = Time::HiRes::time();
                my $error = settle(sub { $timed{$name}->($oauth, @options) });
                my $elapsed = Time::HiRes::time() - $started;

                is_outcome($error, { type => 'client', kind => 'network', retryable => 1 }, $label);
                cmp_ok($elapsed, '>=', 0.2, "$label: waited for its bound");
                cmp_ok($elapsed, '<', 1.5, "$label: its 0.25s bound fired");
            }
        }
    };
}

subtest 'an option or argument OAuth cannot use is refused before any request' => sub {
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    my $oauth = client()->oauth;

    eval { $oauth->metadata(retries => 1) };
    like($@, qr/unknown option\(s\): retries/, 'retries is not an OAuth option');
    eval { $oauth->device_authorization('internetdata-cli', scope => ['account.read']) };
    like($@, qr/expected scope as a string/, 'a scope must be a string');
    eval { $oauth->revoke('internetdata-cli', 'mo_rt_x', timeout => -1) };
    like($@, qr/timeout must be a number of seconds/, 'a negative timeout is refused');
    eval { $oauth->exchange_device_code(undef, 'mo_dc_x') };
    like($@, qr/expected client_id as a string/, 'a client ID is required');
    eval { $oauth->poll_device_token('internetdata-cli', 'mo_dc_x') };
    like($@, qr/expected the device authorization hash/, 'a poll needs the device authorization');
    is(scalar @requests, 0, 'and not one request was spent finding out');
};

subtest 'the promise forms chain' => sub {
    serve({ status => 200, body => \%EVERY_REQUIRED_MEMBER });
    my $oauth = client()->oauth;
    fake_clock($oauth);
    my $got;
    $oauth->device_authorization_p('internetdata-cli')
        ->then(sub { $oauth->poll_device_token_p('internetdata-cli', shift) })
        ->then(sub { $got = shift })
        ->wait;

    is($got->{access_token}, 'mo_at_x', 'device_authorization_p then poll_device_token_p');
};

done_testing();
