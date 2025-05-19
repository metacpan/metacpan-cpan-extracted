use Test::More;

use Doubly::Linked::PP;

my $list = Doubly::Linked::PP->new(10);

ok($list->add($list->remove));

is($list->data, 10);

done_testing;
