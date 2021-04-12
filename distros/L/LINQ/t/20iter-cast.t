
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<cast> method of L<LINQ::Iterator>.

=head1 DEPENDENCIES

This test requires L<Types::Standard>. It will be skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern -requires => { 'Types::Standard' => 0 };
use LINQ qw( LINQ );
use Types::Standard -types;

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	6,
	"Bee",
	"Cat",
	9,
	"Dog",
	"Elephant",
	3.14,
];

object_ok(
	sub {
		return exception {
			$collection->cast( Int )->to_array,
		};
	},
	'$e',
	isa  => [qw( LINQ::Exception LINQ::Exception::Cast )],
	can  => [qw( message collection type )],
	more => sub {
		my $e = shift;
		is( $e->collection, $collection, '$e->collection' );
		is( $e->type,       Int,         '$e->type' );
	},
);

my $Rounded = Int->plus_coercions( Num, sub { int( $_ ) } );

object_ok(
	sub {
		return exception {
			$collection->cast( $Rounded )->to_array;
		};
	},
	'$e',
	isa  => [qw( LINQ::Exception LINQ::Exception::Cast )],
	can  => [qw( message collection type )],
	more => sub {
		my $e = shift;
		is( $e->collection, $collection, '$e->collection' );
		is( $e->type,       $Rounded,    '$e->type' );
	},
);

my $Rounded2 = Int->plus_coercions(
	Num, sub { int( $_ ) },
	Any, sub { 0 },
);

is_deeply(
	$collection->cast( $Rounded2 )->to_array,
	[qw/ 0 0 6 0 0 9 0 0 3 /],
	'successful cast'
);

done_testing;
