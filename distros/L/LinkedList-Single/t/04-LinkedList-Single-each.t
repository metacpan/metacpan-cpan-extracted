
use v5.12;

use Test::More;

my $class   = 'LinkedList::Single';

my $count   = $ENV{ EXPENSIVE_TESTS } ? 2**16 : 10;

use_ok $class;

my $listh   = $class->new( 1 .. $count );

$listh->head;

my $i   = 0;

for(;;)
{
    my ( $j ) = $listh->each
    or last;

    ok ++$i == $j, "Found $i ($j)";
}

ok $i == $count, "Found entire list (1 .. $count)";

done_testing;

# this is not a module

0

__END__
