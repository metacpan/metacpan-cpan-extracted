package Eixo::QueueInmediate;

use strict;
use parent qw(Eixo::Queue);

sub addAndWait{
	my ($self, $job) = @_;
	
	$self->add($job);	

	$self->wait();
	
}

1;
