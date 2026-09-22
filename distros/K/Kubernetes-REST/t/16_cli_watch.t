#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Kubernetes::REST::CLI::Watch;
use Kubernetes::REST::WatchEvent;

# ============================================================================
# Test CLI::Watch internals (without requiring a real cluster)
# ============================================================================

# Create a Watch instance with a mock API
sub make_watcher {
    my (%opts) = @_;
    # Build directly without MooX::Options parsing
    return Kubernetes::REST::CLI::Watch->new(
        # Provide a dummy kubeconfig so the lazy api builder doesn't trigger
        kubeconfig => '/dev/null',
        %opts,
    );
}

# Helper to create a WatchEvent
sub make_event {
    my (%args) = @_;
    my $raw = $args{raw} // {
        apiVersion => 'v1',
        kind => $args{kind} // 'Pod',
        metadata => {
            name => $args{name} // 'test-pod',
            namespace => $args{namespace} // 'default',
        },
        ($args{status} ? (status => $args{status}) : ()),
        ($args{spec} ? (spec => $args{spec}) : ()),
    };

    # Create a simple mock object
    my $object;
    if ($args{type} eq 'ERROR') {
        $object = $raw;
    } else {
        require IO::K8s;
        $object = eval {
            IO::K8s->new->struct_to_object('IO::K8s::Api::Core::V1::Pod', $raw);
        } // $raw;
    }

    return Kubernetes::REST::WatchEvent->new(
        type => $args{type},
        object => $object,
        raw => $raw,
    );
}

# ============================================================================
# _timestamp tests
# ============================================================================

subtest '_timestamp - datetime format' => sub {
    my $w = make_watcher(timestamp_format => 'datetime');
    my $ts = $w->_timestamp;
    like $ts, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'datetime format';
};

subtest '_timestamp - date format' => sub {
    my $w = make_watcher(timestamp_format => 'date');
    my $ts = $w->_timestamp;
    like $ts, qr/^\d{4}-\d{2}-\d{2}$/, 'date format';
};

subtest '_timestamp - time format' => sub {
    my $w = make_watcher(timestamp_format => 'time');
    my $ts = $w->_timestamp;
    like $ts, qr/^\d{2}:\d{2}:\d{2}$/, 'time format';
};

subtest '_timestamp - epoch format' => sub {
    my $w = make_watcher(timestamp_format => 'epoch');
    my $ts = $w->_timestamp;
    like $ts, qr/^\d+$/, 'epoch format is numeric';
    ok $ts > 1700000000, 'epoch is a reasonable timestamp';
};

subtest '_timestamp - iso format' => sub {
    my $w = make_watcher(timestamp_format => 'iso');
    my $ts = $w->_timestamp;
    like $ts, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, 'iso format';
};

subtest '_timestamp - unknown format dies' => sub {
    my $w = make_watcher(timestamp_format => 'bogus');
    throws_ok { $w->_timestamp } qr/Unknown --timestamp-format/,
        'unknown format dies';
};

# ============================================================================
# _handle_event - type filtering
# ============================================================================

subtest '_handle_event - no filter passes all' => sub {
    my $w = make_watcher();

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'ADDED', name => 'pod-1'));
    }
    open STDOUT, '>&', $oldfh;
    like $output, qr/ADDED/, 'ADDED event printed without filter';
};

subtest '_handle_event - type filter accepts matching' => sub {
    my $w = make_watcher(event_type => 'ADDED,DELETED');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'ADDED', name => 'pod-1'));
    }
    open STDOUT, '>&', $oldfh;
    like $output, qr/ADDED/, 'matching type shown';
};

subtest '_handle_event - type filter rejects non-matching' => sub {
    my $w = make_watcher(event_type => 'DELETED');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'ADDED', name => 'pod-1'));
    }
    open STDOUT, '>&', $oldfh;
    is $output, '', 'non-matching type filtered out';
};

# ============================================================================
# _handle_event - name filtering
# ============================================================================

subtest '_handle_event - name filter matches' => sub {
    my $w = make_watcher(names => 'nginx');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'ADDED', name => 'nginx-web'));
    }
    open STDOUT, '>&', $oldfh;
    like $output, qr/nginx-web/, 'matching name shown';
};

subtest '_handle_event - name filter rejects' => sub {
    my $w = make_watcher(names => '^nginx');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'ADDED', name => 'redis-cache'));
    }
    open STDOUT, '>&', $oldfh;
    is $output, '', 'non-matching name filtered out';
};

