package MYDan::Node::DBI::Cache;

=head1 NAME

MYDan::Node::DBI::Cache - DB interface to MYDan::Node cache data

=head1 SYNOPSIS

 use MYDan::Node::DBI::Cache;

 my $db = MYDan::Node::DBI::Cache->new( '/database/file' );

 $db->select( 'node', name => [ 1, 'foo' ] );

=cut
use strict;
use warnings;

=head1 METHODS

See MYDan::Util::SQLiteDB.

=cut
use base qw( MYDan::Util::SQLiteDB );

=head1 DATABASE

A SQLITE db has a I<node> table of I<four> columns:

 name : cluster name
 attr : table name
 node : node name
 info : info associated with node

=cut
our $TABLE  = 'node';

sub define
{
    name => 'TEXT NOT NULL',
    attr => 'TEXT NOT NULL',
    node => 'TEXT NOT NULL',
    info => 'BLOB',
};


=head3 insert( @record ) 

Insert @record into $table.

=cut
sub insert
{
    my $self = shift;
    $self->SUPER::insert( $TABLE, @_ );
}

=head3 select( $column, %query ) 

Select $column from $table.

=cut
sub select
{
    my $self = shift;
    $self->SUPER::select( $TABLE, @_ );
}

=head3 delete( %query ) 

Delete records from $table.

=cut
sub delete
{
    my $self = shift;
    $self->SUPER::delete( $TABLE, @_ );
}

1;
