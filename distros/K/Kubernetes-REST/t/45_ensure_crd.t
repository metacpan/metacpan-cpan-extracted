#!/usr/bin/env perl
# Tests for ensure_crd: apply CRDs from typed classes, wait for the Established
# condition, then invalidate discovery. Mock-driven (no cluster).

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Test::Kubernetes::Mock qw(mock_api);

# --- Inline CRD classes (a single-version CRD and a two-version CRD) ----------
BEGIN {
    package My::CRD::V1::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    k8s hostname => Str;
    k8s replicas => Int;
    $INC{'My/CRD/V1/StaticWebSite.pm'} = 1;

    package My::CRD::V1beta1::Widget;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1beta1',
        resource_plural => 'widgets';
    k8s size => Str;
    $INC{'My/CRD/V1beta1/Widget.pm'} = 1;

    package My::CRD::V1::Widget;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'widgets';
    k8s size => Int;
    $INC{'My/CRD/V1/Widget.pm'} = 1;
}

my $CRD_PATH   = '/apis/apiextensions.k8s.io/v1/customresourcedefinitions';
my $json       = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# Build a CustomResourceDefinition manifest with optional Established=True.
sub crd_manifest {
    my (%a) = @_;
    my %m = (
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => $a{name}, resourceVersion => $a{rv} // '1' },
        spec       => {
            group => $a{group},
            scope => 'Cluster',
            names => { plural => $a{plural}, kind => $a{kind}, singular => lc($a{kind}) },
            versions => [ map { { name => $_, served => \1, storage => \0 } } @{ $a{versions} } ],
        },
    );
    $m{status} = { conditions => [
        { type => 'Established', status => ($a{established} ? 'True' : 'False') },
    ] } if exists $a{established};
    return \%m;
}

# Find the request captured for a given method (last match wins).
sub last_request {
    my ($io, $method) = @_;
    my ($req) = grep { $_->{method} eq $method } reverse @{ $io->requests };
    return $req;
}

# ---------------------------------------------------------------------------
# Case 1: happy path. The CRD already exists (ensure -> PUT) and reports
# Established=True immediately, so ensure_crd applies it, the first poll
# succeeds, and discovery is invalidated exactly once.
# ---------------------------------------------------------------------------
subtest 'apply + wait Established + invalidate (update path)' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    my $name = 'staticwebsites.homelab.example.com';
    my $body = crd_manifest(
        name => $name, group => 'homelab.example.com',
        plural => 'staticwebsites', kind => 'StaticWebSite',
        versions => ['v1'], established => 1, rv => '7',
    );
    $io->add_response('GET', "$CRD_PATH/$name", $body);
    $io->add_response('PUT', "$CRD_PATH/$name", $body);

    my $invalidated = 0;
    my $orig = \&Kubernetes::REST::invalidate_discovery;
    no warnings 'redefine';
    local *Kubernetes::REST::invalidate_discovery =
        sub { $invalidated++; goto &$orig };
    use warnings;

    my @out = $api->ensure_crd('My::CRD::V1::StaticWebSite');

    is(scalar @out, 1, 'one established CRD returned');
    is($out[0]->metadata->name, $name, 'returned CRD is the expected one');
    ok($api->_crd_established($out[0]), 'returned CRD carries Established=True');
    is($invalidated, 1, 'invalidate_discovery called exactly once');

    # The applied payload is the CRD built from to_crd (verify path + body).
    my $put = last_request($io, 'PUT');
    ok($put, 'a PUT request was issued');
    is($put->{path}, "$CRD_PATH/$name", 'PUT went to the CRD-by-name path');
    my $sent = $json->decode($put->{content});
    is($sent->{kind}, 'CustomResourceDefinition', 'PUT body is a CRD');
    is($sent->{spec}{group}, 'homelab.example.com', 'PUT body group from to_crd');
    is($sent->{spec}{names}{plural}, 'staticwebsites', 'PUT body plural from to_crd');
    is($sent->{spec}{versions}[0]{name}, 'v1', 'PUT body version from to_crd');
    ok($sent->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{hostname},
        'PUT body carries the generated openAPIV3Schema');
};

