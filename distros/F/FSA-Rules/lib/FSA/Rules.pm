package FSA::Rules;

use strict;
use 5.006_002;
use Scalar::Util 1.01 ();
$FSA::Rules::VERSION = '0.35';

=head1 Name

FSA::Rules - Build simple rules-based state machines in Perl

=head1 Synopsis

  my $fsa = FSA::Rules->new(
     ping => {
         do => sub {
             print "ping!\n";
             my $state = shift;
             $state->result('pong');
             $state->machine->{count}++;
         },
         rules => [
             game_over => sub { shift->machine->{count} >= 20 },
             pong      => sub { shift->result eq 'pong' },
         ],
     },

     pong => {
         do => sub { print "pong!\n" },
         rules => [ ping => 1, ], # always goes back to ping
     },
     game_over => { do => sub { print "Game Over\n" } }
  );

  $fsa->start;
  $fsa->switch until $fsa->at('game_over');

=head1 Description

This class implements a simple state machine pattern, allowing you to quickly
build rules-based state machines in Perl. As a simple implementation of a
powerful concept, it differs slightly from an ideal DFA model in that it does
not enforce a single possible switch from one state to another. Rather, it
short circuits the evaluation of the rules for such switches, so that the
first rule to return a true value will trigger its switch and no other switch
rules will be checked. (But see the C<strict> attribute and parameter to
C<new()>.) It differs from an NFA model in that it offers no back-tracking.
But in truth, you can use it to build a state machine that adheres to either
model--hence the more generic FSA moniker.

FSA::Rules uses named states so that it's easy to tell what state you're in
and what state you want to go to. Each state may optionally define actions
that are triggered upon entering the state, after entering the state, and upon
exiting the state. They may also define rules for switching to other states,
and these rules may specify the execution of switch-specific actions. All
actions are defined in terms of anonymous subroutines that should expect an
FSA::State object itself to be passed as the sole argument.

FSA::Rules objects and the FSA::State objects that make them up are all
implemented as empty hash references. This design allows the action
subroutines to use the FSA::State object passed as the sole argument, as well
as the FSA::Rules object available via its C<machine()> method, to stash data
for other states to access, without the possibility of interfering with the
state or the state machine itself.

=head2 Serialization

As of version 0.24, FSA::Rules supports serialization by L<Storable> 2.05 and
later. In other words, FSA::Rules can function as a persistent state machine.

However, FSA::Rules stores data outside of FSA::Rules objects, in private data
structures inside the FSA::Rules module itself. Therefore, unless you want to
clone your FSA::Rules object, you must let it fall out of scope after you
serialize it, so that its data will be cleared from memory. Otherwise, if you
freeze and thaw an FSA::Rules object in a single process without C<undef>ing
the original, there will be I<two> copies of the object stored by FSA::Rules.

So how does it work? Because the rules are defined as code references, you
must use Storable 2.05 or later and set its C<$Deparse> and C<$Eval> variables
to true values:

  use Storable 2.05 qw(freeze thaw);

  local $Storable::Deparse = 1;
  local $Storable::Eval    = 1;

  my $frozen = freeze($fsa);
  $fsa = thaw($frozen);

The only caveat is that, while Storable can serialize code references, it
doesn't properly reference closure variables. So if your rules code references
are closures, you'll have to serialize the data that they refer to yourself.

=cut

##############################################################################

=head1 Class Interface

=head2 Constructor

=head3 new

  my $fsa = FSA::Rules->new(
      foo_state => { ... },
      bar_state => { ... },
  );

  $fsa = FSA::Rules->new(
      \%params,
      foo_state => { ... },
      bar_state => { ... },
  );

Constructs and returns a new FSA::Rules object. An optional first argument
is a hash reference that may contain one or more of these keys:

=over

=item start

Causes the C<start()> method to be called on the machine before returning it.

=item done

A value to which to set the C<done> attribute.

=item strict

A value to which to set the C<strict> attribute.

=item state_class

The name of the class to use for state objects. Defaults to "FSA::State". Use
this parameter if you want to use a subclass of FSA::State.

=item state_params

A hash reference of parameters to pass as a list to the C<state_class>
constructor.

=back

All other parameters define the state table, where each key is the name of a
state and the following hash reference defines the state, its actions, and its
switch rules. These state specifications will be converted to FSA::State
objects available via the C<states()> method. The first state parameter is
considered to be the start state; call the C<start()> method to automatically
enter that state.

The supported keys in the state definition hash references are:

=over

=item label

  label => 'Do we have a username?',
  label => 'Create a new user',

A label for the state. It might be the question that is being asked within the
state (think decision tree), the answer to which determines which rule will
trigger the switch to the next state. Or it might merely describe what's
happening in the state.

=item on_enter

  on_enter => sub { ... }
  on_enter => [ sub {... }, sub { ... } ]

