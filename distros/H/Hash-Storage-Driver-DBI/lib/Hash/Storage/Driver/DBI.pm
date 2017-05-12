package Hash::Storage::Driver::DBI;

our $VERSION = 0.01;

use v5.10;
use strict;
use warnings;

use Carp qw/croak/;
use Query::Abstract;

use base "Hash::Storage::Driver::Base";

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);
    croak "DBH REQUIRED" unless $self->{dbh};
    croak "TABLE REQUIRED" unless $self->{table};

    return $self;
}

sub init {
    my ($self) = @_;
    $self->{query_abstract} = Query::Abstract->new( driver => [
        'SQL' => [ table => $self->{table} ]
    ] );
}

sub get {
    my ( $self, $id ) = @_;

    my $sth = $self->{dbh}->prepare_cached("SELECT * FROM $self->{table} WHERE $self->{key_column} = ?");
    $sth->execute($id);

    my $row = $sth->fetchrow_hashref();
    $sth->finish();

    my $serialized = $row->{ $self->{data_column} };
    return $self->{serializer}->deserialize($serialized);
}

sub set {
    my ( $self, $id, $fields ) = @_;
    return unless keys %$fields;

    my $data = $self->get($id);
    my $is_create =  $data ? 0 : 1;

    # Prepare serialized data
    $data ||= {};
    @{$data}{ keys %$fields } = values %$fields;

    my $serialized = $self->{serializer}->serialize($data);

    # Prepare index columns
    my @columns;
    foreach my $column (keys %$fields) {
        push @columns, $column if grep { $column eq $_ } @{ $self->{index_columns} || [] };
    }

    my @values = @{$fields}{@columns};

    # Add serialized column
    push @columns, $self->{data_column};
    push @values, $serialized;

    my $sql = '';
    my $bind_values = [@values];

    if ($is_create) {
        my $values_cnt = @columns + 1;
        $sql = "INSERT INTO $self->{table}(" . join(', ', @columns, $self->{key_column} ) . ") VALUES(" . join(', ', ('?')x $values_cnt) . ")";
        push @$bind_values, $id;
    } else {
        my $update_str = join(', ', map { "$_=?" } @columns );
        $sql = "UPDATE $self->{table} SET $update_str WHERE $self->{key_column} = ?";
        push @$bind_values, $id;
    }

    my $sth = $self->{dbh}->prepare_cached($sql);

    $sth->execute(@$bind_values);
    $sth->finish();
}

sub del {
    my ( $self, $id ) = @_;
    my $sql = "DELETE FROM $self->{table} WHERE $self->{key_column}=?";

    my $sth = $self->{dbh}->prepare_cached($sql);
    $sth->execute($id);
    $sth->finish();
}

sub list {
    my ( $self, @query ) = @_;

    my ($sql, $bind_values) = $self->{query_abstract}->convert_query(@query);

    my $sth = $self->{dbh}->prepare_cached($sql);
    $sth->execute(@$bind_values);

    my $rows = $sth->fetchall_arrayref({});
    $sth->finish();


    return [ map { $self->{serializer}->deserialize(
        $_->{ $self->{data_column} }
    ) } @$rows ];
}

sub count {
    my ( $self, $filter ) = @_;
    my ($where_str, $bind_values) = $self->{query_abstract}->convert_filter($filter);

    my $sql = "SELECT COUNT(*) FROM $self->{table} $where_str";

    my $sth = $self->{dbh}->prepare_cached($sql);
    $sth->execute(@$bind_values);

    my $row = $sth->fetchrow_arrayref();
    return $row->[0];
}


1;

=head1 NAME

Hash::Storage::Driver::DBI - DBI driver for Hash::Storage

MODULE IS IN A DEVELOPMENT STAGE. DO NOT USE IT YET.

=head1 SYNOPSIS

    my $st = Hash::Storage->new( driver => [ DBI => {
        dbh           => $dbh,
        serializer    => 'JSON',
        table         => 'users',
        key_column    => 'user_id',
        data_column   => 'serialized',
        index_columns => ['age', 'fname', 'lname', 'gender']
    }]);

    # Store hash by id
    $st->set( 'user1' => { fname => 'Viktor', gender => 'M', age => '28' } );

    # Get hash by id
    my $user_data = $st->get('user1');

    # Delete hash by id
    $st->del('user1');

=head1 DESCRIPTION

Hash::Storage::Driver::DBI is a DBI Driver for Hash::Storage (multipurpose storage for hash). You can consider Hash::Storage object as a collection of hashes.
You can use it for storing users, sessions and a lot more data.

=head1 OPTIONS

=head2 dbh

Database handler

=head2 serializer

Data::Serializer driver name

=head2 table

Table name to save data

=head2 key_column

column for saving object id

=head2 data_column

all data will be serialized in one field.

=head2 index_columns

List of colums to increase searches

=head1 AUTHOR

"koorchik", C<< <"koorchik at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/koorchik/Hash-Storage-Driver-DBI/issues>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 "koorchik".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut