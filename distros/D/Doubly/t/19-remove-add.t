use Test::More;

use Doubly;

my $list = Doubly->new(10);

ok($list->add($list->remove));

is($list->data, 10);

done_testing;
