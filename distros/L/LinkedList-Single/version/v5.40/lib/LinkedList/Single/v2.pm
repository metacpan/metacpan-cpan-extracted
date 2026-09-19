########################################################################
# housekeeping
########################################################################

package LinkedList::Single  v2.0.0;
use v5.40;
use FindBin::libs;

use Object::Pad v0.821;

use Carp            qw( croak                   );
use Data::Dumper    qw( Dumper                  );
use Sub::Name       qw( subname                 );
use Symbol          qw( qualify qualify_to_ref  );

my $nmgr_r  = qualify 'NodeMgr';

my $list_c  = qualify 'List';
my $curs_c  = qualify 'Cursor';
my $frag_c  = qualify 'Fragment';

sub new
{
    $list_c->new
}

########################################################################
# package varaibles and sanity checks
########################################################################

our @CARP_NOT   = qw( $nmgr_r $list_c $curs_c $frag_c );

########################################################################
# utility subs
########################################################################

########################################################################
# general purpose

my $dump_format
= sub
{
    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Indent     = 1;
    local $Data::Dumper::Sortkeys   = 1;

    local $Data::Dumper::Purity     = 0;
    local $Data::Dumper::Deepcopy   = 0;
    local $Data::Dumper::Quotekeys  = 0;

    join "\n\t" => '', map { ref $_ ? Dumper $_ : $_ } @_
};

########################################################################
# private methods for unwrapping the node structure that simplify
# managing the classes. any modification to the structure in
# NodeMgr will need to be reflected in these kwikhaks or pushed
# down into NodeMgr calls.

# some of these are used externally for tesitng

