
# Link - link two objects together and allow sending signal(s) between them

package Games::3D::Link;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;
use Games::3D::Signal qw/
  SIG_FLIP SIG_OFF SIG_DIE
  SIG_ACTIVATE SIG_DEACTIVATE
  signal_name
  /;
use Games::3D::Thingy;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter Games::3D::Thingy/;

$VERSION = '0.03';

sub DEBUG () { 0; }

##############################################################################
# protected class vars

{
  sub add_timer { die ("You need to set a timer callback first.") };
  my $timer = 'Games::3D::Link';	# make it point to our add_timer()
  sub timer_provider
    {
    $timer = shift if @_ > 0;
    $timer;
    }
}

##############################################################################
# methods

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{input_states} = {};  			# for AND gates
  $self->{inputs} = {};  
  $self->{outputs} = {};

  $self->{count} = 1;				# send signal only once  
  $self->{delay} = 0;				# immidiately
  $self->{repeat} = 2000;			# 2 seconds if count != 1
  $self->{rand} = 0;				# exactly
  $self->{once} = 0;				# not once
  $self->{fixed_output} = undef;		# none (just releay)
  $self->{invert} = 0;				# not
  $self->{and} = 0;				# act as OR gate
  $self;
  }

# override signal() to be more complex than Thingy's default

sub signal
  {
  my ($self,$input,$sig) = @_;

#  my $id = $input; $id = $input->{id} if ref($id);
#  print "# ",$self->name()," received signal $sig from $id\n";

  die ("Unregistered input $input tried to send signal to link $self->{id}")
   if !exists $self->{inputs}->{$input};

  # if the signal is DIE, DESTROY yourself
  if ($sig == SIG_DIE)
    {
    $self->kill();
    return;
    }
  # if the signal is ACTIVATE or DEACTIVATE, (in)activate yourself
  if ($sig == SIG_ACTIVATE)
    {
    $self->activate();
    return;				# don't relay this signal
    }
  elsif ($sig == SIG_DEACTIVATE)
    {
    $self->deactivate();
    return;				# don't relay this signal
    }

  # AND gate: all inputs must be in the same state to send the signal
  if ($self->{and} && scalar keys %{$self->{inputs}} > 1)
    {
    # store the signal at the input (for AND gate)
    $self->{input_states}->{$input} = $sig;
    # and check the others
    my $in = $self->{input_states};
    foreach my $i (keys %$in)
      {
      # if not all match yet, don't send signal
      return if ($in->{$i} != $sig);
      }
    }
  return unless $self->{active} == 1;	# inactive links don't send signals

  # if we need to always send the same signal, do so
  if (defined $self->{fixed_output})
    {
    $sig = $self->{fixed_output};
    }
  # otherwise we might need to invert the signal to be sent
  elsif ($self->{invert})
    {
    $sig = Games::3D::Signal::invert($sig);			# invert()
    }
  
  # need to delay sending, or send more than one time
  if ($self->{count} != 1 || $self->{delay} != 0)
    {
    timer()->add_timer(
      $self->{delay}, $self->{count}, $self->{repeat}, $self->{rand},
      sub 
        {
        $self->output($input,$sig);
        },
     );
    }
  else
    {
    print '# ',$self->name()," relays ",signal_name($sig),
     " from $input to outputs.\n" if DEBUG;
    # Send signal straight away. 
    $self->output($input,$sig);		# send $sig to all outputs
    }
  $self->deactivate() if $self->{once};
  }

sub link
  {
  my ($self,$src,$dst) = @_;

  $self->{inputs}->{$src->{id}} = $src;
  if ($self->{and} && scalar keys %{$self->{inputs}} > 1)
    {
    $self->{input_states}->{$src->{id}} = SIG_OFF;
    }
  $self->{outputs}->{$dst->{id}} = $dst;
  $src->add_output($self);			# the link appears as output
  $dst->add_input($self);			# and input at both ends
  }

sub unlink
  {
  # unlink all inputs and outputs from ourself
  my $self = shift;

  $self->SUPER::unlink();

  $self->{input_states} = {};
  $self;
  }

# override input() to also add the input state
sub add_input
  {
  my ($self,$src) = @_;

  $self->{inputs}->{$src->{id}} = $src;
  if ($self->{and} && scalar keys %{$self->{inputs}} > 1)
    {
    $self->{input_states}->{$src->{id}} = SIG_OFF;
    }
  $self;
  }

sub delay
  {
  # Sets the initial delay of the link, the delay for each consecutive signal,
  # and the randomized offset for these times.
  # Note that the second delay only comes into play if the
  # count() was set to a value different than 1, otherwise each firing of the
  # link will use the first delay again.
  my ($self,$delay,$rand,$repeat) = @_;

  $self->{delay} = abs($delay) if defined $delay;
  $self->{repeat} = abs($repeat) if defined $repeat;
  $self->{rand} = abs($rand) if defined $rand;
  ($self->{delay},$self->{repeat},$self->{rand});
  }

sub count
  {
  # Sets the count. If != 1, the outgoing signal will be resent coun() times,
  # each time delayed by a bit specified with delay(). A count of -1 means
  # infinitely.

  my $self = shift;

  if (defined $_[0])
    {
    $self->{count} = shift;
    }
  $self->{count};
  }
  
sub once
  {
  my $self = shift;

  $self->{once} = ($_[0] ? 1 : 0) if @_ > 0;
  $self->{once};
  }

sub invert
  {
  my $self = shift;

  $self->{invert} = $_[0] ? 1 : 0 if @_ > 0;
  $self->{invert};
  }

sub fixed_output
  {
  my $self = shift;

  $self->{fixed_output} = shift if @_ > 0;
  $self->{fixed_output};
  }

