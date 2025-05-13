use Test::More;
use Doubly::Linked;

ok(my $linked_list = Doubly::Linked->new());

is($linked_list->data, undef);

ok($linked_list->data(1));

is($linked_list->data, 1);

ok($linked_list->data({ a => 1}));

is_deeply($linked_list->data, { a =>1 });

ok($linked_list->data([1,2,3]));

is_deeply($linked_list->data, [1,2,3]);

ok($linked_list->data(sub { 1 }));

is($linked_list->data->(), 1);

ok($linked_list = Doubly::Linked->new(100));

is($linked_list->data, 100);

done_testing();
