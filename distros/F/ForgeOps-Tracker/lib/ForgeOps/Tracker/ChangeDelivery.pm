package ForgeOps::Tracker::ChangeDelivery;

use strict;
use warnings;

# Adapts Client->deliver_change and Client->deliver_change_snapshot to the deliver() method
# DeliveryQueue's worker thread calls, the same way SpanDelivery does for traces, so record_change()
# and the startup snapshot share one queue (its bound, its lazy thread start, its per-item error
# guard) and never block the caller. Each queued item is [$kind, $payload], $kind being 'change' or
# 'snapshot': one queue and one worker thread for both, rather than a second thread (a whole
# interpreter clone under ithreads) for a snapshot that's only sent once.
my %METHOD_FOR = (change => 'deliver_change', snapshot => 'deliver_change_snapshot');

sub new {
    my ($class, $client) = @_;
    return bless { client => $client }, $class;
}

sub deliver {
    my ($self, $item) = @_;
    my ($kind, $payload) = @$item;
    my $method = $METHOD_FOR{$kind} or return 0;
    return $self->{client}->$method($payload);
}

1;
