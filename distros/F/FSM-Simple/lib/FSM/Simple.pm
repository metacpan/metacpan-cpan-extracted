package FSM::Simple;

# h2xs -XA -n FSM::Simple

use 5.010001;
use strict;
use warnings;
use Carp;
#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FSM::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
#	
#);

our $VERSION = '0.02';


##########################################################################################
### Public interface.
##########################################################################################

sub new {
	my ($class, %opts) = @_;
	
	my $trans_history = (exists $opts{trans_history} and $opts{trans_history} == 1) ? 1 : 0;
	
	my $self = {
		states                => {},    # Defined states
		init_state            => undef, # Name of initial state
		trans_history         => [],
		trans_history_enabled => $trans_history,
	};
	bless($self, $class);
	return $self;
}


sub add_state {
	my ($self, %args) = @_;
    my $state_name = $args{name};
    my $sub_ref    = $args{sub};
	
	croak "State name and subroutine reference required" unless defined $state_name and defined $sub_ref;
	croak "'sub' must be subroutine reference" unless ref $sub_ref eq 'CODE';
	croak "'name' must be SCALAR" unless ref $state_name eq '';
	
	$self->{states}{$state_name}{sub_to_run} = $sub_ref;
	$self->{states}{$state_name}{counter} = 0;

	$self->{init_state} = $state_name unless defined $self->{init_state}; # You don't need to know which state was added first.
	
	return;
}


sub init_state {
	my ($self, @states) = @_;
	return $self->{init_state} unless @states;
	
	my $init_state = shift @states;
	croak "Wrong initial state name" unless defined $init_state;
	croak "Initial state '$init_state' must be exists in list of states" unless exists $self->{states}{$init_state};
	
	$self->{init_state} = $init_state;
	
	return;
}

# This transition will be triggered when the subroutine returns this value.
sub add_trans {
    my ($self, %args) = @_;
	my $from_state     = $args{from};
	my $to_state       = $args{to};
	my $expected_value = $args{exp_val};
	
	croak "'from' required in add_transition"    unless defined $from_state;
	croak "'to' required in add_transition"      unless defined $to_state;
	croak "'exp_val' required in add_transition" unless defined $expected_value;
	
	croak "A name of start state '$from_state' must be defined"  unless exists $self->{states}{$from_state};
	croak "A name of target state '$to_state' must be defined"   unless exists $self->{states}{$to_state};
	croak "A value must be a SCALAR" if ref $expected_value ne '';

	$self->{states}{$from_state}{transitions}{$expected_value} = $to_state;
	
	return;
}


sub run {
	my ($self) = @_;
	return unless defined $self->{init_state};
	
	my $current_state = $self->{init_state}; # for convenience.
	my $rh_inout = {};
	
	while(1) {
		croak "Undefined state $current_state" unless exists $self->{states}{$current_state};
		
		$rh_inout = $self->{states}{$current_state}{sub_to_run}($rh_inout);
		$self->{states}{$current_state}{counter}++;
		push @{ $self->{trans_history} }, $current_state if $self->{trans_history_enabled};
		
		my $result = $rh_inout->{returned_value} // last;
		croak "Returned value must be a SCALAR" if ref $result ne '';
		croak "Next state is not defined for value '$result'" unless exists $self->{states}{$current_state}{transitions}{$result};
		
		$current_state = $self->{states}{$current_state}{transitions}{$result};
	}
	
	return;
}


##########################################################################################
### Additional methods.
##########################################################################################


sub trans_history {
    my ($self) = @_;
    return $self->{trans_history};
}


sub trans_stats {
    my ($self) = @_;
    
    my $rh_states_stats = {};
    while (my ($state, $rh_value) = each %{ $self->{states} }) {
        $rh_states_stats->{$state} = $rh_value->{counter};
    }

    return $rh_states_stats;
}


sub trans_array {
	my ($self) = @_;

	my %transitions;
	while (my ($state, $rh_value) = each %{ $self->{states} }) {
		while (my ($returned_val, $target_state) = each %{ $rh_value->{transitions} }) {
			$transitions{"${state}->${target_state}"} = {from => $state, to => $target_state, returned_value => $returned_val};
		}
    }

    return values %transitions;
}


sub clear_trans_history {
    my ($self) = @_;
    
    $self->{trans_history} = [];
    
    return;
}


