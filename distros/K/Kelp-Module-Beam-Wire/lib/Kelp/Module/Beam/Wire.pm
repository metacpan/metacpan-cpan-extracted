package Kelp::Module::Beam::Wire;
$Kelp::Module::Beam::Wire::VERSION = '1.00';
use Kelp::Base 'Kelp::Module';
use Beam::Wire;

sub build
{
	my ($self, %args) = @_;

	my $wire = Beam::Wire->new(%args);
	$wire->set($args{app_service} // 'app', $self->app);

	# register as a sub so that it is avaliable in class context
	$self->register(container => sub { $wire });

	return;
}

1;
__END__

=head1 NAME

Kelp::Module::Beam::Wire - Beam::Wire dependency injection container for Kelp


=head1 SYNOPSIS

	# in config
	modules => [qw(Beam::Wire)],
	modules_init => {
		'Beam::Wire' => {
			# optional, default is 'app'
			app_service => 'myapp',

			# other config for Beam::Wire constructor
		},
	},

	# in your application
	my $app = MyApp->container->get('myapp');

=head1 DESCRIPTION

This is a very straightforward module that registers the C<container> method in
your Kelp app, accessing a constructed Beam::Wire object.

=head1 METHODS INTRODUCED TO KELP

=head2 container

	my $beam_wire = $kelp->container;

Returns the L<Beam::Wire> instance.

=head1 CONFIGURATION

In addition to special behavior of the configuration fields listed below, all
of the configuration from C<modules_init> is fed to L<Beam::Wire> constructor.

=head2 app_service

A name of the service which will hold the instance of the Kelp application
itself. By default, value C<'app'> is used.

Since Kelp is pretty much a singleton (unless you use L<Kelp/new_anon>), you
can introduce this method for easy access to the application instance from the
class name:

	sub {
		shift->container->get('app')
	}


=head1 CAVEATS

Accessing the container from the class name won't work if you use
L<Kelp/new_anon> to instantiate the application.

=head1 SEE ALSO

=over

=item * L<Kelp>, the framework

=item * L<Beam::Wire>, the dependency injection container

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

