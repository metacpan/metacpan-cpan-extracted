use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->start);

is($linked_list->data, 1);
is($linked_list->next->data, 2);
is($linked_list->next->next->data, 3);

done_testing();
