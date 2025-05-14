use Test::More;
use Doubly;

ok(my $linked_list = Doubly->new());

ok($linked_list->insert_at_start({ c => 3 })); # first always get set
ok($linked_list = $linked_list->insert_at_start({ b => 2 }));
ok($linked_list->insert_at_start({ a => 1 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);

done_testing();
