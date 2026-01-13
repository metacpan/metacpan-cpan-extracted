package Gears::App;
$Gears::App::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Gears qw(load_component get_component_name);
use Gears::X;

extends 'Gears::Component';

has param 'router' => (
	isa => InstanceOf ['Gears::Router'],
);

has param 'config' => (
	isa => InstanceOf ['Gears::Config'],
);

has field 'controllers' => (
	isa => ArrayRef [InstanceOf ['Gears::Controller']],
	default => sub { [] },
);

# we are the app
has extended 'app' => (
	default => sub ($self) { $self },
	init_arg => undef,
);

sub _build_controller ($self, $class)
{
	return $class->new(app => $self);
}

sub load_controller ($self, $controller)
{
	my $base = (ref $self) . '::Controller';
	my $class = get_component_name($controller, $base);
	push $self->controllers->@*, $self->_build_controller(load_component($class));

	return $self;
}

__END__

=head1 NAME

Gears::App - Main application class

=head1 SYNOPSIS

	package My::App;

	use v5.40;
	use Mooish::Base;

	extends 'Gears::App';

	sub build ($self)
	{
		$app->load_controller('User');
		$app->load_controller('Blog');
	}

	# Later in your code
	my $app = My::App->new(
		router => $router,
		config => $config,
	);

=head1 DESCRIPTION

Gears::App is the main application class that ties together the core components
of a Gears application. It extends L<Gears::Component> and serves as the
central hub that holds references to the router, configuration, and loaded
controllers.

The application object is passed to all components, providing them with access
to the shared application state. Controllers can be dynamically loaded and are
automatically configured with a reference to the application.

=head1 EXTENDING

Application classes should extend Gears::App and can add their own attributes
and methods. The application object is available to all components and
controllers, making it a good place to store shared application state.

Example:

	package My::App;

	use v5.40;
	use Mooish::Base;

	extends 'Gears::App';

	has field 'database' => (
		isa => InstanceOf['DBI::db'],
		builder => 1,
	);

	sub _build_database ($self)
	{
		# Initialize database connection
		return DBI->connect(...);
	}

=head1 INTERFACE

=head2 Attributes

=head3 router

A L<Gears::Router> instance that handles routing for the application.

I<Required in constructor>

=head3 config

A L<Gears::Config> instance that manages application configuration.

I<Required in constructor>

=head3 controllers

An array reference containing all loaded L<Gears::Controller> instances.

I<Not available in constructor>

=head3 app

While this attribute is derived from L<Gears::Component>, it makes little sense
in app object. It is set to point at the object itself and removed from
constructor arguments.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 load_controller

	$app = $app->load_controller($name)

Loads a controller by name and adds it to the application's controller list.
The controller name is resolved relative to the application's namespace with
C<::Controller> appended. For example, if your application is C<My::App> and
you call C<load_controller('User')>, it will load C<My::App::Controller::User>.

Returns the application object for method chaining.

