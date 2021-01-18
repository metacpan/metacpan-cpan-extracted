package Kelp::Module::Symbiosis::Base;

our $VERSION = '1.10';

use Kelp::Base qw(Kelp::Module);
use Plack::Util;

attr "-middleware" => sub { [] };

# should likely be overriden for a more suitable name
# won't break backcompat though
sub name { ref shift }

sub run
{
	my ($self) = shift;

	my $app = $self->psgi(@_);
	for (@{$self->middleware}) {
		my ($class, $args) = @$_;

		# Same middleware loading procedure as Kelp
		next if $self->{_loaded_middleware}->{$class}++ && !$ENV{KELP_TESTING};

		my $mw = Plack::Util::load_class($class, "Plack::Middleware");
		$app = $mw->wrap($app, %{$args // {}});
	}
	return $app;
}

sub psgi
{
	die __PACKAGE__ . " - psgi needs to be reimplemented";
}

sub build
{
	my ($self, %args) = @_;

	die 'Kelp::Module::Symbiosis needs to be loaded before ' . ref $self
		unless $self->app->can('symbiosis');

	my $middleware = $self->middleware;
	foreach my $mw (@{$args{middleware}}) {
		my $config = $args{middleware_init}{$mw};
		push @$middleware, [$mw, $config];
	}

	$self->app->symbiosis->_link($self->name, $self, $args{mount});
	return;
}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis::Base - Base class for symbiotic modules

=head1 SYNOPSIS

	package Kelp::Module::MyModule;

	use Kelp::Base qw(Kelp::Module::Symbiosis::Base);

	sub psgi
	{
		# write code that returns psgi application without middlewares
	}

	sub build
	{
		my ($self, %args) = @_;
		$self->SUPER::build(%args);

		# write initialization code as usual
		$self->register(some_method => sub { ... });
	}

=head1 DESCRIPTION

This class serves as a base for a Kelp module that is supposed to be ran as a standalone Plack application (mounted separately). It takes care of middleware management, mounting into Symbiosis manager and some basic initialization chores. To write a new module that introduces a standalone Plack application as a Kelp module, simply extend this class and override methods: C<psgi build name> (see below for details).

=head2 Purpose

It is a base for Kelp modules that are meant to be used with Symbiosis - it inherits from L<Kelp::Module>. It can also come very handy because of the built in middleware handling and access to Kelp application's configuration.

=head1 METHODS

=head2 run

	sig: run($self)

Calls I<psgi()> and wraps its contents in middlewares. Returns a Plack application.

=head2 psgi

	sig: psgi($self, @more_data)

By default, this method will throw an exception. It has to be replaced with an actual application producing code in the child class. The resulting application will be wrapped in middlewares from config in I<run()>.

B<Must be reimplemented> in a module.

=head2 build

	sig: build($self, %args)

Standard Kelp module building method. When reimplementing it's best to call parent's implementation, as middleware initialization happens in base implementation.

B<Should be reimplemented> in a module. If it isn't, no extra methods will be added to the Kelp instance, but all the middleware and module registration in Symbiosis will happen anyway.

=head2 name

	sig: name($self)

I<new in 1.10>

Returns a name of a module - a string. This name will be available in L<Kelp::Module::Symbiosis/loaded> hash as a key, containing the module instance as a value.

B<Should be reimplemented> in a module. If it isn't, it will return the name of the package.

=head2 middleware

	sig: middleware($self)

Returns an array containing all the middlewares in format: C<[ middleware_class, { middleware_config } ]>. By default, this config comes from module configuration.

=head1 CONFIGURATION

example configuration could look like this (for L<Kelp::Module::WebSocket::AnyEvent>):

	modules => [qw/JSON Symbiosis WebSocket::AnyEvent/],
	modules_init => {
		Symbiosis => {
			mount => undef, # kelp will be mounted manually under different path
		},
		"WebSocket::AnyEvent" => {
			serializer => "json",
			middleware => [qw/Recorder/],
			middleware_init => {
				Recorder => { output => "~/recorder.out" },
			}
		},
	}

=head2 middleware, middleware_init

Middleware specs for this application - see above example. Every module basing on this class can specify its own set of middlewares. They are configured exactly the same as middlewares in Kelp. There's currently no standarized way to retrieve middleware configurations from Kelp into another application (to wrap that application in the same middleware as Kelp), so custom code is needed if such need arise.

=head2 mount

	modules_init => {
		"Symbiotic::Module" => {
			mount => '/path',
			...
		},
	}

I<new in 1.10>

Should be a string value. If specified, the module will be automatically mounted under that path - there will be no need to call that explicitly, and it will work like: C<< $kelp->symbiosis->mount($path => $module); >>.

=head1 SEE ALSO

=over 2

=item * L<Kelp::Module::Symbiosis>, the module manager

=back
