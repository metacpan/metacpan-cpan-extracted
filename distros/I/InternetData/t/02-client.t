use strict;
use warnings;

use lib 't/lib';

use Encode ();
use File::Temp ();
use Mojo::Headers;
use Mojo::IOLoop;
use Mojo::JSON qw(false true);
use Mojo::UserAgent;
use Test::More;
use Time::HiRes ();
use InternetData;
use InternetDataTest;
use InternetDataTest::Origin;

# The Perl-specific surface, as distinct from the shared corpus in
# t/01-conformance.t.

subtest 'the API key reaches the wire, and only one way' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [] });
    });

    InternetData->new(base_url => $origin->url, api_key => 'secret-key')->database->list;

    my ($request) = $origin->requests;
    is($request->{headers}{Authorization}, 'Bearer secret-key', 'sent as a bearer token');
    # `?apikey=` belongs to v1 on this same host, with a different key
    # vocabulary. Sending a v2 key that way would make it look plausible on the
    # version it does not belong to, and query strings end up in logs.
    is_deeply($request->{query}, {}, 'never as a query parameter');
    ok(!exists $request->{headers}{'X-Api-Key'}, 'nor under a second header');
};

subtest 'a keyless client builds and sends no credential at all' => sub {
    # Today every endpoint is licensed, so a keyless client only ever gets a
    # 401. It still has to BUILD, because a database offered without a license
    # would need exactly this client - and an empty key is what an unset
    # `${{ secrets.X }}` interpolates to, where `Bearer ` is worse than nothing.
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [] });
    });

    for my $args ([], [api_key => undef], [api_key => '']) {
        $origin->reset;
        ok(InternetData->new(base_url => $origin->url, @$args)->database->list,
            'the client built and called');
        my ($request) = $origin->requests;
        ok(!exists $request->{headers}{Authorization}, 'no empty Authorization without a key');
        is_deeply($request->{query}, {}, 'and no apikey query parameter');
    }
};

subtest 'a blank key is no key, and the blanks around a key are no part of it' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [] });
    });

    for my $key ('   ', "\t", " \r\n ") {
        $origin->reset;
        InternetData->new(base_url => $origin->url, api_key => $key)->database->list;
        my ($request) = $origin->requests;
        ok(!exists $request->{headers}{Authorization}, 'no Authorization for a blank key');
    }
    for my $key ("secret-key\n", "secret-key\r\n", " \tsecret-key ") {
        $origin->reset;
        InternetData->new(base_url => $origin->url, api_key => $key)->database->list;
        my ($request) = $origin->requests;
        is($request->{headers}{Authorization}, 'Bearer secret-key', 'sent without its blanks');
    }
};

subtest 'a key holding a control character is refused where it is set' => sub {
    # Mojo refused a CR or LF in the header with a raw string from every call,
    # and sent any other control character on the wire.
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [] });
    });
    for my $key ("secret\r\nX-Injected: 1", "sec\nret", "sec\x01ret", "secret\x7f", "sec\tret") {
        my $client = eval { InternetData->new(base_url => $origin->url, api_key => $key) };
        ok(!defined $client, 'refused');
        like($@, qr/api_key holds a control character/, 'naming the cause');
        unlike($@, qr/sec/, 'and not the key');
    }
    is($origin->count, 0, 'with nothing sent');
};

# Through 1.11.2 Mojo died writing such a header in its reactor, so every call
# failed as a retried `Request timeout` after its whole bound, with nothing sent.
subtest 'a key holding a character past U+00FF is refused where it is set' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [] });
    });
    for my $key ('sec' . chr(0x4e2d) . 'ret', 'sec' . chr(0x100) . 'ret') {
        my $client = eval { InternetData->new(base_url => $origin->url, api_key => $key) };
        ok(!defined $client, 'refused');
        like($@, qr/api_key holds a character past U\+00FF/, 'naming the cause');
        unlike($@, qr/sec/, 'and not the key');
    }
    is($origin->count, 0, 'with nothing sent');
    # A Latin-1 character, and a key's UTF-8 bytes, go out as those bytes, which
    # the server answers as it answers any wrong key.
    for my $case (['k' . chr(0xe9) . 'y', "k\xe9y"], [Encode::encode('UTF-8', 'k' . chr(0x4e2d) . 'y'), "k\xe4\xb8\xady"]) {
        $origin->reset;
        my $client = eval { InternetData->new(base_url => $origin->url, api_key => $case->[0]) };
        ok($client, 'accepted') or next;
        $client->database->list;
        my ($request) = $origin->requests;
        is(unpack('H*', $request->{headers}{Authorization}), unpack('H*', "Bearer $case->[1]"), 'sent as its bytes');
    }
};

subtest 'an empty result code gives way to the status' => sub {
    for my $case ([{ rc => 'UNAUTHORIZED_ID' }, 'UNAUTHORIZED_ID'], [{ rc => '' }, 'request failed with status 403'],
                  [{ rc => undef }, 'request failed with status 403'], [{}, 'request failed with status 403']) {
        my ($body, $want) = @$case;
        my $origin = InternetDataTest::Origin->new(sub {
            shift->render(json => $body, status => 403);
        });
        eval { InternetData->new(base_url => $origin->url, api_key => 'k')->database->list };
        is($@->kind, 'forbidden', 'a 403');
        is($@->message, $want, "reads as '$want'");
    }
};