Optional. A code reference or array reference of code references. These will
be executed when entering the state, after any switch actions defined by the
C<rules> of the previous state. The FSA::State for which the C<on_enter>
actions are defined will be passed to each code reference as the sole
argument.

=item do

  do => sub { ... }
  do => [ sub {... }, sub { ... } ]

Optional. A code reference or array reference of code references. These are
the actions to be taken while in the state, and will execute after any
C<on_enter> actions. The FSA::State object for which the C<do> actions are
defined will be passed to each code reference as the sole argument.

=item on_exit

  on_exit => sub { ... }
  on_exit => [ sub {... }, sub { ... } ]

Optional. A code reference or array reference of code references. These will
be executed when exiting the state, before any switch actions (defined by
C<rules>). The FSA::State object for which the C<on_exit> actions are defined
will be passed to each code reference as the sole argument.

=item rules

Optional. The rules for switching from the state to other states. This is an
array reference but shaped like a hash. The keys are the names of the states
to consider moving to, while the values are the rules for switching to that
state. The rules will be executed in the order specified in the array
reference, and I<they will short-circuit> unless the C<strict> attribute has
been set to a true value. So for the sake of efficiency it's worthwhile to
specify the switch rules most likely to evaluate to true before those more
likely to evaluate to false.

Rules themselves are best specified as hash references with the following
keys:

=over

=item rule

A code reference or value that will be evaluated to determine whether to
switch to the specified state. The value must be true or the code reference
must return a true value to trigger the switch to the new state, and false not
to switch to the new state. When executed, it will be passed the FSA::State
object for the state for which the rules were defined, along with any other
arguments passed to C<try_switch()> or C<switch()>--the methods that execute
the rule code references. These arguments may be inputs that are specifically
tested to determine whether to switch states. To be polite, rules should not
transform the passed values if they're returning false, as other rules may
need to evaluate them (unless you're building some sort of chaining rules--but
those aren't really rules, are they?).

=item message

An optional message that will be added to the current state when the rule
specified by the C<rule> parameter evaluates to true. The message will also be
used to label switches in the output of the C<graph()> method.

=item action

A code reference or an array reference of code references to be executed
during the switch, after the C<on_exit> actions have been executed in the
current state, but before the C<on_enter> actions execute in the new state.
Two arguments will be passed to these code references: the FSA::State object
for the state for which they were defined, and the FSA::State object for the
new state (which will not yet be the current state).

=back

A couple of examples:

  rules => [
      foo => {
          rule => 1
      },
      bar => {
          rule    => \&goto_bar,
          message => 'Have we got a bar?',
      },
      yow => {
          rule    => \&goto_yow,
          message => 'Yow!',
          action  => [ \&action_one, \&action_two],
      }
  ]

A rule may also simply be a code reference or value that will be evaluated
when FSA::Rules is determining whether to switch to the new state. You might want
just specify a value or code reference if you don't need a message label or
switch actions to be executed. For example, this C<rules> specification:

  rules => [
      foo => 1
  ]

Is equivalent to this C<rules> specification:

  rules => [
      foo => { rule => 1 }
  ]

And finally, you can specify a rule as an array reference. In this case, the
first item in the array will be evaluated to determine whether to switch to
the new state, and any other items must be code references that will be
executed during the switch. For example, this C<rules> specification:

  rules => [
      yow => [ \&check_yow, \&action_one, \&action_two ]
  ]

Is equivalent to this C<rules> specification:

  rules => [
      yow => {
          rule   =>  \&check_yow,
          action => [ \&action_one, \&action_two ],
      }
  ]

=back

=cut

my (%machines, %states);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my $params = ref $_[0] ? shift : {};
    my $fsa = $machines{$self} = {
        done   => undef,
        notes  => {},
        stack  => [],
        table  => {},
        self   => $self,
    };

    # Weaken the circular reference.
    Scalar::Util::weaken $fsa->{self};

    $params->{state_class}  ||= 'FSA::State';
    $params->{state_params} ||= {};
    while (@_) {
        my $state = shift;
        my $def   = shift;
        $self->_croak(qq{The state "$state" already exists})
          if exists $fsa->{table}{$state};

        # Setup enter, exit, and do actions.
        for (qw(on_enter do on_exit)) {
            if (my $ref = ref $def->{$_}) {
                $def->{$_} = [$def->{$_}] if $ref eq 'CODE';
            } else {
                $def->{$_} = [];
            }
        }

        # Create the state object and cache the state data.
        my $obj = $params->{state_class}->new(%{$params->{state_params}});
        $def->{name} = $state;
        $def->{machine} = $self;
        $fsa->{table}{$state} = $obj;
        push @{$fsa->{ord}}, $obj;
        $states{$obj} = $def;

        # Weaken the circular reference.
        Scalar::Util::weaken $def->{machine};
    }

    # Setup rules. We process the table a second time to catch invalid
    # references.
    while (my ($key, $obj) = each %{$fsa->{table}}) {
        my $def = $states{$obj};
        if (my $rule_spec = $def->{rules}) {
            my @rules;
            while (@$rule_spec) {
                my $state = shift @$rule_spec;
                $self->_croak(
                    qq{Unknown state "$state" referenced by state "$key"}
                ) unless $fsa->{table}{$state};

                my $rules = shift @$rule_spec;
                my $exec = ref $rules eq 'ARRAY' ? $rules : [$rules];
                my $rule = shift @$exec;
                my $message;
                if (ref $rule eq 'HASH') {
                    $self->_croak(
                        qq{In rule "$state", state "$key": you must supply a rule.}
                    ) unless exists $rule->{rule};
                    $exec = ref $rule->{action} eq 'ARRAY'
                      ? $rule->{action}
                      : [$rule->{action}]
                      if exists $rule->{action};
                    $message = $rule->{message} if exists $rule->{message};
                    $rule    = $rule->{rule};
                }
                # Used to convert a raw value to a code reference here, but as
                # it ended up as a closure and these don't serialize very
                # well, I pulled it out. Now try_switch has to check to see if
                # a rule is a literal value each time it's called. This
                # actually makes it faster for literal values, but a little
                # slower for code references.

                push @rules, {
                    state   => $fsa->{table}{$state},
                    rule    => $rule,
                    exec    => $exec,
                    message => $message,
                };

                # Weaken the circular reference.
                Scalar::Util::weaken $rules[-1]->{state};
            }
            $def->{rules} = \@rules;
        } else {
            $def->{rules} = [];
        }
    }

    # Handle any parameters.
    $self->start if $params->{start};
    $self->done($params->{done}) if exists $params->{done};
    $self->strict($params->{strict}) if exists $params->{strict};
    return $self;
}

