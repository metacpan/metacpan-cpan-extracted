#!/usr/bin/env perl
# Tests for the Kubernetes Pod Log API using mock data.
#
# Run:
#   prove -l t/20_log.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::LogEvent;

my $mock_io = Test::Kubernetes::Mock::IO->new;

my $api = Kubernetes::REST->new(
    server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
    credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
    resource_map_from_cluster => 0,
    io          => $mock_io,
);

# === Test 1: One-shot log retrieval ===
subtest 'one-shot log' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/nginx-abc/log', [
        '2024-01-01T00:00:00Z Starting nginx',
        '2024-01-01T00:00:01Z Listening on port 80',
        '2024-01-01T00:00:02Z Ready to accept connections',
    ]);

    my $text = $api->log('Pod', 'nginx-abc', namespace => 'default');

    like($text, qr/Starting nginx/, 'log contains first line');
    like($text, qr/Listening on port 80/, 'log contains second line');
    like($text, qr/Ready to accept connections/, 'log contains third line');
};

# === Test 2: Streaming log with on_line callback ===
subtest 'streaming log' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/nginx-abc/log', [
        'line 1: hello',
        'line 2: world',
        'line 3: done',
    ]);

    my @events;
    $api->log('Pod', 'nginx-abc',
        namespace => 'default',
        follow    => 1,
        on_line   => sub { push @events, $_[0] },
    );

    is(scalar @events, 3, 'received 3 log events');

    isa_ok($events[0], 'Kubernetes::REST::LogEvent', 'event is LogEvent');
    is($events[0]->line, 'line 1: hello', 'first line');
    is($events[1]->line, 'line 2: world', 'second line');
    is($events[2]->line, 'line 3: done', 'third line');
};

# === Test 3: LogEvent class ===
subtest 'LogEvent class' => sub {
    my $event = Kubernetes::REST::LogEvent->new(line => 'test log line');
    ok($event, 'LogEvent created');
    is($event->line, 'test log line', 'line accessor');
};

# === Test 4: log requires name ===
subtest 'log requires name' => sub {
    throws_ok {
        $api->log('Pod', namespace => 'default');
    } qr/name required/, 'dies without name';
};

# === Test 5: log with name as key-value ===
subtest 'log with name as key-value' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/my-pod/log', [
        'key-value style works',
    ]);

    my $text = $api->log('Pod', name => 'my-pod', namespace => 'default');
    like($text, qr/key-value style works/, 'name as key-value works');
};

# === Test 6: log with tailLines parameter ===
subtest 'log with tailLines' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/staging/pods/app-xyz/log', [
        'last line',
    ]);

    my $text = $api->log('Pod', 'app-xyz',
        namespace => 'staging',
        tailLines => 10,
    );

    like($text, qr/last line/, 'tailLines log works');
};

# === Test 7: log with container parameter ===
subtest 'log with container' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/multi-container/log', [
        'sidecar output',
    ]);

    my @events;
    $api->log('Pod', 'multi-container',
        namespace => 'default',
        container => 'sidecar',
        on_line   => sub { push @events, $_[0] },
    );

    is(scalar @events, 1, 'received log from container');
    is($events[0]->line, 'sidecar output', 'container log line');
};

# === Test 8: log with timestamps ===
subtest 'log with timestamps' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/ts-pod/log', [
        '2024-01-01T12:00:00.000Z log with timestamp',
    ]);

    my $text = $api->log('Pod', 'ts-pod',
        namespace  => 'default',
        timestamps => 1,
    );

    like($text, qr/2024-01-01T12:00:00/, 'timestamps in log');
};

# === Test 9: log with previous ===
subtest 'log with previous' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/crashed-pod/log', [
        'previous container output before crash',
    ]);

    my $text = $api->log('Pod', 'crashed-pod',
        namespace => 'default',
        previous  => 1,
    );

    like($text, qr/before crash/, 'previous container log');
};

# === Test 10: process_log_chunk public method ===
subtest 'process_log_chunk public method' => sub {
    my $buffer = '';
    my @events = $api->process_log_chunk(\$buffer, "first line\nsecond line\n");

    is(scalar @events, 2, 'two events from chunk');
    isa_ok($events[0], 'Kubernetes::REST::LogEvent');
    is($events[0]->line, 'first line', 'first line from chunk');
    is($events[1]->line, 'second line', 'second line from chunk');

    # Partial line stays in buffer
    @events = $api->process_log_chunk(\$buffer, "partial");
    is(scalar @events, 0, 'no events from partial line');
    is($buffer, 'partial', 'partial line in buffer');

    # Complete the partial line
    @events = $api->process_log_chunk(\$buffer, " line complete\n");
    is(scalar @events, 1, 'one event after completing partial');
    is($events[0]->line, 'partial line complete', 'partial line completed');
};

