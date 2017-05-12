=pod

=encoding utf-8

=head1 PURPOSE

Test multi methods with multiple inheritance.

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
	package AAA;
	our @ISA = qw( BBB CCC );
}

{
	package BBB;
	use Kavorka qw( multi method );
	
	multi method foo (HashRef $x) {
		return 'HashRef';
	}
}

{
	package CCC;
	use Kavorka qw( multi method );
	
	multi method foo (ArrayRef $x) {
		return 'ArrayRef';
	}
}

is( AAA->foo( {} ), 'HashRef' );
is( AAA->foo( [] ), 'ArrayRef' );

is( AAA->BBB::foo( {} ), 'HashRef' );
is( BBB::foo( AAA => {} ), 'HashRef' );

{
	local $TODO = "I don't think it's possible to detect whether the method has been invoked this way";
	ok( exception { AAA->BBB::foo( {} ) } );
	ok( exception { BBB::foo( AAA => {} ) } );
};

done_testing;
