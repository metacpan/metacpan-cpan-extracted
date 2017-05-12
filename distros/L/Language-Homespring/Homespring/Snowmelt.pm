package Language::Homespring::Snowmelt;

$VERSION = 0.01;

use warnings;
use strict;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{interp}		= $options->{interp};
	$self->{time_at_node}	= 0;
	$self->{location}	= $options->{location};

	return $self;
}

sub move {
	my ($self) = @_;

	$self->{time_at_node}++;

	# see if we can leave the current node

	return if (($self->{location}->{node_name} eq 'marshy') && ($self->{time_at_node} == 1));

	# see if we can enter the next one

	my $dest = $self->{location}->{parent_node};

	if (defined($dest)){
		$self->{location} = $dest;
		$self->{time_at_node} = 0;
		$self->smash();
	}else{
		# if there's nowhere to go, 
		$self->kill();
	}

}

sub kill {
	my ($self) = @_;
	@{$self->{interp}->{snowmelt}} = grep{
		$_ ne $self
	}@{$self->{interp}->{snowmelt}};
}

sub smash {
	my ($self) = @_;

	# smash stuff at the current node
	my $node_name = $self->{location}->{node_name};

	#print "Smashing up a $node_name...\n";

	$self->{location}->{destroyed} = 1;

	if ($node_name eq 'universe'){
		$self->{interp}->{universe_ok} = 0;
	}

}

1;

