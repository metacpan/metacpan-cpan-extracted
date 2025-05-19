use Test::More;
use Doubly::Linked::PP;

ok(my $linked_list = Doubly::Linked::PP->new());

ok($linked_list->insert_at_start(1));
ok($linked_list = $linked_list->insert_at_end(2));
ok($linked_list->insert_after(3));

ok($linked_list = $linked_list->end);

is($linked_list->is_end, 1);

done_testing();
