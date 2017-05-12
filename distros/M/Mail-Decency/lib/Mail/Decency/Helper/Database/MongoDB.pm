package Mail::Decency::Helper::Database::MongoDB;

use Moose;
extends 'Mail::Decency::Helper::Database';
use mro 'c3';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;
use Tie::IxHash;
use MongoDB;
use Carp qw/ carp /;
use Time::HiRes qw/ usleep ualarm /;

has db       => ( is => "ro", isa => "MongoDB::Database" );
has host     => ( is => "ro", isa => "Str", default => "127.0.0.1" );
has port     => ( is => "ro", isa => "Int", default => 27017 );
has user     => ( is => "ro", isa => "Str", predicate => 'use_auth' );
has pass     => ( is => "ro", isa => "Str" );
has database => ( is => "ro", isa => "Str", default => "decency" );

sub BUILD {
    my ( $self ) = @_;
    
    $self->connect;
    
    return;
}


=head2 connect

=cut

sub connect {
    my ( $self ) = @_;
    eval {
        my %connect = (
            auto_reconnect => 1
        );
        if ( $self->host =~ /,/ ) {
            my ( $left, $right ) = split( /\s*,\s*/, $self->host, 2 );
            my ( $pleft, $pright ) = split( /\s*,\s*/, $self->port, 2 );
            $pright ||= $pleft;
            $connect{ host } = 'mongodb://'. join( ',',
                join( ':', $left, $pleft ),
                join( ':', $right, $pright ),
            );
        }
        else {
            my $host = $self->host || 'localhost';
            my $port = $self->port || '27017';
            $connect{ host } = 'mongodb://'. join( ':', $host, $port );
        }
        if ( $self->use_auth ) {
            $connect{ username } = $self->user;
            $connect{ password } = $self->pass if $self->pass;
            $connect{ db_name }  = $self->database;
        }
        $self->{ db } = MongoDB::Connection->new( %connect )->get_database( $self->database );
    };
    if ( $@ ) {
        die "Connection to mongodb failed: $@\n:";
    }
}


=head2 stat_print

=cut

sub stat_print {
    my ( $self ) = @_;
    print "TODO\n";
}



=head2 search

Search in database for a key

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub search {
    my ( $self, $schema, $table, $search_ref ) = @_;
    $self->read_lock; # accquire semaphore
    $search_ref = $self->update_query( $search_ref );
    
    my @res = $self->_try_transaction( $schema => $table => find => [ $search_ref ] );
    
    $self->read_unlock; # release semaphore
    return wantarray ? @res : \@res;
}


=head2 search_read

Returns read handle and read method name for massive read actions

=cut

sub search_read {
    my ( $self, $schema, $table, $search_ref ) = @_;
    $search_ref = $self->update_query( $search_ref );
    my ( $handle ) = $self->_try_transaction( $schema => $table => query => [ $search_ref ] );
    return ( $handle, 'next' );
}


=head2 get

Search in database for a key

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub get {
    my ( $self, $schema, $table, $search_ref ) = @_;
    $self->read_lock; # accquire semaphore
    $search_ref = $self->update_query( $search_ref );
    my ( $ref ) = $self->_try_transaction( $schema => $table => find_one => [ $search_ref ] );
    #print Dumper { q => $search_ref, res => $ref };
    $self->read_unlock; # release semaphore
    return $self->parse_data( $ref );
}


=head2 set

Getter method for BerkeleyDB::*

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub set {
    my ( $self, $schema, $table, $search_ref, $data_ref ) = @_;
    $self->write_lock; # accquire semaphore
    $search_ref = $self->update_query( $search_ref );
    $data_ref   = $self->update_data( $data_ref );
    delete $data_ref->{ _id } if defined $data_ref->{ _id };
    
    my ( $res ) = $self->_try_transaction( $schema => $table => update => [ $search_ref, { %$search_ref, %$data_ref }, { upsert => 1 } ] );
    
    $self->write_unlock; # release semaphore
    return $res;
}




=head2 increment

Increment a sole value. Has to have "data" as key!

=cut


