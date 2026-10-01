#!/usr/bin/env perl
# karr k61: patch, patch_status, ensure_crd, port_forward, exec and attach
# croak on an argument they do not take - before any request.
#
# All six ignored a key they did not read. patch handed nothing on, so a
# misspelt namespce => 'default' patched the object of that name at cluster
# scope (or croaked in the path, for a namespaced Kind) and patch_type =>
# 'merge' sent a strategic merge patch. ensure_crd waited the default 30
# seconds for a timeout it was given as tiemout. The duplex methods handed
# every key they did not read on to build_path, which ignored what it had no
# use for: containr => 'app' ran the command in the default container,
# stdn => 1 attached without stdin, on_message => sub {...} never saw a frame.
# They now croak naming the key and the ones they take, as delete, list, get,
# watch, ensure_only and log do (k49, k53, k58).
#
# What they take is what they read. patch and patch_status: name,
# namespace, patch and type - with an object only patch and type, since the
# object names itself (as delete takes only propagationPolicy with an
# object, and as Net::Async::Kubernetes refuses it since its k63).
# ensure_crd: timeout, poll_interval and storage. The duplex methods: name,
# namespace, the stream toggles and container their subresource takes,
# command for exec, ports for port_forward, subprotocol and the four
# callbacks. kind, api_version, resource and namespaced were build_path's
# arguments for IO::K8s::Unstructured and are refused, as by list, get and
# watch since k58; subresource was overridden by each method's own.
#
# The v0 Patch* methods pass on only what patch takes; their other
# parameters stay ignored, as with List*, Read*, Watch* and Delete*.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query', and every duplex session
# with its callbacks.
{
    package Test::K61::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls         => (is => 'ro', default => sub { [] });
    has content_types => (is => 'ro', default => sub { [] });
    has duplex_opts   => (is => 'ro', default => sub { [] });

    around [qw(call call_streaming)] => sub {
        my ($orig, $self, $req, @rest) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        push @{ $self->content_types }, $req->headers->{'Content-Type'};
        return $self->$orig($req, @rest);
    };

    sub call_duplex {
        my ($self, $req, %opts) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, 'DUPLEX ' . $path;
        push @{ $self->duplex_opts }, \%opts;
        return { session => 1 };
    }
}

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::K61::IO->new,
        %args,
    );
}

my $PODS = '/api/v1/namespaces/default/pods';
my %POD  = (apiVersion => 'v1', kind => 'Pod',
    metadata => { name => 'web', namespace => 'default' });
my $PATCH = { metadata => { labels => { env => 'staging' } } };

# A typed Pod, built without touching any client's transport.
sub pod { api()->new_object(Pod => { %POD, metadata => { %{ $POD{metadata} } } }) }

# Croaks naming $key and $allowed, at the caller's line, having sent nothing
# - with discovery on, so not even discovery was read. $first is the first
# argument after the invocant: a Kind only discovery could resolve, or an
# object.
sub refuses {
    my ($method, $key, $allowed, $first, @call) = @_;
    my $api = api(resource_map_from_cluster => 1);
    my $line = __LINE__; my $ok = eval { $api->$method($first, @call); 1 };
    my $err = $@;
    my $what = "$method" . (ref $first ? '($object)' : '') . " $key";
    ok(!$ok, "$what: croaks");
    like($err, qr/\AUnknown argument '\Q$key\E' to $method\(\) \(allowed: \Q$allowed\E\)/,
        "$what: names '$key' and the ones it takes");
    like($err, qr/ at \Q$0\E line $line\.$/, "$what: at the caller's line");
    is_deeply($api->io->calls, [], "$what: nothing was sent, discovery included");
}

my $PATCH_ALLOWED        = 'name, namespace, patch, type';
my $PATCH_OBJECT_ALLOWED = 'patch, type';

