=head1 NAME

DynGig::Util::EZDB - Interface to a single-schema SQLite DB

=cut
package DynGig::Util::EZDB;

use warnings;
use strict;
use Carp;

use DBI;

=head1 SCHEMA
 
 key TEXT NOT NULL,
 value TEXT,
 PRIMARY KEY ( key )

=cut
our @SCHEMA =
(
    key   => 'TEXT NOT NULL PRIMARY KEY',
    value => 'TEXT',
);

=head1 SYNOPSIS
 
 use DynGig::Util::EZDB;
 
 my $file = '/db/file/path';
 my @table = qw( table1 table2 .. );

 my $db = DynGig::Util::EZDB->new( $file, table => \@table );
 my $db_existing = DynGig::Util::EZDB->new( $file );

 $db->set( 'table1', 'key1', 'value1' );

 my %keyval = $db->dump( 'table2' );

 map { $db->delete( $_, key => 'key1', value => 'value2' ) } $db->table();

 $db->truncate( 'table2' );

 my $quoted = $db->quote( "bob loblaw's law blog" )

=cut
sub new
{
    my ( $class, $db, %param ) = @_;
##  connect to DB
    my %config = ( RaiseError => 1, PrintWarn => 0, PrintError => 0 );
    my $dbh = DBI->connect( "DBI:SQLite:dbname=$db", '', '', \%config );

    croak "open $db: $!" unless open my $fh, '<', $db;
##  create tables
    my $table = $param{table};
    my $this = bless +{ sth => {}, dbh => $dbh, fh => $fh },
        ref $class || $class;

    map { $this->create( $_ ) } @$table if $table;

##  prepare statement handle
    $table = $dbh->table_info( undef, undef, undef, 'TABLE' )
        ->fetchall_hashref( 'TABLE_NAME' );

    map { $this->_statement( $_ ) unless $this->{sth}{$_} } keys %$table;
    return $this;
}

=head1 METHODS

=head2 schema( @schema )

Set or get schema. In get mode,
returns ARRAY ref in scalar context, returns ARRAY in list context.

=cut
sub schema
{
    my $class = shift;
    @SCHEMA = @_ if @_;
    return wantarray ? @SCHEMA : [ @SCHEMA ];
}

=head2 set( table, @key, @value )

INSERT or UPDATE keys and values into table. Returns status of operation.

=cut
sub set
{
    my ( $this, $table ) = splice @_, 0, 2;
    my $result = $this->_execute( $table, 'insert', @_ );
}

=head2 dump( table )

Dump all records from a table into a HASH.
Returns HASH reference in scalar context.
Returns flattened HASH in list context.

=cut
sub dump
{
    my ( $this, $table ) = @_;
    my ( $result, $sth ) = $this->_execute( $table, 'select_all' );
    my %result = map { @$_ } @{ $sth->fetchall_arrayref() } if $result;

    return wantarray ? %result : \%result;
}

=head2 delete( table, delete_key => value )

Deletes by attribute from a table.

=cut
sub delete
{
    my ( $this, $table, %param ) = @_;
    my %schema = @SCHEMA;

    map { $this->_execute( $table, 'delete_' . $_, $param{$_} )
        if defined $param{$_} } keys %schema;
}

=head2 create( table )

create a table

=cut
sub create
{
    my ( $this, $table ) = @_;
    my $neat = DBI::neat( $table );
    my @schema;
    my $exist = $this->{dbh}->table_info( undef, undef, undef, 'TABLE' )
        ->fetchall_hashref( 'TABLE_NAME' );

    for ( my $i = 0; $i < @SCHEMA; )
    {
        push @schema, sprintf '%s %s', @SCHEMA[ $i ++, $i ++ ];
    }

    $this->{dbh}
        ->prepare( sprintf 'CREATE TABLE %s ( %s )', $neat, join ', ', @schema )
        ->execute() unless $exist->{$table};

    $this->_statement( $table ) unless $this->{sth}{$table};
}

=head2 drop( table )

drop a table from the database

=cut
sub drop
{
    my ( $this, $table ) = @_;
    my $neat = DBI::neat( $table );

    return 1 unless $this->{sth}{$table};

    delete $this->{sth}{$table};
    $this->{dbh}->prepare( "DROP TABLE $neat" )->execute();
}

=head2 truncate( table )

Deletes all records from a table.

=cut
sub truncate
{
    my ( $this, $table ) = @_;
    my $result = $this->_execute( $table, 'truncate' );
}

=head2 quote( string )

See DBI::quote().

=cut
sub quote
{
    my $this = shift @_;
    $this->{dbh}->quote( @_ );
}

=head2 table()

Returns a list of all tables. Returns ARRAY reference in scalar context.

=cut
sub table
{
    my $this = shift @_;
    my @table = keys %{ $this->{sth} };

    return wantarray ? @table : \@table;
}

=head2 reload()

reload table names form DB files.

=cut
sub reload
{
    my $this = shift @_;
    my $table = $this->{dbh}->table_info( undef, undef, undef, 'TABLE' )
        ->fetchall_hashref( 'TABLE_NAME' );
    my $sth = $this->{sth};

    my %count;
    map { $count{$_}++ } keys %$sth, keys %$table;
    map { delete $sth->{$_} } grep { $count{$_} == 1 } keys %$sth;
    map { $this->_statement( $_ ) } grep { $count{$_} == 1 } keys %$table;

    return $this;
}

=head2 stat()

Stat of database file. Also see stat().
Returns ARRAY reference in scalar context.

=cut
sub stat
{
    my $this = shift @_;
    my @stat = stat $this->{fh};

    return wantarray ? @stat : \@stat;
}

sub _statement
{
    my ( $this, $table ) = @_;
    my @attr = map { $SCHEMA[ $_ << 1 ] } 0 .. @SCHEMA / 2 - 1;
    my $key = join ',', @attr;
    my $val = join ',', map { '?' } @attr; 

    my %op =
    (
        truncate => 'DELETE FROM %s',
        select_all => 'SELECT * FROM %s',
        insert => "INSERT OR REPLACE INTO %s ($key) VALUES ($val)",
    );

    map { $op{ 'delete_'.$_ } = "DELETE FROM %s WHERE $_ = ?" } @attr;

    my $dbh = $this->{dbh};
    my $sth = $this->{sth}{$table} ||= {};
    my $neat = DBI::neat( $table );

    map { $sth->{$_} = $dbh->prepare( sprintf $op{$_}, $neat ) } keys %op;
}

sub _execute
{
    my ( $this, $table, $name ) = splice @_, 0, 3;
    my $handle = $this->{sth};

    return unless $table && $handle->{$table};

    my ( $sth, $result ) = $handle->{$table}{$name};

    while ( $sth )
    {   
        $result = eval { $sth->execute( @_ ) };
        last unless $@;
        croak $@ if $@ !~ /locked/;
    }

    return $result, $sth;
}

=head1 SEE ALSO

DBI

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
