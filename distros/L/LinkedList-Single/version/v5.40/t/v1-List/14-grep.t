
use v5.20;

use FindBin::libs;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

use_ok $class;

my $count   = 11;
my $listh   = $class->new( 1 .. $count );
my $odds
= sub
{
    my ( $value ) = shift;

    $value % 2
};

my $pass1   = $listh->head->grep( $odds );

ok $pass1, 'Grep returns a list';

note "Initial List:\n", explain $listh->head_node;
note "Copy List:\n", explain $pass1->head_node;

for
(
    $pass1->head,
    my $expect = 1
    ;
    $pass1->has_next
    ;
    $pass1->next
)
{
    my ( $found ) = $pass1->node_data;

    ok $found == $expect  , "Found: '$found' ($expect)";

    $expect     += 2;
}

done_testing;

# this is not a module

0

__END__
