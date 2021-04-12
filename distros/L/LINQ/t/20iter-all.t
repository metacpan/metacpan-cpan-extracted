
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<all> method of L<LINQ::Iterator>.

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
	!people->all( sub { $_->name eq 'Elsa' } ),
	'all returning false',
);

ok(
	people->all( sub { $_->name =~ /[aeiou]/i } ),
	'all returning true',
);

ok(
	LINQ( [] )->all( sub { die; } ),
	'all returning true on empty collection without even needing to run check',
);

done_testing;
