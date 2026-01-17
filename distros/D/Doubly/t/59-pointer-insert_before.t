use Test::More;
use Doubly::Pointer;

ok(my $linked_list = Doubly::Pointer->new());

ok($linked_list->insert_before({ c => 3 })); # first always get set
ok($linked_list = $linked_list->insert_before({ b => 2 }));
ok($linked_list->insert_before({ a => 1 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);

done_testing();
