use Test::More;
use Doubly::Pointer;

ok(my $linked_list = Doubly::Pointer->new());

ok($linked_list->add({ a => 1}));
ok($linked_list = $linked_list->add({ b => 2 }));
ok($linked_list->add({ c => 3 }));

ok($linked_list = $linked_list->start);

is($linked_list->find(sub { $_[0]->{b} == 2 })->data->{b}, 2);

done_testing();
