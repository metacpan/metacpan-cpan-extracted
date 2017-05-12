package Gantry::Utils::DB;
require Exporter;

use strict; 
use Carp qw( croak confess );
use DBI;
use vars qw( @ISA @EXPORT );

############################################################
# Variables                                                #
############################################################
@ISA    = qw( Exporter );
@EXPORT = qw(   db_commit
                db_connect
                db_disconnect
                db_finish
                db_lastseq
                db_next
                db_nextvals 
                db_query
                db_rollback
                db_rowcount
                db_run      ); 

############################################################
# Functions                                                #
############################################################
############################################################
# Functions                                                #
############################################################
sub new {
    my ( $class, $dbh ) = @_;

    my $self = { };
    bless( $self, $class );

    # populate self with data from site
    return( $self );

} # end new

#-------------------------------------------------
# db_commit( $dbh )
#-------------------------------------------------
sub db_commit {
    my $handle = shift;

    $handle->commit if ( $handle->{AutoCommit} == 0 );

    return();
} # END db_commit

#-------------------------------------------------
# db_connect()
#-------------------------------------------------
sub db_connect {
    my ( $db_type, $user, $pass, $server, $db, $commit );

    # Setup the variables, sanity check it too.
    if ( $_[0] =~ /^(dbtype|usr|pwd|db|srv|commit)$/ ) { # It's a hash
        my %settings = @_;
    
        $db_type    = $settings{dbtype} || '';
        $user       = $settings{usr}    || '';
        $pass       = $settings{pwd}    || '';
        $db         = $settings{db}     || '';
        $server     = $settings{srv}    || '';
        $commit     = $settings{commit} || '';

        $commit     = ( $commit =~ /off/i ) ? 0 : 1 ; 
    }
    else {
        ( $db_type, $user, $pass, $server, $db, $commit ) = @_;
    
        $db_type    = ''    if ( ! defined ( $db_type ) );
        $user       = ''    if ( ! defined ( $user ) );
        $pass       = ''    if ( ! defined ( $pass ) );
        $server     = ''    if ( ! defined ( $server ) );
        $db         = ''    if ( ! defined ( $db ) );
        $commit     = '1'   if ( ! defined ( $commit ) );
        $commit     = ( $commit =~ /off/i ) ? 0 : 1 ; 
    }

    croak 'No Database Type defined' if ( length( $db_type ) < 1 );

    my $dsn = "dbi:$db_type"; 
    
    $dsn .= ":dbname=$db" if $db;
    $dsn .= ( $server eq '' ) ? '' : ";host=$server";

    warn( $dsn );
    
    my $dbh = DBI->connect( $dsn, "$user", "$pass", 
                            {   RaiseError  =>  0,
                                PrintError  =>  1,
                                AutoCommit  =>  $commit } ) or
                                confess( $DBI::errstr );

    return( $dbh );
} # END db_connect 

#-------------------------------------------------
# db_disconnect( $dbh )
#-------------------------------------------------
sub db_disconnect {
    my $handle = shift;

    $handle->rollback if ( $handle->{AutoCommit} == 0 );

    $handle->disconnect;

    return;
} # END db_disconnect 

#-------------------------------------------------
# db_finish( $sth )
#-------------------------------------------------
sub db_finish {
    my $handle = shift;

    $handle->finish;

    return();
} # END db_finish

#-------------------------------------------------
# db_lastseq( $dbh, $sequence_name )
#-------------------------------------------------
sub db_lastseq {
    my ( $handle, $seq ) = @_;

    croak "No database handle for db_lastseq: $!\n" unless ( defined $handle );

    if ( ! defined $seq ) {
        $handle->rollback if ( $handle->{AutoCommit} );
        croak "No sequence for db_lastseq: $!\n";
    }

    my $sth = db_query ( $handle, "db_lastseq getting last value",
                         "SELECT last_value FROM $seq;" );

    my ( $last_value ) = db_next ( $sth );

    db_finish ( $sth );

    return ( $last_value );

} # END db_lastseq

#-------------------------------------------------
# db_next( $sth )
#-------------------------------------------------
sub db_next {
    my $handle = shift;

    croak "Error: db_next() not given a handle, $!\n" if ( ! $handle );
    
    return( $handle->fetchrow );    
} # END db_next 

#-------------------------------------------------
# db_nextvals( $sth )
#-------------------------------------------------
sub db_nextvals {
    my $handle = shift; 
   
    if( ! $handle ) {
        croak "Query error db_nextvals() not given a statement: $!\n";
    }
    
    return( $handle->fetchrow_hashref );

} # END db_nextvals

#-------------------------------------------------
# db_query( $dbh, $description, @query )
#-------------------------------------------------
sub db_query {
    my ( $handle, $description ) = ( shift, shift );
    my ( $query, $params );
    my ( $sql, $sth );
    
    if ( ! defined ( $handle ) ) {
        croak "Error $description: db_query not given a connection: $!\n";
    }
    
    # Determine which version of the function is being called.
    if ( ref( $_[0] ) eq 'ARRAY' ) {
        ( $query, $params ) = @_;

        $sql = join ( "\n", @$query );
    }
    else {
        # Warn users not to call db_query this way.
        warn(
            'db_query called without bound parameters is unsafe. ' .
            'Please update your code to use bound parameters.'
        );

        $sql = join ( "\n", @_ );
    }
    
    if ( length ( $sql ) == 0 ) {
        $handle->rollback if ( $handle->{AutoCommit} == 0 );
        croak "Error $description: db_query not given any SQL: $!\n";
    }

    $sth = $handle->prepare( $sql );
    $sth->execute( @$params ) or do 
        {
            $handle->rollback if ( $handle->{AutoCommit} == 0 );
            croak "SQL Query Error ( $description ): $sql\n";
        };
    
    return $sth;
} # END db_query 

