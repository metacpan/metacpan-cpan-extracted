package Mail::Decency::Helper::Database::DBD;

use Moose;
extends 'Mail::Decency::Helper::Database';
use mro 'c3';

use version 0.74; our $VERSION = qv( "v0.1.4" );


use Data::Dumper;
use DBIx::Connector;
use SQL::Abstract;

has db   => ( is => "ro", isa => "DBIx::Connector" );
has sql  => ( is => "ro", isa => "SQL::Abstract" );
has args => ( is => "ro", isa => "ArrayRef", required => 1 );

sub BUILD {
    my ( $self ) = @_;
    
    $self->{ sql } = SQL::Abstract->new();
    
    eval {
        # connect via fork save connector
        my $dbh = DBIx::Connector->new( @{ $self->args }, { RaiseError => 1, PrintError => 0 } );
        
        # use abstracted api
        $self->{ db } = $dbh;
    };
    die "Error creating DBD insances: $@\n" if $@;
    
    return $self;
}


=head2 search

Search in database for a key

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub search {
    my ( $self, $schema, $table, $search_ref, $no_lock ) = @_;
    
    $self->read_lock unless $no_lock; # accquire semaphore
    $search_ref = $self->update_query( $search_ref );
    
    my $sth;
    eval {
        my ( $stm, @bind ) = $self->sql->select( "${schema}_${table}" => [ '*' ], $search_ref );
        $sth = $self->db->dbh->prepare_cached( $stm );
        $sth->execute( @bind );
    };
    if ( $@ || $DBI::errstr ) {
        $self->read_unlock; # release semaphore
        die "!! DATABASE ERROR: $DBI::errstr !!\n";
    }
    
    my @res;
    while ( my $res = $sth->fetchrow_hashref ) {
        push @res, $res;
    }
    
    $self->read_unlock unless $no_lock; # release semaphore
    return wantarray ? @res : \@res;
}


=head2 search_read

Returns read handle and read method name for massive read actions

=cut

sub search_read {
    my ( $self, $schema, $table, $search_ref ) = @_;
    $search_ref = $self->update_query( $search_ref );
    
    my $sth;
    eval {
        my ( $stm, @bind ) = $self->sql->select( "${schema}_${table}" => [ '*' ], $search_ref );
        $sth = $self->db->dbh->prepare_cached( $stm );
        $sth->execute( @bind );
    };
    die "Database error: $DBI::errstr\n" if $DBI::errstr;
    
    return ( $sth, 'fetchrow_hashref' );
}


=head2 get

Search in database for a key

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub get {
    my ( $self, $schema, $table, $search_ref, $no_lock ) = @_;
    $search_ref = $self->update_query( $search_ref );
    my ( $ref ) = $self->search( $schema => $table => $search_ref, $no_lock );
    my $res = $self->parse_data( $ref );
    return $res;
}


=head2 set

Getter method for BerkeleyDB::*

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut

sub set {
    my ( $self, $schema, $table, $search_ref, $data_ref ) = @_;
    $self->write_lock; # accquire semaphore
    
    $search_ref = $self->update_query( $search_ref );
    
    $data_ref ||= $search_ref;
    $data_ref = $self->update_data( $data_ref );
    
    
    # get existing ..
    my $existing = $self->get( $schema => $table => $search_ref, 1 );
    
    my ( $stm, @bind );
    
    # update ..
    if ( $existing ) {
        ( $stm, @bind ) = $self->sql->update( "${schema}_${table}" => $data_ref, $search_ref );
    }
    
    # insert ..
    else {
        ( $stm, @bind ) = $self->sql->insert( "${schema}_${table}" => { %$data_ref, %$search_ref } );
    }
    
    
    # exec ..
    eval {
        my $sth = $self->db->dbh->prepare( $stm );
        $sth->execute( @bind );
        #$self->db->dbh->commit;
    };
    if ( $@ || $DBI::errstr ) {
        $self->write_unlock; # release semaphore
        die "!! DATABASE ERROR: $DBI::errstr !!\n";
    }
    
    $self->write_unlock; # release semaphore
    
    return;
}




=head2 increment

Getter method for BerkeleyDB::*

CAUTION: use with care. Always provide ALL search keys, not only one of a kind!

=cut


