package HTTP::ClickHouse;

use 5.010000;
use strict;
use warnings FATAL => 'all';
use Carp;

=head1 NAME

HTTP::ClickHouse - Perl driver for ClickHouse

=cut

use Data::Dumper;
use Net::HTTP::NB;
use IO::Select;
use Storable qw(nfreeze thaw);
use URI;
use URI::QueryParam;

our @ISA = qw(HTTP::ClickHouse::Base);
use HTTP::ClickHouse::Base;

use constant READ_BUFFER_LENGTH => 4096;

=head1 VERSION

Version 0.061

=cut

our $VERSION = '0.061';
our $AUTOLOAD;

=head1 SYNOPSIS

HTTP::ClickHouse - Perl interface to ClickHouse Database via HTTP.

=head1 EXAMPLE

    use HTTP::ClickHouse;
 
    my $chdb =  HTTP::ClickHouse->new(
        host     => '127.0.0.1', 
        user     => 'Harry',
        password => 'Alohomora',
    );

    $chdb->do("create table test (id UInt8, f1 String, f2 String) engine = Memory");

    $chdb->do("INSERT INTO my_table (id, field_1, field_2) VALUES", 
        [1, "Gryffindor", "a546825467 1861834657416875469"],
        [2, "Hufflepuff", "a18202568975170758 46717657846"],
        [3, "Ravenclaw", "a678 2527258545746575410210547"],
        [4, "Slytherin", "a1068267496717456 878134788953"]
    );

    my $rows = $chdb->selectall_array("SELECT count(*) FROM my_table");  
    unless (@$rows) { $rows->[0]->[0] = 0; } # the query returns an empty string instead of 0
    print $rows->[0]->[0]."\n"; 


    if ($chdb->select_array("SELECT id, field_1, field_2 FROM my_table")) {
        my $rows = $chdb->fetch_array();
        foreach my $row (@$rows) {
            # Do something with your row
            foreach my $col (@$row) {
                # Do something
                print $col."\t";
            }
            print "\n";
        }
    }

    $rows = $chdb->selectall_hash("SELECT count(*) as count FROM my_table");
    foreach my $row (@$rows) {
        foreach my $key (keys %{$row}){
            # Do something
            print $key." = ".$row->{$key}."\t";
        }
        print "\n";
    }
 
    ...

    disconnect $chdb;

=head1 DESCRIPTION

This module implements HTTP driver for Clickhouse OLAP database 

=head1 SUBROUTINES/METHODS

=head2 new

Create a new connection object with auto reconnect socket if disconnected.

    my $chdb =  HTTP::ClickHouse->new(
        host     => '127.0.0.1', 
        user     => 'Harry',
        password => 'Alohomora'
    );

options:

    host       => 'hogwards.mag',              # optional, default value '127.0.0.1'
    port       => 8123,                        # optional, default value 8123
    user       => 'Harry',                     # optional, default value 'default'
    password   => 'Alohomora',                 # optional
    database   => 'database_name',             # optional, default name "default"         
    nb_timeout => 10                           # optional, default value 25 second
    keep_alive => 1                            # optional, default 1 (1 or 0)
    debug      => 1                            # optional, default 0

=cut

sub new {
    my $class = shift;
    my $self = { @_ };
    $self = bless $self, $class;
    $self->_init();
    $self->_connect();
    return $self;
}

sub _connect {
    my $self = shift;

    my $_uri = URI->new("/");
    $_uri->query_param('user' => $self->{user}) if $self->{user};
    $_uri->query_param('password' => $self->{password}) if $self->{password};
    $_uri->query_param('database' => $self->{database});
    $self->{_uri} = nfreeze($_uri);

    $self->{socket} = Net::HTTP::NB->new(
        Host        => $self->{host},
        PeerPort    => $self->{port},
        HTTPVersion => '1.1',
        KeepAlive   => $self->{keep_alive}
    ) or carp "Error. Can't connect to ClickHouse host: $!";
}

sub uri {
    my $self = shift;
    return thaw($self->{_uri});
}

sub _status {
    my $self = shift;
    my $select = IO::Select->new($self->{socket});
    my ($code, $mess, %h);

    my $_status = eval {
        READHEADER: {
            die "Get header timeout" unless $select->can_read($self->{nb_timeout});
            ($code, $mess, %h) = $self->{socket}->read_response_headers;
            redo READHEADER unless $code;
        }
    };

    $_status = $code if ($code);
    if ($@) {
        carp($@) if $self->{debug};
        $_status = 500; 
    }
    return $_status;
}

sub _read {
    my $self = shift;
    my $remainder = '';
    my @_response;
    READBODY: {
        my $_bufer;
        my $l = $self->{socket}->read_entity_body($_bufer, READ_BUFFER_LENGTH);
        $_bufer = $remainder . $_bufer;
        $remainder = '';
        last unless $l;
        if ($_bufer =~ s!([^\n]+\z)!!) {
            $remainder = $1;
        }
        push @_response, split (/\n/, $_bufer);
        redo READBODY;
    }
    return $self->body2array(@_response);
}

