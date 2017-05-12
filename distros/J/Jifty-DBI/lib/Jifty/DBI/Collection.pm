package Jifty::DBI::Collection;

use warnings;
use strict;
use Scalar::Defer qw/lazy/;
use Scalar::Util qw/weaken/;
use overload (
    '@{}'       => \&items_array_ref,
    '<>'        => \&next,
    bool        => sub {shift},
    fallback    => 1
);

=head1 NAME

Jifty::DBI::Collection - Encapsulate SQL queries and rows in simple
perl objects

=head1 SYNOPSIS

  use Jifty::DBI::Collection;

  package My::ThingCollection;
  use base qw/Jifty::DBI::Collection/;

  package My::Thing;
  use Jifty::DBI::Schema;
  use Jifty::DBI::Record schema {
    column column_1 => type is 'text';
  };

  package main;

  use Jifty::DBI::Handle;
  my $handle = Jifty::DBI::Handle->new();
  $handle->connect( driver => 'SQLite', database => "my_test_db" );

  my $collection = My::ThingCollection->new( handle => $handle );

  $collection->limit( column => "column_1", value => "matchstring" );

  while ( my $record = $collection->next ) {
      print $record->id;
  }

=head1 DESCRIPTION

This module provides an object-oriented mechanism for retrieving and
updating data in a DBI-accessible database.

In order to use this module, you should create a subclass of
L<Jifty::DBI::Collection> and a subclass of L<Jifty::DBI::Record> for
each table that you wish to access.  (See the documentation of
L<Jifty::DBI::Record> for more information on subclassing it.)

Your L<Jifty::DBI::Collection> subclass must override L</new_item>,
and probably should override at least L</_init> also; at the very
least, L</_init> should probably call L</_handle> and L</_table> to
set the database handle (a L<Jifty::DBI::Handle> object) and table
name for the class -- see the L</SYNOPSIS> for an example.


=cut

use vars qw($VERSION);

use Data::Page;
use Clone;
use Carp qw/croak/;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/pager prefetch_related derived _handle _is_limited rows_per_page/);

=head1 METHODS

=head2 new

Creates a new L<Jifty::DBI::Collection> object and immediately calls
L</_init> with the same parameters that were passed to L</new>.  If
you haven't overridden L<_init> in your subclass, this means that you
should pass in a L<Jifty::DBI::Handle> (or one of its subclasses) like
this:

   my $collection = My::Jifty::DBI::Subclass->new( handle => $handle );

However, if your subclass overrides L</_init> you do not need to take
a handle argument, as long as your subclass takes care of calling the
L</_handle> method somehow.  This is useful if you want all of your
L<Jifty::DBI> objects to use a shared global handle and don't want to
have to explicitly pass it in each time, for example.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->record_class( $proto->record_class ) if ref $proto;
    $self->_init(@_);
    return ($self);
}

=head2 _init

This method is called by L<new> with whatever arguments were passed to
L</new>.  By default, it takes a C<Jifty::DBI::Handle> object as a
C<handle> argument and calls L</_handle> with that.

=cut

sub _init {
    my $self = shift;
    my %args = (
        handle  => undef,
        derived => undef,
        @_
    );
    $self->_handle( $args{'handle'} )  if ( $args{'handle'} );
    $self->derived( $args{'derived'} ) if ( $args{'derived'} );
    $self->table( $self->record_class->table() );
    $self->clean_slate(%args);
}

sub _init_pager {
    my $self = shift;
    return $self->pager( Data::Page->new(0, 10, 1) );
}

=head2 clean_slate

This completely erases all the data in the object. It's useful if a
subclass is doing funky stuff to keep track of a search and wants to
reset the object's data without losing its own data; it's probably
cleaner to accomplish that in a different way, though.

=cut

sub clean_slate {
    my $self = shift;
    my %args = (@_);
    $self->redo_search();
    $self->_init_pager();
    $self->{'itemscount'}       = 0;
    $self->{'tables'}           = "";
    $self->{'auxillary_tables'} = "";
    $self->{'where_clause'}     = "";
    $self->{'limit_clause'}     = "";
    $self->{'order'}            = "";
    $self->{'alias_count'}      = 0;
    $self->{'first_row'}        = 0;

    delete $self->{$_} for qw(
        items
        joins
        raw_rows
        count_all
        subclauses
        restrictions
        _open_parens
        criteria_count
    );

    $self->rows_per_page(0);
    $self->implicit_clauses(%args);
    $self->_is_limited(0);
}

=head2 implicit_clauses

Called by L</clean_slate> to set up any implicit clauses that the
collection B<always> has.  Defaults to doing nothing. Is passed the
paramhash passed into L</new>.

=cut

sub implicit_clauses { }

=head2 _handle [DBH]

Get or set this object's L<Jifty::DBI::Handle> object.

=cut

=head2 _do_search

This internal private method actually executes the search on the
database; it is called automatically the first time that you actually
need results (such as a call to L</next>).

=cut

sub _do_search {
    my $self = shift;

    my $query_string = $self->build_select_query();

    # If we're about to redo the search, we need an empty set of items
    delete $self->{'items'};

    my $records = $self->_handle->simple_query($query_string);
    return 0 unless $records;
    my @names = @{ $records->{NAME_lc} };
    my $data  = {};

    my @tables = map { $_->{alias} } values %{ $self->prefetch_related || {} };

    unless ( @tables ) {
        while ( my $row = $records->fetchrow_hashref() ) {
            $row->{ substr($_, 5) } = delete $row->{ $_ }
                foreach grep rindex($_, "main_", 0) == 0, keys %$row;
            my $item = $self->new_item;
            $item->load_from_hash($row, fast => 1);
            $self->add_record($item);
        }
        if ( $records->err ) {
            $self->{'must_redo_search'} = 0;
        }

        return $self->_record_count;
    }

    my @order;
    my $i = 1;
    while ( my $base_row = $records->fetchrow_hashref() ) {
        my $main_pkey = $base_row->{ $names[0] };
        $main_pkey = 'unique-'.$i++ if $self->{group_by};
        push @order, $main_pkey
            unless ( $order[0] && $order[-1] eq $main_pkey );

        # let's chop the row into subrows;
        foreach my $table ('main', @tables) {
            my %tmp = ();
            for my $k( grep rindex($_, $table ."_", 0) == 0, keys %$base_row ) {
                $tmp{ substr($k, length($table)+1) } = $base_row->{ $k };
            }
            $data->{$main_pkey}{$table}{ $base_row->{ $table . '_id' } || $main_pkey }
                = \%tmp if keys %tmp;
        }
    }

    foreach my $row_id (@order) {
        my $item;
        foreach my $row ( values %{ $data->{$row_id}->{'main'} } ) {
            $item = $self->new_item();
            $item->load_from_hash($row, fast => 1);
        }
        foreach my $alias ( grep { $_ ne 'main' } keys %{ $data->{$row_id} } )
        {

            my $related_rows = $data->{$row_id}->{$alias};
            my ( $class, $col_name )
                = $self->class_and_column_for_alias($alias);
            next unless $class;

            my @rows = sort { $a->{id} <=> $b->{id} }
                grep { $_->{id} } values %$related_rows;

            if ( $class->isa('Jifty::DBI::Collection') ) {
                my $collection = $class->new( $self->_new_collection_args,
                    derived => 1 );
                foreach my $row (@rows) {
                    my $entry = $collection->new_item;
                    $entry->load_from_hash($row, fast => 1);
                    $collection->add_record($entry);
                }

                $item->prefetched( $col_name => $collection );
            } elsif ( $class->isa('Jifty::DBI::Record') ) {
                warn "Multiple rows returned for $class in prefetch"
                    if @rows > 1;
                my $entry = $class->new( $self->_new_record_args );
                $entry->load_from_hash( shift(@rows), fast => 1 ) if @rows;
                $item->prefetched( $col_name => $entry );
            } else {
                Carp::cluck(
                    "Asked to prefetch $alias as a $class. Don't know how to handle $class"
                );
            }
        }
        $self->add_record($item);

    }
    if ( $records->err ) {
        $self->{'must_redo_search'} = 0;
    }

    return $self->_record_count;
}

