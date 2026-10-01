#!/usr/bin/env perl
# karr k46: a resource name nothing resolves croaks naming that name.
#
# list, get, delete and every other method that takes a resource name handed
# what expand_class made of it straight to _build_path. For a qualified name
# that resolves to nothing - no class, and with discovery its group/version
# not served (karr k43) - that is undef, and require_module croaked "argument
# is not a module name": neither the name nor the reason. For a bare Kind it is
# the fabricated IO::K8s::<Kind>, and the croak was "Can't locate
# IO/K8s/<Kind>.pm in @INC (you may need to install the IO::K8s::<Kind>
# module)" - a module that does not exist. Both now croak "unknown resource
# '<name>'", the way Net::Async::Kubernetes reports it, before any request is
# sent. expand_class itself keeps its contract (undef, or the fabricated name).
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request, streaming ones included, as 'METHOD /path?query'.
{
    package Test::Unknown::RecordingIO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around [qw( call call_streaming )] => sub {
        my ($orig, $self, $req, @rest) = @_;
        (my $path = $req->url // '') =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, ($req->method // 'GET') . ' ' . $path;
        return $self->$orig($req, @rest);
    };
}

sub api_with {
    my (%args) = @_;
    my $io = Test::Unknown::RecordingIO->new;
    my $api = Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
        %args,
    );
    return ($api, $io);
}

# Every public entry point that resolves a resource name and builds a request
# path (or, for compare_schema, loads the class) from it.
my @ENTRY_POINTS = (
    [ list           => sub { $_[0]->list($_[1], namespace => 'ns', labelSelector => 'app=x') } ],
    [ get            => sub { $_[0]->get($_[1], 'w1', namespace => 'ns') } ],
    [ delete         => sub { $_[0]->delete($_[1], 'w1', namespace => 'ns') } ],
    [ patch          => sub { $_[0]->patch($_[1], 'w1', namespace => 'ns',
                                patch => { metadata => { labels => { a => 'b' } } }) } ],
    [ patch_status   => sub { $_[0]->patch_status($_[1], 'w1', namespace => 'ns',
                                patch => { status => { phase => 'x' } }) } ],
    [ watch          => sub { $_[0]->watch($_[1], namespace => 'ns', on_event => sub {}) } ],
    [ log            => sub { $_[0]->log($_[1], 'w1', namespace => 'ns') } ],
    [ port_forward   => sub { $_[0]->port_forward($_[1], 'w1', namespace => 'ns', ports => [8080]) } ],
    [ exec           => sub { $_[0]->exec($_[1], 'w1', namespace => 'ns', command => ['id']) } ],
    [ attach         => sub { $_[0]->attach($_[1], 'w1', namespace => 'ns') } ],
    [ compare_schema => sub { $_[0]->compare_schema($_[1]) } ],
);

subtest 'without discovery: every entry point names the unresolved name' => sub {
    for my $name ('other.org/v1/Widget', 'Ghost') {
        my ($api, $io) = api_with(resource_map_from_cluster => 0);

        is($api->expand_class($name),
            ($name eq 'Ghost' ? 'IO::K8s::Ghost' : undef),
            "$name: expand_class keeps its contract");

        for my $entry (@ENTRY_POINTS) {
            my ($method, $call) = @$entry;
            eval { $call->($api, $name) };
            my $err = $@;
            like($err, qr/\Aunknown resource '\Q$name\E': no IO::K8s class/,
                "$method $name: croaks naming the resource");
            like($err, qr/add it to resource_map if it is a CRD/,
                "$method $name: says what to do about it");
            unlike($err, qr/not a module name|Can't locate/,
                "$method $name: not the module loader's message");
        }
        is_deeply($io->calls, [], "$name: no request was sent");
    }
};

# The discovery cluster of t/44 and t/47: example.com/v1 serves Widget.
my %CORE_DISCOVERY = (
    kind       => 'APIGroupDiscoveryList',
    apiVersion => 'apidiscovery.k8s.io/v2',
    items      => [ {
        metadata => { name => '' },
        versions => [ {
            version   => 'v1',
            resources => [ {
                resource     => 'pods',
                responseKind => { group => '', version => 'v1', kind => 'Pod' },
                scope        => 'Namespaced',
            } ],
        } ],
    } ],
);
my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [ {
        metadata => { name => 'example.com' },
        versions => [ {
            version   => 'v1',
            resources => [ {
                resource     => 'widgets',
                responseKind => { group => 'example.com', version => 'v1', kind => 'Widget' },
                scope        => 'Namespaced',
            } ],
        } ],
    } ],
);

subtest 'with discovery: an unserved group/version names the qualified name (k43)' => sub {
    for my $name (qw( other.example.com/v1/Widget example.com/v2/Widget Ghost )) {
        my ($api, $io) = api_with();
        $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
        $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
        # Resolve a Kind only discovery serves once, so fetching the cluster
        # map and the catalog is out of the way ('Pod' would take the
        # fetch-free path and leave both for later).
        is($api->expand_class('Widget'), 'IO::K8s::Unstructured',
            'the bare Kind resolves through example.com/v1');
        my $mark = @{ $io->calls };

        for my $method (qw( list get delete )) {
            my ($call) = map { $_->[1] } grep { $_->[0] eq $method } @ENTRY_POINTS;
            eval { $call->($api, $name) };
            my $err = $@;
            like($err, qr/\Aunknown resource '\Q$name\E': no IO::K8s class/,
                "$method $name: croaks naming the resource");
            unlike($err, qr/discovery failed/,
                "$method $name: a healthy catalog is not blamed");
        }
        is_deeply([ @{ $io->calls }[ $mark .. $#{ $io->calls } ] ], [],
            "$name: no request went anywhere - above all not to example.com/v1")
            or diag explain $io->calls;
    }
};

subtest 'with discovery failing: the reason is named, not only the name' => sub {
    # No /api fixture: every discovery request is answered 404.
    my ($api, $io) = api_with();
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    eval { $api->get('other.example.com/v1/Widget', 'w1', namespace => 'ns') };
    my $err = $@;
    like($err, qr/\Aunknown resource 'other\.example\.com\/v1\/Widget': no IO::K8s class/,
        'croaks naming the resource');
    like($err, qr/discovery failed, so the cluster could not confirm it: Kubernetes API error \(discovery GET \/api\): 404 /,
        'and says discovery failed, with its reason');
    is_deeply([ grep { !m{\AGET /apis?\z} } @{ $io->calls } ], [],
        'nothing but the discovery attempts was sent');
};

subtest 'ensure_only warns with the clear text for an unresolved kinds entry (k37)' => sub {
    my ($api, $io) = api_with(resource_map_from_cluster => 0);
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [],
            kinds      => ['other.org/v1/Widget'],
            namespaces => ['default'],
        );
    }
    is(scalar @warnings, 1, 'one warning') or diag explain \@warnings;
    like($warnings[0] // '',
        qr/\Aensure_only: cannot list other\.org\/v1\/Widget in namespace 'default', nothing pruned there: unknown resource 'other\.org\/v1\/Widget': no IO::K8s class/,
        'it names the entry, the namespace and the clear reason');
    unlike($warnings[0] // '', qr/not a module name/, 'not the module loader\'s message');
    is_deeply($io->calls, [], 'nothing was sent');
};

done_testing;
