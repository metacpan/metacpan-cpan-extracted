#!/usr/bin/env perl
# karr k50: an HTTP error status dies with an object, not only a string.
#
# get/list/delete/update and every other call that checks a response died
# with the string "Kubernetes API error (<context>): <status> <body> at FILE
# line N." - to tell a 404 (already gone) or a 409 (conflict, re-read and
# retry) from a real failure, a caller had to parse that text. The response
# check now throws a Kubernetes::REST::APIError carrying the status, the
# Status body's reason/message/details, the decoded body, the context and the
# response. It stringifies to exactly the old message, location included, so
# code that prints or matches $@ is unaffected.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Encode ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::APIError;

# Answers 'METHOD /path' with a fixed status and raw body bytes, so a test can
# serve any status and a body that is not JSON at all; everything else goes to
# the mock (whose miss is a 404 Status).
{
    package Test::APIError::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has answers => (is => 'ro', default => sub { {} });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        my $answer = $self->answers->{ $req->method . ' ' . $path }
            or return $self->$orig($req);
        return Test::Kubernetes::Mock::Response->new(
            status  => $answer->[0],
            content => $answer->[1],
        );
    };
}

sub api_answering {
    my (%answers) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::APIError::IO->new(answers => \%answers),
    );
}

my $PODS = '/api/v1/namespaces/default/pods';

# What the API server really answers for a missing Pod.
my $NOT_FOUND = '{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",'
    . '"message":"pods \"web\" not found","reason":"NotFound",'
    . '"details":{"name":"web","kind":"pods"},"code":404}';

subtest 'a 404 Status: status, reason, message, details' => sub {
    my $api = api_answering("GET $PODS/web" => [ 404, $NOT_FOUND ]);

    my $line = __LINE__; my $ok = eval { $api->get('Pod', 'web', namespace => 'default'); 1 };
    my $err = $@;

    ok(!$ok, 'get died');
    isa_ok($err, 'Kubernetes::REST::APIError');
    is($err->code, 404, 'code is the HTTP status');
    ok($err->is_not_found, 'is_not_found');
    ok(!$err->is_conflict, 'not is_conflict');
    is($err->reason, 'NotFound', 'reason from the Status body');
    is($err->message, 'pods "web" not found', 'message from the Status body');
    is_deeply($err->details, { name => 'web', kind => 'pods' }, 'details from the Status body');
    is($err->body, $NOT_FOUND, 'body is the decoded body');
    is($err->context, 'get Pod', 'context names the operation');
    is($err->response && $err->response->status, 404, 'response is the response object');

    my $expected = "Kubernetes API error (get Pod): 404 $NOT_FOUND"
        . ' at ' . __FILE__ . " line $line.\n";
    is("$err", $expected, 'stringifies to the old message, naming the caller line');
    ok($err eq $expected, 'eq compares the string');
    ok($err, 'is true');
};

subtest 'a 409 Conflict' => sub {
    my $conflict = '{"kind":"Status","apiVersion":"v1","status":"Failure",'
        . '"message":"the object has been modified","reason":"Conflict","code":409}';
    my $api = api_answering("PUT $PODS/web" => [ 409, $conflict ]);
    my $pod = $api->new_object(Pod => {
        metadata => { name => 'web', namespace => 'default', resourceVersion => '1' },
    });

    eval { $api->update($pod) };
    my $err = $@;
    isa_ok($err, 'Kubernetes::REST::APIError');
    is($err->code, 409, 'code 409');
    ok($err->is_conflict, 'is_conflict');
    ok(!$err->is_not_found, 'not is_not_found');
    is($err->reason, 'Conflict', 'reason Conflict');
    is($err->context, 'update IO::K8s::Api::Core::V1::Pod', 'context names update');
};

