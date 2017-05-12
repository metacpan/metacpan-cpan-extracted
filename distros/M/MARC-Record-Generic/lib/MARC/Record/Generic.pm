package MARC::Record::Generic;

# ABSTRACT: read/write MARC data into Perl primitives

use strict;
use warnings;
use MARC::Record;
use MARC::Field;

our $VERSION = 0.001;

# MARC::Record -> generic hash
sub MARC::Record::as_generic {
    my $self = shift;

    return {
        leader => $self->leader,
        fields => [ map {
            $_->tag,
            ( $_->is_control_field
              ? $_->data
              : {
                  ind1 => $_->indicator(1),
                  ind2 => $_->indicator(2),
                  subfields => [ map { ($_->[0], $_->[1]) } $_->subfields ],
                }
            )
        } $self->fields ],
    };
}

# generic hash -> MARC::Record
sub MARC::Record::new_from_generic {
    my ($class, $data) = @_;
    my $record = MARC::Record->new();
    $record->leader( $data->{leader} );

    my @fields;
    @_ = @{$data->{fields}};
    while ( @_ ) {
        my ($tag, $val) = (shift, shift);
        my @attrs
            = ref($val) eq 'HASH'
                ? ( $val->{ind1}, $val->{ind2}, @{$val->{subfields}} )
                : ( $val );
        push @fields, MARC::Field->new( $tag, @attrs );
    }

    $record->append_fields( @fields );
    return $record;
}

1;

__END__
=head1 NAME

MARC::Record::Generic - Convert between MARC::Record objects and
native Perl primitives.

=head1 SYNOPSIS

 use MARC::Record::Generic;

 my $record = MARC::Record->new_from_generic( $marcdata );
 $marcdata = $record->as_generic;

=head1 DESCRIPTION

This module provides routines for converting between MARC::Record objects
and Perl native data in the format of:

 my $marcdata = {
   leader => '01109cam a2200349 a 4500',
   fields => [
     '001',
     '   89009461 //r92',
     '005',
     '19991006093052.0',
     '008',
     '991006s1989    nyuaf   bb    00110aeng  ',
     '010',
     {
       subfields => [
         'a',
         '89009461 //r92'
       ],
       ind1 => ' ',
       ind2 => ' '
     },
     '010',
     ...
   ]
 }

Data in this format can be used for a number of purposes, but the
principle intention is to make MARC data amenable to serializing into
JSON, YAML, etc. Field and subfield order is preserved. Multiple
instances of either are also allowed. No effort is made to ensure that
the MARC contents are sensible or follow a particular standard.

=head1 INTERFACE

MARC::Record::Generic injects two subroutines into the MARC::Record
namespace.

=over

=item *

MARC::Record::as_generic( )

An instance method for a MARC::Record object. Returns the objects
values as Perl primitives.

=item *

MARC::Record::new_from_generic( $marcdata )

A package method of MARC::Record which applies the values contained
in C<$data> to the object which it returns.

=back

=head1 SEE ALSO

Code inspired by Frederic Demians' MARC::Moose::Formater::JSON.

Format inspired by http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json

=head1 AUTHOR

Clay Fouts <cfouts@khephera.net>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 PTFS/LibLime

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