##############################################################################

=head1 Instance Interface

=head2 Instance Methods

=head3 start

  my $state = $fsa->start;

Starts the state machine by setting the state to the first state defined in
the call to C<new()>. If the machine is already in a state, an exception will
be thrown. Returns the start state FSA::State object.

=cut

sub start {
    my $self = shift;
    my $fsa = $machines{$self};
    $self->_croak(
        'Cannot start machine because it is already running'
    ) if $fsa->{current};
    my $state = $fsa->{ord}[0] or return $self;
    $self->curr_state($state);
    return $state;
}

##############################################################################

=head3 at

  $fsa->switch until $fsa->at('game_over');

Requires a state name. Returns false if the current machine state does not
match the name. Otherwise, it returns the state.

=cut

sub at {
    my ($self, $name) = @_;
    $self->_croak("You must supply a state name") unless defined $name;
    my $fsa = $machines{$self};
    $self->_croak(qq{No such state "$name"})
      unless exists $fsa->{table}{$name};
    my $state = $self->curr_state or return;
    return unless $state->name eq $name;
    return $state;
}

##############################################################################

=head3 curr_state

  my $curr_state = $fsa->curr_state;
  $fsa->curr_state($curr_state);

Get or set the current FSA::State object. Pass a state name or object to set
the state. Setting a new state will cause the C<on_exit> actions of the
current state to be executed, if there is a current state, and then execute
the C<on_enter> and C<do> actions of the new state. Returns the new FSA::State
object when setting the current state.

=cut

sub curr_state {
    my $self = shift;
    my $fsa = $machines{$self};
    my $curr = $fsa->{current};
    return $curr unless @_;

    my $state = shift;
    unless (ref $state) {
        my $name = $state;
        $state = $fsa->{table}{$name}
          or $self->_croak(qq{No such state "$name"});
    }

    # Exit the current state.
    $curr->exit if $curr;
    # Run any switch actions.
    if (my $exec = delete $fsa->{exec}) {
        $_->($curr, $state) for @$exec;
    }

    # Push the new state onto the stack and cache the index.
    push @{$fsa->{stack}}
      => [$state->name => { result => undef, message => undef}];
    push @{$states{$state}->{index}}, $#{$fsa->{stack}};

    # Set the new state.
    $fsa->{current} = $state;
    $state->enter;
    $state->do;
    return $state;
}

##############################################################################

=head3 state

Deprecated alias for C<curr_state()>. This method will issue a warning and
will be removed in a future version of FSA::Rules. Use C<curr_state()>,
instead.

=cut

sub state {
    require Carp;
    Carp::carp(
        'The state() method has been deprecated. Use curr_state() instead'
    );
    shift->curr_state(@_);
}

##############################################################################

=head3 prev_state

  my $prev_state = $fsa->prev_state;

Returns the FSA::State object representing the previous state. This is useful
in states where you need to know what state you came from, and can be very
useful in "fail" states.

=cut

sub prev_state {
    my $self = shift;
    my $stacktrace = $self->raw_stacktrace;
    return unless @$stacktrace > 1;
    return $machines{$self}->{table}{$stacktrace->[-2][0]};
}