# === Test 11: build_path public method ===
subtest 'build_path public method' => sub {
    my $class = $api->expand_class('Pod');
    my $path = $api->build_path($class, name => 'test-pod', namespace => 'default');
    is($path, '/api/v1/namespaces/default/pods/test-pod', 'build_path returns correct path');

    my $log_path = $path . '/log';
    is($log_path, '/api/v1/namespaces/default/pods/test-pod/log', 'log path correct');
};

# === Test 12: prepare_request public method ===
subtest 'prepare_request public method' => sub {
    my $req = $api->prepare_request('GET', '/api/v1/namespaces/default/pods/test-pod/log',
        parameters => { follow => 'true', tailLines => 100 },
    );

    is($req->method, 'GET', 'request method');
    like($req->url, qr{/api/v1/namespaces/default/pods/test-pod/log}, 'request url');
    like($req->url, qr{follow=true}, 'follow parameter in url');
    like($req->url, qr{tailLines=100}, 'tailLines parameter in url');
};

# === Test 13: LogEvent requires line ===
subtest 'LogEvent requires line' => sub {
    throws_ok {
        Kubernetes::REST::LogEvent->new();
    } qr/required/, 'LogEvent dies without line';
};

# === Test 14: empty log output ===
subtest 'empty log' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/empty-pod/log', []);

    my $text = $api->log('Pod', 'empty-pod', namespace => 'default');
    is($text, "\n", 'empty log returns newline');

    my @events;
    $api->log('Pod', 'empty-pod',
        namespace => 'default',
        on_line   => sub { push @events, $_[0] },
    );
    is(scalar @events, 0, 'no events from empty log stream');
};

# === Test 15: log with sinceSeconds ===
subtest 'log with sinceSeconds' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/recent-pod/log', [
        'recent log line',
    ]);

    my $text = $api->log('Pod', 'recent-pod',
        namespace    => 'default',
        sinceSeconds => 3600,
    );

    like($text, qr/recent log line/, 'sinceSeconds log works');
};

# === Test 16: log with sinceTime ===
subtest 'log with sinceTime' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/time-pod/log', [
        'log after time',
    ]);

    my $text = $api->log('Pod', 'time-pod',
        namespace => 'default',
        sinceTime => '2024-01-01T00:00:00Z',
    );

    like($text, qr/log after time/, 'sinceTime log works');
};

# === Test 17: log with limitBytes ===
subtest 'log with limitBytes' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/big-pod/log', [
        'limited output',
    ]);

    my $text = $api->log('Pod', 'big-pod',
        namespace  => 'default',
        limitBytes => 1024,
    );

    like($text, qr/limited output/, 'limitBytes log works');
};

# === Test 18: process_log_chunk with multiple chunks simulating real streaming ===
subtest 'process_log_chunk multi-chunk streaming' => sub {
    my $buffer = '';

    # First chunk: one complete line + start of second
    my @events = $api->process_log_chunk(\$buffer, "complete line\npartial li");
    is(scalar @events, 1, 'one complete line from first chunk');
    is($events[0]->line, 'complete line', 'first chunk complete line');
    is($buffer, 'partial li', 'buffer holds partial');

    # Second chunk: rest of second line + third line
    @events = $api->process_log_chunk(\$buffer, "ne here\nthird line\n");
    is(scalar @events, 2, 'two lines from second chunk');
    is($events[0]->line, 'partial line here', 'reassembled partial line');
    is($events[1]->line, 'third line', 'third line from second chunk');
    is($buffer, '', 'buffer empty after complete lines');
};

# === Test 19: process_log_chunk preserves empty lines ===
subtest 'process_log_chunk empty lines' => sub {
    my $buffer = '';
    my @events = $api->process_log_chunk(\$buffer, "line one\n\nline three\n");
    is(scalar @events, 3, 'three events including empty line');
    is($events[0]->line, 'line one', 'first line');
    is($events[1]->line, '', 'empty line preserved');
    is($events[2]->line, 'line three', 'third line');
};

