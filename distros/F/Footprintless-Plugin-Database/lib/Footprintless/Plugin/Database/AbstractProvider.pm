use strict;
use warnings;

package Footprintless::Plugin::Database::AbstractProvider;
$Footprintless::Plugin::Database::AbstractProvider::VERSION = '1.04';
# ABSTRACT: A base class for database providers
# PODNAME: Footprintless::Plugin::Database::AbstractProvider

use parent qw(Footprintless::MixableBase);

use overload q{""} => 'to_string', fallback => 1;

use Carp;
use DBI;
use Footprintless::Mixins qw(
    _entity
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub backup {
    die("abstract method invocation");
}

sub begin_transaction {
    my ($self) = @_;
    croak("not connected") unless ( $self->{connection} );

    $self->{connection}->begin_work();

    return $self;
}

sub client {
    my ( $self, %options ) = @_;

    my $in_file;
    eval {
        my $in_handle = delete( $options{in_handle} );
        if ( $options{in_file} ) {
            open( $in_file, '<', delete( $options{in_file} ) )
                || croak("invalid in_file: $!");
        }
        if ( $options{in_string} ) {
            my $string = delete( $options{in_string} );
            open( $in_file, '<', \$string )
                || croak("invalid in_string: $!");
        }
        $self->_connect_tunnel();

        my $local_in = $in_handle || $in_file;
        local (*STDIN) = $local_in if ($local_in);

        require Footprintless::Plugin::Database::SqlShellAdapter;
        Footprintless::Plugin::Database::SqlShellAdapter::sql_shell( $self->_connection_string(),
            $self->{username}, $self->{password}, @{ $options{client_options} } );
    };
    my $error = $@;
    $self->disconnect();
    if ($in_file) {
        close($in_file);
    }

    croak($error) if ($error);
}

sub _column_info {
    my ( $self, $statement_handle ) = @_;
    my $column_info = [];
    if ( defined( $statement_handle->{NUM_OF_FIELDS} ) ) {
        $column_info = [
            map {
                my $element = {};
                $element->{name} = $statement_handle->{NAME}->[$_]
                    if defined( $statement_handle->{NAME} );
                $element->{type} = $statement_handle->{TYPE}->[$_]
                    if defined( $statement_handle->{TYPE} );
                if ( my $type_info =
                    $self->{connection}->type_info( $statement_handle->{TYPE}->[$_] ) )
                {
                    $element->{type_name} = $type_info->{TYPE_NAME}
                        if defined( $type_info->{TYPE_NAME} );
                    $element->{type_info} = $type_info if defined( $type_info->{NAME} );
                }
                $element->{column_size} = $statement_handle->{PRECISION}->[$_]
                    if defined( $statement_handle->{PRECISION} );
                $element->{scale} = $statement_handle->{SCALE}->[$_]
                    if defined( $statement_handle->{SCALE} );
                if ( defined( $statement_handle->{NULLABLE} )
                    && ( my $nullable = $statement_handle->{NULLABLE}->[$_] ) != 2 )
                {
                    $element->{nullable} = $nullable ? 1 : 0;
                }
                $element;
            } 0 .. $statement_handle->{NUM_OF_FIELDS} - 1
        ];
    }
    return $column_info;
}

sub commit_transaction {
    my ($self) = @_;
    croak("not connected") unless ( $self->{connection} );

    $self->{connection}->commit();

    return $self;
}

sub connect {
    my ($self) = @_;

    return if ( $self->{connection} );

    $self->_connect_tunnel();

    my ( $hostname, $port ) = $self->_hostname_port();

    $logger->debugf( 'connecting to %s', $self->to_string() );
    $self->{connection} = DBI->connect( $self->_connection_string(),
        $self->{username}, $self->{password}, { RaiseError => 1, AutoCommit => 1 } )
        || croak("unable to connect to $hostname on port $port: $@");
    $logger->tracef('connected');

    return $self;
}

sub _connect_tunnel {
    my ($self) = @_;

    return if ( $self->{tunnel} );

    if ( $self->{tunnel_hostname} ) {
        $logger->debugf( 'opening tunnel through %s', $self->{tunnel_hostname} );
        $self->{tunnel} = $self->{factory}->tunnel(
            $self->{coordinate},
            destination_hostname => $self->{tunnel_destination_hostname} || $self->{hostname},
            destination_port => $self->{port}
        );
        $self->{tunnel}->open();
    }

    return $self;
}

sub _connection_string {
    die("abstract method invocation");
}

sub DESTROY {
    my ($self) = @_;
    $self->disconnect();
}

sub disconnect {
    my ($self) = @_;

    if ( $self->{connection} ) {
        $logger->debugf( 'disconnecting from %s', $self->to_string() );
        $self->{connection}->disconnect();
        delete( $self->{connection} );
    }

    if ( $self->{tunnel} ) {
        $logger->debug('closing tunnel');
        $self->{tunnel}->close();
        delete( $self->{tunnel} );
    }

    return $self;
}

sub execute {
    my ( $self, $query ) = @_;

    my $result;
    $self->_process_sql(
        $query,
        sub {
            $result = $_[1];
        }
    );
    return $result;
}

sub get_schema {
    return $_[0]->{schema};
}

sub _hostname_port {
    my ($self) = @_;

    my ( $hostname, $port );
    if ( $self->{tunnel} ) {
        $hostname = $self->{tunnel}->get_local_hostname() || 'localhost';
        $port = $self->{tunnel}->get_local_port();
    }
    else {
        $hostname = $self->{hostname};
        $port     = $self->{port};
    }

    return ( $hostname eq 'localhost' ? '127.0.0.1' : $hostname, $port );
}

sub _init {
    my ( $self, %options ) = @_;

    my $entity = $self->_entity( $self->{coordinate} );

    $self->{backup}                      = $entity->{backup};
    $self->{database}                    = $entity->{database};
    $self->{hostname}                    = $entity->{hostname} || 'localhost';
    $self->{password}                    = $entity->{password};
    $self->{port}                        = $entity->{port};
    $self->{schema}                      = $entity->{schema};
    $self->{tunnel_destination_hostname} = $entity->{tunnel_destination_hostname};
    $self->{tunnel_hostname}             = $entity->{tunnel_hostname};
    $self->{tunnel_username}             = $entity->{tunnel_username};
    $self->{username}                    = $entity->{username};

    return $self;
}

sub _process_sql {
    my ( $self, $query, $statement_handler ) = @_;

    my ( $sql, $parameters ) =
        ref($query) eq 'HASH'
        ? ( $query->{sql}, $query->{parameters} )
        : ($query);
    eval {
        if ( $logger->is_trace() ) {
            $logger->trace(
                "$self->{hostname}: '$sql'",
                (   $parameters
                    ? ( ",[" . join( ',', @$parameters ) . "]" )
                    : ''
                )
            );
        }
        my $statement_handle = $self->{connection}->prepare_cached($sql);
        &{$statement_handler}(
            $statement_handle,
            (   defined($parameters)
                ? $statement_handle->execute(@$parameters)
                : $statement_handle->execute()
            )
        );
        $statement_handle->finish();
    };
    if ($@) {
        croak("query failed: $@");
    }
}

sub query {
    my ( $self, $query, $result_handler, %options ) = @_;
    my $hash = $options{hash};
    my $column_info = $options{column_info} || ( $hash && [] );

    $self->_process_sql(
        $query,
        sub {
            my ( $statement_handle, $execute_result ) = @_;
            @$column_info = @{ $self->_column_info($statement_handle) } if $column_info;
            if ( !$options{no_fetch} ) {
                while ( my @row = $statement_handle->fetchrow_array() ) {
                    @row =
                        map { $column_info->[$_]->{name} => $row[$_] } 0 .. ( scalar(@row) - 1 )
                        if $hash;
                    &{$result_handler}(@row);
                }
            }
        }
    );
    return;
}

sub query_for_list {
    my ( $self, $query, $row_mapper, %options ) =
        ( shift, shift, ( scalar(@_) % 2 ) ? shift : undef, @_ );

    my @results = ();
    my $hash    = $options{hash};
    $self->query(
        $query,
        sub {
            if ($row_mapper) {
                push( @results, &{$row_mapper}(@_) );
            }
            else {
                push( @results, $hash ? {@_} : \@_ );
            }
        },
        %options
    );
    return wantarray() ? @results : \@results;
}

sub query_for_map {
    my ( $self, $query, $row_mapper, %options ) =
        ( shift, shift, ( scalar(@_) % 2 ) ? shift : undef, @_ );

    my %results = ();
    my $hash    = $options{hash};
    $self->query(
        $query,
        sub {
            if ($row_mapper) {
                my $key_value_pair = &{$row_mapper}(@_);
                $results{ $key_value_pair->[0] } = $key_value_pair->[1];
            }
            else {
                $results{ $_[ $hash ? 1 : 0 ] } = $hash ? {@_} : \@_;
            }
        },
        %options
    );
    return wantarray() ? %results : \%results;
}

sub query_for_scalar {
    my ( $self, $query, $row_mapper ) = @_;

    my $result;
    $self->_process_sql(
        $query,
        sub {
            my ( $statement_handle, $execute_result ) = @_;
            if ( my @row = $statement_handle->fetchrow_array() ) {
                if ($row_mapper) {
                    $result = &$row_mapper(@row);
                }
                else {
                    $result = $row[0];
                }
            }
        }
    );
    return $result;
}

sub restore {
    die("abstract method invocation");
}

sub rollback_transaction {
    my ($self) = @_;
    croak("not connected") unless ( $self->{connection} );

    $self->{connection}->rollback();

    return $self;
}

sub to_string {
    my ($self) = @_;
    return "{schema=>'$self->{schema}',hostname=>'$self->{hostname}',port=>$self->{port}}";
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::AbstractProvider - A base class for database providers

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    my $db = $footprintless->db('dev.db');
    $db->execute('create table foo ( id int, name varchar(16) )');

    my $rows_inserted = $db->execute(
        q[
            insert into foo (id, name) values
                (1, 'foo'),
                (2, 'bar')
        ]);

    my $name_of_1 = $db->query_for_scalar(
        {
            sql => 'select id, name from foo where id = ?',
            parameters => [1]
        },
        sub {
            my ($id, $name) = @_;
            return $name;
        });

    my $rows_count = $db->query_for_scalar('select count(*) from foo');

=head1 DESCRIPTION

Provides a base class implementing the common abstractions.  Other providers
should extend this class and override methods as desired.  

There are a few core concepts used for the execute, and query methods.  They are

=head3 query

A string containing a sql statement, or a hashref with a required C<sql> entry 
containing the sql statement and an optional C<parameters> entry contianing a 
list of values for the placeholders of the prepared statement.  For example:

    {
        sql => 'select name, phone from employees where dept = ? and title = ?',
        parameters => [$dept, $title]
    }

=head3 row_handler 

A callback that will be called once for each row.  It will be passed the list of
values requested in the query.  This callback does not return anything.

=head3 row_mapper

A callback that will be called once for each row.  It will be passed the list of
values requested in the query.  It must return a value that will be I<collected>
by the C<query_for_xxx> method according to that methods behavior.

=head1 ENTITIES

A simple deployment:

    db => {
        provider => 'mysql',
        schema => 'my_table',
        port => 3306,
        username => $properties->{db.username},
        pasword => $properties->{db.password}
    }

A more complex situation, perhaps tunneling over ssh to your prod database:

    db => {
        provider => 'postgres',
        database => 'my_database',
        schema => 'my_table',
        hostname => 'my.production.server',
        port => 5432,
        username => $properties->{db.username},
        pasword => $properties->{db.password},
        tunnel_hostname => 'my.bastion.host'
    }

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate, %options)

Constructs a new database provider instance.  Should be called on a subclass.
Subclasses should I<NOT> override this method, rather, override C<_init>.  See
L<Footprintless::MixableBase> for details.

=head1 METHODS

=head2 backup($to, [%options])

Will backup the database to C<$to>.  The allowed values for C<$to> are:

- Another instance of the same provider to pipe to the C<restore> method
- A callback method to call with each I<chunk> of the backup
- A C<GLOB> to write to
- A filename to write to

The options are determined by the implementation.

=head2 begin_transaction()

Begins a transaction.

=head2 client([%options])

Will open an interactive client connected to the database.

=head2 commit_transaction()

Commits the current transaction.

=head2 connect()

Opens a connection to the database.

=head2 disconnect()

Closes the current connection to the database.

=head2 execute($query)

Executes C<$query> and returns the number of rows effected.

=head2 get_schema()

Returns the configured schema name.

=head2 query($query, $row_handler, %options)

Executes C<$query> and calls C<$row_handler> once for each row.  Does not return
anything. If you do not set the C<hash> option, the C<$row_handler> gets the 
field data in the C<@_> array (see C<hash> option below).

The following options may be set:

=over 4

=item C<column_info>

To get column information, set this option to an array ref - when the query is
executed, before the C<$row_handler> is called for the first time, the array
will be populated with the column information, the indexed by result column.
This array may be empty if the underlying driver does not support column
information.

Each item in the array will be a hash containing the following properties if
the driver does not support a field it will be missing:

=over 4

=item C<name>

The column name

=item C<type>

The SQL type identified by number - these are supposedly cataloged as part of
the ISO/IEC 9075 type registry - but I would not know because this particular
spec seems to be a particularly well guarded secret (I could not get it for
free on the internet). I suggest looking directly at the C<type_name> and 
C<type_info> properties instead of worrying about this.

=item C<type_name>

The SQL type identified by name.

=item C<type_info> 

A single C<type_info> hash describing the type for the column as
described at http://search.cpan.org/~timb/DBI-1.637/DBI.pm#type_info

=item C<column_size>

The precision of the column. For numeric types, this is the number of digits
(does not include sign, decimal point, or even exponent digits). For character
based types, this is the number of bytes which may or may not correspond to
the number of characters.

=item C<scale>

An integer indicating "scale" or C<undef> for types where scale is not used.

=item C<nullable>

Indicates whether or not we can assign this column to null - C<undef> if the
nullability is unknown. Otherwise this may be evaluated a boolean.

=back

=item C<hash>

Set this to a true value to get the parameters to the C<$row_handler> to be set up
suitable for a hash assignment. The actual parameters are an array, but will
now come as: column-name-1 => field-1, column-name-2 => field-2...

=item C<no_fetch>

Set this to a true value to skip the fetching of data from a result set - this is
useful for "queries" that have no result set and would throw an exception when
we attempt to fetch a row (i.e. C<ALTER SESSION> queries). 

=back

=head2 query_for_list($query, [$row_mapper,] %options)

Executes C<$query> and calls C<$row_mapper> once for each row.  C<$row_mapper> is
expected to return a scalar representing the row.  All of the returned scalars will
be collected into a list and returned.  When called in list context, a list is
returned.  In scalar context, an arrayref is returned.  If C<$row_mapper> is not
supplied, each rows values will be returned as an arrayref (or as hashref if the
C<hash> option is selected). For information about the C<options>, see the 
C<query()> method - being that they are the same options.

=head2 query_for_map($query, [$row_mapper,] %options)

Executes C<$query> and calls C<$row_mapper> once for each row.  C<$row_mapper> is
expected to return a hashref with a single key/value pair.  All of the returned 
hashrefs will be collected into a single hash and returned.  When called in list 
context, a hash is returned.  In scalar context, a hashref is returned.  If 
C<$row_mapper> is not supplied, each rows values will be returned as a hashref 
using the first value as the key, and the whole rows arrayref as the value (or
as hashref if the C<hash> option is selected). For information about the
C<options>, see the C<query()> method - being that they are the same options..

=head2 query_for_scalar($query, $row_mapper)

Executes C<$query> and calls C<$row_mapper> once for the first row of the result 
set.  C<$row_mapper> is expected to return a scalar representing the row.  If 
C<$row_mapper> is not supplied, the first value from the first row is returned.
This can be useful for queries like C<select count(*) from foo>.

=head2 restore($from, %options)

Will restore the database from C<$from>.  The allowed values for C<$from> are:

- Another instance of the same provider to pipe from the C<backup> method
- A hashref containing a C<command> key whose value is a command to pipe input from
- A C<GLOB> to read from
- A filename to read from

The options are determined by the implementation.

=head2 rollback_transaction()

Rolls back the current transaction.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<DBI|DBI>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::MixableBase|Footprintless::MixableBase>

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<Footprintless::Plugin::Database::CsvProvider|Footprintless::Plugin::Database::CsvProvider>

=item *

L<Footprintless::Plugin::Database::MySqlProvider|Footprintless::Plugin::Database::MySqlProvider>

=item *

L<Footprintless::Plugin::Database::PostgreSqlProvider|Footprintless::Plugin::Database::PostgreSqlProvider>

=back

=for Pod::Coverage DESTROY to_string

=cut