# ============================================================================
# _handle_event - output formats
# ============================================================================

subtest '_handle_event - json output' => sub {
    my $w = make_watcher(output => 'json');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'MODIFIED', name => 'pod-1'));
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/"type"\s*:\s*"MODIFIED"/, 'JSON output has type';
    like $output, qr/"object"/, 'JSON output has object';
};

subtest '_handle_event - yaml output' => sub {
    my $w = make_watcher(output => 'yaml');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_handle_event(make_event(type => 'DELETED', name => 'pod-1'));
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/type: DELETED/, 'YAML output has type';
    like $output, qr/---/, 'YAML output has separator';
};

# ============================================================================
# _print_text - text formatting
# ============================================================================

subtest '_print_text - normal event' => sub {
    my $w = make_watcher(timestamp_format => 'epoch');

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_print_text(make_event(type => 'ADDED', name => 'my-pod', namespace => 'ns1'));
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/ADDED/, 'text has event type';
    like $output, qr{ns1/my-pod}, 'text has namespace/name';
};

subtest '_print_text - cluster-scoped resource (no namespace)' => sub {
    my $w = make_watcher(timestamp_format => 'epoch');

    my $event = make_event(type => 'ADDED', name => 'my-node');
    # Override object to not have namespace
    $event->{raw}{metadata}{namespace} = undef;
    delete $event->{raw}{metadata}{namespace};

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_print_text($event);
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/my-node/, 'text has name';
};

subtest '_print_text - ERROR event' => sub {
    my $w = make_watcher(timestamp_format => 'epoch');

    my $event = Kubernetes::REST::WatchEvent->new(
        type => 'ERROR',
        object => { code => 410, message => 'Gone' },
        raw => { code => 410, message => 'Gone' },
    );

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_print_text($event);
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/ERROR\(410\)/, 'error code shown';
    like $output, qr/Gone/, 'error message shown';
};

subtest '_print_text - pod with phase status' => sub {
    my $w = make_watcher(timestamp_format => 'epoch');

    my $event = make_event(
        type => 'MODIFIED',
        name => 'running-pod',
        namespace => 'default',
        status => { phase => 'Running' },
    );

    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $w->_print_text($event);
    }
    open STDOUT, '>&', $oldfh;

    like $output, qr/Running/, 'status hint shows phase';
};

# ============================================================================
# run() - error handling
# ============================================================================

subtest 'run - no kind dies' => sub {
    my $w = make_watcher();
    throws_ok { $w->run(undef) } qr/Usage: kube_watch/,
        'run without kind dies with usage';
};

subtest 'run - empty kind dies' => sub {
    my $w = make_watcher();
    throws_ok { $w->run('') } qr/Usage: kube_watch/,
        'run with empty kind dies with usage';
};

# ============================================================================
# argv handling - Kind is the first positional after new_with_options
#
# bin/kube_watch reads the Kind with `shift @ARGV` after new_with_options.
# MooX::Options must strip the parsed options from @ARGV (protect_argv => 0),
# otherwise `kube_watch -n default Pod` shifts off '-n' instead of 'Pod'.
# ============================================================================

subtest 'new_with_options - options before Kind, @ARGV left with Kind first' => sub {
    local @ARGV = ('-n', 'default', 'Pod');
    my $w = Kubernetes::REST::CLI::Watch->new_with_options;
    is $w->namespace, 'default', 'namespace option parsed';
    # This is exactly what bin/kube_watch does to obtain the Kind
    my $kind = shift @ARGV;
    is $kind, 'Pod', 'Kind is Pod, not the consumed -n option';
};

subtest 'new_with_options - Kind after options, mixed short options' => sub {
    local @ARGV = ('-n', 'default', '-o', 'json', 'Deployment');
    my $w = Kubernetes::REST::CLI::Watch->new_with_options;
    is $w->namespace, 'default', 'namespace parsed';
    is $w->output, 'json', 'output parsed';
    my $kind = shift @ARGV;
    is $kind, 'Deployment', 'Kind is Deployment after consumed options';
};