# ---------------------------------------------------------------------------
# Case 2: create path + timeout. The CRD does not exist (ensure -> POST) and
# never establishes, so ensure_crd applies it and croaks on timeout. The POST
# payload/path is still verifiable, and discovery is NOT invalidated.
# ---------------------------------------------------------------------------
subtest 'create path, never Established -> timeout croak' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    my $name = 'staticwebsites.homelab.example.com';
    # POST returns the created object without an Established condition; the
    # by-name GET is left unregistered (404) so every poll is not-established.
    $io->add_response('POST', $CRD_PATH, crd_manifest(
        name => $name, group => 'homelab.example.com',
        plural => 'staticwebsites', kind => 'StaticWebSite', versions => ['v1'],
    ));

    my $invalidated = 0;
    my $orig = \&Kubernetes::REST::invalidate_discovery;
    no warnings 'redefine';
    local *Kubernetes::REST::invalidate_discovery =
        sub { $invalidated++; goto &$orig };
    use warnings;

    my @out = eval {
        $api->ensure_crd(['My::CRD::V1::StaticWebSite'], timeout => 0);
    };
    my $err = $@;
    ok($err, 'ensure_crd croaked');
    like($err, qr/\Q$name\E/, 'croak names the CRD');
    like($err, qr/Established/, 'croak mentions the Established condition');
    is($invalidated, 0, 'discovery not invalidated on timeout');

    my $post = last_request($io, 'POST');
    ok($post, 'a POST request was issued');
    is($post->{path}, $CRD_PATH, 'POST went to the CRD collection path');
    my $sent = $json->decode($post->{content});
    is($sent->{spec}{names}{plural}, 'staticwebsites', 'POST body plural from to_crd');
    is($sent->{spec}{versions}[0]{name}, 'v1', 'POST body version from to_crd');
};

# ---------------------------------------------------------------------------
# Case 3: multi-version. Two classes naming the same CRD are assembled into ONE
# multi-version CRD (not two competing single-version CRDs). We verify the
# assembled POST body, then let it time out (timeout => 0).
# ---------------------------------------------------------------------------
subtest 'multi-version assembly (storage given)' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    my $name = 'widgets.example.com';
    $io->add_response('POST', $CRD_PATH, crd_manifest(
        name => $name, group => 'example.com',
        plural => 'widgets', kind => 'Widget', versions => ['v1beta1', 'v1'],
    ));

    eval {
        $api->ensure_crd(
            [ 'My::CRD::V1beta1::Widget', 'My::CRD::V1::Widget' ],
            storage => 'v1', timeout => 0,
        );
    };
    ok($@, 'timed out (never Established) as expected');

    my @posts = grep { $_->{method} eq 'POST' } @{ $io->requests };
    is(scalar @posts, 1, 'exactly ONE CRD applied for two versions of one CRD');
    my $sent = $json->decode($posts[0]{content});
    is($sent->{metadata}{name}, $name, 'assembled CRD metadata.name');
    my @vs = @{ $sent->{spec}{versions} };
    is(scalar @vs, 2, 'two versions in the assembled CRD');
    is($vs[0]{name}, 'v1beta1', 'versions kept in pass order (v1beta1 first)');
    is($vs[1]{name}, 'v1', 'v1 second');
    ok($vs[1]{storage},  'v1 is the storage version');
    ok(!$vs[0]{storage}, 'v1beta1 is not the storage version');
};

# ---------------------------------------------------------------------------
# Case 4: multi-version without a storage version is refused before any request
# (the storage version is never guessed).
# ---------------------------------------------------------------------------
subtest 'multi-version without storage croaks, applies nothing' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    eval {
        $api->ensure_crd('My::CRD::V1beta1::Widget', 'My::CRD::V1::Widget');
    };
    my $err = $@;
    ok($err, 'croaked on ambiguous storage version');
    like($err, qr/widgets\.example\.com/, 'croak names the CRD');
    like($err, qr/storage/, 'croak points at the storage option');
    like($err, qr/v1beta1/, 'croak lists the v1beta1 candidate version');
    like($err, qr/\bv1\b/, 'croak lists the v1 candidate version');
    is(scalar @{ $io->requests }, 0, 'no request was issued');
};

# ---------------------------------------------------------------------------
# Case 5: argument validation.
# ---------------------------------------------------------------------------
subtest 'ensure_crd requires at least one class' => sub {
    my $api = mock_api();
    eval { $api->ensure_crd() };
    like($@, qr/requires at least one CRD class/, 'empty call croaks');
};