for my $method (qw(patch patch_status)) {
    subtest "$method: an argument it does not take croaks" => sub {
        refuses($method, 'namespce', $PATCH_ALLOWED,
            'Widget', 'web', namespce => 'default', patch => $PATCH);
        refuses($method, 'patch_type', $PATCH_ALLOWED,
            'Widget', 'web', patch => $PATCH, patch_type => 'merge');
        refuses($method, 'subresource', $PATCH_ALLOWED,
            'Widget', name => 'web', patch => $PATCH, subresource => 'scale');
        refuses($method, 'api_version', $PATCH_ALLOWED,
            'Widget', name => 'web', patch => $PATCH, api_version => 'example.com/v1');
        # Named before the missing patch, as ensure_only names a misspelt
        # label before the missing one.
        refuses($method, 'pacth', $PATCH_ALLOWED, 'Widget', 'web', pacth => $PATCH);
    };

    subtest "$method: with an object, only patch and type" => sub {
        my $pod = pod();
        refuses($method, 'namespace', $PATCH_OBJECT_ALLOWED,
            $pod, patch => $PATCH, namespace => 'other');
        refuses($method, 'name', $PATCH_OBJECT_ALLOWED,
            $pod, patch => $PATCH, name => 'db');
        refuses($method, 'patch_type', $PATCH_OBJECT_ALLOWED,
            $pod, patch => $PATCH, patch_type => 'json');
        refuses($method, 'pacth', $PATCH_OBJECT_ALLOWED, $pod, pacth => $PATCH);
    };
}

subtest 'patch and patch_status: the arguments they take still go out' => sub {
    my $api = api();
    $api->io->add_response('PATCH', "$PODS/web", \%POD);
    $api->io->add_response('PATCH', "$PODS/web/status", \%POD);
    my $pod = pod();

    $api->patch('Pod', 'web', namespace => 'default', patch => $PATCH, type => 'merge');
    $api->patch('Pod', name => 'web', namespace => 'default', patch => $PATCH);
    $api->patch($pod, patch => $PATCH, type => 'merge');
    $api->patch_status('Pod', 'web', namespace => 'default', patch => $PATCH,
        type => 'strategic');
    $api->patch_status($pod, patch => $PATCH);

    is_deeply($api->io->calls, [
        "PATCH $PODS/web", "PATCH $PODS/web", "PATCH $PODS/web",
        "PATCH $PODS/web/status", "PATCH $PODS/web/status",
    ], 'name and namespace in the path, from the arguments or the object');
    is_deeply($api->io->content_types, [
        'application/merge-patch+json', 'application/strategic-merge-patch+json',
        'application/merge-patch+json', 'application/strategic-merge-patch+json',
        'application/merge-patch+json',
    ], 'type picks the patch type, each method its own default');
};

my $ENSURE_CRD_ALLOWED = 'timeout, poll_interval, storage';

subtest 'ensure_crd: an option it does not take croaks' => sub {
    # The class is never loaded: the option is refused before any class is
    # asked for its CRD.
    for my $case (
        [ tiemout   => [ 'My::K61::Unloaded' ], tiemout => 5 ],
        [ interval  => [ 'My::K61::Unloaded' ], timeout => 5, interval => 2 ],
        [ storage_version => [ 'My::K61::Unloaded' ], storage_version => 'v1' ],
        # Named before the missing class.
        [ timout    => [], timout => 5 ],
    ) {
        my ($key, $classes, @opts) = @$case;
        my $api = api(resource_map_from_cluster => 1);
        my $line = __LINE__; my $ok = eval { $api->ensure_crd($classes, @opts); 1 };
        my $err = $@;
        ok(!$ok, "$key: croaks");
        like($err, qr/\AUnknown argument '$key' to ensure_crd\(\) \(allowed: \Q$ENSURE_CRD_ALLOWED\E\)/,
            "$key: names the key and the ones it takes");
        like($err, qr/ at \Q$0\E line $line\.$/, "$key: at the caller's line");
        is_deeply($api->io->calls, [], "$key: nothing was sent");
    }
};

my $PF_ALLOWED = 'name, namespace, ports, subprotocol, on_open, on_frame, on_close, on_error';
my $EXEC_ALLOWED = 'name, namespace, command, container, stdin, stdout, stderr, tty,'
    . ' subprotocol, on_open, on_frame, on_close, on_error';
my $ATTACH_ALLOWED = 'name, namespace, container, stdin, stdout, stderr, tty,'
    . ' subprotocol, on_open, on_frame, on_close, on_error';