sub increment {
    my ( $self, $schema, $table, $search_ref, $amount, $key ) = @_;
    $key ||= 'data';
    $amount ||= 1;
    $self->usr_lock; # accquire exclusive semaphore
    
    my $ref = $self->get( $schema => $table => $search_ref );
    $ref ||= { $key => 0 };
    $ref->{ $key } += $amount;
    $self->set( $schema => $table => $search_ref => $ref );
    
    $self->usr_unlock; # release exclusive semaphore
    return $ref->{ $key };
}



=head2 remove

Delete an entry permenante

=cut

sub remove {
    my ( $self, $schema, $table, $search_ref ) = @_;
    $self->write_lock; # accquire semaphore
    $search_ref = $self->update_query( $search_ref );
    my ( $res ) = $self->_try_transaction( $schema => $table => remove => [ $search_ref ] );
    $self->write_unlock; # release semaphore
    return $res;
}


=head2 ping

Pings MongoDB Server, check wheter connect possible or not

=cut

sub ping {
    my ( $self, $schema, $table ) = @_;
    
    eval {
        my $col = $self->db->get_collection( "${schema}_${table}" );
    };
    $self->logger->debug0( "Collection '${$schema}_${table}' not existing, yet.. no harm, should be created automatically. Response: $@" )
        if $@;
    
    return 1;
}


=head2 setup

Create database

setup indices

=cut

sub setup {
    my ( $self, $schema, $table, $columns_ref, $execute ) = @_;
    
    if ( $execute ) {
        if ( defined $columns_ref->{ -unique } ) {
            my $unique = Tie::IxHash->new( map { ( $_ => 1 ) } @{ $columns_ref->{ -unique } } );
            $self->db->get_collection( "${schema}_${table}" )->ensure_index( $unique, { unique => 1 } );
        }
        
        if ( defined $columns_ref->{ -index } ) {
            my $idx = Tie::IxHash->new( map { ( $_ => 1 ) } @{ $columns_ref->{ -index } } );
            $self->db->get_collection( "${schema}_${table}" )->ensure_index( $idx );
        }
    }
    
    else {
        print "-- MongoDB does no require create statements\n";
    }
    
    return 1;
}


=head2 update_query

=cut

sub update_query {
    my ( $self, $ref ) = @_;
    $ref = $self->next::method( $ref );
    
    my %op_match = (
        '>'  => '$gt',
        '<'  => '$lt',
        '>=' => '$gte',
        '<=' => '$lte',
        '!=' => '$ne',
    );
    while( my ( $k, $v ) = each %$ref ) {
        my $type = ref( $v );
        next unless $type;
        if ( $type eq 'HASH' ) {
            foreach my $op( keys %$v ) {
                $v->{ $op_match{ $op } } = delete $v->{ $op }
                    if defined $op_match{ $op };
            }
        }
        elsif ( $type eq 'ARRAY' ) {
            $ref->{ $k } = { '$in' => delete $ref->{ $k } };
        }
    }
    
    return $ref;
}


=head2 _try_transaction

Cause mongodb does not handle clean re-connections, this has to be implemented in code

=cut

sub _try_transaction {
    my ( $self, $schema, $table, $method, $args_ref ) = @_;
    
    my @res;
    
    # if mongodb was restarted, this will throw an error
    eval {
        local $SIG{ ALRM } = sub {
            #$self->logger->error( "MongoDB Connection lost, try reconnect" );
            die "Timeout\n";
        };
        ualarm( 1_000_000 );
        @res = $self->db->get_collection( "${schema}_${table}" )->$method( @$args_ref );
        alarm( 0 );
    };
    
    # handle disconnection event
    if ( $@ && ( $@ =~ /not connected/ || $@ =~ /Timeout/ ) ) {
        
        # try connect
        eval { $self->connect; };
        
        # mongo db probably down:
        carp "Cannot connect to MongoDB: $@" if $@;
        
        # fetch again
        @res = $self->db->get_collection( "${schema}_${table}" )->$method( @$args_ref );
    }
    elsif ( $@ ) {
        carp "Mongodb problem: $@";
    }
    
    return @res;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
