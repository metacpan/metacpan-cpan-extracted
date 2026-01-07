package Gears;
$Gears::VERSION = '0.001';
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

	use Gears;

	# do something

=head1 DESCRIPTION

This module delivers basic parts of a web framework.

This is a stub release which will be fully documented later. Stay tuned.

=head1 SEE ALSO

L<Thunderhorse>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

