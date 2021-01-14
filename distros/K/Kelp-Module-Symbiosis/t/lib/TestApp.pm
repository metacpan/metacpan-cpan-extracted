package TestApp;
use Kelp::Base 'Kelp';

sub build
{
	my $self = shift;
	my $r = $self->routes;

	$r->add('/home', 'home');
	$self->symbiosis->mount('/test', $self->testmod);
	$self->symbiosis->mount('/test2', $self->another);
	$self->symbiosis->mount('/test/test', $self->another);
}

sub home
{
	'this is home';
}

1;
