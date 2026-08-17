use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep);

use HTTP::API::Core;

my (@after, @errors);
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => {
        after_response => sub {
            my ($response, $ctx) = @_;
            push @after, [$response, {%$ctx}];
        },
        on_error => sub {
            my ($error, $ctx) = @_;
            push @errors, [$error, {%$ctx}];
        },
    },
    transport => sub {
        my ($method, $url, $opts) = @_;
        sleep 0.01;
        return {
            status => 200,
            reason => 'OK',
            headers => { 'X-Request-Id' => 'req-123' },
            content => '{}',
        };
    },
);

my $response = $api->get('/observed');
ok defined($response->elapsed), 'response exposes elapsed time';
cmp_ok $response->elapsed, '>=', 0, 'elapsed time is non-negative';
is $response->request_id, 'req-123', 'response exposes request ID';

is scalar(@after), 1, 'after_response called once';
ok defined($after[0][1]{started_at}), 'after_response context has started_at';
ok defined($after[0][1]{elapsed}), 'after_response context has elapsed';
cmp_ok $after[0][1]{elapsed}, '>=', 0, 'context elapsed is non-negative';
is $after[0][1]{request_id}, 'req-123', 'after_response context has request ID';
is $after[0][0]->elapsed, $after[0][1]{elapsed}, 'response and context share elapsed value';

my $failure = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    hooks => {
        on_error => sub {
            my ($error, $ctx) = @_;
            push @errors, [$error, {%$ctx}];
        },
    },
    transport => sub {
        sleep 0.005;
        return {
            status => 503,
            reason => 'Unavailable',
            headers => { 'X-Correlation-Id' => 'corr-9' },
            content => '{}',
        };
    },
);

my $error;
eval { $failure->get('/fail'); 1 } or $error = $@;
isa_ok $error, 'HTTP::API::Core::Error';
ok defined($error->elapsed), 'HTTP error exposes elapsed time';
cmp_ok $error->elapsed, '>=', 0, 'HTTP error elapsed is non-negative';
is $error->request_id, 'corr-9', 'HTTP error retains request ID';

is scalar(@errors), 1, 'on_error called once';
ok defined($errors[0][1]{started_at}), 'on_error context has started_at';
ok defined($errors[0][1]{elapsed}), 'on_error context has elapsed';
is $errors[0][1]{request_id}, 'corr-9', 'on_error context has request ID';

my $transport_failure = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub {
        sleep 0.002;
        die "socket exploded\n";
    },
);

my $transport_error;
eval { $transport_failure->get('/boom'); 1 } or $transport_error = $@;
isa_ok $transport_error, 'HTTP::API::Core::Error';
is $transport_error->category, 'transport', 'transport error category preserved';
ok defined($transport_error->elapsed), 'transport errors expose elapsed time';
cmp_ok $transport_error->elapsed, '>=', 0, 'transport error elapsed is non-negative';

done_testing;
