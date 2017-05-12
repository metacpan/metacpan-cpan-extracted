use strict;
use warnings;
use Test::More;
unless(eval { require Inline::Python }) {
	plan skip_all => 'Inline::Python not found';
}
ok('yes', 'this worked');
done_testing;


