use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert_after({ a => 1}));
ok($linked_list = $linked_list->insert_after({ b => 2 }));
ok($linked_list->insert_after({ c => 3 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);

done_testing();
