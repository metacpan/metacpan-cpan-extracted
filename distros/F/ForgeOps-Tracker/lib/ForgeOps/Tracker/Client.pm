package ForgeOps::Tracker::Client;

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(encode_json);

# Delivers one payload over HTTP. Every failure mode: DNS, connection, timeout, a non-2xx
# response: is caught here and turned into a false return rather than a thrown exception, since
# a broken or unreachable tracker must never be able to break the host app. Uses HTTP::Tiny and
# JSON::PP, both core since Perl 5.14: same reasoning as every other SDK in this repo (see e.g.
# sdks/node/src/client.js): this has to work in any host app without adding a dependency of its
# own for something as simple as one POST request. deliver and deliver_performance_samples both
# post through the same private _post helper, which differs only in which URI it posts to and
# what payload shape it sends.
sub new {
    my ($class, $configuration) = @_;
    return bless {
        configuration => $configuration,
        http          => HTTP::Tiny->new(timeout => $configuration->{timeout}),
    }, $class;
}

sub deliver {
    my ($self, $payload) = @_;
    return $self->_post($self->{configuration}->ingestion_uri, $payload, 'delivery');
}

sub deliver_performance_samples {
    my ($self, $samples) = @_;
    return $self->_post(
        $self->{configuration}->performance_samples_uri,
        { samples => $samples },
        'performance samples delivery',
    );
}

# Delivers a batch of individual capture_metric entries as { metrics => [...] }, and infrastructure
# readings the same way.
sub deliver_metrics {
    my ($self, $entries) = @_;
    return $self->_post($self->{configuration}->custom_metrics_uri, { metrics => $entries }, 'metrics delivery');
}

sub deliver_infrastructure_metrics {
    my ($self, $entries) = @_;
    return $self->_post($self->{configuration}->infrastructure_metrics_uri, { metrics => $entries }, 'infrastructure metrics delivery');
}

# Delivers one finished trace, { trace_id => ..., spans => [...] }, to the spans endpoint.
sub deliver_spans {
    my ($self, $trace) = @_;
    return $self->_post($self->{configuration}->spans_uri, $trace, 'span delivery');
}

sub _post {
    my ($self, $uri, $payload, $description) = @_;
    my $config = $self->{configuration};

    my $api_key = $config->api_key;
    return 0 unless $uri && defined $api_key;

    my $response = eval {
        $self->{http}->post(
            $uri,
            {
                headers => {
                    'Authorization' => "Bearer $api_key",
                    'Content-Type'  => 'application/json',
                },
                content => encode_json($payload),
            },
        );
    };

    if (!$response) {
        $config->log("[forge-ops-tracker] $description failed: $@") if $@;
        return 0;
    }

    unless ($response->{success}) {
        $config->log(
            "[forge-ops-tracker] $description failed: $response->{status} $response->{reason}"
        );
        return 0;
    }

    return 1;
}

1;
