package Eixo::Zone::Artifact::NetworkBridge;

use strict;
use parent qw(Eixo::Zone::Artifact);

sub new{

	return bless({

		name=>$_[1],
	
		ctl=>$_[2],

		ns=>undef,

		f_created=>undef	

	}, $_[0]);

}

sub integrity{

	($_[0]->{f_created}) ? $_[0]->exists : !$_[0]->exists;
}

sub setAddr{
	my ($self, $addr) = @_;

	die(ref($self) . "::setAddr: bridge not created") 

		unless($self->{f_created});

	my ($method, @extra) = $self->__getMethod("link_addr");

	$self->{ctl}->$method($self->{name}, $addr, @extra);
	
}

sub create{
	my ($self) = @_;

	return if($self->{f_created});

	my ($method, @extra) = $self->__getMethod("bridge_create");

	$self->{ctl}->$method($self->{name}, @extra);

	$self->{f_created} = 1;
	
}

sub clean{
	$_[0]->delete;
}

sub delete{
	my ($self) = @_;

	return unless($self->{f_created});

	my ($method, @extra) = $self->__getMethod("bridge_rm");

	$self->{ctl}->$method($self->{name}, @extra);

	$self->{f_created} = undef;
}

sub setns{
	my ($self, $ns) = @_;

	$self->{ns} = $ns;

	if($self->{f_created}){

		# we need to move it to its new namespace
		

	}
}

sub addif{
	my ($self, $if) = @_;

	my ($method, @extra) = $self->__getMethod("bridge_addif");

	$self->{ctl}->$method($self->{name}, $if, @extra);
}	

sub exists{
	my ($self) = @_;

	my ($method, @extra) = $self->__getMethod("bridge_exists");
	
	$self->{ctl}->$method($self->{name}, @extra);

}

sub __getMethod{
	my ($self, $method) = @_;

	if(my $ns = $self->{ns}){

		$method . "_ns", $ns; 	

	}
	else{
		$method;
	}
}

1;


