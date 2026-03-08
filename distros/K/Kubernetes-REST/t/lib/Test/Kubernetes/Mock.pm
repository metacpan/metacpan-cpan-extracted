package Test::Kubernetes::Mock;
# Mock HTTP responses for Kubernetes::REST tests

use strict;
use warnings;
use JSON::MaybeXS;
use Path::Tiny qw(path);
use Exporter 'import';

our @EXPORT_OK = qw(mock_api live_api is_live record_response);

my $MOCK_DIR = path(__FILE__)->parent->parent->parent->parent->child('mock');
my $json = JSON::MaybeXS->new->pretty->canonical;

# Keep kubeconfig object alive so temp cert files aren't deleted
my $_kubeconfig;

# Check if we should use live cluster
# Requires TEST_KUBERNETES_REST_KUBECONFIG to be set explicitly (safety measure)
sub is_live {
    return 0 unless $ENV{TEST_KUBERNETES_REST_KUBECONFIG};
    return 1;
}

# Get API - either mock or live based on environment
sub mock_api {
    require Kubernetes::REST;
    require Kubernetes::REST::Server;
    require Kubernetes::REST::AuthToken;

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        io => Test::Kubernetes::Mock::IO->new,
    );
}

sub live_api {
    require Kubernetes::REST::Kubeconfig;
    die "TEST_KUBERNETES_REST_KUBECONFIG must be set for live tests"
        unless $ENV{TEST_KUBERNETES_REST_KUBECONFIG};
    my %args = (kubeconfig_path => $ENV{TEST_KUBERNETES_REST_KUBECONFIG});
    $args{context_name} = $ENV{TEST_KUBERNETES_REST_CONTEXT} if $ENV{TEST_KUBERNETES_REST_CONTEXT};
    # Keep kubeconfig alive so temp cert files aren't deleted
    $_kubeconfig = Kubernetes::REST::Kubeconfig->new(%args);
    return $_kubeconfig->api;
}

# Record a response to mock file
sub record_response {
    my ($name, $data) = @_;
    my $file = $MOCK_DIR->child("$name.json");
    $file->spew_utf8($json->encode($data));
    return $file;
}

# Load mock response
sub load_response {
    my ($name) = @_;
    my $file = $MOCK_DIR->child("$name.json");
    return undef unless $file->exists;
    return $json->decode($file->slurp_utf8);
}

# Mock IO class that returns recorded responses
package Test::Kubernetes::Mock::IO;
use Moo;
with 'Kubernetes::REST::Role::IO';

has responses => (
    is => 'ro',
    default => sub { {} },
);

has watch_events => (
    is => 'ro',
    default => sub { {} },
);

has log_lines => (
    is => 'ro',
    default => sub { {} },
);

sub add_response {
    my ($self, $method, $path, $data) = @_;
    my $key = lc($method) . $path;
    $key =~ s{/}{_}g;
    $key =~ s{_+}{_}g;
    $key =~ s{^_}{};
    $self->responses->{$key} = $data;
}

sub call {
    my ($self, $req) = @_;

    # Generate key from method + uri
    my $method = $req->method // 'GET';
    my $path = $req->uri // $req->url // '';
    # Strip host from url if present
    $path =~ s{^https?://[^/]+}{};

    # Strip query parameters for path matching
    my $clean_path = $path;
    $clean_path =~ s{\?.*}{};

    # Check for log lines (one-shot mode, log paths end with /log)
    if (my $lines = $self->log_lines->{$clean_path}) {
        return Test::Kubernetes::Mock::Response->new(
            status => 200,
            content => join("\n", @$lines) . "\n",
        );
    }

    my $key = lc($method) . $path;
    $key =~ s{/}{_}g;
    $key =~ s{_+}{_}g;  # collapse multiple underscores
    $key =~ s{^_}{};

    warn "MOCK: Looking for key '$key' (method=$method, path=$path)\n" if $ENV{MOCK_DEBUG};

    # Check programmatic responses first, then file-based
    my $data = $self->responses->{$key} // Test::Kubernetes::Mock::load_response($key);

    if ($data) {
        return Test::Kubernetes::Mock::Response->new(
            status => 200,
            content => JSON::MaybeXS->new->encode($data),
        );
    }

    # Not found in mock
    return Test::Kubernetes::Mock::Response->new(
        status => 404,
        content => '{"kind":"Status","status":"Failure","message":"not found in mock"}',
    );
}

sub add_watch_events {
    my ($self, $path, $events) = @_;
    $self->watch_events->{$path} = $events;
}

sub add_log_lines {
    my ($self, $path, $lines) = @_;
    $self->log_lines->{$path} = $lines;
}

sub call_streaming {
    my ($self, $req, $callback) = @_;

    my $path = $req->url // '';
    $path =~ s{^https?://[^/]+}{};
    # Strip query parameters for key lookup
    $path =~ s{\?.*}{};

    # Check for log lines first (log paths end with /log)
    if (my $lines = $self->log_lines->{$path}) {
        for my $line (@$lines) {
            $callback->($line . "\n", undef);
        }
        return Test::Kubernetes::Mock::Response->new(
            status => 200,
        );
    }

    # Check for watch events
    my $events = $self->watch_events->{$path};

    unless ($events) {
        return Test::Kubernetes::Mock::Response->new(
            status => 404,
            content => '{"kind":"Status","status":"Failure","message":"no streaming data for path"}',
        );
    }

    my $json = JSON::MaybeXS->new;
    for my $event (@$events) {
        my $line = $json->encode($event) . "\n";
        $callback->($line, undef);
    }

    return Test::Kubernetes::Mock::Response->new(
        status => 200,
    );
}

package Test::Kubernetes::Mock::Response;
use Moo;

has status => (is => 'ro', required => 1);
has content => (is => 'ro', default => sub { '' });

1;

__END__

=head1 NAME

Test::Kubernetes::Mock - Mock HTTP layer for Kubernetes::REST tests

=head1 SYNOPSIS

    use Test::Kubernetes::Mock qw(mock_api live_api is_live);

    my $api;
    if (is_live()) {
        $api = live_api();
    } else {
        $api = mock_api();
    }

    my $pods = $api->list('Pod');

=head1 DESCRIPTION

Provides mock and live API instances for testing Kubernetes::REST.

=head1 ENVIRONMENT VARIABLES

=over 4

=item TEST_KUBERNETES_REST_KUBECONFIG

Path to kubeconfig file for live tests. B<Required> for live tests.
This is intentionally a long name to prevent accidentally running
tests against production clusters.

    TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/test-config prove -l t/

=item TEST_KUBERNETES_REST_CONTEXT

Optional. Kubernetes context to use from the kubeconfig.

=item MOCK_DEBUG

Set to 1 to see which mock files are being looked up.

=back

=head1 RUNNING TESTS

    # Run with mock data (default, safe)
    prove -l t/05_api_operations.t

    # Run against live cluster (requires explicit kubeconfig)
    TEST_KUBERNETES_REST_KUBECONFIG=/path/to/kubeconfig prove -l t/05_api_operations.t

    # Record new mock fixtures from live cluster
    TEST_KUBERNETES_REST_KUBECONFIG=/path/to/kubeconfig perl t/record_fixtures.pl

=cut
