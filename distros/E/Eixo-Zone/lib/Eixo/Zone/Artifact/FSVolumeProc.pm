package Eixo::Zone::Artifact::FSVolumeProc;

use strict;
use parent qw(Eixo::Zone::Artifact::FSVolume);

sub new {
	my ($class, %args) = @_;

	return bless({

		ctl=>$args{ctl},

		f_mounted=>undef,

	}, $class);
}

sub create{
	my ($self) = @_;
}

sub mount{
	my ($self) = @_;

	$self->{ctl}->procfsCreateAndMount();

	$self->{f_mounted} = 1;
}


1;
