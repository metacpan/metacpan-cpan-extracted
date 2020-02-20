package Kelp::Module::Symbiosis;

use Kelp::Base qw(Kelp::Module);
use Plack::App::URLMap;
use Carp;
use Scalar::Util qw(blessed);

our $VERSION = '1.00';

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
	my $psgi_apps = Plack::App::URLMap->new;

	my $error = "Cannot start the ecosystem:";
	while (my ($path, $app) = each %{$self->mounted}) {
		croak "$error mount point $path is not an object"
			unless blessed $app;
		croak "$error application mounted under $path cannot run()"
			unless $app->can("run");
		$psgi_apps->map($path, $app->run(@_));
	}

	return $psgi_apps->to_app;
}

sub run
{
	my ($self) = shift;
	return $self->run_all(@_);
}

sub build
{
	my ($self, %args) = @_;
	if (!exists $args{automount} || $args{automount}) {
		$self->mount("/", $self->app);
	}

	$self->register(
		symbiosis => $self,
		run_all => sub { shift->symbiosis->run_all(@_); },
	);

}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis - manage an entire ecosystem of Plack organisms under Kelp

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/Symbiosis SomeSymbioticModule/],
	modules_init => {
		Symbiosis => {
			automount => 0, # boolean, defaults to 1
		},
	},

	# in kelp application
	$kelp->symbiosis->mount('/app-path' => $kelp); # only required if automount is 0
	$kelp->symbiosis->mount('/other-path' => $kelp->some_symbiotic_module);

	# in psgi script
	my $app = MyApp->new();
	$app->run_all; # instead of run

=head1 DESCRIPTION

This module is an attempt to standardize the way many standalone Plack applications should be ran alongside the Kelp framework. The intended use is to introduce new "organisms" into symbiotic interaction by creating Kelp modules that are then attached onto Kelp. Then, the I<run_all> should be invoked in place of Kelp's I<run>, which will construct a L<Plack::App::URLMap> and return it as an application.

=head1 METHODS

=head2 mount

	sig: mount($self, $path, $app)

Adds a new $app to the ecosystem under $path.

=head2 run_all

	sig: run_all($self)

Constructs and returns a new L<Plack::App::URLMap> with all the mounted modules and Kelp itself.

=head2 mounted

	sig: mounted($self)

Returns a hashref containing a list of mounted modules, keyed with their specified mount paths.

=head1 METHODS INTRODUCED TO KELP

=head2 symbiosis

Returns an instance of this class.

=head2 run_all

Shortcut method, same as C<< symbiosis->run_all() >>.

=head1 CONFIGURATION

=head2 automount

Whether to automatically call I<mount> for the Kelp instance, which will be mounted to root path I</>. Defaults to I<1>.

If you set this to I<0> you will have to run something like C<< $kelp->symbiosis->mount($mount_path, $kelp); >> in Kelp's I<build> method. This will allow other paths than root path for the base Kelp application, if needed.

=head1 REQUIREMENTS FOR MODULES

The sole requirement for a module to be mounted into Symbiosis is its ability to I<run()>. A module also needs to be a blessed reference, of course.

The I<run> method should return a psgi application ready to be ran by the Server, wrapped in all the needed middlewares. See L<Kelp::Module::Symbiosis::Base> for a preferred base class for these modules.

=head1 SEE ALSO

=over 2

=item L<Kelp::Module::Symbiosis::Base>, a base for symbiotic modules

=item L<Kelp::Module::Websocket::AnyEvent>, a reference symbiotic module

=item L<Plack::App::URLMap>, Plack URL mapper application

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
