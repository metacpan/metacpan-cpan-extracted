=pod

=encoding utf-8

=head1 PURPOSE

Check C<:lvalue> works for C<fun> keyword.

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
	
	fun foo () :lvalue { $Example::FOO }
}

$Example::FOO = 42;

is(Example::foo(), 42);

Example::foo()++;

is(Example::foo(), 43);
is($Example::FOO, 43);

done_testing;

