use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

ok($linked_list->insert(sub {}, { c => 3 })); # first always get set
ok($linked_list = $linked_list->insert(sub{ $_[0]->{c} == 3 }, { b => 2 }));
ok($linked_list->insert(sub {$_[0]->{b} == 2}, { a => 1 }));

ok($linked_list = $linked_list->start);

is($linked_list->data->{a}, 1);
is($linked_list->next->data->{b}, 2);
is($linked_list->next->next->data->{c}, 3);

done_testing();
