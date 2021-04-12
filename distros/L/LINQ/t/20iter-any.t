
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<any> method of L<LINQ::Iterator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );
use DisneyData qw( people pets );

ok(
	people->any( sub { $_->name eq 'Elsa' } ),
	'any returning true',
);

ok(
	!people->any( sub { $_->name eq 'Aurora' } ),
	'any returning false',
);

ok(
	!LINQ( [] )->any( sub { die; } ),
	'any returning false on empty collection without even needing to run check',
);

ok(
	LINQ( [0] )->any,
	'any with no callable returns true if the collection contains anything',
);

done_testing;
