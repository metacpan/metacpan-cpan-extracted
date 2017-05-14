package Eixo::Zone::Artifact::PSInit;

# Abstraction of a init process

use strict;
use parent qw(Eixo::Zone::Artifact);

sub new{
	
	return bless({

		code=>$_[1],

		resume=>$_[2],

		ctl=>$_[3],

		pid=>undef,

		SELF_NETWORK=>undef,

		SELF_USER=>undef,

		f_created=>undef,	

	});
}

sub start{
	my ($self, %opts) = @_;

	my $flags = $self->__setFlags(%opts);

	my $pid = $self->{ctl}->clone(

		$self->__createStartCode(),

		$flags

	);

	$self->{pid} = $pid;

	$self->{f_created} = 1;

	$self;
}

sub clear{

	$_[0]->end;
}

sub end{

	return unless($_[0]->{f_created});

	kill("TERM", $_[0]->{pid});

	waitpid($_[0]->{pid}, 0);

	$_[0]->{f_created} = undef;
}

sub integrity{

	($_[0]->{f_created}) ? kill(0, $_[0]->{pid}) : 1;
}

sub __setFlags{
	my ($self, %opts) = @_;

	my $flags = 0 | $self->{ctl}->CLONE_NEWPID | 17;

	# new mount?
	$flags |= $self->{ctl}->CLONE_NEWNS if(

		$opts{MOUNTS}

	);

	# new net
	$flags |= $self->{ctl}->CLONE_NEWNET if(

		$opts{NETWORK} || $self->{SELF_NETWORK}

	);

	# new user namespace
	$flags |= $self->{ctl}->CLONE_NEWUSER if(

		$opts{USER} || $self->{SELF_USER}

	);

	$flags;
}

sub __createStartCode{
	my ($self) = @_;

	# a process should always be able to get its own zone::resume
	my $resume = $self->{resume};
	
	my $init = $self->{code};

	sub {

		no strict 'refs';
		
		*{"main::zone_resume"} = sub {
			return $resume;
		};

		$init->();

	}
}

1;