sub increment {
    my ( $self, $schema, $table, $search_ref, $amount, $key ) = @_;
    $key ||= 'data';
    $amount ||= 1;
    
    # lock for increment
    $self->usr_lock;
    
    # read (don't use the actual read, this won't be lock aware!
    $search_ref = $self->update_query( $search_ref );
    my ( $ref ) = $self->search( $schema => $table => $search_ref );
    $ref = $self->parse_data( $ref );
    
    # increment data
    #print "$ref->{ $key } -> ";
    $ref->{ $key } += $amount;
    #print "$ref->{ $key }\n";
    
    # write data (without locks)
    $self->set( $schema => $table => $search_ref => $ref );
    
    # unlock after increment
    $self->usr_unlock;
    
    return $ref->{ $key };
}



=head2 remove

Delete a key permanent

=cut

sub remove {
    my ( $self, $schema, $table, $search_ref ) = @_;
    
    $self->write_lock; # accquire semaphore
    
    eval {
        my ( $stm, @bind ) = $self->sql->delete( "${schema}_${table}" => $search_ref );
        my $sth = $self->db->dbh->prepare( $stm );
        $sth->execute( @bind );
    };
    if ( $@ || $DBI::errstr ) {
        $self->write_unlock; # release semaphore
        die "Error in remove: $DBI::errstr\n"; 
    };
    
    $self->write_unlock; # release semaphore
    
    return;
}


=head2 ping

Check wheter schema/table exists

=cut

sub ping {
    my ( $self, $schema, $table ) = @_;
    
    my ( $stm, @bind ) = $self->sql->select( "${schema}_${table}" => [ 'COUNT( id )' ] );
    $self->db->dbh->{ PrintError } = 0;
    
    eval {
        my $sth = $self->db->dbh->prepare( $stm );
        if ( $sth ) {
            $sth->execute;
            my ( $amount ) = $sth->fetchrow_array;
        }
    };
    
    return ! $DBI::errstr;
}


=head2 create

Create database

So far supported:
Any database supporting VARCHAR, BLOB and INTEGER

=cut

sub setup {
    my ( $self, $schema, $table, $columns_ref, $execute ) = @_;
    
    my ( @columns, @indices, @uniques ) = ();
    while( my ( $name, $ref ) = each %$columns_ref ) {
        if ( $name eq '-index' ) {
            my $idx = join( "_", @{ $columns_ref->{ -index } } );
            push @indices, [
                "${schema}_${table}_${idx} ON ${schema}_${table}",
                $columns_ref->{ -index }
            ];
        }
        elsif ( $name eq '-unique' ) {
            my $idx = join( "_", @{ $columns_ref->{ -unique } } );
            push @uniques, [
                "${schema}_${table}_${idx} ON ${schema}_${table}",
                $columns_ref->{ -unique }
            ];
        }
        else {
            my $type = ref( $ref ) eq 'ARRAY'
                ? ( $#$ref == 0
                    ? $ref->[0]
                    : "$ref->[0]($ref->[1])"
                )
                : $ref
            ;
            push @columns, "$name $type";
        }
    }
    push @columns, "id INTEGER PRIMARY KEY";
    
    my @stm;
    
    push @stm, scalar $self->sql->generate(
        'create table', "${schema}_${table}" => \@columns );
    
    push @stm, scalar $self->sql->generate(
        'create index', $_->[0] => $_->[1] )
        for @indices;
    
    push @stm, scalar $self->sql->generate(
        'create unique index', $_->[0] => $_->[1] )
        for @uniques;
    
    unless ( $execute ) {
        print join( "\n",
            "-- TABLE: ${schema}_${table} (SQLITE):",
            join( ";\n", @stm ),
        ). ";\n";
        return 0;
    }
    else {
        foreach my $stm( @stm ) {
            $self->db->dbh->do( $stm );
        }
        return 1;
    }
}




=head2 update_data

Update input data for write 

Transforms any complex "data" key into YAML

=cut

sub update_data {
    my ( $self, $data_ref ) = @_;
    $data_ref = $self->next::method( $data_ref );
    if ( defined $data_ref->{ data } && ref( $data_ref->{ data } ) ) {
        $data_ref->{ data } = YAML::Dump( $data_ref->{ data } );
    }
    return wantarray ? ( $data_ref->{ data } ) : $data_ref;
}

=head2 parse_data

Parse data after read. Parses any YAML data in "data" key into perl object

=cut

sub parse_data {
    my ( $self, $data_ref ) = @_;
    $data_ref = $self->next::method( $data_ref );
    if ( $data_ref && ref( $data_ref ) && defined $data_ref->{ data } ) {
        eval {
            $data_ref->{ data } = YAML::Load( $data_ref->{ data } );
        };
    }
    return $data_ref;
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
