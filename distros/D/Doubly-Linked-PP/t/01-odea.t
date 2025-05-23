use Test::More;
use Doubly::Linked::PP;

ok(my $linked_list = Doubly::Linked::PP->new());

ok($linked_list->insert_at_start(1));

is($linked_list->data, 1);

ok(my $keep_list = $linked_list->insert_at_end(2));

is($linked_list->data, 1);
is($keep_list->data, 2);

ok($keep_list->insert_after(3));

is($linked_list->data, 1);
is($keep_list->data, 2);

ok($linked_list = $linked_list->start);

is($linked_list->is_start, 1);

is($linked_list->data, 1);

is($linked_list->next->data, 2);
is($linked_list->next->next->data, 3);

is($linked_list->next->next->is_end, 1);

ok($linked_list->next->remove);

is($linked_list->next->data, 3);

done_testing();