sub _query {
    my $self = shift;
    my $method = shift;
    my $query = shift;
    my $data = shift;

    delete $self->{response};

    my $t = $self->_ping();
    if ($t == 0) { $self->_connect(); carp('Reconnect socket') if $self->{debug}; }

    my $uri = $self->uri();
    $uri->query_param('query' => $query);

    my @qparam;
    push @qparam, $method => $uri->as_string();
    push @qparam, $data if ($method eq 'POST');

    $self->{socket}->write_request(@qparam);

    my $_status = $self->_status();
    my $body = $self->_read();  # By default, data is returned in TabSeparated format.
    $self->{response} = $body;

    if ($_status ne '200') {
        carp(join(" ".$body)) if $self->{debug};
        carp(Dumper($body)) if $self->{debug};
        return 0;
    }
    return 1;
}

=head2 select_array & fetch_array

First step - select data from the table (readonly). It returns 1 if query completed without errors or 0.
Don't set FORMAT in query. TabSeparated is used by default in the HTTP interface.

Second step - fetch data.
It returns a reference to an array containing a reference to an array for each row of data fetched.

    if ($chdb->select_array("SELECT id, field_1, field_2 FROM my_table")) {
        my $rows = $chdb->fetch_array();
        foreach my $row (@$rows) {
            # Do something with your row
            foreach my $col (@$row) {
                # Do something
                print $col."\t";
            }
            print "\n";
        }
    }

=cut

sub select_array {
    my $self = shift;
    my $query = shift;
    $query .= ' FORMAT TabSeparated';
    return $self->_query('GET', $query); # When using the GET method, 'readonly' is set.
}

sub fetch_array {
    my $self = shift;
    my $_responce = $self->{response};
#    unless (@$_responce) { $_responce->[0]->[0] = 0; } # the query returns an empty string instead of 0
    return $_responce;
}

=head2 selectall_array

Fetch data from the table (readonly). 
It returns a reference to an array containing a reference to an array for each row of data fetched.

    my $rows = $chdb->selectall_array("SELECT count(*) FROM my_table");  
    unless (@$rows) { $rows->[0]->[0] = 0; } # the query returns an empty string instead of 0
    print $rows->[0]->[0]."\n"; 

=cut

sub selectall_array {
    my $self = shift;
    my $query = shift;
    $self->select_array($query);
    return $self->fetch_array;
}

=head2 select_hash & fetch_hash

First step - select data from the table (readonly). It returns 1 if query completed without errors or 0.
Don't set FORMAT in query.

Second step - fetch data.
It returns a reference to an array containing a reference to an array for each row of data fetched.

    if ($chdb->select_hash("SELECT id, field_1, field_2 FROM my_table")) {
        my $rows = $chdb->fetch_hash();
        foreach my $row (@$rows) {
            # Do something with your row
            foreach my $key (sort(keys %{$row})){
                # Do something
                print $key." = ".$row->{$key}."\t";
            }
            print "\n";
        }
    }

=cut

sub select_hash {
    my $self = shift;
    my $query = shift;
    $query .= ' FORMAT TabSeparatedWithNames';
    return $self->_query('GET', $query); # When using the GET method, 'readonly' is set.
}

sub fetch_hash {
    my $self = shift;
    return $self->array2hash(@{$self->{response}});
}

=head2 selectall_hash

Fetch data from the table (readonly). 
It returns a reference to an array containing a reference to an hash for each row of data fetched.

    my $rows = $chdb->selectall_hash("SELECT id, field_1, field_2 FROM my_table");
    foreach my $row (@$rows) {
        # Do something with your row
        foreach my $key (sort(keys %{$row})){
            # Do something
            print $key." = ".$row->{$key}."\t";
        }
        print "\n";
    }

=cut

sub selectall_hash {
    my $self = shift;
    my $query = shift;
    $self->select_hash($query);
    return $self->fetch_hash;
}

=head2 do

Universal method for any queries inside the database, which modify data (insert data, create, alter, detach or drop table or partition).
It returns 1 if query completed without errors or 0.

    # drop
    $chdb->do("drop table test if exist");

    # create
    $chdb->do("create table test (id UInt8, f1 String, f2 String) engine = Memory");

    # insert
    $chdb->do("INSERT INTO my_table (id, field_1, field_2) VALUES", 
        [1, "Gryffindor", "a546825467 1861834657416875469"],
        [2, "Hufflepuff", "a18202568975170758 46717657846"],
        [3, "Ravenclaw", "a678 2527258545746575410210547"],
        [4, "Slytherin", "a1068267496717456 878134788953"]
    );

=cut

sub do {
    my $self = shift;
    my $query = shift;
    my $data = $self->data_prepare(@_);
    return $self->_query('POST', $query, $data);
}

sub _ping {
    my $self = shift;
    $self->{socket}->write_request(GET => '/ping');
    my $_status = $self->_status();   
    if ($_status == 200) {
        my $body = $self->_read();
        if ($body->[0]->[0] eq 'Ok.') {
            return 1;
        }
    }
    return 0;
}

=head2 disconnect

Disconnects http socket from the socket handle. Disconnect typically occures only used before exiting the program. 

    disconnect $chdb;

    # or

    $chdb->disconnect;

=cut

sub disconnect {
    my $self = shift;
    $self->{socket}->keep_alive(0) if ($self->{socket});
    $self->_ping();
}


=head1 SEE ALSO

=over 4

=item * ClickHouse official documentation

L<https://clickhouse.yandex/reference_en.html>

=back

=head1 AUTHOR

Maxim Motylkov

=head1 TODO

The closest plans are

=over 4

=item * Add json data format.

=back

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

   Copyright 2016 Maxim Motylkov

   This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION,
   THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

sub HTTP::ClickHouse::AUTOLOAD {
    croak "No such method: $AUTOLOAD";
}

sub DESTROY {
}

1;
