package Melian;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Perl client to the Melian cache
$Melian::VERSION = '0.006';
use v5.34;
use Carp qw(croak);
use IO::Socket::INET;
use IO::Socket::UNIX;
use JSON::XS qw(decode_json);
use List::Util qw(first);
use Socket qw(SOCK_STREAM);
use constant {
    'MELIAN_HEADER_VERSION' => 0x11,
    'ACTION_FETCH'          => ord('F'),
    'ACTION_DESCRIBE'       => ord('D'),
};

use Exporter qw(import);
our @EXPORT_OK = qw(
    fetch_raw_with
    fetch_by_int_with
    fetch_by_string_with
    table_of
    column_id_of
    load_schema_from_describe
);

sub new {
    my ($class, @opts) = @_;
    @opts > 0 && @opts % 2 == 0
        or croak('Melian->new(%args)');

    my %args = @opts;
    my $self = bless {
        'dsn'     => $args{'dsn'}     // 'unix:///tmp/melian.sock',
        'timeout' => $args{'timeout'} // 1,
        'socket'  => undef,
    }, $class;

    my @schema_args = grep /^schema(?:_spec|_file)?$/, keys %args;
    @schema_args > 1
        and croak(q{Provide maximum one of: 'schema', 'schema_spec', 'schema_file'});

    if ( ! $self->{'socket'} ) {
        $self->connect();
    }

    if (my $schema = $args{'schema'}) {
        $self->{'schema'} = $schema;
    } elsif (my $spec = $args{'schema_spec'}) {
        $self->{'schema'} = load_schema_from_spec( $args{'schema_spec'} );
    } elsif (my $path = $args{'schema_file'}) {
        $self->{'schema'} = load_schema_from_file( $args{'schema_file'} );
    } else {
        $self->{'schema'} = load_schema_from_describe( $self->{'socket'} );
    }

    return $self;
}

sub create_connection {
    my ($class, @opts) = @_;
    @opts > 0 && @opts % 2 == 0
        or croak('Melian->create_connection(%args)');

    my %args    = @opts;
    my $dsn     = $args{'dsn'}     // 'unix:///tmp/melian.sock';
    my $timeout = $args{'timeout'} // 1;

    return _connect_return_socket( $dsn, $timeout );
}

