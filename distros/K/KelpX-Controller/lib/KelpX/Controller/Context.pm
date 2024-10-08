package KelpX::Controller::Context;
$KelpX::Controller::Context::VERSION = '1.02';
use Kelp::Base 'Kelp::Context';

attr persistent_controllers => !!1;

sub build_controller
{
	my ($self, $class) = @_;
	return $class->new(context => $self);
}

1;

