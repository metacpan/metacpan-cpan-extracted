package Eixo::Zone::Artifact::FSVolumeTmp;

use strict;
use parent qw(Eixo::Zone::Artifact::FSVolume);

sub new {
	my ($class, %args) = @_;

	return bless({

		size=>$args{size},

		path=>$args{path} || '/tmp',

		ctl=>$args{ctl},

		f_mounted=>undef,

	}, $class);
}

sub create{
	my ($self) = @_;
}

sub mount{
	my ($self) = @_;

	$self->{ctl}->tmpfsCreate(

		size=>$self->{size},
	
		path=>$self->{path}
	);

	$self->{f_mounted} = 1;
}


1;
