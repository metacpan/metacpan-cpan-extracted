package Eixo::Zone::Artifact::NetworkVeth;

use strict;
use parent qw(Eixo::Zone::Artifact);

sub new{

	my ($self) = bless({

		name=>$_[1],

		ctl => $_[2],

		f_created=>undef,

		ns=>{},

	}, $_[0]);

	($self->{a}, $self->{b}) = $self->generatePair;

	$self;

}

sub DELETE{

	$_[0]->delete if($_[0]->{f_created});
}

sub clean{
	$_[0]->delete;
}

# this is an interface
sub up{
	my ($self, $extreme) = @_;

	$extreme = lc($extreme);

	my ($method, @extra) = $self->__getMethod("link_up", $extreme);

	$self->{ctl}->$method(
	
		$self->{$extreme},

		@extra
	);

	$self;
}

sub down{

}

sub setns{
	my ($self, $ns, $extreme) = @_;

	$extreme = lc($extreme);

	$self->{ctl}->link_setns($self->{$extreme}, $ns);

	$self->{ns}->{$extreme} = $ns;

	$self;
}

sub delete{
	my ($self) = @_;

	$self->{ctl}->link_delete($self->{a}) if(

		$self->{ctl}->link_exists($self->{a})

	);
}

sub addr{
	my ($self, $addr, $extreme) = @_;
	
	$extreme = lc($extreme);

	my ($method, @extra) = $self->__getMethod(

		'link_addr',

		$extreme

	);
	
	$self->{ctl}->$method($self->{$extreme}, $addr, @extra);
}

sub create{
	my ($self) = @_;

	$self->{ctl}->link_create($self->{a}, $self->{b});

	$self->{f_created} = 1;

	$self;
}

sub generatePair{

	(
		$_[0]->{name} . "_a",

		$_[0]->{name} . "_b",
	)
}

sub __getMethod{
	my ($self, $base_method, $extreme) = @_;
	
	if(my $ns = $self->{ns}->{$extreme}){
	
		$base_method . '_ns', $ns;

	}
	else{
		$base_method;
	}
}

1;
