package TestApp;

use Kelp::Base 'Kelp';

attr context_obj => 'KelpX::Controller::Context';

sub build
{
	my $self = shift;

	$self->add_route('/' => 'dump');
}

sub before_dispatch
{
	my $self = shift;

	$self->res->header('X-Dispatch', 'true');
}

1;