##############################################################################

=head3 states

  my @states = $fsa->states;
  my $states = $fsa->states;
  my $state  = $fsa->states($state_name);
  @states    = $fsa->states(@state_names);
  $states    = $fsa->states(@state_names);

Called with no arguments, this method returns a list or array reference of all
of the FSA::State objects that represent the states defined in the state
machine. When called with a single state name, it returns the FSA::State object
object for that state. When called with more than one state name arguments,
it returns a list or array reference of those states.

If called with any state names that did not exist in the original definition of
the state machine, this method will C<croak()>.

=cut

sub states {
    my $self = shift;
    my $fsa = $machines{$self};
    return wantarray ? @{$fsa->{ord}} : $fsa->{ord} unless @_;

    if (my @errors = grep { not exists $fsa->{table}{$_} } @_) {
        $self->_croak("No such state(s) '@errors'");
    }

    return $fsa->{table}{+shift} unless @_ > 1;
    return wantarray ? @{$fsa->{table}}{@_} : [ @{$fsa->{table}}{@_} ];

}

##############################################################################

=head3 try_switch

  my $state = $fsa->try_switch;
  $state = $fsa->try_switch(@inputs);

Checks the switch rules of the current state and switches to the first new
state for which a rule returns a true value. The evaluation of switch rules
short-circuits to switch to the first state for which a rule evaluates to a
true value unless the C<strict> attribute is set to a true value.

If <strict> is set to a true value, I<all> rules will be evaluated, and if
more than one returns a true statement, an exception will be thrown. This
approach guarantees that every attempt to switch from one state to another
will have one and only one possible destination state to which to switch, thus
satisfying the DFA pattern.

All arguments passed to C<try_switch> will be passed to the switch rule code
references as inputs. If a switch rule evaluates to true and there are
additional switch actions for that rule, these actions will be executed after
the C<on_exit> actions of the current state (if there is one) but before the
C<on_enter> actions of the new state. They will be passed the current state
object and the new state object as arguments.

Returns the FSA::State object representing the state to which it switched and
C<undef> if it cannot switch to another state.

=cut

sub try_switch {
    my $self = shift;
    my $fsa = $machines{$self};
    my $state = $fsa->{current};
    # XXX Factor this out to the state class to evaluate the rules?
    my @rules = $state->_rules;
    my $next;
    while (my $rule = shift @rules) {
        my $code = $rule->{rule};
        next unless ref $code eq 'CODE' ? $code->($state, @_) : $code;

        # Make sure that no other rules evaluate to true in strict mode.
        if (@rules && $self->strict) {
            if ( my @new = grep {
                my $c = $_->{rule};
                ref $c eq 'CODE' ? $c->( $state, @_ ) : $c
            } @rules ) {
                $self->_croak(
                    'Attempt to switch from state "', $state->name, '"',
                    ' improperly found multiple destination states: "',
                    join('", "', map { $_->{state}->name } $rule, @new), '"'
                );
            }
        }

        # We're good to go.
        $fsa->{exec} = $rule->{exec};
        $state->message($rule->{message}) if defined $rule->{message};
        $next = $self->curr_state($rule->{state});
        last;
    }
    return $next;
}

##############################################################################

=head3 switch

  my $state = eval { $fsa->switch(@inputs) };
  print "No can do" if $@;

The fatal form of C<try_switch()>. This method attempts to switch states and
returns the FSA::State object on success and throws an exception on failure.

=cut

sub switch {
    my $self = shift;
    my $ret = $self->try_switch(@_);
    return $ret if defined $ret;
    $self->_croak(
        'Cannot determine transition from state "',
        $machines{$self}->{current}->name, '"'
    );
}

##############################################################################

=head3 done

  my $done = $fsa->done;
  $fsa->done($done);
  $fsa->done( sub {...} );

Get or set a value to indicate whether the engine is done running. Or set it
to a code reference to have that code reference called each time C<done()> is
called without arguments and have I<its> return value returned. A code
reference should expect the FSA::Rules object passed in as its only argument.
Note that this varies from the pattern for state actions, which should expect
the relevant FSA::State object to be passed as the argument. Call the
C<curr_state()> method on the FSA::Rules object if you want the current state
in your C<done> code reference.

This method can be useful for checking to see if your state engine is done
running, and calling C<switch()> when it isn't. States can set it to a true
value when they consider processing complete, or you can use a code reference
that determines whether the machine is done. Something like this:

  my $fsa = FSA::Rules->new(
      foo => {
          do    => { $_[0]->machine->done(1) if ++$_[0]->{count} >= 5 },
          rules => [ foo => 1 ],
      }
  );

Or this:

  my $fsa = FSA::Rules->new(
      foo => {
          do    => { ++shift->machine->{count} },
          rules => [ foo => 1 ],
      }
  );
  $fsa->done( sub { shift->{count} >= 5 });

