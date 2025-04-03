package TestApp::Controller;

use Kelp::Base 'KelpX::Controller';

attr test => sub {
	state $last = 0;
	return ++$last;
};

sub before_dispatch
{
	my $self = shift;

	$self->res->header('X-Dispatch', ref $self);
}

sub build
{
	my $self = shift;

	$self->add_route('/dump', 'dump');
	$self->add_route('/dump3', 'Nested::dump');
}

sub dump
{
	my $self = shift;

	return $self->app->dumper_sub->($self, __PACKAGE__);
}

1;

