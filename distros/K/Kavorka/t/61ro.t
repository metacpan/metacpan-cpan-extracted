=pod

=encoding utf-8

=head1 PURPOSE

Test the C<ro> trait.

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

{
	package Example;
	use Kavorka;
	
	fun foo ($x but ro) {
		++$x;
	}
	
	fun bar ($x is rw) {
		++$x;
	}
}

like(
	exception { Example::foo(42) },
	qr{^Modification of a read-only value attempted },
);

is(
	Example::bar(42),
	43,
);

done_testing;

