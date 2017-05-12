#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

use Frost::Asylum;
use Frost::Util;

$Frost::Util::UUID_CLEAR	= 1;		#	delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing

$Data::Dumper::Deparse	= true;

our $ASYL;

$ASYL = Frost::Asylum->new ( data_root => $TMP_PATH );

#	from Moose-1.14/t/200_examples/005_example_w_TestDeep.t

=pod

This tests how well Moose type constraints
play with Test::Deep.

Its not as pretty as Declare::Constraints::Simple,
but it is not completely horrid either.

=cut

use Test::Requires {
	'Test::Deep' => '0.01', # skip all if not installed
};

use Test::Exception;

{
	package Foo;
#	use Moose;
	use Frost;
	use Moose::Util::TypeConstraints;

	use Test::Deep qw[
		eq_deeply array_each subhashof ignore
	];

	# define your own type ...
	type 'ArrayOfHashOfBarsAndRandomNumbers'
		=> where {
			eq_deeply($_,
				array_each(
					subhashof({
						bar				=> Test::Deep::isa('Bar'),
						random_number	=> ignore()
					})
				)
			)
		};

	has id => ( auto_id => 1 );

	has 'bar' => (
		is  => 'rw',
		isa => 'ArrayOfHashOfBarsAndRandomNumbers',
	);

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Bar;
#	use Moose;
	use Frost;

	has id => ( auto_id => 1 );

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $array_of_hashes = [
#	{ bar => Bar->new, random_number => 10 },
#	{ bar => Bar->new },
	{ bar => Bar->new ( asylum => $ASYL ), random_number => 10 },
	{ bar => Bar->new ( asylum => $ASYL ) },
];

my $foo;
lives_ok {
#	$foo = Foo->new('bar' => $array_of_hashes);
	$foo = Foo->new('bar' => $array_of_hashes, asylum => $ASYL);
} '... construction succeeded';
isa_ok($foo, 'Foo');

#DEBUG Dump [ $foo, $foo->bar, $array_of_hashes ], [qw( foo foo_bar array)];

#	is_deeply($foo->bar, $array_of_hashes, '... got our value correctly');
#     Structures begin differing at:
#          $got->[0]{bar}{_status} = 'exists'
#     $expected->[0]{bar}{_status} = 'missing'
#
ok(
eq_deeply($foo->bar,
				array_each(
					subhashof({
						bar				=> Test::Deep::isa('Bar'),
						random_number	=> ignore()
					})
				))
, '... got our value correctly' );

dies_ok {
	$foo->bar({});
} '... validation failed correctly';

dies_ok {
	$foo->bar([{ foo => 3 }]);
} '... validation failed correctly';

done_testing;
