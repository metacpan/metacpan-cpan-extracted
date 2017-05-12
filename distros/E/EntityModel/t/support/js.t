use strict;
use warnings;
use Test::More;
unless(eval { require JavaScript::V8 }) {
	plan skip_all => 'JavaScript::V8 not found';
}
ok('yes', 'this worked');
done_testing;

