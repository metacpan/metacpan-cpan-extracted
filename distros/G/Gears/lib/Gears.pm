package Gears;
$Gears::VERSION = '0.100';
###################################################
# ~~~~~~~~~~ We fear not our mortality ~~~~~~~~~~ #
# ~~~~ We'll serve to the best of our ability ~~~ #
# ~~~~~~ We give our lives to our masters ~~~~~~~ #
# ~~~~~~~~~ We vow to smite our enemies ~~~~~~~~~ #
###################################################

use v5.40;

# TODO: replace with load_module when it stabilizes
use Module::Load qw(load);

# TODO: replace with export_lexically when it stabilizes
use Exporter qw(import);
our @EXPORT_OK = qw(
	load_component
	get_component_name
);

sub load_component ($package)
{
	state %loaded;

	# only load package once for a given class name. Assume components have a
	# new method (avoids Class::Inspector dependency)
	return $loaded{$package} //= do {
		load $package
			unless $package->can('new');
		$package;
	};
}

sub get_component_name ($package, $base)
{
	return "${base}::${package}" =~ s{^.+\^}{}r;
}

__END__

=head1 NAME

Gears - A framework to build web frameworks

=head1 SYNOPSIS

	# Create an application
	package My::App;
	use Mooish::Base;
	extends 'Gears::App';

	# Build routes and components
	sub build ($self)
	{
		$self->load_controller('User');
		$self->load_controller('Blog');
	}

	# Using this package
	use Gears qw(load_component get_component_name);

	my $class = load_component('MyApp::Component::Session');
	my $name = get_component_name('Session', 'MyApp::Component');

=head1 DESCRIPTION

Gears is a toolkit for building web frameworks. It provides the essential
building blocks needed to create structured web applications: an application
container (L<Gears::App>), a component system with lifecycle hooks
(L<Gears::Component>), controllers (L<Gears::Controller>), routing
(L<Gears::Router>), configuration management (L<Gears::Config>), templating
(L<Gears::Template>), logging (L<Gears::Logger>), request context handling
(L<Gears::Context>) and more.

The framework is designed to be flexible and extensible. Rather than being a
complete web framework itself, Gears gives you the tools to build your own
framework with the features and opinions you need. All components follow a
consistent pattern and can be extended or replaced.

The base Gears module provides utility functions, which are not limited to
being used internally by the framework.

=head2 Stability notice

B<Gears is currently in a beta phase> and will stabilize on version
C<1.000>. Until then, no stability promises are made and everything is up for
changing.

=head1 INTERFACE

This package uses exporter and imports no symbols by default.

=head2 load_component

	my $class = load_component($package);

Loads a component class if it hasn't been loaded yet and returns the package
name. Uses a state cache to ensure each package is only loaded once.

If the package already has a C<new> method available, it assumes the package is
already loaded and skips loading. This optimization avoids unnecessary loads
and the dependency on L<Class::Inspector>.

Returns the package name after ensuring it's loaded.

=head2 get_component_name

	my $name = get_component_name($package, $base);

Glues a name of a component which is a subclass of C<$base>. C<$package> will
be joined together with C<$base> to form a full namespace, allowing short names
of the components to be used, for example in configuration. If C<$package>
starts with C<^> character, then C<$base> will not be included in the final
component name at all.

=head1 SEE ALSO

L<Thunderhorse>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