sub _new_record_args {
    my $self = shift;
    return ( handle => $self->_handle );
}

sub _new_collection_args {
    my $self = shift;
    return ( handle => $self->_handle );
}

=head2 add_record RECORD

Adds a record object to this collection.

This method automatically sets our "must redo search" flag to 0 and our "we have limits" flag to 1.

Without those two flags, counting the number of items wouldn't work.

=cut

sub add_record {
    my $self   = shift;
    my $record = shift;
    $self->_is_limited(1);
    $self->{'must_redo_search'} = 0;
    push @{ $self->{'items'} }, $record;
}

=head2 _record_count

This private internal method returns the number of
L<Jifty::DBI::Record> objects saved as a result of the last query.

=cut

sub _record_count {
    my $self = shift;
    return 0 unless defined $self->{'items'};
    return scalar @{ $self->{'items'} };
}

=head2 _do_count

This internal private method actually executes a counting operation on
the database; it is used by L</count> and L</count_all>.

=cut

sub _do_count {
    my $self = shift;
    my $all = shift || 0;

    my $query_string = $self->build_select_count_query();
    my $records      = $self->_handle->simple_query($query_string);
    return 0 unless $records;

    my @row = $records->fetchrow_array();
    return 0 if $records->err;

    $self->{ $all ? 'count_all' : 'raw_rows' } = $row[0];

    return ( $row[0] );
}

=head2 _apply_limits STATEMENTREF

This routine takes a reference to a scalar containing an SQL
statement.  It massages the statement to limit the returned rows to
only C<< $self->rows_per_page >> rows, skipping C<< $self->first_row >>
rows.  (That is, if rows are numbered starting from 0, row number
C<< $self->first_row >> will be the first row returned.)  Note that it
probably makes no sense to set these variables unless you are also
enforcing an ordering on the rows (with L</order_by>, say).

=cut

sub _apply_limits {
    my $self         = shift;
    my $statementref = shift;
    $self->_handle->apply_limits( $statementref, $self->rows_per_page,
        $self->first_row );

}

=head2 _distinct_query STATEMENTREF

This routine takes a reference to a scalar containing an SQL
statement.  It massages the statement to ensure a distinct result set
is returned.

=cut

sub _distinct_query {
    my $self         = shift;
    my $statementref = shift;
    $self->_handle->distinct_query( $statementref, $self );
}

=head2 _build_joins

Build up all of the joins we need to perform this query.

=cut

sub _build_joins {
    my $self = shift;

    return ( $self->_handle->_build_joins($self) );

}

=head2 _is_joined 

Returns true if this collection will be joining multiple tables
together.

=cut

sub _is_joined {
    my $self = shift;
    if ( $self->{'joins'} && keys %{ $self->{'joins'} } ) {
        return (1);
    } else {
        return 0;
    }
}

=head2 _is_distinctly_joined

Returns true if this collection is joining multiple table, but is
joining other table's distinct fields, hence resulting in distinct
resultsets.  The behaviour is undefined if called on a non-joining
collection.

=cut

sub _is_distinctly_joined {
    my $self = shift;
    if ( $self->{'joins'} ) {
        for ( values %{ $self->{'joins'} } ) {
            return 0 unless $_->{is_distinct};
        }

        return 1;
    }
}

=head2 _is_limited

If we've limited down this search, return true. Otherwise, return
false. 

C<1> means "we have limits"
C<-1> means "we should return all rows. We want no where clause"
C<0> means "no limits have been applied yet.

=cut

=head2 build_select_query

Builds a query string for a "SELECT rows from Tables" statement for
this collection

=cut

sub build_select_query {
    my $self = shift;

    return "" if $self->derived;

    # The initial SELECT or SELECT DISTINCT is decided later

    my $query_string = $self->_build_joins . " ";

    if ( $self->_is_limited ) {
        $query_string .= $self->_where_clause . " ";
    }
    if ( $self->distinct_required ) {

        # DISTINCT query only required for multi-table selects
        $self->_distinct_query( \$query_string );
    } else {
        $query_string
            = "SELECT " . $self->query_columns . " FROM $query_string";
        $query_string .= $self->_group_clause;
        $query_string .= $self->_order_clause;
    }

    $self->_apply_limits( \$query_string );

    return ($query_string)

}

=head2 query_columns

The columns that the query would load for result items.  By default
it's everything.

=cut

sub query_columns {
    my $self = shift;

    my @cols = ();
    if ( $self->{columns} and @{ $self->{columns} } ) {
        push @cols, @{ $self->{columns} };
    } else {
        push @cols, $self->_qualified_record_columns( 'main' => $self->record_class );
    }
    my %prefetch_related = %{ $self->prefetch_related || {} };
    foreach my $alias ( keys %prefetch_related ) {
        my $class = $prefetch_related{$alias}{class};

        my $reference;
        if ( $class->isa('Jifty::DBI::Collection') ) {
            $reference = $class->record_class;
        } elsif ( $class->isa('Jifty::DBI::Record') ) {
            $reference = $class;
        }

        my $only_cols = $prefetch_related{$alias}{columns};

        push @cols, $self->_qualified_record_columns( $alias => $reference, $only_cols );
    }
    return CORE::join( ', ', @cols );
}

=head2 class_and_column_for_alias

Takes the alias you've assigned to a prefetched related
object. Returns the class of the column we've declared that alias
prefetches.

=cut

sub class_and_column_for_alias {
    my $self     = shift;
    my $alias    = shift;
    my %prefetch = %{ $self->prefetch_related || {} };
    my $related  = $prefetch{$alias};
    return unless $related;

    return $related->{class}, $related->{name};
}

sub _qualified_record_columns {
    my $self  = shift;
    my $alias = shift;
    my $item  = shift;
    my $only_cols = shift;
    my @columns = map { $_->name } grep { !$_->virtual && !$_->computed } $item->columns;
    if ($only_cols) {
        my %wanted = map { +($_ => 1) } @{ $only_cols };
        @columns = grep { $wanted{$_} } @columns;
    }
    return map {$alias ."." . $_ ." as ". $alias ."_". $_} @columns
}

=head2 prefetch PARAMHASH

Prefetches properties of a related table, in the same query.  Possible
keys in the paramhash are:

=over

=item name

This argument is required; it specifies the name of the collection or
record that is to be prefetched.  If the name matches a column with a
C<refers_to> relationship, the other arguments can be inferred, and
this is the only parameter which needs to be passed.

It is possible to pass values for C<name> which are not real columns
in the model; these, while they won't be accessible by calling 
C<< $record-> I<columnname> >> on records in this collection, will
still be accessible by calling C<< $record->prefetched( I<columnname> ) >>.

=item reference

Specifies the series of column names to traverse to extract the
information.  For instance, if groups referred to multiple users, and
users referred to multiple phone numbers, then providing
C<users.phones> would do the two necessary joins to produce a phone
collection for all users in each group.

This option defaults to the name, and is irrelevant if an C<alias> is
provided.

=item alias

Specifies an alias which has already been joined to this collection as
the source of the prefetched data.  C<class> will also need to be
specified.

=item class

Specifies the class of the data to preload.  This is only necessary if
C<alias> is provided, and C<name> is not the name of a column which
provides C<refers_to> information.