subtest 'a Retry-After is digits or an HTTP date in GMT, and nothing else' => sub {
    # Mojo::Date read ISO 8601, any zone as GMT and an unknown month as January,
    # and the digits took a fraction.
    my @at = gmtime(time + 60);
    my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @weekdays = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @mons = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($s, $mi, $h, $d, $mo, $y, $wd) = @at;
    $y += 1900;
    my $clock = sprintf('%02d:%02d:%02d', $h, $mi, $s);
    my $imf = sprintf('%s, %02d %s %d %s', $days[$wd], $d, $mons[$mo], $y, $clock);
    my $next = $y + 1;
    my @cases = (
        ['0', 'rate_limited'], ['120', 'rate_limited'], [' 7 ', 'rate_limited'], ["$imf GMT", 'rate_limited'],
        [sprintf('%s, %02d-%s-%02d %s GMT', $weekdays[$wd], $d, $mons[$mo], $y % 100, $clock), 'rate_limited'],
        [sprintf('%s %s %2d %s %d', $days[$wd], $mons[$mo], $d, $clock, $y), 'rate_limited'],
        ["$imf +0000", 'quota_exceeded'], ["$imf +0500", 'quota_exceeded'], ["$imf EST", 'quota_exceeded'],
        ["$imf PST", 'quota_exceeded'], ["$imf gmt", 'quota_exceeded'],
        [sprintf('%d-%02d-%02dT%sZ', $y, $mo + 1, $d, $clock), 'quota_exceeded'],
        [sprintf('Foo, %02d %s %d %s GMT', $d, $mons[$mo], $y, $clock), 'quota_exceeded'],
        [sprintf('%s, %02d Xyz %d %s GMT', $days[$wd], $d, $y, $clock), 'quota_exceeded'],
        [sprintf('%02d %s %d %s GMT', $d, $mons[$mo], $y, $clock), 'quota_exceeded'],
        ["Tue, 31 Nov $next 08:49:37 GMT", 'quota_exceeded'], ["Mon, 30 Feb $next 08:49:37 GMT", 'quota_exceeded'],
        ["Fri, 01 Jan $next 25:00:00 GMT", 'quota_exceeded'], ["Fri, 01 Jan $next 08:61:00 GMT", 'quota_exceeded'],
        ['1.5', 'quota_exceeded'], ['+1', 'quota_exceeded'], ['-1', 'quota_exceeded'], ['0x10', 'quota_exceeded'],
        ['1_0', 'quota_exceeded'], ['1e3', 'quota_exceeded'], ['tomorrow', 'quota_exceeded'], ['', 'quota_exceeded'],
    );
    for my $case (@cases) {
        my ($value, $kind) = @$case;
        my $headers = Mojo::Headers->new;
        $headers->header('Retry-After' => $value);
        is(InternetData::Error->from_response(429, $headers, {})->kind, $kind, "'$value' is $kind");
    }
    my $headers = Mojo::Headers->new;
    $headers->header('Retry-After' => "$imf GMT");
    my $wait = InternetData::Error->from_response(429, $headers, {})->retry_after;
    ok($wait >= 55 && $wait <= 60, "a date is the seconds until it, in GMT ($wait)");
    $headers->header('Retry-After' => 'Sun, 06 Nov 1994 08:49:37 GMT');
    is(InternetData::Error->from_response(429, $headers, {})->retry_after, 0, 'a date already past is no wait');
};

subtest 'responses are unwrapped at the right depth' => sub {
    my $family = InternetDataTest::family();
    my $open = InternetDataTest::family(base => 'asn', standing => 'unlicensed', open => true, license_type => undef);
    my %bodies = (
        '/api/v2/database/list' => { databases => [$family, $open] },
        '/api/v2/database/checksum' => InternetDataTest::checksum(),
        '/api/v2/database/downloads' => { downloads => [InternetDataTest::download(open => true)] },
        '/api/v2/database/metadata' => InternetDataTest::metadata(),
    );
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->render(json => $bodies{ $c->req->url->path->to_string });
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k');

    # `checksums` returns the WHOLE digest set. Reading a top-level sha256
    # shipped broken in another SDK: it returned undef against a healthy API.
    my $sums = $client->database->checksums('bogon_ip_v1', 'csvgz');
    is_deeply($sums, $bodies{'/api/v2/database/checksum'}{checksums}, 'the whole digest set');
    is($sums->{sha256}, 's256', 'the digest a caller actually wants is there');

    # v2 answers `databases`, where vpndetection's v1 answered `datasets`. One
    # letter of difference between two brands' feeds is exactly the sort of thing
    # a hand-written client gets wrong once and never notices.
    my $databases = $client->database->list;
    is_deeply($databases, [$family, $open], 'list unwraps databases');
    is($databases->[0]{base}, 'bogon_ip', 'a family is keyed by base, not by a database id');
    is($databases->[0]{versions}[0]{id}, 'bogon_ip_v1', 'and the id to download hangs off versions');
    # An Open family's standing stays as served, never derived from open.
    is_deeply([map { [!!$_->{open}, $_->{standing}] } @$databases], [['', 'licensed'], [1, 'unlicensed']],
        'open is read beside standing');

    my $downloads = $client->database->downloads;
    is_deeply($downloads, $bodies{'/api/v2/database/downloads'}{downloads}, 'downloads unwraps downloads');
    ok($downloads->[0]{open}, 'and a download of an Open database says so');
    # metadata is the whole document rather than a member of it: it carries the
    # per-format size a caller budgets a transfer against.
    my $meta = $client->database->metadata('bogon_ip_v1');
    is($meta->{entries}, 42, 'metadata is the whole document');
    is($meta->{size}{csvgz}, 760, 'including the size that budgets a transfer');
};

