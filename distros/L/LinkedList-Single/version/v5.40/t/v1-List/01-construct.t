
use v5.12;

use FindBin::libs;

use Test::More;
use Scalar::Util    qw( blessed refaddr reftype weaken );

my $class   = 'LinkedList::Single';

use_ok $class;

ok do
{
    my $listh   = $class->new->head;

    refaddr $$listh == refaddr $listh->head_node
},
"head returns list handler ($class)";

ok do
{
    my $value   = rand;
    my $listh   = $class->new( $value );

    my ( $found ) = $listh->node_data;

    $value == $found 

}, 'new inserts data value';

ok do
{
    # due to bug in older perl, 
    # without the DESTROY handling things gracefully
    # the cleanup fails with the 100-th level of 
    # recursion.
    #
    # newer version simply undefs $$node then removes
    # the root link.
    #
    # weak link is required to validate that the 
    # list is actually destroyed.

    my $size    
    = $ENV{ TEST_BIG_LIST }
    ? 1_000_000
    : 1000
    ;

    note "List size: $size nodes";

    my $listh   = $class->new( 1 .. $size );
    my $root    = $listh->root;

    weaken $root;

    undef $listh;

    not defined $root

}, 'DESTROY cleans up the list';


done_testing;

# this is not a module

0

__END__
