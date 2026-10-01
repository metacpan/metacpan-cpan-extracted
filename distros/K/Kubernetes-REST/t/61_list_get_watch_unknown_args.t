#!/usr/bin/env perl
# karr k58: list, get and watch croak on an argument they do not take, and
# ensure on anything after its object - before any request.
#
# All three handed every key they did not read on to build_path, which
# ignored what it had no use for: label_selector => 'app=web' listed
# unfiltered, namespce => 'default' listed across the cluster, a watch with
# timeoutSeconds => 5 ran for the default 300. They now croak naming the key
# and the ones they take, as delete, ensure_only and log do (k49, k53).
#
# What they passed on and build_path did use stays where it works: get's
# subresource ('status' answers with the whole object). name and subresource
# on list and watch go: they turn the request into a GET of one object, which
# the server answers with that object - list read it as an empty list, watch
# as one event without a type. One object is selected on the list endpoint
# with fieldSelector => 'metadata.name=NAME'. kind, api_version, resource and
# namespaced are build_path's arguments for IO::K8s::Unstructured, ignored for
# every typed class; a qualified name ('example.com/v1/Widget') pins the
# group and version instead.
#
# The v0 List*, Read* and Watch* methods pass on only what the new method
# takes; their other parameters stay ignored, as with Delete* since k49.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query'.
{
    package Test::K58::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around [qw(call call_streaming)] => sub {
        my ($orig, $self, $req, @rest) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        return $self->$orig($req, @rest);
    };
}

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::K58::IO->new,
        %args,
    );
}

my $PODS = '/api/v1/namespaces/default/pods';
my %POD  = (apiVersion => 'v1', kind => 'Pod',
    metadata => { name => 'web', namespace => 'default' });
my %POD_LIST = (apiVersion => 'v1', kind => 'PodList', items => [ {%POD} ]);

# Croaks naming $key and $allowed, at the caller's line, having sent nothing
# - with discovery on and a Kind only discovery could resolve, so not even
# discovery was read.
sub refuses {
    my ($method, $key, $allowed, @call) = @_;
    my $api = api(resource_map_from_cluster => 1);
    my $line = __LINE__; my $ok = eval { $api->$method('Widget', @call); 1 };
    my $err = $@;
    ok(!$ok, "$method @call[0 .. 1]: croaks");
    like($err, qr/\AUnknown argument '\Q$key\E' to $method\(\) \(allowed: \Q$allowed\E\)/,
        "$method: names '$key' and the ones it takes");
    like($err, qr/ at \Q$0\E line $line\.$/, "$method: at the caller's line");
    is_deeply($api->io->calls, [], "$method: nothing was sent, discovery included");
}

my $LIST_ALLOWED = 'namespace, labelSelector, fieldSelector';

subtest 'list: an argument it does not take croaks' => sub {
    # [ the key named - the first unknown one in sort order, the call ]
    for my $case (
        [ label_selector => label_selector => 'app=web' ],
        [ namespce       => namespce       => 'default' ],
        [ name           => name           => 'web' ],
        [ name           => subresource    => 'status', name => 'web' ],
        [ api_version    => api_version    => 'example.com/v1' ],
        [ kind           => kind           => 'Widget' ],
        [ api_version    => resource => 'widgets', namespaced => 1,
                            api_version => 'example.com/v1' ],
        # A namespace passed positionally listed across the cluster.
        [ default        => 'default' ],
    ) {
        my ($key, @call) = @$case;
        local $SIG{__WARN__} = sub { };   # the odd-sized list
        refuses('list', $key, $LIST_ALLOWED, @call);
    }
};

subtest 'list: the arguments it takes still go out' => sub {
    my $api = api();
    $api->io->add_response('GET', "$PODS?fieldSelector=status.phase=Running&labelSelector=app=web",
        \%POD_LIST);
    my $list = $api->list('Pod', namespace => 'default',
        labelSelector => 'app=web', fieldSelector => 'status.phase=Running');
    is(scalar @{ $list->items }, 1, 'the list');
    is_deeply($api->io->calls,
        [ "GET $PODS?fieldSelector=status.phase=Running&labelSelector=app=web" ],
        'namespace in the path, both selectors in the query');
};

my $GET_ALLOWED = 'name, namespace, subresource';

subtest 'get: an argument it does not take croaks' => sub {
    refuses('get', 'namespce', $GET_ALLOWED, 'web', namespce => 'default');
    refuses('get', 'subresourse', $GET_ALLOWED, 'web', subresourse => 'status');
    refuses('get', 'api_version', $GET_ALLOWED,
        name => 'web', api_version => 'example.com/v1');
    refuses('get', 'kind', $GET_ALLOWED, name => 'web', kind => 'Widget');
};

