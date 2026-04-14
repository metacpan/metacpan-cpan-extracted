use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Sort;

subtest 'direction' => sub {
	is(Asc,  'asc',  'Asc');
	is(Desc, 'desc', 'Desc');
};

subtest 'direction meta' => sub {
	my $meta = Direction();
	is($meta->count, 2, '2 directions');
	ok($meta->valid('asc'),  'asc is valid');
	ok($meta->valid('desc'), 'desc is valid');
	ok(!$meta->valid('ASC'), 'ASC is not valid');
};

subtest 'null handling' => sub {
	is(NullsFirst, 'nulls_first', 'NullsFirst');
	is(NullsLast,  'nulls_last',  'NullsLast');
};

subtest 'null handling meta' => sub {
	my $meta = NullHandling();
	is($meta->count, 2, '2 null handling options');
	ok($meta->valid('nulls_first'), 'nulls_first is valid');
	ok($meta->valid('nulls_last'),  'nulls_last is valid');
};

done_testing;
