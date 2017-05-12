package Language::Homespring;

$VERSION = 0.04;

use strict;
use warnings;

use Language::Homespring::Node;
use Language::Homespring::Salmon;
use Language::Homespring::Snowmelt;
use Language::Homespring::River;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{root_node} = undef;
	$self->{salmon} = [];
	$self->{snowmelt} = [];
	$self->{new_salmon} = [];
	$self->{dead_salmon} = [];
	$self->{output} = '';
	$self->{universe_ok} = 1;

	return $self;	
}

sub parse {
	my ($self, $source) = @_;

	my @tokens = 
		map{s/(\.$)|(^\.)/\n/g; $_}
		map{s/\. / /g; $_}
		map{s/ \././g; $_}
		split /(?:(?<!\.) (?!\.))|(?:\n(?!\.))/, $source;

	#print((join '|', @tokens)."\n\n");

	$self->{root_node} = new Language::Homespring::Node({
		'interp' => $self,
		'node_name' => shift @tokens,
	});
	my $parent = $self->{root_node};

	for my $token(@tokens){
		if ($token){
			my $new_node = new Language::Homespring::Node({
				'interp' => $self,
				'node_name' => $token,
				'parent_node' => $parent,
			});
			$parent->add_child($new_node);

			my $new_river = new Language::Homespring::River({
				'interp' => $self,
				'up_node' => $new_node,
				'down_node' => $parent,
			});
			$parent->add_river_up($new_river);
			$new_node->add_river_down($new_river);

			$parent = $new_node;
		}else{
			if (defined $parent->{parent_node}){
				$parent = $parent->{parent_node};
			}
		}
	}
}

sub tick {
	my ($self) = @_;
	my @nodes;

	$self->{output} = '';

	# has our universe been smashed?
	return if !$self->{universe_ok};

	# process snowmelts
		@nodes = $self->_get_nodes('snowmelt');
		for (@nodes){
			#spawn a new snowmelt
			my $snowmelt = new Language::Homespring::Snowmelt({'interp' => $self, 'location' => $_});
			push @{$self->{snowmelt}}, $snowmelt;
		}		
		$_->move() for (@{$self->{snowmelt}});

		# has our universe been smashed?
		return if !$self->{universe_ok};
	

	# process water

		# turn everything off
		$self->_set_all('water', 0);

		# water from springs
		@nodes = $self->_get_all_nodes();
		for (@nodes){
			$self->_water_downwards($_) if $_->{spring};
		}

	# process electricity

		# turn everything off
		$self->_set_recurse($self->{root_node}, 'power', 0);

		# process "powers"
		@nodes = $self->_get_nodes('powers');
		for(@nodes){
			if (!$_->{destroyed}){
				$self->_power_downwards($_);
			}
		}

		# process "hydro power"
		@nodes = $self->_get_nodes('hydro power');
		for (@nodes){
			$self->_power_downwards($_) if $_->{water} && !$_->{destroyed};
		}

		# process "power invert"
		@nodes = $self->_get_nodes('power invert');
		for (@nodes){
			$self->_power_downwards($_) if !$_->{power} && !$_->{destroyed};
		}

	# process salmon

		$_->move() for (@{$self->{salmon}});

		# sort out dead salmon
		@{$self->{salmon}} = grep{
			my $ok = 1;
			for my $dead(@{$self->{dead_salmon}}){
				$ok = 0 if $_ == $dead;
			}
			$ok;
		}@{$self->{salmon}};

		# sort out new salmon
		push @{$self->{salmon}}, @{$self->{new_salmon}};
		$self->{new_salmon} = [];

	# process others

		@nodes = $self->_get_nodes('hatchery');
		for (@nodes){
			if ($_->{power}){
				my $location = @{$_->{rivers_up}}[0];
				my $salmon = new Language::Homespring::Salmon({'interp' => $self,'mature' => 1, 'upstream' => 1, 'location' => $location});
				push @{$self->{salmon}}, $salmon;
			}
		}

	#	@nodes = $self->_get_nodes('bear');
	#	for (@nodes){
	#		for my $salmon($_->get_salmon()){
	#			$salmon->kill() if $salmon->{mature};
	#		}
	#	}

	return $self->{output};
}

sub run{
	my ($self, $max_ticks, $delimit) = @_;
	my $tick = 0;
	while(1){
		print $self->tick();
		print $delimit if defined($delimit);
		$tick++;
		return if (defined($max_ticks) && ($tick >= $max_ticks));
		return if !$self->{universe_ok};
	}
}

