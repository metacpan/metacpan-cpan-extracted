
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<average> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

is(
	LINQ( [ 1 .. 7 ] )->average,
	4,
	'simple average',
);

is(
	LINQ( [qw/Aardvark Bee Hawk/] )->average( sub { length( $_ ) } ),
	5,
	'simple average(CODE)',
);

done_testing;