sub and_gate
  {
  my $self = shift;
  
  if (@_ > 0)
    {
    $self->{and} = $_[0] ? 1 : 0; 
    }
  $self->{and};
  }

1;

__END__

=pod

=head1 NAME

Games::3D::Link - link two or more objects together by a signal-relay chain

=head1 SYNOPSIS

	use Games::3D::Thingy;
	use Games::3D::Link;

	# send signal straight through
	my $link = Games::3D::Link->new();

	my $src = Games::3D::Thingy->new();
	my $dst = Games::3D::Thingy->new();

	$src->link ($dst, $link);

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

Represents a link between two objects and allows relaying a signal between
them.

A link has one (or more) inputs, and one (or more) outputs. Signals are send
to the inputs via calling a subroutine (any of on(), off(), flip(), or
signal()), and the signal will effect the state of the input. Each input will
remember it's state and is per default in the off state.

Each link is by default an OR gate e.g. each incoming signal is relayed
instantly to each output. 

You can use C<< $link->and_gate(1) >> to switch the link to the AND gate
type.

In this state only when all the inputs are in the the same state, the
specified signal (default is the state the inputs are in) is sent to all the
outputs.

This means a link acts like an AND gate, only if all the inputs are in the
same state, it triggers. 

=head1 METHODS

=over 2

=item timer_provider

	Games::3D::Link::timer_provider( $class );

You need to call this before any link with delay will work. Pass as argument
a classname or an object reference. This works best when you pass an
Games::Irrlicht object :)
	
	my $app = Games::Irrlicht->new();
	Games::3D::Link::timer_provider( $app );

=item new()

	my $link = Games::3D::Link->new( @options );

Creates a new link.

=item is_active()

	$link->is_active();

Returns true if the link is active, or false for inactive. Inactive links will
not relay signals, but will still maintain their inputs.

=item activate()

	$link->activate();

Set the link to the active state. Newly created links are always active.

=item deactivate()
	
	$link->deactivate();

Set the link to inactive. Newly created ones are always active. Inactive links
will not relay signals until they are activated again, but they will maintain
their input states properly while inactive.

=item id()

Return the link's unique id.

=item name()

	print $link->name();
	$link->name('new name');

Set and/or return the link's name. The default name is the last part of
the classname, uppercased, preceded by '#' and the link's unique id.

=item signal()

	$link->signal($input_id,$signal);
	$link->signal($self,$signal);

Put the signal into the link's input. The input can either be an ID, or just
the object sending the signal. The object needs to be linked to the input
of the link first, by using L<link()>, or L<add_input()>.

=item add_input()

	$link->add_input($object);

Registers C<$object> as a valid input source for this link. See also L<link()>.

Do not forget to also register the link C<$link> as output for C<$object> via
C<$object->add_output($link);>. It is easier and safer to just use
C<$link->link($src,$dst);>, though.

=item add_output()

	$link->add_output($object);

Registers C<$object> as an output of this link, e.g. each signal the link
relays will also be sent to this object. See also L<link()>.

Do not forget to also register the link C<$link> as input for C<$object> via
C<$object->add_input($link);>. It is easier and safer to just use
C<$link->link($src,$dst);>, though.

=item link()

	$link->link($src,$dest);

Is a combination of L<add_input()> and L<add_output()>, e.g links the
source object via this link to the destination object. If the link was
connecting other objects beforehand, these connections will also remain.

=item count()

	$link->count(2);

Sets the count of how many times the incoming signal is sent out. Default is
1. This acts basically as a multiplier, setting it to 2 will for instance
send each incoming signal two times out, with a delay in between. The
delay can be set with L<delay()>.

Returns the count.

=item delay()

	$link->delay(2000);		# 2 seconds
	$link->delay(1000,500);		# 1 second, and then 1/2 second
	$link->delay(1000,500,200);	# 1s, 1/2s, and both of them with
					# randomized by +/- 200 ms

Sets the delay between the receiving of the signal and it's relaying. The
default for this is 0. Also sets the delay between each consecutive relay
if count() is different than 1. The third parameter is an optional
random offset applied to both delays.

Returns a list of (first_delay, resend_delay, random_offset).

=item once()

	if ($link->once()) { ... }		# return true if one-time link
	$link->once(1);				# enable one-time sending
	$link->once(0);				# disable

Sets the one-time flag of the link. If set to a true value, the link will
only re-act to the first signal, and then deactivate itself.

If the link is set to send for each incoming signal more than one signal (via
C<delay()>), they still will all be sent. Also, each of the outputs of the link
will receive the signal. The once flag is only for the incoming signals, not
how many go out.

You can enable the link again (with L<activate()>, and it will once more work
on one incoming signal.

Default is off, e.g. the link will work on infinitely many incoming signals.

Returns the once flag.

=item fixed_output()

	if (defined $link->fixed_output()) { ... }
	$link->fixed_output(undef);			# disable
	$link->fixed_output(SIG_ON);			# always send ON

Get/set the fixed output signal. If set to undef (default), then the input
signal will be relayed through (unless L<invert()> was set, which would
invert the input before sending it out), if set to a specific value, this
set signal will always be sent, regardless of the input signal or the invert()
flag.

=item and_gate()

	$link->and_gate(1) unless $link->and_gate();

Set/get the flag indicating this link is an AND gate.

=item invert()

	$link->invert(1) unless $link->invert();

Set/get the flag indicating this link is inverted.

=item unlink()

	$link->unlink();

Unlink all inputs and outputs from the link.

=item add_timer()

	$link->add_timer();

Add a timer to this link. See L<timer_provider>.

=back

=head1 AUTHORS

(c) 2003, 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D::Thingy>, L<Games::Irrlicht>

=cut

