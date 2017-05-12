use strict;
use warnings;
use Test::More;
unless(eval { require Inline::C }) {
	plan skip_all => 'Inline::C not found';
}
ok('yes', 'this worked');
done_testing;