# Through 1.8.1 an object without the member a call unwraps came back undef, as
# if it were the answer, so `@{ $db->list }` died in the caller's code.
subtest 'a 2xx a database call cannot read as its answer is a retried server_error' => sub {
    my ($body, $type);
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->res->headers->content_type($type);
        $c->render(data => $body);
    });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0)->database;
    my %calls = (
        list => sub { $db->list },
        checksums => sub { $db->checksums('bogon_ip_v1', 'csvgz') },
        downloads => sub { $db->downloads },
        metadata => sub { $db->metadata('bogon_ip_v1') },
    );
    my @bodies = (
        ['<html>gateway</html>', 'text/html'], ['{"databases":[', 'application/json'],
        ['', 'application/json'], ['[]', 'application/json'],
        ['{}', 'application/json'],
        ['{"databases":{},"checksums":[],"downloads":"x"}', 'application/json', 'list', 'checksums', 'downloads'],
        # metadata IS the answer, so an object without its id is none.
        ['{"id":null,"updated":"2026-10-10"}', 'application/json', 'metadata'],
    );
    for my $case (@bodies) {
        ($body, $type, my @only) = @$case;
        for my $name (@only ? @only : sort keys %calls) {
            my $error = eval { $calls{$name}->(); 1 } ? undef : $@;
            ok(ref $error && $error->isa('InternetData::Error'), "$name, '$body': raised an InternetData::Error")
                or next;
            is($error->kind, 'server_error', "$name, '$body': server_error");
            is($error->status, 200, "$name, '$body': carrying the status");
        }
    }

    ($body, $type) = ('{}', 'application/json');
    $origin->reset;
    my $retried = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1)->database;
    ok(!eval { $retried->list; 1 }, 'still failing on the retry');
    is($origin->count, 2, 'and retried like any outage');
};

# Through 1.10.0 a member of another type than the spec's came back as served:
# a version of "3" as a string, `{}` as a family, a `size` of "760" as the size.
subtest 'a member of the wrong type at any depth is a retried server_error' => sub {
    my $body;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/json');
        $c->render(data => $body);
    });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1)->database;
    my %calls = (
        list => sub { $db->list },
        metadata => sub { $db->metadata('bogon_ip_v1') },
        checksums => sub { $db->checksums('bogon_ip_v1', 'csvgz') },
        downloads => sub { $db->downloads },
    );
    my $family = InternetDataTest::family();
    my $version = $family->{versions}[0];
    my $listing = sub { { databases => [shift] } };
    my $sums = sub { InternetDataTest::checksum(checksums => { %{ InternetDataTest::checksum()->{checksums} }, @_ }) };
    my @cases = (
        [list => $listing->({ %$family, versions => [{ %$version, version => '3' }] })],
        [list => $listing->({ %$family, versions => [{ %$version, version => 'x' }] })],
        [list => $listing->({ %$family, versions => [{ %$version, version => 1.5 }] })],
        [list => $listing->({ %$family, versions => [{ %$version, formats => [1] }] })],
        [list => $listing->({ %$family, versions => [{ %$version, id => undef }] })],
        [list => $listing->({ %$family, versions => [1] })],
        [list => $listing->({ %$family, open => 'yes' })],
        [list => $listing->({ %$family, open => 1 })],
        [list => $listing->({ %$family, expires => 1 })],
        [list => $listing->({ %$family, base => undef })],
        [list => $listing->({})],
        [metadata => InternetDataTest::metadata(entries => '42')],
        [metadata => InternetDataTest::metadata(size => { csvgz => '760' })],
        [metadata => InternetDataTest::metadata(size => '760')],
        [metadata => InternetDataTest::metadata(schema => { csvgz => [{ name => 1, type => 't' }] })],
        [metadata => InternetDataTest::metadata(sample => { csvgz => [1] })],
        [metadata => InternetDataTest::metadata(updated => undef)],
        [metadata => InternetDataTest::metadata(size => { csvgz => undef })],
        [checksums => $sums->(sha256 => 1)],
        [checksums => $sums->(sha512 => undef)],
        # Through 1.11.2 nothing read the answer's id or format, so an answer
        # without either came back whole.
        [checksums => InternetDataTest::checksum(id => undef)],
        [checksums => InternetDataTest::checksum(format => undef)],
        [checksums => InternetDataTest::checksum(id => 7)],
        [checksums => InternetDataTest::checksum(format => 7)],
        [checksums => { id => 'bogon_ip_v1', checksums => InternetDataTest::checksum()->{checksums} }],
        [downloads => { downloads => [InternetDataTest::download(bytes => '10')] }],
        [downloads => { downloads => [InternetDataTest::download(open => 'true')] }],
        [downloads => { downloads => [InternetDataTest::download(created => undef)] }],
    );
    for my $case (@cases) {
        (my $name, my $wire) = @$case;
        $body = Mojo::JSON::encode_json($wire);
        $origin->reset;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $error = eval { $calls{$name}->(); 1 } ? undef : $@;
        ok(ref $error && $error->isa('InternetData::Error'), "$name, $body: raised an InternetData::Error")
            or next;
        is($error->kind, 'server_error', "$name, $body: server_error");
        is($error->status, 200, "$name, $body: carrying the status");
        is($origin->count, 2, "$name, $body: retried like any outage");
        is_deeply(\@warnings, [], "$name, $body: and warning the caller of nothing");
    }
};

