use strict;
package DigitalOcean::Domain;
use Mouse;
use DigitalOcean::Domain::Record;

#ABSTRACT: Represents a Domain object in the DigitalOcean API

has DigitalOcean => (
    is => 'rw',
    isa => 'DigitalOcean',
);


has name => ( 
    is => 'ro',
    isa => 'Str',
);


has ttl => ( 
    is => 'ro',
    isa => 'Num|Undef',
);


has zone_file => ( 
    is => 'ro',
    isa => 'Str|Undef',
);


has path => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD { 
    my ($self) = @_;
    
    $self->path('domains/' . $self->name . '/records'); 
}


sub records {
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self->DigitalOcean], ['Domain', $self]];
    return $self->DigitalOcean->_get_collection($self->path, 'DigitalOcean::Domain::Record', 'domain_records', {per_page => $per_page}, $init_arr);
}



sub create_record {
    my $self = shift;
    my %args = @_;

    my $record = $self->DigitalOcean->_create($self->path, 'DigitalOcean::Domain::Record', 'domain_record', \%args);
    $self->_prepare_record($record);

    return $record;
}


sub record {
    my ($self, $id) = @_;

    my $record = $self->DigitalOcean->_get_object($self->path . "/$id", 'DigitalOcean::Domain::Record', 'domain_record');
    $self->_prepare_record($record);

    return $record;
}

sub _prepare_record { 
    my ($self, $record) = @_;
    $record->DigitalOcean($self->DigitalOcean);
    $record->Domain($self);
}


sub delete { 
    my ($self) = @_;
    return $self->DigitalOcean->_delete(path => 'domains/' . $self->name);
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Domain - Represents a Domain object in the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 name

The name of the domain itself. This should follow the standard domain format of domain.TLD. For instance, example.com is a valid domain name.

=head2 ttl

This value is the time to live for the records on this domain, in seconds. This defines the time frame that clients can cache queried information before a refresh should be requested.

=head2 zone_file

This attribute contains the complete contents of the zone file for the selected domain. Individual domain record resources should be used to get more granular control over records. However, this attribute can also be used to get information about the SOA record, which is created automatically and is not accessible as an individual record resource.

=head2 path

Returns the api path for this domain

=head2 records

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Domain::Record> objects of the records collection that is associated with this domain. 

    my $records_collection = $domain->records;
    my $obj;

    while($obj = $records_collection->next) { 
        print $obj->id . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page/DigitalOcean::/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $records_collection = $domain->records(2);
    my $obj;

    while($obj = $records_collection->next) { 
        print $obj->id . "\n";
    }

=head2 create_record

This will create a new record associated with this domain. Returns a L<DigitalOcean::Domain::Record> object.

=over 4

=item

B<type> Required (All Records), String, The record type (A, MX, CNAME, etc).

=item

B<name> Required (A, AAAA, CNAME, TXT, SRV), String, The host name, alias, or service being defined by the record.

=item

B<data> Required (A, AAAA, CNAME, MX, TXT, SRV, NS), String, Variable data depending on record type. See the [Domain Records]() section for more detail on each record type.

=item

B<priority> Optional, Number, The priority of the host (for SRV and MX records. null otherwise).

=item

B<port> Optional, Number, The port that the service is accessible on (for SRV records only. null otherwise).

=item

B<weight> Optional, Number, The weight of records with the same priority (for SRV records only. null otherwise).

=back

    my $record = $domain->create_record(
        type => 'A',
        name => 'test',
        data => '196.87.89.45',
    );

=head2 record

This will retrieve a record by id and return a L<DigitalOcean::Domain::Record> object.

    my $record = $domain->record(56789);

=head2 delete

This deletes the domain from your account. This will return 1 on success and undef on failure.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