sub connect {
    my ($self) = @_;
    return if $self->{'socket'};

    my $dsn = $self->{'dsn'};
    if ($dsn =~ m{^unix://(.+)$}i) {
        my $path = $1;
        $self->{'socket'} = IO::Socket::UNIX->new(
            'Type' => SOCK_STREAM(),
            'Peer' => $path,
        ) or croak "Failed to connect to UNIX socket $path: $!";
    } elsif ($dsn =~ m{^tcp://([^:]+):(\d+)$}i) {
        my ($host, $port) = ($1, $2);
        $self->{'socket'} = IO::Socket::INET->new(
            'PeerHost' => $host,
            'PeerPort' => $port,
            'Proto'    => 'tcp',
            'Timeout'  => $self->{'timeout'},
        ) or croak "Failed to connect to $host:$port: $!";
    } else {
        croak "Unsupported DSN '$dsn'. Use unix:///path or tcp://host:port";
    }

    $self->{'socket'}->autoflush(1);
    return 1;
}

sub _connect_return_socket {
    my $socket;
    if ($_[0] =~ m{^unix://(.+)$}i) {
        my $path = $1;
        $socket = IO::Socket::UNIX->new(
            'Type' => SOCK_STREAM(),
            'Peer' => $path,
        ) or croak "Failed to connect to UNIX socket $path: $!";
    } elsif ($_[0]=~ m{^tcp://([^:]+):(\d+)$}i) {
        my ($host, $port) = ($1, $2);
        $socket = IO::Socket::INET->new(
            'PeerHost' => $host,
            'PeerPort' => $port,
            'Proto'    => 'tcp',
            'Timeout'  => $_[1],
        ) or croak "Failed to connect to $host:$port: $!";
    } else {
        croak "Unsupported DSN '$_[0]'. Use unix:///path or tcp://host:port";
    }

    $socket->autoflush(1);
    return $socket;
}

sub disconnect {
    my ($self) = @_;
    if ($self->{'socket'}) {
        $self->{'socket'}->close();
        $self->{'socket'} = undef;
        return 1;
    }

    return;
}

sub disconnect_socket {
    $_[0] or return;
    $_[0]->close();
    $_[0] = undef;
    return 1;
}

sub fetch_raw_from {
    my ( $self, $table_name, $column_name, $key ) = @_;

    # Get table ID
    my $table = $self->get_table_id($table_name);
    my $table_id = $table->{'id'};

    # Get column ID
    my $column_id = $self->get_column_id( $table, $column_name );
    return $self->fetch_raw( $table_id, $column_id, $key );
}

sub fetch_raw {
    my ( $self, $table_id, $column_id, $key ) = @_;
    defined $key
        or croak("You must provide a key to fetch");
    return $self->_send(ACTION_FETCH(), $table_id, $column_id, $key);
}

# $conn, $table_id, $column_id, $key
sub fetch_raw_with {
    defined $_[3]
        or croak("You must provide a key to fetch");
    return _send_with($_[0], ACTION_FETCH(), $_[1], $_[2], $_[3]);
}

sub fetch_by_string_from {
    my ( $self, $table_name, $column_name, $key ) = @_;

    # Get table ID
    my $table = $self->get_table_id($table_name);
    my $table_id = $table->{'id'};

    # Get column ID
    my $column_id = $self->get_column_id( $table, $column_name );
    return $self->fetch_by_string( $table_id, $column_id, $key );
}

sub fetch_by_string {
    my ($self, $table_id, $column_id, $key) = @_;
    my $payload = $self->fetch_raw($table_id, $column_id, $key);
    return undef if $payload eq '';
    return decode_json($payload);
}

# $conn, $table_id, $column_id, $key
sub fetch_by_string_with {
    my $payload = fetch_raw_with($_[0], $_[1], $_[2], $_[3]);
    return undef if $payload eq '';
    return decode_json($payload);
}

sub fetch_by_int_from {
    my ( $self, $table_name, $column_name, $id ) = @_;

    # Get table ID
    my $table = $self->get_table_id($table_name);
    my $table_id = $table->{'id'};

    # Get column ID
    my $column_id = $self->get_column_id( $table, $column_name );

    return $self->fetch_by_int( $table_id, $column_id, $id );
}

sub fetch_by_int {
    my ($self, $table_id, $column_id, $id) = @_;
    return $self->fetch_by_string($table_id, $column_id, pack 'V', $id);
}

# $conn, $table_id, $column_id, $id
sub fetch_by_int_with {
    return fetch_by_string_with($_[0], $_[1], $_[2], pack 'V', $_[3]);
}

sub load_schema_from_describe {
    my $payload = _send_with( $_[0], ACTION_DESCRIBE(), 0, 0, '' );
    defined $payload && length $payload
        or croak('Could not get schema data');
    return decode_json($payload);
}


sub load_schema_from_file {
    my $path = shift;

    open my $fh, '<', $path
        or croak("Cannot open schema file $path: $!");
    local $/;
    my $content = <$fh>;
    close $fh
        or croak("Cannot close schema file: $path: $!");

    my $decoded;
    eval {
        $decoded = decode_json($content);
        1;
    } or do {
        my $error = $@ || 'Zombie error';
        croak("Failed to parse JSON schema in file '$path': $error");
    };

    return $decoded;
}

# table1#0|60|id#0:int,table2#1|45|id#0:int;hostname#1:string
sub load_schema_from_spec {
    my $spec = shift;
    my %data;

    for my $section_data ( split m{,}, $spec ) {
        my ( $table_data, $table_period, $columns ) = split m{\|}, $section_data;
        my ( $table_name, $table_id ) = split m{#}, $table_data;
        defined $table_name && defined $table_id
            or croak('Schema spec failure: Missing table name or table ID');

        my %table_entry = (
            'name'   => $table_name,
            'id'     => $table_id,
            'period' => $table_period,
        );

        my @columns;
        my $column_id = 0;
        foreach my $column_data ( split m{;}, $columns ) {
            my ( $column_name, $column_type ) = split /:/, $column_data;
            push @{ $table_entry{'indexes'} }, {
                'id'     => $column_id++,
                'column' => $column_name,
                'type'   => $column_type,
            }
        }

        push @{ $data{'tables'} }, \%table_entry;
    }

    return \%data;
}

sub _send {
    my ( $self, $action, $table_id, $column_id, $payload ) = @_;
    $payload //= '';
    defined $table_id && defined $column_id
        or croak("Invalid table ID or index ID");

    my $header = pack(
        'CCCCN',
        MELIAN_HEADER_VERSION(),
        $action,
        $table_id,
        $column_id,
        length $payload,
    );

    _write_all( $self->{'socket'}, $header . $payload );
    my $len_buf = _read_exactly( $self->{'socket'}, 4 );
    my $len = unpack 'N', $len_buf;
    return '' if $len == 0;
    return _read_exactly( $self->{'socket'}, $len );
}

# $conn, $action, $table_id, $column_id, $payload
sub _send_with {
    $_[4] //= '';
    defined $_[2] && defined $_[3]
        or croak("Invalid table ID or index ID");

    my $header = pack(
        'CCCCN',
        MELIAN_HEADER_VERSION(),
        $_[1],
        $_[2],
        $_[3],
        length $_[4],
    );

    _write_all( $_[0], $header . $_[4] );
    my $len_buf = _read_exactly( $_[0], 4 );
    my $len = unpack 'N', $len_buf;
    return '' if $len == 0;
    return _read_exactly( $_[0], $len );
}

# $socket, $buf
sub _write_all {
    my $offset = 0;
    my $len = length $_[1];
    while ( $offset < $len ) {
        my $written = syswrite( $_[0], $_[1], $len - $offset, $offset );
        croak("Melian write failed: $!") unless defined $written && $written > 0;
        $offset += $written;
    }
}

# $socket, $len
sub _read_exactly {
    my $buffer = '';

    while ( length($buffer) < $_[1] ) {
        my $read = sysread( $_[0], my $chunk, $_[1] - length $buffer );
        croak("Melian read failed: $!") unless defined $read;
        croak("Melian socket closed unexpectedly") if $read == 0;
        $buffer .= $chunk;
    }

    return $buffer;
}

sub get_table_id {
    my ( $self, $name ) = @_;
    my $table = List::Util::first(
        sub { $_->{'name'} eq $name },
        @{ $self->{'schema'}{'tables'} },
    );

    $table or croak("Cannot find table named '$name'");
    return $table;
}

sub table_of {
    my ( $schema, $name ) = @_;
    my $table = List::Util::first(
        sub { $_->{'name'} eq $name },
        @{ $schema->{'tables'} }
    );
    $table or croak("Cannot find table named '$name'");
    return $table;
}

sub get_column_id {
    my ( $self, $table, $name ) = @_;

    # Get column ID
    my $column = List::Util::first(
        sub { $_->{'column'} eq $name },
        @{ $table->{'indexes'} },
    );

    $column or croak("Cannot find column named '$name'");
    return $column->{'id'};
}

sub column_id_of {
    my ( $table, $name ) = @_;

    # Get column ID
    my $column = List::Util::first(
        sub { $_->{'column'} eq $name },
        @{ $table->{'indexes'} },
    );

    $column or croak("Cannot find column named '$name'");
    return $column->{'id'};
}

sub schema {
    my $self = shift;
    return $self->{'schema'};
}

sub DESTROY { $_[0]->disconnect() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Melian - Perl client to the Melian cache

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Melian;

    #-----------------------------------------------
    # OO INTERFACE (easy, name-based)
    #-----------------------------------------------
    my $melian = Melian->new(
        'dsn' => 'unix:///tmp/melian.sock',
    );

    my $row = $melian->fetch_by_string_from( 'cats', 'name', 'Pixel' );

    # Using IDs directly (faster)
    my $row2 = $melian->fetch_by_string( 1, 1, 'Pixel' );

    #-----------------------------------------------
    # FUNCTIONAL INTERFACE (fastest)
    #-----------------------------------------------
    use Melian qw(fetch_by_string_with);

    my $conn = Melian->create_connection(
        'dsn' => 'unix:///tmp/melian.sock',
    );

    # Must use IDs in functional mode
    my $row3 = fetch_by_string_with( $conn, 1, 1, 'Pixel' );

=head1 DESCRIPTION

Melian is a tiny, fast, no-nonsense Perl client for the Melian cache server.

L<Melian|https://github.com/xsawyerx/melian/> (the server) keeps full table
snapshots in memory. Lookups are done entirely inside the server and returned
as small JSON blobs. Think of it as a super-fast read-only lookup service.

This module gives you two ways to talk to Melian:

=head2 Object-Oriented Mode (easy)

Use table names and column names:

    $melian->fetch_by_string_from( 'cats', 'name', 'Pixel' );

Behind the scenes, the module:

=over 4

=item *

Looks up the table ID in the schema

=item *

Looks up the column ID in the schema

=item *

Builds the binary request to the server

=item *

Reads the reply and decodes JSON

=back

This is the most convenient way. It is a little slower, because there is some
name lookup and method dispatch each time.

=head2 Functional Mode (fastest)

Use this when you want raw speed:

    my $conn = Melian->create_connection(...);
    my $row = fetch_by_string_with( $conn, $table_id, $column_id, $key );

This avoids:

=over 4

=item *

Method calls

=item *

Object construction

=item *

Lookup of table IDs and column IDs

=back

It is simply: "write a request to the socket, read a response."

If you're chasing microseconds, this is the mode for you.

=head1 SCHEMA

Melian needs a schema so it knows which table IDs and column IDs correspond
to which names. A schema looks something like:

    people#0|60|id#0:int

Or:

    people#0|60|id#0:int,cats#1|45|id#0:int;name#1:string

The format is simple:

=over 4

=item *

C<table_name#table_id> (multiple tables separated by C<,>)

=item *

C<|refresh_period_in_seconds>

=item *

C<|column_name#column_id:column_type> (multiple columns separated by C<;>)

=back

You do NOT need to write this schema unless you want to. If you do not supply
one, Melian will request it automatically from the server at startup.

If you provide a schema, it should match the schema set for the Melian server.

=head2 Accessing table and column IDs

Once the client is constructed:

    my $schema = $melian->schema();

Each table entry contains:

    {
        id      => 1,
        name    => "cats",
        period  => 45,
        indexes => [
            { id => 0, column => "id",   type => "int"    },
            { id => 1, column => "name", type => "string" },
        ],
    }

If you use the functional API, you probably want to store them in constants:

    use constant {
        'CAT_ID_TABLE'    => 1,
        'CAT_ID_COLUMN'   => 0, # integer column
        'CAT_NAME_COLUMN' => 1, # string column
    };

This saves name lookups on every request.

=head1 METHODS

=head2 C<new(...)>

    my $melian = Melian->new(
        'dsn'         => 'unix:///tmp/melian.sock',
        'timeout'     => 1, # Only relevant for TCP/IP
        'schema_spec' => 'people#0|60|id#0:int',
    );

Creates a new client and automatically loads the schema.

You may specify:

=over 4

=item * C<schema> — already-parsed schema hashref

    my $melian = Melian->new(
        'schema' => {
            'id'      => 1,
            'name'    => 'cats',
            'period'  => 45,
            'indexes' => [
                { 'id' => 0, 'column' => "id",   'type' => 'int'    },
                { 'id' => 1, 'column' => "name", 'type' => 'string' },
            ],
        }
        ...
    );

You would normally either provide a spec, a file, or nothing (to let
Melian fetch it from the server).

=item * C<schema_spec> — inline schema description

    my $melian = Melian->new(
        'schema_spec' => 'cats#0|45|id#0:int;name#1:string',
        ...
    );

=item * C<schema_file> — path to JSON schema file

    my $melian = Melian->new(
        'schema_file' => '/etc/melian/schema.json',
        ...
    );

=item * nothing — Melian will ask the server for the schema

    my $melian = Melian->new(...);

=back

=head2 C<connect()>

    $melian->connect();

Opens the underlying socket. Called automatically by C<new()>.

=head2 C<disconnect()>

    $melian->disconnect();

Closes the socket. Called automatically when instance goes out
of scope, so you don't need to think about this.

=head2 C<fetch_raw($table_id, $column_id, $key_bytes)>

    my $encoded_data = $melian->fetch_raw( 0, 0, pack 'V', 20 );
    my $encoded_data = $melian->fetch_raw( 0, 1, 'Pixel' );

Fetches a raw JSON string. Does NOT decode it. Assumes input is encoded
correctly.

You probably don't want to use this. See C<fetch_by_int()>,
C<fetch_by_int_from()>, C<fetch_by_string()>, and
C<fetch_by_string_from()> instead.

=head2 C<fetch_raw_from($table_name, $column_name, $key_bytes)>

    my $encoded_data = $melian->fetch_raw_from( 'cats', 'id', pack 'V', 20 );
    my $encoded_data = $melian->fetch_raw_from( 'cats', 'name', 'Pixel' );

Same as above, but uses names instead of IDs.

You probably don't want to use this. See C<fetch_by_int()>,
C<fetch_by_int_from()>, C<fetch_by_string()>, and
C<fetch_by_string_from()> instead.

=head2 C<fetch_by_string($table_id, $column_id, $string_key)>

    my $hashref = $melian->fetch_by_string( 0, 1, 'Pixel' );

Fetches JSON from the server and decodes into a Perl hashref.

=head2 C<fetch_by_string_from($table_name, $column_name, $string_key)>

    my $hashref = $melian->fetch_by_string( 'cats', 'name', 'Pixel' );

Name-based version. Slightly slower than using IDs.

=head2 C<fetch_by_int($table_id, $column_id, $int)>

    my $hashref = $melian->fetch_by_int( 0, 0, 5 );

Same as C<fetch_by_string>, but for integer-based column searches.

=head2 C<fetch_by_int_from($table_name, $column_name, $int)>

    my $hashref = $melian->fetch_by_int_from( 'cats', 'id', 5 );

Name-based version. Slightly slower than using IDs.

=head1 FUNCTIONS

These functions form the high-speed functional interface. They require a
socket returned by C<create_connection()>.

=head2 C<create_connection(%args)>

    my $conn = Melian->create_connection(%same_args_as_new);

Returns a raw socket connected to the server. Same options as C<new()>, but
no object is created.

=head2 C<fetch_raw_with($conn, $table_id, $column_id, $key_bytes)>

    my $encoded_data = fetch_raw_with( $conn, 0, 0, pack 'V', 20 );
    my $encoded_data = fetch_raw_with( $conn, 0, 1, 'Pixel' );

Similar to C<fetch_raw()> but uses the connection object you get back from
C<create_connection()>.

You probably don't want to use this. See C<fetch_by_int_with()> and
C<fetch_by_string_with()> instead.

=head2 C<fetch_by_string_with($conn, $table_id, $column_id, $string_key)>

    my $hashref = fetch_by_string_with( $conn, 0, 1, 'Pixel' );

Behaves like the corresponding OO method but skips object overhead and
schema lookup.

=head2 C<fetch_by_int_with($conn, $table_id, $column_id, $int)>

    my $hashref = fetch_by_int_with( $conn, 0, 0, 5 );

Behaves like the corresponding OO method but skips object overhead and
schema lookup.

=head2 C<table_of($schema, $table_name)>

    my $table_data = table_of( $schema, 'cats' );
    my $table_id   = $table_data->{'id'};

Fetches the table information from the schema.

=head2 C<column_id_of($table_data, $column_name)>

    my $table_data = table_of( $schema, 'cats' );
    my $column_id  = column_id_of( $table_data, 'name' );

Fetches the ID of a column from a given table metadata.

=head2 C<load_schema_from_describe($conn)>

    my $schema = load_schema_from_describe($conn);

This helps you retrieve the schema if you're using the functional
interface. You can then use this schema to determine table and column
IDs.

=head1 PERFORMANCE NOTES

=over 4

=item *

OO mode is convenient but has overhead from name lookups and method calls.

=item *

ID-based OO mode is faster because it skips name lookups.

=item *

Functional mode is the fastest and is roughly equivalent to calling C<syswrite>
and C<sysread> directly in Perl.

=item *

If you care about performance, use table and column IDs with the functional interface.

=back

=head1 AUTHORS

=over 4

=item *

Sawyer X

=item *

Gonzalo Diethelm

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Sawyer X, Gonzalo Diethelm.

This is free software, licensed under:

  The MIT (X11) License

=cut
