package Kelp::Module::Raisin;

our $VERSION = '1.00';

use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
use Plack::Util;
use Scalar::Util qw(blessed);

sub name { 'raisin' }

# since Raisin::API is really a singleton we have to keep it that way. If we
# wouldn't, test suite would be full of Raisin route redefinition warnings and
# would likely lead to buggy code
my $psgi;

sub psgi
{
	my ($self) = @_;

	return $psgi //= $self->app->raisin->run;
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);

	die 'Raisin module requires "class" configuration'
		unless $args{class};

	my $class = Plack::Util::load_class($args{class});

	# let it bug out with regular error message if it can't app
	my $raisin = $class->app;
	die "$class not isa Raisin"
		unless defined blessed $raisin && $raisin->isa('Raisin');

	$self->register(raisin => $raisin);
}

1;
__END__

=head1 NAME

Kelp::Module::Raisin - Raisin integration with Kelp

=head1 SYNOPSIS

	# in config - order matters
	modules => [qw(Symbiosis Raisin)],
	modules_init => {
		# optional
		Symbiosis => {
			mount => '/path', # will mount Kelp under /path
		},

		# required
		Raisin => {
			mount => '/api', # will mount Raisin under /api
			class => 'My::Raisin', # required - full class name of Raisin app
		},
	},

	# in application's build method
	$self->raisin->add_route(
		method => 'GET',
		path => '/from-kelp',
		params => {},
		code => sub { 'Hello World from Kelp, in Raisin!' },
	);

	# in psgi script
	$app = MyKelpApp->new;
	$app->run_all;


=head1 DESCRIPTION

This is a very straightforward module that integrates the L<Kelp> framework with the L<Raisin> API framework using L<Kelp::Module::Symbiosis>. See the documentation for L<Kelp::Module::Symbiosis> and L<Kelp::Module::Symbiosis::Base> for a full reference on how this module behaves.

=head1 MODULE INFORMATION

This module name is I<'raisin'>. You can refer to it with that name in Symbiosis methods - I<loaded> and I<mounted>. There shouldn't be a need to, since it will be mounted automatically if you specify L</mount> in configuration.

The module class itself does not expose anything particularly interesting, it is just a wrapper for Raisin.

=head1 METHODS INTRODUCED TO KELP

=head2 raisin

	my $raisin = $kelp->raisin;

Returns the running instance of Raisin.

=head1 CONFIGURATION

=head2 middleware, middleware_init

Same as L<Kelp::Module::Symbiosis::Base/middleware, middleware_init>. Since Raisin can wrap itself in its own middleware it will likely not be that useful.

=head2 mount

See L<Kelp::Module::Symbiosis::Base/mount> for details.

=head2 class

Should be a full name of the package that defines an api using L<Raisin::API>. Keep in mind that Raisin::API is really a singleton so it is not suitable for multiple app setup.

=head1 SEE ALSO

=over 2

=item * L<Kelp>, the framework

=item * L<Raisin>, the API framework

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
