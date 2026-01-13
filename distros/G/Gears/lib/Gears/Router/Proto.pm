package Gears::Router::Proto;
$Gears::Router::Proto::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard, -role;

requires qw(
	pattern
);

has param 'router' => (
	isa => InstanceOf ['Gears::Router'],
	weak_ref => 1,
);

has field 'locations' => (
	isa => ArrayRef [InstanceOf ['Gears::Router::Location']],
	default => sub { [] },
);

sub add ($self, $pattern, $data = {})
{
	my $location = $self->router->_build_location(
		$data->%*,
		router => $self->router,
		pattern => $self->pattern . $pattern,
	);

	push $self->locations->@*, $location;
	return $location;
}

