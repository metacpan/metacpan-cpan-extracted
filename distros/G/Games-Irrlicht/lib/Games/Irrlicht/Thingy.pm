
# Thingy - a base class for timers, event handlers, buttons etc

package Games::Irrlicht::Thingy;

# (C) by Tels <http://bloodgate.com/>

use strict;

use vars qw/$VERSION/;

$VERSION = '0.02';

##############################################################################
# protected vars

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
  my $self = {}; bless $self, $class;

  $self->{id} = ID();
  $self->{app} = shift;

  $self->{active} = 1;
  $self->{group} = undef;
  
  $self->{outputs} = {};
  
  $self->{name} = $class;
  $self->{name} =~ s/.*:://;
  $self->{name} = ucfirst($self->{name});
  $self->{name} .= ' #' . $self->{id};
  
  $self->_init(@_);
  }

sub _init
  {
  my $self = shift;

  $self;
  }

sub group
  {
  # return the group this thing belongs to or undef
  my $self = shift;
  $self->{group};
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

  return 1 if $self->{active} == 1;			 # already active
  $self->{active} = 1;
  $self->{app}->_activated_thing($self);
  1;
  }

sub deactivate
  {
  my ($self) = shift;

  return 0 if $self->{active} == 0;			 # already inactive
  $self->{active} = 0;
  $self->{app}->_deactivated_thing($self);
  0;
  }

sub is_active
  {
  my ($self) = shift;

  $self->{active};
  }

sub id
  {
  # return thing id
  my $self = shift;
  $self->{id};
  }

1;

__END__

=pod

=head1 NAME

Games::Irrlicht::Thingy - base class for event handlers, timers etc

=head1 SYNOPSIS

	package Games::Irrlicht::MyThingy;

	use Games::Irrlicht::Thingy;
	require Exporter;

	@ISA = qw/Games::Irrlicht::Thingy/;

	sub _init
	  {
	  my ($self) = shift;

	  # init with arguments from @_
	  }

	# override or add any method you need

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a base class for "things" in Games::Irrlicht. It should
not be used on it's own.

=head1 METHODS

These methods need not to be overwritten:

=over 2

=item new()

	my $thingy = Games::Irrlicht::Thingy->new($app,@options);

Creates a new thing, and registers it with the application $app (usually
an instance of a subclass of Games::Irrlicht).

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

=back

=head1 AUTHORS

(c) 2002, 2003, 2004, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::Irrlicht>.

=cut

