package CountingApp;
use Kelp::Base 'Kelp';

my $ran_times = 0;

sub run
{
	my $self = shift;
	$ran_times += 1;

	return $self->SUPER::run(@_);
}

sub get_count
{
	return $ran_times;
}

sub build
{
	my $self = shift;

	$self->routes->add('/', 'home');
	$self->symbiosis->mount("/kelp", $self);
	$self->symbiosis->mount("/also-kelp", $self);
	$self->symbiosis->mount("/test", $self->testmod);
	$self->symbiosis->mount("/also-test", $self->testmod);
}

sub home
{
	'kelp';
}

1;
