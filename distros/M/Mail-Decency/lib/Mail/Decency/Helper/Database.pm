package Mail::Decency::Helper::Database;

use Moose;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

use IPC::SysV qw/ IPC_PRIVATE IPC_CREAT S_IRWXU /;
use IPC::Semaphore;

use Time::HiRes qw/ usleep ualarm /;
use Carp qw/ confess /;

=head1 NAME

Mail::Decency::Helper::Database

=head1 DESCRIPTION

Base class for all databases

=head1 SYNPOSIS

Create a new datbaase like this:

    Mail::Decency::Helper::Database->create( MongoDB => $config_ref );


=head1 CLASS ATTRIBUTES

=head2 type : Str

The type of the database (DBD, MongoDB)

=cut

has type   => ( is => "rw", isa => "Str" );

=head2 logger : CodeRef

Log-Handler method

=cut

has logger => ( is => "rw", isa => "Mail::Decency::Helper::Logger" );

=head2 locker : IPC::Semaphore

=cut

has locker => ( is => "ro", predicate => "use_lock" );

=head2 locker_pid : Int

PID of process creating the semaphore

=cut

has locker_pid => ( is => "rw", isa => 'Int' );


=head1 METHODS


=head2 create $type, $args_ref

Returns a new instance of the create database object

    my $database = Mail::Decency::Helper::Database->create( DBD => $args_ref );

=over

=item * $type

Either DBD or MongoDB for now

=item * $args_ref

HashRef of constrauctions variabels for the module's new-method

=back

=cut

sub create {
    my ( $class, $type, $args_ref ) = @_;
    
    my $module = "Mail::Decency::Helper::Database::$type";
    my $ok = eval "use $module; 1";
    unless ( $ok ) {
        confess "Unsupported database '$type': $@\n";
    }
    
    # create locker
    # get a free share..
    my $locker = IPC::Semaphore->new( IPC_PRIVATE, 3, S_IRWXU | IPC_CREAT )
        or die "Cannot create IPC Semaphore for locking: $!\n";
    $locker->setall( (1) x 3 )
        or die "Cannot initial unlock semaphores: $!\n";
    
    # create and return instance
    my $obj;
    eval {
        $obj = $module->new(
            %$args_ref,
            type       => $type,
            locker     => $locker,
            locker_pid => $$
        );
    };
    die "Connection error for '$type': $@" if $@;
    return $obj;
}


=head2 DEMOLISH

Remove locker

=cut

sub DEMOLISH {
    my ( $self ) = @_;
    $self->locker->remove if $self->locker_pid == $$; # remove semaphore with parent process only
    $self->db->disconnect if $self->db;
    delete $self->{ db };
}


=head2 get $schema, $table, $search_ref

Searches and returns single entry from database

See parse_data method for return contexts.

=over

=item * $schema

The schema/context/prefix of the lookup.. eg "throttle" for throttle tables

=item * $table

The table/suffix of the lookup .. eg "sender_domain" for the "throttle_sender_domain" table

=item * $search_ref

HashRef of search attributes. Can be flat or nested

    $search_ref = { attribute => "value" }; # simple equals
    $search_ref = { attribute => { ">" => 123 } }; # complex "greater then"

=back


=head2 set $schema, $table, $search_ref, $data_ref

Writes to database. Could affect multiple entries.

=over

=item * $schema, $table, $search_ref

Set get method

=item * $data_ref

HashRef or scalar of the data to be saved. If scalar, it is will be converted into { data => "scalar" } 

=back


=head2 search $schema, $table, $search_ref

Returns a list of search results (in opposite to the get method). In scalar contexts it returns an ArrayRef instead

=over

=item * $schema, $table, $search_ref

Set get method

=back

=cut


=head2 update_data

Transforms flat (scalar) values into { data => $value } hashrefs

=cut

sub update_data {
    my ( $self, $data ) = @_;
    return $data if ref( $data );
    return { data => $data };
}

=head2 parse_data $data_ref

Transforms hashref values in an array context from { value => $value } to ( $value )

In array-context, it will return the content of the "data" field, if any

Can be modified in derived modules.

=cut

sub parse_data {
    my ( $self, $data ) = @_;
    return unless defined $data;
    return wantarray ? ( $data ) : { data => $data } unless ref( $data );
    return wantarray ? ( $data->{ data } ) : $data;
}



=head2 update_query $query_ref

Update method for search query. Can be overwritten/extended in derived modules.

=cut

sub update_query {
    my ( $self, $query_ref ) = @_;
    return $query_ref if ref( $query_ref );
    return { key => $query_ref };
}


=head2 do_lock

Locks via flock file

=cut

sub do_lock {
    my ( $self, $num ) = @_;
    $num ||= 0;
    
    my $locker = $self->locker;
    
    # !! ATTENTION !!
    #   the purpose of this locking is to ensure increments in multi-forking
    #   environment work. The purpose is NOT to assure absolute mutual
    #   exclusion. 
    #   worst case for data: some counter are not incremented
    #   worst case for process: slow response (not to speak of deadlock)
    #   the process needs overrule the (statistic) data needs.
    # !! ATTENTION !!
    my $deadlock = 1_500_000; # = 1.5 sec
    eval {
        $SIG{ ALRM } = sub {
            die "Deadlock timeout\n";
        };
        ualarm( $deadlock );
        $locker->op( $num, -1, 0 );
        ualarm( 0 );
    };
    if ( $@ ) {
        $locker->setval( $num, 0 );
        warn "Deadlock in $num blighted\n";
    }
}


=head2 do_unlock

Unlocks the flock

=cut

sub do_unlock {
    my ( $self, $num ) = @_;
    $num ||= 0;
    #$self->locker->write( 0, 0, 1 );
    $self->locker->op( $num, 1, 0 );
}

=head2 read_lock

Do read lock

=cut

sub read_lock {
    return shift->do_lock( 1 );
}

=head2 read_unlock

Do unlock read

=cut

sub read_unlock {
    return shift->do_unlock( 1 );
}



=head2 write_lock

Do read lock

=cut

sub write_lock {
    my ( $self ) = @_;
    $self->read_lock;
    $self->do_lock( 2 );
    return ;
}

=head2 write_unlock

Do unlock read

=cut

sub write_unlock {
    my ( $self ) = @_;
    $self->do_unlock( 2 );
    $self->read_unlock;
}

=head2 usr_lock

Custom locker

=cut

sub usr_lock {
    return shift->do_lock( 0 );
}

=head2 usr_lock

Custom locker

=cut

sub usr_unlock {
    return shift->do_unlock( 0 );
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
