use Test::More;
use Doubly::Pointer;

ok(my $linked_list = Doubly::Pointer->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->start);

is($linked_list->is_start, 1);

ok($linked_list->remove_from_end);

ok($linked_list->remove_from_end);

ok($linked_list->remove_from_end);

is($linked_list->remove_from_start, undef);

ok(my $linked_list = Doubly::Pointer->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->end);

is($linked_list->is_end, 1);

ok($linked_list->remove_from_end);

ok($linked_list->remove_from_end);

ok($linked_list->remove_from_end);

is($linked_list->remove_from_start, undef);





done_testing();

