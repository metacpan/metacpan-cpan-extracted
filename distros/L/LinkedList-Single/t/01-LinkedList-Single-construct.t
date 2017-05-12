
use v5.12;

use Test::More;
use Scalar::Util    qw( blessed refaddr reftype weaken );

my $class   = 'LinkedList::Single';

use_ok $class;

ok do
{
    my $listh   = $class->new;
    my $sanity  = $listh->head;

    refaddr $listh == refaddr $sanity
},
"head returns list handler ($class)";

ok do
{
    my $listh   = $class->new( 1 );

    my ( $found ) = $listh->node_data;

    1 == $found 

}, 'new inserts data value';

ok do
{
    # without the DESTROY handling things gracefully
    # the cleanup fails with the 100-th level of 
    # recursion.

    my $listh   = $class->new( 1 .. 200 );

    my $head    = $listh->root;

    weaken $head;

    undef $listh;

    not defined $head

}, 'DESTROY cleans up the list';


done_testing;

# this is not a module

0

__END__
