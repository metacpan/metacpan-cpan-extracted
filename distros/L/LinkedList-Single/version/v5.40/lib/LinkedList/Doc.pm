package LinkedList::Single::Doc v2.0.0;
1
__END__

[Draft]

=head1 NAME

LinkedList::Single v2.0.0 - Re-written using Object::Pad.

=head1 SYNOPSIS

    use LinkedList::Single; # pulls in the classes.

    # constructor for a list takes no arguments.  lists 
    # are static: you can push, pop, shift, or unshift on 
    # them, but any access to the data in sequence uses a 
    # separate cursor.
    #
    # each list is a, possibly empty, sequence of data 
    # nodes with a single empty 'sentinel' at the end. 
    # an empty list will have the sentinel as its only
    # (i.e., first) node.

    my $list    = LinkedList::Single->new;          # wrapper
    my $list    = LinkedList::Single::List->new;    # constructor

    # lists are true if they have at least one data node.
    #
    # most operations on the list, including finding the head or
    # tail and creating cursor will fail with an exception
    # if the list is empty (i.e., if a list object is false).

    if( $list )
    {
        # do something
    }
    else
    {
        die 'This list is empty!';
    }

    # the lists's root node can store data for the list. 
    # this node is unaffected by shift/unshift/push/pop
    # and the set_data/data calls will succeed on an
    # empty list.
    #
    # data returns a list or arrayref of copied values.

    $list->set_data( 'List Name', [ qw( blah blah ) ] );

    my @data    = $list->data;  # ( 'List Name', [...]  )
    my $data    = $list->data;  # [ 'List Name', [...]  ]

    # lists have a head and tail if they are not empty;
    # accessing the head or tail of an empty list will
    # raise an 'empty list' exception.
    #
    # shift and unshift act on the head node;
    # push and pop affect the tail node.
    #
    # push and pop are slow because they have to find the end
    # of a list. generally prefer unshift and shift or using
    # cursors with append or drop.
    #
    # shift and pop will croak on an empty list while
    # locating the head or tail!
    #
    # nodes store data as a list, you don't need to wrap your
    # contents into an arrayref for storage; set_data, push,
    # and unshift take lists of arguments as one node's data.
    #
    # data is returned as a list or arrayref depending on 
    # context.

    $list->unshift( qw( some data here ) );

    my @data    = $list->shift; # @data = ( 'some','data','here' )
    my $data    = $list->shift; # $data = [ 'some','data','here' ]

    $list->unshift( $_->@* )
    for [ 'hello', 'world!' ], [ 'frobnicate( this )' ];

    # list is 'frobnicate(this)' -> ( 'hello','world' )

    my @data    = $list->pop;   # ( 'hello', 'world!' )
    my @data    = $list->shift; # ( 'fronicate( this )' )

    # node data is whatever was passed to set_data, 
    # unshift, or push. 
    #
    # this creates a node with data of three arrayrefs:

    $list->unshift( [], []. [] );   # one node

    # these both create an empty node:

    $list->unshift;
    $list->push;

    # Cursors reference a node in a list. They are created
    # from a list at the head or from another cursor at 
    # the current node.

    my $list    
    = LinkedList::Single->new->unshift( 'foo' )->unshift( 'bar' );

    my $curs    = $list->cursor;    # $curs references 'bar'.
    my $curs1   = $curs->cursor;    # $curs1 references 'bar'.

    # Cursors objects are true if they are at a data node,
    # they are false when they reference the sentinel node,
    # which can happen if they iterate over the full list
    # (see "advance", below).

    $curs
    or die 'You walked off the list!!!';

    ############################################################
    #
    # NOTE: a cursor is true if it REFERENCES a data (i.e., 
    # non-sentinel) node, not if it's current node HAS data!
    #
    # empty nodes can be created as placeholders, this is an
    # intentional feature of the list. cursors referencing 
    # an empty nodes are true; only cursors referencing 
    # the sentinel node are false.
    #
    ############################################################

    # once there is data on the list cursors can be created,
    # prior to that you will get an 'empty list' exception.
    #
    # cursors have a weak reference to their list in order to
    # use head and tail. if the list is false either by going
    # out of scope or becomming empty (e.g., via shift, pop, 
    # or truncate) then head, tail, and next will all fail
    # with a 'stale list' or 'empty list' exception.

    my $list    = LinkedList::Single->new;

    # $list->cursor will fail until we add some data 

    $list->unshift( $_ ) for qw( foo bar bletch blort );

    # list is now: blort -> bletch -> bar -> foo.
    # .. and Voila! we can generate a cursor:

    my $cursor  = $list->cursor;    # references the head node.
    say $cursor->data;              # "blort".

    # default is LinkedList::Single::Cursor object.
    # use your own class or object to get a derived type.
    # use a class derived from LinkedList::Single::Cursor
    # or an object of that class as the prototype for 
    # your cursor:

    my $cursor  = $list->cursor;                    # LL::S::Cursor
    my $cursor  = $list->cursor( $derived_class  ); # your class
    my $cursor  = $list->cursor( $derived_object ); #      "

    # this simplifies generating a derived list class that
    # returns some derived type of cursor.

    try
    {
        # this sequence will succeed.
        # unshift here creates a new, empty node.

        my $list    = LinkedList::Single->new;
        $list->unshift;

        my $cursor  = $list->cursor
        or die 'Horribly';

        # we get his far becuase there is a node on 
        # the list, even if it's data is empty:

        my @data    = $cursor->data;    # @data == ()
    }
    catch
    {
        # only way in here is if construction failed due to
        # exausting memory; the empty list is not a failure.
    };

    # cursors can be copied to keep bookmarks, perform 
    # iterative searches along the list, or split up a 
    # list for separate processing (see 'Fragments', below).

    for my $tmp_c ( $cursor->cursor )
    {
        # twiddle the list using $tmp_c without affecting
        # $cursor...
    }

    # like the list, $cursor->cursor take a prototype argument:

    my $derived_obj = $cursor->cursor( $class  );
    my $derived_obj = $cursor->cursor( $object );

    # non-empty lists will generate cursors for the head and 
    # tail nodes.

    my $cursor  = $list->head;
    my $cursor  = $list->tail;

    # once created the cursor can move down list list in 
    # two ways: 'next' and 'advance'.
    #
    # "next" is used to walk down only the data nodes of a 
    # list, it will # raise an exception if we try to move 
    # the cursor onto # the sentinel.
    #
    # "avance" will walk onto the sentinel. it is used when 
    # the cursor is supposed to iterate an entire list and 
    # we want to know that no more data is available.

    try
    {
        for(;;)
        {
            # next will not move onto the sentinel.
            # $curs2 is always left on a data node.

            my $curs2   = $curs1->next;
            ...
        }
    }
    catch( $err )
    {
        # get here with an 'onto sentinel' 
        # exception prior to walking off
        # the list.

        $err =~ m{sentinel}
        or die $err;
    }

    try
    {
        my $curs    = $list->cursor;

        for(;;)
        {
            frobnicate( $curs->data );

            $curs->has_next
            or last;

            $curs->next;
        }

        # at this point $curs is left on the last
        # data node, it will be true.

        return $curs
    }
    catch( $err )
    {
        # get here if $list is empty
        # or frobnicate fails.
    }

    # these two leave the cursor on the sentinel,
    # making it easy to determine if the list has
    # been fully iterated.

    try
    {
        # keep walking down the list until the
        # cursor is false.
        #
        # Note: checking $curs every pass through the loop 
        # gets expensive.

        while( $curs )
        {
            frobnicate( $curs->data );

            # advance returns true if the cursor 
            # is still true (i.e., on data) and
            # false when we've moved onto the 
            # sentinel.

            $curs->advance;
        }

        # at this point $curs is on the sentinel node.
        # it will be false, indicating to the caller 
        # that we know the list is complete.

        return $curs
    }
    catch( $err )
    {
        # get here from an exception from frobnicate.
    }

    # template for walking down a list.
    # the handler subref returns false to stop
    # processing the list without an exception.
    
    deal_with_list( $cursor, $handler )
    {

        # this is more efficient since it only has
        # to check the cursor once; after that the
        # return from advance is enough to know 
        # whether we should keep processing.

        $cursor
        or croak 'already on the sentinel';

        for(;;)
        {
            # if $handler raises an exception then $cursor
            # will be left on the node that caused it.

            $handler->( $cursor->data )
            or last;

            # advance returns true if the cursor is still 
            # true (i.e., on data) and false when we've 
            # moved onto the sentinel.

            $cursor->advance
            or last;
        }

        # $cursor is either true on the last node 
        # processed if frobnicate returned false 
        # or false if the entire list was processed.

        return $cursor
    }

    ############################################################
    # a few obvious methods on the cursor handle the
    # usual cases. these take a subref as argument to
    # select the nodes or handle the  contents.
    #
    # Note: These all begin at the cursor's >current< position
    # on the list to allow filtering tail portions of the list
    # or fragments!
    #
    # To filter the full list use $list->grep, etc, to get a new
    # cursor initialized to the head node.
    #
    # each either consumes the full/remaining list or 
    # stops when its handler returns false, returns the cursor.
    # 
    # first leaves the cursor at the first following node for
    # with the selector returns true; if nothing is found then
    # $cursor will be false; first is a more effecient than each
    # if all you want to do is position the cursor based on data.
    #
    # grep and map consume the full/remaining list, returning the
    # node data (grep) or handler output (map) as a list or 
    # arrayref; on completion the cursor will be false to 
    # indicate that the full list has been consumed.
    #
    # Once the list has been consumed a cursor will be false,
    # raising an error on most operations, and can be reset by
    # calling head or tail.
    ############################################################

    # called as $self->$handler for each node.
    # this can modify the list (e.g., $cursor->delete to 
    # remove the current node):

    my $handler = sub( $cursor ) { ... ; return $true_to_continue )

    $cursor->each( $handler );  # iterate from $cursor location.
    $list->  each( $handler );  # iterate a from the list head.

    # called with $select->( $self->data ) for each
    # node, returning perly true/false to select the data.
    # result is a FLAT LIST of all data (i.e., node data is
    # not separately wrapped).
    # modifications to @node_data will not show up in 
    # the returned data.
    #
    # to get separate date per node use map (below).

    my $select  = sub( @node_data ) { ... ; return $boolean }

    my @found   = $cursor->grep( $select );
    my @found   = $list->  grep( $select );

    # called like grep, but pushes the @output into a flat
    # list; to get separate data for each node return 
    # a container (e.g., arrayref) for each node;
    # returning an empty output for a node pushes nothing
    # onto the result (i.e., it can be grep-ish just like
    # the perl's builtin map).

    my $munge   = sub( @node_data ) { ... ; return @output }

    my @result  = $cursor->map( $munge );   # flat list of @munged_data
    my @result  = $list->  map( $munge );

    # for per-node data use:

    my $munge   = sub( @node_data ) { ... ; return \@output }

    # advance the current node until $select returns true 
    # (or we run out of list). list method returns a new 
    # cursor for that location; cursor method modifies the
    # current cursor, returning it. if nothing is found then
    # the returned cursor will be false.

    # new cursor from a cursor location:

    my $select  = sub( @node_data ) { ... ; $true_if_stop_here }

    if( my $cursor = $list->first( $select ) )
    {
        # twiddle $cursor
        ...
    }
    else
    {
        say 'Nothing found for your select anywhere on the list.';
    }

    if( my $curs2  = $cursor->first( $select ) )
    {
        # twiddle $curs2
        ...
    }
    else
    {
        say 'Nothing found for your select below $cursor';
    }

    # or just return the data...

    try
    {
        if( my $cursor  = $list->first( $select ) )
        {
            # returning an arrayref allows checking
            # if nothing at all was returned.

            scalar $cursor->data
        }
        else
        {
            return
        }
    }
    catch( $msg )
    {
        # get here with empty $list or die in $select 

        $msg =~ m{empty list}
        and return;

        die $msg
    }

    # extract the full contents following the cursor or of 
    # the whole list using array refs to have one item per
    # node.
    #
    # notice the lack of arguments, this is a bit faster for
    # longer lists than grep or map.

    my @data    = $cursor->extract;
    my @data    = $list  ->extract;

    # cursors can copy fragments of a full list (e.g., via 
    # truncate). these have a sentinel, but will lack a list
    # to keep them alive outside of the cursor. the data's
    # lifespan is this cursor's and moving the cursor will
    # free the current node as the cursor moves to the next
    # node.
    #
    # truncate ends the list at the current node, but has
    # to copy some data to make that happen; truncate_after
    # drops the following node, which requires a trivial 
    # update to the current one. Both return the trucnated
    # portion of the list as a head node.
    #
    # a simple queue manager can unshift jobs in execution
    # order, find the first executable one, run the queue,
    # and re-queue the jobs if one fails:

    my $queue   = LinkedList::Single->new;

    while( sleep 60 )
    {
        $queue->unshift( $_ )
        for slurp_new_queue_metadata_from_queue_directory;

        # if $run_now never returns true then $jobs is 
        # false to begin when and $the loop never runs.

        my $time    = time;

        my $run_now
        = sub( %job_meta )
        {
            $job_meta{ run_after } < $time
        };

        my $jobs    = $queue->first( $run_now );

        while( $jobs )
        {
            # advance will eventually push $jobs onto the 
            # sentinel, leaving it false.
            #
            # each advance moves the cursor onto a new
            # node, de-referencing the prior one and 
            # freeing it. 
            #
            # anything left on $jobs can be re-queued 
            # with append_list and left for the next pass.

            try
            {
                process_job $job->data
            }
            catch( $err )
            {
                say "Error processing job: $err";
                say 'Requeuing remaining list.';

                $queue->append_list( $jobs );
            }

            $jobs->advance;
        }
    }
    
    # cursors can view or modify the list from their position:

    # read or update the data:
    # list in array mode, arrayref in scalar mode

    my @data        = $cursor->data;    
    my $data        = $cursor->data;  

    # always returns a list (behaves like splice), gives a 
    # count in scalar mode:

    my @old_data    = $cursor->set_data( @new_data );
    my $count       = $cursor->set_data( @new_data );

    # it's common to look at the next node's data.
    # with a list this is the head node's data.
    # these will fail on an empty list or sentinel.

    my @next_data   = $cursor->next_data;
    my @head_data   = $list->next_data;

    ############################################################
    # NOTE:
    # Prefer append to insert to avoid copying data.
    # Prefer drop to delete to avoid copying data.
    #
    # $list->unshift and $list->shift are effectively 
    # insert and delete at the head; but don't to this, use
    # the shift and unshift methods as they are far more 
    # efficient.
    #
    # push and pop are append and delete at the tail.
    ############################################################

    # add a new node following the current one.
    # after this operation $cursor->advance will leave us
    # on the node from which we executed the append:

    $cursor->append( @data );   # next node has new @data

    # insert a new node prior to this one.
    # after this operation $cursor->advance will leave us
    # staring at the next node on the list.

    $cursor->insert( @data );   # current node follows new @data.

    # remove the node following this one, returning its data,
    # raising an exeption if you try to remove past the tail.
    # after this operation $cursor->advance may fail (see 
    # $cursor->can_advance, above).

    my @old_data    = $cursor->drop;

    # remove the current node returning its data (think of
    # hitting the 'Del' key on your keyboard). this may leave 
    # the cursor on the sentinel node, which will raise an 
    # error for any operation other than 'can_advance' or 
    # using the node in a boolean context.

    my @old_data    = $cursor->delete;

    # remove following nodes while there is a list and 
    # the current node matches some_test (see examples
    # with first for better approach):

    $cursor->delete
    while $cursor and some_test( $cursor->data );

    # discard the entre list or nodes follwing the cursor.
    # after this operation $cursor->advance will raise
    # an exception and $list->cursor will also fail due to
    # an empty list.

    my $top_of_list = $cursor->truncate;
    my $entire_list = $list->truncate;

    # create a sub-queue of the remaining nodes to process,
    # leaving the remaining queue on the list (simple FIFO
    # queue).

    sub generate_subque( $list )
    {
        # skip an empty list

        $list or return;

        try
        {
            # $found is a cursor with its node set to the 
            # first entry in $list with a true return from 
            # $timeout_search.

            my $found   = $list->first( $timeout_search )
            or return;

            my $subq = $found->truncate
            or return;

            for(;;)
            {
                process_queue_entry( $subq->data );
                $subq->advance;
            }
        }
        catch( $msg )
        {
            # ignore 'sentinel' nastygrams from the advance.

            $msg =~ m{ sentinel }x
            or die;
        }

        # at this point $subq goes out of scope and its sentinel
        # is discarded, releasing the last of the list contents.
    }


    # there are two was to append a set of nodes to the current 
    # list/cursor:
    #
    # append_list will take the list or a fragment
    # at a cursor and append it to the last node of a list (i.e.,
    # a bulk push) or after a cursor. it returns $self leaving
    # the current node unmodified for a cursor.
    #
    # bulk_append takes a subref arg and appends the results
    # of executing it for each new node, leaving the the
    # cursor's node at the last node appended. the generator
    # returns whatever it likes for the node data, performing
    # a 'die "\n"' when it is done -- which gives the try block
    # an $err of ''.

    # create a new list by grafting off a portion of another list
    # using first.

    try
    {
        my $new_list
        = LinkedList::Single->new
        (
            $old_list->find( $select )->truncate
        );

        # at this point $new_list has everything 
        # truncated off the tail oif $old_list.
    }
    catch( $err )
    {
        # get here if $old_list is empty
        # or finds nothing.
    }

    # generate a new list with whatever data you like.
    # run a query, keep fetching rows until we run out
    # then die with an empty exception. this allows 
    # returning an empty list or explicit undef for the
    # node data.

    sub init_queue
    {
        my $dbh = ... ;
        my $sth = ... ;

        my $rows
        = sub
        {
            $sth->fetchrow_arrayref->@*
            or die "\n"
        }; 

        # caller gets back a new list with the query data
        # appended in row order.

        LinkedList::Single->new->bulk_append( $init_data )
    }

