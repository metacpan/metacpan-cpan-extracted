=pod

=encoding utf-8

=head1 PURPOSE

Test the C<fresh> and C<override> traits for subs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

package Example1 {
	use Moo;
	use Scalar::Util qw(blessed);
}

package R1 {
	use Moo::Role;
	use Kavorka;
	method blammo () { 2 }
}

package Example2 {
	use Moo;
	use Kavorka;
	extends 'Example1';
	with 'R1';
	
	::like(
		::exception {
			method blessed () is fresh { 1 }
		},
		qr/^Method 'blessed' already exists in inheritance hierarchy; possible namespace pollution; not fresh/,
		"the `fresh` trait complains about overriding namespace pollution",
	);
	
	::is(
		::exception {
			method blasted () is fresh { 1 }
		},
		undef,
		"the `fresh` trait does not complain when installing a fresh, new method",
	);
}

package Example3 {
	use Moo;
	use Kavorka;
	extends 'Example2';
	
	::like(
		::exception {
			method blasted () is fresh { 1 }
		},
		qr/^Method 'blasted' is inherited from 'Example2'; not fresh/,
		"the `fresh` trait complains about overriding methods in superclass",
	);
	
	::like(
		::exception {
			method blammo () is fresh { 1 }
		},
		qr/^Method 'blammo' is provided by role 'R1'; not fresh/,
		"the `fresh` trait complains about overriding methods already provided by a role",
	);
	
	::is(
		::exception {
			method blasted () is override { 1 }
		},
		undef,
		"the `override` trait does not complain when overriding methods in superclass",
	);
	
	::is(
		::exception {
			method blammo () is override { 1 }
		},
		undef,
		"the `override` trait does not complain when overriding methods already provided by a role",
	);
	
	::like(
		::exception {
			method blighty () is override { 1 }
		},
		qr/^Method 'blighty' does not exist in inheritance hierarchy; cannot override/,
		"the `override` trait complains when installing a fresh, new method",
	);
}

done_testing;