sub clear_trans_stats {
    my ($self) = @_;
    
    foreach my $rh_state_desc ( values %{ $self->{states} }) {
        $rh_state_desc->{counter} = 0;
    }
    
    return;
}


sub trans_history_off {
    my ($self) = @_;
    
    $self->{trans_history_enabled} = 0;
    
    return;
}


sub trans_history_on {
    my ($self) = @_;
    
    $self->{trans_history_enabled} = 1;
    
    return;
}


sub generate_graphviz_code {
	my ($self, %args) = @_;
	my $graph_name = $args{name} || 'finite_state_machine';
	my $size       = $args{size} || '8';
	
	my $transitions = '';
	foreach my $rh_trans ($self->trans_array) {
		$transitions .= sprintf "    %s -> %s [ label = \"%s\" ];\n", $rh_trans->{from}, $rh_trans->{to}, $rh_trans->{returned_value};
	}
	
    my $graphviz_code = qq|
digraph $graph_name {
    rankdir=LR;
    size="$size";
    node [shape = doublecircle]; $self->{init_state};
    node [shape = circle];
$transitions
    // Install graphviz if required
    // Write this code to (e.g.) fsm.dot and run:
    // dot -T png fsm.dot -o fsm.png
}
    |;

	return $graphviz_code;
}


1;
__END__

=head1 NAME

FSM::Simple - Flexible Perl implementation of Finite State Machine.

=head1 SYNOPSIS

    use FSM::Simple;
    
    my $machine = FSM::Simple->new();
    
    $machine->add_state(name => 'init',      sub => \&init);
    $machine->add_state(name => 'make_cake', sub => \&make_cake);
    $machine->add_state(name => 'eat_cake',  sub => \&eat_cake);
    $machine->add_state(name => 'clean',     sub => \&clean);
    $machine->add_state(name => 'stop',      sub => \&stop);
    
    $machine->add_trans(from => 'init',      to => 'make_cake', exp_val => 'makeCake');
    $machine->add_trans(from => 'make_cake', to => 'eat_cake',  exp_val => 1);
    $machine->add_trans(from => 'eat_cake',  to => 'clean',     exp_val => 'good');
    $machine->add_trans(from => 'eat_cake',  to => 'make_cake', exp_val => 'bad');
    $machine->add_trans(from => 'clean',     to => 'stop',      exp_val => 'foo');
    $machine->add_trans(from => 'clean',     to => 'stop',      exp_val => 'done');
    
    $machine->run();
    
    sub init {
        my $rh_args = shift;
        print "Let's make a cake\n";
        
        # Prepare ingredients.
        $rh_args->{flour}  = 2;    # kg
        $rh_args->{water}  = 0.5;  # liter
        $rh_args->{leaven} = 0.1;  # kg
        
        $rh_args->{returned_value} = 'makeCake';
        return $rh_args;
    }
    
    sub make_cake {
        my $rh_args = shift;
        print "I am making a cake\n";
    
        # Do somethink with ingredients
        # from $rh_arhs
        # and put the cake into $rh_args
        $rh_args->{cake} = '%%%';
    
        $rh_args->{returned_value} = 1;
        return $rh_args;
    }
    
    sub eat_cake {
        my $rh_args = shift;
        print "I am eating a cake\n";
        
        # Eat the cake from $rh_args->{cake}
        
        # If the cake is tasty then return 'good' otherwise 'bad'.
        srand;
        if (rand(1000) < 400) {
            $rh_args->{returned_value} = 'good';
        }
        else {
            $rh_args->{returned_value} = 'bad';
        }
        
        return $rh_args;
    }
    
    sub clean {
        my $rh_args = shift;
        print "I am cleaning the kitchen\n";
    
        $rh_args->{returned_value} = 'done';
        return $rh_args;
    }
    
    sub stop {
        my $rh_args = shift;
        print "Stop machine\n";
    
        $rh_args->{returned_value} = undef; # stop condition!!!
        return $rh_args;
    }

Example of output:

  Let's make a cake
  I am making a cake
  I am eating a cake
  I am cleaning the kitchen
  Stop machine

=head1 DESCRIPTION

This module contains a class with simple Finite State Machine (FSM) implementation.
This is tiny layer for better control of flow in your code.
You can create your own subs and add these to the FSM object.
Next you can define transitions between those subs with expected returned value. 

