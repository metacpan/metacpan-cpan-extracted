use Test::More;

BEGIN{
        use_ok('List::Priority');
}

my $list = List::Priority->new();

is($list->size(), 0, "Newly created list is empty");

$list->insert(2,'World!');
$list->insert(5,'Hello');
$list->insert(3,' ');

is($list->size(), 3, "Size of list is 3");

is($list->pop(), 'Hello', 'Most important element');
is($list->size(), 2, "Size of list is 2 after popping");

my $error = $list->insert(2,'World!');
is($list->size(), 3, "Duplicate elements can be added");
is($list->shift(), 'World!', 'Duplicate element removed');

for my $count (6..12) {
        $list->insert($count, "element$count");
        $list->insert($count, "second$count");
}
is($list->size(), 16, "Size of list is now 16");

is($list->shift(), 'World!', 'Least important element');
is($list->size(), 15, "Size lowered by shifting");

done_testing;
