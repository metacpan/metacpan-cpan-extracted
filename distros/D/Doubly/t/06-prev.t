use Test::More;
use Doubly;

ok(my $linked_list = Doubly->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->end);

is($linked_list->data, 3);
is($linked_list->prev->data, 2);
is($linked_list->prev->prev->data, 1);

done_testing();
