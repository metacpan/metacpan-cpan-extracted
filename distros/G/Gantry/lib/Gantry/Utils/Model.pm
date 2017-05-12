package Gantry::Utils::Model;
use strict; use warnings;

use Carp;
use DBI;

use overload
    '""'     => sub { shift->stringify_self },
    fallback => 1;  # Shhh.  Say nothing.

#-----------------------------------------------------------------
# dbh managment methods
#-----------------------------------------------------------------

sub get_db_options {
    return {};
}

sub disconnect {
    my $class = shift;
    my $dbh   = shift || $class->db_Main();

    $dbh->rollback unless ( $dbh->{AutoCommit} );

    $dbh->disconnect;
}

sub dbi_commit {
    my $class = shift;
    my $dbh   = shift || $class->db_Main();

    $dbh->commit unless ( $dbh->{AutoCommit} );
}

#-----------------------------------------------------------------
# constructor
#-----------------------------------------------------------------

sub construct {
    my $class = shift;
    my $data  = shift;

    # see unless block on line 526 of viperl Class::DBI for cached alternative
    # that line is in the _init method
    my $obj   = bless {}, $class;

    my @cols  = keys %{ $data };

    @{ $obj }{ @cols } = @{ $data }{ @cols };

    $obj->{__DIRTY__}  = {};

    return $obj;
}

#-----------------------------------------------------------------
# select statements
#-----------------------------------------------------------------