# === Test 20: check_response public method ===
subtest 'check_response public method' => sub {
    my $ok_response = Test::Kubernetes::Mock::Response->new(
        status => 200, content => 'ok',
    );
    my $result = $api->check_response($ok_response, 'test');
    is($result->status, 200, 'check_response passes on 200');

    my $err_response = Test::Kubernetes::Mock::Response->new(
        status => 404, content => 'not found',
    );
    throws_ok {
        $api->check_response($err_response, 'test op');
    } qr/test op.*404/, 'check_response croaks on 404';
};

# === Test 21: inflate_object public method ===
subtest 'inflate_object public method' => sub {
    my $class = $api->expand_class('Namespace');
    my $response = Test::Kubernetes::Mock::Response->new(
        status => 200,
        content => '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"test-ns"}}',
    );
    my $obj = $api->inflate_object($class, $response);
    is($obj->metadata->name, 'test-ns', 'inflate_object inflates correctly');
};

# === Test 22: inflate_list public method ===
subtest 'inflate_list public method' => sub {
    my $class = $api->expand_class('Namespace');
    my $response = Test::Kubernetes::Mock::Response->new(
        status => 200,
        content => '{"apiVersion":"v1","kind":"NamespaceList","items":[{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"ns-a"}},{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"ns-b"}}]}',
    );
    my $list = $api->inflate_list($class, $response);
    is(scalar @{$list->items}, 2, 'inflate_list returns 2 items');
    is($list->items->[0]->metadata->name, 'ns-a', 'first item name');
    is($list->items->[1]->metadata->name, 'ns-b', 'second item name');
};

# === Test 23: process_watch_chunk public method ===
subtest 'process_watch_chunk public method' => sub {
    my $class = $api->expand_class('Pod');
    my $buffer = '';
    my $json_line = '{"type":"ADDED","object":{"apiVersion":"v1","kind":"Pod","metadata":{"name":"watch-pod","namespace":"default","resourceVersion":"999"},"spec":{"containers":[{"name":"nginx","image":"nginx"}]},"status":{"phase":"Running"}}}' . "\n";

    my @results = $api->process_watch_chunk($class, \$buffer, $json_line);
    is(scalar @results, 1, 'one watch event from chunk');
    is($results[0]->{event}->type, 'ADDED', 'event type is ADDED');
    is($results[0]->{resourceVersion}, '999', 'resourceVersion tracked');
    isa_ok($results[0]->{event}->object, 'IO::K8s::Api::Core::V1::Pod', 'inflated to Pod');
    is($results[0]->{event}->object->metadata->name, 'watch-pod', 'pod name correct');
};

# === Test 24: log streaming returns undef ===
subtest 'log streaming returns undef' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/void-pod/log', [
        'some output',
    ]);

    my $result = $api->log('Pod', 'void-pod',
        namespace => 'default',
        on_line   => sub {},
    );
    is($result, undef, 'streaming log returns undef');
};

# === Test 25: log one-shot returns string ===
subtest 'log one-shot returns string' => sub {
    $mock_io->add_log_lines('/api/v1/namespaces/default/pods/string-pod/log', [
        'line A',
        'line B',
    ]);

    my $text = $api->log('Pod', 'string-pod', namespace => 'default');
    ok(defined $text, 'one-shot log returns defined value');
    ok(length($text) > 0, 'one-shot log returns non-empty string');
};

# === Test 26: all log query parameters included in request ===
subtest 'all log query parameters in request' => sub {
    my $req = $api->prepare_request('GET', '/api/v1/namespaces/default/pods/test/log',
        parameters => {
            container    => 'sidecar',
            follow       => 'true',
            tailLines    => 50,
            sinceSeconds => 3600,
            sinceTime    => '2024-01-01T00:00:00Z',
            timestamps   => 'true',
            previous     => 'true',
            limitBytes   => 1024,
        },
    );

    like($req->url, qr{container=sidecar}, 'container in URL');
    like($req->url, qr{follow=true}, 'follow in URL');
    like($req->url, qr{tailLines=50}, 'tailLines in URL');
    like($req->url, qr{sinceSeconds=3600}, 'sinceSeconds in URL');
    like($req->url, qr{sinceTime=}, 'sinceTime in URL');
    like($req->url, qr{timestamps=true}, 'timestamps in URL');
    like($req->url, qr{previous=true}, 'previous in URL');
    like($req->url, qr{limitBytes=1024}, 'limitBytes in URL');
};

done_testing;
