package KelpX::Controller;
$KelpX::Controller::VERSION = '2.00';
use Kelp::Base;
use Carp;

attr -context => sub { croak 'context is required for controller' };
attr -app => sub { $_[0]->context->app };

sub req
{
	return $_[0]->context->req;
}

sub res
{
	return $_[0]->context->res;
}

sub add_route
{
	my ($self, $route, $args) = @_;

	# borrowed from Whelk

	# make sure we have hash (same as in Kelp)
	$args = {
		to => $args,
	} unless ref $args eq 'HASH';

	# add proper namespace to the route
	my $base = $self->context->app->routes->base;
	if (!ref $args->{to} && $args->{to} !~ m{^\+|#|::}) {
		my $class = ref $self;
		if ($class !~ s/^${base}:://) {
			$class = "+$class";
		}

		my $join = $class =~ m{#} ? '#' : '::';
		$args->{to} = join $join, $class, $args->{to};
	}

	my $location = $self->app->add_route($route, $args);
	$location->parent->dest->[0] //= ref $self;    # makes sure plain subs work

	return $location;
}

sub build
{
}

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	# make sure superclass build method won't be called
	if (exists &{"${class}::build"}) {
		$self->build;
	}

	return $self;
}

1;

__END__

=head1 NAME

KelpX::Controller - Base custom controller for Kelp

=head1 SYNOPSIS

	### application's configuration
	modules_init => {
		Routes => {
			base => 'My::Controller',
			rebless => 1, # needed for historic reasons
		}
	},

	### your base controller
	package My::Controller;

	use Kelp::Base 'KelpX::Controller';

	sub build
	{
		my $self = shift;

		$self->add_route('/sub' => sub { ... });
		$self->add_route('/method_name', 'this_controller_method');
		$self->add_route('/hashref', {
			to => 'this_controller_method',
		});
	}

	sub this_controller_method
	{
		my $self = shift;

		return 'Hello world from ' . ref $self;
	}

	### your main application class
	package My::Kelp;

	attr context_obj => 'KelpX::Controller::Context';

	sub build
	{
		my $self = shift;

		$self->context->build_controllers;
	}

=head1 DESCRIPTION

Since Kelp I<2.16> it's quite easy to introduce your own base controller class
instead of subclassing the main application class.

This extension is a more modern approach to route handling, which lets you have
a proper hierarchy of custom classes which serve as controllers. Enabling it is
easy, and can be done as shown in L</SYNOPSIS>.

The controller will be built just like a regular object the first time it's
used. It will not be cleared after the request, since the context object will
have its C<persistent_controllers> set to true by default. You may override
L</build> in the controller, but if you want to have it add any routes then you
will have to instantiate it manually using C<< $app->context->controller >>.

=head2 Building controllers

In order for routes defined in your controller to register, you need to build
the controllers. You can done it manually by calling C<<
$self->context->controller >> for each of your controllers, or automatically by
calling C<< $self->context->build_controllers >>. The latter will load all
modules in the namespace of your base controller using L<Module::Loader> and
build them. As long as all your controllers are in the same namespace under the
base controller, the automatic method is recommended (though it does not allow
for conditional disabling of the controllers).

=head1 ATTRIBUTES

=head2 context

B<Required>. The app's context object.

=head2 app

The application object. Will be loaded from L</context>.

=head1 METHODS

These methods are provided for convenience, but they are not meant to fully
replicate the API available when not using controllers or using reblessing. For
this reason, this module is not a drop-in replacement for reblessing
controllers.

=head2 build

A build method, which will be called right after the controller is
instantiated. Similar to C<app> build method. Takes no arguments and does
nothing by default - it's up to you to override it.

Since controllers inherit from one another and each route should only be built
once, a special check is implemented which will not run this method
automatically if it was not implemented in a controller class (to avoid calling
parent class method). Make sure B<not> to call C<SUPER> version of this method
if you implement it. If you need code that must be run for every controller,
it's recommended to override C<new>.

=head2 add_route

Similar to L<Kelp::Module::Routes/add_route>, but it modifies the destination
so that the route dispatch will run in the context of current controller.
Unlike core Kelp controllers, you can use simple function names or even plain
subroutines and they will pass the instance of your controller as their first
argument.

=head2 req

Proxy for reading the C<req> attribute from L</context>.

=head2 res

Proxy for reading the C<res> attribute from L</context>.

=head1 CAVEATS

=over

=item

When using this module, even subroutine based routes will be run using the
application's main controller (instead of application instance). Thanks to
this, main class will never be used as call context for route handlers, so any
hooks like C<before_dispatch> can be safely moved to the base controller.

=back

=head1 SEE ALSO

L<Kelp>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