=back

For backwards compatibility, C<prefetch> can instead be called with
C<alias> and C<name> as its two arguments, instead of a paramhash.

=cut

sub prefetch {
    my $self = shift;

    # Back-compat
    if ( @_ and $self->{joins}{ $_[0] } ) {

        # First argument appears to be an alias
        @_ = ( alias => $_[0], name => $_[1] );
    }

    my %args = (
        alias     => undef,
        name      => undef,
        class     => undef,
        reference => undef,
        columns   => undef,
        @_,
    );

    die "Must at least provide name to prefetch"
        unless $args{name};

    # Reference defaults to name
    $args{reference} ||= $args{name};

    # If we don't have an alias, do the join
    if ( not $args{alias} ) {
        my ( $class, @columns )
            = $self->find_class( split /\./, $args{reference} );
        $args{class} = ref $class;
        ( $args{alias} ) = $self->resolve_join(@columns);
    }

    if ( not $args{class} ) {

        # Check the column
        my $column = $self->record_class->column( $args{name} );
        $args{class} = $column->refers_to if $column;

        die "Don't know class" unless $args{class};
    }

    # Check that the class is a Jifty::DBI::Record or Jifty::DBI::Collection
    unless ( UNIVERSAL::isa( $args{class}, "Jifty::DBI::Record" )
        or UNIVERSAL::isa( $args{class}, "Jifty::DBI::Collection" ) )
    {
        warn
            "Class ($args{class}) isn't a Jifty::DBI::Record or Jifty::DBI::Collection";
        return undef;
    }

    $self->prefetch_related( {} ) unless $self->prefetch_related;
    $self->prefetch_related->{ $args{alias} } = {};
    $self->prefetch_related->{ $args{alias} }{$_} = $args{$_}
        for qw/alias class name columns/;

    # Return the alias, in case we made it
    return $args{alias};
}

=head2 find_column NAMES

Tales a chained list of column names, where all but the last element
is the name of a column on the previous class which refers to the next
collection or record.  Returns a list of L<Jifty::DBI::Column> objects
for the list.

=cut

sub find_column {
    my $self  = shift;
    my @names = @_;

    my $last = pop @names;
    my ( $class, @columns ) = $self->find_class(@names);
    $class = $class->record_class
        if UNIVERSAL::isa( $class, "Jifty::DBI::Collection" );
    my $column = $class->column($last);
    die "$class has no column '$last'" unless $column;
    return @columns, $column;
}

=head2 find_class NAMES

Tales a chained list of column names, where each element is the name
of a column on the previous class which refers to the next collection
or record.  Returns an instance of the ending class, followed by the
list of L<Jifty::DBI::Column> objects traversed to get there.

=cut

sub find_class {
    my $self  = shift;
    my @names = @_;

    my @res;
    my $object = $self;
    my $itemclass = $self->record_class;
    while ( my $name = shift @names ) {
        my $column = $itemclass->column($name);
        die "$itemclass has no column '$name'" unless $column;

        push @res, $column;

        my $classname = $column->refers_to;
        unless ($classname) {
            die "column '$name' of $itemclass is not a reference";
        }

        if ( UNIVERSAL::isa( $classname, 'Jifty::DBI::Collection' ) ) {
            $object = $classname->new( $self->_new_collection_args );
            $itemclass = $object->record_class;
        } elsif ( UNIVERSAL::isa( $classname, 'Jifty::DBI::Record' ) ) {
            $object = $classname->new( $self->_new_record_args );
            $itemclass = $classname;
        } else {
            die
                "Column '$name' refers to '$classname' which is not record or collection";
        }
    }

    return $object, @res;
}

=head2 resolve_join COLUMNS

Takes a chained list of L<Jifty::DBI::Column> objects, and performs
the requisite joins to join all of them.  Returns the alias of the
last join.

=cut

sub resolve_join {
    my $self  = shift;
    my @chain = @_;

    my $last_alias = 'main';

    foreach my $column (@chain) {
        my $name = $column->name;

        my $classname = $column->refers_to;
        unless ($classname) {
            die "column '$name' of is not a reference";
        }

        if ( UNIVERSAL::isa( $classname, 'Jifty::DBI::Collection' ) ) {
            my $right_alias = $self->new_alias($classname->record_class);
            $self->join(
                type        => 'left',
                alias1      => $last_alias,
                column1     => 'id',
                alias2      => $right_alias,
                column2     => $column->by || 'id',
                is_distinct => 1,
            );
            $last_alias = $right_alias;
        } elsif ( UNIVERSAL::isa( $classname, 'Jifty::DBI::Record' ) ) {
            my $right_alias = $self->new_alias($classname);
            $self->join(
                type        => 'left',
                alias1      => $last_alias,
                column1     => $name,
                alias2      => $right_alias,
                column2     => $column->by || 'id',
                is_distinct => 1,
            );
            $last_alias = $right_alias;
        } else {
            die
                "Column '$name' refers to '$classname' which is not record or collection";
        }
    }
    return $last_alias;
}

=head2 distinct_required

Returns true if Jifty::DBI expects that this result set will end up
with repeated rows and should be "condensed" down to a single row for
each unique primary key.

Out of the box, this method returns true if you've joined to another table.
To add additional logic, feel free to override this method in your subclass.

XXX TODO: it should be possible to create a better heuristic than the simple
"is it joined?" question we're asking now. Something along the lines of "are we
joining this table to something that is not the other table's primary key"

=cut

sub distinct_required {
    my $self = shift;
    return ( $self->_is_joined ? !$self->_is_distinctly_joined : 0 );
}

=head2 build_select_count_query

Builds a SELECT statement to find the number of rows this collection
 would find.

=cut

sub build_select_count_query {
    my $self = shift;

    return "" if $self->derived;

    my $query_string = $self->_build_joins . " ";

    if ( $self->_is_limited ) {
        $query_string .= $self->_where_clause . " ";
    }

    # DISTINCT query only required for multi-table selects
    if ( $self->distinct_required or $self->prefetch_related ) {
        $query_string = $self->_handle->distinct_count( \$query_string );
    } else {
        $query_string = "SELECT count(main.id) FROM " . $query_string;
    }

    return ($query_string);
}

=head2 do_search

C<Jifty::DBI::Collection> usually does searches "lazily". That is, it
does a C<SELECT COUNT> or a C<SELECT> on the fly the first time you ask
for results that would need one or the other.  Sometimes, you need to
display a count of results found before you iterate over a collection,
but you know you're about to do that too. To save a bit of wear and tear
on your database, call C<do_search> before that C<count>.

=cut

sub do_search {
    my $self = shift;
    return if $self->derived;
    $self->_do_search() if $self->{'must_redo_search'};

}

=head2 next

Returns the next row from the set as an object of the type defined by
sub new_item.  When the complete set has been iterated through,
returns undef and resets the search such that the following call to
L</next> will start over with the first item retrieved from the
database.

You may also call this method via the built-in iterator syntax.
The two lines below are equivalent:

    while ($_ = $collection->next) { ... }

    while (<$collection>) { ... }

=cut

sub next {
    my $self = shift;

    my $item = $self->peek;

    if ( $self->{'itemscount'} < $self->_record_count ) {
        $self->{'itemscount'}++;
    } else {    #we've gone through the whole list. reset the count.
        $self->goto_first_item();
    }

    return ($item);
}

=head2 peek

Exactly the same as next, only it doesn't move the iterator.

=cut

sub peek {
    my $self = shift;

    return (undef) unless ( $self->_is_limited );

    $self->_do_search() if $self->{'must_redo_search'};

    if ( $self->{'itemscount'} < $self->_record_count )
    {    #return the next item
        my $item = ( $self->{'items'}[ $self->{'itemscount'} ] );
        return ($item);
    } else {    #no more items!
        return (undef);
    }
}

