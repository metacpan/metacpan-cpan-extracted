use strict;
use warnings;
use Test::More;
use HTTP::API::Core;
use HTTP::API::Core::Error;

sub ok_response {
    return { status => 200, reason => 'OK', headers => {}, content => '{}' };
}

# Constructor and request hook validation.
for my $case (
    [ hooks => 'bad', qr/hooks must be a hash reference/ ],
    [ hooks => { unknown => sub {} }, qr/unknown hook: unknown/ ],
    [ hooks => { before_request => ['bad'] }, qr/must be a code reference/ ],
) {
    my ($name, $value, $expected) = @$case;
    my $error;
    eval {
        HTTP::API::Core->new(
            base_url => 'https://api.example.test',
            $name => $value,
            transport => sub { ok_response() },
        );
        1;
    } or $error = $@;
    like $error, $expected, 'constructor hook validation is stable';
}

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub { ok_response() },
);

my $request_error;
eval { $api->get('/x', hooks => 'bad'); 1 } or $request_error = $@;
like $request_error, qr/hooks must be a hash reference/, 'request hook validation is stable';

# Client hooks precede request hooks and preserve declaration order.
my @order;
my $ordered = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        before_request => [
            sub { push @order, 'client-1' },
            sub { push @order, 'client-2' },
        ],
    },
    transport => sub { ok_response() },
);
$ordered->get('/ordered', hooks => {
    before_request => [
        sub { push @order, 'request-1' },
        sub { push @order, 'request-2' },
    ],
});
is_deeply \@order,
    [qw(client-1 client-2 request-1 request-2)],
    'client and request hooks have stable ordering';

# Context mutation is applied to the current attempt.
my $seen;
my $mutable = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        before_request => sub {
            my ($ctx) = @_;
            $ctx->{method} = 'PUT';
            $ctx->{url} = 'https://other.example.test/replaced';
            $ctx->{headers}{'X-Hook'} = 'yes';
            $ctx->{content} = 'replaced';
        },
    },
    transport => sub {
        my ($method, $url, $opts) = @_;
        $seen = [$method, $url, $opts];
        return ok_response();
    },
);
$mutable->post('/original', content => 'initial');
is $seen->[0], 'PUT', 'before_request can replace method';
is $seen->[1], 'https://other.example.test/replaced', 'before_request can replace URL';
is $seen->[2]{headers}{'X-Hook'}, 'yes', 'before_request can mutate headers';
is $seen->[2]{content}, 'replaced', 'before_request can replace content';

# Success and failure callbacks receive their documented argument types and context.
my ($after_response, $after_context);
my $success = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        after_response => sub { ($after_response, $after_context) = @_ },
    },
    transport => sub { +{
        status => 200,
        reason => 'OK',
        headers => { 'X-Request-Id' => 'req-success' },
        content => '{}',
    } },
);
$success->get('/success');
isa_ok $after_response, 'HTTP::API::Core::Response';
is $after_context->{attempt}, 1, 'after_response context includes attempt';
ok defined $after_context->{started_at}, 'after_response context includes started_at';
ok defined $after_context->{elapsed}, 'after_response context includes elapsed';
is $after_context->{request_id}, 'req-success', 'after_response context includes request_id';

my ($on_error, $error_context);
my $failure = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        on_error => sub { ($on_error, $error_context) = @_ },
    },
    transport => sub { +{
        status => 503,
        reason => 'Unavailable',
        headers => { 'X-Request-Id' => 'req-error' },
        content => '{}',
    } },
);
my $http_error;
eval { $failure->get('/failure'); 1 } or $http_error = $@;
isa_ok $on_error, 'HTTP::API::Core::Error';
is $error_context->{attempt}, 1, 'on_error context includes attempt';
ok defined $error_context->{elapsed}, 'on_error context includes elapsed';
is $error_context->{request_id}, 'req-error', 'on_error context includes request_id';

# Hook failures are structured, non-retryable, and preserve existing core errors.
my $wrapped = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 3, base_delay => 0, jitter => 0 },
    hooks => { before_request => sub { die "plain hook failure\n" } },
    transport => sub { die 'transport must not run' },
);
my $wrapped_error;
eval { $wrapped->get('/wrapped'); 1 } or $wrapped_error = $@;
isa_ok $wrapped_error, 'HTTP::API::Core::Error';
is $wrapped_error->category, 'hook', 'ordinary hook failures use hook category';
ok !$wrapped_error->retryable, 'hook failures are not retryable';

my $original = HTTP::API::Core::Error->new(
    category => 'hook',
    method => 'GET',
    url => 'https://api.example.test/preserved',
    message => 'already structured',
);
my $preserving = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => { before_request => sub { die $original } },
    transport => sub { die 'transport must not run' },
);
my $preserved;
eval { $preserving->get('/preserved'); 1 } or $preserved = $@;
is $preserved, $original, 'existing HTTP::API::Core::Error is preserved';

done_testing;
