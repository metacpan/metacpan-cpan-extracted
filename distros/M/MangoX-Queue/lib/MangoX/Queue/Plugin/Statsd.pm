package MangoX::Queue::Plugin::Statsd;

use Mojo::Base -base;
use Carp 'croak';

BEGIN {
	eval { require Net::Statsd } or croak qq{ Net::Statsd is required };
}

has 'queue';

sub register {
	my ($self, $queue) = @_;

	$self->queue($queue);

	on $queue consumed => sub {
		Net::Statsd::increment($self->queue->collection->name . '.consumed');
	};
	on $queue enqueued => sub {
		Net::Statsd::increment($self->queue->collection->name . '.enqueued');
	};
	on $queue dequeued => sub {
		Net::Statsd::increment($self->queue->collection->name . '.dequeued');
	};
	on $queue error => sub {
		Net::Statsd::increment($self->queue->collection->name . '.error');
	};
}

1;