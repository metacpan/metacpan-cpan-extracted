#!/usr/bin/env perl
# karr k64: the warning that the resource map falls back to the built-in one
# names the caller's line.
#
# The resource map is a lazy attribute, and most calls reach it through
# another one: resolving a name or inflating a response builds the inner
# IO::K8s, whose builder asks for the map. Carp skips the frames of Moo's
# generated accessors, but stopped where this client calls into one, so the
# warning named the line of the k8s builder in REST.pm instead of the call
# that needed the map. Only reading $api->resource_map directly named the
# caller. It now names the caller's line on every path, with the one
# location k59 left it.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

my $PODS = '/api/v1/namespaces/default/pods';

# A client with discovery on and no discovery served: the mock answers
# GET /api with a 404, so the map falls back.
sub api {
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', $PODS, { kind => 'PodList', items => [
        { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'web', namespace => 'default' } },
    ] });
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
    );
}

my $FALLBACK = qr/\AFalling back to the built-in resource map: Could not load resource map from cluster: Kubernetes API error \(discovery GET \/api\): 404 /;

# Runs $code (which returns the line it made the call on) and checks the one
# fallback warning names that line.
sub warns_at_caller {
    my ($what, $code) = @_;
    my @warnings;
    my $line = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $code->(api());
    };
    is(scalar @warnings, 1, "$what: one warning");
    like($warnings[0], $FALLBACK, "$what: the fallback, with the reason");
    like($warnings[0], qr/ at \Q$0\E line $line\.\n\z/, "$what: at the caller's line");
    is(scalar(() = $warnings[0] =~ / at \S+ line \d+\./g), 1, "$what: with one location");
}

subtest 'reading resource_map itself' => sub {
    warns_at_caller('resource_map', sub { my $api = shift;
        my $line = __LINE__; $api->resource_map; $line });
};

subtest 'resolving a name the built-in map does not know' => sub {
    warns_at_caller('expand_class', sub { my $api = shift;
        my $line = __LINE__; $api->expand_class('Widget'); $line });
    warns_at_caller('list of an unknown Kind', sub { my $api = shift;
        my $line = __LINE__; eval { $api->list('Widget', namespace => 'default') }; $line });
};

subtest 'inflating a response' => sub {
    warns_at_caller('list', sub { my $api = shift;
        my $line = __LINE__; $api->list('Pod', namespace => 'default'); $line });
};

subtest 'a method delegated to the inner IO::K8s, and k8s itself' => sub {
    warns_at_caller('new_object', sub { my $api = shift;
        my $line = __LINE__; $api->new_object(Namespace => { metadata => { name => 'x' } }); $line });
    warns_at_caller('k8s', sub { my $api = shift;
        my $line = __LINE__; $api->k8s; $line });
};

done_testing;