=head1 DESCRIPTION

What you have here are two classes:

    LinkedList::Single::List
    LinkedList::Single::Coursor

and one role:

    LinkedList::Single::NodeMgr

Class similarities:

=over 4

Lists and cursors both access an ordered list of "nodes" that contain 
data and references to the next node. The references only go one way, 
"down" the list and the data may be anything, including other lists, 
or empty.

The last node on any list is a empty "sentinel" node used to track 
whether the list is empty (i.e., the first node is a sentinel) or 
determine if a cursor has iterated through the entire list.

Both lists and cursors can be used in a boolean context, testing if a 
list is not empty or a cursor does not reference the sentinel node.

=back

Basic differences:

=over4 

Lists are anchored and keep their list alive but cannot move;
cursors can move but won't keep their data alive if they move.

List are created empty, have data added to them, and can 
only manipulate their first ("head") and last ("tail") entries.

Cursors are creatd from lists and can manipulate the data from 
the middle.

Cursors can be used to create transient lists that are dependent
on the cursor to keep alive; moving the cursor down a fragment 
will automatically free the previous nodes. This is a Good Thing.

=back

=head2 Basic Structures

=head3 List Class

The class LinkedList::Single::List doesn't actually do much -- the fun 
stuff is handled with cusors, described in the next section. The basic
use of List objects is to anchor the list, keep it referenced, and thus
keep the nodes alive. 