=head2 goto_first_item

Starts the recordset counter over from the first item. The next time
you call L</next>, you'll get the first item returned by the database,
as if you'd just started iterating through the result set.

=cut

sub goto_first_item {
    my $self = shift;
    $self->goto_item(0);
}

=head2 goto_item

Takes an integer, n.  Sets the record counter to n. the next time you
call L</next>, you'll get the nth item.

=cut

sub goto_item {
    my $self = shift;
    my $item = shift;
    $self->{'itemscount'} = $item;
}

=head2 first

Returns the first item

=cut

sub first {
    my $self = shift;
    $self->goto_first_item();
    return ( $self->next );
}

=head2 last

Returns the last item

=cut

sub last {
    my $self = shift;
    $self->goto_item( ( $self->count ) - 1 );
    return ( $self->next );
}

=head2 distinct_column_values

Takes a column name and returns distinct values of the column.
Only values in the current collection are returned.

Optional arguments are C<max> and C<sort> to limit number of
values returned and it makes sense to sort results.

    $col->distinct_column_values('column');

    $col->distinct_column_values(column => 'column');

    $col->distinct_column_values('column', max => 10, sort => 'asc');

=cut

sub distinct_column_values {
    my $self = shift;
    my %args = (
        column => undef,
        sort   => undef,
        max    => undef,
        @_%2 ? (column => @_) : (@_)
    );

    return () if $self->derived;

    my $query_string = $self->_build_joins;
    if ( $self->_is_limited ) {
        $query_string .= ' '. $self->_where_clause . " ";
    }

    my $column = 'main.'. $args{'column'};
    $query_string = 'SELECT DISTINCT '. $column .' FROM '. $query_string;

    if ( $args{'sort'} ) {
        $query_string .= ' ORDER BY '. $column
            .' '. ($args{'sort'} =~ /^des/i ? 'DESC' : 'ASC');
    }

    my $sth  = $self->_handle->simple_query( $query_string ) or return;
    my $value;
    $sth->bind_col(1, \$value) or return;
    my @col;
    if ($args{max}) {
        push @col, $value while 0 < $args{max}-- && $sth->fetch;
    } else {
        push @col, $value while $sth->fetch;
    }
    return @col;
}

=head2 items_array_ref

Return a reference to an array containing all objects found by this
search.

You may also call this method via the built-in array dereference syntax.
The two lines below are equivalent:

    for (@{$collection->items_array_ref}) { ... }

    for (@$collection) { ... }

=cut

sub items_array_ref {
    my $self = shift;

    # If we're not limited, return an empty array
    return [] unless $self->_is_limited;

    # Do a search if we need to.
    $self->_do_search() if $self->{'must_redo_search'};

    # If we've got any items in the array, return them.  Otherwise,
    # return an empty array
    return ( $self->{'items'} || [] );
}

=head2 new_item

Should return a new object of the correct type for the current collection.
L</record_class> method is used to determine class of the object.

Each record class at least once is loaded using require. This method is
called each time a record fetched so load attempts are cached to avoid
penalties. If you're sure that all record classes are loaded before
first use then you can override this method.

=cut

{ my %cache = ();
sub new_item {
    my $self  = shift;
    my $class = $self->record_class();

    die "Jifty::DBI::Collection needs to be subclassed; override new_item\n"
        unless $class;

    unless ( exists $cache{$class} ) {
        $class->require;
        $cache{$class} = undef;
    }
    return $class->new( $self->_new_record_args );
} }

=head2 record_class

Returns the record class which this is a collection of; override this
to subclass.  Or, pass it the name of a class as an argument after
creating a C<Jifty::DBI::Collection> object to create an 'anonymous'
collection class.

If you haven't specified a record class, this returns a best guess at
the name of the record class for this collection.

It uses a simple heuristic to determine the record class name -- It
chops "Collection" or "s" off its own name. If you want to name your
records and collections differently, go right ahead, but don't say we
didn't warn you.

=cut

sub record_class {
    my $self = shift;
    if (@_) {
        $self->{record_class} = shift if (@_);
        $self->{record_class} = ref $self->{record_class}
            if ref $self->{record_class};
    } elsif ( not ref $self or not $self->{record_class} ) {
        my $class = ref($self) || $self;
        $class =~ s/(?<!:)(Collection|s)$//
            || die "Can't guess record class from $class";
        return $class unless ref $self;
        $self->{record_class} = $class;
    }
    return $self->{record_class};
}

=head2 redo_search

Takes no arguments.  Tells Jifty::DBI::Collection that the next time
it is asked for a record, it should re-execute the query.

=cut

sub redo_search {
    my $self = shift;
    $self->{'must_redo_search'} = 1;
    delete $self->{$_} for qw(items raw_rows count_all);
    $self->{'itemscount'} = 0;
}

=head2 unlimit

Unlimit clears all restrictions on this collection and resets
it to a "default" pristine state. Note, in particular, that 
this means C<unlimit> will erase ordering and grouping 
metadata.  To find all rows without resetting this metadata,
use the C<find_all_rows> method.

=cut

sub unlimit {
    my $self = shift;

    $self->clean_slate();
    $self->_is_limited(-1);
}

=head2 find_all_rows

C<find_all_rows> instructs this collection class to return all rows in
the table. (It removes the WHERE clause from your query).

=cut

sub find_all_rows {
    my $self = shift;
    $self->_is_limited(-1);
}

=head2 limit

Takes a hash of parameters with the following keys:

=over 4

=item table 

