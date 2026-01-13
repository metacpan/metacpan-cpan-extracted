package Gears::Component;
$Gears::Component::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

has param 'app' => (
	isa => InstanceOf ['Gears::App'],
	weak_ref => 1,
);

sub BUILD ($self, $)
{
	$self->configure;
	my $class = ref $self;

	# make sure superclass build method won't be called (avoid building the
	# same elements twice)
	if (exists &{"${class}::build"}) {
		$self->build;
	}
}

sub configure ($self)
{
}

sub build ($self)
{
}

__END__

=head1 NAME

Gears::Component - Base class for application components

=head1 SYNOPSIS

	package My::App::Component::Cache;

	use v5.40;
	use Mooish::Base;

	extends 'Gears::Component';

	has field 'cache_data' => (
		default => sub { {} },
	);

	sub configure ($self)
	{
		# Called first, before build
		# Good place to read configuration
	}

	sub build ($self)
	{
		# Called after configure
		# The programmer can build the component here
	}

=head1 DESCRIPTION

Gears::Component is the base class for all application components in Gears. It
provides access to the main application object and defines a two-phase
initialization process through the C<configure> and C<build> methods.

All components maintain a weak reference to the application to prevent circular
references. The initialization happens automatically during object construction,
with C<configure> called first, followed by C<build> if it's defined in the
component class (not inherited).

=head1 INTERFACE

=head2 Attributes

=head3 app

A weak reference to the L<Gears::App> instance. This allows the component to
access shared application resources.

I<Required in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 configure

	$component->configure()

Called first during component initialization, before C<build>. This method is
intended to be overridden by subclasses to perform configuration-related setup.
The default implementation is empty.

This method is always called, even if not overridden in the component class.

=head3 build

	$component->build()

Called after C<configure> during component initialization. This method is
intended to be overridden by subclasses to perform component setup that may
depend on configuration.

This method is only called if defined directly in the component class, not if
inherited from a parent class. This prevents double initialization when
extending components, as it is intended to change the application itself.

The default implementation is empty.

