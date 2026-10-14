package ForgeOps::Tracker::Client;

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(encode_json);
use ForgeOps::Tracker::DeliveryStatus;

# Delivers one payload over HTTP. Every failure mode: DNS, connection, timeout, a non-2xx
# response: is caught here and turned into a false return rather than a thrown exception, since
# a broken or unreachable tracker must never be able to break the host app. Uses HTTP::Tiny and
# JSON::PP, both core since Perl 5.14: same reasoning as every other SDK in this repo (see e.g.
# sdks/node/src/client.js): this has to work in any host app without adding a dependency of its
# own for something as simple as one POST request. deliver and deliver_performance_samples both
# post through the same private _post helper, which differs only in which URI it posts to and
# what payload shape it sends.
#
# Every deliver* method answers 1 only when the payload was delivered. Whether a 0 is worth another
# attempt is last_status: see ForgeOps::Tracker::DeliveryStatus.
sub new {
    my ($class, $configuration) = @_;
    return bless {
        configuration => $configuration,
        http          => HTTP::Tiny->new(timeout => $configuration->{timeout}),
        last_status   => ForgeOps::Tracker::DeliveryStatus::FAILED,
    }, $class;
}

# The DeliveryStatus of the most recent deliver* call on this client, in this thread (ithreads give
# each thread its own copy of the client, so one thread's attempt never overwrites another's).
sub last_status {
    my ($self) = @_;
    return $self->{last_status};
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

# Delivers one record_change() call. A plan without change tracking answers 403, which is just a
# false return here like any other non-2xx (with a last_status of REJECTED).
sub deliver_change {
    my ($self, $change) = @_;
    return $self->_post($self->{configuration}->changes_uri, $change, 'change delivery');
}

# Delivers the startup snapshot, { environment => ..., state => {...} }.
sub deliver_change_snapshot {
    my ($self, $snapshot) = @_;
    return $self->_post($self->{configuration}->change_snapshots_uri, $snapshot, 'change snapshot delivery');
}

sub _post {
    my ($self, $uri, $payload, $description) = @_;
    my $status = $self->_attempt($uri, $payload, $description);
    $self->{last_status} = $status;
    return $status eq ForgeOps::Tracker::DeliveryStatus::DELIVERED ? 1 : 0;
}

# One POST, answered as a DeliveryStatus.
sub _attempt {
    my ($self, $uri, $payload, $description) = @_;
    my $config = $self->{configuration};

    my $api_key = $config->api_key;
    return ForgeOps::Tracker::DeliveryStatus::FAILED unless $uri && defined $api_key;

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
        return ForgeOps::Tracker::DeliveryStatus::FAILED;
    }

    my $status = ForgeOps::Tracker::DeliveryStatus::for_code($response->{status});
    if ($status eq ForgeOps::Tracker::DeliveryStatus::REJECTED) {
        $config->log(
            "[forge-ops-tracker] $description rejected: $response->{status} $response->{reason}, the server will not accept a retry"
        );
    } elsif ($status eq ForgeOps::Tracker::DeliveryStatus::FAILED) {
        $config->log(
            "[forge-ops-tracker] $description failed: $response->{status} $response->{reason}"
        );
    }

    return $status;
}

1;