subtest 'get: name, namespace and subresource, in both call forms' => sub {
    my $api = api();
    $api->io->add_response('GET', "$PODS/web", \%POD);
    $api->io->add_response('GET', "$PODS/web/status", \%POD);
    is($api->get('Pod', 'web', namespace => 'default')->metadata->name, 'web',
        'shorthand');
    is($api->get('Pod', 'web', namespace => 'default', subresource => 'status')
        ->metadata->name, 'web', 'shorthand, subresource');
    is($api->get('Pod', subresource => 'status', name => 'web', namespace => 'default')
        ->metadata->name, 'web', 'keyed, subresource first');
    is_deeply($api->io->calls,
        [ "GET $PODS/web", "GET $PODS/web/status", "GET $PODS/web/status" ],
        'the object, then its /status twice');
};

my $WATCH_ALLOWED = 'on_event, timeout, resourceVersion, labelSelector, fieldSelector, namespace';

subtest 'watch: an argument it does not take croaks' => sub {
    for my $case (
        [ name           => 'web' ],
        [ label_selector => 'app=web' ],
        [ timeoutSeconds => 5 ],
        [ subresource    => 'status', name => 'web' ],
        [ api_version    => 'example.com/v1' ],
    ) {
        refuses('watch', $case->[0] eq 'subresource' ? 'name' : $case->[0], $WATCH_ALLOWED,
            @$case, on_event => sub { });
    }
    # Named before the missing on_event, as ensure_only names it before a
    # missing label.
    refuses('watch', 'name', $WATCH_ALLOWED, name => 'web');
};

subtest 'watch: the arguments it takes still go out' => sub {
    my $api = api();
    $api->io->add_watch_events($PODS, [ { type => 'ADDED', object => {%POD} } ]);
    my @types;
    $api->watch('Pod', namespace => 'default', timeout => 5, resourceVersion => '7',
        labelSelector => 'app=web', fieldSelector => 'status.phase=Running',
        on_event => sub { push @types, $_[0]->type });
    is_deeply(\@types, ['ADDED'], 'the event');
    is_deeply($api->io->calls,
        [ "GET $PODS?fieldSelector=status.phase=Running&labelSelector=app=web"
            . '&resourceVersion=7&timeoutSeconds=5&watch=true' ],
        'every option in the query');
};

subtest 'ensure: anything after the object croaks, before anything is sent' => sub {
    for my $case (
        [ 'an option',       {%POD}, namespace => 'other' ],
        [ 'a second object', {%POD}, {%POD, metadata => { name => 'db', namespace => 'default' }} ],
    ) {
        my ($what, @call) = @$case;
        my $api = api();
        my $line = __LINE__; my $ok = eval { $api->ensure(@call); 1 };
        ok(!$ok, "$what: ensure croaks");
        is($@, 'Invalid arguments to ensure(): it takes one object or hashref'
            . " (ensure_all takes several) at $0 line $line.\n",
            "$what: says so, at the caller's line");
        is_deeply($api->io->calls, [], "$what: nothing was sent");
    }
};

subtest 'v0 List*, Read*, Watch*: parameters the new method does not take stay ignored' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('GET', $PODS, \%POD_LIST);
    $api->io->add_response('GET', "$PODS/web", \%POD);
    $api->io->add_watch_events($PODS, [ { type => 'ADDED', object => {%POD} } ]);

    my $list = $api->Core->ListNamespacedPod(namespace => 'default',
        limit => 10, pretty => 'true', name => 'web');
    is(scalar @{ $list->items }, 1, 'ListNamespacedPod: the list');
    my $pod = $api->Core->ReadNamespacedPod(name => 'web', namespace => 'default',
        pretty => 'true', exact => 1);
    is($pod->metadata->name, 'web', 'ReadNamespacedPod: the object');
    my @types;
    $api->Core->WatchNamespacedPod(namespace => 'default', watch => 1,
        timeoutSeconds => 5, on_event => sub { push @types, $_[0]->type });
    is_deeply(\@types, ['ADDED'], 'WatchNamespacedPod: the event');
    is_deeply($api->io->calls,
        [ "GET $PODS", "GET $PODS/web", "GET $PODS?timeoutSeconds=300&watch=true" ],
        'the collection, the object, the watch - as the new methods take them');
};

done_testing;
