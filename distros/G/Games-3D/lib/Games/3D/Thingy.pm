
# Thingy - a base class for virtual and physical 3D objects

package Games::3D::Thingy;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;
use vars qw/@ISA $VERSION $AUTOLOAD/;
@ISA = qw/Exporter/;

use Games::3D::Signal qw/
  STATE_OFF STATE_FLIP STATE_ON STATE_0
  SIG_FLIP SIG_ACTIVATE SIG_DEACTIVATE
  SIG_DIE SIG_NOW_0 SIG_KILLED
  state_from_signal
  signal_from_state signal_name
  /;

sub DEBUG () { 0; }

$VERSION = '0.04';

##############################################################################
# protected vars

# each Thingy will get a unique ID, however, upon adding it to the world/level
# it will get a new ID, local and unique to that world. We could do away with
# this function here...
  {
  my $id = 1;
  sub ID { return $id++;}
  }

##############################################################################
# methods

sub new
  {
  # create a new instance of a thingy
  my $class = shift;

  my $template;
  $template = shift if ref($_[0]) =~ /::Template/;

  my $self = { id => ID() };
  bless $self, $class;

  $self->{active} = 1;
  $self->{_world} = undef;		# not contained in anything yet
  
  $self->{outputs} = {};
  $self->{inputs} = {};
  
  $self->{name} = $class;
  $self->{name} =~ s/.*:://;
  $self->{name} = ucfirst($self->{name});
  $self->{name} .= ' #' . $self->{id};
  
  $self->{state} = 0;				# current state

  # time when state change has to end. endtime is starttime + time_for_change,
  # as defined in field 0 of 'states' below:
  $self->{state_endtime} = 0;			# disable change
  $self->{state_target} = 0;			# target state (from current)

  # example:
  $self->{state_0} = [
    1,						# ms to change to this state
# example:
#    'light_r' => 0,	  			# light off
#    'light_g' => 0,	  			# light off
#    'light_b' => 0,	  			# light off
#    'light_a' => 0,	  			# light off
    ];
  $self->{state_1} = [
    1,
# example:
#    'light_r' => 1.0,	  			# light on
#    'light_g' => 1.0,	  			# light on
#    'light_b' => 0,	  			# light on
#    'light_a' => 1.0,	  			# light on
   ];
  
  $self->{visible} = 0;			# invisible
  $self->{think_time} = 0;		# never think
  $self->{next_think} = 0;

  $template->init_thing($self) if $template;

  $self->_init(@_);
  }

sub kill
  {
  my ($self,$src) = @_;

  $self->event($src,'kill'); 

  # send SIG_KILLED to all our links to announce our death
  $self->output($self, SIG_KILLED);

  # remove all links from and to ourself 
  $self->unlink();

  # remove ourself from parent if necc.
  $self->{_world}->unregister($self) if $self->{_world};

  undef;
  }

sub event
  {
  # when an event (frob, use, kill etc) occurs, this routine handles it
  my ($self,$src,$event) = @_;

  &{$self->{"_event_$event"}}($self,$src) if $self->{"_event_$event"};
  }

sub AUTOLOAD
  {
  # when you do $self->name(), the AUTOLOAD steps in, checks that the
  # attribute "name" exists, and constructs a little accessor method for it.
  # This is then put into place and the next time round it will be called
  # directly.

  my $func = $AUTOLOAD;
  my $class = $func; 
  $func =~ s/.*:://;		# remove package
  $class =~ s/::[^:]+$//;	# keep package
  return if $func eq 'DESTROY';	# we have DESTROY, so not necc. here
 
#  print "autoload for $class $func\n";
  no strict 'refs';
#  if (!$self->attr_exists($func))
#    {
#    require Carp; Carp::croak ("Attribute '$func' does not exist in $class");
#    }
  *{$class."::$func"} =
  sub { 
    my $self = shift;
    if (@_ > 0)
      {
      # more than one argument, need to modify
      $self->{$func} = $_[0];
      }
    $self->{$func};
    };
  &$func;	# call constructed accessor method using @_
  }

sub id
  {
  my $self = shift;

  $self->{id};
  }