# ---------------------------------------------------------------------------
# karr k45: the wait for Established goes by the status of each poll, never by
# the text of an error. A 404 means "not registered yet" and is polled again;
# any other failure ends the wait at once with that error - a 500 whose
# message merely contains "404" too, instead of being polled away until the
# timeout and reported as a CRD that did not establish.
#
# The mock answers a path the same way every time; the wait needs a sequence.
# This subclass answers from a per-request script first - 'METHOD /path' =>
# [ [ status, body ], ... ], consumed in order - and hands everything else to
# the mock, as in t/17.
# ---------------------------------------------------------------------------
{
    package Test::EnsureCRD::ScriptedIO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has script => (is => 'ro', default => sub { {} });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        my $steps = $self->script->{ $req->method . ' ' . $path };
        return $self->$orig($req) unless $steps && @$steps;
        my ($status, $body) = @{ shift @$steps };
        push @{ $self->requests },
            { method => $req->method, path => $path, content => $req->content };
        return Test::Kubernetes::Mock::Response->new(
            status  => $status,
            content => $json->encode($body),
        );
    };
}

sub scripted_api {
    my (%script) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::EnsureCRD::ScriptedIO->new(script => \%script),
    );
}

sub failure {
    my ($code, $reason, $message) = @_;
    return [ $code, { kind => 'Status', apiVersion => 'v1', status => 'Failure',
                      code => $code, reason => $reason,
                      (defined $message ? (message => $message) : ()) } ];
}

sub polls {
    my ($api, $path) = @_;
    return scalar grep { $_->{method} eq 'GET' && $_->{path} eq $path }
        @{ $api->io->requests };
}

subtest 'k45: a 500 saying 404 ends the wait with the 500, not a timeout' => sub {
    my $name = 'staticwebsites.homelab.example.com';
    my %crd  = (name => $name, group => 'homelab.example.com',
                plural => 'staticwebsites', kind => 'StaticWebSite', versions => ['v1']);
    # ensure's GET finds nothing, the POST creates it, the first poll fails.
    # Once the script runs out the mock answers 404, which is polled again.
    my $api = scripted_api(
        "GET $CRD_PATH/$name" => [ failure(404, 'NotFound'),
                                   failure(500, 'InternalError', 'etcd timed out after 404 ms') ],
        "POST $CRD_PATH"      => [ [ 201, crd_manifest(%crd) ] ],
    );

    eval {
        $api->ensure_crd(['My::CRD::V1::StaticWebSite'], timeout => 1, poll_interval => 0.05);
    };
    my $err = $@;
    like($err, qr/ensure_crd wait \Q$name\E\): 500 /, 'croaks with the 500');
    like($err, qr/etcd timed out after 404 ms/, 'the server message is carried');
    unlike($err, qr/did not reach the Established condition/, 'it is not reported as a timeout');
    is(polls($api, "$CRD_PATH/$name"), 2, 'ensure GET plus exactly one poll - no polling on');
};

subtest 'k45: a real 404 is polled again until Established' => sub {
    my $name = 'staticwebsites.homelab.example.com';
    my %crd  = (name => $name, group => 'homelab.example.com',
                plural => 'staticwebsites', kind => 'StaticWebSite', versions => ['v1']);
    my $api = scripted_api(
        "GET $CRD_PATH/$name" => [ failure(404, 'NotFound'),     # ensure's GET
                                   failure(404, 'NotFound'),     # poll 1
                                   failure(404, 'NotFound'),     # poll 2
                                   [ 200, crd_manifest(%crd, established => 1) ] ],
        "POST $CRD_PATH"      => [ [ 201, crd_manifest(%crd) ] ],
    );

    my @out = eval {
        $api->ensure_crd(['My::CRD::V1::StaticWebSite'], timeout => 5, poll_interval => 0.01);
    };
    is($@, '', 'ensure_crd does not die');
    is(scalar @out, 1, 'one established CRD returned');
    ok(@out && $api->_crd_established($out[0]), 'it carries Established=True');
    is(polls($api, "$CRD_PATH/$name"), 4, 'ensure GET plus three polls');
};

done_testing;
