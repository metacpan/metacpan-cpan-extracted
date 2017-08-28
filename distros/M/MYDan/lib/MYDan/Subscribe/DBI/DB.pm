package MYDan::Subscribe::DBI::DB;

=head1 NAME

=head1 SYNOPSIS

 use MYDan::Subscribe::DBI::DB;

 my $db = MYDan::Subscribe::DBI::DB->new( '/database/file' );

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
 user : node name
 level : node name

=cut
our $TABLE  = 'subscribe';

sub define
{
    name => 'TEXT NOT NULL',
    attr => 'TEXT NOT NULL',
    user => 'TEXT NOT NULL',
    level => 'TEXT NOT NULL',
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