# RFC 3339 alone, on a day that exists. Through 1.11.3 a date was checked as a
# string alone, so every one of these came back as served (measured 2026-10-29).
subtest 'a date or date-time that is not RFC 3339 is a retried server_error' => sub {
    my $body;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/json');
        $c->render(data => $body);
    });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1)->database;
    my @date_times = ('2026-10-05', '2026-10-05T10:00:00', '2026-10-05T10:00:00+05', '2026-10-05T10:00Z',
        '2026-10-05T10:00:00+0500', '2026-10-05T10:00:00+05:00:30', '2026-10-05T24:00:00Z', '2026-10-05T10:60:00Z',
        '2026-10-05T10:00:60Z', '2026-02-30T10:00:00Z', '2026-10-05T10:00:00+24:00', '2026-10-05T10:00:00+05:60',
        ' 2026-10-05T10:00:00Z', '2026-10-05T10:00:00Z ', '2026-10-05 10:00:00Z', '2026-10-5T10:00:00Z',
        '+12026-10-05T10:00:00Z', '2026-10-05T10:00:00.Z', '20261005T100000Z', '2026-10-05T10:00:00UTC', 'x',
        'tomorrow', 'monday', '', "2026-10-05T10:00:00Z\n", "\x{0662}026-10-05T10:00:00Z");
    my @dates = ('2026-10-05T10:00:00', '2026-10-05T10:00:00Z', '2026-02-30', '2026-11-31', '2026-13-01', '2026-10-5',
        '20261005', '2026-W41-1', '2026-278', ' 2026-10-05', '+12026-10-05', 'x', 'tomorrow', 'monday', '',
        "2026-10-05\n", "\x{0662}026-10-05", '2025-02-29', '1900-02-29');
    my $family = InternetDataTest::family();
    my @cases;
    for my $value (@date_times) {
        for my $member (qw(starts expires renews_at notice_due_at)) {
            push @cases, [list => "$member '$value'", sub { $db->list }, { databases => [{ %$family, $member => $value }] }];
        }
        push @cases, [downloads => "created '$value'", sub { $db->downloads },
            { downloads => [InternetDataTest::download(created => $value)] }];
    }
    for my $value (@dates) {
        push @cases, [metadata => "updated '$value'", sub { $db->metadata('bogon_ip_v1') },
            InternetDataTest::metadata(updated => $value)];
    }
    for my $case (@cases) {
        my ($call, $name, $run, $wire) = @$case;
        $name =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
        $body = Mojo::JSON::encode_json($wire);
        $origin->reset;
        my $error = eval { $run->(); 1 } ? undef : $@;
        ok(ref $error && $error->isa('InternetData::Error'), "$call, $name: raised an InternetData::Error")
            or next;
        is($error->kind, 'server_error', "$call, $name: server_error");
        is($error->status, 200, "$call, $name: carrying the status");
        is($origin->count, 2, "$call, $name: retried like any outage");
    }
    for my $value ('2026-10-05T10:00:00Z', '2026-10-05t10:00:00.5z', '2026-10-05T10:00:00-00:00',
        '2026-10-05T10:00:00.123456789+05:30', '2024-02-29T23:59:59+23:59', '0001-01-01T00:00:00Z',
        '2000-02-29T00:00:00Z') {
        $body = Mojo::JSON::encode_json({ databases => [{ %$family, starts => $value }] });
        is(eval { $db->list->[0]{starts} } // "died: $@", $value, "starts '$value' is an answer");
        $body = Mojo::JSON::encode_json({ downloads => [InternetDataTest::download(created => $value)] });
        is(eval { $db->downloads->[0]{created} } // "died: $@", $value, "created '$value' is an answer");
    }
    for my $value ('2026-10-05', '2024-02-29', '0099-12-31', '2000-02-29') {
        $body = Mojo::JSON::encode_json(InternetDataTest::metadata(updated => $value));
        is(eval { $db->metadata('bogon_ip_v1')->{updated} } // "died: $@", $value, "updated '$value' is an answer");
    }
    $body = Mojo::JSON::encode_json(InternetDataTest::metadata(sample => { csvgz => [undef] }));
    $origin->reset;
    my $error = eval { $db->metadata('bogon_ip_v1'); 1 } ? undef : $@;
    ok(ref $error && $error->kind eq 'server_error' && $origin->count == 2, 'a sample row of null is a retried server_error');
};

# Refusing these would fail every refused download and every family with no
# license: a nullable member may be null, and an optional one absent.
subtest 'nullable and optional members stay an answer' => sub {
    my $family = InternetDataTest::family(expires => undef, license_type => undef);
    delete $family->{starts};
    my %bodies = (
        '/api/v2/database/list' => { databases => [$family] },
        '/api/v2/database/metadata' => InternetDataTest::metadata(),
        '/api/v2/database/downloads' => { downloads => [InternetDataTest::download(
            bytes => undef, http_status => undef, apikey_id => undef, client_ip => undef, user_agent => undef,
        )] },
    );
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        $c->render(json => $bodies{ $c->req->url->path->to_string });
    });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0)->database;
    is_deeply($db->list, [$family], 'a family with no license');
    is($db->metadata('bogon_ip_v1')->{entries}, 42, 'metadata with no sample');
    is($db->downloads->[0]{bytes}, undef, 'a refused download, its nulls kept');
};

subtest 'the query a call makes says what it asked for' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my %body = (
            '/api/v2/database/downloads' => { downloads => [] },
            '/api/v2/database/checksum' => InternetDataTest::checksum(id => 'bogon_asn_v1'),
            '/api/v2/database/metadata' => InternetDataTest::metadata(id => 'bogon_asn_v1'),
            '/api/v2/database/list' => { databases => [] },
        );
        $c->render(json => $body{ $c->req->url->path->to_string });
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k');

    $client->database->checksums('bogon_asn_v1', 'csvgz');
    $client->database->metadata('bogon_asn_v1');
    $client->database->downloads(limit => 5);
    $client->database->downloads;
    $client->database->list;

    my @requests = $origin->requests;
    is_deeply($requests[0]{query}, { id => 'bogon_asn_v1', format => 'csvgz' }, 'checksums');
    # No format: one metadata document describes every format the database is
    # built in.
    is_deeply($requests[1]{query}, { id => 'bogon_asn_v1' }, 'metadata takes an id alone');
    is_deeply($requests[2]{query}, { limit => 5 }, 'downloads passes a limit through');
    is_deeply($requests[3]{query}, {}, 'and sends none when none was given');
    is_deeply($requests[4]{query}, {}, 'list takes nothing at all');
};

