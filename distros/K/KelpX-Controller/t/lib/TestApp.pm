package TestApp;

use Kelp::Base 'Kelp';

attr context_obj => 'KelpX::Controller::Context';

sub build
{
	my $self = shift;

	# app add_route, not controller's (check if all routes hit the controller)
	$self->add_route('/dump_sub' => $self->dumper_sub);

	$self->context->build_controllers;
}

sub before_dispatch
{
	my $self = shift;

	$self->res->header('X-Dispatch', ref $self);
}

sub dumper_sub
{
	return sub {
		my $self = shift;

		my %app = $self->can('app') ? (app => ref $self->app) : ();
		my %test = $self->can('test') ? (test => $self->test) : ();

		return {
			%app,
			%test,
			class => ref $self,
			context => ref $self->context,
			req => ref $self->req,
			res => ref $self->res,
			extra => [@_],
		};
	};
}

1;

