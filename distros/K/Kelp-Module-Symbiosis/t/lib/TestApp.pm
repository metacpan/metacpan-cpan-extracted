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
	$self->symbiosis->mount('/test', $self->testmod);
}

sub build_from_loaded
{
	my $self = shift;

	$self->symbiosis->mount('/s', $self);
	$self->symbiosis->mount('/test', 'symbiont');
	$self->symbiosis->mount('/test/test2', 'AnotherTestSymbiont');
}

sub home
{
	'this is home';
}

1;
