package TestApp;
use Kelp::Base 'Kelp';

sub build
{
	my $self = shift;
	my $r = $self->routes;

	$r->add('/home', 'home');
}

sub build_from_methods
{
	my $self = shift;

	if ($self->symbiosis->engine->isa('KelpX::Symbiosis::Engine::Kelp')) {
		$self->symbiosis->mount(qr{^/test(?!/test2)(/.+)?}, $self->testmod);
	}
	else {
		$self->symbiosis->mount('/test', $self->testmod);
	}
}

sub build_from_loaded
{
	my $self = shift;

	if ($self->symbiosis->engine->isa('KelpX::Symbiosis::Engine::Kelp')) {
		$self->symbiosis->mount('/test/test2', 'AnotherTestSymbiont');
		$self->symbiosis->mount(qr{^/test(?!/test2)(/.+)?}, 'symbiont');
	}
	else {
		$self->symbiosis->mount('/s', $self);
		$self->symbiosis->mount('/test', 'symbiont');
		$self->symbiosis->mount('/test/test2', 'AnotherTestSymbiont');
	}
}

sub home
{
	'this is home';
}

1;

