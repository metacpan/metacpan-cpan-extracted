package KelpX::Controller;
$KelpX::Controller::VERSION = '1.01';
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

sub before_dispatch
{
	my $self = shift;
	return $self->app->before_dispatch(@_);
}

sub before_finalize
{
	my $self = shift;
	return $self->app->before_finalize(@_);
}

sub build
{
}

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->build;
	return $self;
}

1;

__END__

=head1 NAME

KelpX::Controller - Base custom controller for Kelp

=head1 SYNOPSIS

	# your base controller
	package My::Controller;

	use Kelp::Base 'KelpX::Controller';

	sub build
	{
		# build your controller
	}

	# your application
	package My::Kelp;

	attr context_obj => 'KelpX::Controller::Context';

	...

=head1 DESCRIPTION

Since Kelp I<2.16> it's quite easy to introduce your own base controller class
instead of subclassing the main application class. While Kelp gives you this
option, it trusts you will develop your own infrastructure for that.

This module is a toolbox for less tedious integration of custom controller
class into your application. It consists of two classes, C<KelpX::Controller>
and C<KelpX::Controller::Context>. They must be used in tandem as shown in
L</SYNOPSIS>.

The controller will be built just like a regular object the first time it's
used. It will not be cleared after the request, since the context object will
have its C<persistent_controllers> set to true by default. You may override
L</build> in the controller, but if you want to have it add any routes then you
will have to instantiate it manually using C<< $app->context->controller >>.

=head1 ATTRIBUTES

=head2 context

B<Required>. The app's context object.

=head2 app

The application object. Will be loaded from L</context>.

=head1 METHODS

=head2 build

A build method, which will be called right after the controller is
instantiated. Takes no arguments and does nothing by default - it's up to you
to override it.

=head2 req

Proxy for reading the C<req> attribute from L</context>.

=head2 res

Proxy for reading the C<res> attribute from L</context>.

=head2 before_dispatch

Proxy for C<before_dispatch> from L</app>.

=head2 before_finalize

Proxy for C<before_finalize> from L</app>.

=head1 SEE ALSO

L<Kelp>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

