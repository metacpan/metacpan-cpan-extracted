package Eixo::Zone::Artifact::NetworkNS;

use strict;
use parent qw(Eixo::Zone::Artifact);

sub new{

	my ($self) = bless({

		name=>$_[1],

		ctl => $_[2],

		f_created=>undef,

	}, $_[0]);

	$self;

}

sub DESTROY{

	$_[0]->delete if($_[0]->{f_created});
}

sub integrity{

	($_[0]->{f_created}) ? 
	
		$_[0]->{ctl}->ns_exists($_[0]->{name}) :

		!$_[0]->{ctl}->ns_exists($_[0]->{name})

}

sub clean{
	$_[0]->delete;
}

sub create{
	my ($self) = @_;

	$self->{ctl}->ns_create($self->{name});

	$self->{f_created} = 1;
}

sub delete{
	my ($self) = @_;

	$self->{ctl}->ns_delete($self->{name}) if(

		$self->{ctl}->ns_exists($_[0]->{name})

	);
}

1;
