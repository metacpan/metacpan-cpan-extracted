#!/usr/bin/env perl
# karr k55: an HTTP error fetching /openapi/v2 dies with a
# Kubernetes::REST::APIError, like every other checked response.
#
# schema_for and compare_schema fetch the cluster's OpenAPI spec on first use.
# An error status there croaked with the plain string "Could not fetch OpenAPI
# spec: <status>" - no body, and nothing for a caller to branch on. It now
# goes through the same response check as every API call: an APIError with
# the status, the Status body's reason and message, context
# 'fetch OpenAPI spec', naming the caller's line.
#
# The 410 ERROR event of an expired watch stays a plain string on purpose:
# it is no HTTP status - the watch request itself was answered with 200 - and
# the caller's answer to it is a re-list, not error handling (see t/10).
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Answers 'METHOD /path' with a fixed status and raw body; everything else
# goes to the mock.
{
    package Test::K55::IO;
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
        io          => Test::K55::IO->new(answers => \%answers),
    );
}

my $FORBIDDEN = '{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",'
    . '"message":"forbidden: User \"system:anonymous\" cannot get path \"/openapi/v2\"",'
    . '"reason":"Forbidden","details":{},"code":403}';

for my $method (qw(schema_for compare_schema)) {
    subtest "$method: a 403 is an APIError" => sub {
        my $api = api_answering('GET /openapi/v2' => [ 403, $FORBIDDEN ]);

        my $line = __LINE__; my $ok = eval { $api->$method('Pod'); 1 };
        my $err = $@;

        ok(!$ok, "$method died");
        isa_ok($err, 'Kubernetes::REST::APIError');
        is($err->code, 403, 'code is the HTTP status');
        is($err->reason, 'Forbidden', 'reason from the Status body');
        like($err->message, qr/cannot get path "\/openapi\/v2"/, 'message from the Status body');
        is($err->context, 'fetch OpenAPI spec', 'context names the fetch');
        is("$err", "Kubernetes API error (fetch OpenAPI spec): 403 $FORBIDDEN"
            . " at $0 line $line.\n", 'stringifies with the body, at the caller\'s line');
    };
}

subtest 'a body that is no Status: code and body, no reason' => sub {
    my $api = api_answering('GET /openapi/v2' => [ 503, 'service unavailable' ]);
    eval { $api->schema_for('Pod') };
    my $err = $@;
    isa_ok($err, 'Kubernetes::REST::APIError');
    is($err->code, 503, 'code');
    is($err->body, 'service unavailable', 'body');
    ok(!defined $err->reason, 'no reason');
    unlike("$err", qr/Could not fetch OpenAPI spec/, 'not the old plain string');
};

subtest 'a failed fetch is not cached' => sub {
    my $api = api_answering('GET /openapi/v2' => [ 503, 'service unavailable' ]);
    ok(!eval { $api->schema_for('Pod'); 1 }, 'the first fetch fails');
    delete $api->io->answers->{'GET /openapi/v2'};
    $api->io->add_response('GET', '/openapi/v2', {
        definitions => { 'io.k8s.api.core.v1.Pod' => { description => 'a Pod' } },
    });
    is($api->schema_for('Pod')->{description}, 'a Pod', 'the next call fetches again');
};

done_testing;
