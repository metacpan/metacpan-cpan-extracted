package Melian;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Perl client to the Melian cache
$Melian::VERSION = '0.001';
use v5.34;
use JSON::XS qw<decode_json>;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use Carp qw(croak);
use constant {
    'MELIAN_HEADER_VERSION' => 0x11,
    'ACTION_FETCH'          => ord('F'),
    'ACTION_DESCRIBE'       => ord('D'),
};

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

    if (my $schema = $args{'schema'}) {
        $self->{'schema'} = $schema;
    } elsif (my $spec = $args{'schema_spec'}) {
        $self->{'schema'} = _load_schema_from_spec( $args{'schema_spec'} );
    } elsif (my $path = $args{'schema_file'}) {
        $self->{'schema'} = _load_schema_from_file( $args{'schema_file'} );
    } else {
        $self->{'schema'} = $self->_load_schema_from_describe();
    }

    return $self;
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

sub disconnect {
    my ($self) = @_;
    if ($self->{'socket'}) {
        $self->{'socket'}->close();
        $self->{'socket'} = undef;
        return 1;
    }

    return;
}

sub fetch_raw {
    my ($self, $table_id, $index_id, $key) = @_;
    $self->connect();
    defined $key
        or croak("You must provide a key to fetch");
    return $self->_send(ACTION_FETCH(), $table_id, $index_id, $key);
}

sub fetch_json {
    my ($self, $table_id, $index_id, $key) = @_;
    my $payload = $self->fetch_raw($table_id, $index_id, $key);
    return undef if $payload eq '';

    my $decoded;
    eval {
        $decoded = decode_json($payload);
        1;
    } or do {
        my $error = $@ || 'Zombie error';
        croak("Failed to decode JSON response: $error");
    };

    return $decoded;
}

sub fetch_json_by_id {
    my ($self, $table_id, $index_id, $id) = @_;
    return $self->fetch_json($table_id, $index_id, pack('V', $id));
}

sub _load_schema_from_describe {
    my $self = shift;

    $self->connect();
    my $payload = $self->_send(ACTION_DESCRIBE(), 0, 0, '');
    defined $payload && length $payload
        or croak('Could not get schema data');

    my $decoded = eval { decode_json($payload) };
    croak("Failed to decode schema response: $@") if $@;

    return $decoded;
}


sub _load_schema_from_file {
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

# table1#0|60|id:int,table2#1|45|id:int;hostname:string
sub _load_schema_from_spec {
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
    my ( $self, $action, $table_id, $index_id, $payload ) = @_;
    $payload //= '';
    $self->connect();
    defined $table_id && defined $index_id
        or croak("Invalid table ID or index ID");

    my $header = pack(
        'CCCCN',
        MELIAN_HEADER_VERSION(),
        $action,
        $table_id,
        $index_id,
        length $payload,
    );

    _write_all( $self->{'socket'}, $header . $payload );
    my $len_buf = _read_exactly( $self->{'socket'}, 4 );
    my $len = unpack 'N', $len_buf;
    return '' if $len == 0;
    return _read_exactly( $self->{'socket'}, $len );
}

sub _write_all {
    my ( $socket, $buf ) = @_;
    my $offset = 0;
    my $len = length $buf;
    while ( $offset < $len ) {
        my $written = syswrite( $socket, $buf, $len - $offset, $offset );
        croak "Socket write failed: $!" unless defined $written && $written > 0;
        $offset += $written;
    }
}

sub _read_exactly {
    my ( $socket, $len ) = @_;
    my $buffer = '';

    while ( length($buffer) < $len ) {
        my $read = sysread( $socket, my $chunk, $len - length $buffer );
        croak "Socket read failed: $!" unless defined $read;
        croak "Socket closed unexpectedly" if $read == 0;
        $buffer .= $chunk;
    }

    return $buffer;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Melian - Perl client to the Melian cache

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Melian;

    my $client = Melian->new(
        dsn => 'unix:///tmp/melian.sock',
    );

    my $row = $client->fetch_json_by_id(0, 0, 5);

=head1 DESCRIPTION

C<Melian> provides a Perl client for the Melian cache server. It handles the
binary protocol, schema negotiation, and simple fetch helpers so applications
can retrieve rows by table/index identifiers using either UNIX or TCP sockets.

=head1 METHODS

=head2 new

    my $client = Melian->new(
        'dsn'         => 'tcp://127.0.0.1:8765',
        'schema_spec' => 'table1#0|60|id:int',
        'timeout'     => 1,
    );

An example of a more complicated schema spec:

    table1#0|60|id:int,table2#1|45|id:int;hostname:string

Creates a new client. Require a C<dsn> and optionally accept C<timeout>,
C<schema>, C<schema_spec>, or C<schema_file> to control how the schema is
loaded.

Logic for handling schema:

=over 4

=item * If you provide a C<schema> attribute, it uses it.

=item * If you provide a C<schema_file> attribute, it will parse it.

=item * If you provide a C<schema_spec> attribute, it will parse the spec.

=item * If you provide none, will request the schema from the server.

=back

=head2 connect

    $client->connect();

Explicitly opens the underlying socket if it is not already connected. Usually
called automatically by fetch routines.

=head2 disconnect

    $client->disconnect();

Closes the socket connection.

=head2 fetch_raw

    my $payload = $client->fetch_raw($table_id, $index_id, $key_bytes);

Sends a C<FETCH> action and returns the raw payload as bytes for the specified
table/index pair.

=head2 fetch_json

    my $row = $client->fetch_json($table_id, $index_id, $key_bytes);

Like C<fetch_raw> but decodes the JSON payload into a hashref, or returns
C<undef> if the server responds with an empty payload.

=head2 fetch_json_by_id

    my $row = $client->fetch_json_by_id($table_id, $index_id, $numeric_id);

Helper for integer primary keys; packs the ID into little-endian bytes and
returns the decoded row.

=head2 describe_schema

    my $schema = $client->_load_schema_from_describe();

Sends a C<DESCRIBE> action to the server and returns the parsed schema hashref.
Used internally during construction when no explicit schema is provided.

=head1 AUTHORS

=over 4

=item *

Sawyer X

=item *

Gonzalo Diethelm

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
