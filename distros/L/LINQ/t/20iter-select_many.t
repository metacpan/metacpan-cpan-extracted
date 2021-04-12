
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<select_many> method of L<LINQ::Iterator>.

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

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	"Bee",
	"Cat",
	"Dog",
	"Elephant",
];

is_deeply(
	$collection->select_many(
		sub {
			length >= 4
				? [ substr( $_, 0, 2 ), substr( $_, 2, 2 ) ]
				: [];
		}
	)->to_array,
	[qw/ Aa rd Aa rd El ep /],
	'select_many returning an arrayref',
);

is_deeply(
	$collection->select_many(
		sub {
			length >= 4
				? LINQ [ substr( $_, 0, 2 ), substr( $_, 2, 2 ) ]
				: LINQ [];
		}
	)->to_array,
	[qw/ Aa rd Aa rd El ep /],
	'select_many returning a LINQ::Collection',
);

done_testing;
