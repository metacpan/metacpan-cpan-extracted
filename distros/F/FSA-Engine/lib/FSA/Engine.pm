package FSA::Engine;
our $VERSION = '0.01';
$VERSION = eval $VERSION;

#
# Simple implementation of a Finite-state Automata as a Moose Role
#
use Moose::Role;

# The states table, with optional entry and exit actions
#
has 'fsa_states' => (
    is          => 'rw',
    isa         => 'HashRef',
    lazy_build  => 1,
    builder     => '_build_fsa_states',
);

# The transitions table, from state to state, with test conditions and transition actions
#
has 'fsa_transitions' => (
    is          => 'rw',
    isa         => 'HashRef',
    lazy_build  => 1,
    builder     => '_build_fsa_transitions',
);

# The current state of the FSA
#
has 'fsa_state' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    trigger     => \&_fsa_state_trigger,
);

# The current input value
#
has 'fsa_input' => (
    is          => 'rw',
);

# The fsa_state change trigger
#
sub _fsa_state_trigger {
    my ( $self, $new_state, $old_state ) = @_;

    if (not $old_state or $new_state ne $old_state) {
        my $state_actions = $self->fsa_states->{$new_state};
        if ($state_actions and $state_actions->{entry_action}) {
            &{$state_actions->{entry_action}};
        }
    }
}


# do the FSA State Change checks
#
sub fsa_check_state {
    my ($self, $input) = @_;

    $self->fsa_input($input) if defined $input;

    # Do the transition tests for the current state
    my $state_transitions = $self->fsa_transitions->{$self->fsa_state};

    for my $transition_name (keys %$state_transitions) {
        my $transition = $state_transitions->{$transition_name};
        if ($transition->do_test($self->fsa_input)) {
            # test succeeded, carry out transition
            # First the leaving action (if any) of the current state
            my $state_actions = $self->fsa_states->{$self->fsa_state};
            if ($state_actions and $state_actions->{exit_action}) {
                &{$state_actions->{exit_action}};
            }

            # Now carry out the transition action (if any)
            if ($transition->action) {
                &{$transition->action}($self->fsa_input);
            }

            # Change the state (note: the entry action will be carried
            # out by virtue of the trigger, this ensures that the entry
            # action is always done even when the fsa_state is changed
            # manually)
            $self->fsa_state($transition->state);

            # return the new state
            return $self->fsa_state;
        }
    }
    # no state change occurred
    return;
}

1;

=head1 NAME

FSA::Engine - A Moose Role to convert an object into a Finite State Machine.

=head1 SYNOPSIS

Create a Package which defines your FSA states and transition rules.

  package PingPong;
  use Moose;
  with 'FSA::Engine';
  
  has 'counter' => (
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
  );
  
  sub _build_fsa_states {
    return {
      ping => { entry_action  => sub {print "ping!\n";}, },
      pong => { entry_action  => sub {print "pong!\n";}, },
      game_over => { },
    };
  }
 
  sub _build_fsa_transitions {
    return {
      ping => { ... },
      pong => { ... },
      game_over => { ... },
      # see BUILD_METHODS below for a full example
    };
  }
  1;

Create an instance of your class

  use PingPong;
  
  my $game = PingPong->new({ fsa_state => 'ping' });
  
  while ($game->fsa_state ne 'game_over') {
      $game->fsa_check_state;
  }

=head1 DESCRIPTION

This Moose Role allows you to implement a simple state machine in your class by 
defining the transitions and the states that comprise that state machine.

All you need to do to transform your class into a FSA is to C<with 'FSA::Engine'>.

This is not an ideal DFA implementation since it does not enforce a single
possible switch from one state to another, instead it short-circuits the
evaluation at the first rule to return true.

FSA::Engine uses named states and named transitions so it is easier to
tell what state you are in.

Optionally, each state can have an entry and an exit action that are triggered
when the state is entered and exited.

Each state may define transition rules which determine the conditions to switch 
to other states and these rules may optionally define actions to carry out if
the rules are followed.

