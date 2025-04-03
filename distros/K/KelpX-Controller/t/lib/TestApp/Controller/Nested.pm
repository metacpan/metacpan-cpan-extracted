package TestApp::Controller::Nested;

use Kelp::Base 'TestApp::Controller';

sub build
{
	my $self = shift;

	$self->add_route(
		'/dump2', {
			to => 'dump'
		}
	);
	$self->add_route('/dump2_sub', $self->app->dumper_sub);
}

sub dump
{
	my $self = shift;

	return $self->app->dumper_sub->($self, __PACKAGE__);
}

1;