Lists can reference their head, tail, and the data for 'node0' which
anchors the head node. This metadata is not affected by the other list
op's and can be used to store list metadata.

At the end of each list is an empty 'sentinel' node which has 
neither a reference to a next node nor any data. A list with only 
its sentinel node is empty: the list object will test false and 
trying to execute any of head, tail, shift, pop, or creating a 
cursor will fail with an 'empty list' exception.

Each node on the list contains arbitrary data as a list. This means 
that nodes can be empty. An empty data node will have a referencd to
the next node, so the node itself won't be empty, just the data.

=head3 Cursor Class

Instances of LinkedList::Single::Cursor are built from a list or 
one another. They reference the list they were created from, can 
reset themselves to the head or tail of the list, and can also 
walk down the list one node at a time. The ability to move along
the list allows them to search or return list contents and perform
surgery on the list by truncating it and returning the portion 
after a given point. 

Cursors are used to move down the list in the each, grep, map, and 
first methods; the corresponding list methods simply create a new
cursor and call the method on the temp object.

=head4 Fragments

The normal list starts with a List object and proceeds down as a 
sequence of references. The list's root node (not visible through
List or Cursor methods) keeps the list referenced.

The truncate and truncate_next Cursor methods return the head
of a list that is not anchored by a List object. The only 
referant they have is the node reference returned from the 
method. If that goes out of scope so does the list downstream.

