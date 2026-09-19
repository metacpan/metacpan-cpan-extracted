use v5.24;

use FindBin::libs;

use Test::More;
use Scalar::Util    qw( reftype );

my $madness = 'LinkedList::Single';

SKIP:
{
    use_ok $madness
    or skip "$madness is useless";

    for my $listh ( $madness->new )
    {
        ok $listh->isa( $madness ),     "$listh isa $madness";
        ok 'REF' eq reftype $listh,     "$listh isa ref";

        ok $$listh,                     "$$listh is true";
        ok 'ARRAY' eq reftype $$listh,  "$$listh is an array";
    }

    my @expect
    = qw
    (
        construct
        initialize
        new
        clone
        DESTROY
        truncate
        replace
        curr_node
        node
        set_meta
        add_meta
        get_meta
        has_nodes
        has_next
        is_empty
        clear_node_data
        node_data
        next_data
        clear_data
        list_data
        new_root
        new_head
        root_node
        head_node
        root
        head
        next
        each
        first
        add
        cut
        splice
        push
        unshift
        shift
    );

    for my $proto ( $madness, $madness->new )
    {
        ok $proto->can( $_ ), "$proto can '$_'"
        for @expect;
    }
}

done_testing;

# this is not a module

0

__END__
