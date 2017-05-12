package KinoSearch1::Index::SegWriter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        invindex   => undef,
        seg_name   => undef,
        finfos     => undef,
        field_sims => undef,
        # members
        norm_outstreams => undef,
        fields_writer   => undef,
        postings_writer => undef,
        doc_count       => 0,
    );
    __PACKAGE__->ready_get(qw( seg_name doc_count ));
}

use KinoSearch1::Analysis::TokenBatch;
use KinoSearch1::Index::FieldsWriter;
use KinoSearch1::Index::PostingsWriter;
use KinoSearch1::Index::CompoundFileWriter;
use KinoSearch1::Index::IndexFileNames
    qw( @COMPOUND_EXTENSIONS SORTFILE_EXTENSION );

sub init_instance {
    my $self = shift;
    my ( $invindex, $seg_name, $finfos )
        = @{$self}{ 'invindex', 'seg_name', 'finfos' };

    # init norms
    my $norm_outstreams = $self->{norm_outstreams} = [];
    my @indexed_field_nums = map { $_->get_field_num }
        grep { $_->get_indexed } $finfos->get_infos;
    for my $field_num (@indexed_field_nums) {
        my $filename = "$seg_name.f$field_num";
        $invindex->delete_file($filename)
            if $invindex->file_exists($filename);
        $norm_outstreams->[$field_num] = $invindex->open_outstream($filename);
    }

    # init FieldsWriter
    $self->{fields_writer} = KinoSearch1::Index::FieldsWriter->new(
        invindex => $invindex,
        seg_name => $seg_name,
    );

    # init PostingsWriter
    $self->{postings_writer} = KinoSearch1::Index::PostingsWriter->new(
        invindex => $invindex,
        seg_name => $seg_name,
    );
}

# Add a document to the segment.
sub add_doc {
    my ( $self, $doc ) = @_;
    my $norm_outstreams = $self->{norm_outstreams};
    my $postings_cache  = $self->{postings_cache};
    my $field_sims      = $self->{field_sims};
    my $doc_boost       = $doc->get_boost;

    for my $indexed_field ( grep { $_->get_indexed } $doc->get_fields ) {
        my $field_name  = $indexed_field->get_name;
        my $token_batch = KinoSearch1::Analysis::TokenBatch->new;

        # if the field has content, put it in the TokenBatch
        if ( $indexed_field->get_value_len ) {
            $token_batch->append( $indexed_field->get_value, 0,
                $indexed_field->get_value_len );
        }

        # analyze the field
        if ( $indexed_field->get_analyzed ) {
            $token_batch
                = $indexed_field->get_analyzer()->analyze($token_batch);
        }

        # invert the doc
        $token_batch->build_posting_list( $self->{doc_count},
            $indexed_field->get_field_num );

        # prepare to store the term vector, if the field is vectorized
        if ( $indexed_field->get_vectorized and $indexed_field->get_stored ) {
            $indexed_field->set_tv_string( $token_batch->get_tv_string );
        }

        # encode a norm into a byte, write it to an outstream
        my $norm_val
            = $doc_boost 
            * $indexed_field->get_boost
            * $field_sims->{$field_name}
            ->lengthnorm( $token_batch->get_size );
        my $outstream = $norm_outstreams->[ $indexed_field->get_field_num ];
        $outstream->lu_write( 'a',
            $field_sims->{$field_name}->encode_norm($norm_val) );

        # feed PostingsWriter
        $self->{postings_writer}->add_postings( $token_batch->get_postings );
    }

    # store fields
    $self->{fields_writer}->add_doc($doc);

    $self->{doc_count}++;
}

sub add_segment {
    my ( $self, $seg_reader ) = @_;

    # prepare to bulk add
    my $deldocs = $seg_reader->get_deldocs;
    my $doc_map = $deldocs->generate_doc_map( $seg_reader->max_doc,
        $self->{doc_count} );
    my $field_num_map
        = $self->{finfos}->generate_field_num_map( $seg_reader->get_finfos );

    # bulk add the slab of documents to the various writers
    $self->_merge_norms( $seg_reader, $doc_map );
    $self->{fields_writer}
        ->add_segment( $seg_reader, $doc_map, $field_num_map );
    $self->{postings_writer}->add_segment( $seg_reader, $doc_map );

    $self->{doc_count} += $seg_reader->num_docs;
}

