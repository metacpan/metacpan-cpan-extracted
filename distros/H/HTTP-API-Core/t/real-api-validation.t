use strict;
use warnings;
use Test::More;
use utf8;

use lib 'examples';
use HTTP::API::Core::Example::Stripe;
use HTTP::API::Core::Example::GitLab;

subtest stripe => sub {
    my @calls;
    my $client = HTTP::API::Core::Example::Stripe->new(
        token => 'sk_test_example',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @calls, [$method, $url, $opts];
            my $content = $url =~ /starting_after=cus_2/
                ? '{"object":"list","data":[{"id":"cus_3"}],"has_more":false}'
                : '{"object":"list","data":[{"id":"cus_1"},{"id":"cus_2"}],"has_more":true}';
            return {
                status => 200,
                headers => {
                    'Content-Type' => 'application/json',
                    'Request-Id' => 'req_example',
                },
                content => $content,
            };
        },
    );

    my @customers = $client->customers_pager(limit => 2)->all;
    is_deeply [map { $_->{id} } @customers], [qw(cus_1 cus_2 cus_3)],
        'follows Stripe starting_after cursor';
    like $calls[1][1], qr/(?:[?&])starting_after=cus_2(?:&|$)/,
        'uses the last object id as Stripe cursor';
    is $calls[0][2]{headers}{Authorization}, 'Bearer sk_test_example',
        'uses bearer authentication';

    $client->create_customer(
        email => 'a+b\@example.test',
        idempotency_key => 'idem-123',
    );
    is $calls[2][2]{headers}{'Idempotency-Key'}, 'idem-123',
        'maps generic idempotency support to Stripe header';
    is $calls[2][2]{headers}{'content-type'}, 'application/x-www-form-urlencoded',
        'uses Stripe form encoding';
    like $calls[2][2]{content}, qr/email=a%2Bb%5C%40example\.test/,
        'form body is encoded by the service-specific recipe';

    $client->create_customer(name => "é😀");
    like $calls[3][2]{content}, qr/name=%C3%A9%F0%9F%98%80/,
        'form body percent-encodes UTF-8 bytes for non-ASCII text';
};

subtest gitlab => sub {
    my @calls;
    my $client = HTTP::API::Core::Example::GitLab->new(
        token => 'gitlab-token',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @calls, [$method, $url, $opts];
            my $content = $url =~ /(?:[?&])page=2(?:&|$)/
                ? '[]'
                : '[{"id":1},{"id":2}]';
            return {
                status => 200,
                headers => {
                    'Content-Type' => 'application/json',
                    'X-Request-Id' => 'gitlab-request',
                    'RateLimit-Limit' => '600',
                    'RateLimit-Remaining' => '599',
                },
                content => $content,
            };
        },
    );

    my @projects = $client->projects_pager(per_page => 2, membership => 'true')->all;
    is_deeply [map { $_->{id} } @projects], [1, 2],
        'reads GitLab top-level arrays with page pagination';
    is $calls[0][2]{headers}{'PRIVATE-TOKEN'}, 'gitlab-token',
        'uses GitLab private-token header';
    like $calls[0][1], qr/(?:[?&])membership=true(?:&|$)/,
        'passes GitLab query filters';
    like $calls[1][1], qr/(?:[?&])page=2(?:&|$)/,
        'advances GitLab page number';
};

done_testing;
