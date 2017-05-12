
use v5.12;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

my @valz    = ( 1 .. 9 );

plan tests => 3;

use_ok $class;

my $listh   = $class->new( @valz );

$listh      += 3;

my $node    = $listh->node;
my $value   = $node->[1];

my $skip    = $listh->new->new_head( $node );

my $head    = $skip->head_node;
my ( $test ) = $skip->head->each;

ok $head == $node,  'Nodes match';
ok $test == $value, 'Head of new list is on value list';

# this is not a module

0

__END__
