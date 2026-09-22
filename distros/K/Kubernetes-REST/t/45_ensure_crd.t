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

done_testing;