Then you can just run the state engine, checking C<done()> to find out when
it's, uh, done.

  $fsa->start;
  $fsa->switch until $fsa->done;

Although you could just use the C<run()> method if you wanted to do that.

Note that C<done> will be reset to C<undef> by a call to C<reset()> when it's
not a code reference. If it I<is> a code reference, you need to be sure to
write it in such a way that it knows that things have been reset (by examining
states, for example, all of which will have been removed by C<reset()>).

=cut

sub done {
    my $self = shift;
    my $fsa = $machines{$self};
    if (@_) {
        $fsa->{done} = shift;
        return $self;
    }
    my $code = $fsa->{done};
    return $code unless ref $code eq 'CODE';
    return $code->($self);
}

##############################################################################

=head3 strict

  my $strict = $fsa->strict;
  $fsa->strict(1);

Get or set the C<strict> attribute of the state machine. When set to true, the
strict attribute disallows the short-circuiting of rules and allows a transfer
if only one rule returns a true value. If more than one rule evaluates to
true, an exception will be thrown.

=cut

sub strict {
    my $self = shift;
    return $machines{$self}->{strict} unless @_;
    $machines{$self}->{strict} = shift;
    return $self;
}

##############################################################################

=head3 run

  $fsa->run;

This method starts the FSA::Rules engine (if it hasn't already been set to a
state) by calling C<start()>, and then calls the C<switch()> method repeatedly
until C<done()> returns a true value. In other words, it's a convenient
shortcut for:

    $fsa->start unless $self->curr_state;
    $fsa->switch until $self->done;

But be careful when calling this method. If you have no failed switches
between states and the states never set the C<done> attribute to a true value,
then this method will never die or return, but run forever. So plan carefully!

Returns the FSA::Rules object.

=cut

sub run {
    my $self = shift;
    $self->start unless $self->curr_state;
    $self->switch until $self->done;
    return $self;
}

##############################################################################

=head3 reset

  $fsa->reset;

The C<reset()> method clears the stack and notes, sets the current state to
C<undef>, and sets C<done> to C<undef> (unless C<done> is a code reference).
Also clears any temporary data stored directly in the machine hash reference
and the state hash references. Use this method when you want to reuse your
state machine. Returns the DFA::Rules object.

  my $fsa = FSA::Rules->new(@state_machine);
  $fsa->done(sub {$done});
  $fsa->run;
  # do a bunch of stuff
  $fsa->{miscellaneous} = 42;
  $fsa->reset->run;
  # $fsa->{miscellaneous} does not exist

=cut

sub reset {
    my $self = shift;
    my $fsa = $machines{$self};
    $fsa->{current} = undef;
    $fsa->{notes} = {};
    $fsa->{done} = undef unless ref $fsa->{done} eq 'CODE';
    @{$fsa->{stack}} = ();
    for my $state ($self->states) {
        @{$states{$state}->{index}} = ();
        delete $state->{$_} for keys %$state;
    }
    delete $self->{$_} for keys %$self;
    return $self;
}

##############################################################################

=head3 notes

  $fsa->notes($key => $value);
  my $val = $fsa->notes($key);
  my $notes = $fsa->notes;

The C<notes()> method provides a place to store arbitrary data in the state
machine, just in case you're not comfortable using the FSA::Rules object
itself, which is an empty hash. Any data stored here persists for the lifetime
of the state machine or until C<reset()> is called.

Conceptually, C<notes()> contains a hash of key-value pairs.

C<< $fsa->notes($key => $value) >> stores a new entry in this hash.
C<< $fsa->notes->($key) >> returns a previously stored value.
C<< $fsa->notes >>, called without arguments, returns a reference to the
entire hash of key-value pairs.

Returns the FSA::Rules object when setting a note value.

=cut

sub notes {
    my $self = shift;
    my $fsa = $machines{$self};
    return $fsa->{notes} unless @_;
    my $key = shift;
    return $fsa->{notes}{$key} unless @_;
    $fsa->{notes}{$key} = shift;
    return $self;
}

##############################################################################

=head3 last_message

  my $message = $fsa->last_message;
  $message = $fsa->last_message($state_name);

Returns the last message of the current state. Pass in the name of a state to
get the last message for that state, instead.

=cut

sub last_message {
    my $self = shift;
    return $self->curr_state->message unless @_;
    return $self->states(@_)->message;
}

##############################################################################

=head3 last_result

  my $result = $fsa->last_result;
  $result = $fsa->last_result($state_name);

Returns the last result of the current state. Pass in the name of a state to
get the last result for that state, instead.

=cut

sub last_result {
    my $self = shift;
    return $self->curr_state->result unless @_;
    return $self->states(@_)->result;
}

##############################################################################

=head3 stack

  my $stack = $fsa->stack;

