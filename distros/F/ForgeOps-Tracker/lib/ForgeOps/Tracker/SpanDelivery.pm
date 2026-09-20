package ForgeOps::Tracker::SpanDelivery;

use strict;
use warnings;

# Adapts Client->deliver_spans to the deliver() method DeliveryQueue's worker thread calls, so
# finished traces reuse that queue (its bound, its lazy thread start, its per-item error guard)
# instead of a second copy of it.
sub new {
    my ($class, $client) = @_;
    return bless { client => $client }, $class;
}

sub deliver {
    my ($self, $trace) = @_;
    return $self->{client}->deliver_spans($trace);
}

1;
