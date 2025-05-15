use Test::More;
use Doubly;
my $list = Doubly->new();

$list->bulk_add(1..100000);

is($list->data, 1);

is($list->length, 100000);

ok($list = $list->end);

is($list->data, 100000);

is($list->prev->data, 99999);

$list->destroy();

is($list->data, undef);

done_testing();
