
# World - contains everything in the game world

package Games::3D::World;

# (C) by Tels <http://bloodgate.com/>

use strict;
use vars qw/$VERSION/;
use Games::3D::Template;

$VERSION = '0.07';

##############################################################################
# protected vars

  {
  my $id = 1;
  sub ID { return $id++;}
  sub _reset_ID { $id = 1; }
  }

##############################################################################
# methods

sub new
  {
  # create a new world
  my $class = shift;
 
  my $self = bless {}, $class;

  $self->{things} = { };
  $self->{render} = { };
  $self->{thinks} = { };
  $self->{templates} = {};
  _reset_ID();

  if (@_ == 2)
    {
    $self->load_templates($_[0]);
    $self->load_from_file($_[1]);
    }

  $self->{time} = 0;

  $self;
  }

sub load_from_file
  {
  my ($self,$file) = @_;

  $self->{file} = $file; 
  $self->{things} = { };
  _reset_ID();

  $self;
  }

sub load_templates
  {
  my ($self,$file) = @_;

  if (!ref($file))
    {
    # got filename, so read in data
    open FILE, "$file" or die ("Cant read $file: $!");
    local $/ = undef;				# slurp mode
    my $doc = <FILE>;
    $file = \$doc;
    close FILE; 
    }

  $self->{templates} = {};
  my @objects = Games::3D::Template::from_string($$file);

  if (@objects == 1 && !ref($objects[0]))
    {
    die($objects[0]);
    }
  foreach my $o (@objects)
    {
    if (exists $self->{templates}->{$o->{class}})
      {
      warn ("Template for class $o->{class} already seen");
      }
    $self->{templates}->{$o->{class}} = $o;
    $o->{_world} = $self;
    }

  $self;
  }

sub templates
  {
  my $self = shift;
  scalar keys %{$self->{templates}};
  }

sub save_templates
  {
  my ($self,$file) = @_;
 
  $self;
  }

sub save_to_file
  {
  my ($self,$file) = @_;
 
  $self->{file} = $file; 
  $self;
  }

sub reload
  {
  my $self = shift;

  $self->load_from_file($self->{file});
  }

sub register
  {
  # register an object with yourself
  my ($self,$obj) = @_;

  $obj->{id} = ID();				# get it a new ID
  $self->{things}->{$obj->{id}} = $obj;   	# store it
  $self->{things}->{_world} = $self;		# give thing access to us
  if ($obj->{visible})
    {
    $self->{render}->{$obj->{id}} = $obj;   	# store it
    }
  if ($obj->{think_time} != 0)
    {
    $self->{think}->{$obj->{id}} = $obj;   	# store it
    }

  $self;
  }

sub unregister
  {
  # should ONLY be called via $thing->{_world}->unregister($thing) !
  my ($self,$thing) = @_;

  my $id = $thing->{id};
  delete $self->{render}->{$id};
  delete $self->{things}->{$id};
  # tricky, what happens if called inside update()?  
  delete $self->{think}->{$id};
 
  $self;
  }

sub things
  {
  # get count of things
  my ($self) = @_;

  scalar keys %{$self->{things}};
  }

sub thinkers
  {
  # get count of thinking things
  my ($self) = @_;

  scalar keys %{$self->{think}};
  }

sub update
  {
  my ($self,$now) = @_;

  $self->{time} = $now;				# cache time
  foreach my $id (keys %{$self->{think}})
    {
    my $thing = $self->{think}->{$id};
    if ($thing->{next_think} >= $now)
      {
      $thing->think($now);
      }
    # if the thing is in transition between states, let it update itself
    $thing->update($now) if $thing->{state_endtime} != 0;

    # XXX TODO: does not handle things that no longer want to think()
    }
  $self;
  }

sub time
  {
  my $self = shift;

  $self->{time};
  }

sub render
  {
  my ($self,$now,$callback) = @_;

  foreach my $id (keys %{$self->{render}})
    {
    &$callback ( $now, $self->{render}->{$id} );
    }
  $self;
  }

sub create
  {
  # create an object based on a template (class name)
  my ($self,$class) = @_;

  return undef if !exists $self->{templates}->{$class};
  $self->{templates}->{$class}->create_thing();
  }

sub find_template
  {
  # given a class name, return the template object for it
  my ($self,$class) = @_;

  $self->{templates}->{$class};
  }

sub id { 0; }

1;

__END__

=pod

=head1 NAME

Games::3D::World - contains all things in the game world

=head1 SYNOPSIS

	use Games::3D::World;

	# construct world from templates file and level file
	my $level = Games::3D::World->new( $templates, $file);

	# load the same level again
	$level->reload();

	# create a new world from sratch:
	my $world = Games::3D::World->new();
	$world->load_templates( $templates_file );

	# add some thing directly
        $world->create ( $thing_class );

	# create another one
	my $thing = Games::3D::Thingy->new( ... );
	$thing->visible(1);
	$thing->think_time(100);
	# and make our world contain it
	$world->register($thing);
	
	# save the world
	$world->save_to_file();

	# foreach frame to render:
	while ($not_quit)
	  {
	  # other code like user input handling here
	  ...
	  # update the world with the current frame time:
	  $world->update( $now );
	  ...
	  # then let world call $callback for each visible object
	  $world->render( $now, $callback );
	  # other drawing code here
	  ...
	  }

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This class represents the entire in-game object system. It contains
I<Templates>, e.g. the blue-prints for objects, as well as the objects itself.

=head1 METHODS

=over 2

=item new()

	my $world = Games::3D::World->new( templates => $file );

Creates a new game world/level and reads in the templates from C<$file>.

=item load_from_file()

	$world->load_from_file( $file );

Load the game world/level from a file, replacing all existing data.

=item load_templates()

	$world->load_templates( $templates_file );

Loads the templates from a file. Alternatively, if given a scalar ref,
will I<load> the templates from the contents of the scalar.

=item save_to_file()

	my $rc = $world->save_to_file( $file );

Save game world/level to a file, returns undef for success, otherwise
ref to error message.

=item save_templates()

	my $rc = $world->save_templates( $file );

Save game world/level to a file, returns undef for success, otherwise
ref to error message.

=item templates()

	print "I have ", $world->templates(), " templates\n";

Returns the number of templates the world currently knows about.

=item render()

	$world->render();

Calls the method C<render()> on all things that want to be rendered.

=item update()

	$world->update( $now );

Let's all objects that want to think regulary think, and then updates 
objects that need updating. After this call, each object represents the
the state if has at the time C<$now>.

=item time()

	$world->time( );

Return the current time. Usefull for objects that want to know the time,
because L<update()> might cause some object to send a signal to another
object, and the second one needs to know when the signal arrives.

=item create()
  
	my $object = $world->create($class);

Create an object based on a template (class name) and populate it's settings
with the default values.

=item find_template()

	my $template_object = $world->find_template($class);

Given a class name, return the template object for it..

=item id()

	my $id = $world->id();

Return the ID of this world, which is always 0.

=item register()

	$self->register($thingy);

Register an object with the world.

=item unregister()

This method is automatically called to unregister objects with
the world upon their death.

=item reload()

	$world->reload();

Loads the world from the file again, thus resetting it to its
initial state again.

=item things()

	my $things = $world->things();

Returns the count of things in this world.

=item thinkers()

	my $thinkers = $world->thinkers();

Get the count of thinking things this world has.

=back

=head1 AUTHORS

(c) 2003, 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D::Thingy>, L<Games::3D::Link>, L<Games::Irrlicht>.

=cut

