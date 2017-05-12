package Jifty::DBI::Handle::Pg;
use strict;

use vars qw($VERSION @ISA $DBIHandle $DEBUG);
use base qw(Jifty::DBI::Handle);

use strict;

=head1 NAME

  Jifty::DBI::Handle::Pg - A Postgres specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of L<Jifty::DBI::Handle> that
compensates for some of the idiosyncrasies of Postgres.

=head1 METHODS

=cut

=head2 connect

connect takes a hashref and passes it off to SUPER::connect; Forces
the timezone to GMT, returns a database handle.

=cut

sub connect {
    my $self = shift;

    $self->SUPER::connect(@_);
    $self->simple_query("SET TIME ZONE 'GMT'");
    $self->simple_query("SET DATESTYLE TO 'ISO'");
    $self->auto_commit(1);
    return ($DBIHandle);
}

=head2 insert

Takes a table name as the first argument and assumes that the rest of
the arguments are an array of key-value pairs to be inserted.

In case of insert failure, returns a L<Class::ReturnValue> object
preloaded with error info

=cut

sub insert {
    my $self  = shift;
    my $table = shift;
    my %args  = (@_);
    my $sth   = $self->SUPER::insert( $table, %args );

    unless ($sth) {
        return ($sth);
    }

    if ( $args{'id'} || $args{'Id'} ) {
        $self->{'id'} = $args{'id'} || $args{'Id'};
        return ( $self->{'id'} );
    }

    my $sequence_name = $self->id_sequence_name($table);
    unless ($sequence_name) { return ($sequence_name) }   # Class::ReturnValue
    my $seqsth = $self->dbh->prepare(
        qq{SELECT CURRVAL('} . $sequence_name . qq{')} );
    $seqsth->execute;
    $self->{'id'} = $seqsth->fetchrow_array();

    return ( $self->{'id'} );
}

=head2 id_sequence_name TABLE

Takes a TABLE name and returns the name of the  sequence of the primary key for that table.

=cut

sub id_sequence_name {
    my $self  = shift;
    my $table = shift;

    return $self->{'_sequences'}{$table}
        if ( exists $self->{'_sequences'}{$table} );

    #Lets get the id of that row we just inserted
    my $seq;
    my $colinfosth = $self->dbh->column_info( undef, undef, lc($table), '%' );
    while ( my $foo = $colinfosth->fetchrow_hashref ) {

        # Regexp from DBIx::Class's Pg handle. Thanks to Marcus Ramberg
        if ( defined $foo->{'COLUMN_DEF'}
            && $foo->{'COLUMN_DEF'}
            =~ m!^nextval\(+'"?([^"']+)"?'(::(?:text|regclass)\))+!i )
        {
            return $self->{'_sequences'}{$table} = $1;
        }

    }
    my $ret = Class::ReturnValue->new();
    $ret->as_error(
        errno        => '-1',
        message      => "Found no sequence for $table",
        do_backtrace => undef
    );
    return ( $ret->return_value );

}

=head2 blob_params column_NAME column_type

Returns a hash ref for the bind_param call to identify BLOB types used
by the current database for a particular column type.  The current
Postgres implementation only supports BYTEA types.

=cut

sub blob_params {
    my $self = shift;
    my $name = shift;
    my $type = shift;

    # Don't assign to key 'value' as it is defined later.
    return ( { pg_type => DBD::Pg::PG_BYTEA() } )
        if $type =~ /^(?:blob|bytea)$/;
    return ( {} );
}

=head2 apply_limits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE
starting with FIRST_ROW;

=cut

sub apply_limits {
    my $self         = shift;
    my $statementref = shift;
    my $per_page     = shift;
    my $first        = shift;

    my $limit_clause = '';

    if ($per_page) {
        $limit_clause = " LIMIT ";
        $limit_clause .= $per_page;
        if ( $first && $first != 0 ) {
            $limit_clause .= " OFFSET $first";
        }
    }

    $$statementref .= $limit_clause;

}

=head2 _make_clause_case_insensitive column operator VALUE

Takes a column, operator and value. performs the magic necessary to make
your database treat this clause as case insensitive.

Returns a column operator value triple.

=cut

sub _make_clause_case_insensitive {
    my $self     = shift;
    my $column   = shift;
    my $operator = shift;
    my $value    = shift;

    if ( $self->_case_insensitivity_valid( $column, $operator, $value ) ) {
        $column = "LOWER($column)";
        if ( $operator =~ /^(IN|=)$/i and ref($value) eq 'ARRAY' ) {
            $value = [ map {"LOWER($_)"} @$value ];
        } else {
            $value = "LOWER($value)";
        }
    }
    return ( $column, $operator, $value );
}

=head2 distinct_query STATEMENTREF

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.

=cut

sub distinct_query {
    my $self         = shift;
    my $statementref = shift;
    my $collection   = shift;
    my $table        = $collection->table;

    if (grep {
            ( defined $_->{'alias'} and $_->{'alias'} ne 'main' )
                || defined $_->{'function'}
        } @{ $collection->order_by }
        )
    {

        # If we are ordering by something not in 'main', we need to GROUP
        # BY and adjust the ORDER_BY accordingly
        local $collection->{group_by}
            = [ @{ $collection->{group_by} || [] }, { column => 'id' } ];
        local $collection->{order_by} = [
            map {
                my $alias = $_->{alias} || '';
                my $column = $_->{column};
                my $order = $_->{order};
                if ($column =~ /\W/) {
                    warn "Possible SQL injection in column '$column' in order_by\n";
                    next;
                }
                $alias .= '.' if $alias;

                ( ( !$alias or $alias eq 'main.' ) and $column eq 'id' )
                    ? $_
                    : { %{$_}, column => undef, function => ($order =~ /^des/i ? 'MAX':'MIN'). "($alias$column)" }
                } @{ $collection->{order_by} }
        ];
        my $group = $collection->_group_clause;
        my $order = $collection->_order_clause;
        $$statementref
            = "SELECT "
            . $collection->query_columns
            . " FROM ( SELECT main.id FROM $$statementref $group $order ) distinctquery, $table main WHERE (main.id = distinctquery.id)";
    } else {
        $$statementref
            = "SELECT DISTINCT "
            . $collection->query_columns
            . " FROM $$statementref";
        $$statementref .= $collection->_group_clause;
        $$statementref .= $collection->_order_clause;
    }
}

=head2 canonical_true

The canonical true value in Postgres is 't'.

=cut

sub canonical_true { 't' }

=head2 canonical_false

The canonical false value in Postgres is 'f'.

=cut

sub canonical_false { 'f' }

1;

__END__

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Handle>, L<DBD::Pg>

=cut

