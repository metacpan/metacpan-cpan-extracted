package Language::Homespring::Node;

$VERSION = 0.02;

use warnings;
use strict;

my $node_count = 0;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{interp}		= $options->{interp};
	$self->{parent_node}	= $options->{parent_node} || undef;
	$self->{node_name}	= $options->{node_name} || '';
	$self->{child_nodes}	= [];
	$self->{rivers_up}	= [];
	$self->{river_down}	= undef;
	$self->{power}		= 0;
	$self->{water}		= 0;
	$self->{destroyed}	= 0;
	$self->{spring}		= $self->_is_spring();
	$self->{uid}		= ++$node_count;
	$self->{depth}		= 0;
	$self->{node_name_safe}	= $self->_make_safe($options->{node_name});
	$self->{toggle}		= 0;

	# easier to deal with lowercase commands :)
	$self->{node_name} = lc($self->{node_name}) if (!$self->{spring});

	return $self;
}

sub add_child {
	my ($self, $child) = @_;
	push @{$self->{child_nodes}}, $child;
}

sub get_salmon {
	my ($self) = @_;
	my @out;
	for (@{$self->{interp}->{salmon}}){
		if ($_->{location} eq $self){
			push @out, $_;
		}
	}
	return @out;
}

sub get_depth {
	my ($self) = @_;

	if (!$self->{depth}){
		if (scalar(@{$self->{child_nodes}})){
			for (@{$self->{child_nodes}}){
				$self->{depth} += $_->get_depth();
			}
		}else{
			$self->{depth} = 2;
		}
	}

	return $self->{depth};
}

sub _is_spring {
	my ($self) = @_;

	my @keywords = (
'powers',
'hydro power',
'power invert',
'marshy',
'shallows',
'rapids',
'bear',
'young bear',
'bird',
'upstream killing device',
'net',
'current',
'insulated',
'force field',
'bridge',
'waterfall',
'evaporates',
'pump',
'fear',
'lock',
'inverse lock',
'narrows',
'sense',
'switch',
'upstream sense',
'downstream sense',
'range sense',
'range switch',
'young sense',
'young switch',
'young range sense',
'young range switch',
'youth fountain',
'time',
'reverse up',
'reverse down',
'force up',
'force down',
'hatchery',
'snowmelt',
'append down',
'append up',
'clone',
'universe',
'oblivion',
'spawn',
'split',
	);

	for (@keywords){
		return 0 if (lc $_ eq lc $self->{node_name});
	}
	return 1;
}

sub _make_safe {
	my ($self, $name) = @_;

	if ($name){
		$name =~ s/\n/\\n/g;
	}

	return $name;
}

sub add_river_up {
	my ($self, $river) = @_;
	push @{$self->{rivers_up}}, $river;
}

sub add_river_down {
	my ($self, $river) = @_;
	$self->{river_down} = $river;
}

sub debug {
	my ($self) = @_;
	return "node $self->{uid} ($self->{node_name_safe})";
}

sub every_other {
	my ($self) = @_;
	$self->{toggle} = !$self->{toggle};
	return $self->{toggle};
}

1;

