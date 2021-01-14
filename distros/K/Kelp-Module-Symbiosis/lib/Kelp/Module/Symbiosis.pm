package Kelp::Module::Symbiosis;

our $VERSION = '1.01';

use Kelp::Base qw(Kelp::Module);
use Plack::App::URLMap;
use Carp;
use Scalar::Util qw(blessed);

attr "-mounted" => sub { {} };

sub mount
{
	my ($self, $path, $app) = @_;
	my $mounted = $self->mounted;

	carp "Overriding mounting point $path"
		unless !exists $mounted->{$path};
	$mounted->{$path} = $app;
	return scalar keys %{$mounted};
}

sub run_all
{
	my ($self) = shift;

	warn __PACKAGE__ . '->run_all is deprecated, please use ' . __PACKAGE__ . ' run instead';
	return $self->run(@_);
}

sub run
{
	my ($self) = shift;
	my $psgi_apps = Plack::App::URLMap->new;

	my $error = "Cannot start the ecosystem:";
	while (my ($path, $app) = each %{$self->mounted}) {
		if (blessed $app) {
			croak "$error application mounted under $path cannot run()"
				unless $app->can("run");
			$psgi_apps->map($path, $app->run(@_));
		}
		elsif (ref $app eq 'CODE') {
			$psgi_apps->map($path, $app);
		}
		else {
			croak "$error mount point $path is not an object";
		}
	}

	return $psgi_apps->to_app;
}

sub build
{
	my ($self, %args) = @_;
	if (!exists $args{automount} || $args{automount}) {
		$self->mount("/", $self->app);
	}

	$self->register(
		symbiosis => $self,
		run_all => sub { shift->symbiosis->run(@_); },
	);

}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis - Manage an entire ecosystem of Plack organisms under Kelp

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/Symbiosis SomeSymbioticModule/],
	modules_init => {
		Symbiosis => {
			automount => 0, # boolean, defaults to 1
		},
	},

	# in kelp application
	$kelp->symbiosis->mount('/app-path' => $kelp); # only required if config 'automount' is explicitly false
	$kelp->symbiosis->mount('/other-path' => $kelp->some_symbiotic_module);

	# in psgi script
	my $app = MyApp->new();
	$app->run_all; # instead of run

=head1 DESCRIPTION

This module is an attempt to standardize the way many standalone Plack applications should be ran alongside the Kelp framework. The intended use is to introduce new "organisms" into symbiotic interaction by creating Kelp modules that are then attached onto Kelp. Then, the added method I<run_all> should be invoked in place of Kelp's I<run>, which will construct a L<Plack::App::URLMap> and return it as an application.

=head2 Why not just use Plack::Builder in a .psgi script?

One reason is not to put too much logic into .psgi script. It my opinion a framework should be capable enough not to make adding an additional application feel like a hack. This is of course subjective.

The main functional reason to use this module is the ability to access the Kelp application instance inside another Plack application. If that application is configurable, it can be configured to call Kelp methods. This way, Kelp can become a glue for multiple standalone Plack applications, the central point of a Plack mixture:

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

	sub build {
		my ($kelp) = @_;

		my $another_app = $kelp->get_another_app;
		$kelp->symbiosis->mount('/app' => $another_app);
	}

=head2 What can be mounted?

The sole requirement for a module to be mounted into Symbiosis is its ability to I<run()>, returning the psgi application. A module also needs to be a blessed reference, of course. Fun fact: Symbiosis module itself meets that requirements, so one symbiotic app can be mounted inside another.

It can also be just a plain psgi app, which happens to be a code reference.

Whichever it is, it should be a psgi application ready to be ran by the server, wrapped in all the needed middlewares. This is made easier with L<Kelp::Module::Symbiosis::Base>, which allows you to add symbionts in the configuration for Kelp along with the middlewares. Because of this, this should be a preferred way of defining symbionts.

For very simple use cases, this will work though:

	# in application build method
	my $some_app = SomePlackApp->new()->to_app;
	$self->symbiosis->mount('/path', $some_app);

=head1 METHODS

=head2 mount

	sig: mount($self, $path, $app)

Adds a new $app to the ecosystem under $path.

=head2 run_all

	sig: run_all($self)

DEPRECATED: use L</run> instead.

=head2 run

Constructs and returns a new L<Plack::App::URLMap> with all the mounted modules and Kelp itself.

=head2 mounted

	sig: mounted($self)

Returns a hashref containing a list of mounted modules, keyed with their specified mount paths.

=head1 METHODS INTRODUCED TO KELP

=head2 symbiosis

Returns an instance of this class.

=head2 run_all

Shortcut method, same as C<< $kelp->symbiosis->run() >>.

=head1 CONFIGURATION

=head2 automount

Whether to automatically call I<mount> for the Kelp instance, which will be mounted to root path I</>. Defaults to I<1>.

If you set this to I<0> you will have to run something like C<< $kelp->symbiosis->mount($mount_path, $kelp); >> in Kelp's I<build> method. This will allow other paths than root path for the base Kelp application, if needed.

=head1 CAVEATS

Routes specified in symbiosis will be matched before routes in Kelp. Once you mount something under I</api> for example, you will no longer be able to specify Kelp route for anything under I</api>.

=head1 SEE ALSO

=over 2

=item * L<Kelp::Module::Symbiosis::Base>, a base for symbiotic modules

=item * L<Kelp::Module::Websocket::AnyEvent>, a reference symbiotic module

=item * L<Plack::App::URLMap>, Plack URL mapper application

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
