package Kelp::Module::Storage::Abstract;
$Kelp::Module::Storage::Abstract::VERSION = '1.00';
use Kelp::Base 'Kelp::Module';
use Storage::Abstract;
use Plack::App::Storage::Abstract;

sub build
{
	my ($self, %args) = @_;
	my $app = $self->app;

	my $routes = delete $args{public_routes} // {};
	require Kelp::Module::Storage::Abstract::KelpExtensions
		if delete $args{kelp_extensions};

	my $storage = Storage::Abstract->new(%args);

	foreach my $key (keys %$routes) {
		my $mapping = $routes->{$key};
		my $this_storage = $storage;

		# key will have />file appended
		# name will be adjusted so that /public/path key becomes storage_public_path
		my $name = $key;
		$name =~ s{^/+|/+$}{}g;
		$name =~ s{/+}{_}g;
		$name = "storage_$name";
		$key =~ s{/?$}{/>file};

		if ($mapping && $mapping ne '/') {
			$this_storage = Storage::Abstract->new(
				driver => 'subpath',
				source => $storage,
				subpath => $mapping,
			);
		}

		my $plack_app = Plack::App::Storage::Abstract->new(
			storage => $this_storage,
			encoding => $app->charset,
		);

		$app->add_route(
			$key => {
				to => $plack_app->to_app,
				name => $name,
				psgi => 1,
			}
		);
	}

	$self->register(storage => $storage);
}

1;

__END__

=head1 NAME

Kelp::Module::Storage::Abstract - Abstract file storage for Kelp

=head1 SYNOPSIS

	# in the configuration
	modules => [qw(Storage::Abstract)],
	modules_init => {
		'Storage::Abstract' => {
			driver => 'directory',
			directory => '/path/to/rootdir',
			public_routes => {
				# map URL /public to the root of the storage
				'/public' => '/',
			},
			kelp_extensions => 1,
		},
	},

=head1 DESCRIPTION

This module adds L<Storage::Abstract> instance to Kelp, along with a static
file server functionality and some file-related utility methods.

=head1 METHODS INTRODUCED TO KELP

=head2 storage

	$obj = $app->storage

This is a L<Storage::Abstract> object constructed using the module configuration.

=head1 CONFIGURATION

Most configuration values will be used to construct the underlying storage
object. Consult L<Storage::Abstract> and its drivers documentation for details.

Two special flags exist:

=over

=item * C<public_routes>

This key, if passed, should be a hash reference where each key is a base route
and each value is a storage path from which the files will be served. If you write:

	public_routes => {
		'/public' => '/',
	},

Then it will be possible to access to all files from your storage through
C</public> route. A L<Plack::App::Storage::Abstract> instance will be set up on
each of these routes.

This route will be given a name corresponding to its url, with slashes replaced
with underscores and C<storage_> prepended. So the route above will be named
C<storage_public>. You may use it to build URLs for this route - the additional
path of the file must be passed as a C<file> placeholder, so for example:

	my $url = $app->url_for(storage_public => (file => 'my/file'));

=item * C<kelp_extensions>

This key will enable additional extensions to L<Kelp::Response>. It will add a
new method to it called C<render_file>. This method will take files from your
storage and render them much like L<Plack::App::Storage::Abstract> does:

	$app->add_route('/serve_file' => sub {
		my $app = shift;
		$app->res->render_file('/file/path');
	});

Note that it modifies the base L<Kelp::Response> class and not create a subclass.

=back

=head1 SEE ALSO

L<Kelp>

L<Storage::Abstract>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