sub as_string
  {
  my $self = shift;

  my $txt = ref($self) . " {\n";
  foreach my $k (sort keys %$self)
    {
    next if $k =~ /^_/;                                 # skip internal keys
    my $v = $self->{$k};                                # get key
    next if !defined $v;                                # skip empty
    if (ref($v) eq 'HASH')
      {
      next if scalar keys %$v == 0;
      $v = "{\n";
      foreach my $key (sort keys %{$self->{$k}})
        {
        my $vi = $self->{$k}->{$key};
        $vi = $vi->as_string() if ref($v);
        $v .= "    $key = $vi\n";
        }
      $v .= "  }";
      }
    elsif (ref($v) eq 'ARRAY')
      {
      next if scalar @$v == 0;
      $v = "[ ";
      foreach my $vi (@{$self->{$k}})
        {
        $vi = $vi->as_string() if ref($v);
        $v .= "$vi, ";
        }
      $v =~ /,\s$/;					# remove last ,
      $v .= "]";
      }
    else
      {
      $v = '"'.$v.'"' if $v =~ /[^a-z0-9_\.,='"+-]/;
      next if $v eq '';
      }
    $txt .= "  $k = $v\n";
    }
  $txt .= "}\n";
  }

sub new_flag
  {
  my ($self,$name,$value) = @_;

  $name =~ s/^-//;		# -name => name

  # set the initial value
  $self->{$name} = $value ? 1 : 0;

  my $class = ref($self);
  return if defined *{$class."::is_$name"};

  # create an accessor method
  no strict 'refs';
  *{$class."::is_$name"} =
  sub {
    my $self = shift;
    if (@_ > 0)
      {
      # more than one argument, need to modify
      $self->{$name} = $_[0] ? 1 : 0;
      }
    $self->{$name};
    };
  }

BEGIN { no warnings 'redefine'; }

sub _init
  {
  my $self = shift;
  $self;
  }

sub container
  {
  # return the container this thing is inside or undef for none
  my $self = shift;

  $self->{parent};
  }

sub insert
  {
  # insert thingy into a container
  my $self = shift;
  my $thingy = shift;

  $self->{contains}->{$thingy->{id}} = $thingy;
  $self->_update_space();
  $self;
  }

sub _update_space
  {
  }

sub remove
  {
  # remove thing from ourself
  my $self = shift;
  my $thing = shift;

  if (ref $thing)
    {
    my $c = $self->{contains};
    if (exists $c->{$thing->{id}})
      {
      delete $c->{$thing->{id}};
      $self->_update_space();	
      }
    }
  else
    {
    # try to remove us from our container
    $self->{parent}->remove($self) if (defined $self->{parent});
    }
  }

sub name
  {
  # (set and) return the name of this thingy
  my $self = shift;
  if (defined $_[0])
    {
    $self->{name} = shift;
    }
  $self->{name};
  }

sub activate
  {
  my ($self) = shift;

  $self->{active} = 1;
  1;
  }

sub deactivate
  {
  my ($self) = shift;

  $self->{active} = 0;
  0;
  }

sub is_active
  {
  my ($self) = shift;

  $self->{active};
  }

sub state
  {
  my $self = shift;

  # if given a state change and we are active
  if (defined $_[0] && $self->{active} == 1)
    {
    my $old_state = $self->{state};

    # initiate state change:
    my $newstate;
 
    if ($_[0] == STATE_FLIP)
      {
      if ($self->{state} <= STATE_ON)
	{
        $newstate = STATE_ON - $self->{state};
        }
      else
        {
        # XXX TODO: on thingy with more than 2 states, flip is undefined
        $newstate = STATE_0;
        }
      }
    else
      {
      $newstate = $_[0];
      }

    if ($self->{state} != $newstate)
      {
      print '# ', $self->name(), 
	" changes state from $self->{state} to $newstate\n" if DEBUG;

      # set the endtime for when the state change should be complete
      my $now = 0;
      $now = $self->{_world}->time() if $self->{_world}; 
      $self->{state_endtime} = $now +
       ($self->{"state_$newstate"}->[0] || 1);	# avoid state changes
							# that take no time
      $self->{state_target} = $newstate;
      # notifing our listeners will be done when the state change is complete
      }
    } 
  $self->{state};
  }

sub signal
  {
  # receive signal $sig from input $input, where $input is the sender's ID (not
  # the link(s) relaying the signal). We ignore here the input. Links relay
  # their input to their outputs (maybe, delayed , inverted etc), while other
  # objects receive input, change state (or not) and then maybe output
  # something.
  my ($self,$input,$sig) = @_;

  my $id = $input; $id = $input->{id} if ref($id);
  print "# ",$self->name()," received signal ",signal_name($sig),
   " from $id\n" if DEBUG;

  # if asked to die, do so now
  if ($sig == SIG_DIE)
    { 
    $self->kill();
    return;
    }
  # if asked to deactivate, do so now
  if ($sig == SIG_ACTIVATE)
    { 
    $self->{active} = 1;
    return;
    }
  if ($sig == SIG_DEACTIVATE)
    { 
    $self->{active} = 0;
    return;
    }
  # set ourself to the new state, unless SIG_NOW_x (these are ignored)
  $self->state(state_from_signal($sig)) if $sig <= SIG_NOW_0;
  # relay incoming signals to outputs if neccessary
  $self->output($input,$sig);
  }

sub inputs
  {
  my ($self) = @_;
  
  keys %{$self->{inputs}};
  }

sub outputs
  {
  my ($self) = @_;
  
  keys %{$self->{outputs}};
  }

sub add_input
  {
  my ($self,$src) = @_;
  
  $self->{inputs}->{$src->{id}} = $src;
  }

sub add_output
  {
  my ($self,$dst) = @_;

  $self->{outputs}->{$dst->{id}} = $dst;
  }

sub del_input
  {
  my ($self,$src) = @_;
  
  delete $self->{inputs}->{$src->{id}};
  }

sub del_output
  {
  my ($self,$dst) = @_;

  delete $self->{outputs}->{$dst->{id}};
  }

sub unlink
  {
  # unlink all inputs and outputs from ourself
  my $self = shift;

  foreach my $out (keys %{$self->{outputs}})
    {
    $self->{outputs}->{$out}->del_input($self)
     if ref($self->{outputs}->{$out});
    }
  foreach my $in (keys %{$self->{inputs}})
    {
    $self->{inputs}->{$in}->del_output($self)
     if ref($self->{inputs}->{$in});
    }
  $self->{inputs} = {};
  $self->{outputs} = {};
  $self;
  }

sub output
  {
  # send a signal to all the outputs
  my ($self,$source,$sig) = @_;

  $source = $source->{id} if ref($source);
  my $out = $self->{outputs};
  foreach my $id (keys %{$self->{outputs}})
    {
    $out->{$id}->signal($source,$sig);			# sender id, signal	
    }
  }

sub link
  {
  # link us to another one by creating intermidiate link object and return
  # link object
  my ($self,$dst,$link) = @_;

  $self->{outputs}->{$link->{id}} = $link;
  $link->add_output($dst);			# from link to $dst
  $dst->add_input($link);
  $link->add_input($self);			# from us to link
  $link;
  }

sub update
  {
  # if thing is going from state A to state B, interpolate values based upon
  # current time tick. If reached state B, disable interpolation, and send a 
  # signal. Return 1 if while still in transit, 0 if target state reached

  my ($self, $tick) = @_;

  # if the thingy is in between two state changes, interpolate between them
  return if $self->{state_endtime} == 0;	# no change neccessary
  
  # for all fields in the target state, interpolate them
  my $s = "state_$self->{state_target}";
  if (!exists $self->{$s})
    {
    $self->{$s} = [1];
    }
  my @states = @{$self->{$s}};

  if ($tick >= $self->{state_endtime})		# overdue
    {
    # simple set the fields, and disable the state change
    print "# update($tick) caused change ",$self->name(),
     " $self->{state} => $self->{state_target}\n" if DEBUG;

    $self->{state_endtime} = 0;			# no further change
    $self->{state} = $self->{state_target};	# reached target state
    # send signal that state change is complete
    print "# Sending signal ", signal_name(signal_from_state($self->{state})),
     "\n" if DEBUG;
    $self->output($self, signal_from_state($self->{state}));

    while (@states > 0)
      {
      # set a => 1 (f.i.)
      $self->{$states[0]} = $states[1];
      splice @states,0,2;			# throw away first two entries
      }
    return 0;					# no more changes
    }
  
  my $time = shift @states;			# field 0 is the time it takes
 
  # get the values from the current state 
  my @cur_states = @{$self->{"states_$self->{state}"}};
  shift @cur_states;				# dont need field 0

  # factor: endtime - time = starttime		# 200 - 100 = 100
  #         tick - starttime = elapsedtime	# 180 - 100 = 80
  #         time / elapsedtime = factor		# 100 / 80 = 0.8 (80%)

  my $factor = $time / ($tick - ($self->{state_endtime} - $time));

  # interpolate linaer to the target values  
  while (@states > 0)
    {
    # 20 .. 80 => 60 * 0.8 (factor, 80%) = 48 + 20 => 68 as current value
    $self->{$states[0]} =
     ($states[1] - $cur_states[1]) * $factor + $cur_states[1];

    splice @states,0,2;				# throw away first two entries
    splice @cur_states,0,2;			# throw away first two entries
    }
  1;						# more changes to do
  }

##############################################################################
# field access

sub is
  {
  my ($self,$flag) = @_;

  if (!exists $self->{$flag})
    {
    require Carp;
    Carp::croak ("Flag '$flag' does not exist at $self");
    }
  $self->{$flag};
  }

sub make
  {
  my ($self,$flag) = @_;

  if (!exists $self->{$flag})
    {
    require Carp;
    Carp::croak ("Flag '$flag' does not exist at $self");
    }
  $self->{$flag} = 1;
  }

sub get
  {
  my ($self,$field) = @_;

  if (!exists $self->{$field})
    {
    require Carp;
    Carp::croak ("Field '$field' does not exist at " . $self->name());
    }
  $self->{$field};
  }

1;

__END__

=pod

=head1 NAME

Games::3D::Thingy - base class for virtual and physical 3D objects

=head1 SYNOPSIS

	package Games::3D::MyThingy;

	use Games::3D::Thingy;
	require Exporter;

	@ISA = qw/Games::3D::Thingy/;

	sub _init
	  {
	  my ($self) = shift;

	  # init with arguments from @_
	  }

	# override or add any method you need

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a base class for "things" in Games::3D. It should
not be used on it's own.

=head1 METHODS

These methods need not to be overwritten:

=over 2

=item new()

	my $thingy = Games::3D::Thingy->new(@options);
	my $thingy = Games::3D::Thingy->new( $options ); # hash ref w/ options

Creates a new thing.

=item container()

	print $thing->container();

Return the container this thing is contained in or undef for none.

=item insert()

	$thing->insert($other_thing);

Insert the other thing into thing, if possible. Returns undef for not
possible (thing does not fit, container full etc), or C<$thing>.

=item remove()

	$container = $thing->inside();			   # get container
	$container->remove($thing) if defined $container;  # remove now

	# or easier:
	$thing->remove();		# if inside container, remove me	

Removes the thing from it's container.

See also L<insert()>.

=item is_active()

	$thingy->is_active();

Returns true if the thingy is active, or false for inactive.

=item activate()

	$thingy->activate();

Set the thingy to active. Newly created ones are always active.

=item deactivate()
	
	$thingy->deactivate();

Set the thingy to inactive. Newly created ones are always active.

Inactive thingies ignore signals or state changes until they become active
again.

=item id()

Return the thingy's unique id.

=item name()

	print $thingy->name();
	$thingy->name('new name');

Set and/or return the thingy's name. The default name is the last part of
the classname, uppercased, preceded by '#' and the thingy's unique id.

=item is()

	$thingy->is('dead');

Returns the flag as 1 or 0. The argument is the flag name.

=item make()

	$thingy->make($flag);
	$thingy->make('dead');

Sets the flag named $flag to 1.

=item is_$name()

	print "dead!" if $thingy->is_dead();
	$thingy->is_dead(0);			# let it live again

Sets the flag named $name to 1 or 0, if no argument is given, returns simple
the state of the flag. Of course, the flag has to exist.

=item state

	print "ON " if $thingy->state() == STATE_ON;
	$thingy->state(STATE_OFF);
	$thingy->state(STATE_FLIP);

Returns the state of the thing. An optional argument changes the object's
state to the given one, and sends the newly set state to all outputs (see
L<add_output()>.

=item signal()

        $link->signal($input_id,$signal);
        $link->signal($self,$signal);

Put the signal into the link's input. The input can either be an ID, or just
the object sending the signal. The object needs to be linked to the input
of the link first, by using L<link()>, or L<add_input()>.

=item add_input()

        $thingy->add_input($object);

Registers C<$object> as a valid input source for this object. Does nothing
for Thingies and their subclasses, they simple receive and handle signals from
everyone. Important for Games::3D::Link, though.

Do not forget to also register the link C<$link> as output for C<$object> via
C<$object->add_output($link);>. It is easier and safer to just use
link() from Games::3D::Link, though.

=item add_output()

        $thingy->add_output($destination);

Registers C<$object> as an output of this object, e.g. each signal the object
generateds will also be sent to the destinationt.

If the target of the output is not a Thingy or a subclass, but a
Games::3D::Link object, do not forget to also register the
object C<$thingy> as input for C<$destination> via
C<$destination->add_input($object);>.

In short: If you want to simple link two objects, just register the second
object as output on the first. If you want to link two objects (ore even more)
in more complex ways, use L<link()>.

=item link()

	$link = $object->link($different_object);

Links the object to a different object by creating an intermediate link
object. Returns the reference to that link object.

It is possible to link the object to itself, however, this makes only sense
when using delayed, inverted, or otherwise limited (like one-shot) links.
Otherwise you create a signal endless-loop, which will take an eternity or
two to resolve.

Here is an example, that turns the object automatically off two seconds after
it was turned on:
	
	$link = $object->link($object);
	$link->delay(2000);
	$link->fixed_output(SIGNAL_OFF);
	$link->fixed_input(SIGNAL_ON);

Note that without that last line, turning C<$object> would cause another 
off signal to be send after two more seconds, which is not neccessary. Here
is an example of an object that flips it self on and off in randomized 2
second intervalls:

	$link = $object->link($object);
	$link->delay(2000,500);
	$link->fixed_output(SIGNAL_FLIP);

Note that each flip signal will start the next flip signal.

=item output()

  	$thingy->output($source,$signal);

Sends the signal C<$signal> to all the outputs that were registered with that
thingy and tells the receiver that the signal came from C<$source>. Example
to send one signal from the thingy itself (instead of relaying it):

	$thingy->output($thingy->{id}, SIGNAL_ON);

=item del_output()

	$thingy->del_output( $listener );

Call to remove C<$listener> from the list of outputs from C<$thingy>. 

=item del_input()

	$thingy->del_input( $listener );

Call to remove C<$listener> from the list of inputs from C<$thingy>. 

=item as_string()

	$thingy->as_string();

Return this thingy as string.

=item event()

	$thingy->event($src,$event);

When an event (frob, use, kill etc) occurs, this routine handles it.

=item get()

=item inputs()

=item kill()

	$thingy->kill();

Sends the thingy itself a KILL signal, then annnounced to all linked
things the death of the thingy. Unlinks all inputs and outputs,
and then removes the thingy from the world it resided in.

=item new_flag()

	$thingy->new_flag($name,$value);

Creates a new flag with the given name and value and creates an
accesssor for it.

=item outputs()

	my @outputs = $thingy->outputs();

Returns a list of all connected outputs of this thingy.

=item unlink()

	$thingy->unlink();

Unlink all inputs and outputs from ourself.

=item update()

	$thingy->update($tick);

If this thingy is going from state A to state B, interpolate values based upon
current time tick. If reached state B, disable interpolation, and send a 
signal. Returns 1 while still in transit, 0 when the target state is/was
reached.

=back

=head1 AUTHORS

(c) 2002 - 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<Games::Irrlicht>.

=cut

