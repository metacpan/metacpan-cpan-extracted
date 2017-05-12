package Devel::MRO;

use 5.008_001;
use strict;

our $VERSION = '0.05';

# all features in mro_compat.h

1;
__END__

=for stopwords mro gfx API pre

=head1 NAME

Devel::MRO - Provides mro functions for XS modules

=head1 VERSION

This document describes Devel::MRO version 0.05.

=head1 SYNOPSIS

	# In your XS distribution

	# Add the following to your Makefile.PL
	use inc::Module::Install;
	use ExtUtils::Depends;
	# ...
	requires 'MRO::Compat' if $] < 5.010_000;

	include 'ExtUtils::Depends';
	my $pkg = ExtUtils::Depends->new('Your::Module', 'Devel::MRO');
	# ...

	WriteMakefile(
		$pkg->get_makefile_vars,
		# ...
	);

	/* Then put the "include" directive in your Module.xs */

	/* ... */
	#include "ppport.h"

	#define NEED_mro_get_linear_isa /* or NEED_mro_get_linear_isa_GLOBAL */
	#include "mro_compat.h"

	/* Now you can use several mro functions in your Module.xs:
		mro_get_linear_isa()
		mro_get_pkg_gen()
		mro_method_changed_in()
	*/

=head1 DESCRIPTION

C<Devel::MRO> provides several mro functions for XS modules.

This module provides only a header file, B<mro_compat.h>, so you need not load
it in your modules.

=head1 XS interface

=head2 AV* mro_get_linear_isa(HV* stash)

The same as C<mro::get_linear_isa()> in Perl.

In 5.10 or later, it is just a public Perl API.

In pre-5.10 it calls C<mro::get_linear_isa> provided by C<MRO::Compat>. It has a
cache mechanism as Perl 5.10 does, so it is much faster than the direct call of
C<MRO::Compat>'s C<mro::get_linear_isa>.

=head2 void mro_method_changed_in(HV* stash)

The same as C<mro::method_changed_in()> in Perl.

=head2 U32 mro_get_pkg_gen(HV* stash)

The same as C<mro::get_pkg_gen()> in Perl. This is not a Perl API.

This may evaluate I<stash> more than once.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

ExtUtils::Depends.

MRO::Compat if Perl version < 5.10.0.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji(gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 SEE ALSO

L<mro>.

L<MRO::Compat>.

L<perlapi/"MRO Functions">.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
