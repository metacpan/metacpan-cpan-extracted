use Test::More;
use Doubly::Linked::PP;
my $list = Doubly::Linked::PP->new();

my $nested = Doubly::Linked::PP->new();

$nested->bulk_add(qw/a b c d e f g/);

my $nested2 = Doubly::Linked::PP->new();
$nested2->bulk_add(1..1000, $nested);

$list->bulk_add($nested, $nested2);

$list = $list->start;

is($list->data->data, "a");

is($list->data->next->data, "b");

is($list->next->data->data, 1);
is($list->next->data->end->data->data, 'a');

is($list->next->data->end->data->next->data, 'b');

is($list->next->data->end->data->end->data, 'g');

done_testing();
