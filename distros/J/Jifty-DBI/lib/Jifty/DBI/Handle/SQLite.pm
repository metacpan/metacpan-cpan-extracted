
package Jifty::DBI::Handle::SQLite;
use Jifty::DBI::Handle;
@ISA = qw(Jifty::DBI::Handle);

use vars qw($VERSION @ISA $DBIHandle $DEBUG);
use strict;

=head1 NAME

  Jifty::DBI::Handle::SQLite -- A SQLite specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of Jifty::DBI::Handle that 
compensates for some of the idiosyncrasies of SQLite.

=head1 METHODS

=head2 database_version

Returns the version of the SQLite library which is used, e.g., "2.8.0".
SQLite can only return short variant.

=cut

sub database_version {
    my $self = shift;
    return '' unless $self->dbh;
    return $self->dbh->{sqlite_version} || '';
}

=head2 insert

Takes a table name as the first argument and assumes that the rest of the arguments
are an array of key-value pairs to be inserted.

If the insert succeeds, returns the id of the insert, otherwise, returns
a Class::ReturnValue object with the error reported.

=cut

sub insert {
    my $self  = shift;
    my $table = shift;
    my %args  = ( id => undef, @_ );

    # We really don't want an empty id

    my $sth = $self->SUPER::insert( $table, %args );
    return unless $sth;

# If we have set an id, then we want to use that, otherwise, we want to lookup the last _new_ rowid
    $self->{'id'} = $args{'id'} || $self->dbh->func('last_insert_rowid');

    warn "$self no row id returned on row creation" unless ( $self->{'id'} );
    return ( $self->{'id'} );    #Add Succeded. return the id
}

=head2 case_sensitive 

Returns 1, since SQLite's searches are case sensitive by default.
Note, however, SQLite's C<like> operator is case I<in>sensitive.

=cut

sub case_sensitive {
    my $self = shift;
    return (1);
}

=head2 distinct_count STATEMENTREF

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result count


=cut

sub distinct_count {
    my $self         = shift;
    my $statementref = shift;

    # Wrapper select query in a subselect as Oracle doesn't allow
    # DISTINCT against CLOB/BLOB column types.
    $$statementref
        = "SELECT count(*) FROM (SELECT DISTINCT main.id FROM $$statementref )";

}

sub _make_clause_case_insensitive {
    my $self     = shift;
    my $column   = shift;
    my $operator = shift;
    my $value    = shift;

    return ($column, $operator, $value)
        unless $self->_case_insensitivity_valid( $column, $operator, $value );

    return("$column COLLATE NOCASE", $operator, $value);
}

=head2 rename_column ( table => $table, column => $old_column, to => $new_column )

rename column

=cut

sub rename_column {
    my $self = shift;
    my %args = (
        table  => undef,
        column => undef,
        to     => undef,
        @_
    );

    my $table   = $args{'table'};

    # Convert columns
    my ($schema) = $self->fetch_result(
        "SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type = ?",
        $table, 'table',
    );
    $schema =~ s/(.*create\s+table\s+)\S+(.*?\(\s*)//i
        or die "Cannot find 'CREATE TABLE' statement in schema for '$table': $schema";

    my $new_table    = join( '_', $table, 'new', $$ );
    my $new_create_clause = "$1$new_table$2";

    my @column_info = ( split /,/, $schema );
    my @column_names = map { /^\s*(\S+)/ ? $1 : () } @column_info;

    s/^(\s*)\b\Q$args{column}\E\b/$1$args{to}/i for @column_info;

    my $new_schema = $new_create_clause . join( ',', @column_info );
    my $copy_columns = join(
        ', ',
        map {
            ( lc($_) eq lc( $args{column} ) )
              ? "$_ AS $args{to}"
              : $_
          } @column_names
    );

    # Convert indices
    my $indice_sth = $self->simple_query(
        "SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type = ?",
        $table, 'index'
    );
    my @indice_sql;
    while ( my ($index) = $indice_sth->fetchrow_array ) {
        $index =~ s/^(.*\(.*)\b\Q$args{column}\E\b/$1$args{to}/i;
        push @indice_sql, $index;
    }
    $indice_sth->finish;

    # Run the conversion SQLs
    $self->begin_transaction;
    $self->simple_query($new_schema);
    $self->simple_query("INSERT INTO $new_table SELECT $copy_columns FROM $table");
    $self->simple_query("DROP TABLE $table");
    $self->simple_query("ALTER TABLE $new_table RENAME TO $table");
    $self->simple_query($_) for @indice_sql;
    $self->commit;
}

1;

__END__

=head1 AUTHOR

Jesse Vincent, jesse@fsck.com

=head1 SEE ALSO

perl(1), Jifty::DBI

=cut
