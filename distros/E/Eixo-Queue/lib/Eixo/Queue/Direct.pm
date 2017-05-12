package Eixo::Queue::Direct;

use strict;
use Eixo::Base::Clase qw(Eixo::Queue);

has(

	onWork=>undef,
);

sub add{
	my ($self, $job) = @_;

	$self->onWork->($job);

	return $job;
}


1;


