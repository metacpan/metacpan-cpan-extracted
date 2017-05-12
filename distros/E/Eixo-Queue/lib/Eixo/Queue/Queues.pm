package Eixo::Queue::Queues;

use strict;
use Eixo::Base::Clase;

has(

	queues=>{},

	jobs_resolve=>{},

);

#
# Jobs administration
#
sub getJob{
	my ($self, $id) = @_;

	if(my $queue_name = $self->jobs_resolve->{$id}){

		$self->queues->{$queue_name}->status($id);

	}
}


sub addJob{
	my ($self, $job) = @_;


	my $queue = $self->queues->{$job->queue};

	unless($queue->isInmediate || $queue->isDirect){

		#
		# Add resolve unless inmediate or direct queue 
		#
		$self->jobs_resolve->{$job->id} = $job->queue;
	}

	#
	# Add job to the queue 
	#
	$queue->add($job);

	return $job if($queue->isDirect);

	return $job->copy($queue->wait) if($queue->isInmediate);

	return 1;
}

#
# Queues administration
#

sub createQueue{
	my ($self, $queue) = @_;

	unless($queue && $queue->isa('Eixo::Queue')){

		die(ref($self) . '::createQueue: queue must exist and be an instance of Eixo::Queue');


	}

	$self->queues->{$queue->name} = $queue;

	$queue->init;
}


1;
