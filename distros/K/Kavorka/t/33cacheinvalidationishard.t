=pod

=encoding utf-8

=head1 PURPOSE

Cache invalidation is hard.

The optimized multi sub implementation is a form of caching.

Test that optimizations are invalidated correctly.

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
	use Kavorka qw( multi method );
	
	multi method foo (ArrayRef $x) { 'array' }
}

{
	package Example2;
	use Kavorka qw( multi method );
	
	our @ISA = 'Example';
	
	multi method foo (HashRef $x) { 'hash' }
}

is( Example2->foo({}), 'hash' );
is( Example2->foo([]), 'array' );

like(
	exception { Example2->foo(\1) },
	qr{^Arguments to Example2::foo did not match any known signature for multi sub},
);

# Now we add a new implementation to Example, and check that the
# optimized dispatcher in Example2 gets updated!
{
	package Example;
	use Kavorka qw( multi method );
	
	multi method foo (ScalarRef $x) { 'scalar' }
}

is( Example2->foo({}), 'hash' );
is( Example2->foo([]), 'array' );
is( Example2->foo(\1), 'scalar' );

done_testing;
