package Gears::App;
$Gears::App::VERSION = '0.001';
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

