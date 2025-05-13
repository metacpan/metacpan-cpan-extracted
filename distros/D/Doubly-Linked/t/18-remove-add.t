use Test::More;

use Doubly::Linked;

my $list = Doubly::Linked->new(10);

ok($list->add($list->remove));

is($list->data, 10);

done_testing;