=head1 BUILD METHODS

There are some attributes that require building methods.

=head2 _build_fsa_actions

  sub _build_fsa_states {
    return {
      ping => { entry_action  => sub {print "ping!\n";}, },
      pong => { entry_action  => sub {print "pong!\n";}, },
      game_over => { },
    };
  }

The fsa_actions attribute is defined as a hash reference, where the keys are
the names of each state and the value is a hash reference.

In this example the states are B<ping>, B<pong> and B<game_over>. The hash
reference referred to by each state has the following optional keys.

=head3 entry_action

This is an anonymous subroutine that (if defined) will be called when the
state is entered.

The B<entry_action> will be called after any Transition action that may have
been called leading to this state.

=head3 exit_action

This is an anonymous subroutine that (if defined) will be called when the
state is exited.

The B<exit_action> is called before any Transition action called leaving this
state.

=head2 _build_fsa_transitions

  sub _build_fsa_transitions {
    return {
      foo_state => {
        transition_one => { ... },
        transition_two => { ... }, 
      },
      bar_state => {
        transition_three => { ... },
      },
    };
  }

The fsa_transitions attribute is defined as a hash reference, where the keys are
the names of each state and the value is a hash reference of the transitions 
possible from that state. A more complete example is as follows (which goes with
the SYNOPSIS)

  sub _build_fsa_transitions {
    my ($self) = @_;
  
    return {
      ping  => {
        volley => FSA::Engine::Transition->new({
          test    => sub {$self->counter < 20;},
          action  => sub {$self->counter($self->counter+1);},
          state   => 'pong',
        }),
        end_of_game => FSA::Engine::Transition->new({
          test    => sub {$self->counter >= 20;},
          action  => sub {print "Game over\n";},
          state   => 'game_over',
        }),
      },
      pong  => {
        return_volley => FSA::Engine::Transition->new({
          test    => sub {1;},  # always goes back to ping
          state   => 'ping',
        }),
      },
      game_over   => {
      },
    };
  }

The transition names B<ping>, B<pong> and B<game_over> are keys to
L<FSA::Engine::Transition> objects which will define the
B<test> to carry out, an optional B<action> to carry out if the test succeeds
and the B<state> to move to if the test succeeds.

Each B<test> is made until one succeeds at which point the B<action> (if any)
is carried out and the FSA state is advanced to B<state>.

When a B<test> succeeds, all futher tests are short-circuited. Note that this
action may change in future releases.

=head1 METHODS

An FSA class will have the following additional methods:

=head2 fsa_check_state

  $new_state = $my_fsa->fsa_check_state;

  $new_state = $my_fsa->fsa_check_state($input);

Check for a state change in the FSA, optionally a new input value can be provided.

If the state machine changes state, then the new state (name) is returned, otherwise
it returns C<undef>

=head1 ATTRIBUTES

An FSA class will have the following additional attributes:

=head2 fsa_state

This is a required attribute.

  my $game = PingPong->new({
    fsa_state => 'ping',
    });

When used during construction the C<fsa_state> determines the initial state of the
FSA.

  $current_state = $my_fsa->fsa_state;

At other times it returns the current state of the FSA.

=head1 SUPPORT

You can find information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FSA-Engine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/i/FSA-Engine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FSA-Engine>

=item * Search CPAN

L<http://search.cpan.org/dist/FSA-Engine>

=back

=head1 SEE ALSO

This module was influenced in part by L<FSA::Rules> which implements
an FSA using a traditional Perl OO method.

=head1 AUTHOR

Ian C. Docherty <pause@iandocherty.com>

Thanks also to James Spurin <pause@twitchy.net> for support and advice.

Thanks to various members of the Moose mailing list for recommendations on how to name this module.

=head1 COPYRIGHT AND LICENSE

Copyright(c) 2011 Ian C. Docherty

This module is free software; you can distribute it and/or modify it under the same
terms as Perl itself.
