#!/usr/bin/env perl
# karr k59: an HTTP error reading discovery is a Kubernetes::REST::APIError.
#
# Reading GET /api or GET /apis croaked the plain string "discovery GET /api
# failed: 401" - the status without the body, which says why (Unauthorized,
# Forbidden), and nothing for a caller to branch on. The read now goes
# through the same response check as every API call: absorb_discovery dies
# with an APIError, context 'discovery GET /api', at the caller's line. The
# client's own read embeds it where it names the reason - the unknown
# resource croak, build_path for IO::K8s::Unstructured, fetch_resource_map
# and the fallback warning - as its message without a location of its own,
# so each message names one line: the caller's.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::HTTPResponse;

my $UNAUTHORIZED = '{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",'
    . '"message":"Unauthorized","reason":"Unauthorized","code":401}';

# Answers 'METHOD /path' with a fixed status and raw body; everything else
# goes to the mock.
{
    package Test::K59::IO;
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

my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

my $CORE = { kind => 'APIGroupDiscoveryList', items => [ {
    metadata => { name => '' },
    versions => [ { version => 'v1', resources => [ {
        resource     => 'pods',
        responseKind => { group => '', version => 'v1', kind => 'Pod' },
        scope        => 'Namespaced',
    } ] } ],
} ] };

# A client reading discovery itself, /api answered 401.
sub api_unauthorized {
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::K59::IO->new(answers => { 'GET /api' => [ 401, $UNAUTHORIZED ] }),
    );
}

sub response {
    my ($status, $body) = @_;
    return Kubernetes::REST::HTTPResponse->new(
        status  => $status,
        content => ref $body ? $wire_json->encode($body) : $body,
    );
}

sub locations {
    my ($text) = @_;
    return scalar(() = $text =~ / at \S+ line \d+\./g);
}

my $REASON = "Kubernetes API error (discovery GET /api): 401 $UNAUTHORIZED";

subtest 'absorb_discovery: an HTTP error is an APIError' => sub {
    my $api = Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::K59::IO->new,
    );
    my $failed = response(401, $UNAUTHORIZED);

    my %responses = ('/api' => $failed, '/apis' => response(200, $CORE));
    my $line = __LINE__; my $ok = eval { $api->absorb_discovery(%responses); 1 };
    my $err = $@;
    ok(!$ok, 'absorb_discovery died');
    isa_ok($err, 'Kubernetes::REST::APIError') or return;
    is($err->code, 401, 'code is the HTTP status');
    is($err->reason, 'Unauthorized', 'reason from the Status body');
    is($err->context, 'discovery GET /api', 'context names the discovery read');
    is($err->response, $failed, 'the response handed over');
    is("$err", "$REASON at $0 line $line.\n",
        'stringifies with the body, at the caller\'s line');
    ok(!$api->_has_discovery, 'no catalog cached');

    eval {
        $api->absorb_discovery('/api' => response(200, $CORE),
            '/apis' => response(503, 'unavailable'));
    };
    isa_ok($@, 'Kubernetes::REST::APIError', 'a 503 on /apis') or return;
    is($@->context, 'discovery GET /apis', 'context names /apis');
    is($@->body, 'unavailable', 'with the body');
};

subtest 'the unknown resource croak names the reason once' => sub {
    my $api = api_unauthorized();
    # Resolving Widget builds the resource map too, which falls back to the
    # built-in one with a warning - pinned below.
    local $SIG{__WARN__} = sub { };
    my $line = __LINE__; eval { $api->list('Widget', namespace => 'default') };
    is($@, "unknown resource 'Widget': no IO::K8s class for this apiVersion/kind"
        . ' (add it to resource_map if it is a CRD); discovery failed, so the cluster'
        . " could not confirm it: $REASON at $0 line $line.\n",
        'the APIError\'s message, the caller\'s line only');
};

subtest 'build_path for IO::K8s::Unstructured names the reason once' => sub {
    my $api = api_unauthorized();
    my @args = ('IO::K8s::Unstructured', kind => 'Widget', name => 'w1');
    my $line = __LINE__; eval { $api->build_path(@args) };
    is($@, "discovery failed, so Kind 'Widget' is unconfirmed - cannot build a path"
        . " for IO::K8s::Unstructured: $REASON at $0 line $line.\n",
        'the APIError\'s message, the caller\'s line only');
};

subtest 'fetch_resource_map names the reason once' => sub {
    my $api = api_unauthorized();
    my $line = __LINE__; eval { $api->fetch_resource_map };
    is($@, "Could not load resource map from cluster: $REASON at $0 line $line.\n",
        'its own wording, the APIError\'s message, the caller\'s line only');
};

subtest 'the embedded reason drops each form of location Carp writes' => sub {
    # After a file handle was read - kube_client create reads its manifest
    # from STDIN - Carp's location ends ', <$fh> line N.', or 'chunk N' with
    # another $/. Reproducing that through a request depends on which handle
    # was read last, so the helper that renders the reason is asked directly.
    my $api = api_unauthorized();
    for my $case (
        [ 'plain',                " at /x/REST.pm line 3.\n" ],
        [ 'after a read',         " at /x/REST.pm line 3, <\$fh> line 1.\n" ],
        [ 'after a chunked read', " at /x/REST.pm line 3, <STDIN> chunk 2.\n" ],
        [ 'none',                 '' ],
    ) {
        my ($what, $location) = @$case;
        is($api->_error_reason("boom at noon, 503$location"), 'boom at noon, 503',
            "$what: the location goes, an ' at ' in the text stays");
    }
    my $err = eval {
        Kubernetes::REST::APIError->throw(code => 401, body => 'nope', context => 'x');
    };
    is($api->_error_reason($@), 'Kubernetes API error (x): 401 nope', 'an APIError');
};

subtest 'the fallback to the built-in map warns with the reason once' => sub {
    my $api = api_unauthorized();
    my @warnings;
    my $map = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->resource_map;
    };
    is(scalar @warnings, 1, 'one warning');
    like($warnings[0], qr/\AFalling back to the built-in resource map: Could not load resource map from cluster: \Q$REASON\E at /,
        'names the load failure and the APIError\'s message');
    is(locations($warnings[0]), 1, 'with one location');
    ok($map->{Pod}, 'the built-in map comes back');
};

done_testing;
