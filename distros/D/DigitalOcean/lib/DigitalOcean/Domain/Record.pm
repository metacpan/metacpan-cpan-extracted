use strict;
package DigitalOcean::Domain::Record;
use Mouse;

#ABSTRACT: Represents a Domain object in the DigitalOcean API

has DigitalOcean => (
    is => 'rw',
    isa => 'DigitalOcean',
);

has Domain => (
    is => 'rw',
    isa => 'DigitalOcean::Domain',
);


has id => ( 
    is => 'ro',
    isa => 'Num',
);


has type => ( 
    is => 'ro',
    isa => 'Str|Undef',
);


has name => ( 
    is => 'ro',
    isa => 'Str|Undef',
);


has data => ( 
    is => 'ro',
    isa => 'Str|Undef',
);


has priority => ( 
    is => 'ro',
    isa => 'Num|Undef',
);


has port => ( 
    is => 'ro',
    isa => 'Num|Undef',
);


has weight => ( 
    is => 'ro',
    isa => 'Num|Undef',
);


sub path {
    my ($self) = @_;
    return $self->Domain->path . '/' . $self->id;
}


sub update { 
    my $self = shift;
    my (%args) = @_;

    return $self->DigitalOcean->_put_object($self->path, 'DigitalOcean::Domain::Record', 'domain_record', \%args);
}


sub delete { 
    my ($self) = @_;
    return $self->DigitalOcean->_delete(path => $self->path);
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Domain::Record - Represents a Domain object in the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

A unique identifier for each domain record.

=head2 type

The type of the DNS record (ex: A, CNAME, TXT, ...).

=head2 name

The name to use for the DNS record.

=head2 data

The value to use for the DNS record.

=head2 priority

The priority for SRV and MX records.

=head2 port

The port for SRV records.

=head2 weight

The weight for SRV records.

=head2 path

Returns the api path for this record.

=head2 update

This method edits an existing domain record. 

=over 4

=item

B<type> String, The record type (A, MX, CNAME, etc).

=item

B<name> String (A, AAAA, CNAME, TXT, SRV), The host name, alias, or service being defined by the record.

=item

B<data> String (A, AAAA, CNAME, MX, TXT, SRV, NS), Variable data depending on record type. 

=item

B<priority> Number (MX, SRV), The priority of the host (for SRV and MX records. null otherwise).

=item

B<port> Number, The port that the service is accessible on (for SRV records only. null otherwise).

=item

B<weight> Number, The weight of records with the same priority (for SRV records only. null otherwise).

=back

    my $updated_record = $record->update(
        record_type => 'A',
        name => 'newname',
        data => '196.87.89.45',
    );

This method returns the updated L<DigitalOcean::Domain::Record>.

=head2 delete

This deletes the record for the associated domain from your account. This will return 1 on success and undef on failure.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
