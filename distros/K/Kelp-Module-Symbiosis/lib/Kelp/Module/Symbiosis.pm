package Kelp::Module::Symbiosis;
$Kelp::Module::Symbiosis::VERSION = '2.11';
use Kelp::Base qw(Kelp::Module);
use KelpX::Symbiosis::Adapter;

sub build
{
	my ($self, %args) = @_;

	my $adapter = KelpX::Symbiosis::Adapter->new(
		app => $self->app,
		engine => delete $args{engine} // 'URLMap'
	);

	$adapter->build(%args);
	$self->register(
		symbiosis => $adapter,
		run_all => sub { shift->symbiosis->run(@_); },
	);

}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis - Fertile ground for building Plack apps

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/Symbiosis SomeSymbioticModule/],
	modules_init => {
		Symbiosis => {
			mount => '/kelp', # a path to mount Kelp main instance
		},
		SomeSymbioticModule => {
			mount => '/elsewhere', # a path to mount SomeSymbioticModule
		},
	},

	# in kelp application - can be skipped if all mount paths are specified in config above
	my $symbiosis = $kelp->symbiosis;
	$symbiosis->mount('/app-path' => $kelp);
	$symbiosis->mount('/other-path' => $kelp->module_method);
	$symbiosis->mount('/other-path' => 'module_name'); # alternative - finds a module by name

	# in psgi script
	my $app = KelpApp->new();
	$app->run_all; # instead of run

=head1 DESCRIPTION

This module is an attempt to standardize the way many standalone Plack
applications should be ran alongside the Kelp framework. The intended use is to
introduce new "organisms" into symbiotic interaction by creating Kelp modules
that are then attached onto Kelp. Then, the added method I<run_all> should be
invoked in place of Kelp's I<run>, which will construct and return an ecosystem.

=head2 Module state with Kelp 2.10

This module isn't as useful anymore with Kelp version C<2.10> adding easy
mounting of Plack apps. It may still be useful in some specific scenarios, like
automatic URLMap usage or when some modules use it, but generally you can
consider it outdated, as the problem it was solving is now easily solved using
core L<Kelp>. See L<Kelp::Manual/Nesting Plack apps> for details on how Kelp
deals with mounting applications under a route natively.

=head2 Why not just use Plack::Builder in a .psgi script?

One reason is not to put too much logic into .psgi script. It my opinion a
framework should be capable enough not to make adding an additional application
feel like a hack. This is of course subjective.

The main functional reason to use this module is the ability to access the Kelp
application instance inside another Plack application. If that application is
configurable, it can be configured to call Kelp methods. This way, Kelp can
become a glue for multiple standalone Plack applications, the central point of
a Plack mixture:

	# in Symbiont's Kelp module (extends Kelp::Module::Symbiosis::Base)

	sub psgi {
		my ($self) = @_;

		my $app = Some::Plack::App->new(
			on_something => sub {
				my $kelp = $self->app; # we can access Kelp!
				$kelp->something_happened;
			},
		);

		return $app->to_app;
	}

	# in Kelp application class

	sub something_happened {
		... # handle another app's signal
	}


=head2 What can be mounted?

The sole requirement for a module to be mounted into Symbiosis is its ability
to I<run()>, returning the psgi application. A module also needs to be a
blessed reference, of course. Fun fact: Symbiosis module itself meets that
requirements, so one symbiotic app can be mounted inside another.

It can also be just a plain psgi app, which happens to be a code reference.

Whichever it is, it should be a psgi application ready to be ran by the server,
wrapped in all the needed middlewares. This is made easier with
L<Kelp::Module::Symbiosis::Base>, which allows you to add symbionts in the
configuration for Kelp along with the middlewares. Because of this, this should
be a preferred way of defining symbionts.

For very simple use cases, this will work though:

	# in application build method
	my $some_app = SomePlackApp->new->to_app;
	$self->symbiosis->mount('/path', $some_app);

=head1 METHODS

These methods are available on the object in C<< $app->symbiosis >>:

=head2 mount

	sig: mount($self, $path, $app)

Adds a new $app to the ecosystem under $path. I<$app> can be:

=over

=item

A blessed reference - will try to call C<run> on it

=item

A code reference - will try calling it

=item

A string - will try finding a symbiotic module with that name and mounting it.
See L<Kelp::Module::Symbiosis::Base/name>

=back

=head2 run

Returns a coderef ready to be run by a Plack handler. Details on that depend on
the engine used, see L</engine>.

Note: it will not run mounted object twice. This means that it is safe to mount
something in two paths at once, and it will just be an alias to the same
application.

=head2 mounted

	sig: mounted($self)

Returns a hashref containing a list of mounted modules, keyed by their specified mount paths.

=head2 loaded

	sig: loaded($self)

I<new in 1.10>

Returns a hashref containing a list of loaded modules, keyed by their names.

A module is loaded once it is added to Kelp configuration. This can be used to
access a module that does not introduce new methods to Kelp.

=head1 METHODS INTRODUCED TO KELP

=head2 symbiosis

Returns an instance of this class.

=head2 run_all

Shortcut method, same as C<< $kelp->symbiosis->run() >>.

=head1 CONFIGURATION

	# Symbiosis MUST be specified as the first one
	modules => [qw/Symbiosis Module::Some/],
	modules_init => {
		Symbiosis => {
			mount => '/kelp',
		},
		'Module::Some' => {
			mount => '/some',
			...
		},
	}

Symbiosis should be the first of the symbiotic modules specified in your Kelp
configuration. Failure to meet this requirement will cause your application to
crash immediately.

=head2 engine

I<new in 2.00>

Engine is the approach taken by the module to run your apps. Engines are
implemented in namespace C<KelpX::Symbiosis::Engine>. Bundled engines include:

=over

=item * L<KelpX::Symbiosis::Engine::URLMap>, which uses L<App::Plack::URLMap> and mounts Kelp into it alongside other apps

=item * L<KelpX::Symbiosis::Engine::Kelp>, which uses app routing to mount other apps

=back

Default is C<URLMap>. See their documentation for caveats regarding each implementation.

=head2 mount

I<new in 1.10>

A path to mount the Kelp instance, which defaults to I<'/'>. Specify a string
if you wish a to use different path. Specify an I<undef> or empty string to
avoid mounting at all - you will have to run something like C<<
$kelp->symbiosis->mount($mount_path, $kelp); >> in Kelp's I<build> method
(unless the engine is C<Kelp>, in which case you can't mount the app anywhere -
it will always be root).

=head2 reverse_proxy

I<new in 1.11>

A boolean flag (I<1/0>) which enables reverse proxy for all the Plack apps at
once. Requires L<Plack::Middleware::ReverseProxy> to be installed.

=head2 middleware, middleware_init

I<new in 1.12>

Middleware specs for the entire ecosystem. Every application mounted in
Symbiosis will be wrapped in these middleware. They are configured exactly the
same as middlewares in Kelp. Regular Kelp middleware will be used just for the
Kelp application, so if you want to wrap all symbionts at once, this is the
place to do it.

=head1 CAVEATS

Routes specified in symbiosis will be matched before routes in Kelp. Once you
mount something under I</api> for example, you will no longer be able to
specify Kelp route for anything under I</api>.

=head1 SEE ALSO

=over

=item * L<Kelp::Module::Symbiosis::Base>, a base for symbiotic modules

=item * L<Kelp::Module::WebSocket::AnyEvent>, a reference symbiotic module

=item * L<Plack::App::URLMap>, Plack URL mapper application

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