subtest 'retries are configurable per call' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { rc => 'ERROR' }, status => 500);
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0);

    eval { $client->database->list(retries => 2) };
    isa_ok($@, 'InternetData::Error', 'still failed');
    is($origin->count, 3, 'one attempt plus two retries, not the client default of none');

    $origin->reset;
    eval { $client->database->list };
    is($origin->count, 1, 'the client default still applies without an override');
};

for my $body (qw(stall_body trickle_body)) {
subtest "a per-call timeout below the client one fires on a $body" => sub {
    my $origin = InternetDataTest::Origin->new(\&{"InternetDataTest::Origin::$body"});
    my $db = InternetData->new(
        base_url => $origin->url, api_key => 'k', retries => 0, timeout => 3,
    )->database;
    my %calls = (
        list => sub { $db->list(@_) },
        metadata => sub { $db->metadata('bogon_ip_v1', @_) },
        checksums => sub { $db->checksums('bogon_ip_v1', 'mmdb', @_) },
        downloads => sub { $db->downloads(@_) },
        download_url => sub { $db->download_url('bogon_ip_v1', 'mmdb', @_) },
    );

    for my $name (sort keys %calls) {
        my $started = Time::HiRes::time();
        my $answer = eval { $calls{$name}->(timeout => 0.25) };
        my $error = $@;
        my $elapsed = Time::HiRes::time() - $started;

        ok(!defined $answer, "$name: the call failed");
        isa_ok($error, 'InternetData::Error', $name);
        is($error->kind, 'network', "$name: surfaces as a transport failure");
        is($error->retryable, 1, "$name: and is worth another attempt");
        cmp_ok($elapsed, '>=', 0.2, "$name: the call waited for it");
        cmp_ok($elapsed, '<', 1.5, "$name: the call's 0.25s fired, not the client's 3s");
    }

    # A per-call value left on something the client shares would pass the loop
    # above and leave every later call on the wrong bound.
    my $bounded = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0, timeout => 0.25);
    my $started = Time::HiRes::time();
    eval { $bounded->database->list };
    my $elapsed = Time::HiRes::time() - $started;
    is(ref $@ && $@->kind, 'network', "without an override the client's own bound fires");
    cmp_ok($elapsed, '>=', 0.2, 'after waiting for it');
    cmp_ok($elapsed, '<', 1.5, 'at its 0.25s');
};
}

subtest 'a per-call timeout bounds every attempt of that call and nothing after it' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my $path = $c->req->url->path->to_string;
        return InternetDataTest::Origin::stall_body($c) if $path eq '/api/v2/database/list';
        $c->render_later;
        Mojo::IOLoop->timer(0.5 => sub { $c->render(json => InternetDataTest::metadata()) });
    });
    my $ua = Mojo::UserAgent->new;
    my $db = InternetData->new(
        base_url => $origin->url, api_key => 'k', retries => 1, timeout => 3, ua => $ua,
    )->database;

    my $started = Time::HiRes::time();
    eval { $db->list(timeout => 0.25) };
    my $elapsed = Time::HiRes::time() - $started;
    is($@->kind, 'network', 'the call timed out');
    is($origin->count, 2, 'once, and once more on the retry');
    cmp_ok($elapsed, '<', 1.5, "the retry kept the call's bound rather than taking the client's");
    is($ua->request_timeout, 3, 'the agent is left as the client configured it');

    # Slower than the last call's bound and well inside the client's, so this
    # fails only if that bound outlived the call it was given to.
    is($db->metadata('bogon_ip_v1')->{id}, 'bogon_ip_v1',
        'the next call is bounded by the client again');
};

subtest "a request started inside another call's window takes its own bound" => sub {
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => { databases => [], downloads => [] }) });
    my $ua = Mojo::UserAgent->new;
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', timeout => 3, ua => $ua)->database;
    my (%bound, $nested);
    $ua->on(start => sub {
        my (undef, $tx) = @_;
        my $path = $tx->req->url->path->to_string;
        $bound{$path} = $ua->request_timeout;
        # The bound is swapped around start_p, and Mojo runs a loop tick in there
        # when the loop is idle. Starting a request from this event puts it inside
        # that window as deterministically as a retry landing in the tick would.
        $nested ||= $db->downloads_p if $path eq '/api/v2/database/list';
    });

    $db->list(timeout => 0.25);
    $nested->wait;

    is($bound{'/api/v2/database/list'}, 0.25, 'the call took its own bound');
    is($bound{'/api/v2/database/downloads'}, 3,
        "and the request started inside its window took the client's, not the call's");
};

subtest 'a per-call timeout is refused where it cannot work' => sub {
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => {}) });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k')->database;
    my $dir = File::Temp->newdir;
    my $path = $dir->dirname . '/bogon_ip_v1.mmdb';

    for my $bad (-1, 'soon') {
        eval { $db->list(timeout => $bad) };
        like($@, qr/timeout must be a number of seconds/, "list refuses timeout => $bad");
        eval { $db->download_url('bogon_ip_v1', 'mmdb', timeout => $bad) };
        like($@, qr/timeout must be a number of seconds/, "download_url refuses timeout => $bad");
    }
    # A transfer runs as long as the file takes. A bound would cut it off, and
    # one spent on the link alone would read as bounding a transfer it does not.
    eval { $db->download('bogon_ip_v1', 'mmdb', $path, timeout => 5) };
    like($@, qr/unknown option\(s\): timeout/, 'download refuses one outright');
    eval { $db->download_bytes('bogon_ip_v1', 'mmdb', timeout => 5) };
    like($@, qr/unknown option\(s\): timeout/, 'and so does download_bytes');
    is($origin->count, 0, 'and not one request was spent finding out');
    ok(!-e "$path.part", 'nor was a .part file left behind');
};

