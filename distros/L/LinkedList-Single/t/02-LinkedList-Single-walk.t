
use v5.12;

use Test::More;
use Scalar::Util    qw( blessed refaddr reftype weaken );

my $class   = 'LinkedList::Single';

use_ok $class;

my $count   = 100;

my $listh   = $class->new( 1 .. $count );

for my $expect ( 1 .. $count )
{
    my ( $found ) = $listh->node_data;

    ok $found == $expect, "Data: $found ($expect)";

    $listh->next;
}

ok
do
{
    my @a   = $listh->node_data;

    ! @a
}, 'List exhausted';

done_testing;

# this is not a module

0

__END__