This can be useful for consuming temporary portions of a list.
For example, if a queue is unshifted as job arrive then the 
list of jobs after a point in time can be procssed as a unit
using the list, first(), and a select that returns true for the
first job old enough to be worth processing. The queue can be
truncated using the cursor, and a new cursor can walk down the
returned list to submit the jobs. As the cursor advances down
the list the prior node becomes unreferenced and is released
until the cursor is on the sentinel (false). At that point 
if the cursor goes out of scope the entire fragment is gone. 

Fragments can be used to transfer nodes from one list to another 
using truncate() and append_list(), say to accumulate nodes from
worker threads to a main thread's queue.

=head3 NodeMgr role

The List and Cursor classes treat the actual node contents as
opaque. There are places where nodes are assigned or copied
between objects, but the node itself is not unwrapped. This is
done in the NodeMgr class, which... er... Managed Nodes. This 
is where all of the operations on node contents are performed.

The role is used by both List and Cursor classes to perform all
operation on the guts of nodes. 

There are a few reasons for this; mainly that it leaves both classes
insulated from changes in the underlying structure. If some later
arrangement for the nodes works better then it can be replaced inside
of NodeMgr without modifying the classes. 

This also simplifies creating new classes as they can simply apply 
NodeMgr and build on top of it. Derived classes are also insulated
from any changes in the structure. 

=over 4

=item Why make NodeMgr a role not a class?

The role is a bit more flexible, allowing its reuse in any class
that wanted to add list-ish behavior. The classes for List and Cursor 
define the structure and basic behavior required for lists and 
cursors. They use NodeMgr to handle the node operations, but could
use any other node-handler; and any other class wanting to add 
node-ish behavior could use NodeMgr without having to hack its
hierarchy.

Another way to say is is that a list and cursor use nodes, they
aren't nodes; they need node-handling behavior it's not inherit
in their structure.

=back
