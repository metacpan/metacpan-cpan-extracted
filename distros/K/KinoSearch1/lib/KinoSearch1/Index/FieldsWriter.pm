package KinoSearch1::Index::FieldsWriter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        invindex => undef,
        seg_name => undef,
        # members
        fdata_stream  => undef,
        findex_stream => undef,
    );
}
use Compress::Zlib qw( compress );

sub init_instance {
    my $self     = shift;
    my $invindex = $self->{invindex};

    # open an index stream and a data stream.
    my $fdx_file = "$self->{seg_name}.fdx";
    my $fdt_file = "$self->{seg_name}.fdt";
    for ( $fdx_file, $fdt_file, ) {
        $invindex->delete_file($_) if $invindex->file_exists($_);
    }
    $self->{findex_stream} = $invindex->open_outstream($fdx_file);
    $self->{fdata_stream}  = $invindex->open_outstream($fdt_file);
}

sub add_doc {
    my ( $self, $doc ) = @_;

    # record the data stream's current file pointer in the index.
    $self->{findex_stream}->lu_write( 'Q', $self->{fdata_stream}->tell );

    # only store fields marked as "stored"
    my @stored = sort { $a->get_field_num <=> $b->get_field_num }
        grep $_->get_stored, $doc->get_fields;

    # add the number of stored fields in the Doc
    my @to_write = ( scalar @stored );

    # add flag bits and value for each stored field
    for (@stored) {
        push @to_write, ( $_->get_field_num, $_->get_fdt_bits );
        push @to_write, $_->get_compressed
            ? compress( $_->get_value )
            : $_->get_value;
        push @to_write, $_->get_tv_string;
    }

    # write out data
    my $lu_template = 'V' . ( 'VaTT' x scalar @stored );
    $self->{fdata_stream}->lu_write( $lu_template, @to_write );
}

sub add_segment {
    my ( $self, $seg_reader, $doc_map, $field_num_map ) = @_;
    my ( $findex_stream, $fdata_stream )
        = @{$self}{qw( findex_stream fdata_stream )};
    my $fields_reader = $seg_reader->get_fields_reader;

    my $max = $seg_reader->max_doc;
    return unless $max;
    $max -= 1;
    for my $orig ( 0 .. $max ) {
        # if the doc isn't deleted, copy it to the new seg
        next unless defined $doc_map->get($orig);

        # write pointer
        $findex_stream->lu_write( 'Q', $fdata_stream->tell );

        # retrieve all fields
        my ( $num_fields, $all_data ) = $fields_reader->fetch_raw($orig);

        # write number of fields
        $fdata_stream->lu_write( 'V', $num_fields );

        # write data for each field
        for ( 1 .. $num_fields ) {
            my ( $field_num, @some_data ) = splice( @$all_data, 0, 4 );
            $fdata_stream->lu_write( 'VaTT', $field_num_map->get($field_num),
                @some_data );
        }
    }
}

sub finish {
    my $self = shift;
    $self->{fdata_stream}->close;
    $self->{findex_stream}->close;
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::FieldsWriter - write stored fields to an invindex

==head1 DESCRIPTION

FieldsWriter writes fields which are marked as stored to the field data and
field index files.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