#-------------------------------------------------
# db_rollback( $sth )
#-------------------------------------------------
sub db_rollback {
    my $handle = shift;

    $handle->rollback;

    return;
} # END db_rollback

#-------------------------------------------------
# db_rowcount( $sth )
#-------------------------------------------------
sub db_rowcount {
    my $handle = shift;

    return( $handle->rows );
} # END db_rowcount

#-------------------------------------------------
# db_run( $dbh, $description, @sql )
#-------------------------------------------------
sub db_run {
    my ( $handle, $description, @sql ) = @_;

    if ( ! defined ( $handle ) ) {
        croak "Error $description: db_run() not given a connection: $!\n";
    }

    if ( length ( @sql ) == 0 ) {
        $handle->rollback if ( $handle->{AutoCommit} == 0 );
        croak "Error $description: db_run() was not given any SQL: $!\n";
    }

    my $command = join ( "\n", @sql );

    $handle->do( $command ) or do 
            {
                $handle->rollback if ( $handle->{AutoCommit} == 0 );
                croak "SQL Query Error ($description): $command\n".
                      $handle->errstr. "\n";
            };

    return;
} # END db_run

# EOF
1;

__END__

=head1 NAME

Gantry::Utils::DB - Database wrapper functions, specfic to PostgreSQL

=head1 SYNOPSIS

  db_commit
    db_commit( $dbh );

  db_connect
    $dbh = db_connect( $db_type, $user, $pass, $server, $db, $commit );
    $dbh = db_connect( %config_hash );

  db_disconnect
    db_disconnect( $dbh );

  db_finish
    db_finish( $sth );

  db_lastseq
    $last_value = db_lastseq( $dbh, $sequence_name );

  db_next
    ( @values ) = db_next( $sth );

  db_nextvals
    $hash_reference = db_nextvals( $handle );

  db_query
    $sth = db_query_bp( $dbh, $description, \@sql_query, \@params );
    $sth = db_query( $dbh, $description, @sql_query );*
    * Not safe and should not be used.

  db_rollback
    db_rollback( $dbh );

  db_rowcount
    $rows = db_rowcount( $sth );

  db_run
    db_run( $dbh, $description, @sql_query );

=head1 DESCRIPTION

These functions wrap the common DBI calls to Databases with error
checking. 

=head1 FUNCTIONS 

=over 4

=item db_commit( $dbh )

Takes a database handle and commits all pending transactions if AutoCommit is
not enabled, otherwise does nothing. Returns no value.

=item $dbh = db_connect( %config_hash )

=item $dbh = db_connect( $db_type, $user, $pass, $server, $db, $commit )

Creates a connection to the database specified by $db on host $server. It then
returns a $dbh variable containing the connection. The hash has the values
db_type, usr, pwd, db, srv, commit for the respective variables. Commit 
should be specified as the text 'on' or 'off', case does not matter.
'db_type' should be a valid DBI database type ( eg. 'Pg' for postgres. ).

=item db_disconnect( $dbh )

Takes a database handle and disconnects that connection to the database,
it will also rollback any pending transactions that have not been commited 
with db_commit(). Returns no value.

=item db_finish( $sth )

Finishes a statement handle after a db_query() is completed. Returns nothing.

=item $last_value = db_lastseq( $dbh, $sequence_name )

Takes a database handle and the name of the sequence. It returns the last 
value that the sequence handed out. Usefully during transactions when 
the id of the last inserted SQL is needed. Will croak() if there is no
database handle passed in or if no sequence is passed in. If no sequence
is passed in, before croak()ing it will preform a rollback.

=item ( @values ) = db_next( $sth )

Takes a statement handle and returns the next row as an array. The function
will croak() if there is no statement handle passed in.

=item $hash_reference = db_nextvals( $sth )

This function takes a sql statement handle, C<$sth>, and returns the next
row from the statement as a hash reference with the column names as 
the keys and the values set from the row in the query.

=item $sth = db_query( $dbh, $description, \@sql_query, \@params )

This function takes a database handle, C<$dbh>, a description of the 
call, C<$description>, a sql query, C<\@sql_query>, and a list of parameters,
C<\@params> to bind. The query is then run against the database specified
in C<$dbh> using the specified bound parameters C<\@params>. The function
will return a statment handle, C<$sth>, or if there is an error while
executing the sql query it will C<croak()>.

=item $sth = db_query( $dbh, $description, @sql_query )

Calling db_query in this way is unsafe. It is vulnerable to sql injection
attacks. Please use the alternate calling method listed above instead.

=item db_rollback( $dbh )

Takes a database handle and preforms a rollback on the handle. Returns nothing.

=item $rows = db_rowcount( $sth )

Takes a statement handle and returns an integer count of the number of 
rows affected in the statement handle ( ie. the number of rows in a select ).

=item db_run( $dbh, $description, @sql_query )

This function behaves identcally to C<db_query()>, save it uses the DBI->do
vs the DBI->execute method to run the sql query. This means this function
will never return a statement handle.

=back

=head1 METHODS

=over 4

=item new

Not currently used, since there are no other methods to act on the
object.

=back

=head1 SEE ALSO

Gantry::Utils::SQL(3), DBI(3), DBD::Pg(3)

=head1 LIMITATIONS

This library is untested with databases other than Postgresql.

=head1 AUTHOR

Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005, Nicholas Studt.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