Returns an array reference of all states the machine has been in since it was
created or since C<reset()> was last called, beginning with the first state
and ending with the current state. No state name will be added to the stack
until the machine has entered that state. This method is useful for debugging.

=cut

sub stack {
    my $self = shift;
    return [map { $_->[0] } @{$machines{$self}->{stack}}];
}

##############################################################################

=head3 raw_stacktrace

  my $stacktrace = $fsa->raw_stacktrace;

Similar to C<stack()>, this method returns an array reference of the states
that the machine has been in. Each state is an array reference with two
elements. The first element is the name of the state and the second element is
a hash reference with two keys, "result" and "message". These are set to the
values (if used) set by the C<result()> and C<message()> methods on the
corresponding FSA::State objects.

A sample state:

  [
      some_state,
      {
          result  => 7,
          message => 'A human readable message'
      }
  ]

=cut

sub raw_stacktrace { $machines{shift()}->{stack} }

##############################################################################

=head3 stacktrace

  my $trace = $fsa->stacktrace;

Similar to C<raw_stacktrace>, except that the C<result>s and C<message>s are
output in a human readable format with nicely formatted data (using
Data::Dumper). Functionally there is no difference from C<raw_stacktrace()>
unless your states are storing references in their C<result>s or C<message>s

For example, if your state machine ran for only three states, the output may
resemble the following:

  State: foo
  {
    message => 'some message',
    result => 'a'
  }

  State: bar
  {
    message => 'another message',
    result => [0, 1, 2]
  }

  State: bar
  {
    message => 'and yet another message',
    result => 2
  }

=cut

sub stacktrace {
    my $states     = shift->raw_stacktrace;
    my $stacktrace = '';
    require Data::Dumper;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys  = 1;
    local  $Data::Dumper::Useperl  = $] < 5.008;
    foreach my $state (@$states) {
        $stacktrace .= "State: $state->[0]\n";
        $stacktrace .= Data::Dumper::Dumper($state->[1]);
        $stacktrace .= "\n";
    }
    return $stacktrace;
}

##############################################################################

=head3 graph

  my $graph_viz = $fsa->graph(@graph_viz_args);
  $graph_viz = $fsa->graph(\%params, @graph_viz_args);

Constructs and returns a L<GraphViz> object useful for generating graphical
representations of the complete rules engine. The parameters to C<graph()> are
all those supported by the GraphViz constructor; consult the L<GraphViz>
documentation for details.

Each node in the graph represents a single state. The label for each node in
the graph will be either the state label or if there is no label, the state
name.

Each edge in the graph represents a rule that defines the relationship between
two states. If a rule is specified as a hash reference, the C<message> key
will be used as the edge label; otherwise the label will be blank.

An optional hash reference of parameters may be passed as the first argument
to C<graph()>. The supported parameters are:

=over

=item with_state_name

This parameter, if set to true, prepends the name of the state and two
newlines to the label for each node. If a state has no label, then the state
name is simply used, regardless. Defaults to false.

=item wrap_nodes

=item wrap_node_labels

This parameter, if set to true, will wrap the node label text. This can be
useful if the label is long. The line length is determined by the
C<wrap_length> parameter. Defaults to false.

=item wrap_edge_labels

=item wrap_labels

This parameter, if set to true, will wrap the edge text. This can be useful if
the rule message is long. The line length is determined by the C<wrap_length>
parameter. Defaults to false C<wrap_labels> is deprecated and will be removed
in a future version.

=item text_wrap

=item wrap_length

The line length to use for wrapping text when C<wrap_nodes> or C<wrap_labels>
is set to true. C<text_wrap> is deprecated and will be removed in a future
version. Defaults to 25.

=item node_params

A hash reference of parameters to be passed to the GraphViz C<add_node()>
method when setting up a state as a node. Only the C<label> parameter will be
ignored. See the C<GraphViz|GraphViz/"add_node"> documentation for the list of
supported parameters.

=item edge_params

A hash reference of parameters to be passed to the GraphViz C<add_node()>
method when setting up a state as a node. See the
C<GraphViz|GraphViz/"add_edge"> documentation for the list of supported
parameters.

=back

B<Note:> If either C<GraphViz> or C<Text::Wrap> is not available on your
system, C<graph()> will simply will warn and return.

=cut

