use Modern::Perl;
package Intertangle::API::Glib;
# ABSTRACT: Helper for using Glib
$Intertangle::API::Glib::VERSION = '0.001';
use strict;
use warnings;

use Glib;
use List::MoreUtils qw(zip);

sub Inline  {
	return unless $_[-1] eq 'C';

	require ExtUtils::Depends;
	my $ref = ExtUtils::Depends::load('Glib');

	my $config = +{ map { uc($_) => $ref->{$_} } qw(inc libs typemaps) };

	# Set CCFLAGSEX to the value of INC directly. This is to get around some
	# shell parsing / quoting bug that causes INC to quote parts that
	# should not be quoted.
	$config->{CCFLAGSEX} = delete $config->{INC};

	# Add the Glib.pm dynamic library to access the `gperl` symbols. This
	# is usually handled automatically by simply loading Glib.pm via
	# DynaLoader, but on Windows, it must be explicitly linked.
	if( $^O eq 'MSWin32') {
		my %dl_module_to_so = zip( @DynaLoader::dl_modules, @DynaLoader::dl_shared_objects );
		$config->{MYEXTLIB} = $dl_module_to_so{Glib};
	}

	$config->{AUTO_INCLUDE} = <<C;
#include <gperl.h>
C

	$config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Glib - Helper for using Glib

=head1 VERSION

version 0.001

=head1 METHODS

=head2 Inline

  use Inline C with => qw(Intertangle::API::Glib);

Returns the flags needed to configure L<Inline::C> for using the
L<Glib> XS API.

=head1 SEE ALSO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
