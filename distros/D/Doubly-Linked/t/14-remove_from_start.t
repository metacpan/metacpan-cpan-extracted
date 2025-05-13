use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->end);

is($linked_list->is_end, 1);

is($linked_list->data, 3);

is($linked_list->prev->data, 2);
is($linked_list->prev->prev->data, 1);

ok($linked_list->remove_from_start);

is($linked_list->data, 3);

ok($linked_list->remove_from_start);

is($linked_list->data, 3);

ok($linked_list->remove_from_start);

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->start);

ok($linked_list->remove_from_start);

is($linked_list->data, 2);

ok($linked_list->remove_from_start);

is($linked_list->data, 3);

ok($linked_list->remove_from_start);

done_testing();

