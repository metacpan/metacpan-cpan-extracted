#!/usr/bin/env perl
# karr k48: ensure and ensure_only name an unknown Kind, before any request.
#
# A manifest hashref without apiVersion resolves by its Kind alone. For a Kind
# nothing resolves, expand_class answers the fabricated IO::K8s::<Kind>, and
# ensure/ensure_only handed that on to struct_to_object, which died with
# "Can't locate IO/K8s/<Kind>.pm" - a module that does not exist. They now
# croak the way every method taking a resource name does since karr k46:
# "unknown resource '<Kind>'", before anything is sent.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

sub api_with {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::Kubernetes::Mock::IO->new,
        %args,
    );
}

sub calls {
    my ($api) = @_;
    return [ map { "$_->{method} $_->{path}" } @{ $api->io->requests } ];
}

my %GHOST = (
    kind     => 'Ghost',
    metadata => { name => 'g1', namespace => 'default' },
);
my %CONFIGMAP = (
    apiVersion => 'v1',
    kind       => 'ConfigMap',
    metadata   => { name => 'cm1', namespace => 'default', labels => { app => 'x' } },
    data       => { a => 'b' },
);

my @CALLS = (
    [ ensure      => sub { $_[0]->ensure({ %GHOST }) } ],
    # The Ghost comes second: every manifest resolves before the first object
    # is applied, so not even the ConfigMap goes out.
    [ ensure_only => sub {
        $_[0]->ensure_only(
            label      => 'app=x',
            objects    => [ { %CONFIGMAP }, { %GHOST } ],
            kinds      => ['ConfigMap'],
            namespaces => ['default'],
        );
    } ],
);

sub assert_unknown_ghost {
    my ($method, $err) = @_;
    like($err, qr/\Aunknown resource 'Ghost': no IO::K8s class/,
        "$method: croaks naming the Kind");
    like($err, qr/add it to resource_map if it is a CRD/,
        "$method: says what to do about it");
    unlike($err, qr/Can't locate/, "$method: not the module loader's message");
}

subtest 'without discovery: no request at all' => sub {
    for my $entry (@CALLS) {
        my ($method, $call) = @$entry;
        my $api = api_with(resource_map_from_cluster => 0);
        eval { $call->($api) };
        assert_unknown_ghost($method, $@);
        is_deeply(calls($api), [], "$method: no request was sent")
            or diag explain calls($api);
    }
};

# With discovery the Kind is looked up there first (it could be a CRD the
# cluster serves) - that is the only traffic, nothing reaches the resource.
my %CORE_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [ {
        metadata => { name => '' },
        versions => [ {
            version   => 'v1',
            resources => [ {
                resource     => 'configmaps',
                responseKind => { group => '', version => 'v1', kind => 'ConfigMap' },
                scope        => 'Namespaced',
            } ],
        } ],
    } ],
);
my %GROUPED_DISCOVERY = (kind => 'APIGroupDiscoveryList', items => []);

subtest 'with discovery: only the discovery documents are read' => sub {
    for my $entry (@CALLS) {
        my ($method, $call) = @$entry;
        my $api = api_with();
        $api->io->add_response('GET', '/api',  \%CORE_DISCOVERY);
        $api->io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
        eval { $call->($api) };
        assert_unknown_ghost($method, $@);
        is_deeply(calls($api), [ 'GET /api', 'GET /apis' ],
            "$method: nothing but discovery was requested")
            or diag explain calls($api);
    }
};

done_testing;
