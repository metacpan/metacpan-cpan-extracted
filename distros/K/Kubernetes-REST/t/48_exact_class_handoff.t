#!/usr/bin/env perl
# karr k42: a class this client has already resolved is inflated as exactly
# that class.
#
# expand_class() returns a plain class name - a resource_map value of
# '+Gizmo' comes back as 'Gizmo'. IO::K8s's struct_to_object() and
# json_to_object() resolve a name again, and to them a single-segment 'Gizmo'
# is a Kind: IO::K8s::Gizmo, which does not exist, or whatever class the
# resource_map maps the Kind Gizmo to. Handing the resolved name back to them
# without its '+' made ensure() die, list() drop every item, and - when the
# Kind name is also a map key - inflate into another group's class and send
# the object to that group's endpoint.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPResponse;
use JSON::MaybeXS ();
use IO::K8s;

my $GIZMOS = '/apis/k42.example.com/v1/namespaces/ns/gizmos';
my $GVK    = 'k42.example.com/v1/Gizmo';

sub gizmo {
    my ($name, %extra) = @_;
    return {
        apiVersion => 'k42.example.com/v1',
        kind       => 'Gizmo',
        metadata   => { name => $name, namespace => 'ns', %extra },
        spec       => { size => 'large' },
    };
}

# The Gizmo entry is keyed by its GVK only, as a provider registers a Kind
# whose short name is taken. %extra adds further map entries.
sub gizmo_api {
    my (%extra) = @_;
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('POST', $GIZMOS, gizmo('g1', resourceVersion => '1'));
    $io->add_response('GET', "$GIZMOS/g1", gizmo('g1', resourceVersion => '1'));
    $io->add_response('PUT', "$GIZMOS/g1", gizmo('g1', resourceVersion => '2'));
    $io->add_response('GET', $GIZMOS, {
        apiVersion => 'k42.example.com/v1', kind => 'GizmoList',
        items      => [ gizmo('g1'), gizmo('g2') ],
    });
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        resource_map => {
            %{ IO::K8s->default_resource_map },
            $GVK => '+Gizmo',
            %extra,
        },
        io => $io,
    );
    return ($api, $io);
}

sub sent {
    my ($io) = @_;
    return [ map { "$_->{method} $_->{path}" } @{ $io->requests } ];
}

subtest 'ensure() with a manifest resolved through a +single-segment GVK entry' => sub {
    my ($api, $io) = gizmo_api();
    is $api->expand_class('Gizmo', 'k42.example.com/v1'), 'Gizmo', 'expand_class drops the +';

    my $result = eval { $api->ensure(gizmo('g1')) };
    is $@, '', 'ensure does not die';
    isa_ok $result, 'Gizmo', 'the result';
    is_deeply sent($io), [ "GET $GIZMOS/g1", "PUT $GIZMOS/g1" ],
        'the manifest went to the Gizmo endpoint';
};

subtest 'create path: the POST response inflates as Gizmo' => sub {
    my ($api, $io) = gizmo_api();
    my $object = $api->k8s->new_object('+Gizmo', gizmo('g1'));

    my $created = eval { $api->create($object) };
    is $@, '', 'create does not die';
    isa_ok $created, 'Gizmo', 'the created object';
    is_deeply sent($io), [ "POST $GIZMOS" ], 'posted to the Gizmo endpoint';
};

subtest 'list() and get() through the GVK string inflate Gizmo' => sub {
    my ($api) = gizmo_api();

    my @warnings;
    my $list = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        eval { $api->list($GVK, namespace => 'ns') };
    };
    is_deeply \@warnings, [], 'no item was dropped';
    is scalar @{ $list ? $list->items : [] }, 2, 'both items come back';
    isa_ok $list && $list->items->[0], 'Gizmo', 'a list item';

    my $obj = eval { $api->get($GVK, 'g1', namespace => 'ns') };
    is $@, '', 'get does not die';
    isa_ok $obj, 'Gizmo', 'the fetched object';
};

subtest 'the Kind name mapped to another class does not hijack a resolved Gizmo' => sub {
    # The short key Gizmo points at a class in another group. A resolved
    # 'Gizmo' re-read as a Kind would land there - silently, with its endpoint.
    my ($api, $io) = gizmo_api(Gizmo => '+My::Istio::Gateway');
    my $istio = '/apis/networking.istio.io/v1/namespaces/ns/gateways';

    my $result = eval { $api->ensure(gizmo('g1')) };
    is $@, '', 'ensure does not die';
    isa_ok $result, 'Gizmo', 'the result';
    is_deeply [ grep { /\Q$istio\E/ } @{ sent($io) } ], [],
        'nothing was sent to the other group';

    my $list = eval { $api->list($GVK, namespace => 'ns') };
    isa_ok $list && $list->items->[0], 'Gizmo', 'a list item';
};

# ---------------------------------------------------------------------------
# The seam: inflate_object/inflate_list/process_watch_chunk take the class
# expand_class resolved and build_path loaded, and use it exactly. A short or
# qualified name still resolves as a name - a package that merely shares a
# Kind's name is not mistaken for the class.
# ---------------------------------------------------------------------------
my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

sub response {
    my ($data) = @_;
    return Kubernetes::REST::HTTPResponse->new(status => 200, content => $wire_json->encode($data));
}

subtest 'seam: a resolved single-segment class is used exactly' => sub {
    my ($api) = gizmo_api(Gizmo => '+My::Istio::Gateway');
    my $class = $api->expand_class($GVK);
    $api->build_path($class, namespace => 'ns');   # loads it, as a seam caller does

    isa_ok eval { $api->inflate_object($class, response(gizmo('g1'))) }, 'Gizmo',
        'inflate_object';

    my $list = do {
        local $SIG{__WARN__} = sub {};   # a dropped item is asserted below
        $api->inflate_list($class, response({ items => [ gizmo('g1') ] }));
    };
    is scalar @{ $list->items }, 1, 'inflate_list keeps the item';
    isa_ok $list->items->[0], 'Gizmo', 'inflate_list item';

    my $buffer = '';
    my ($event) = $api->process_watch_chunk($class, \$buffer,
        $wire_json->encode({ type => 'ADDED', object => gizmo('g1') }) . "\n");
    isa_ok $event->{event}->object, 'Gizmo', 'watch event object';
};

{
    # Shares the core Kind name Secret, like a CPAN distribution that happens
    # to be loaded. It is not an IO::K8s class and must not be taken for one.
    package Secret;
    sub new { bless {}, shift }
}

subtest 'seam: short and qualified names still resolve' => sub {
    my ($api) = gizmo_api();
    my $cm = { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'c', namespace => 'ns' } };
    my $secret = { apiVersion => 'v1', kind => 'Secret', metadata => { name => 's', namespace => 'ns' } };

    isa_ok eval { $api->inflate_object('ConfigMap', response($cm)) },
        'IO::K8s::Api::Core::V1::ConfigMap', 'a short name';
    isa_ok eval { $api->inflate_object('v1/ConfigMap', response($cm)) },
        'IO::K8s::Api::Core::V1::ConfigMap', 'a qualified name';
    isa_ok eval { $api->inflate_object('Secret', response($secret)) },
        'IO::K8s::Api::Core::V1::Secret', 'a Kind name shared with a loaded non-IO::K8s package';
};

done_testing;