# Through 1.11.2 a count was taken as given: NaN compares false with 0, so a
# failing call was retried for good, a word read as 0, 1.5 as two retries, and a
# negative per call as none.
subtest 'a retry count that cannot work is refused where it is set' => sub {
    # A 404 is never retried, so a value that slips through fails its assertion
    # rather than retrying for good.
    my $status = 404;
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => {}, status => $status) });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 0)->database;
    my $dir = File::Temp->newdir;
    my $path = $dir->dirname . '/bogon_ip_v1.mmdb';

    for my $bad (-1, 'nan', -9**9**9, 1.5, 'two', '', [2]) {
        my $shown = ref $bad ? 'a reference' : "'$bad'";
        my $client = eval { InternetData->new(base_url => $origin->url, api_key => 'k', retries => $bad) };
        like($@, qr/InternetData->new: retries must be a whole number/, "new refuses retries => $shown");
        ok(!$client, "and builds no client for retries => $shown");
        for my $call (
            [list => sub { $db->list(retries => $bad) }],
            [metadata => sub { $db->metadata('bogon_ip_v1', retries => $bad) }],
            [download_url => sub { $db->download_url('bogon_ip_v1', 'mmdb', retries => $bad) }],
            [download => sub { $db->download('bogon_ip_v1', 'mmdb', $path, retries => $bad) }],
            [download_bytes => sub { $db->download_bytes('bogon_ip_v1', 'mmdb', retries => $bad) }],
        ) {
            eval { $call->[1]->() };
            like($@, qr/database->\Q$call->[0]\E: retries must be a whole number/, "$call->[0] refuses retries => $shown");
        }
    }
    is($origin->count, 0, 'and not one request was spent finding out');
    ok(!-e "$path.part", 'nor was a .part file left behind');

    # A count written as a string is that count, and Inf retries for good.
    for my $good ('1', '1e0', 9**9**9) {
        ok(eval { InternetData->new(api_key => 'k', retries => $good); 1 }, "new takes retries => '$good'");
    }
    $status = 503;
    eval { $db->list(retries => '1') };
    is($origin->count, 2, "and a per-call '1' is one retry");
};

subtest 'a client-wide timeout is refused where it cannot work' => sub {
    my $origin = InternetDataTest::Origin->new(sub { shift->render(json => { databases => [] }) });

    for my $bad (-1, 'soon') {
        my $client = eval { InternetData->new(base_url => $origin->url, api_key => 'k', timeout => $bad) };
        like($@, qr/InternetData->new: timeout must be a number of seconds/, "new refuses timeout => $bad");
        ok(!$client, "and builds no client for timeout => $bad");
    }
    is($origin->count, 0, 'and not one request was spent finding out');
    # 0 is no bound at all, which is a choice rather than a mistake.
    is_deeply(InternetData->new(base_url => $origin->url, api_key => 'k', timeout => 0)->database->list,
        [], 'while timeout => 0 still builds a client that answers');
};

subtest 'a zero written as a string is no bound too' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my $c = shift;
        return $c->render(json => { databases => [] }) if $c->req->url->path->to_string eq '/api/v2/database/list';
        $c->render(json => { issuer => 'x', authorization_endpoint => 'x', token_endpoint => 'x' });
    });
    # Each is 0 as a number and true as a string, and Mojo tests the bound for
    # truth before arming it: handed over as given, each was a timer that fired
    # at once and failed every call.
    for my $zero ('0.0', '00', '0e0', '0 but true') {
        my $client = InternetData->new(base_url => $origin->url, retries => 0, timeout => $zero);
        my $got = eval { $client->database->list };
        is_deeply($got, [], "the client's timeout => '$zero' bounds nothing") or diag $@;
        my $keyless = InternetData->new(base_url => $origin->url, retries => 0);
        $got = eval { $keyless->database->list(timeout => $zero) };
        is_deeply($got, [], "and neither does list's") or diag $@;
        $got = eval { $keyless->oauth->metadata(timeout => $zero) };
        is($got && $got->{issuer}, 'x', "nor oauth->metadata's") or diag $@;
    }
};

subtest 'an unpublished format is refused before the network' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c, $o) = @_;
        return $c->render(json => InternetDataTest::checksum(format => $c->param('format')))
            if $c->req->url->path->to_string =~ /checksum/;
        $c->res->headers->location($o->url . '/file');
        $c->rendered(302);
    });
    my $db = InternetData->new(base_url => $origin->url, api_key => 'k')->database;
    my $dir = File::Temp->newdir;
    my $path = $dir->dirname . '/bogon_ip_v1.bin';

    is_deeply([InternetData::Database::FORMATS], InternetDataTest::corpus()->{formats},
        'the formats it takes are the ones the corpus publishes');
    for my $format ('zip', 'MMDB', 'csv.gz') {
        for my $call (
            [checksums => sub { $db->checksums('bogon_ip_v1', $format) }],
            [download_url => sub { $db->download_url('bogon_ip_v1', $format) }],
            [download => sub { $db->download('bogon_ip_v1', $format, $path) }],
            [download_bytes => sub { $db->download_bytes('bogon_ip_v1', $format) }],
        ) {
            eval { $call->[1]->() };
            like($@, qr/'\Q$format\E' is not a published format; expected one of csvgz, mmdb/,
                "$call->[0] refuses '$format', naming what it takes");
        }
    }
    is($origin->count, 0, 'and not one request was spent finding out');
    ok(!-e "$path.part", 'nor was a .part file left behind');

    for my $format (InternetData::Database::FORMATS) {
        $db->checksums('bogon_ip_v1', $format);
        $db->download_url('bogon_ip_v1', $format);
    }
    is($origin->count, 4, 'while every published format still reaches the API');
};

