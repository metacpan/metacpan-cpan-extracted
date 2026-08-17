use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

my @events;
my $calls = 0;

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => {
        attempts => 2,
        base_delay => 0,
        max_delay => 0,
        jitter => 0,
    },
    hooks => {
        before_request => sub {
            my ($ctx) = @_;
            push @events, "before:$ctx->{attempt}";
            $ctx->{headers}{'X-Trace'} = "attempt-$ctx->{attempt}";
        },
        after_response => sub {
            my ($response, $ctx) = @_;
            push @events, "after:" . $response->status . ":$ctx->{attempt}";
        },
        on_error => sub {
            my ($error, $ctx) = @_;
            push @events, "error:" . $error->status . ":$ctx->{attempt}";
        },
    },
    transport => sub {
        my ($method, $url, $opts) = @_;
        $calls++;
        is $opts->{headers}{'X-Trace'}, "attempt-$calls", 'before_request can mutate headers';

        return {
            status => 503,
            reason => 'Unavailable',
            headers => {},
            content => '{}',
        } if $calls == 1;

        return {
            status => 200,
            reason => 'OK',
            headers => {},
            content => '{"ok":true}',
        };
    },
);

my $res = $api->get('/items');
is $res->status, 200, 'request succeeds after retry';
is_deeply(
    \@events,
    ['before:1', 'error:503:1', 'before:2', 'after:200:2'],
    'hooks run once per attempt around retry',
);

my @ordered;
my $ordered_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        before_request => [
            sub { push @ordered, 'client-1' },
            sub { push @ordered, 'client-2' },
        ],
    },
    transport => sub {
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);

$ordered_api->get('/x',
    hooks => {
        before_request => sub { push @ordered, 'request' },
    },
);
is_deeply \@ordered, [qw(client-1 client-2 request)], 'request hooks append after client hooks';

my $url_seen;
my $mutation_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        before_request => sub {
            my ($ctx) = @_;
            $ctx->{url} = 'https://other.example.test/rewritten';
            $ctx->{content} = 'changed';
        },
    },
    transport => sub {
        my ($method, $url, $opts) = @_;
        $url_seen = $url;
        is $opts->{content}, 'changed', 'before_request can replace content';
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);
$mutation_api->post('/original', content => 'initial');
is $url_seen, 'https://other.example.test/rewritten', 'before_request can replace URL';

my $hook_error_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => { before_request => sub { die "boom\n" } },
    transport => sub { die 'transport must not run' },
);
my $hook_error;
eval { $hook_error_api->get('/x'); 1 } or $hook_error = $@;
isa_ok $hook_error, 'HTTP::API::Core::Error';
is $hook_error->category, 'hook', 'hook failure has hook category';
ok !$hook_error->retryable, 'hook failure is not retryable';
like "$hook_error", qr/hook failed: boom/, 'hook failure keeps useful cause';

eval {
    HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        hooks => { nope => sub {} },
    );
    1;
};
like $@, qr/unknown hook: nope/, 'unknown hook rejected';

eval {
    HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        hooks => { before_request => ['not-code'] },
    );
    1;
};
like $@, qr/must be a code reference/, 'invalid hook rejected';

done_testing;
