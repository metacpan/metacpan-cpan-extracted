
use v5.20;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

# this is deep enough to test the old memory bug.

use_ok $class;

my $listh   = $class->new->root;
my $count   = 11;

$listh->add( $_ )->next
for
(
    1 .. $count
);

note "Initial List:\n", explain $listh->head_node;

my $expect  = 1;

for
(
    $listh->head
    ;
    $listh->has_next
    ;
    $listh->next
)
{
    my ( $found ) = $listh->node_data;

    ok $found == $expect, "Found: '$found' ($expect)";

    ++$expect;
}

my $odds
= sub
{
    my $val = shift;
    $val % 2
};

ok $listh->prune( $odds ), 'Prune returns true.';

note "Pruned List:\n", explain $listh->head_node;

$expect     = 1;

for
(
    $listh->head
    ;
    $listh->has_next
    ;
    $listh->next
)
{
    my ( $found ) = $listh->node_data;

    ok $found == $expect  , "Found: '$found' ($expect)";

    $expect     += 2;
}

done_testing;

# this is not a module

0

__END__
