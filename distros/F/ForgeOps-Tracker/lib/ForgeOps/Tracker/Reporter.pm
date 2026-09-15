package ForgeOps::Tracker::Reporter;

use strict;
use warnings;

# Ties Configuration, EventBuilder, and DeliveryQueue together into the one thing callers actually
# need: report an exception. Mirrors gems/forge_ops_tracker's ErrorSubscriber#report: never
# throws. An error reporter that itself throws while reporting an error is the worst possible
# failure mode, so every path here is wrapped to guarantee this never propagates back into the
# host app.
sub new {
    my ($class, $configuration, $event_builder, $delivery_queue) = @_;
    return bless {
        configuration   => $configuration,
        event_builder   => $event_builder,
        delivery_queue  => $delivery_queue,
    }, $class;
}

sub report {
    my ($self, $error, $context) = @_;

    eval {
        return unless $self->{configuration}->is_enabled;

        my $payload = $self->{event_builder}->build($error, $context);
        $self->{delivery_queue}->push($payload);
        1;
    } or do {
        my $err = $@;
        eval { $self->{configuration}->log("[forge-ops-tracker] report failed: $err") };
    };

    return;
}

1;