subtest 'a body that is not a Status' => sub {
    for my $case (
        [ 'HTML from a proxy', 502, '<html><body>Bad Gateway</body></html>' ],
        [ 'JSON, not a Status', 500, '{"error":"boom"}' ],
        [ 'no body at all',     503, '' ],
    ) {
        my ($label, $status, $body) = @$case;
        my $api = api_answering("GET $PODS/web" => [ $status, $body ]);

        my $line = __LINE__; eval { $api->get('Pod', 'web', namespace => 'default') };
        my $err = $@;
        isa_ok($err, 'Kubernetes::REST::APIError', $label);
        is($err->code, $status, "$label: code");
        is($err->reason,  undef, "$label: no reason");
        is($err->message, undef, "$label: no message");
        is($err->details, undef, "$label: no details");
        is($err->body, $body, "$label: body as it came");
        ok(!$err->is_not_found && !$err->is_conflict, "$label: neither 404 nor 409");
        is("$err",
            "Kubernetes API error (get Pod): $status $body at " . __FILE__ . " line $line.\n",
            "$label: stringifies to the old message");
    }
};

subtest 'the body is decoded to characters' => sub {
    my $bytes = Encode::encode('UTF-8',
        '{"kind":"Status","status":"Failure","message":"ungültig: Café","reason":"Invalid","code":422}');
    my $api = api_answering("GET $PODS/web" => [ 422, $bytes ]);

    eval { $api->get('Pod', 'web', namespace => 'default') };
    my $err = $@;
    is($err->message, 'ungültig: Café', 'message holds characters');
    like($err->body, qr/ungültig: Café/, 'body holds characters');
};

# Net::Async::Kubernetes and other async wrappers call the public
# check_response from their own package; the location then names their line,
# as the croak did.
{
    package Test::APIError::Consumer;
    our $LINE;
    sub check {
        my ($api, $response) = @_;
        $LINE = __LINE__; $api->check_response($response, 'get Pod');
    }
}

subtest 'check_response from another package' => sub {
    my $api = api_answering();
    my $response = Test::Kubernetes::Mock::Response->new(status => 404, content => $NOT_FOUND);

    eval { Test::APIError::Consumer::check($api, $response) };
    my $err = $@;
    isa_ok($err, 'Kubernetes::REST::APIError');
    is("$err", "Kubernetes API error (get Pod): 404 $NOT_FOUND at " . __FILE__
        . " line $Test::APIError::Consumer::LINE.\n",
        'names the calling line in the calling package');
    is($err->response, $response, 'carries the very response object');

    my $fine = Test::Kubernetes::Mock::Response->new(status => 200, content => '{}');
    is($api->check_response($fine, 'get Pod'), $fine, 'a success status returns the response');

    # Without a context the message has empty parentheses, as it always had.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $line = __LINE__; eval { $api->check_response($response) };
    $err = $@;
    isa_ok($err, 'Kubernetes::REST::APIError', 'without a context');
    is("$err", "Kubernetes API error (): 404 $NOT_FOUND at " . __FILE__ . " line $line.\n",
        'without a context: the message has empty parentheses');
    is_deeply(\@warnings, [], 'without a context: no warning');
};

# Every call that checks a response throws the object: the mock answers a 404
# Status for anything it has no data for.
subtest 'every checked call throws it' => sub {
    my $api = Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::Kubernetes::Mock::IO->new,
    );
    my $pod = $api->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } });
    for my $case (
        [ list         => 'list Pod',        sub { $api->list('Pod', namespace => 'default') } ],
        [ get          => 'get Pod',         sub { $api->get('Pod', 'web', namespace => 'default') } ],
        [ create       => 'create ' . ref($pod), sub { $api->create($pod) } ],
        [ update       => 'update ' . ref($pod), sub { $api->update($pod) } ],
        [ patch        => 'patch ' . ref($pod),  sub {
            $api->patch('Pod', 'web', namespace => 'default', patch => { metadata => {} }) } ],
        [ delete       => 'delete ' . ref($pod), sub { $api->delete($pod) } ],
        [ watch        => 'watch Pod',       sub { $api->watch('Pod', namespace => 'default', on_event => sub {}) } ],
        [ log          => 'log Pod',         sub { $api->log('Pod', 'web', namespace => 'default') } ],
    ) {
        my ($method, $context, $call) = @$case;
        eval { $call->() };
        my $err = $@;
        isa_ok($err, 'Kubernetes::REST::APIError', $method);
        is(ref $err && $err->code, 404, "$method: code 404");
        is(ref $err && $err->context, $context, "$method: context");
        like("$err", qr/\AKubernetes API error \(\Q$context\E\): 404 /, "$method: message");
    }
};

done_testing;
