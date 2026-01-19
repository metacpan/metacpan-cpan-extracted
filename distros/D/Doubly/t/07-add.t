use Test::More;
use Doubly;

ok(my $linked_list = Doubly->new());

ok($linked_list->add({ a => 1}));
ok($linked_list = $linked_list->add({ b => 2 }));
ok($linked_list->add({ c => 3 }));
ok($linked_list->add({ d => 4 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);
is($linked_list->next->next->next->data->{d}, 4);

done_testing();
