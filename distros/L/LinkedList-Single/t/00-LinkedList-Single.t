
use v5.12;

use Test::More;
use Scalar::Util    qw( reftype );

my $class   = 'LinkedList::Single';

use_ok $class;

my @expect
= qw
(
    DESTROY
    add
    add_meta
    clear_data
    clone
    construct
    cut
    each
    get_meta
    has_next
    has_nodes
    head
    head_node
    initialize
    is_empty
    new
    new_head
    next
    node
    push
    root
    set_data
    set_meta
    shift
    splice
    truncate
    unshift
);

ok $class->can( $_ ),   "$class can '$_'" for @expect;

my $node    = $class->new;

ok $node->can( $_ ),    "node can '$_'"   for @expect;


ok $node->isa( $class ),        'node isa $class';
ok 'REF' eq reftype $node,      '$node is a ref';

ok $$node,                      '$$node is true';
ok 'ARRAY' eq reftype $$node,   '$$node is an array';

undef $node;

ok ! $node,                     "Node is false";

done_testing;

# this is not a module

0

__END__
