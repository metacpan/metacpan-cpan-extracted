package Language::Homespring::Salmon;

$VERSION = 0.02;

use warnings;
use strict;

my $salmon_count = 0;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{interp}		= $options->{interp};
	$self->{value}		= $options->{value} || 'homeless';
	$self->{upstream}	= $options->{upstream} || 0;
	$self->{mature}		= $options->{mature} || 0;
	$self->{location}	= $options->{location};
	$self->{time_in_river}	= 0;
	$self->{uid}		= ++$salmon_count;

	#print "Creating salmon : ".$self->debug()."\n";

	return $self;
}

sub move {
	my ($self) = @_;
	my ($node_to_pass, $river_target);

	if ($self->{upstream}){
		$node_to_pass = $self->{location}->{up_node};
		$river_target = undef;
		if ($node_to_pass){
			my $count = scalar(@{$node_to_pass->{rivers_up}});
			if ($count){
				$river_target = @{$node_to_pass->{rivers_up}}[0];
			}
		}
	}else{
		$node_to_pass = $self->{location}->{down_node};
		$river_target = $node_to_pass->{river_down};
	}

	$self->{time_in_river}++;

	##
	## see if we can pass the next node
	##

	my $node_name = $node_to_pass->{node_name};

	return if (($node_to_pass->{node_name} eq 'shallows') && ($self->{mature}) && ($self->{time_in_river} == 1));
	return if (($node_to_pass->{node_name} eq 'rapids')   && (!$self->{mature}) && ($self->{time_in_river} == 1));

	return if (($node_to_pass->{node_name} eq 'net')     && ($self->{mature}));
	return if (($node_to_pass->{node_name} eq 'current') && (!$self->{mature}));

	if (($node_to_pass->{node_name} eq 'bear') && ($self->{mature})){
		$self->kill();
		return;
	}

	if (($node_to_pass->{node_name} eq 'young bear') && ($self->{mature})){
		if ($node_to_pass->every_other()){
			$self->kill();
			return;
		}
	}

	if (($node_to_pass->{node_name} eq 'bird') && (!$self->{mature})){
		$self->kill();
		return;
	}

	if (($node_to_pass->{node_name} eq 'force field') && ($node_to_pass->{power})){
		if ($self->{upstream}){
			$self->spawn($node_to_pass);
		}else{
			return;
		}
	}

	##
	## do we have a new river to swim into?
	##

	if (defined($river_target)){

		$self->{location} = $river_target;
		$self->{time_in_river} = 0;

	}else{

		# if there's nowhere to go, 
		# either spawn or print

		if ($self->{upstream}){
			$self->spawn($node_to_pass);
		}else{
			$self->output();
		}
	}

}

sub spawn {
	my ($self, $spring) = @_;

	#print "spawning in river ".$self->{location}->{uid}." from node ".$spring->debug()."\n";

	my $value = ($spring->{spring})?$spring->{node_name}:'nameless';
	my $new_salmon = new Language::Homespring::Salmon({
		'interp' => $self->{interp},
		'value' => $value,
		'upstream' => 0,
		'mature' => 0,
		'location' => $self->{location},
	});
	push @{$self->{interp}->{new_salmon}}, $new_salmon;
	$self->{upstream} = 0;
	$self->{mature} = 1;
}

sub output {
	my ($self) = @_;
	$self->{interp}->{output} .= $self->{value};
	$self->kill();
}

sub kill {
	my ($self) = @_;
	$self->{value} = 'DEAD';
	push @{$self->{interp}->{dead_salmon}}, $_;
}

sub debug {
	my ($self) = @_;

	return "salmon $self->{uid} in river ".$self->{location}->{uid}." ("
		.(($self->{mature})?'mature':'young')
		.") swimming "
		.(($self->{upstream})?'upsteam':'downstream')
		."\n";

}

1;

