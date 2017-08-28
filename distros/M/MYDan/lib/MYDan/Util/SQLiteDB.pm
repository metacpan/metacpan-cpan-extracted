package MYDan::Util::SQLiteDB;

=head1 NAME

MYDan::Util::SQLiteDB - SQLite database interface

=head1 SYNOPSIS

 use base qw( MYDan::Util::SQLiteDB );

 my $db = MYDan::Util::SQLiteDBI->new( '/database/file' => @table );

 $db->select( foo => 'name', [ 1, 'bar' ] );

=cut
use strict;
use warnings;
use Carp;
use DBI;

sub new
{
    my ( $class, $db ) = splice @_, 0, 2;

    $db = DBI->connect
    ( 
        "DBI:SQLite:dbname=$db", '', '',
        { RaiseError => 1, PrintWarn => 0, PrintError => 0 }
    );

    my $self = bless { db => $db }, ref $class || $class;
    my @define = $self->define();
    $self->{column} = [ map { $define[ $_ << 1 ] } 0 .. @define / 2 - 1 ];

    my %exist = $self->exist();
    map { $self->create( $_ ) } @_, keys %exist;
    return $self;
}

=head1 METHODS

=head3 column()

Returns table columns.

=cut
sub column
{
    my $self = shift;
    return @{ $self->{column} };
}

=head3 table()

Returns table names.

=cut
sub table
{
    my $self = shift;
    my %table = $self->exist();
    keys %table;
}

=head3 create( $table )

Create $table.

=cut
sub create
{
    my ( $self, $table ) = splice @_;
    my %exist = $self->exist();
    my %column = $self->define();
    my @column = $self->column();

    my $db = $self->{db};
    my $neat = DBI::neat( $table );

    unless ( $exist{$table} )
    {
        $db->do
        (
            sprintf "CREATE TABLE $neat ( %s )",
            join ', ', map { "$_ $column{$_}" } @column
        ) 
    }

    my $stmt = $self->{stmt}{$table} = {};

=head3 insert( $table, @record )

Inserts @record into $table.

=cut
    $stmt->{insert} = $db->prepare
    (
        sprintf "INSERT OR REPLACE INTO $neat ( %s ) VALUES ( %s )",
        join( ',', @column ), join( ',', map { '?' } @column )
    );

=head3 dump( $table )

Dump all records from $table.

=cut
    $stmt->{dump} = $db->prepare( "SELECT * FROM $neat" );

=head3 truncate( $table )

Delete all records from $table.

=cut
    $stmt->{truncate} = $db->prepare( "DELETE FROM $neat" );

=head3 drop( $table )

Drop $table.

=cut
    $stmt->{drop} = $db->prepare( "DROP TABLE $neat" );
    return $self;
}

sub AUTOLOAD
{
    my ( $self, $table ) = splice @_, 0, 2;
    return unless my $stmt = $self->{stmt}{$table};
    return unless our $AUTOLOAD =~ /::(\w+)$/ && ( $stmt = $stmt->{$1} );
    @{ $self->execute( $stmt, @_ )->fetchall_arrayref };
}

sub DESTROY
{
   my $self = shift;
   %$self = ();
}

=head3 select( $table, $column, %query ) 

Select $column from $table.

=cut
sub select
{
    my ( $self, $table, $column ) = splice @_, 0, 3;
    return unless $self->{stmt}{$table};
    my $stmt = "SELECT $column FROM ". DBI::neat( $table ). $self->query( @_ );
    return @{ $self->do( $stmt )->fetchall_arrayref };
}

=head3 delete( $table, %query ) 

Delete records from $table.

=cut
sub delete
{
    my ( $self, $table ) = splice @_, 0, 2;
    return unless $self->{stmt}{$table};
    $self->do( 'DELETE FROM '. DBI::neat( $table ). $self->query( @_ ) );
}

=head1 QUERY

I<%query> consists of ARRAY indexed by I<column>. The first array element
is a boolean value that indcates if I<column> is IN or NOT IN the rest of
the array elements. i.e.

 x => [ 0, 'foo', 'bar' ], y => [ 1, 'bar', 'baz' ]

means:

 "WHERE x NOT IN ( 'foo','bar' ) AND y IN ( 'bar','baz' )"

=cut
sub query
{
    my ( $self, %cond, @cond ) = splice @_;

    while ( my ( $col, $cond ) = each %cond )
    {
        my $in = $cond->[0] eq '1' ? 'IN' : $cond->[0] eq '0' ?'NOT IN' : $cond->[0];
        push @cond, sprintf "$col $in ( %s )",
            join ',', map { DBI::neat( $cond->[$_] ) } 1 .. @$cond - 1;
    }
    return @cond ? ' WHERE ' . join ' AND ', @cond : '';
}

## return a flattened hash of existing tables
sub exist
{
    my $self = shift;
    my $exist = $self->{db}->table_info( undef, undef, undef, 'TABLE' )
        ->fetchall_hashref( 'TABLE_NAME' );
    return %$exist; 
}

## execute a statement
sub do
{
    my $self = shift;
    $self->execute( $self->{db}->prepare( @_ ) );
}

## execute a prepared statement
sub execute
{
    my ( $self, $stmt ) = splice @_, 0, 2;
    while ( $stmt )
    {
        eval { $stmt->execute( @_ ) };
        last unless $@;
        confess $@ if $@ !~ /locked/;
    }
    return $stmt;
}

1;
