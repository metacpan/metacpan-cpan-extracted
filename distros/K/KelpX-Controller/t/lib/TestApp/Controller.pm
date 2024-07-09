package TestApp::Controller;

use Kelp::Base 'KelpX::Controller';

attr test => undef;
my $last = 0;

sub build
{
	my $self = shift;

	$last += 1;
	$self->test($last);
}

sub dump
{
	my $self = shift;

	return {
		class => ref $self,
		app => ref $self->app,
		context => ref $self->context,
		req => ref $self->req,
		res => ref $self->res,
		test => $self->test,
	};
}

1;

