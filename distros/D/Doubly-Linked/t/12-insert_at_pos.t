use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert_at_pos(0, { a => 1}));
ok($linked_list = $linked_list->insert_at_pos(1, { b => 2 }));
ok($linked_list->insert_at_pos(2, { c => 3 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);

done_testing();
