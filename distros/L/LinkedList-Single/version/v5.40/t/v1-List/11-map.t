
use v5.20;

use FindBin::libs;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

# this is deep enough to test the old memory bug.

my @valz    = ( 1 .. 1024 );

use_ok $class;

my $xform   
= sub
{
    my $buffer  = shift;

    @$buffer
};

for my $method ( qw( map copy ) )
{

    my $listh   = $class->new( @valz );
    my $copy    = $listh->map( $xform );

    my $found   = $listh->head_node;
    my $expect  = $copy->head_node;

    diag "\nIgnore recursion depth warnings, they are normal\n";

    cmp_deeply $found, $expect, "'$method' duplicated the list.";
}

done_testing;

# this is not a module

0

__END__
