use Test::More;

use Doubly::Pointer;

my $list = Doubly::Pointer->new(10);

ok($list->add($list->remove));

is($list->data, 10);

done_testing;
