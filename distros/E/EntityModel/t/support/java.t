use strict;
use warnings;
use Test::More;
unless(eval { require Inline::Java }) {
	plan skip_all => 'Inline::Java not found';
}
ok('yes', 'this worked');
done_testing;


