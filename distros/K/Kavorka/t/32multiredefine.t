=pod

=encoding utf-8

=head1 PURPOSE

Test that multi methods can be further defined at run time.

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

use Kavorka qw( multi fun );

multi fun foo (HashRef $x)  { 'hash' }
multi fun foo (ArrayRef $y) { 'array' }

is(
	foo({}),
	'hash',
);

is(
	foo([]),
	'array',
);

like(
	exception { foo(\1) },
	qr{^Arguments to main::foo did not match any known signature for multi sub},
);

multi fun foo (ScalarRef $y) { 'scalar' }

is(
	foo({}),
	'hash',
);

is(
	foo([]),
	'array',
);

is(
	foo(\1),
	'scalar',
);

done_testing;