package MangoX::Queue::Delay;

use Mojo::Base -base;
use Mojo::Log;

has start     => sub { $ENV{MANGOX_QUEUE_DELAY_START}     // 0.1  };
has current   => sub { $ENV{MANGOX_QUEUE_DELAY_START}     // 0.1  };
has increment => sub { $ENV{MANGOX_QUEUE_DELAY_INCREMENT} // 0.1  };
has maximum   => sub { $ENV{MANGOX_QUEUE_DELAY_MAXIMUM}   // 10   };

has log => sub { Mojo::Log->new->level('error') };

sub reset {
	my ($self) = @_;
	
	$self->log->debug("Reset delay to " . $self->start . " seconds");

	$self->current($self->start);
}

sub wait {
	my ($self, $callback) = @_;

	my $delay = $self->current;
	$self->log->debug("Current delay is $delay seconds");

	my $incremented = $delay + $self->increment;
	$self->log->debug("New delay is $incremented seconds");

	if($incremented > $self->maximum) {
		$self->log->debug("Limiting delay to maximum " . $self->maximum . " seconds");
		$incremented = $self->maximum;
	}

	$self->current($incremented);

	if($callback) {
		$self->log->debug("Non-blocking delay for $delay seconds");
		Mojo::IOLoop->timer($delay => $callback);
	} else {
		$self->log->debug("Sleeping for $delay seconds");
		sleep $delay;
	}

	return $delay;
}

1;