subtest 'port_forward: an argument it does not take croaks' => sub {
    my @base = ('Widget', 'web', ports => [8080]);
    refuses('port_forward', 'namespce', $PF_ALLOWED, @base, namespce => 'default');
    refuses('port_forward', 'on_message', $PF_ALLOWED, @base, on_message => sub { });
    refuses('port_forward', 'subresource', $PF_ALLOWED, @base, subresource => 'exec');
    refuses('port_forward', 'api_version', $PF_ALLOWED, @base,
        api_version => 'example.com/v1');
    # Named before the missing ports.
    refuses('port_forward', 'port', $PF_ALLOWED, 'Widget', name => 'web', port => 8080);
};

subtest 'exec: an argument it does not take croaks' => sub {
    my @base = ('Widget', 'web', command => ['id']);
    refuses('exec', 'containr', $EXEC_ALLOWED, @base, containr => 'app');
    refuses('exec', 'stdn', $EXEC_ALLOWED, @base, stdn => 1);
    refuses('exec', 'ports', $EXEC_ALLOWED, @base, ports => [8080]);
    refuses('exec', 'kind', $EXEC_ALLOWED, @base, kind => 'Widget');
    # Named before the missing command.
    refuses('exec', 'cmd', $EXEC_ALLOWED, 'Widget', name => 'web', cmd => ['id']);
};

subtest 'attach: an argument it does not take croaks' => sub {
    my @base = ('Widget', 'web');
    refuses('attach', 'containr', $ATTACH_ALLOWED, @base, containr => 'app');
    refuses('attach', 'command', $ATTACH_ALLOWED, @base, command => ['sh']);
    refuses('attach', 'on_message', $ATTACH_ALLOWED, @base, on_message => sub { });
    # The first unknown key in sort order is the one named.
    refuses('attach', 'namespaced', $ATTACH_ALLOWED, @base,
        resource => 'widgets', namespaced => 1);
    # Named before the missing name.
    refuses('attach', 'nam', $ATTACH_ALLOWED, 'Widget', stdin => 1, nam => 'web');
};

subtest 'port_forward, exec, attach: every argument they take still goes out' => sub {
    my $api = api();
    my %cb = map { $_ => sub { } } qw(on_open on_frame on_close on_error);
    my %streams = (stdin => 1, stdout => 0, stderr => 1, tty => 1, container => 'app');

    $api->port_forward('Pod', 'web', namespace => 'default', ports => [8080, 8443],
        subprotocol => 'v5.channel.k8s.io', %cb);
    $api->exec('Pod', 'web', namespace => 'default', command => ['id'], %streams,
        subprotocol => 'v5.channel.k8s.io', %cb);
    $api->attach('Pod', name => 'web', namespace => 'default', %streams,
        subprotocol => 'v5.channel.k8s.io', %cb);

    is_deeply($api->io->calls, [
        "DUPLEX $PODS/web/portforward?ports=8080&ports=8443",
        "DUPLEX $PODS/web/exec?command=id&container=app&stderr=true&stdin=true"
            . '&stdout=false&tty=true',
        "DUPLEX $PODS/web/attach?container=app&stderr=true&stdin=true"
            . '&stdout=false&tty=true',
    ], 'name and namespace in the path, the rest in the query');
    for my $i (0 .. 2) {
        is_deeply([ sort keys %{ $api->io->duplex_opts->[$i] } ],
            [ sort keys %cb ], "session $i: the four callbacks handed to the backend");
    }
};

subtest 'v0 Patch*: parameters patch does not take stay ignored' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('PATCH', "$PODS/web", \%POD);

    my $pod = $api->Core->PatchNamespacedPod(name => 'web', namespace => 'default',
        patch => $PATCH, type => 'merge', pretty => 'true', fieldManager => 'me');
    is($pod->metadata->name, 'web', 'PatchNamespacedPod: the object');
    is_deeply($api->io->calls, [ "PATCH $PODS/web" ], 'the patch, as patch takes it');
    is_deeply($api->io->content_types, [ 'application/merge-patch+json' ],
        'with the type passed on');
};

done_testing;
