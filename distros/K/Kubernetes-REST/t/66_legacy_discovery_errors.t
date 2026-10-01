#!/usr/bin/env perl
# karr k63: legacy discovery says which group/version it could not read.
#
# A cluster older than Kubernetes 1.27 answers GET /api and GET /apis with
# the legacy documents, and the client reads one APIResourceList per
# group/version. An HTTP error there was skipped without a word: the Kinds of
# that group/version were missing from the resource map, and a name among
# them later croaked as unknown, with nothing pointing at the cause. It now
# warns, naming the apiVersion and the APIError's message - status and body -
# at the caller's line, and reads the other groups on. A 404 stays silent:
# the group/version went away between the group list and its request.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Answers 'METHOD /path' with a fixed status and raw body; everything else
# goes to the mock.
{
    package Test::K63::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has answers => (is => 'ro', default => sub { {} });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        $path =~ s{\?.*}{};
        my $answer = $self->answers->{ $req->method . ' ' . $path }
            or return $self->$orig($req);
        return Test::Kubernetes::Mock::Response->new(
            status  => $answer->[0],
            content => $answer->[1],
        );
    };
}

my $UNAVAILABLE = '{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",'
    . '"message":"the server is currently unable to handle the request",'
    . '"reason":"ServiceUnavailable","code":503}';

# A pre-1.27 cluster: core v1, and the groups metrics.k8s.io (listed first,
# its v1beta1 answered by %answers), gone.example.com (v1 answers 404: the
# mock serves nothing there) and apps.
sub legacy_api {
    my (%answers) = @_;
    my $io = Test::K63::IO->new(answers => \%answers);
    $io->add_response('GET', '/api', { kind => 'APIVersions', versions => ['v1'] });
    $io->add_response('GET', '/apis', { kind => 'APIGroupList', groups => [
        map { {
            name             => $_->[0],
            versions         => [ { groupVersion => "$_->[0]/$_->[1]", version => $_->[1] } ],
            preferredVersion => { groupVersion => "$_->[0]/$_->[1]", version => $_->[1] },
        } } [ 'metrics.k8s.io', 'v1beta1' ], [ 'gone.example.com', 'v1' ], [ 'apps', 'v1' ],
    ] });
    $io->add_response('GET', '/api/v1', { kind => 'APIResourceList', groupVersion => 'v1',
        resources => [ { name => 'pods', namespaced => JSON::MaybeXS::true(), kind => 'Pod' } ] });
    $io->add_response('GET', '/apis/apps/v1', { kind => 'APIResourceList', groupVersion => 'apps/v1',
        resources => [ { name => 'deployments', namespaced => JSON::MaybeXS::true(),
            kind => 'Deployment' } ] });
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
    );
}

sub skipped {
    my ($api_version, $path, $status_and_body) = @_;
    return "discovery: cannot read apiVersion '$api_version', its Kinds are missing"
        . " from the resource map: Kubernetes API error (discovery GET $path):"
        . " $status_and_body";
}

subtest 'an error status for a group/version warns, the others are read on' => sub {
    my $api = legacy_api('GET /apis/metrics.k8s.io/v1beta1' => [ 503, $UNAVAILABLE ]);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $line = __LINE__; my $map = $api->fetch_resource_map;

    is_deeply(\@warnings, [
        skipped('metrics.k8s.io/v1beta1', '/apis/metrics.k8s.io/v1beta1', "503 $UNAVAILABLE")
            . " at $0 line $line.\n",
    ], 'one warning: the apiVersion, status and body, at the caller\'s line - none for the 404');
    is($map->{Pod}, 'Api::Core::V1::Pod', 'core read');
    is($map->{Deployment}, 'Api::Apps::V1::Deployment', 'apps, listed after both, read');
    my $groups = $api->_discovery->{groups};
    ok(!exists $groups->{'metrics.k8s.io'}, 'nothing of the failed group in the catalog');
    ok(!exists $groups->{'gone.example.com'}, 'nor of the vanished one');
};

subtest 'an error status for a core version warns too' => sub {
    my $api = legacy_api('GET /api/v1' => [ 500, 'etcd timeout' ]);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $map = $api->fetch_resource_map;

    is(scalar @warnings, 1, 'one warning');
    like($warnings[0], qr/\A\Q${\ skipped('v1', '\/api\/v1', '500 etcd timeout') }\E at /,
        'names the core apiVersion, status and body');
    ok(!exists $map->{Pod}, 'no core Kind in the map');
    is($map->{Deployment}, 'Api::Apps::V1::Deployment', 'the groups are read on');
};

subtest 'read on the way to a request, it names that call\'s line' => sub {
    # Pod resolves from the built-in map; inflating its item builds the inner
    # IO::K8s, which builds the resource map, which reads discovery - three
    # lazy attributes deep.
    my $api = legacy_api('GET /apis/metrics.k8s.io/v1beta1' => [ 503, $UNAVAILABLE ]);
    $api->io->add_response('GET', '/api/v1/namespaces/default/pods', { kind => 'PodList',
        items => [ { apiVersion => 'v1', kind => 'Pod',
            metadata => { name => 'web', namespace => 'default' } } ] });
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $line = __LINE__; my $list = $api->list('Pod', namespace => 'default');

    is(scalar @warnings, 1, 'one warning');
    like($warnings[0], qr/\A\Qdiscovery: cannot read apiVersion 'metrics.k8s.io\/v1beta1'\E.* at \Q$0\E line $line\.$/,
        'at the line of the list call');
};

done_testing;