my $node_data
= subname node_data
=> sub( $node )
{
    # data for the root node can be used for list
    # metadata for the list and always exists.
    #
    # cursors return whatever's in the current node,
    # croaking on the sentinel.

    $node->@*
    or croak 'Bogus $node: sentinel';

    wantarray // return;
    wantarray
    ?   $node->@[ 1 .. $#$node ]
    : [ $node->@[ 1 .. $#$node ] ]
};

my $drop_node
= subname drop
=> sub( $node )
{
    # $next keeps the node contents alive long enough
    # to return the data.

    my $next = $node->[0]
    or croak 'Bogus drop_node at sentinel node';

    $next->@*
    ? $node->[0]  = $next->[0]
    : croak 'Bogus drop next is sentinel'
    ;

    $next->$node_data
};

my $append
= subname append
=> sub( $node, @data )
{
    $node->[0]  = [ $node->[0], @data ];
};

my $sentinel_node
= subname sentinel_node
=> sub()
{
    []
};

########################################################################
# Object Managlement
########################################################################

role LinkedList::Single::NodeMgr
{
    # Note: operations that unwrap the object contents
    # belong here, shared by any classes that have to
    # manipulate nodes. things like "$obj->node = $obj->next"
    # that don't manipulate the object guts abound in
    # the Cursor class, but nowhere there are $node
    # internals examined outside of this role.

    ############################################################
    # housekeeping
    ############################################################

    use Carp            qw( croak           );
    use Scalar::Util    qw( blessed reftype );

    our @CARP_NOT   = ( __PACKAGE__, qw( Object::Pad ) );

    ############################################################
    # definition
    ############################################################

    field $node;    # notice the lack of a default

    method object_type()
    {
        # classes can override this to provide more
        # info (e.g., "List::Circular").
        #
        # return $type to simplify handling in a scalar
        # context.

        my ( $type ) = $self->META->name =~ m{ (\w+) $}x;

        $type
    }

    ############################################################
    # construct the object
    ############################################################

    ADJUST :params ( :$whence = undef )
    {
        my $name    = $self->META->name;

        # this could be spread across the classes, simpler to
        # have it here. note that if-logic needs to proceed
        # from most-to-least derived.

        if( $self->isa( $list_c ) )
        {
            $whence
            and croak "Botched $name: extraneous 'whence' argument";

            $node   = $sentinel_node->();
        }
        elsif( $self->isa( $curs_c ) )
        {
            # cursors require and object, not a bare node.
            # note that this intentionally will create a
            # cursor to an empty list in order to support
            # the sentinel and *_lazy methods.

            blessed $whence
            or croak "Botched $name: '$whence' is not an object";

            $whence->DOES( $nmgr_r )
            or croak "Botched $name: '$whence' does not $nmgr_r";

            $node   = $whence->node;
        }
        elsif( $self->isa( $frag_c ) )
        {
            if( $whence )
            {
                state $sent_type    = reftype $sentinel_node->();

                # fragments require a bare node, normally
                # as a by-product of detach.

                blessed $whence
                and croak "Botched $name: '$whence' is not a bare node.";

                reftype $whence eq $sent_type
                or croak "Botched $name: '$whence' is not '$sent_type'";

                $node   = [ splice $whence->@* ];
            }
            else
            {
                # empty fragment is reasonable,
                # e.g., generate_lazy().

                $node   = $sentinel_node->();
            }
        }
        else
        {
            croak "Unknown class: none of $list_c, $curs_c, $frag_c";
        }
    }

    method cursor()
    {
        $curs_c->new( whence => $self )
    }

    method fragment()
    {
        $frag_c->new( whence => $self->node )
    }

    method list()
    {
        $self
        ->fragment
        ->push_onto
        (
            $list_c->new
        )
    }

    ############################################################
    # introspection
    ############################################################
    # calling them 'car/cdr' seemed a bit obscure; 'next' and
    # 'data' seemed more approachable.
    #
    # these are data leaks to some extent; workable so long as
    # caller's don't inspect the contents of what's returned
    # for the node.

    method node :lvalue
    {
        # ideally "my method node", but that doesn't work
        # in O::P yet. sans the private method is is where
        # the internal data structure leaks out.
        #
        # use to transfer node value between objects:
        # $node = $whence->node.

        $node
    }

    method next_node :lvalue
    {
        $node->[0]
    };

    method tail_node()
    {
        $node->@*
        or croak 'Bogus tail_node at sentinel';

        my $tail    = $node;

        for
        (
            my $next    = $tail->[0]
          ; $next->@*
          ; $next       = $next->[0]
        )
        {
            $tail   = $next;
        }


        $tail
    }

    method is_sentinel()
    {
        ! $node->@*
    }

    method count()
    {
        # sentinel short-curcuits the ++$i, leaves
        # the count at zero.

        my $i       = 0;
        my $curr    = $node;

        ++$i    while ( $curr ) = $curr->@*;

        $i
    }

    ############################################################
    # node data

    method data()
    {
        $node->@*
        or croak 'Bogus data: at sentinel';

        my $wa = wantarray
        // croak 'Botched data: used in void context';

        $wa
        ?   $node->@[ 1 .. $#$node ]
        : [ $node->@[ 1 .. $#$node ] ]
    }

    method next_data()
    {
        my $next    = $node->[0]
        or croak 'Bogus next_data at sentinel';

        my $wa = wantarray
        // croak 'Botched next_data: used in void context';

        $wa
        ?   $next->@[ 1 .. $#$next ]
        : [ $next->@[ 1 .. $#$next ] ]
    }

    method set_data
    {
        # this can set the sentinal node,
        # effectivly making it a push.

        $node->@*   = ( $node->[0] || $sentinel_node->(), @_ );

        $self
    }

    method push_data
    {
        push $node->@*, @_;

        $self
    }

    ############################################################
    # obvious locations along the list.
    # head lives with the list as that is the only place
    # we are guaranteed to find it.

    method next( $count = 1 )
    {
        my $curs    = $self->cursor;

        $count
        and do
        {
            $count > 0
            or croak "Botched next: negative count '$count'";

            my $next    = $node;
            $next       = $next->[0] for ( 1 .. $count );

            $curs->node = $next;
        };

        $curs
    }

    method tail()
    {
        my $curs    = $self->cursor;
        $curs->node = $curs->tail_node;

        $curs
    }

    method sentinel()
    {
        # this may not advance at all for an empty list or
        # cursor at the sentinel already.
        #
        # bit less work than tail since it dosn't have to
        # check the following node, only the current one.

        my $curs    = $self->cursor;
        $curs->node
        = do
        {
            my $sent    = $node;
            $sent       = $sent->[0] while $sent->@*;
            $sent
        };

        $curs
    }

    ############################################################
    # modify the sequnce of nodes
    #
    # insert has a bit more overhead due to copying the values,
    # useully not enough differnce to notice.
    #
    # push/pop make sense on a cursor and live here; shift and
    # unshift only make sense on a list and live there.

    method push
    {
        if( $node->@* )
        {
            $self->tail->append( @_ )
        }
        else
        {
            # push at the sentinel still works, just
            # moves the sentinel out one node..

            $node->@*   = ( $sentinel_node->(), @_ );
        }

        $self
    }

    method pop()
    {
        $self
        or croak "Bogus pop at sentinel";

        $self->tail->delete
    }

    method insert
    {
        # insert a new node prior to this one.
        # the [] allocate new storage with the
        # value of $ref as the next node and
        # the new data passed in.
        #
        # this is more expensive than append due to
        # copying $node->@*.
        # generally, prefer append; but this is
        # allowable at the sentinel and makes sense
        # for a list.

        $node->@*   = ( [ $node->@* ], @_ );
        $self
    }

    method reverse
    {
        $node->@*
        or return $self;

        # effectively $self->unshift( $tmp->shift )
        # without all of the method call overhead.
        #
        # $next buffers $tmp->next while $head gets
        # moved to the new list.

        my $head    = $self->fragment->node;
        my $next    = '';

        while( $head->@* )
        {
            $next   = splice $head->@*, 0, 1, $node;
            $node   = $head;
            $head   = $next
        }

        $self
    }

    method generate_lazy( $generator )
    {
        # ignore $self this just generates a fragment.

        my $frag    = $frag_c->new;

        try
        {
            # push whatever the generator hands us, which
            # may be empty, until it does a 'die "\n"',
            # interruping the assignment, leaving $node as
            # the sentinel.

            for( my $node = $frag->node ;; )
            {
                ( $node ) =
                (
                    $node->@* = ( $sentinel_node->(), $generator->() )
                )
            }
        }
        catch( $err )
        {
            # anything other than a newline is a 'real'
            # exception and has to be passed on.

            $err eq "\n"
            or croak "Failed append_lazy: $err";
        }

        $frag
    }

    method append_lazy( $generator )
    {
        # can't append_to an empty list/sentinel: if $self
        # is false then use insert.

        $self
        ? $self->generate_lazy( $generator )->append_to( $self )
        : $self->generate_lazy( $generator )->insert_at( $self )
    }

    method insert_lazy( $generator )
    {
        # unshift_lazy == $list->head->insert_lazy

        $self->generate_lazy( $generator )->insert_at( $self )
    }

    method push_lazy( $generator )
    {
        $self->sentinel->insert_lazy( $generator )
    }

    method push_list( @valz )
    {
        $self->push_lazy
        (
            sub
            {
                @valz or die "\n";
                shift @valz
            }
        )
    }

    method transfer_node( $thence )
    {
        $thence->node->@*   = splice $node->@*;
        $self
    }

    ############################################################
    #
    # delete    == 'delete key' == remove $node node.
    # drop      == backspace    == remove next node.
    #
    # $list->head->delete   == shift;
    # $list->tail->drop     == pop;
    #
    # the head is extraneous since lists cannot move, but you
    # get the point.
    #
    ############################################################

    method delete()
    {
        # delete the current node, replacing it with the
        # contents of the next node.
        #
        # Note: this may leave the current node as the
        # sentinel.
        #
        # Note: drop is more efficient since it doesn't
        # copy both node contents, only the next ref.
        #
        # Note: delete on a list == shift; the difference
        # being that "shift" is always at the head.

        my $next = $node->[0]
        or croak 'Bogus delete at sentinel';

        if( defined wantarray )
        {
            # 1 .. $#$node == skip the next ref, only data.
            (
                splice $node->@*, 0, 1+$#$node, $next->@*
            )[1..$#$node]
        }
        else
        {
            $node->@*   = $next->@*
        }
    }

# sanity check: is the 1..$self->count any worse than
# using push (in map)? if not then all we need is map
# with a default of "sub{ @_ }". benchmark this with
# some really large lists before leaving it in.

    # bulk extract the list contents into a single flat
    # list or list of arrayrefs.

    method flat_list()
    {
        defined( my $wa  = wantarray )
        or croak 'Bogus extract: used in void context';

        $self
        or return;

        my @data    = ();
        my $node    = $self->node;
        my @found
        = map
        {
            ( $node, @data ) = $node->@*;
            @data
        }
        ( 1 .. $self->count );

        return
        $wa
        ?  @found
        : \@found
    }

    method extract()
    {
        # bulk extract the list contents.
        # cursors allow extracting only a portion.

        defined( my $wa  = wantarray )
        or croak 'Bogus extract: used in void context';

        # the empty list is sufficient to notice that
        # nothing was extracted.

        $node->@*
        or return;

        my $curr    = $self->node;
        my @found
        = map
        {
            ( $curr, my @data ) = $curr->@*;
            \@data
        }
        ( 1 .. $self->count );

        return
        $wa
        ?  @found
        : \@found
    }

    method push_args( @argz )
    {
        $self
        ->generate_lazy
        (
            sub
            {
                @argz
                ? shift @argz
                : die "\n"
            }
        )
        ->push_onto( $self )
    }
}

role LinkedList::Single::Header
{
    use Carp            qw( croak           );
    use Scalar::Util    qw( blessed         );
    use Symbol          qw( qualify_to_ref  );

    ############################################################
    # list ops
    #
    # yes, cursor and head are identical: the only node
    # available is the head but having a consistent name
    # for it seems worthwhile and provides a saner error
    # message.
    #
    # extensions to this could add a ( class => ... )
    # argument; for the moment this simply uses the
    # hardwired class.

    method head()
    {
        # head of an empty list is meaningless: there is
        # no data node to return.

        $self
        or croak 'Bogus head: empty list';

        $curs_c->new( whence => $self )
    }

    method shift()
    {
        $self
        or croak 'Bogus shift: empty list';

        $self->delete
    }

    method unshift
    {
        $self->insert( @_ )
    }

    method unshift_lazy( $generator )
    {
        $self->cursor->insert_lazy( $generator )
    }

    method unshift_list( @node_valz )
    {
        @node_valz
        or return $self;

        $self
        ->generate_lazy
        (
            sub
            {
                @node_valz
                or die "\n";

                shift @node_valz
            }
        )
        ->insert_at
        (
            $self
        )
    }
}

role LinkedList::Single::Iterator;
{
    ############################################################
    # housekeeping
    ############################################################

    use Carp            qw( croak carp          );
    use Scalar::Util    qw( looks_like_number   );

    our @CARP_NOT   = ( __PACKAGE__, qw( Object::Pad ) );

    ############################################################
    # methods
    ############################################################

    method advance()
    {
        # the assignment may leave $self on the sentinal (i.e.,
        # false), which is intentional if we want to
        # indicate that the list has been consumed by a cursor.
        #
        # e.g.,
        #
        #   while( $cursor ) { ... ; $cursor->advance }
        #
        #   for( my $curs = $list->cursor ; $curs ; $curs->advance )
        #   { ... }
        #
        #   my $curs    = $list->head;
        #   for(;;) { ... ; $curs->advance->is_sentinel and last }
        #
        # this dodges a trivial exception and allows the
        # test for $self to gracefully stop the processing

        my $next    = $self->next_node
        or croak 'Bogus advance at sentinel';

        # if we are alive at this point then there is a next node.

        $self->node = $next;
        $self
    }

    ############################################################
    # manage list contents.
    # append and drop make no sense for a list so they live
    # down here with the cursor (e.g., push == $list->tail->append).

    method append
    {
        # effectivly push.

        $self->is_sentinel
        ? $self->set_data( $sentinel_node->(), @_ )
        : $self->node->$append( @_ )
        ;

        $self
    }

    method drop()
    {
        # remove the node following this one, returning
        # the data if requested.

        $self->node->$drop_node
    }

    method sort( $comp_gen = undef )
    {
        # it makes sense to sort both a fragment
        # and a cursor.
        #
        # list acquires this via wrapper.

        $comp_gen
        //= do
        {
            my ( $sample )   = $self->data;

            looks_like_number $sample
            ? sub{ my ($x) = @_; sub{ $x <  $_[0] } }
            : sub{ my ($x) = @_; sub{ $x lt $_[0] } }
        };

        # note that $self may be a cursor/fragment:
        # we may not be sorting the entire list.
        #
        # creating the fragment truncates $self to
        # the first node; the one node simplifies
        # the insert logic in not having to deal
        # with the initially emtpy list.

        $self
        ->next
        ->fragment
        ->consume
        (
            sub
            {
                $self
                ->first( $comp_gen->( @_ ) )
                ->insert( @_ )
            }
        )
        ->push_onto( $self )

        # push_onto returns $thence ($self)
    }

    ############################################################
    # list bulk processing.
    # absent any other action, these leave the cursor untouched.
    #
    # each's handler may return false to stop
    # processing; the others may raise an exception.
    #
    # find the first item on the list matching a filter:
    #
    # my $curs  = $cursor->first( $filter );
    # my @data  = $cursor->first( $filter )->data;
    #
    # find the first item on a list and munge all the remaining
    # ones:
    #
    # $list->cursor->first( $filter )->each( $handler );
    #
    # because each is normally used to manage the list contents
    # it is passed the cursor object; the others are passed
    # $cursor->data.
    #
    # see also lightweight wrappers in List class.
    ############################################################

    method each( $handler )
    {
        # caller gets back the cursor on the last
        # node processed in case they care. useful
        # for duplicating the behavior or first()
        # or making second(), etc.
        #
        # reasonable to call in a void context to
        # simply process the list.

        $self
        or croak 'Bogus each at sentinel';

        my $curs = $self->cursor;

        for( ;; )
        {
            # handler returns false to abort processing,
            # sans exception we end up on the sentinel.
            # for consistency with the other handlers,
            # the newline exception is also handled here.

            try
            {
                $curs->$handler
                or last;
            }
            catch( $err )
            {
                $err eq "\n"
                or croak "Failed each: $err";

                carp 'Aborted each.';
                last
            }

            $curs->advance
            or last;
        }

        # false if the list is completed.

        $curs
    }

    method grep( $filter )
    {
        defined wantarray
        or croak 'Bogus grep: used in void context';

        $self
        or croak 'Bogus grep at sentinel';

        my @found   = ();
        my @data    = ();

        for
        (
            my $curr = $self->cursor
          ; $curr
          ; $curr->advance
        )
        {
            try
            {
                @data   = $curr->data;

                $filter->( @data )
                or next;

                push @found, @data;
            }
            catch( $err )
            {
                $err eq "\n"
                or croak "Failed grep: $err";

                carp 'Aborted grep.';
                last
            }
        }

        wantarray
        ?  @found
        : \@found
    }

    method map( $handler )
    {
        defined wantarray
        or croak 'Bogus map: used in void context';

        $self
        or croak 'Bogus map at sentinel';

        my @result  = ();

        for
        (
            my $curr = $self->cursor
          ; $curr
          ; $curr->advance
        )
        {
            try
            {
                push @result, $handler->( $curr->data );
            }
            catch( $err )
            {
                $err eq "\n"
                or croak "Failed map: $err";

                last
            }
        }

        wantarray
        ?  @result
        : \@result
    }

    method first( $select )
    {
        defined wantarray
        or croak 'Bogus first: used in void context';

        $self
        or croak 'Bogus first at sentinel';

        for
        (
            my $curr = $self->cursor
          ; $curr
          ; $curr->advance
        )
        {
            # caller gets back the first cursor that maches
            # or undef at the sentinel.

            try
            {
                $select->( $curr->data )
                and return $curr;
            }
            catch( $err )
            {
                $err eq "\n"
                or croak "Failed first: $err";

                last
            }
        }
    }
}

role LinkedList::Single::Transient
{
    use Carp        qw( carp croak  );
    use Sub::Name   qw( subname     );

    our @CARP_NOT   = qw( $nmgr_r $list_c $curs_c $frag_c );

    ############################################################
    # these look odd.. until you see the guts of append_lazy
    # and insert_lazy:
    #
    # $self->generate_lazy( $generator )->insert_at( $self );
    #
    # returning $self via $thence. all of these leave the
    # fragment empty, false, and generally useless.

    my $push_onto
    = sub
    {
        my( $src, $dst ) = @_;

        $src->transfer_node( $dst->sentinel );
        $dst
    };

    method push_onto( $thence )
    {
        $thence->DOES( $nmgr_r )
        or croak "Bogus push: '$thence' does not $nmgr_r";

        $self->$push_onto( $thence )
    }

    method append_to( $thence )
    {
        $thence->DOES( $nmgr_r )
        or croak "Botched append_to: '$thence' does not $nmgr_r";

        $thence
        or croak "Bogus append_to at sentinel";

        $thence
        ->next
        ->$push_onto( $self     )
        ->$push_onto( $thence   )
    }

    method insert_at( $thence )
    {
        $thence->DOES( $nmgr_r )
        or croak "Bogus append_to: '$thence' does not $nmgr_r";

        $thence
        ?
            $thence
            ->$push_onto( $self )
            ->$push_onto( $thence )
        :
            $self->transfer_node( $thence )
        ;

        $thence
    }

    method consume( $handler )
    {
        # consume the fragment, leaving nothing but the
        # sentinel when complete.

        $self
        or croak 'Botched consume: empty fragment';

        while( $self )
        {
            try
            {
                $handler->( $self->data );
            }
            catch( $err )
            {
                $err eq "\n"
                or carp
                    "Failed consume: $err\n"
                  , $dump_format->( $self->data )
                ;

                last
            }

            $self->advance
            or last;
        }

        # absent exctptions, this will be false (sentinel).
        # caller can check for true $self on return and
        # handle the non-empty portion to reclaim the data.

        $self
    }
}

########################################################################
# nothing below this point should unwerap $node.                       #
########################################################################

class LinkedList::Single::List v2.0.0
:repr( pvobj )
{
    ############################################################
    # once node-twiddling operaitons are pushed into the
    # role for sharing with the cursor this is kinda
    # boring: the node object is a static entity that
    # references the head so that the list is kept alive.
    #
    # all it really does is house the list and generate
    # cursors.
    #
    # shift & unshift live here since a cursor has no idea
    # of where the list's head is; push and pop find the
    # tail so they make sense to share.
    #
    # everything else interesting is in the cursor class
    # it knows where on the list to perform the operations.
    ############################################################

    use overload
        q/bool/ =>
        sub
        {
            # list is true if its head node is not the sentinel.

            my ( $list ) = @_;

            ! $list->is_sentinel
        }
    ;

    use Sub::Name   qw( subname         );
    use Symbol      qw( qualify_to_ref  );

    apply LinkedList::Single::NodeMgr;
    apply LinkedList::Single::Header;

    # trivial wrappers, avoid $list->cursor->...
    # for common operations we are likley to
    # use with a list.

    our @wrappers
    = qw
    (
        each
        map
        grep
        first
        sort
    );

    for my $name ( @wrappers )
    {
        my $sub = $curs_c->can( $name )
        or die "Bogus $name: $curs_c cannot '$name'";

        *{ qualify_to_ref $name }
        = subname $name
        => sub
        {
            my ( $list ) = @_;

            splice @_, 0, 1, $list->cursor;

            goto &$sub
        };
    }
}

class LinkedList::Single::Cursor    v2.0.0
:repr( pvobj )
{
    use overload
        q/bool/ =>
        sub
        {
            # cursor is true if its head node is not the sentinel.

            my ( $curs ) = @_;

            ! $curs->is_sentinel
        }
    ;

    apply LinkedList::Single::NodeMgr;
    apply LinkedList::Single::Iterator;
}

class LinkedList::Single::Fragment  v2.0.0
{
    ############################################################
    # splicing into an existing list requries a
    # sequence of nodes that doesn't have a head.
    # hence a fragment: a sequence of nodes sans
    # the list's un-moveable root node.
    #
    # note these methods are:
    #
    #   $frag->append_to( $list_or_curs );
    #   $frag->insert_at( $list_or_curs );
    #
    # this avoids appending one list to another
    # and getting multi-headed animal syndrome.
    #
    # it makes no sense to apply bulk op's to a
    # fragment; they live in the cursor class.
    ############################################################

    use overload
        q/bool/ =>
        sub
        {
            # list is true if its head node is not the sentinel.

            my ( $list ) = @_;

            ! $list->is_sentinel
        }
    ;

    apply LinkedList::Single::NodeMgr;
    apply LinkedList::Single::Iterator;
    apply LinkedList::Single::Transient;
}

# keep require happy
1
__END__

=head1 NAME

LinkedList::Single - Singly linked list using Object::Pad.

=head1 SYNOPSIS

    ############################################################
    # we define lists, cursors, and fragments.
    # all of them are based on NodeMgr role, which
    # handles the node's structure. the classes which
    # apply this do not unwrap the node structure for
    # themselves, delegaing the internsl to NodeMgr.
    ############################################################

    ############################################################
    # lists are simple: They cannot move but can have
    # data unshifted or pushed onto them, shifted and
    # popped off.
    #
    # lists are some number of data nodes followed by an empty
    # node called the 'sentinel'. an empty list has a sentinal
    # as its head node and will test false in a boolean context.
    ############################################################

    # the list constructor takes no arguments,
    # returning an empty list.

    my $list    = LinkedList::Single->new;

    # nodes on the list are arrays of whatever
    # you like: arrayref's, objects, empty...

    # push and pop do what you'd expect, though they
    # are expensive in having to trace the list to find
    # its end each time.

    $list->push( @stuff );      # one node with a list of data
    $list->count;               # 1 == node count

    my @items   = $list->pop;   # return a list of @stuff
    $list->count;               # 0

    # unshift and shift are much faster, working on the
    # list's head which is always available.

    $list->unshift( @an_array_of_data       );
    $list->unshift( \@stored_as_array_ref   );
    $list->unshift( %flattened_hash         );

    $list->unshift();   # empty nodes are valid!!!

    my $n   = $list->count; # 4

    # shift returns a list of whatever was put in the node.

    my @data    = $list->shift; # empty
    my %bar     = $list->shift; # rebuild the hash from a list
    my ( $foo ) = $list->shift; # return an arrayref
    my $count   = $list->shift; # array of data assigned to a scalar


    # empty lists return a count of zero, not an exception.
    # $list is true if it is not empty

    if( $list )
    {
        say 'List node count: ' . $list->count;
    }
    else
    {
        say 'Your list is empty.';
    }

    ############################################################
    # cursors are a bit more interesting: they can move,
    # but have only a current node -- their 'head' is the
    # current node, not the list's head.
    ############################################################

    # the Cursor's constructor takes a single argument of
    # list, cursor, or fragment (something that DOES NodeMgr)
    # and creates a cursor with its current node referencing
    # the one in our constructor argument.
    #
    # cursors can create new cursors referencing their current
    # position. This is handy to have $curs2 bookmark a position
    # while $curs3 advances up the list.

    my $curs1   = LinkedList::Single::Cursor->new( $list );
    my $curs2   = $list->cursor;
    my $curs3   = $curs2->cursor;

    # append and insert add new items to the list.
    # append is more efficient; neither one moves
    # the cursor.

    $cursor->append( @data );   # add a node >after< this one.
    $cursor->insert( @data );   # insert one here, moving the curren tnode.

    # for bulk insertion there are *_lazy methods which take
    # a generator. these will

    # remove the following node or current one, returning
    # its data as a list (as with shift and pop). in a
    # void context they return nothing, just wiping the
    # node.
    #
    # delete works like a delete key: removing the node
    # currently referenced by the cursor; drop takes out
    # the following node.
    #
    # deleting or dropping the sentinel is an error.

    my @data    = $cursor->delete;  # current node
    my @data    = $cursor->drop;    # following node

    # advance the cursor, returning false if we move
    # onto the sentinel node, raising an error if we
    # try to walk off of it.

    # given a cursor these two loops are equivalent.
    # using advance is a bit more efficient.

    my $cursor  = $list->cursor;

    # these both leave $cursor on the sentinel node (i.e.,
    # $cursor is false) to indicate that the entire list
    # is consumed.

    while( $cursor )
    {
        ...

    }
    continue
    {
        $cursor->advance;
    }

    # or

    for(;;)
    {
        ...

        $cursor->advance
        or last;
    }

    # the cursor's "head" is its referenced node -- it cannot
    # go back on a singly linked list.
    #
    # the cursors' "tail" is the same one given by the list:
    # it's last data node (before the sentinel).
    #
    # both head and tail raise an exception on an empty list
    # or cursor at the sentinel (i.e., if the dispatching
    # object is false).

    try
    {
        my $cursor  = $list->head;
        ...
    }
    catch( $err )
    {
        $err =~ m{sentinel}
        and die 'Sorry, your list is empty, head is meaningless.';
    }

    try
    {
        my $cursor  = $cursor->tail;
        ...
    }
    catch( $err )
    {
        $err =~ m{sentinel}
        and die 'Sorry, your cursor is on the sentinel;
    }

    # there are cases where placing the cursor on a sentinel
    # node is useful -- mainly for bulk append.

    my $sent    = $list->sentinel;
    my $sent    = $curs->sentinel;

    # node data is accessed via data.
    # in a scalar context this returns an arrayref,
    # in a list context it returns, well... a list.

    for(;;)
    {
        my $curs    = $list->cursor;

        # list of values passed to frobnicate
        frobnicate( $curs->data );

        $curs->advance
        or last;
    }

    ############################################################
    # cursors have each, grep, map, first, extract to
    # simplify consuming the nodes at or after their
    # current node (which does not have to the lists's
    # head node!).
    #
    # lists have convienence methods for these that call
    # $list->head->each, etc.
    #
    # these all take a closure as argument to process,
    # select, munge, or extract the list contents.

    # each is similar to perl's each on lists, except
    # that it uses a scratch cursor and is not affected
    # by re-executing it if the previous call did not
    # complete the list.
    #
    # each is passed a cursor and can modify the list
    # using it. each will stop when the closure returns
    # false or the cursor walks onto the sentinel node.
    # other than testing for a false value, the return
    # from each is ignored.

    sub random_sample( $count, $list )
    {
        # randomly delete up to 10 nodes, saving
        # their data as a single list.

        my $range   = $list->count;
        my $cutoff  = 1 + 10/$range;
        my @result  = ();

        my $delete_random_nodes
        = sub( $curs )
        {
            $cutoff > int( rand $range )
            and
            push @result, $curs->delete;

            --$count
        };

        $list->each( $delete_odd_data );

        # at this point @result has accumulated
        # the random data. note that if any node
        # has more than one item @result may be
        # greater than 10.
    }

    # grep does what you'd expect: if the select closure
    # returns true the node's data is pushed onto the
    # result set.
    #
    # find any nodes with counts greater than a configured
    # cutoff value.

    my $cutoff  = $config_object->cutoff;
    my $select
    = sub( @node_data )
    {
        @node_data > $cutoff
    };

    my @found   = $list->grep( $select );

    # map also does what you'd expect, returning
    # the contents of whatever $munge does to each
    # node's data. it can at as a grep-ish transform
    # by returning an empty list.

    # return totals of node_data with more
    # than one data element.

    my $munge
    = sub( @node_data )
    {
        @node_data > 1
        ? sum( @node_data )
        : ()
    };

    my @found   = $list->map( $munge );

    # returns a cursor to the first node for which
    # $select returns true.

    # examining a queue stored in reverse-startup order
    # this returns the first job with a startup time
    # prior to now. if nothing is found a cursor
    # referencing the sentinel node is found, which
    # will test false.
    #
    # Note: this is more effective when combined with
    # the truncate() method described with "Fragments",
    # below.

    my $now = time;

    my $first_job
    = sub( $job )
    {
        $time > $job->start
    };

    my $dispatch
    = sub( $job )
    {
        $que_mgr->dispatch( $job );
    };

    if( my $runnable = $list->first( $first_job ) )
    {
        my $count   = $runnable->count;

        say "Executing $count jobs at $time";

        $runnable->each( $dispatch );
    }
    else
    {
        say "Nothing going at $time";
    }

    # extract all node data as an array-of-arrays
    # this uses a map internally to generate the
    # list in one pass (vs. pushing it node-by-node
    # in grep or map) and is more efficient for bulk
    # extraction.
    #
    # note that this does not take a closure argument,
    # it selects all nodes.

    my @data    = $list_or_cursor->extract; # array of refs
    my $data    = $list_or_cursor->extract; # ref to array of refs

    ############################################################
    # now the fun starts: Fragments are cursors
    # referencing a sequence of nodes that are not
    # anchored by a static list. they are created by their
    # constructor or the detach & splice methods. their
    # purpose is avoiding multi-headed-animal syndrome
    # when they are appended or inserted into a list.
    #
    # constructing a fragment from a list/cursor will detach
    # the nodes from their source, leaving a singly-refernced
    # head node. unlike lists, cursors can advance, allowing
    # them to consume a list until it is empty. their methods
    # provide transient properties that make fragments handy
    # for moving nodes between lists or extracting sections
    # out of them.
    #
    # fragments are also handy for lists that are going to
    # be consumed and discarded: advancing a fragment object
    # will de-reference the prior node and reclaim the node
    # storage. this works nicely for things like queues that
    # will be chopped off as a block, dispatched, and then
    # forgotten (see examples below).
    #
    # fragments also support the append_lazy method that
    # uses a closure to generate nodes, which can then be
    # consumed or appended/inserted into lists or using
    # cursors.
    ############################################################

    my $frag    = LinkedList::Single::Fragment->new;
    my $frag
    = LinkedList::Single::Fragment
    ->new
    ->append_lazy( $subref );

    # fragments have the append_to and insert_at methods
    # which take a list or cursor as an argument. the
    # fragment is spliced into the list at the head of a
    # list or at/after the referenced node for a cursor.
    # these methods return the destination object, not
    # the invoking fragment, to simplify constructing a
    # list using the generator.
    #
    # the generator returns whatever the nodes should have
    # (empty is fine) and raises a "\n" exception to indicate
    # the end-of-list.
    #
    # note that appending with an empthy list or sentinel
    # cursor raises an exception as there are no prior
    # nodes to insert 'after'; insert with an empty list
    # or sentinel cursor is fine.

    # generate a new list with values of ( 1023..1 ):

    my $generate_nodes
    = sub()
    {
        state $i    = 1024;

        --$i or die "\n"
    };

    my $list
    = LinkedList::Single::Fragment
    ->new
    ->append_lazy( $generator )
    ->append_to( LinkedList::Single->new );

    # generate a fragment of queued jobs and append it to
    # the working queue.

    my $que_path    = $config->read( 'queue_dir' );
    my $curr_jobs
    = sub()
    {
        # read whatever's in the directory

        state @waiting  = ();

        @waiting
        or
        @waiting
        = map
        {
            $job_class->new( $_ )
        }
        ls "$que_path/*.job";

        shift @waiting
        or die "\n"
    };

    my $que = LinkedList::Single->new;

    for(;;)
    {
        LinkedList::Single::Fragment
        ->new
        ->append_lazy( $curr_jobs );
        ->append_to( $que );
    }

    ############################################################
    # Exception Handling
    ############################################################

    # the code here uses try/catch blocks to report most
    # errors, returning the dispatching object on success
    # or undef on failure.
    #
    # in cases where the code has to indicate a non-error
    # end of processing (e.g., to stop an each iteration)
    # it can use:
    #
    #   die "\n"
    #
    # to dispatch an empty exception. this approach is used in
    # all of the Iterator and Traneient methods which accept a
    # handler such as each(), sort(), and consume().
    #
    # for example, a list of pending jobs sorted in decreasing
    # start order can be handled by findind the first


    my $now = 0;
    my $que = LinkedList::Single->new;

    for(;;)
    {
        # new jobs appended in start-time order.

        $que->read_new_jobs;

        $now        = time;
        my $cutoff  = $now + 59;

        if
        (
            my $curr    = $que->first( sub { $_[0] < $now } )->fragment
        )
        {
            my $handler
            = sub( @node_data )
            {
                # give up processing the queue at 60sec and
                # re-accumulate the pending jobs.

                time > $cutoff and die "\n";

                # process the next queue entry

                try
                {
                    dispatch_job( @node_data );
                }
                catch( $err )
                {
                    ...
                }
            };

            try
            {
                $curr->consume( $handler );
            }
            catch( $err )
            {
                $err eq "\n"
                ? say 'Reached cutoff'
                : say "Error processing que: $err"
            }

            # return the unused portion.

            $curr->push_onto( $que );
        }

        $now    = time;

        $now < $cutoff
        and sleep $cutoff - $now;
    }

=head1 DESCRIPTION

The critical difference between this and the prior LL::S version
is separating the List from the Iterator. This avoids the problems
caused by having an implicit 'current' node embedded into the list.
Here, the list is forever static, the iterators are transient and 
able to move, and Fragments are list-less iterators that can consume
a list or move pieces of them around.

This distinction also improves performance by avoiding the need for
an inside-out 'head' structure to keep the lists alive: The List is
always at the head, terators are trivial to create and easily 
discarded. This improves performance in anything that has to 
use the head for shift/unshift or walk down the list with lightweight
iterators.

One thing carried over from the v1 list is the "sentinel" node at
the end of each list. This is an empty node, lacking both data and
any 'next node' reference. The node serves to flag empty lists
and also simplifies appending to lists or truncating them: The 
sentinel can be assigned an existing node's contents to append
the node or the contents assigned to a new node to truncate the 
list without having to modify the parent/refrencing node. Examples
are creating a fragment via:

    $frag->node->@*     = splice $curs->node->@*

or 

    $cursor->node->@*   = $frag->head->node->@*

both of which leave the right hand node as an empty sentinel without
having to access the node's parent (which is difficult using a 
singly-linked list).

=head2 Roles

Note: The classes here are trivial; most of the content is in Roles.

=head3 LinkedList::Single::NodeMgr

All access to the individual node contents lives here. The point
of this is that anyone wishing to modify the format, or derive a
new internal structure, will find all of the access here (and in
a few package lexicals shared among the roles). The methods here
are intentionally optimized for speed and contain most of the
boilerplate.

The ADJUST block for all of the classes lives here, using if-logic
to manage the intial contents. Logically the constructors could 
have been spread among the roles but it seemed saner here to put
it all in one place.

This is where the sentinal node structure is defined and the 
internal layout of the node contents is handled. Note that nodes
themselves are not objects; the objects here manage anonymous,
class-less nodes.

=head3 LinkedList::Single::Header

The few methods for an object that cannot move, used by List. Things 
like shift or unshift that depend on knowing where the head of a list 
are live here.

=head3 LinkedList::Single::Iterator;

The many, many methods related to moving an object along the list of
nodes and modifying the list modifying the list at a node live here. 
These range from next() through append() and insert() to each() and 
first().

=head3 LinkedList::Single::Transient

Handlers for fragments of a list lacking a head. These methods
are used to transfer nodes between lists. Several of these have
the unusual property of returning their argument (the destination)
rather than the dispatching object (source) since the transfer
leaves the original fragment empty and useless.

=head2 Classes

These are trivial, aside from a few lightweight
wrappers in List these all simply overload 'bool'
and use the roles. The overloaded bool handler 
simplifies itrations such as

  $list or die 'The list is empty...';

  while( $iterator ) { there is a next node }

  if( $fragment } { there are more nodes to process } 


=head3 LinkedList::Single

This has one methnod of note: 'new' which redispatches to
LinkedList::Single::List->new. The point of this is allowing existing
code to call LinkedList::Single->new and get a working object. This
works at all because the usual use of LL::S is to create a list; 
though transient lists may be better handled with Fragment.

=head3 LinkedList::Single::List

Applies: NodeMgr, Header.

Lists cannot move. Their purpose is to reference the head node,
keeping the list alive and providing a location for head, shift,
and unshift. The other classes are normally created from a list.

=head3 LinkedList::Single::Cursor

Applies: NodeMgr, Iterator;

These are created referencing an exising node from a List, Iterator,
or Fragment and can walk down the list. They are usually created using
from lists via $list->cusor or Cursor->new( $list ).

The bulk-operations on lists all live in Iterator, using transient 
cursors to manage the current location instead of having the 'current' 
location embedded in the list (avoiding the pain of Perl's each() 
operator or LL::S v1).

=head3 LinkedList::Single::Fragment

Applies Nodemgr, Iterator, Transient.

Fragments are used to either consume a set of nodes
or transfer nodes between lists. Constructing a fragment from a list 
(or via an iterator in a list or fragment) truncates the source list, 
avoiding a doubly-referenced node. This means that fragments are 
created from lists [usually] or other fragments [doable] will destroy 
themselves propery once they are no longer referenced. This leads to 
two main uses of Fragments:

=over 4

=item Appending to lists.

Appending a node referenced by an iterator to another list leaves 
the appended node doubly-referenced: once from the orignal list,
once on the new one. Fragments avoid this issue by truncating the
source list (or fragment) by replacing the source node with a
sentinel. This makes it safe to add Fragments to a List or Fragment.

Append and splice on lists both use a fragment to move the nodes
from one list to another. Because Fragments are intentinally transient 
it is often not all that useful to return them from methods: By the 
time they are returned they are empty. The solution is most cases is 
returning the method argument: The list onto which the fragment was 
appended:

    $frag->append_to( $list );

returns $list since after this operation the -- usually anonymous --
fragment contains only a single sentinel node.

For example, the splice() appends a transient tail fragment from the 
original list to the fragment being spliced then appends the total
fragment to the list. For example, Fragment's insert_at takes any
node_mgr object and puts a fragment into the list prior to the 
existing node:


    method insert_at( $thence )
    {
        ...

        $thence
        ->$push_onto( $self )
        ->$push_onto( $thence )
    }

The first push_onto( $self ) returns the dispatching object, the
second one returns $thence, the point at which the fragment was
inserted.

=item Fragments can consume nodes.

Unlike an iterator, which walks down a list referenced by a List,
fragments are orphans. Advancing the Fragment object dereference the 
current head node and has it garbage collected. This makes it 
convienent to consume the list, with node or data element destructors
being called as the fragment advances.

One example of this is a queue, where currently executable jobs are
moved into a Fragment which discards them as the jobs are dispatched,
allowing the data elements' destructors to handle cleanup.

The Fragment method 

  $frag->consume( $handler )

will iterate each node through handler, leaving $frag empty
unless $handler raises an exception (see also NULL Exceptions).

=back

=head2 Classes

The classes are trivial: Each one provides its own bool() override
that returns false if the List or Fragment is empty or a Cursor
has walked off the list. Other than that the classes mostly use roles.

Note that cursors do not track which List or Fragment of their
referenced node lives on. The assumption is that Cursors are 
transients, created with lexical variables, and will have a lifetime
short enough to track. If this causes memory leaks a separate wrappr
class can be added to track them.

=over 4

=item List

Applys NodeMgr & Header.

bool() tests for a sentinel head node:

    $list or die 'The list is empty';

List also provides wrappers for bulk operations that require a 
Cursor: each, map, grep, first, and sort. These are wrapped to
re-dispatch the method via a cursor.

Constructng a list is trivial:

    my $list    = LinkedList::Single->new;

notice the lack of arguments: List are always created empty and
will raise an exception if given any arguments to their constructor.

=item Cursor

Applys NodeMgr & Iterator.

bool() tests for a sentinel curr node:

    $curs or die 'You have walked off the list';

Constructing a Cursor requires a NodeMgr-ish object. Cursors can
reference an empty list or a cursor at the sentinel. The object
simply needs to have a node. For lists the obvious place to 
initialize the cursor is the head or tail:

    my $curs    = $list->head;  # returns a cursor, not a node!
    my $curs    = $list->tail;  # ditto.

Note that a cursor requires an object for construction, not a bare
node! Nodes are not objects:

    my $curs    = $list->node;  # raises an exception!

=item Fragment

Applys NodeMgr, Iterator, and Transient.

bool() tests for a sentinel curr node:

    $frag or die 'Your fragment is consumed/empty';

Constructing a fragment starts with any NodeMgr-ish object,
truncates the object at its current node (the head for a
List or Fragment, curr for Cursor) and returns the remainder
of the now-headless list in the Fragment:

    my $frag    = LinkedList::Single::Fragment->new( $list );
    my $frag    = LinkedList::Single::Fragment->new( $curs );
    my $frag    = LinkedList::Single::Fragment->new( $another_frag );

    # a new, empty Fragment:
    my $frag    = LinkedList::Single::Fragment->new;

Each of these will leave $frag referencing a [possibly sentinel] node 
and the source object truncated. This leaves a List or Fragment empty 
and Cursor referencing a sentinel node (both of which are false for 
the object). The Fragment's construction leaves the fragment as the
only object referencing the fragment's head node -- the source node
is left in place, referenced but an empty sentinel.

=back

=head2 Role Methods by Role

=head3 LinkedList::Single::NodeMgr

=over 4

=item method object_type

Takes no arguments. Returns the short (leaf) class name of the
dispatching object, derived from C<< $self->META->name >>. Does not
affect the object or list.

=item method cursor

Takes no arguments. Returns a new Cursor referencing the same node as
the dispatching object. Does not affect the object or list.

=item method fragment

Takes no arguments. Detaches the dispatching object's node contents
into a new Fragment: the Fragment receives the current node's data and
successors, while the dispatching object is left referencing an empty
sentinel in its place. Returns the new Fragment.

=item method list

Takes no arguments. Detaches the dispatching object via C<fragment>
and appends the result onto a newly constructed List. Returns the new
List; the dispatching object is left referencing a sentinel.

=item method node

Takes no arguments; C<:lvalue> accessor. Returns the object's raw
internal node reference, and may be assigned to in order to make the
object reference a different node outright (e.g. C<$node =
$whence->node>). Assignment does not alter list structure, only what
node this object points at.

=item method next_node

Takes no arguments; C<:lvalue> accessor. Returns the reference stored
in the current node's successor slot. Assigning to it rewires the
list at this point, replacing whatever previously followed the
current node.

=item method tail_node

Takes no arguments. Walks from the current node to the last data node
before the sentinel and returns its raw internal reference, raising
an exception if the dispatching object is already the sentinel. Does
not affect the object or list.

=item method is_sentinel

Takes no arguments. Returns true if the current node is the empty
sentinel (no data, no successor), false otherwise. Does not affect
the object or list.

=item method count

Takes no arguments. Walks from the current node to the sentinel and
returns the number of data nodes found (zero if already at the
sentinel). Does not affect the object or list.

=item method data

Takes no arguments. Returns the current node's data, as a list in
list context or an arrayref in scalar context, raising an exception at
the sentinel or when called in void context. Does not affect the
object or list.

=item method next_data

Takes no arguments. Returns the data of the node following the
current one, as a list or arrayref per context, raising an exception
if there is no next node or if called in void context. Does not
affect the object or list.

=item method set_data( @data )

Takes a (possibly empty) list of data. Overwrites the current node's
data with C<@data>, preserving its existing successor (creating a
sentinel successor if none existed), which makes this behave as a
push when called on the sentinel. Returns the dispatching object.

=item method push_data( @data )

Takes a (possibly empty) list of data. Appends C<@data> onto the
current node's existing data without creating a new node. Returns the
dispatching object.

=item method next( $count = 1 )

Takes an optional non-negative count, default 1. Returns a new cursor
advanced C<$count> nodes past the current one (0 leaves it at the
same node); raises an exception for a negative count. Does not affect
the dispatching object.

=item method tail

Takes no arguments. Returns a new cursor referencing the last data
node before the sentinel. Does not affect the dispatching object.

=item method sentinel

Takes no arguments. Returns a new cursor referencing the list's
sentinel node, walking forward from the current node until it is
reached. Does not affect the dispatching object.

=item method push( @data )

Takes a (possibly empty) list of data. Appends a new node holding
C<@data> after the tail of the list, or, if the current node is the
sentinel, turns it into the first data node. Modifies the list by
adding one node at its end. Returns the dispatching object.

=item method pop

Takes no arguments. Removes the list's last node and returns its
data, raising an exception if the list is empty (sentinel). Modifies
the list by removing its final node.

=item method insert( @data )

Takes a (possibly empty) list of data. Pushes the current node's
existing contents one node further down the list and replaces the
current node with a new one holding C<@data>, so the dispatching
object ends up referencing the new node. More expensive than
C<push_data>/C<append> since it copies the current node's contents.
Returns the dispatching object.

=item method reverse

Takes no arguments. Reverses, in place, the order of every node from
the current node through the sentinel; a no-op if already at the
sentinel. Modifies the list; returns the dispatching object, now
referencing what was the last node of the reversed segment.

=item method generate_lazy( $generator )

Takes a generator coderef. Repeatedly calls C<< $generator->() >>,
appending each result as a new node onto a freshly created,
unattached Fragment, until the generator raises a bare C<"\n">
exception (any other exception propagates). Returns the new Fragment;
does not affect the dispatching object.

=item method append_lazy( $generator )

Takes a generator coderef. Builds a fragment via C<generate_lazy> and
splices it into the list immediately after the dispatching object's
node (via C<append_to>) if non-sentinel, or at the object's position
(via C<insert_at>) if it is the sentinel. Modifies the list by
inserting the generated nodes; returns the destination object.

=item method insert_lazy( $generator )

Takes a generator coderef. Builds a fragment via C<generate_lazy> and
splices it into the list immediately before the dispatching object's
current node (via C<insert_at>), leaving the object referencing the
first newly generated node. Modifies the list by inserting the
generated nodes ahead of the current position; returns the
dispatching object.

=item method push_lazy( $generator )

Takes a generator coderef. Moves to the list's sentinel and calls
C<insert_lazy> there, appending every generated node onto the end of
the list. Modifies the list; returns the same as C<insert_lazy>.

=item method push_list( @valz )

Takes a list of values. Wraps C<@valz> in a generator that yields one
value per node until exhausted, then passes it to C<push_lazy>,
appending one new node per value onto the end of the list. Modifies
the list; returns the same as C<push_lazy>.

=item method transfer_node( $thence )

Takes another NodeMgr-consuming object C<$thence>. Splices the
dispatching object's entire node structure into C<$thence>'s node
slot, leaving the dispatching object referencing an emptied node and
C<$thence> referencing what the dispatching object used to reference.
Returns the dispatching object.

=item method delete

Takes no arguments. Removes the current node from the list by
overwriting it with the following node's contents, raising an
exception at the sentinel. In non-void context returns the removed
data; modifies the list by collapsing out the current node, with the
dispatching object left referencing the same position (now holding
what was the next node).

=item method flat_list

Takes no arguments. Returns the data of every node from the current
one through the sentinel, flattened into a single list (or arrayref
in scalar context); raises an exception in void context, returns
nothing at the sentinel. Does not affect the object or list.

=item method extract

Takes no arguments. Returns the data of every node from the current
one through the sentinel as a list (or arrayref in scalar context) of
per-node arrayrefs; raises an exception in void context, returns
nothing at the sentinel. Does not affect the object or list.

=item method push_args( @argz )

Takes a list of arguments. Wraps them in a generator yielding one
argument per node, builds a fragment via C<generate_lazy>, and pushes
it onto the dispatching object via C<push_onto>, appending one new
node per argument onto the end of the list. Modifies the list;
returns the dispatching object.

=back

=head3 LinkedList::Single::Header

=over 4

=item method head

This takes no arguments and returns a cursor to the node referenced by
the object, raising an exception of the current node is a sentinel.

=item method shift

This takes no arguments and detaches the referenced node and returns
its data, raising an exception of the current node is a sentinel.

=item method unshift( @data )

Updates the object to reference a new node with the (possibly empty )
arguments as data and referencing the current node as its next node.
An empty argument list cretes an empty node with only the next node
populated.

=item method unshift_lazy( &generator )

Iterates inserting new nodes with the genetor's output.

See C<insert_lazy> in the NodeMgr role for a description of the
generator.

=item method unshift_list( @node_valz )

Replaces the current node with the head of a new fragment
with data of @node_valz, its tail node refrencing the current
node. This is done with a closure and unshift_lazy.

=back

=head3 LinkedList::Single::Iterator

=over 4

=item method advance

Takes no arguments. Moves the dispatching object to reference the
next node, raising an exception if there is no next node (already at
the sentinel). Returns the dispatching object, which tests false once
it reaches the sentinel.

=item method append( @data )

Takes a (possibly empty) list of data. Adds a new node holding
C<@data> immediately after the current node, or, if the current node
is the sentinel, turns it into a data node holding C<@data>
(effectively a push). Modifies the list; returns the dispatching
object.

=item method drop

Takes no arguments. Removes the node following the current one and
returns its data, raising an exception if there is no following node.
Modifies the list by removing the successor node; the current node
itself is untouched.

=item method sort( $comp_gen = undef )

Takes an optional comparator-generator coderef, defaulting to a
numeric- or string-less-than generator inferred from the first data
element. Truncates the dispatching object into a fragment, then
re-inserts each element back at its sorted position by repeatedly
locating the insertion point with C<first> and calling C<insert>.
Modifies the list by reordering every node from the current position
through the sentinel; returns the original (destination) object.

=item method each( $handler )

Takes a handler coderef. Walks a scratch cursor from the current node
through the list, calling C<< $handler->($cursor) >> at each node; the
handler may mutate the list via the cursor it receives. Stops when the
handler returns false, raises a bare C<"\n"> (caught, with a warning),
or the sentinel is reached; raises an exception if called at the
sentinel. Returns the final cursor (false if the list was exhausted);
does not move the dispatching object itself.

=item method grep( $filter )

Takes a filter coderef. Walks from the current node to the sentinel,
collecting the data of every node for which C<< $filter->(@data) >>
is true; a bare C<"\n"> from the filter stops the walk early (with a
warning), any other exception propagates. Raises an exception at the
sentinel or in void context. Returns the matched data as a list or
arrayref per context; does not affect the list or dispatching object.

=item method map( $handler )

Takes a handler coderef. Walks from the current node to the sentinel,
applying C<$handler> to each node's data and collecting the results; a
bare C<"\n"> from the handler stops the walk early, any other
exception propagates. Raises an exception at the sentinel or in void
context. Returns the collected results as a list or arrayref per
context; does not affect the list or dispatching object.

=item method first( $select )

Takes a selector coderef. Walks from the current node to the
sentinel, returning a cursor to the first node for which C<<
$select->(@data) >> is true, or undef if none match or the selector
raises a bare C<"\n"> (other exceptions propagate). Raises an
exception at the sentinel or in void context. Does not affect the
list or dispatching object.

=back

=head3 LinkedList::Single::Transient

=over 4

=item method push_onto( $thence )

Takes a NodeMgr-consuming object C<$thence>, raising an exception if
it does not. Transfers the dispatching object's node structure onto
C<$thence>'s sentinel node, splicing the dispatching object's contents
onto the end of C<$thence>'s list/fragment. Modifies both objects:
C<$thence> gains the transferred nodes, the dispatching object is left
empty. Returns C<$thence>.

=item method append_to( $thence )

Takes a NodeMgr-consuming object C<$thence>, raising an exception if
it does not do so or is itself a sentinel. Splices the dispatching
object's nodes into the list immediately after C<$thence>'s current
node, by moving C<$thence>'s existing successor segment onto the
dispatching fragment's tail and then moving the combined result back
onto C<$thence>. Modifies the list, inserting all of the dispatching
object's nodes after C<$thence>. Returns C<$thence>.

=item method insert_at( $thence )

Takes a NodeMgr-consuming object C<$thence> (which may be a
false/sentinel object), raising an exception if it does not do
NodeMgr. If C<$thence> is non-sentinel, splices the dispatching
object's nodes onto C<$thence> and then C<$thence>'s original contents
back onto the result, inserting the dispatching object's nodes
immediately before C<$thence>'s current node while C<$thence> ends up
referencing the first inserted node. If C<$thence> is a sentinel,
simply transfers the dispatching object's node structure onto it.
Modifies the list; returns C<$thence>.

=item method consume( $handler )

Takes a handler coderef, raising an exception if the dispatching
fragment is already empty. Repeatedly invokes C<$handler> with the
current node's data and advances; a bare C<"\n"> from the handler ends
the loop normally, any other exception is reported via C<carp> (with a
dump of the offending data) and also ends the loop. C<advance>
dereferences each node as it is consumed, so normal completion leaves
the dispatching fragment empty. Returns the dispatching object, which
is false unless the handler aborted before the fragment was fully
consumed, in which case it still references the remaining nodes.

=back

=head1 SEE ALSO

=over 4

=item Object::Pad

Which makes all of this possible.

=item Online Descriptions

What went into this:

    https://speakerdeck.com/lembark/refactoring-linkedlist-single-for-perls-new-oo-model

In case you care what I look like:

    https://www.youtube.com/watch?v=JppJG0a-iHs

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009-2026 Steven Lembark.

=head1 LICENSE

This code can be used under the same terms as v5.44 or
any later version of Perl.
