package Eixo::Queue::SocketPair;

use strict;
use Eixo::Base::Clase qw(Eixo::QueueInmediate);


use Socket;
use IO::Handle;
use IO::Select;
use Eixo::Queue::Job;

use Eixo::Queue::SocketPairDriver;

has(

	backend=>undef,

	pid_c=>undef,

	initiated=>undef,

	jobSent=>undef,

	input=>undef,

	output=>undef,

);

sub init{
	my ($self) = @_;

	my ($driver) = $self->__openCommunications;
	
	$self->__startBackend($driver);

	$self->initiated(1);

}

sub DESTROY{
	my ($self) = @_;

	if($self->pid_c){

		kill(10, $self->pid_c);

		waitpid($self->pid_c, 0);

	}

}


	sub __openCommunications{
		my ($self) = @_;

		&Eixo::Queue::SocketPairDriver::open();
	}

	sub __startBackend{
		my ($self, $driver) = @_;

		my ($a, $b) = ($self->__openCommunications(), $self->__openCommunications);


		if(my $pid = fork){
	
			$a->A;
			$b->A;

			$self->{input} = $a;
			$self->{output} = $b;

			$self->pid_c($pid);

		}
		else{
			$a->B;
			$b->B;

			$self->{input} = $b;
			$self->{output} = $a;

			eval{

				$self->__backendLoop();

			};
			if($@){
	
				use Data::Dumper;

				print Dumper($@);

				exit 1;
			}

			exit 0;
	
		}
		
	}

	sub __backendLoop{
		my ($self) = @_;

		while(my $job = $self->input->receive){

			$job = Eixo::Queue::Job->unserialize($job);

			$self->backend->($job);

			$self->output->send($job->serialize);
		}
	}

sub add{
	my ($self, $job) = @_;

	unless($self->initiated){
		die(ref($self) . '::add Queue not initiated');	
	}

	return undef if($self->jobSent);

	$self->__toBackend($job);

	$self->jobSent(1);

	return 1;
}

	sub __toBackend{
		my ($self, $job) = @_;

		$self->output->send($job->serialize);
	}

sub wait{
	my ($self) = @_;

	if($self->jobSent){

		$self->__waitBackend;

	}
}
	sub __waitBackend{

		my $data = $_[0]->input->receive;

		$_[0]->jobSent(0);

		return Eixo::Queue::Job->unserialize($data);

		
	}


sub status{
	my ($self) = @_;

	$self->jobSent;
}

1;