sub _set_all {
	my ($self, $prop, $value) = @_;
	$self->_set_recurse($self->{root_node}, $prop, $value);
}

sub _set_recurse {
	my ($self, $node, $prop, $value) = @_;
	$node->{$prop} = $value;
	$self->_set_recurse($_, $prop, $value) for @{$node->{child_nodes}};
}

sub _get_nodes {
	my ($self, $name) = @_;
	return $self->_get_nodes_i($self->{root_node}, $name);
}

sub _get_nodes_i {
	my ($self, $node, $name) = @_;
	my @out = ();
	push @out, $node if ($node->{node_name} eq $name);
	push @out, $self->_get_nodes_i($_, $name) for @{$node->{child_nodes}};
	return @out;
}

sub _get_all_nodes {
	my ($self) = @_;
	return $self->_get_all_nodes_i($self->{root_node});
}

sub _get_all_nodes_i {
	my ($self, $node) = @_;
	my @out = ();
	push @out, $node;
	push @out, $self->_get_all_nodes_i($_) for @{$node->{child_nodes}};
	return @out;
}

sub _power_downwards {
	my ($self, $node) = @_;

	return if (!$node->{parent_node});

	$node->{parent_node}->{power} = 1;

	return if ($node->{parent_node}->{node_name} eq 'power invert');
	return if ($node->{parent_node}->{node_name} eq 'insulated');
	return if ($node->{parent_node}->{node_name} eq 'force field');
	return if (($node->{parent_node}->{node_name} eq 'bridge') && ($node->{parent_node}->{destroyed}));

	# TODO: "sense" and "switch"

	$self->_power_downwards($node->{parent_node});
}

sub _water_downwards {
	my ($self, $node) = @_;

	return if (!$node->{parent_node});

	$node->{parent_node}->{water} = 1;

	return if (($node->{parent_node}->{node_name} eq 'force field') && ($node->{parent_node}->{power}));
	return if (($node->{parent_node}->{node_name} eq 'bridge') && ($node->{parent_node}->{destroyed}));
	return if (($node->{parent_node}->{node_name} eq 'evaporates') && ($node->{parent_node}->{power}));

	$self->_water_downwards($node->{parent_node});
}

__END__

=head1 NAME

Language::Homespring - Perl interpreter for "Homespring"

=head1 SYNOPSIS

  use Language::Homespring;

  my $hs = new Language::Homespring();
  $hs->parse("bear hatchery Hello,. World ..\n powers");

  # run one tick
  print $hs->tick;

  # run program until it ends or 1000 ticks are reached
  $hs->run(1000);

=head1 DESCRIPTION

This module is an interpreter for the Homespring language.
It currently only implements a small subset of the homespring
language and is broken in places. The Hello World example in
the "examples" folder works fine though :)

=head1 METHODS

=over 4

=item new()

Creates a new Language::Homespring object, with a blank op-tree.

=item parse( $source )

Parses $source into an op-tree, discarding any previous op-tree.

=item tick()

Executes a single "turn" of the interpreter, returning any output as a scalar.

=item run( $limit )

Executes ticks until the universe is destroyed or the (optional) tick limit is 
reached. Output is sent to STDOUT;

=back

=head1 NODE OPS

=head2 Supported Node Ops

  powers
  hydro power
  power invert
  marshy
  shallows
  rapids
  bear
  young bear
  bird
  net
  current
  insulated

=head2 Partially Supported Node Ops

  force field
  hatchery
  snowmelt
  universe

=head2 Unsupported Node Ops

  upstream killing device
  bridge
  waterfall
  evaporates
  pump
  fear
  lock
  inverse lock
  narrows
  sense
  switch
  upstream sense
  downstream sense
  range sense
  range switch
  young sense
  young switch
  young range sense
  young range switch
  youth fountain
  time
  reverse up
  reverse down
  force up
  force down
  append down
  append up
  clone
  oblivion
  spawn
  split

=head1 AUTHOR

Copyright (C) 2003 Cal Henderson <cal@iamcal.com>

Homespring is Copyright (C) 2003 Jeff Binder

=head1 SEE ALSO

L<perl>

L<Language::Homespring::Visualise>

http://home.fuse.net/obvious/hs.html

=cut
