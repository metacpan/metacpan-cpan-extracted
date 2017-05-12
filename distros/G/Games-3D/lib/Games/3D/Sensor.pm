
# Sensor - monitor conditions and trigger when they are met

package Games::3D::Sensor;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use Games::3D::Signal qw/
  SIG_FLIP SIG_OFF SIG_DIE
  SIG_ACTIVATE SIG_DEACTIVATE
  /;
use Games::3D::Link;
use vars qw/@ISA @EXPORT_OK $VERSION/;
@ISA = qw/Exporter Games::3D::Link/;

$VERSION = '0.01';

sub COND_MET() { 1; }
sub COND_NOT_MET() { 2; }
sub COND_UNCOND() { 3; }

sub SENSOR_BELOW() { 0; }
sub SENSOR_OVER() { 1; }
sub SENSOR_BETWEEN() { 2; }
sub SENSOR_DIED() { 3; }
sub SENSOR_ACTIVE() { 4; }
sub SENSOR_INACTIVE() { 5; }

# periodic re-check required
sub SENSOR_PERIODIC() { 1000; }		# dont use this type, only for comp.

sub SENSOR_VISIBLE() { 1001; }
sub SENSOR_DISTANCE() { 1002; }

@EXPORT_OK = qw/
   COND_MET COND_NOT_MET COND_UNCOND
   SENSOR_BELOW
   SENSOR_BETWEEN
   SENSOR_OVER
   SENSOR_DIED
   SENSOR_ACTIVE
   SENSOR_INACTIVE
   SENSOR_VISIBLE
   SENSOR_DISTANCE
  /;

##############################################################################
# methods

sub _init
  {
  my $self = shift;
  my $args = $_[0];

  $args = { @_ } if ref($_[0]) ne 'HASH';

  my $obj = $args->{obj};
  my $id = $obj->{id};
  $self->{watch} = { 
	$id => [ $obj, $args->{what} ], # object(s) to watch for
	};  					

  $self->{A} = $args->{A} || 0;			# range A..B
  $self->{B} = $args->{B} || $args->{A} || 0;	# range A..B
  warn ("A=$self->{A} > B=$self->{B}\n") if
    $self->{A} > $self->{B};
  $self->{type} = $args->{type} || SENSOR_BELOW;# signal must be below A

  $self->{periodic} = 0;			# check only on change
  $self->{periodic} = 1 
   if $self->{type} > SENSOR_PERIODIC;		# check periodically
  
  $self->{delay} = $args->{delay} || 0;		# immidiately
  $self->{repeat} = $args->{repeat} || 2000;	# 2 seconds if count != 1
  $self->{rand} = $args->{rand} || 0;		# exactly
  $self->{count} = $args->{count} || 1;		# one signal
  $self->{when} = $args->{when} || COND_UNCOND;	# in and outside of range
  $self->{fixed_output} = $args->{fixed_output};# ON and OFF are default

  $self;
  }

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

  # ignore all other signals
  return;				# don't relay this signal
  }

BEGIN
  {
  # inherit these from Thingy instead from Link:
  *link = \&Games::3D::Thingy::link;
  *unlink = \&Games::3D::Thingy::unlink;
  *add_input = \&Games::3D::Thingy::add_input;
  }

sub and_gate
  {
  my $self = shift;

  warn ("Sensors cannot act as AND gates.\n");  
  }

sub watch
  {
  # bind an additional target to the sensor
  my ($self,$dst,$what) = @_;

  my $id = $dst->{id};
  $self->{watch} = { 
	$id => [ $dst, $what ], 	# object(s) to watch for
	};
  $self;
  }

sub when
  {
  my ($self) = shift;

  $self->{when} = shift if @_ > 0;
  $self->{when};
  }

sub type
  {
  my ($self) = shift;

  $self->{type} = shift if @_ > 0;
  $self->{type};
  }

1;

__END__

=pod

=head1 NAME

Games::3D::Sensor - monitor conditions and trigger when they are met

