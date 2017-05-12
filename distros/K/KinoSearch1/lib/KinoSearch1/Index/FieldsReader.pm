package KinoSearch1::Index::FieldsReader;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class Exporter );

use constant ANALYZED   => "\x01";
use constant BINARY     => "\x02";
use constant COMPRESSED => "\x04";

our @EXPORT_OK;

BEGIN {
    @EXPORT_OK = qw( ANALYZED BINARY COMPRESSED );
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        finfos        => undef,
        fdata_stream  => undef,
        findex_stream => undef,
        # members
        size => undef,
    );

}

use Compress::Zlib qw( uncompress );
use KinoSearch1::Document::Field;
use KinoSearch1::Document::Doc;

sub init_instance {
    my $self = shift;

    # derive the number of documents in the segment
    $self->{size} = $self->{findex_stream}->length / 8;
}

# Return number of documents in segment.
sub get_size { $_[0]->{size} }

# Retrieve raw field data from files.  Either the data will be turned into
# full-on Field and Doc objects by fetch_doc, or it will be passed on mostly
# intact when merging segments (field numbers will be modified).
sub fetch_raw {
    my ( $self, $doc_num ) = @_;
    my ( $findex_stream, $fdata_stream )
        = @{$self}{ 'findex_stream', 'fdata_stream' };

    # get data file pointer from index
    $findex_stream->seek( $doc_num * 8 );
    my $start = $findex_stream->lu_read('Q');

    # retrieve one doc's worth of field data
    $fdata_stream->seek($start);
    my $num_fields = $fdata_stream->lu_read('V');
    my $template   = 'VaTT' x $num_fields;
    my @raw        = $fdata_stream->lu_read($template);
    return ( $num_fields, \@raw );
}

# Given a doc_num, rebuild a Doc object from the fields that were
# stored.
sub fetch_doc {
    my ( $self, $doc_num ) = @_;
    my $finfos = $self->{finfos};

    # start a new Doc object, read in data
    my $doc = KinoSearch1::Document::Doc->new;
    my ( $num_fields, $data ) = $self->fetch_raw($doc_num);

    # docode stored data and build up the Doc object Field by Field.
    for ( 1 .. $num_fields ) {
        my ( $field_num, $bits, $string, $tv_string )
            = splice( @$data, 0, 4 );

        # decode fnm bits
        my $analyzed   = ( $bits & ANALYZED )   eq ANALYZED   ? 1 : 0;
        my $binary     = ( $bits & BINARY )     eq BINARY     ? 1 : 0;
        my $compressed = ( $bits & COMPRESSED ) eq COMPRESSED ? 1 : 0;

        # create a field object, merging in the FieldInfo data, and add it
        my $finfo = $finfos->info_by_num($field_num);
        my $field = KinoSearch1::Document::Field->new(
            %$finfo,
            field_num  => $field_num,
            analyzed   => $analyzed,
            binary     => $binary,
            compressed => $compressed,
            fdt_bits   => $bits,
            value      => $compressed ? uncompress($string) : $string,
            tv_string  => $tv_string,
        );
        $doc->add_field($field);
    }

    return $doc;
}

sub decode_fdt_bits {
    my ( undef, $field, $bits ) = @_;
    $field->set_analyzed(   ( $bits & ANALYZED )   eq ANALYZED );
    $field->set_binary(     ( $bits & BINARY )     eq BINARY );
    $field->set_compressed( ( $bits & COMPRESSED ) eq COMPRESSED );
}

sub encode_fdt_bits {
    my ( undef, $field ) = @_;
    my $bits = "\0";
    for ($bits) {
        $_ |= ANALYZED   if $field->get_analyzed;
        $_ |= BINARY     if $field->get_binary;
        $_ |= COMPRESSED if $field->get_compressed;
    }
    return $bits;
}

sub close {
    my $self = shift;
    $self->{findex_stream}->close;
    $self->{fdata_stream}->close;
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::FieldsReader - retrieve stored documents

==head1 DESCRIPTION

FieldsReader's purpose is to retrieve stored documents from the invindex.  In
addition to returning fully decoded Doc objects, it can pass on raw data --
for instance, compressed fields stay compressed -- for the purpose of
merging segments efficiently.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
