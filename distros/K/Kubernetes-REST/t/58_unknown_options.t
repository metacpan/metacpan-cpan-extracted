#!/usr/bin/env perl
# karr k53: ensure_only and log croak on an option they do not take, before
# anything is applied or requested.
#
# ensure_only ignored any key it did not know. A misspelt
# propagation_policy => 'Orphan' pruned with the Background default and took
# the dependents with it; a misspelt namespace => 'default' scanned cluster
# scope only and left every stale namespaced object in place. log ignored
# its unknown keys the same way: tail_lines => 10 fetched the whole log. Both
# now croak naming the key and the ones they take, as delete does since k49.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query'.
{
    package Test::K53::IO;
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
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::K53::IO->new,
    );
}

my %CM = (
    apiVersion => 'v1', kind => 'ConfigMap',
    metadata   => { name => 'keep-me', namespace => 'default', labels => { app => 'demo' } },
);

my $ENSURE_ONLY_ALLOWED = qr/\(allowed: label, objects, kinds, namespaces, propagationPolicy\)/;

subtest 'ensure_only: an unknown option croaks before anything is applied' => sub {
    for my $case (
        [ 'propagation_policy', propagation_policy => 'Orphan', namespaces => ['default'] ],
        [ 'namespace',          namespace => 'default' ],
    ) {
        my ($key, @opts) = @$case;
        my $api = api();
        my $ok = eval {
            $api->ensure_only(
                label   => 'app=demo',
                objects => [ {%CM} ],
                kinds   => ['ConfigMap'],
                @opts,
            );
            1;
        };
        ok(!$ok, "$key: ensure_only croaks");
        like($@, qr/\AUnknown argument '$key' to ensure_only\(\) $ENSURE_ONLY_ALLOWED/,
            "$key: names the key and the ones it takes");
        like($@, qr/ at \Q$0\E line \d+/, "$key: at the caller's line");
        is_deeply($api->io->calls, [], "$key: nothing was sent");
    }
};

subtest 'ensure_only: an unknown option is named before a missing label' => sub {
    my $api = api();
    eval { $api->ensure_only(labels => 'app=demo', objects => [ {%CM} ], kinds => ['ConfigMap']) };
    like($@, qr/\AUnknown argument 'labels' to ensure_only\(\) $ENSURE_ONLY_ALLOWED/,
        'the misspelt label is named');
    is_deeply($api->io->calls, [], 'nothing was sent');
};

my $LOG = '/api/v1/namespaces/default/pods/web/log';

subtest 'log: an unknown option croaks before the request' => sub {
    for my $case (
        [ 'one-shot',  'tail_lines', tail_lines => 10 ],
        [ 'streaming', 'tailline',   tailline => 10, on_line => sub { } ],
        [ 'name =>',   'contianer',  name => 'web', contianer => 'app' ],
    ) {
        my ($form, $key, @opts) = @$case;
        my $api = api();
        $api->io->add_log_lines($LOG, ['a line']);
        my @name = $opts[0] eq 'name' ? () : ('web');
        my $ok = eval { $api->log('Pod', @name, namespace => 'default', @opts); 1 };
        ok(!$ok, "$form: log croaks");
        like($@, qr/\AUnknown argument '$key' to log\(\) \(allowed: name, namespace, container,/,
            "$form: names the key and the ones it takes");
        is_deeply($api->io->calls, [], "$form: nothing was sent");
    }
};

subtest 'log: the options it takes still go out' => sub {
    my $api = api();
    $api->io->add_log_lines($LOG, ['a line']);
    is($api->log('Pod', 'web', namespace => 'default', container => 'app', tailLines => 5,
            sinceSeconds => 60, timestamps => 1, previous => 1, limitBytes => 100),
        "a line\n", 'one-shot answers the log');
    is_deeply($api->io->calls,
        [ "GET $LOG?container=app&limitBytes=100&previous=true&sinceSeconds=60"
            . '&tailLines=5&timestamps=true' ],
        'with every option in the query');
};

done_testing;
