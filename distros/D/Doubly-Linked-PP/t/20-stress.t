use Test::More;
use Doubly::Linked::PP;
my $list = Doubly::Linked::PP->new();

$list->bulk_add(1..100000);

my $next = $list->next;
my $next_next = $list->next->next;

is($list->data, 1);

is($next->data, 2);

is($next_next->data, 3);

is($list->length, 100000);

$list->insert_before(100);
$list->insert_after(200);

is($list->data, 1);

is($next->data, 2);

is($next_next->data, 3);

is($list->prev->data, 100);
is($list->next->data, 200);
is($list->next->next->data, 2);

$list->destroy();

is($list->data, undef);

done_testing();