sub graph {
    my $self = shift;
    my $params = ref $_[0] ? shift : {};

    eval "use GraphViz 2.00; use Text::Wrap";
    if ($@) {
        warn "Cannot create graph object: $@";
        return;
    }

    # Handle backwards compatibility.
    $params->{wrap_node_labels} = $params->{wrap_nodes}
        unless exists $params->{wrap_node_labels};
    $params->{wrap_edge_labels} = $params->{wrap_labels}
        unless exists $params->{wrap_edge_labels};
    $params->{wrap_length} = $params->{text_wrap}
        unless exists $params->{wrap_length};

    # Set up defaults.
    local $Text::Wrap::columns = $params->{wrap_length} || 25;
    my @node_params = %{ $params->{node_params} || {} };
    my @edge_params = %{ $params->{edge_params} || {} };

    # Iterate over the states.
    my $machine = $machines{$self};
    my $graph = GraphViz->new(@_);
    for my $state (@{ $machine->{ord} }) {
        my $def = $states{$state};
        my $name  = $def->{name};

        my $label = !$def->{label} ? $name
            : $params->{with_state_name}  ? "$name\n\n$def->{label}"
            :                               $def->{label};

        $graph->add_node(
            $name,
            @node_params,
            label => $params->{wrap_node_labels} ? wrap('', '', $label) : $label,
        );
        next unless exists $def->{rules};
        for my $condition (@{ $def->{rules} }) {
            my $rule = $condition->{state}->name;
            my @edge = ($name => $rule);
            if ($condition->{message}) {
                push @edge, label => $params->{wrap_edge_labels}
                    ? wrap('', '', $condition->{message})
                    : $condition->{message};
            }
            $graph->add_edge( @edge, @edge_params );
        }
    }
    return $graph;
}

##############################################################################

=head3 DESTROY

This method cleans up an FSA::Rules object's internal data when it is released
from memory. In general, you don't have to worry about the C<DESTROY()> method
unless you're subclassing FSA::Rules. In that case, if you implement your own
C<DESTROY()> method, just be sure to call C<SUPER::DESTROY()> to prevent
memory leaks.

=cut

# This method deletes the record from %machines, which has a reference to each
# state, so those are deleted too. Each state refers back to the FSA::Rules
# object itself, so as each of them is destroyed, it's removed from %states
# and the FSA::Rules object gets all of its references defined in this file
# freed, too. No circular references, so no problem.

sub DESTROY { delete $machines{+shift}; }

##############################################################################

# Private error handler.
sub _croak {
    shift;
    require Carp;
    Carp::croak(@_);
}

##############################################################################

=begin comment

Let's just keep the STORABLE methods hidden. They should just magically work.

=head3 STORABLE_freeze

=cut

sub STORABLE_freeze {
    my ($self, $clone) = @_;
    return if $clone;
    my $fsa = $machines{$self};
    return ( $self, [ { %$self }, $fsa, @states{ @{ $fsa->{ord} } } ] );
}

##############################################################################

=head3 STORABLE_thaw

=end comment

=cut

sub STORABLE_thaw {
    my ($self, $clone, $junk, $data) = @_;
    return if $clone;
    %{ $self }                  = %{ shift @$data };
    my $fsa                     = shift @$data;
    $machines{ $self }          = $fsa;
    @states{ @{ $fsa->{ord} } } = @$data;
    return $self;
}

##############################################################################

package FSA::State;
$FSA::State::VERSION = '0.35';

=head1 FSA::State Interface

FSA::State objects represent individual states in a state machine. They are
passed as the first argument to state actions, where their methods can be
called to handle various parts of the processing, set up messages and results,
or access the state machine object itself.

Like FSA::Rules objects, FSA::State objects are empty hashes, so you can feel
free to stash data in them. But note that each state object is independent of
all others, so if you want to stash data for other states to access, you'll
likely have to stash it in the state machine object (in its hash
implementation or via the C<notes()> method), or retrieve other states from
the state machine using its C<states()> method and then access their hash data
directly.

=head2 Constructor

=head3 new

  my $state = FSA::State->new;

Constructs and returns a new FSA::State object. Not intended to be called
directly, but by FSA::Rules.

=cut

sub new {
    my $class = shift;
    return bless {@_} => $class;
}

##############################################################################

=head2 Instance Methods

=head3 name

  my $name = $state->name;

Returns the name of the state.

=cut

sub name { $states{shift()}->{name} }

##############################################################################

=head3 label

  my $label = $state->label;

Returns the label of the state.

=cut

sub label { $states{shift()}->{label} }

##############################################################################

=head3 machine

  my $machine = $state->machine;

Returns the FSA::Rules object for which the state was defined.

=cut

sub machine { $states{shift()}->{machine} }

##############################################################################

=head3 result

  my $fsa = FSA::Rules->new(
    # ...
    some_state => {
        do => sub {
            my $state = shift;
            # Do stuff...
            $state->result(1); # We're done!
        },
        rules => [
            bad  => sub { ! shift->result },
            good => sub {   shift->result },
        ]
    },
    # ...
  );

This is a useful method to store results on a per-state basis. Anything can be
stored in the result slot. Each time the state is entered, it gets a new
result slot. Call C<result()> without arguments in a scalar context to get the
current result; call it without arguments in an array context to get all of
the results for the state for each time it has been entered into, from first
to last. The contents of each result slot can also be viewed in a
C<stacktrace> or C<raw_stacktrace>.

=cut

