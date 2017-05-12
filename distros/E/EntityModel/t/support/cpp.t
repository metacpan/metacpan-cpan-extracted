use strict;
use warnings;
use Test::More;
unless(eval { require Inline::CPP }) {
	plan skip_all => 'Inline::CPP not found';
}
ok('yes', 'this worked');
done_testing;