subtest 'every closed vocabulary is listed at runtime, as the pinned spec publishes it' => sub {
    # The corpus reads these out of the pinned spec, so a value the spec gains
    # reddens this after the next re-pin rather than leaving a list quietly short.
    my $corpus = InternetDataTest::corpus();
    is_deeply([InternetData::Database::FORMATS], $corpus->{formats}, 'FORMATS');
    is_deeply([InternetData::Database::STANDINGS], $corpus->{standings}, 'STANDINGS');
    is_deeply([InternetData::Database::LICENSE_TYPES], $corpus->{license_type}, 'LICENSE_TYPES');
};

subtest 'a 429 is retried only when it carries Retry-After' => sub {
    my $attempts = 0;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        my $retryable = $c->req->url->query->param('id') eq 'retryable';
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => 0) if $retryable;
            return $c->render(json => { rc => 'RATE_LIMITED' }, status => 429);
        }
        $c->render(json => InternetDataTest::metadata(id => 'ok'));
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 2);

    my $meta = $client->database->metadata('retryable');
    is($meta->{id}, 'ok', 'a rate limit was waited out');
    is($origin->count, 2, 'exactly one retry');

    $attempts = 0;
    $origin->reset;
    my $spent = eval { $client->database->metadata('spent') };
    ok(!defined $spent, 'a spent quota fails');
    is($@->kind, 'quota_exceeded', 'and is classified as such');
    is($origin->count, 1, 'a 429 without Retry-After is never retried');
};

subtest 'a Retry-After wait does not block the event loop' => sub {
    my $attempts = 0;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => 1);
            return $c->render(json => { rc => 'RATE_LIMITED' }, status => 429);
        }
        $c->render(json => { databases => [] });
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1);

    # A sleep inside a promise handler would freeze everything else sharing this
    # loop, the origin in this test included. A timer does not, and a recurring
    # tick is the difference made visible.
    my $ticks = 0;
    my $ticker = Mojo::IOLoop->recurring(0.05 => sub { $ticks++ });
    my $databases = $client->database->list;
    Mojo::IOLoop->remove($ticker);

    is_deeply($databases, [], 'the retry succeeded');
    cmp_ok($ticks, '>=', 5, "the loop kept running through the wait (ticked $ticks times)");
};

subtest 'a retry without Retry-After backs off, doubling' => sub {
    my @at;
    my $origin = InternetDataTest::Origin->new(sub {
        push @at, Time::HiRes::time();
        shift->render(json => { rc => 'ERROR' }, status => 503);
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 2);

    eval { $client->database->list };
    my $error = $@;
    is(ref $error && $error->kind, 'server_error', 'the call failed as the server did');
    is(scalar @at, 3, 'one attempt plus two retries');
    my ($first, $second) = ($at[1] - $at[0], $at[2] - $at[1]);
    cmp_ok($first, '>=', 0.24, sprintf 'the first retry waited %.3f s, at least 250 ms', $first);
    cmp_ok($first, '<', 0.45, 'and not the doubled wait');
    cmp_ok($second, '>=', 0.49, sprintf 'the second waited %.3f s, at least 500 ms', $second);
};

subtest 'the retry schedule, and the longest Retry-After honored' => sub {
    my @backoff = map { InternetData::_retry_delay(undef, $_) } 0 .. 7;
    is_deeply(\@backoff, [0.25, 0.5, 1, 2, 4, 8, 16, 16], 'doubling from 250 ms, capped from the seventh');
    is(InternetData::_retry_delay(3, 4), 3, 'a Retry-After is waited as given');
    is(InternetData::_retry_delay(0, 1), 0.5, 'a Retry-After of 0 waits the backoff');
    is(InternetData::_retry_delay(2_147_483.647, 0), 2_147_483.647, 'up to 2**31 - 1 ms');
    is(InternetData::_retry_delay(2_147_484, 0), 0.25, 'and one past it waits the backoff');
    is(InternetData::_retry_delay(9223372036854775807, 1), 0.5, 'as does one no timer should hold');
};

subtest 'a Retry-After past the bound is waited out on the backoff' => sub {
    my $attempts = 0;
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c) = @_;
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => '9223372036854775807');
            return $c->render(json => { rc => 'RATE_LIMITED' }, status => 429);
        }
        $c->render(json => { databases => [] });
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', retries => 1);

    # Raced against a timer: honored as given, this wait would never end.
    my ($databases, $timed_out);
    my $started = Time::HiRes::time();
    Mojo::Promise->race(
        $client->database->list_p->then(sub { $databases = shift }),
        Mojo::Promise->timer(5)->then(sub { $timed_out = 1 }),
    )->wait;
    ok(!$timed_out, 'the call did not wait on the server');
    is_deeply($databases, [], 'the retry succeeded');
    is($origin->count, 2, 'after exactly one retry');
    cmp_ok(Time::HiRes::time() - $started, '<', 2, 'having waited the backoff');
};