sub special_sql {
    my $class = shift;
    my $sql   = shift;

    my $dbh   = $class->db_Main();
    my $sth   = $dbh->prepare( $sql );

    $sth->execute();

    my %row;

    eval {
        $sth->bind_columns( \( @row{ @{ $sth->{NAME_lc} } } ) );
    };
    if ( $@ ) {
        die "Couldn't execute $sql\n\n$@";
    }

    my @retvals;

    while ( $sth->fetch() ) {
        # XXX we are supposed to defer construction to an iterator unless
        # the user wants an array
        push @retvals, $class->construct( \%row );
    }

    return             unless @retvals;
    return @retvals    if     wantarray;
    return $retvals[0] if     ( $#retvals == 0 );

    #XXX this is supposed to return an iterator with a next operation
    return \@retvals;
}

sub retrieve_all {
    my $class = shift;

    my $attr;

    if ( @_ > 1 ) { $attr = { @_ }; }
    else          { $attr = shift;  }

    my $order = '';
    if ( $attr->{order_by} ) {
        $order = "ORDER BY $attr->{order_by}";
    }

    my $cols     = $class->get_essential_cols();
    my $table    = $class->get_table_name();
    
    my $sql      = "SELECT $cols FROM $table $order";

    return $class->special_sql( $sql );
}

sub retrieve_by_pk {
    my $class    = shift;
    my $id       = shift;

    return unless $id;

    my $cols     = $class->get_essential_cols();
    my $table    = $class->get_table_name();
    my $primary  = $class->get_primary_col();
    my $sql      = "SELECT $cols FROM $table WHERE $primary = $id";
    my @answer   = $class->special_sql( $sql );

    return $answer[0];
}

sub retrieve {
    my $class = shift;

    if ( @_ == 1 ) { return $class->retrieve_by_pk( shift ); }
    else           { return $class->search( @_ );            }
}

sub search {
    my $class = shift;
    my %value_for;
    my $attr;

    my $cols  = $class->get_essential_cols();
    my $table = $class->get_table_name();

    # see if there is an order by clause
    if ( ref( $_[-1] ) =~ /HASH/ ) {
        $attr = pop @_;
    }
    my $order = '';
    if ( $attr->{order_by} ) {
        $order = "ORDER BY $attr->{order_by}";
    }

    # build where clause
    if    ( ref( $_[0] ) eq 'HASH'  ) { %value_for = %{ $_[0] }; }
    elsif ( ref( $_[0] ) eq 'ARRAY' ) { %value_for = @{ $_[0] }; }
    else                              { %value_for = @_;         }

    my @where_frags;

    foreach my $col ( keys %value_for ) {

        push @where_frags,
                "$col = " . $class->quote_scalar( $col, $value_for{$col} );
    }

    my $where = join ' AND ', @where_frags;

    my $sql   = "SELECT $cols FROM $table WHERE $where $order";

    # are we paging?
    if ( my $rows_per_page = delete $attr->{rows} ) {

        my $current_page   = delete $attr->{page} || 1;

        # calculate offset
        my $offset = ( $current_page - 1 ) * $rows_per_page;

        $sql .= " LIMIT $rows_per_page OFFSET $offset";
    }

    return $class->special_sql( $sql );
}

sub page { shift->search( @_ ) }

sub lazy_fetch {
    my $self = shift;
    my $col  = shift;
    # my $col_group = shift;  # using this would require several changes

    my $primary = $self->get_primary_col();

    my $sql     = "SELECT $col FROM " . $self->get_table_name()
                . " WHERE $primary = " . $self->get_primary_key();

    my $dbh     = $self->db_Main();
    my $sth     = $dbh->prepare( $sql );
    $sth->execute();

    my $value;
    $sth->bind_columns( \$value );

    if ( $sth->fetch() ) {
        my $method = "set_$col";
        $self->$method( $value );
    }
    else {
        croak "Error couldn't fetch $col for" . $self->get_primary_key() . "\n";
    }
}

#-----------------------------------------------------------------
# other CRUD
#-----------------------------------------------------------------

sub create {
    my $class     = shift;
    my $value_for = shift;

    # fill in primary_key if needed (it's usually needed)
    my $primary   = $class->get_primary_col();

    if ( not defined $value_for->{ $primary }
            and
         $class->can( 'get_sequence_name' )
    ) {
        $value_for->{ $primary } = $class->_next_primary_key();
    }

    # construct object
    my $new_object = $class->construct( $value_for );

    # make the sql, including quoting
    my @quoted_values;

    foreach my $col ( keys %{ $value_for } ) {
        push @quoted_values, $new_object->quote_attribute( $col );
    }

    my $sql = 'INSERT INTO ' . $class->get_table_name . ' ( '
            . join( ', ', keys   %{ $value_for } ) . ' ) VALUES ( '
            . join( ', ', @quoted_values ) . ' );';

    # execute sql
    my $dbh     = $class->db_Main();
    unless ( $dbh->do( $sql ) ) {
        $dbh->rollback unless ( $dbh->{AutoCommit} );

        croak "Database error with $sql\n$DBI::errstr $!\n";
    }

    return $new_object;
}

sub _next_primary_key {
    my $class = shift;

    my $seq   = $class->get_sequence_name();

    my $sql   = "SELECT NEXTVAL ( '$seq' );";
    my $dbh   = $class->db_Main();
    my $sth   = $dbh->prepare( $sql );
    $sth->execute();

    my $retval;
    $sth->bind_columns( \$retval );
    
    unless ( $sth->fetch() ) {
        croak "Error couldn't fetch next primary_key for $class\n"
                .   "using sequecne $seq\n";
    }

    return $retval;
}

sub find_or_create {
    my $class = shift;

    my $data = ( ref $_[0] ) ? shift : { @_ };

    # see if this data is in some row
    my ( $row ) = $class->search( %{ $data } );

    return ( defined $row ) ? $row : $class->create( $data );
}

sub delete {
    my $self  = shift;

    my $table = $self->get_table_name();
    my $pk    = $self->get_primary_col();

    my $sql   = "DELETE FROM $table WHERE $pk = " . $self->get_primary_key();

    my $dbh   = $self->db_Main();
    my $sth   = $dbh->prepare( $sql );
    $sth->execute();

    undef %$self;
    bless $self, 'Deleted::Object';

    return 1;
}

sub update {
    my $self = shift;

    # build set clause for dirty cols
    my @dirty_cols = keys %{ $self->{__DIRTY__} };

    my @new_values;
    foreach my $dirty_col ( @dirty_cols ) {
        my $value = $self->quote_attribute( $dirty_col );
        push @new_values, "$dirty_col=$value";
    }
    my $new_values = join ',', @new_values;

    # build sql string
    my $primary = $self->get_primary_col();

    my $sql     = 'UPDATE ' . $self->get_table_name() . " SET $new_values"
                . " WHERE $primary = " . $self->get_primary_key() . ';';

    # execute sql
    my $dbh   = $self->db_Main();
    unless ( $dbh->do( $sql ) ) {
        $dbh->rollback unless ( $dbh->{AutoCommit} );

        croak "Database error with $sql\n$DBI::errstr $!\n";
    }

    # reset dirty
    $self->{__DIRTY__} = {};
}

#-----------------------------------------------------------------
# accessors and their helpers
#-----------------------------------------------------------------

sub get {
    my $self = shift;
    my @cols = @_;

    my @retvals;

    foreach my $col ( @cols ) {
        my $method = "get_$col";
        push @retvals, $self->$method();
    }

    return ( wantarray ) ? @retvals : $retvals[0];
}

sub set {
    my $self      = shift;
    my %value_for = @_;

    foreach my $col ( keys %value_for ) {
        my $method = "set_$col";
        $self->$method( $value_for{$col} );
    }
}

sub quote_attribute {
    my $self   = shift;
    my $col    = shift;

    my $getter = "get_$col";
    my $quoter = "quote_$col";

    return $self->$quoter( $self->$getter );
}

sub quote_scalar {
    my $self_or_class = shift;
    my $col           = shift;
    my $value         = shift;

    my $quoter        = "quote_$col";

    return $self_or_class->$quoter( $value );
}

sub stringify_self {
    my $self = shift;

    return $self->get_primary_key();
}

1;

=head1 NAME

Gantry::Utils::Model - a general purpose Object Relational Model base class

=head1 SYNOPSIS

    use base 'Gantry::Utils::Model';

    sub get_table_name     { return 'your_table';                           }
    sub get_sequence_name  { return 'your_table_seq';                       }
    sub get_primary_col    { return 'id';                                   }
    sub get_essential_cols { return 'id, text_col';                         }

    sub get_primary_key    { goto &get_id;                                  }

    sub set_id             { croak "Can't change primary key";              }
    sub get_id             { return $_->[0]{id};                            }
    sub quote_id           { return $_[1];                                  }

    sub set_text_col       {
        my $self  = shift;
        my $value = shift;

        $self->{text_col} = $value;
        $self->{__DIRTY__}{text_col}++;
        return $value;
    }
    sub get_text_col       { return $_->[0]{text_col};                      }
    sub quote_text_col     {
        return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
    }

    sub set_other_text_col {
        my $self  = shift;
        my $value = shift;

        $self->{other_text_col} = $value;
        $self->{__DIRTY__}{other_text_col}++;

        return $value;
    }
    sub get_other_text_col {
        my $self = shift;
        unless ( defined $self->{other_text_col} ) {
            $self->lazy_fetch( 'other_text_col' );
        }
        return $self->{other_text_col};
    }
    sub quote_other_text_col     {
        return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
    }

=head1 DESCRIPTION

This module is a Class::DBI replacement.  Its goal is to reduce the mystery
in the internals of that module, while still providing most of its
functionality.  You'll notice that the inheriting class has a lot more code
than a Class::DBI subclass would.  This is because we use Bigtop to
generate the subclasses.  Thus, we don't care so much about the volume of
code.  The result is code which is easy to read, understand, override
and/or modify.

=head1 RATIONALE

Class::DBI and its cousins provide beautiful APIs for client code.  By
implementing straightforward database row to Perl object correspondence,
they save a lot of mental effort when writing most applications.

They do have drawbacks.  My premise is that most of these drawbacks stem
from a single fundamental design descision.  Perl's traditional Object
Relation Mappers (ORMs) do a lot of work at run time.  For instance, they build
accessors at run time.  When I first started using them, I thought this
was gorgeous.  Class::DBI::mysql was one of my favorite modules.  I
bought the promise of a future where all you had to say was something like

    package MyModel;

    use Class::DBI::SuperClever
        'dbi:Pg:dbname=somedb', 'user', 'passwd', 'MyModel';

and the whole somedb database would be mapped without another word.  Each table
would become a class under MyModel with an accessor for each column.  Then
I could create, retrieve, update, and delete to my heart's content while
beholding the power of Perl.

The problem is that use statements like the above example require extreme
magic (and not a small amount of time).  This leads to a lack of transperency
which leaves me with three problems: (1) I worry, in the back of my mind I
always have the doubt of not knowing what is going on in these complex beasts
(2) I get hit by subtle bugs, like name collisions from inheritence and
inadvertant overriding (3) worst, I am left with a system that works really
well to do the things the author thought of, but not the thing I really need
to do in a particular instance (either because the system is inherently
limiting or more likely because it is so complex I can't wrap my small mind
around it well enough to carry out my task).

This leads to the fundamental principle of this module: simplicity.  Any
programmer with intermediate Perl skills and a passing familiarity with
SQL databases should be able to digest this in a morning.  There are
other goals, but simplicity is at the core.

In order to achieve transperency, it is necessary to have more code in the
subclasses.  This is really why the magical schemes sprang up.  But,
recently I have been working on generation of code.  This amounts to the
same thing, but it happens ahead of time.  So, instead of code being
generated by magic during run time, my code is generated by grammar
based parsing before compile time.  The generator in question is bigtop
which can build a completely funcational web app from a description of
its data model and controllers.  Then, when a programmer wonders what
the model is up to, she has a set of simple modules which explicitly
show what is going on.  To make change, she may add methods or override
the existing generated ones.

=head1 METHODS PROVIDED BY THIS MODULE

=over 4

=item disconnect

Class or instance method.
You can pass in a handle or this will call db_Main to get the standard
one.  In either case, it will rollback any current transaction (if
you aren't auto-committing) and disconnect the handle.

=item dbi_commit

Class or instance method.
By default the dbh managed by this module has AutoCommit off.  Call this
to commit your transactions.

=item construct

Class method.
Mainly for internal use.  This method takes a hash (usually one bound
to a statement handle) and turns it into an object of the subclass through
which it was called.

=item special_sql

Class method.
Accepts sql SELECT statements returns a list (not a reference or iterator)
of objects in the class through which it was called.  Be careful with
column names, they need to be the genuine names of columns in the underlying
table.

=item retrieve_all

Class method.  Pass a list of key/value pairs or a single hash ref.  The
only legal key is order_by, its value will be used literally directly after
'ORDER BY' (that means, don't include the ORDER BY keywords in your value).
Returns a list of objects.

=item retrieve_by_pk

Class method.  Pass a single primary key value.  Returns the row with that
primary key value as an object or undef if no such row is found.

=item retrieve

Class method.  Similar to retrieve in Class::DBI.  If called with one
argument, that argument is taken as a primary key and the request is
forwarded to retrieve_by_pk.  If called with multiple arguments (or no
arguments), those arguments are forwarded to search.

=item search

Class method.  Similar to search in Class::DBI.  Call with the key/value
pairs you want to match in a simple list.

Returns a list of objects one each for every row that matched the search
criterion.

Add a single hash reference as the last parameter if you like.  That hash
reference may only contain these keys:

=over 4

=item order_by

Asks for an ORDER BY clause, the value is used literally to fill in the
blank in 'ORDER BY ___'.

=item rows

Indicates that you want paging.  The value is the number of rows per page.
There is no default, since the absence of this key is taken to mean you don't
want paging.

=item page

Ignored unless rows is supplied.  Defaults to 1.  This is the page number
to retrieve.

=back

=item page

A synonymn for search to better match the Class::DBI::Sweet API.
Note that you must set the rows key in the hash reference passed as the last
argument.  You may also set the page key.  See above.

=item lazy_fetch

Instance method.  Call with the column name you want to fetch.  Returns
nothing useful, but sets the column with the value from the corresponding
row in the underlying table.

=item create

Class method.  Call with a hash reference whose keys are the column names
you want to populate.  The value will be quoted for you according to the
corresponding quote_* method in the subclass.

=item _next_primary_key

Class method.  Returns the next value of the sequence associated with
the underlying table.  This is not reproduceable, it actually increments
the sequence.  It only works if the database is using a sequence for the
table and the model implements get_sequence_name.

=item find_or_create

Class method.  Call with a hash reference of search criteria (think of
a WHERE clause).  First, it calls search, taking a single resulting
object.  If that works, you get the object.  Otherwise, it calls
create with your hash reference and returns the new object.

=item update

Instance method.  Issues an UPDATE to SET the dirty values from the
invocant.  Returns nothing useful, although it could die if the dbh
has problems.

=item delete

Instance method.  Deletes the underlying row from its table and
renders the invocant reference unusable.

=item get

Instance method.  Call with a list of columns whose values you want.
Returns the values in the invocant for the columns you requested.
If you requested only one column a scalar is returned.  Otherwise,
you get a list.

=item set

Instance method.  Call with a list of key/value pairs for columns that
you want to change.  Returns nothing useful.

=item quote_attribute

Instance method.  Primarily for internal use.  Call with a column name.
Returns the value in the column quoted so SQL will take it.

=item quote_scalar

Class or instance method.  Call with a column name and a value.  Returns
the value quoted for SQL as if it were stored in the column of an object.
Even if you call this as an instance method, the instance values are not
used.

=item get_db_options

Subclasses are welcome to override this with a meaningful routine.
The one here returns an empty hash reference.  Yours should provide
data given as extra options to DBI during connection.

=item stringify_self

Returns the id of the row.

=back

=head1 METHODS SUBCLASSES MUST PROVIDE

You can include any useful method you like in your subclass, but these
are the ones this module needs.

=over 4

=item get_table_name

Return the name of the table in the database that your class models.

=item get_sequence_name

Return the name of the sequence associated with your table.  This is
needed for the create method.

=item get_essential_cols

Return an array reference containing the columns you want to fetch
automatically during retrieve, search, etc.

=item get_primary_col

We assume that each table has a unique primary key (though we assume
nothing about its name).  Return the name of that column.

=item get_primary_key

An instance method.  Return the value of the primary key for the invocant.

=item set_COL_NAME

Provide one of these for each column.  Called on an existing object with
a new value.  It must store the value in the object's hash (whose keys
are the column labels) AND set the dirty flag for the column so that eventual
updates will be effective.  Some callers may expect to receive the
new value in return, document whether it returns that value or not.
Example:

    sub set_amount {
        my $self  = shift;
        my $value = shift;

        $self->{amount} = $value;
        $self->{__DIRTY__}{amount}++;

        return $self->{amount};
    }

=item get_COL_NAME

Provide one of these for each column.  Return the unquoted value in the
column.  Example:

    sub get_amount {
        my $self = shift;

        return $self->{amount};
    }

=item quote_COL_NAME

Called as a class or instance method with one argument.  Take that argument,
hold it up to the light, examine in detail.  Then return something that has
the same value properly quoted for SQL.

Note that you should not look in the object, even if one is used as the
invocant.  Always only work on the other argument.

=item COL_NAME (completely optional)

Provide one of these for each column only if you like.  Dispatch to get_ and
set_ methods based on the arguments you receive.  These methods are NEVER
called internally, but your callers might like them.  Example (with
apologies to Dr. Conway):

    sub amount {
        my $self  = shift;
        my $value = shift;

        if ( defined $value ) { return $self->set_amount( $value ); }
        else                  { return $self->get_amount();         }
    }

=back

=head1 OMISSIONS

There is no caching.  This means two things: (1) no sql statement is
prepared with bind parameter place holders and stored for possible
reuse (2) objects are always built for each row retrieved, even if
there is a live object for that row elsewhere in memory.

There are no triggers.  If you need these, put them in the accessors
as needed.  Feel free to override construct.

There are no iterators.  Class::DBI makes iterators, but they only
delay object instantiation, the full query results are pulled from the
beginning.  Replicating that behavior seems like the pursuit of
diminishing returns.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