Each of your sub should return hash reference like this:

  {
     returned_value => 'must be SCALAR!',
     # your data or data from previous sub
  }

which contains required key 'returned_value' and other keys if you want. 
Value of this key must be a SCALAR or undef. 
It will be taken into consideration in decision which state (sub) should be next.
FSM will stop when returned_value equals undef.


=head1 METHODS

=over

=item $fsm = FSM::Simple->new( )

=item $fsm = FSM::Simple->new( trans_history => 1 )

Simple constructor of FSM.
In this method you can turn on transitions history.

=item $fsm->add_state(name => 'state1', sub => \&sub_for_state1)

Add new state to the machine with name and sub reference to run.
This sub has to return hash reference with pair returned_value => 'some SCALAR' .
First state will be as initial state.
You can change initial state by 'init_state' method.

=item $fsm->add_trans( from => 'state1', to => 'state2', exp_val => 'some val' );

Add new transition between state1 and state2.
state2 will be run when state1 returns hash reference with pair
returned_value => 'some val'

=item $fsm->init_state

=item $fsm->init_state( 'state1' )

Get and set name of initial state.

=item $fsm->trans_history_on

Turn on transitions history.

=item $fsm->trans_history_off

Turn off transitions history.

=item $fsm->run

Main method to run machine.
FSM will stop if some state returns pair returned_value => undef .

=item $fsm->trans_history

Get array reference with states which were running
or empty array reference when tranisions history was turned off.

=item $fsm->clean_trans_history

Reset transitions history.

=item $fsm->trans_stats

After run $fsm->run this method will return hash reference with pairs:
state_name => counter (how many times this state was run) 

=item $fsm->clear_trans_stats

Reset values of stats counters.

=item $fsm->trans_array

Get defined transitions as reference of array of hashes with keys:
{ from => 'state1', to => 'state2', returned_value => 'some val' } 

=item $fsm->generate_graphviz_code( )

=item $fsm->generate_graphviz_code( size => 12 )

=item $fsm->generate_graphviz_code( name => 'name_of_graph' )

=item $fsm->generate_graphviz_code( name => 'name_of_graph', size => 12 )

You can generate code for Graphviz to show nice picture with states and transition.
Optionally you can set name of graph and/or size of states (default is 8).
In this code you will find some help how you can generate nice graph.

Example of graphviz code:

  digraph name_of_graph {
    rankdir=LR;
    size="8";
    node [shape = doublecircle]; initial_state;
    node [shape = circle];
    eat_cake_state -> make_cake_state [ label = "bad" ];
    make_cake_state -> eat_cake_state [ label = "1" ];
    clean_state -> stop_state [ label = "foo" ];
    eat_cake_state -> clean_state [ label = "good" ];
    friends_state -> eat_cake_state [ label = "thx" ];
    eat_cake_state -> friends_state [ label = "very good" ];
    initial_state -> make_cake_state [ label = "makeCake" ];

    // Install graphviz if required.
    // Write this code to (e.g.) fsm.dot and run:
    // dot -T png fsm.dot -o fsm.png
  }

=back

=head1 TEST COVERAGE

The result of test coverage:

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  ...-Simple/lib/FSM/Simple.pm  100.0   97.1  100.0  100.0    9.1    3.4   93.6
  add_state.t                    89.2    n/a    n/a  100.0    n/a   18.0   92.0
  add_trans.t                    95.1    n/a    n/a  100.0    n/a   17.4   96.5
  complex_tests.t               100.0  100.0    n/a  100.0    n/a   23.6  100.0
  init_state.t                  100.0    n/a    n/a  100.0    n/a   20.5  100.0
  run.t                         100.0    n/a    n/a  100.0    n/a   17.1  100.0
  Total                          98.3   97.4  100.0  100.0    9.1  100.0   96.7
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

This code was also checked by podchecker, B::Lint and Perl::Critic.

=head1 BUGS

Please contanct with me if you will find some bug or you have any questions/suggestions. 

=head1 SEE ALSO

L<DMA::FSM>, L<Set::FA::Element>, L<FLAT>

=head1 AUTHOR

Pawel Koscielny, E<lt>koscielny.pawel@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Koscielny

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
