
use v5.20;

use FindBin::libs;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

# this is deep enough to test the old memory bug.

use_ok $class;

my $listh   = $class->new->root;
my $count   = 11;

$_ % 2
? $listh->add( $_ )->next
: $listh->add(    )->next
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

    $expect % 2
    ? ok $found == $expect  , "Found: '$found' ($expect)"
    : ok ! $found           , "Found: '$found' ()"
    ;

    ++$expect;
}

ok $listh->prune, 'Prune returns true.';

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