sub result {
    my $self = shift;
    return $self->_state_slot('result') unless @_;
    # XXX Yow!
    $machines{$self->machine}->{stack}[$states{$self}->{index}[-1]][1]{result}
        = shift;
    return $self;
}

##############################################################################

=head3 message

  my $fsa = FSA::Rules->new(
    # ...
    some_state => {
        do => sub {
            my $state = shift;
            # Do stuff...
            $state->message('hello ', $ENV{USER});
        },
        rules => [
            bad  => sub { ! shift->message },
            good => sub {   shift->message },
        ]
    },
    # ...
  );

This is a useful method to store messages on a per-state basis. Anything can
be stored in the message slot. Each time the state is entered, it gets a new
message slot. Call C<message()> without arguments in a scalar context to get
the current message; call it without arguments in an array context to get all
of the messages for the state for each time it has been entered into, from
first to last. The contents of each message slot can also be viewed in a
C<stacktrace> or C<raw_stacktrace>.

=cut

sub message {
    my $self = shift;
    return $self->_state_slot('message') unless @_;
    # XXX Yow!
    $machines{$self->machine}->{stack}[$states{$self}->{index}[-1]][1]{message}
        = join '', @_;
    return $self;
}

##############################################################################

=head3 prev_state

  my $prev = $state->prev_state;

A shortcut for C<< $state->machine->prev_state >>.

=head3 done

  my $done = $state->done;
  $state->done($done);

A shortcut for C<< $state->machine->done >>. Note that, unlike C<message> and
C<result>, the C<done> attribute is stored machine-wide, rather than
state-wide. You'll generally call it on the state object when you want to tell
the machine that processing is complete.

=head3 notes

  my $notes = $state->notes;
  $state->notes($notes);

A shortcut for C<< $state->machine->notes >>. Note that, unlike C<message> and
C<result>, notes are stored machine-wide, rather than state-wide. It is
therefore probably the most convenient way to stash data for other states to
access.

=cut

sub prev_state { shift->machine->prev_state(@_) }
sub notes      { shift->machine->notes(@_) }
sub done       { shift->machine->done(@_) }

##############################################################################

=head3 enter

Executes all of the C<on_enter> actions. Called by FSA::Rules's
C<curr_state()> method, and not intended to be called directly.

=cut

sub enter {
    my $self = shift;
    my $state = $states{$self};
    $_->($self) for @{$state->{on_enter}};
    return $self;
}

##############################################################################

=head3 do

Executes all of the C<do> actions. Called by FSA::Rules's C<curr_state()>
method, and not intended to be called directly.

=cut

sub do {
    my $self = shift;
    my $state = $states{$self};
    $_->($self) for @{$state->{do}};
    return $self;
}

##############################################################################

=head3 exit

Executes all of the C<on_exit> actions. Called by FSA::Rules's C<curr_state()>
method, and not intended to be called directly.

=cut

sub exit {
    my $self = shift;
    my $state = $states{$self};
    $_->($self) for @{$state->{on_exit}};
    return $self;
}

##############################################################################

=head3 DESTROY

This method cleans up an FSA::State object's internal data when it is released
from memory. In general, you don't have to worry about the C<DESTROY()> method
unless you're subclassing FSA::State. In that case, if you implement your own
C<DESTROY()> method, just be sure to call C<SUPER::DESTROY()> to prevent
memory leaks.

=cut

sub DESTROY { delete $states{+shift}; }

##############################################################################

# Used by message() and result() to get messages and results from the stack.

sub _state_slot {
    my ($self, $slot) = @_;
    my $trace = $self->machine->raw_stacktrace;
    my $state = $states{$self};
    return wantarray
      ? map { $_->[1]{$slot} } @{$trace}[@{$state->{index}} ]
      : $trace->[$state->{index}[-1]][1]{$slot};
}

##############################################################################
# Called by FSA::Rules->try_switch to get a list of the rules. I wonder if
# rules should become objects one day?

sub _rules {
    my $self = shift;
    my $state = $states{$self};
    return @{$state->{rules}}
}

1;
__END__

=head1 To Do

=over

=item Factor FSA::Class into a separate file.

=item Switch to Data::Dump::Streamer for proper serialization of closures.

=back

=head1 Support

This module is stored in an open
L<GitHub repository|http://github.com/theory/fsa-rules/>. Feel free to fork
and contribute!

Please file bug reports via
L<GitHub Issues|http://github.com/theory/fsa-rules/issues/> or by sending mail
to L<bug-FSA-Rules@rt.cpan.org|mailto:bug-FSA-Rules@rt.cpan.org>.

=head1 Authors

=over

=item David E. Wheeler <david@justatheory.com>

=item Curtis "Ovid" Poe <eop_divo_sitruc@yahoo.com> (reverse the name to email him)

=back

=head1 Copyright and License

Copyright (c) 2004-2015 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
