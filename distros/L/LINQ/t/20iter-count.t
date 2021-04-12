
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<count> method of L<LINQ::Iterator>.

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

is(
	LINQ( [qw/Aardvark Bee Hawk/] )->count,
	3,
	'simple count',
);

is(
	LINQ( [qw//] )->count,
	0,
	'simple count == 0',
);

is(
	LINQ( [qw/Aardvark Bee Hawk/] )->count( sub { $_ =~ $_[0] }, qr/a/ ),
	2,
	'count(CODE)',
);

done_testing;