subtest 'the download redirect is never followed' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        my ($c, $o) = @_;
        if ($c->req->url->path->to_string eq '/api/v2/database/download') {
            $c->res->headers->location($o->url . '/huge');
            return $c->rendered(302);
        }
        # A real published file: announces gigabytes and then stalls. A client
        # that followed the redirect hangs here, and is caught by the request
        # count rather than by a transfer.
        $c->res->headers->content_length(8 * 1024 * 1024 * 1024);
        $c->res->headers->content_type('application/octet-stream');
        $c->render_later;
        $c->write('x' x 1024);
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', timeout => 3);

    my $url = $client->database->download_url('bogon_ip_v1', 'mmdb');
    is($url, $origin->url . '/huge', 'the Location is the answer');
    is(scalar(grep { $_ eq '/huge' } $origin->paths), 0, 'the file itself was never requested');
    is($origin->count, 1, 'exactly one request was made');
};

subtest 'the redirect is not chased even when the environment says otherwise' => sub {
    # Mojo::UserAgent defaults max_redirects to 0, but MOJO_MAX_REDIRECTS in the
    # ENVIRONMENT overrides that for every agent in the process, including one a
    # caller hands in. Following the 302 would pull the whole file into memory
    # and lose the Location that IS the answer.
    local $ENV{MOJO_MAX_REDIRECTS} = 5;
    is(Mojo::UserAgent->new->max_redirects, 5, 'a fresh agent does follow redirects here');

    my $origin = InternetDataTest::Origin->new(sub {
        my ($c, $o) = @_;
        if ($c->req->url->path->to_string eq '/api/v2/database/download') {
            $c->res->headers->location($o->url . '/file');
            return $c->rendered(302);
        }
        $c->render(data => 'the whole database');
    });
    my $ua = Mojo::UserAgent->new;
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k', ua => $ua);

    is($client->database->download_url('bogon_ip_v1', 'csvgz'), $origin->url . '/file',
        'the client still answers with the link');
    is($ua->max_redirects, 0, 'because it sets max_redirects on the agent it was given');
    is($origin->count, 1, 'and the file was never fetched');
};

subtest 'a 200 where a redirect belongs names the cause' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(data => 'the whole database');
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k');

    my $url = eval { $client->database->download_url('bogon_ip_v1', 'csvgz') };

    ok(!defined $url, 'a success where a 302 was expected is a failure');
    like($@->message, qr/must not follow redirects/, 'and says what would cause it');
};

subtest 'a redirect with no Location is reported rather than returned empty' => sub {
    my $origin = InternetDataTest::Origin->new(sub { shift->rendered(302) });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k');

    my $url = eval { $client->database->download_url('bogon_ip_v1', 'csvgz') };

    ok(!defined $url, 'there is nothing to hand back');
    like($@->message, qr/without a Location header/, 'and the message says so');
};

subtest 'an unknown option is refused rather than ignored' => sub {
    my $client = InternetData->new(api_key => 'k');

    eval { InternetData->new(api_key => 'k', timout => 5) };
    like($@, qr/unknown option/, 'a typo in a constructor option croaks');
    eval { $client->database->list(retires => 2) };
    like($@, qr/unknown option/, 'and so does one in a per-call option');
    eval { $client->database->metadata('bogon_ip_v1', retires => 2) };
    like($@, qr/unknown option/, 'on every call, not just the first');
    eval { InternetData->new(api_key => 'k', retries => -1) };
    like($@, qr/retries must be a whole number/, 'and a value that cannot work is refused too');
};

subtest 'a call refuses arguments it cannot use' => sub {
    my $client = InternetData->new(api_key => 'k');

    eval { $client->database->metadata('') };
    like($@, qr/expected a database id/, 'metadata needs an id');
    eval { $client->database->checksums('bogon_ip_v1') };
    like($@, qr/expected a format/, 'checksums needs a format');
    eval { $client->database->download_url(undef, 'csvgz') };
    like($@, qr/expected a database id/, 'download_url needs an id');
};

subtest 'the non-blocking API works where the blocking one cannot' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { databases => [InternetDataTest::family()] });
    });
    my $client = InternetData->new(base_url => $origin->url, api_key => 'k');

    my $seen;
    $client->database->list_p->then(sub { $seen = shift })->wait;
    is($seen->[0]{base}, 'bogon_ip', 'list_p resolves with the catalog');

    # Mojo::Promise::wait is a no-op inside an already running loop, so a
    # blocking call in a Mojolicious application would silently return undef.
    # Croaking instead points at the promise form, and does it BEFORE any
    # request is spent.
    $origin->reset;
    my $croaked;
    Mojo::IOLoop->next_tick(sub {
        eval { $client->database->list };
        $croaked = $@;
        Mojo::IOLoop->stop;
    });
    Mojo::IOLoop->start;
    like($croaked, qr/list_p/, 'blocking inside a running loop points at the promise form');
    is($origin->count, 0, 'and costs no request finding out');
};

subtest 'a transport failure is a retryable network error' => sub {
    # Nothing is listening, so the request never gets far enough to have a
    # status. Mojo::UserAgent rejects with a plain string there, which is exactly
    # the transport failure the retry rule treats as worth another attempt.
    my $client = InternetData->new(
        base_url => 'http://127.0.0.1:1', api_key => 'k', retries => 0, timeout => 5,
    );

    my $databases = eval { $client->database->list };

    ok(!defined $databases, 'the call failed');
    isa_ok($@, 'InternetData::Error', 'with');
    is($@->kind, 'network', 'classified as a transport failure');
    is($@->retryable, 1, 'and worth another attempt');
    is($@->status, undef, 'carrying no status, because there was no response');
};

done_testing();
