package KelpApp;
use Kelp::Base 'Kelp';

sub build
{
	my $self = shift;

	$self->routes->add('/home', 'home');
	$self->raisin->add_route(
		method => 'GET',
		path => '/from-kelp',
		code => sub { 'Hello World from Kelp, in Raisin!' },
	);
}

sub home
{
	'Hello World from Kelp!';
}

1;