# Bulk write norms.
sub _merge_norms {
    my ( $self, $seg_reader, $doc_map ) = @_;
    my $norm_outstreams = $self->{norm_outstreams};
    my $field_sims      = $self->{field_sims};
    my @indexed_fields  = grep { $_->get_indexed } $self->{finfos}->get_infos;

    for my $field (@indexed_fields) {
        my $field_name   = $field->get_name;
        my $outstream    = $norm_outstreams->[ $field->get_field_num ];
        my $norms_reader = $seg_reader->norms_reader($field_name);
        # if the field was indexed before, copy the norms
        if ( defined $norms_reader ) {
            _write_remapped_norms( $outstream, $doc_map,
                $norms_reader->get_bytes );
        }
        else {
            # the field isn't in the input segment, so write a default
            my $zeronorm = $field_sims->{$field_name}->lengthnorm(0);
            my $num_docs = $seg_reader->num_docs;
            my $normstring
                = $field_sims->{$field_name}->encode_norm($zeronorm)
                x $num_docs;
            $outstream->lu_write( "a$num_docs", $normstring );
        }
    }
}

# Finish writing the segment.
sub finish {
    my $self = shift;
    my ( $invindex, $seg_name ) = @{$self}{ 'invindex', 'seg_name' };

    # write Term Dictionary, positions.
    $self->{postings_writer}->write_postings;

    # write FieldInfos
    my $fnm_file = "$seg_name.fnm";
    $invindex->delete_file($fnm_file) if $invindex->file_exists($fnm_file);
    my $finfos_outstream = $invindex->open_outstream("$seg_name.fnm");
    $self->{finfos}->write_infos($finfos_outstream);
    $finfos_outstream->close;

    # close down all the writers, so we can open the files they've finished.
    $self->{postings_writer}->finish;
    $self->{fields_writer}->finish;
    for ( @{ $self->{norm_outstreams} } ) {
        $_->close if defined;
    }

    # consolidate compound file - if we actually added any docs
    my @compound_files = map {"$seg_name.$_"} @COMPOUND_EXTENSIONS;
    if ( $self->{doc_count} ) {
        my $compound_file_writer
            = KinoSearch1::Index::CompoundFileWriter->new(
            invindex => $invindex,
            filename => "$seg_name.tmp",
            );
        push @compound_files, map { "$seg_name.f" . $_->get_field_num }
            grep { $_->get_indexed } $self->{finfos}->get_infos;
        $compound_file_writer->add_file($_) for @compound_files;
        $compound_file_writer->finish;
        $invindex->rename_file( "$seg_name.tmp", "$seg_name.cfs" );
    }

    # delete files that are no longer needed;
    $invindex->delete_file($_) for @compound_files;
    my $sort_file_name = "$seg_name" . SORTFILE_EXTENSION;
    $invindex->delete_file($sort_file_name)
        if $invindex->file_exists($sort_file_name);
}

1;

__END__

__XS__

MODULE = KinoSearch1   PACKAGE = KinoSearch1::Index::SegWriter

void
_write_remapped_norms(outstream, doc_map_ref, norms_ref)
    OutStream *outstream;
    SV        *doc_map_ref;
    SV        *norms_ref;
PPCODE: 
    Kino1_SegWriter_write_remapped_norms(outstream, doc_map_ref, norms_ref);

__H__

#ifndef H_KINOSEARCH_SEG_WRITER
#define H_KINOSEARCH_SEG_WRITER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1StoreOutStream.h"
#include "KinoSearch1UtilCarp.h"

void Kino1_SegWriter_write_remapped_norms(OutStream*, SV*, SV*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexSegWriter.h"

void 
Kino1_SegWriter_write_remapped_norms(OutStream *outstream, SV *doc_map_ref,
                                    SV* norms_ref) {
    SV     *norms_sv, *doc_map_sv;
    I32    *doc_map, *doc_map_end;
    char   *norms;
    STRLEN  doc_map_len, norms_len;
    
    /* extract doc map and norms arrays */
    doc_map_sv  = SvRV(doc_map_ref);
    doc_map     = (I32*)SvPV(doc_map_sv, doc_map_len);
    doc_map_end = (I32*)SvEND(doc_map_sv);
    norms_sv    = SvRV(norms_ref);
    norms       = SvPV(norms_sv, norms_len);
    if (doc_map_len != norms_len * sizeof(I32))
        Kino1_confess("Mismatched doc_map and norms");

    /* write a norm for each non-deleted doc */
    while (doc_map < doc_map_end) {
        if (*doc_map != -1) {
            outstream->write_byte(outstream, *norms);
        }
        doc_map++;
        norms++;
    }
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::SegWriter - write one segment of an invindex

==head1 DESCRIPTION

SegWriter is a conduit through which information fed to InvIndexer passes on
its way to low-level writers such as FieldsWriter and TermInfosWriter.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