Can be set to something different than this table if a join is
wanted (that means we can't do recursive joins as for now).  

=item alias

Unless alias is set, the join criteria will be taken from EXT_LINKcolumn
and INT_LINKcolumn and added to the criteria.  If alias is set, new
criteria about the foreign table will be added.

=item column

Column to be checked against.

=item value

Should always be set and will always be quoted.  If the value is a
subclass of Jifty::DBI::Object, the value will be interpreted to be
the object's id.

=item operator

operator is the SQL operator to use for this phrase.  Possible choices include:

=over 4

=item "="

=item "!="

Any other standard SQL comparison operators that your underlying
database supports are also valid.

=item "LIKE"

=item "NOT LIKE"

=item "MATCHES"

MATCHES is like LIKE, except it surrounds the value with % signs.

=item "starts_with"

starts_with is like LIKE, except it only appends a % at the end of the string

=item "ends_with"

ends_with is like LIKE, except it prepends a % to the beginning of the string

=item "IN"

IN matches a column within a set of values.  The value specified in the limit
should be an array reference of values.

=item "IS"

=item "IS NOT"

This is useful for when you wish to match columns that contain NULL (or ones that don't). Use this operator and a value of "NULL".

=back

=item escape

If you need to escape wildcard characters (usually _ or %) in the value *explicitly* with 
"ESCAPE", set the  escape character here. Note that backslashes may require special treatment 
(e.g. Postgres dislikes \ or \\ in queries unless we use the E'' syntax).

=item entry_aggregator 

Can be AND or OR (or anything else valid to aggregate two clauses in SQL)

=item case_sensitive

on some databases, such as postgres, setting case_sensitive to 1 will make
this search case sensitive.  Note that this flag is ignored if the column
is numeric.

=back

=cut 

sub limit {
    my $self = shift;
    my %args = (
        table            => undef,
        alias            => undef,
        column           => undef,
        value            => undef,
        quote_value      => 1,
        entry_aggregator => 'or',
        case_sensitive   => undef,
        operator         => '=',
        escape           => undef,
        subclause        => undef,
        leftjoin         => undef,
        @_    # get the real argumentlist
    );

    return if $self->derived;

    #If we're performing a left join, we really want the alias to be the
    #left join criterion.

    if (   ( defined $args{'leftjoin'} )
        && ( not defined $args{'alias'} ) )
    {
        $args{'alias'} = $args{'leftjoin'};
    }

    # {{{ if there's no alias set, we need to set it

    unless ( defined $args{'alias'} ) {

        #if the table we're looking at is the same as the main table
        if ( !defined $args{'table'} || $args{'table'} eq $self->table ) {

            # TODO this code assumes no self joins on that table.
            # if someone can name a case where we'd want to do that,
            # I'll change it.

            $args{'alias'} = 'main';
        }

        else {
            $args{'alias'} = $self->new_alias( $args{'table'} );
        }
    }

    # }}}

    # $column_obj is undefined when the table2 argument to the join is a table
    # name and not a collection model class.  In that case, the class key
    # doesn't exist for the join.
    my $class
        = $self->{joins}{ $args{alias} }
        && $self->{joins}{ $args{alias} }{class}
        ? $self->{joins}{ $args{alias} }{class}
        ->new( $self->_new_collection_args )
        : $self;
    my $column_obj = $class->record_class->column( $args{column} );

    $self->new_item->_apply_input_filters(
        column    => $column_obj,
        value_ref => \$args{'value'},
    ) if $column_obj && $column_obj->encode_on_select && $args{operator} !~ /IS/;

    # Ensure that the column has nothing fishy going on.  We can't
    # simply check $column_obj's truth because joins mostly join by
    # table name, not class, and we don't track table_name -> class.
    if ($args{column} =~ /\W/) {
        warn "Possible SQL injection on column '$args{column}' in limit at @{[join(',',(caller)[1,2])]}\n";
        %args = (
            %args,
            column   => 'id',
            operator => '<',
            value    => 0,
        );
    }
    if ($args{operator} !~ /^(=|<|>|!=|<>|<=|>=
                             |(NOT\s*)?LIKE
                             |(NOT\s*)?(STARTS|ENDS)_?WITH
                             |(NOT\s*)?MATCHES
                             |IS(\s*NOT)?
                             |IN)$/ix) {
        warn "Unknown operator '$args{operator}' in limit at  @{[join(',',(caller)[1,2])]}\n";
        %args = (
            %args,
            column   => 'id',
            operator => '<',
            value    => 0,
        );
    }


    # Set this to the name of the column and the alias, unless we've been
    # handed a subclause name
    my $qualified_column
        = $args{'alias'}
        ? $args{'alias'} . "." . $args{'column'}
        : $args{'column'};
    my $clause_id = $args{'subclause'} || $qualified_column;


    # make passing in an object DTRT
    my $value_ref = ref( $args{value} );
    if ($value_ref) {
        if ( ( $value_ref ne 'ARRAY' )
            && $args{value}->isa('Jifty::DBI::Record') )
        {
            my $by = (defined $column_obj and defined $column_obj->by)
                        ? $column_obj->by
                        : 'id';
            $args{value} = $args{value}->$by;
        } elsif ( $value_ref eq 'ARRAY' ) {

            # Don't modify the original reference, it isn't polite
            $args{value} = [ @{ $args{value} } ];
            map {
                my $by = (defined $column_obj and defined $column_obj->by)
                            ? $column_obj->by
                            : 'id';
                $_ = (
                      ( ref $_ && $_->isa('Jifty::DBI::Record') )
                    ? ( $_->$by )
                    : $_
                )
            } @{ $args{value} };
        }
    }

    #since we're changing the search criteria, we need to redo the search
    $self->redo_search();

    #If it's a like, we supply the %s around the search term
    if ( $args{'operator'} =~ /MATCHES/i ) {
        $args{'value'} = "%" . $args{'value'} . "%";
    } elsif ( $args{'operator'} =~ /STARTS_?WITH/i ) {
        $args{'value'} = $args{'value'} . "%";
    } elsif ( $args{'operator'} =~ /ENDS_?WITH/i ) {
        $args{'value'} = "%" . $args{'value'};
    }
    $args{'operator'} =~ s/(?:MATCHES|ENDS_?WITH|STARTS_?WITH)/LIKE/i;

    # Force the value to NULL (non-quoted) if the operator is IS.
    if ($args{'operator'} =~ /^IS(\s*NOT)?$/i) {
        $args{'quote_value'} = 0;
        $args{'value'} = 'NULL';
    }

    # Quote the value
    if ( $args{'quote_value'} ) {
        if ( $value_ref eq 'ARRAY' ) {
            map { $_ = $self->_handle->quote_value($_) } @{ $args{'value'} };
        } else {
            $args{'value'} = $self->_handle->quote_value( $args{'value'} );
        }
    }

    if ( $args{'escape'} ) {
        $args{'escape'} = 'ESCAPE ' . $self->_handle->quote_value( $args{escape} );
    }

    # If we're trying to get a leftjoin restriction, lets set
    # $restriction to point there. otherwise, lets construct normally

    my $restriction;
    if ( $args{'leftjoin'} ) {
        $restriction
            = $self->{'joins'}{ $args{'leftjoin'} }{'criteria'}{$clause_id}
            ||= [];
    } else {
        $restriction = $self->{'restrictions'}{$clause_id} ||= [];
    }

    # If it's a new value or we're overwriting this sort of restriction,

    if ( defined $args{'value'} && $args{'quote_value'} ) {
        my $case_sensitive = 0;
        if ( defined $args{'case_sensitive'} ) {
            $case_sensitive = $args{'case_sensitive'};
        }
        elsif ( $column_obj ) {
            $case_sensitive = $column_obj->case_sensitive;
        }
        # don't worry about case for numeric columns_in_db
        # only be case insensitive when we KNOW it's a text
        if ( $column_obj && !$case_sensitive && !$column_obj->is_string ) {
            $case_sensitive = 1;
        }

        if ( !$case_sensitive && $self->_handle->case_sensitive ) {
            ( $qualified_column, $args{'operator'}, $args{'value'} )
                = $self->_handle->_make_clause_case_insensitive(
                $qualified_column, $args{'operator'}, $args{'value'} );
        }
    }

    if ( $value_ref eq 'ARRAY' ) {
        croak
            'Limits with an array ref are only allowed with operator \'IN\' or \'=\''
            unless $args{'operator'} =~ /^(IN|=)$/i;
        $args{'value'} = '( ' . join( ',', @{ $args{'value'} } ) . ' )';
        $args{'operator'} = 'IN';
    }

    my $clause = {
        column   => $qualified_column,
        operator => $args{'operator'},
        value    => $args{'value'},
        escape   => $args{'escape'},
    };

    # Juju because this should come _AFTER_ the EA
    my @prefix;
    if ( $self->{'_open_parens'}{$clause_id} ) {
        @prefix = ('(') x delete $self->{'_open_parens'}{$clause_id};
    }

    if ( lc( $args{'entry_aggregator'} || "" ) eq 'none' || !@$restriction ) {
        @$restriction = ( @prefix, $clause );
    } else {
        push @$restriction, $args{'entry_aggregator'}, @prefix, $clause;
    }

    # We're now limited. people can do searches.

    $self->_is_limited(1);

    if ( defined( $args{'alias'} ) ) {
        return ( $args{'alias'} );
    } else {
        return (1);
    }
}

=head2 open_paren CLAUSE

Places an open parenthesis at the current location in the given C<CLAUSE>.
Note that this can be used for Deep Magic, and has a high likelihood
of allowing you to construct malformed SQL queries.  Its interface
will probably change in the near future, but its presence allows for
arbitrarily complex queries.

Here's an example, to construct a SQL WHERE clause roughly equivalent to (depending on your SQL dialect):

  parent = 12 AND task_type = 'action' 
      AND (status = 'open' 
          OR (status = 'done' 
              AND completed_on >= '2008-06-26 11:39:22'))

You can use sub-clauses and C<open_paren> and C<close_paren> as follows:

  $col->limit( column => 'parent', value => 12 );
  $col->limit( column => 'task_type', value => 'action' );

  $col->open_paren("my_clause");

  $col->limit( subclause => "my_clause", column => 'status', value => 'open' );

  $col->open_paren("my_clause");

  $col->limit( subclause => "my_clause", column => 'status', 
      value => 'done', entry_aggregator => 'OR' );
  $col->limit( subclause => "my_clause", column => 'completed_on',
      operator => '>=', value => '2008-06-26 11:39:22' );

  $col->close_paren("my_clause");

  $col->close_paren("my_clause");

Where the C<"my_clause"> can be any name you choose.

=cut

sub open_paren {
    my ( $self, $clause ) = @_;
    $self->{_open_parens}{$clause}++;
}

=head2 close_paren CLAUSE

Places a close parenthesis at the current location in the given C<CLAUSE>.
Note that this can be used for Deep Magic, and has a high likelihood
of allowing you to construct malformed SQL queries.  Its interface
will probably change in the near future, but its presence allows for
arbitrarily complex queries.

=cut

# Immediate Action
sub close_paren {
    my ( $self, $clause ) = @_;
    my $restriction = $self->{'restrictions'}{$clause} ||= [];
    push @$restriction, ')';
}

sub _add_subclause {
    my $self      = shift;
    my $clauseid  = shift;
    my $subclause = shift;

    $self->{'subclauses'}{"$clauseid"} = $subclause;

}

sub _where_clause {
    my $self         = shift;
    my $where_clause = '';

    # Go through all the generic restrictions and build up the
    # "generic_restrictions" subclause.  That's the only one that the
    # collection builds itself.  Arguably, the abstraction should be
    # better, but I don't really see where to put it.
    $self->_compile_generic_restrictions();

    #Go through all restriction types. Build the where clause from the
    #Various subclauses.

    my @subclauses = grep defined && length,
        values %{ $self->{'subclauses'} };

    $where_clause = " WHERE " . CORE::join( ' AND ', @subclauses )
        if (@subclauses);

    return ($where_clause);

}

#Compile the restrictions to a WHERE Clause

sub _compile_generic_restrictions {
    my $self = shift;

    delete $self->{'subclauses'}{'generic_restrictions'};

 # Go through all the restrictions of this type. Buld up the generic subclause
    my $result = '';
    foreach my $restriction ( grep $_ && @$_,
        values %{ $self->{'restrictions'} } )
    {
        $result .= ' AND ' if $result;
        $result .= '(';
        foreach my $entry (@$restriction) {
            unless ( ref $entry ) {
                $result .= ' ' . $entry . ' ';
            } else {
                $result .= join ' ',
                    grep {defined}
                    @{$entry}{qw(column operator value escape)};
            }
        }
        $result .= ')';
    }
    return ( $self->{'subclauses'}{'generic_restrictions'} = $result );
}

# set $self->{$type .'_clause'} to new value
# redo_search only if new value is really new
sub _set_clause {
    my $self = shift;
    my ( $type, $value ) = @_;
    $type .= '_clause';
    if ( ( $self->{$type} || '' ) ne ( $value || '' ) ) {
        $self->redo_search;
    }
    $self->{$type} = $value;
}

# stub for back-compat
sub _quote_value {
    my $self = shift;
    return $self->_handle->quote_value(@_);
}

=head2 order_by_cols DEPRECATED

*DEPRECATED*. Use C<order_by> method.

=cut

sub order_by_cols {
    require Carp;
    Carp::cluck("order_by_cols is deprecated, use order_by method");
    goto &order_by;
}

=head2 order_by EMPTY|HASH|ARRAY_OF_HASHES

Orders the returned results by column(s) and/or function(s) on column(s).

Takes a paramhash of C<alias>, C<column> and C<order>
or C<function> and C<order>.
C<alias> defaults to main.
C<order> defaults to ASC(ending), DES(cending) is also a valid value.
C<column> and C<function> have no default values.

Use C<function> instead of C<alias> and C<column> to order by
the function value. Note that if you want use a column as argument of
the function then you have to build correct reference with alias
in the C<alias.column> format.

If you specify C<function> and C<column>, the column (and C<alias>) will be
wrapped in the function.  This is useful for simple functions like C<min> or
C<lower>.

Use array of hashes to order by many columns/functions.

Calling this I<sets> the ordering, it doesn't refine it. If you want to keep
previous ordering, use C<add_order_by>.

The results would be unordered if method called without arguments.

Returns the current list of columns.

=cut

sub order_by {
    my $self = shift;
    return if $self->derived;
    if (@_) {
        $self->{'order_by'} = [];
        $self->add_order_by(@_);
    }
    return ( $self->{'order_by'} || [] );
}

=head2 add_order_by EMPTY|HASH|ARRAY_OF_HASHES

Same as order_by, except it will not reset the ordering you have already set.

=cut

sub add_order_by {
    my $self = shift;
    return if $self->derived;
    if (@_) {
        my @args = @_;

        unless ( UNIVERSAL::isa( $args[0], 'HASH' ) ) {
            @args = {@args};
        }
        push @{ $self->{'order_by'} ||= [] }, @args;
        $self->redo_search();
    }
    return ( $self->{'order_by'} || [] );
}

=head2 clear_order_by

Clears whatever would normally get set in the ORDER BY clause.

=cut

sub clear_order_by {
    my $self = shift;

    $self->{'order_by'} = [];
}

=head2 _order_clause

returns the ORDER BY clause for the search.

=cut

sub _order_clause {
    my $self = shift;

    return '' unless $self->{'order_by'};

    my $clause = '';
    foreach my $row ( @{ $self->{'order_by'} } ) {

        my %rowhash = (
            alias  => 'main',
            column => undef,
            order  => 'ASC',
            %$row
        );
        if ( $rowhash{'order'} =~ /^des/i ) {
            $rowhash{'order'} = "DESC";
        } else {
            $rowhash{'order'} = "ASC";
        }

        if ( $rowhash{'function'} and not defined $rowhash{'column'} ) {
            $clause .= ( $clause ? ", " : " " );
            $clause .= $rowhash{'function'} . ' ';
            $clause .= $rowhash{'order'};

        } elsif ( ( defined $rowhash{'alias'} )
            and ( $rowhash{'column'} ) )
        {
            if ($rowhash{'column'} =~ /\W/) {
                warn "Possible SQL injection in column '$rowhash{column}' in order_by\n";
                next;
            }

            $clause .= ( $clause ? ", " : " " );
            $clause .= $rowhash{'function'} . "(" if $rowhash{'function'};
            $clause .= $rowhash{'alias'} . "." if $rowhash{'alias'};
            $clause .= $rowhash{'column'};
            $clause .= ")" if $rowhash{'function'};
            $clause .= " " . $rowhash{'order'};
        }
    }
    $clause = " ORDER BY$clause " if $clause;
    return $clause;
}

=head2 group_by_cols DEPRECATED

*DEPRECATED*. Use group_by method.

=cut

sub group_by_cols {
    require Carp;
    Carp::cluck("group_by_cols is deprecated, use group_by method");
    goto &group_by;
}

=head2 group_by EMPTY|HASH|ARRAY_OF_HASHES

Groups the search results by column(s) and/or function(s) on column(s).

Takes a paramhash of C<alias> and C<column> or C<function>.
C<alias> defaults to main.
C<column> and C<function> have no default values.

Use C<function> instead of C<alias> and C<column> to group by
the function value. Note that if you want use a column as argument
of the function then you have to build correct reference with alias
in the C<alias.column> format.

Use array of hashes to group by many columns/functions.

The method is EXPERIMENTAL and subject to change.

=cut

sub group_by {
    my $self = shift;

    return if $self->derived;
    my @args = @_;

    unless ( UNIVERSAL::isa( $args[0], 'HASH' ) ) {
        @args = {@args};
    }
    $self->{'group_by'} = \@args;
    $self->redo_search();
}

=head2 _group_clause

Private function to return the "GROUP BY" clause for this query.

=cut

sub _group_clause {
    my $self = shift;
    return '' unless $self->{'group_by'};

    my $row;
    my $clause;

    foreach $row ( @{ $self->{'group_by'} } ) {
        my %rowhash = (
            alias => 'main',

            column => undef,
            %$row
        );
        if ( $rowhash{'function'} ) {
            $clause .= ( $clause ? ", " : " " );
            $clause .= $rowhash{'function'};

        } elsif ( ( $rowhash{'alias'} )
            and ( $rowhash{'column'} ) )
        {
            if ($rowhash{'column'} =~ /\W/) {
                warn "Possible SQL injection in column '$rowhash{column}' in group_by\n";
                next;
            }

            $clause .= ( $clause ? ", " : " " );
            $clause .= $rowhash{'alias'} . ".";
            $clause .= $rowhash{'column'};
        }
    }
    if ($clause) {
        return " GROUP BY" . $clause . " ";
    } else {
        return '';
    }
}

=head2 new_alias table_OR_CLASS

Takes the name of a table or a Jifty::DBI::Record subclass.
Returns the string of a new Alias for that table, which can be used 
to Join tables or to limit what gets found by
a search.

=cut

sub new_alias {
    my $self = shift;
    my $refers_to = shift || die "Missing parameter";
    my $table;
    my $class = undef;
    if ( $refers_to->can('table') ) {
        $table = $refers_to->table;
        $class = $refers_to;
    } else {
        $table = $refers_to;
    }

    my $alias = $self->_get_alias($table);

    $self->{'joins'}{$alias} = {
        alias => $alias,
        table => $table,
        type  => 'CROSS',
        ( $class ? ( class => $class ) : () ),
        alias_string => " CROSS JOIN $table $alias ",
    };

    return $alias;
}

# _get_alias is a private function which takes an tablename and
# returns a new alias for that table without adding something to
# self->{'joins'}.  This function is used by new_alias and the
# as-yet-unnamed left join code

sub _get_alias {
    my $self  = shift;
    my $table = shift;

    return $table . "_" . ++$self->{'alias_count'};
}

=head2 join

Join instructs Jifty::DBI::Collection to join two tables.  

The standard form takes a paramhash with keys C<alias1>, C<column1>, C<alias2>
and C<column2>. C<alias1> and C<alias2> are column aliases obtained from
$self->new_alias or a $self->limit. C<column1> and C<column2> are the columns 
in C<alias1> and C<alias2> that should be linked, respectively.  For this
type of join, this method has no return value.

Supplying the parameter C<type> => 'left' causes Join to perform a left
join.  in this case, it takes C<alias1>, C<column1>, C<table2> and
C<column2>. Because of the way that left joins work, this method needs a
table for the second column rather than merely an alias.  For this type
of join, it will return the alias generated by the join.

The parameter C<operator> defaults C<=>, but you can specify other
operators to join with.

Passing a true value for the C<is_distinct> parameter allows one to
specify that, despite the join, the original table's rows are will all
still be distinct.

Instead of C<alias1>/C<column1>, it's possible to specify expression, to join
C<alias2>/C<table2> on an arbitrary expression.

=cut

sub join {
    my $self = shift;
    my %args = (
        type    => 'normal',
        column1 => undef,
        alias1  => 'main',
        table2  => undef,
        column2 => undef,
        alias2  => undef,
        @_
    );

    return if $self->derived;
    $self->_handle->join( collection => $self, %args );

}

=head2 set_page_info [per_page => NUMBER,] [current_page => NUMBER]

Sets the current page (one-based) and number of items per page on the
pager object, and pulls the number of elements from the collection.
This both sets up the collection's L<Data::Page> object so that you
can use its calculations, and sets the L<Jifty::DBI::Collection>
C<first_row> and C<rows_per_page> so that queries return values from
the selected page.

If a C<current_page> of C<all> is passed, then paging is basically disabled
(by setting C<per_page> to the number of entries, and C<current_page> to 1)

=cut

sub set_page_info {
    my $self = shift;
    my %args = (
        per_page     => 0,
        current_page => 1,    # 1-based
        @_
    );
    return if $self->derived;

    my $weakself = $self;
    weaken($weakself);

    my $total_entries = lazy { $weakself->count_all };

    if ($args{'current_page'} eq 'all') {
        $args{'current_page'} = 1;
        $args{'per_page'}     = $total_entries;
    }

    $self->pager->total_entries($total_entries)
        ->entries_per_page( $args{'per_page'} )
        ->current_page( $args{'current_page'} );

    $self->rows_per_page( $args{'per_page'} );

    # We're not using $pager->first because it automatically does a count_all
    # to correctly return '0' for empty collections
    $self->first_row( ( $args{'current_page'} - 1 ) * $args{'per_page'} + 1 );

}

=head2 rows_per_page

limits the number of rows returned by the database.  Optionally, takes
an integer which restricts the # of rows returned in a result Returns
the number of rows the database should display.

=cut

=head2 first_row

Get or set the first row of the result set the database should return.
Takes an optional single integer argument. Returns the currently set
integer first row that the database should return.


=cut

# returns the first row
sub first_row {
    my $self = shift;
    if (@_) {
        $self->{'first_row'} = shift;

        #SQL starts counting at 0
        $self->{'first_row'}--;

        #gotta redo the search if changing pages
        $self->redo_search();
    }
    return ( $self->{'first_row'} );
}

=head2 _items_counter

Returns the current position in the record set.

=cut

sub _items_counter {
    my $self = shift;
    return $self->{'itemscount'};
}

=head2 count

Returns the number of records in the set.

=cut

sub count {
    my $self = shift;

    # An unlimited search returns no tickets
    return 0 unless ( $self->_is_limited );

    # If we haven't actually got all objects loaded in memory, we
    # really just want to do a quick count from the database.
    if ( $self->{'must_redo_search'} ) {

        # If we haven't already asked the database for the row count, do that
        $self->_do_count unless ( $self->{'raw_rows'} );

        #Report back the raw # of rows in the database
        return ( $self->{'raw_rows'} );
    }

    # If we have loaded everything from the DB we have an
    # accurate count already.
    else {
        return $self->_record_count;
    }
}

=head2 count_all

Returns the total number of potential records in the set, ignoring any
limit_clause.

=cut

# 22:24 [Robrt(500@outer.space)] It has to do with Caching.
# 22:25 [Robrt(500@outer.space)] The documentation says it ignores the limit.
# 22:25 [Robrt(500@outer.space)] But I don't believe thats true.
# 22:26 [msg(Robrt)] yeah. I
# 22:26 [msg(Robrt)] yeah. I'm not convinced it does anything useful right now
# 22:26 [msg(Robrt)] especially since until a week ago, it was setting one variable and returning another
# 22:27 [Robrt(500@outer.space)] I remember.
# 22:27 [Robrt(500@outer.space)] It had to do with which Cached value was returned.
# 22:27 [msg(Robrt)] (given that every time we try to explain it, we get it Wrong)
# 22:27 [Robrt(500@outer.space)] Because Count can return a different number than actual NumberOfResults
# 22:28 [msg(Robrt)] in what case?
# 22:28 [Robrt(500@outer.space)] count_all _always_ used the return value of _do_count(), as opposed to Count which would return the cached number of
#           results returned.
# 22:28 [Robrt(500@outer.space)] IIRC, if you do a search with a limit, then raw_rows will == limit.
# 22:31 [msg(Robrt)] ah.
# 22:31 [msg(Robrt)] that actually makes sense
# 22:31 [Robrt(500@outer.space)] You should paste this conversation into the count_all docs.
# 22:31 [msg(Robrt)] perhaps I'll create a new method that _actually_ do that.
# 22:32 [msg(Robrt)] since I'm not convinced it's been doing that correctly

sub count_all {
    my $self = shift;

    # An unlimited search returns no tickets
    return 0 unless ( $self->_is_limited );

    # If we haven't actually got all objects loaded in memory, we
    # really just want to do a quick count from the database.
    if ( $self->{'must_redo_search'} || !$self->{'count_all'} ) {

        # If we haven't already asked the database for the row count, do that
        $self->_do_count(1) unless ( $self->{'count_all'} );

        #Report back the raw # of rows in the database
        return ( $self->{'count_all'} );
    }

    # If we have loaded everything from the DB we have an
    # accurate count already.
    else {
        return $self->_record_count;
    }
}

=head2 is_last

Returns true if the current row is the last record in the set.

=cut

sub is_last {
    my $self = shift;

    return undef unless $self->count;

    if ( $self->_items_counter == $self->count ) {
        return (1);
    } else {
        return (0);
    }
}

=head2 DEBUG

Gets/sets the DEBUG flag.

=cut

sub DEBUG {
    my $self = shift;
    if (@_) {
        $self->{'DEBUG'} = shift;
    }
    return ( $self->{'DEBUG'} );
}

=head2 column

Normally a collection object contains record objects populated with all columns
in the database, but you can restrict the records to only contain some
particular columns, by calling the C<column> method once for each column you
are interested in.

Takes a hash of parameters; the C<column>, C<table> and C<alias> keys means
the same as in the C<limit> method.  A special C<function> key may contain
one of several possible kinds of expressions:

=over 4

=item C<DISTINCT COUNT>

Same as C<COUNT(DISTINCT ?)>.

=item Expression with C<?> in it

The C<?> is substituted with the column name, then passed verbatim to the
underlying C<SELECT> statement.

=item Expression with C<(> in it

The expression is passed verbatim to the underlying C<SELECT>.

=item Any other expression

The expression is taken to be a function name.  For example, C<SUM> means
the same thing as C<SUM(?)>.

=back

=cut

sub column {
    my $self = shift;
    my %args = (
        table    => undef,
        alias    => undef,
        column   => undef,
        function => undef,
        @_
    );

    my $table = $args{table} || do {
        if ( my $alias = $args{alias} ) {
            $alias =~ s/_\d+$//;
            $alias;
        } else {
            $self->table;
        }
    };

    my $name = ( $args{alias} || 'main' ) . '.' . $args{column};
    if ( my $func = $args{function} ) {
        if ( $func =~ /^DISTINCT\s*COUNT$/i ) {
            $name = "COUNT(DISTINCT $name)";
        }

        # If we want to substitute
        elsif ( $func =~ /\?/ ) {
            $name =~ s/\?/$name/g;
        }

        # If we want to call a simple function on the column
        elsif ( $func !~ /\(/ ) {
            $name = "\U$func\E($name)";
        } else {
            $name = $func;
        }

    }

    my $column = "col" . @{ $self->{columns} ||= [] };
    $column = $args{column} if $table eq $self->table and !$args{alias};
    $column = ( $args{'alias'} || 'main' ) . "_" . $column;
    push @{ $self->{columns} }, "$name AS \L$column";
    return $column;
}

=head2 columns LIST

Specify that we want to load only the columns in LIST, which should be
a list of column names.

=cut

sub columns {
    my $self = shift;
    $self->column( column => $_ ) for @_;
}

=head2 columns_in_db table

Return a list of columns in table, in lowercase.

TODO: Why are they in lowercase?

=cut

sub columns_in_db {
    my $self  = shift;
    my $table = shift;

    my $dbh = $self->_handle->dbh;

    # TODO: memoize this

    return map lc( $_->[0] ), @{ (
        eval {
            $dbh->column_info( '', '', $table, '' )->fetchall_arrayref( [3] );
            }
            || $dbh->selectall_arrayref("DESCRIBE $table;")
            || $dbh->selectall_arrayref("DESCRIBE \u$table;")
            || []
        ) };
}

=head2 has_column  { table => undef, column => undef }

Returns true if table has column column.
Return false otherwise

=cut

sub has_column {
    my $self = shift;
    my %args = (
        column => undef,
        table  => undef,
        @_
    );

    my $table  = $args{table}  or die;
    my $column = $args{column} or die;
    return grep { $_ eq $column } $self->columns_in_db($table);
}

=head2 table [table]

If called with an argument, sets this collection's table.

Always returns this collection's table.

=cut

sub table {
    my $self = shift;
    $self->{table} = shift if (@_);
    return $self->{table};
}

=head2 clone

Returns copy of the current object with all search restrictions.

=cut

sub clone {
    my $self = shift;

    my $obj = bless {}, ref($self);
    %$obj = %$self;

    $obj->redo_search();    # clean out the object of data

    $obj->{$_} = Clone::clone( $obj->{$_} )
        for grep exists $self->{$_}, $self->_cloned_attributes;
    return $obj;
}

=head2 _cloned_attributes

Returns list of the object's fields that should be copied.

If your subclass store references in the object that should be copied while
cloning then you probably want override this method and add own values to
the list.

=cut

sub _cloned_attributes {
    return qw(
        joins
        subclauses
        restrictions
    );
}

=head2 each CALLBACK

Executes the callback for each item in the collection. The callback receives as
arguments each record, its zero-based index, and the collection. The return
value of C<each> is the original collection.

If the callback returns zero, the iteration ends.

=cut

sub each {
    my $self = shift;
    my $cb   = shift;

    my $idx = 0;
    $self->goto_first_item;

    while (my $record = $self->next) {
        my $ret = $cb->($record, $idx++, $self);
        last if defined($ret) && !$ret;
    }

    return $self;
}

1;
__END__



=head1 TESTING

In order to test most of the features of C<Jifty::DBI::Collection>,
you need to provide C<make test> with a test database.  For each DBI
driver that you would like to test, set the environment variables
C<JDBI_TEST_FOO>, C<JDBI_TEST_FOO_USER>, and C<JDBI_TEST_FOO_PASS> to a
database name, database username, and database password, where "FOO"
is the driver name in all uppercase.  You can test as many drivers as
you like.  (The appropriate C<DBD::> module needs to be installed in
order for the test to work.)  Note that the C<SQLite> driver will
automatically be tested if C<DBD::Sqlite> is installed, using a
temporary file as the database.  For example:

  JDBI_TEST_MYSQL=test JDBI_TEST_MYSQL_USER=root JDBI_TEST_MYSQL_PASS=foo \
    JDBI_TEST_PG=test JDBI_TEST_PG_USER=postgres  make test


=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>, Alex Vandiver
<alexmv@bestpractical.com>, Ruslan Zakirov <ruslan.zakirov@gmail.com>

Based on DBIx::SearchBuilder::Collection, whose credits read:

 Jesse Vincent, <jesse@fsck.com> 

All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Handle>, L<Jifty::DBI::Record>.

=cut
