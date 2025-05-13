use Test::More;
use Doubly::Linked;
my $list = Doubly::Linked->new();

$list->bulk_add(1..10000);
is($list->length, 10000);
$list->bulk_add(1..10000);
is($list->length, 20000);
$list->bulk_add(1..10000);
is($list->length, 30000);
$list->bulk_add(1..10000);
is($list->length, 40000);
$list->bulk_add(1..10000);
is($list->length, 50000);
$list->bulk_add(1..10000);
is($list->length, 60000);
$list->bulk_add(1..10000);
is($list->length, 70000);
$list->bulk_add(1..10000);
is($list->length, 80000);
$list->bulk_add(1..10000);
is($list->length, 90000);
$list->bulk_add(1..10000);
is($list->length, 100000);

ok($list->start);
is($list->is_start, 1);
is($list->is_end, 0);
is($list->data, 1);

ok($list = $list->end);
is($list->is_start, 0);
is($list->is_end,1);
is($list->data, 10000);

done_testing();
