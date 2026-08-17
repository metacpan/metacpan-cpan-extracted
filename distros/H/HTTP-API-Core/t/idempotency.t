use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

sub client_with_capture {
    my @seen;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @seen, [$method, $url, $opts];
            return { status => 200, reason => 'OK', headers => {}, content => '{}' };
        },
    );
    return ($api, \@seen);
}

{
    my ($api, $seen) = client_with_capture();
    $api->post(
        '/payments',
        json => { amount => 1000 },
        idempotency => {
            key => 'payment-123',
            header => 'Idempotency-Key',
        },
    );

    is $seen->[0][2]{headers}{'Idempotency-Key'}, 'payment-123',
        'configured idempotency header is added';
}

{
    my ($api, $seen) = client_with_capture();
    $api->post(
        '/payments',
        headers => { 'idempotency-key' => 'explicit-key' },
        idempotency => {
            key => 'helper-key',
            header => 'Idempotency-Key',
        },
    );

    is $seen->[0][2]{headers}{'idempotency-key'}, 'explicit-key',
        'explicit case-insensitive request header wins';
    ok !exists $seen->[0][2]{headers}{'Idempotency-Key'},
        'no duplicate idempotency header is added';
}

{
    my ($api, $seen) = client_with_capture();
    $api->post(
        '/jobs',
        idempotency => {
            key => 'job-42',
            header => 'X-Request-Deduplication',
        },
    );

    is $seen->[0][2]{headers}{'X-Request-Deduplication'}, 'job-42',
        'custom service-specific header is supported';
}

{
    my ($api, $seen) = client_with_capture();
    $api->post(
        '/payments',
        idempotency => {
            key => 'payment-123',
            header => 'Idempotency-Key',
        },
    );

    is scalar(@$seen), 1, 'POST is still not automatically retried';
}

{
    my ($api) = client_with_capture();

    my @bad = (
        [ 'key', qr/hash reference/ ],
        [ {}, qr/key must be a non-empty/ ],
        [ { key => '', header => 'Idempotency-Key' }, qr/key must be a non-empty/ ],
        [ { key => 'x' }, qr/header must be a non-empty/ ],
        [ { key => 'x', header => '' }, qr/header must be a non-empty/ ],
        [ { key => 'x', header => 'Idempotency-Key', extra => 1 }, qr/unknown idempotency option/ ],
    );

    for my $case (@bad) {
        my ($value, $re) = @$case;
        my $ok = eval { $api->post('/x', idempotency => $value); 1 };
        ok !$ok, 'invalid idempotency configuration is rejected';
        like $@, $re, 'invalid idempotency error is descriptive';
    }
}

done_testing;
