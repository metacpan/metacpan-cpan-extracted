package KelpX::Controller::Context;
$KelpX::Controller::Context::VERSION = '2.00';
use Kelp::Base 'Kelp::Context';
use Module::Loader;

attr persistent_controllers => !!1;

sub build_controller
{
	my ($self, $class) = @_;
	return $class->new(context => $self);
}

sub build_controllers
{
	my ($self) = @_;

	my $base = $self->controller;
	my @subcontrollers = Module::Loader->new->find_modules(ref $base);

	foreach my $controller (@subcontrollers) {
		$self->controller("+$controller");
	}
}

sub set_controller
{
	my ($self, $class) = @_;

	# normally, if there is no controller, an app will be used as current
	# context. Use base controller instead.
	return $self->current($self->controller)
		unless $class;

	return $self->SUPER::set_controller($class);
}

1;

