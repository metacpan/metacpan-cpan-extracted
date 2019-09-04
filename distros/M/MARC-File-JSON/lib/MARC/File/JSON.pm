package MARC::File::JSON;

# ABSTRACT: read/write MARC data into JSON format

use strict;
use warnings;
use 5.010;
use JSON qw(to_json from_json encode_json decode_json);
use JSON::Streaming::Reader;
use MARC::Record::Generic;
use MARC::Record;
use MARC::File;

use vars qw( @ISA $VERSION );
$VERSION = '0.004';
push @ISA, 'MARC::File';

# MARC::Record -> JSON
sub encode {
    my ($record, $args) = @_;
    my $json;
    if ( defined $args ) {
        $json = to_json( $record->as_generic, $args );
    } else {
        $json = encode_json( $record->as_generic);
        utf8::upgrade($json);
    }
    return $json;
}

# JSON -> MARC::Record
sub decode {
    my ($self, $data, $args) = @_;

    if ( !ref($data) ) {
        $data = defined $args
            ? from_json( $data, $args )
            : decode_json( $data );
    }
    return MARC::Record->new_from_generic( $data );
}

sub _next {
    my $self = shift;
    my $jsonr
        = $self->{jsonr} //= JSON::Streaming::Reader->for_stream($self->{fh});
    my $token = $jsonr->get_token;
    if ($token->[0] eq 'start_array') {
        $token = $jsonr->get_token;
    }
    return ($token->[0] eq 'end_array') ? undef : $jsonr->slurp;
}

### Methods injected into MARC::Record

sub MARC::Record::new_from_json {
    my ($class, $json, $args) = @_;
    return __PACKAGE__->decode( from_json($json, $args) );
}

sub MARC::Record::as_json {
    my ($self, $args) = @_;
    return encode( $self, $args );
}

1;

__END__
=head1 NAME

MARC::File::JSON - Convert between MARC::Record objects and JSON
formatted data.

=head1 SYNOPSIS

 use MARC::File::JSON;

 my $record = MARC::Record->new_from_json( $json );
 $json = $record->as_json;

=head1 DESCRIPTION

This module provides routines for converting between MARC::Record objects
and serialized JSON data formatted as:

 {
   "leader":"01109cam a2200349 a 4500",
   "fields":[
     "001",
     "   89009461 //r92",
     "005",
     "19991006093052.0",
     "010", {
       "subfields":[
         "a",
         "89009461 //r92"
       ],
       "ind1":" ",
       "ind2":" "
     },
     "020",
     ...
   ]
 }

=head1 INTERFACE

MARC::File::JSON injects two subroutines into the MARC::Record
namespace. Additionally it inherits from MARC::File and includes
encode(), decode, and _next() routines, making it compatible with
MARC::Batch.

=over

=item *

MARC::Record::new_from_json( $json )

A package method of MARC::Record which applies the values contained
in C<$json> to the object which it returns.

=item *

MARC::Record::as_json( $args )

An instance method for a MARC::Record object. Returns the objects
values as a string of JSON data. C<$args> is an optional hashref
to be passed as the second parameter to JSON::to_json().

=item *

encode( MARC::Record $record )

Returns a JSON string representation of $record.

=item *

decode( $class, $json )

Converts $json into an instance of MARC::Record, applying the
transform in MARC::Record::Generic.

=back

=head1 SEE ALSO

MARC::Record::Generic

Format inspired by http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json

=head1 AUTHOR

Clay Fouts <cfouts@khephera.net>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 PTFS/LibLime

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