=head1 SYNOPSIS

	use Games::3D::Thingy;
	use Games::3D::Sensor;
	use Games::3D::Link;

	my $src = Games::3D::Thingy->new();
	my $dst = Games::3D::Thingy->new();

	# Send a signal SIG_ON (only once)
	# if the health drops below 15
	# Send a SIG_OFF (only once) if it goes outside that
	# range (e.g. >= 15).
	my $sensor = Games::3D::Sensor->new(
		obj => $src, what => 'health',
		type => SENSOR_BELOW,
		A => 15,
		when => COND_UNCOND,	# default
	);
	# the sensor watches the source object, but it does not yet
	# send it's signal to anywhere, so link it to $dst:
	my $link = Games::3D::Link->new();
	$link->link ($sensor, $dst);

	# Send a signal SIG_ON (every 100 ms) if health is between
	# 15 and 45. Don't send any signal if outside that range
	my $sensor_2 = Games::3D::Sensor->new(
		obj => $src, what => 'health',
		type => SENSOR_BETWEEN,
		A => 15,
		B => 45,
		repeat => 100,
		count => 0,		# infinitely
		when => COND_MET,
	);
	# the sensor watches the source object, but it does not yet
	# send it's signal to anywhere, so link it to $dst without an
	# intermidiate link object:
	$sensor_2->add_output($dst);

	# Send SIG_FLIP everytime the condition changes
	# This could be used to change the color of the health
	# bar from green to red everytime the health goes below
	# 10, and back to red if it goes over 10.
	my $sensor_3 = Games::3D::Sensor->new(
		obj => $src, what => 'health',
		type => SENSOR_BELOW,
		A => 10,
		fixed_output => SIG_FLIP,
	);
	# Send SIG_ON three times as long as the condition is not met
	my $sensor_4 = Games::3D::Sensor->new(
		obj => $src, what => 'health',
		type => SENSOR_RANGE,
		A => 10,
		B => 45,
		repeat => 250,
		count => 3,		# 3 times
		when => COND_NOT_MET,
		fixed_output => SIG_ON,
	);

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

Watches over conditions and triggers if they are met.

=head1 METHODS

=over 2

=item new()

	my $sensor = Games::3D::Sensor->new( @options );

Creates a new sensor.

=item is_active()

	$sensor->is_active();

Returns true if the sensor is active, or false for inactive. Inactive sensors
will not send any signals until they become active again.

=item activate()

	$sensor->activate();

Set the sensor to the active state. Newly created sensors are always active.

=item deactivate()
	
	$sensor->deactivate();

Set the sensor to inactive. Newly created ones are always active. Inactive sensors
will not send any signals.

=item id()

Return the sensors' unique id.

=item name()

	print $sensor->name();
	$sensor->name('new name');

Set and/or return the sensors' name. The default name is the last part of
the classname, uppercased, preceded by '#' and the obejcts' unique id.

=item add_output()

	$sensor->add_output($object);

Registers C<$object> as an output of this sensor, e.g. each signal the sensor
generates will also be sent to this object. See also L<link()>.

Do not forget to also register the sensor C<$link> as input for C<$object> via
C<< $object->add_input($sensor); >>. It is easier and safer to just use
C>< $sensor->link($sensor,$dst); >>, though.

=item link()

	$sensor->link($sensor,$dest);

Is a combination of L<add_input()> and L<add_output()>, e.g links the
sensor to the destination object, too. 

=item met_count()

	$sensor->met_count(2);

Sets the count of how many times the signal is sent out. Default is
1. This acts basically as a multiplier, setting it to 2 will for instance
send each signal two times out, with a delay in between. The
delay can be set with L<met_delay()>. Setting it to 0 will send the signal
infinitely often, as long as the condition is met.

Returns the count.

=item unmet_count()

	$sensor->unmet_count(2);

Sets the count of how many times the signal is sent out. Default is
1. This acts basically as a multiplier, setting it to 2 will for instance
send each signal two times out, with a delay in between. The
delay can be set with L<met_delay()>. Setting it to 0 will send the signal
infinitely often, as long as the condition is met.

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

Sets the one-time flag of the sensor. If set to a true value (the default),
then the sensor
link will
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

	if (defined $sensor->fixed_output()) { ... }
	$sensor->fixed_output(undef);			# disable
	$sensor->fixed_output(SIG_FLIP);		# always send FLIP

Get/set the fixed output signal. If set to undef (default), then the two
signals SIG_ON and SIG_OFF will be generated when the condition is
met (or not, respectively). 

Setting C<< $sensor->fixed_output(SIG_FLIP); >> would allow you to
build a sensor that always sends a flip signal as the condition changes
from met to unmet and back.

=item and_gate()

Sensors cannot act as an AND gate, so this routine should not be called.

=item type()

	$sensor->type();

Set/get the type of the sensor.

=item when()

	$sensor->when();

Set/get the when-field of the sensor.

=item watch()

	$sensor->watch( $destination, $what );

Bind an additional target to the sensor.

=item signal()

	$sensor->signal( $input, $signal );
	$sensor->signal( $link, SIG_ON );

C<$input> sends the signal C<$signal> to this sensor.

=back

=head1 AUTHORS

(c) 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D::Thingy>, L<Games::3D::Link>, L<Games::Irrlicht>.

=cut

