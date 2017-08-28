package MYDan::Deploy::Ctrl;

=head1 NAME

MYDan::Deploy::Ctrl - Controls maintenance via a SQLite database

=head1 SYNOPSIS

 use MYDan::Deploy::Ctrl;

 my $ctrl = MYDan::Deploy::Ctrl->new( $name => '/sqlite/file' );

 $ctrl->clear();
 $ctrl->pause();
 $ctrl->resume();
 $ctrl->exclude();
 sleep 3 if $ctrl->stuck();
 
=cut
use strict;
use warnings;

use MIME::Base64;
use base qw( MYDan::Util::SQLiteDB );

=head1 DATABASE

A SQLITE db has a I<watcher> table of I<four> columns:

 name : name of maintenance
 ctrl : 'error', 'pause' or 'exclude'
 node : stage name or node name
 info : additional information, if any

=cut
our ( $TABLE, $EXC, $ANY ) = qw( deploy exclude ANY );

sub define
{
    ctrl => 'TEXT NOT NULL',
    name => 'TEXT NOT NULL',
    node => 'TEXT NOT NULL',
    info => 'BLOB';
};

sub new
{
    my ( $class, $name, $db ) = splice @_;
    my $self = $class->SUPER::new( "$db/$name", $TABLE );
    $self->{name} = $name;
    return $self;
}

=head1 METHODS

=head3 pause( $job, $stage, $stop, $ctrl = 'pause' )

Insert a record that cause stuck.

=cut
sub pause
{
    my $self = shift;
    splice @_, 0, 0 , 'pause' if @_ == 3;
    return if @_ != 4;
    $self->insert( $TABLE, splice( @_, 0,3 ), encode_base64( pop @_ ) );
}

=head3 stuck( name, step )

Return records that cause @stage to be stuck. Return all records if @stage
is not defined.
stuck( )
stuck( name )
stuck( name, step )

=cut
sub stuck
{
    my ( $self, %term ) = shift;
    map{ $term{$_} = [ 1, $ANY, shift ] if @_ }qw( name node );
    $self->select( $TABLE => '*', %term, ctrl => [ 0, $EXC ] );
}

=head3 resume( name, step )

Clear records that cause @stage to be stuck. Clear all records if @stage
is not defined.


=cut
sub resume
{
    my ( $self, %term ) = shift;
    map{ $term{$_} = [ 1, $ANY, shift ] if @_ }qw( name node );
    $self->delete( $TABLE, %term, ctrl => [ 0, $EXC ] );
}

=head3 exclude( $node, $info )

Exclude $node with a $info.

=cut
sub exclude
{
    my $self = shift;
    map{ $self->insert( $TABLE, $EXC, $ANY, $ANY, $_ ) }@_;
}

=head3 excluded()

Return ARRAY ref of excluded nodes.

=cut
sub excluded
{
    my $self = shift;
    my @exc = $self->select( $TABLE => 'info', ctrl => [ 1, $EXC ] );
    return [ map { @$_ } @exc ];
}

=head3 dump()

Return ARRAY ref of *.

=cut
sub dump
{
    my $self = shift;
    my @exc = $self->select( $TABLE => '*' );
    return [ map { @$_ } @exc ];
}

=head3 clear()

clear all records. 

=cut
sub clear
{
    my $self = shift;
    $self->delete( $TABLE );
}

sub any
{
    my $self = shift;
    return $ANY;
}

1;