subtest 'new_with_options - Kind before options still works' => sub {
    local @ARGV = ('Pod', '-n', 'kube-system');
    my $w = Kubernetes::REST::CLI::Watch->new_with_options;
    is $w->namespace, 'kube-system', 'namespace parsed';
    my $kind = shift @ARGV;
    is $kind, 'Pod', 'Kind is Pod when given before options';
};

# ============================================================================
# _name_re - regex compilation
# ============================================================================

subtest '_name_re - valid regex' => sub {
    my $w = make_watcher(names => '^nginx-\d+');
    my $re = $w->_name_re;
    ok $re, 'regex compiled';
    ok 'nginx-123' =~ $re, 'regex matches expected string';
    ok 'redis-123' !~ $re, 'regex rejects non-matching string';
};

subtest '_name_re - invalid regex dies' => sub {
    my $w = make_watcher(names => '(?invalid');
    throws_ok { $w->_name_re } qr/Invalid --names regex/,
        'invalid regex dies';
};

subtest '_name_re - no names returns undef' => sub {
    my $w = make_watcher();
    ok !defined $w->_name_re, 'no names returns undef';
};

# ============================================================================
# _type_filter
# ============================================================================

subtest '_type_filter - no filter returns empty hash' => sub {
    my $w = make_watcher();
    my $tf = $w->_type_filter;
    is ref $tf, 'HASH', 'returns hashref';
    is scalar keys %$tf, 0, 'empty when no event_type set';
};

subtest '_type_filter - parses comma-separated types' => sub {
    my $w = make_watcher(event_type => 'ADDED,DELETED');
    my $tf = $w->_type_filter;
    ok $tf->{ADDED}, 'ADDED in filter';
    ok $tf->{DELETED}, 'DELETED in filter';
    ok !$tf->{MODIFIED}, 'MODIFIED not in filter';
};

subtest '_type_filter - uppercases types' => sub {
    my $w = make_watcher(event_type => 'added,modified');
    my $tf = $w->_type_filter;
    ok $tf->{ADDED}, 'added uppercased to ADDED';
    ok $tf->{MODIFIED}, 'modified uppercased to MODIFIED';
};

# ============================================================================
# CLI::Role::Connection - _build_api
# ============================================================================

subtest 'CLI::Role::Connection - api attribute with kubeconfig' => sub {
    use File::Temp qw(tempdir);
    use YAML::XS ();

    my $tmpdir = tempdir(CLEANUP => 1);
    my $kc_file = "$tmpdir/kubeconfig";

    YAML::XS::DumpFile($kc_file, {
        apiVersion => 'v1',
        kind => 'Config',
        'current-context' => 'test',
        clusters => [{
            name => 'test-cluster',
            cluster => {
                server => 'https://test.k8s.local:6443',
                'insecure-skip-tls-verify' => 1,
            },
        }],
        contexts => [{
            name => 'test',
            context => { cluster => 'test-cluster', user => 'test-user' },
        }],
        users => [{
            name => 'test-user',
            user => { token => 'test-token' },
        }],
    });

    my $w = make_watcher(kubeconfig => $kc_file);
    my $api = $w->api;
    isa_ok $api, 'Kubernetes::REST', 'api built from kubeconfig';
    is $api->server->endpoint, 'https://test.k8s.local:6443', 'server endpoint from kubeconfig';
    is $api->credentials->token, 'test-token', 'token from kubeconfig';
};

subtest 'CLI::Role::Connection - api with context override' => sub {
    use File::Temp qw(tempdir);
    use YAML::XS ();

    my $tmpdir = tempdir(CLEANUP => 1);
    my $kc_file = "$tmpdir/kubeconfig";

    YAML::XS::DumpFile($kc_file, {
        apiVersion => 'v1',
        kind => 'Config',
        'current-context' => 'default',
        clusters => [
            { name => 'c1', cluster => { server => 'https://c1.local', 'insecure-skip-tls-verify' => 1 } },
            { name => 'c2', cluster => { server => 'https://c2.local', 'insecure-skip-tls-verify' => 1 } },
        ],
        contexts => [
            { name => 'default', context => { cluster => 'c1', user => 'u1' } },
            { name => 'other', context => { cluster => 'c2', user => 'u1' } },
        ],
        users => [{ name => 'u1', user => { token => 'tok' } }],
    });

    my $w = make_watcher(kubeconfig => $kc_file, context => 'other');
    my $api = $w->api;
    is $api->server->endpoint, 'https://c2.local', 'context override selects correct cluster';
};

done_testing;
