package KinoSearch1::Index::PostingsWriter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        #constructor params / members
        invindex => undef,
        seg_name => undef,

        # members
        sort_pool => undef,
    );
}

use KinoSearch1::Index::TermInfo;
use KinoSearch1::Index::TermInfosWriter;
use KinoSearch1::Util::SortExternal;

sub init_instance {
    my $self = shift;

    # create a SortExternal object which autosorts the posting list cache
    $self->{sort_pool} = KinoSearch1::Util::SortExternal->new(
        invindex => $self->{invindex},
        seg_name => $self->{seg_name},
    );
}

# Add all the postings in an inverted document to the sort pool.
sub add_postings {
    my ( $self, $postings_array ) = @_;
    $self->{sort_pool}->feed(@$postings_array);
}

# Bulk add all the postings in a segment to the sort pool.
sub add_segment {
    my ( $self, $seg_reader, $doc_map ) = @_;
    my $term_enum = $seg_reader->terms;
    my $term_docs = $seg_reader->term_docs;
    $term_docs->set_read_positions(1);
    _add_segment( $self->{sort_pool}, $term_enum, $term_docs, $doc_map );
}

=for comment

Process all the postings in the sort pool.  Generate the freqs and positions
files.  Hand off data to TermInfosWriter for the generating the term
dictionaries.

=cut

sub write_postings {
    my $self = shift;
    my ( $invindex, $seg_name ) = @{$self}{ 'invindex', 'seg_name' };

    $self->{sort_pool}->sort_all;

    my $tinfos_writer = KinoSearch1::Index::TermInfosWriter->new(
        invindex => $invindex,
        seg_name => $seg_name,
    );
    my $frq_file = "$seg_name.frq";
    my $prx_file = "$seg_name.prx";
    for ( $frq_file, $prx_file ) {
        $invindex->delete_file($_) if $invindex->file_exists($_);
    }
    my $frq_out = $invindex->open_outstream($frq_file);
    my $prx_out = $invindex->open_outstream($prx_file);

    _write_postings( $self->{sort_pool}, $tinfos_writer, $frq_out, $prx_out );

    $frq_out->close;
    $prx_out->close;
    $tinfos_writer->finish;
}

sub finish {
    my $self = shift;
    $self->{sort_pool}->close;
}

1;

__END__
__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::PostingsWriter      

void
_write_postings (sort_pool, tinfos_writer, frq_out, prx_out)
    SortExternal    *sort_pool;
    TermInfosWriter *tinfos_writer;
    OutStream       *frq_out;
    OutStream       *prx_out;
PPCODE:
    Kino1_PostWriter_write_postings(sort_pool, tinfos_writer, frq_out,
        prx_out);

void
_add_segment(sort_pool, term_enum, term_docs, doc_map_ref)
    SortExternal  *sort_pool;
    SegTermEnum  *term_enum;
    TermDocs *term_docs;
    SV  *doc_map_ref;
PPCODE:
    Kino1_PostWriter_add_segment(sort_pool, term_enum, term_docs, 
        doc_map_ref);

__H__

#ifndef H_KINOSEARCH_INDEX_POSTINGS_WRITER
#define H_KINOSEARCH_INDEX_POSTINGS_WRITER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexSegTermEnum.h"
#include "KinoSearch1IndexTerm.h"
#include "KinoSearch1IndexTermDocs.h"
#include "KinoSearch1IndexTermInfosWriter.h"
#include "KinoSearch1StoreOutStream.h"
#include "KinoSearch1UtilByteBuf.h"
#include "KinoSearch1UtilSortExternal.h"

void Kino1_PostWriter_write_postings(SortExternal*, TermInfosWriter*, 
                                    OutStream*, OutStream*);
void Kino1_PostWriter_add_segment(SortExternal*, SegTermEnum*, TermDocs*, SV*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexPostingsWriter.h"

static void Kino1_PostWriter_deserialize(ByteBuf*, ByteBuf*, ByteBuf*, 
                                        U32*, U32*);
static void Kino1_PostWriter_write_positions(OutStream*, ByteBuf*);

void
Kino1_PostWriter_write_postings(SortExternal *sort_pool,
                               TermInfosWriter *tinfos_writer, 
                               OutStream *frq_out, OutStream *prx_out) {
    ByteBuf   *posting           = NULL;
    ByteBuf   *positions, *termstring, *last_termstring;
    TermInfo  *tinfo;
    U32        doc_num           = 0;
    U32        freq              = 0;
    U32        last_doc_num      = 0;
    U32        last_skip_doc     = 0;
    double     frq_ptr, prx_ptr;
    double     last_skip_frq_ptr = 0.0;
    double     last_skip_prx_ptr = 0.0;
    I32        iter              = 0;
    I32        i;
    AV        *skip_data_av;
    SV        *skip_sv;

    posting         = Kino1_BB_new_string("", 0);
    last_termstring = Kino1_BB_new_string("\0\0", 2);
    termstring      = Kino1_BB_new_view(NULL, 0);
    positions       = Kino1_BB_new_view(NULL, 0);
    tinfo           = Kino1_TInfo_new();
    skip_data_av    = newAV();
    skip_sv         = &PL_sv_undef;

    /* each loop is one field, one term, one doc_num, many positions */
    while (1) {
        /* retrieve the next posting from the sort pool */
        Kino1_BB_destroy(posting);
        posting = sort_pool->fetch(sort_pool);

        /* SortExternal returns NULL when exhausted */
        if (posting == NULL) {
            goto FINAL_ITER;
        }

        /* each iter, add a doc to the doc_freq for a given term */
        iter++;
        tinfo->doc_freq++;    /* lags by 1 iter */

        /* break up the serialized posting into its parts */
        Kino1_PostWriter_deserialize(posting, termstring, positions, 
            &doc_num, &freq);

        /* on the first iter, prime the "heldover" variables */
        if (iter == 1) {
            Kino1_BB_assign_string(last_termstring, termstring->ptr,
                termstring->size);
            tinfo->doc_freq      = 0;
            tinfo->frq_fileptr   = frq_out->tell(frq_out);
            tinfo->prx_fileptr   = prx_out->tell(prx_out);
            tinfo->skip_offset   = frq_out->tell(frq_out);
            tinfo->index_fileptr = 0;
        }
        else if ( iter == -1 ) { /* never true; can only get here via goto */
            /* prepare to clear out buffers and exit loop */
            FINAL_ITER: {
                iter = -1;
                Kino1_BB_destroy(termstring);
                termstring = Kino1_BB_new_string("\0\0", 2);
                tinfo->doc_freq++;
            }
        }

        /* create skipdata (unused by KinoSearch1 at present) */
        if ( (tinfo->doc_freq + 1) % tinfos_writer->skip_interval == 0 ) {
            frq_ptr = frq_out->tell(frq_out);
            prx_ptr = prx_out->tell(prx_out);

            av_push(skip_data_av, newSViv(last_doc_num - last_skip_doc    ));
            av_push(skip_data_av, newSViv(frq_ptr      - last_skip_frq_ptr));
            av_push(skip_data_av, newSViv(prx_ptr      - last_skip_prx_ptr));

            last_skip_doc     = last_doc_num;
            last_skip_frq_ptr = frq_ptr;
            last_skip_prx_ptr = prx_ptr;
        }

        /* if either the term or fieldnum changes, process the last term */
        if ( Kino1_BB_compare(termstring, last_termstring) ) {
            /* take note of where we are for the term dictionary */
            frq_ptr = frq_out->tell(frq_out);
            prx_ptr = prx_out->tell(prx_out);

            /* write skipdata if there is any */
            if (av_len(skip_data_av) != -1) {
                /* kludge to compensate for doc_freq's 1-iter lag */
                if (
                    (tinfo->doc_freq + 1) % tinfos_writer->skip_interval == 0 
                ) {
                    /* remove 1 cycle of skip data */
                    for (i = 3; i > 0; i--) {
                        skip_sv = av_pop(skip_data_av);
                        SvREFCNT_dec(skip_sv);
                    }
                }
                if (av_len(skip_data_av) != -1) {
                    /* tell tinfos_writer about the non-zero skip amount */
                    tinfo->skip_offset = frq_ptr - tinfo->frq_fileptr;

                    /* write out the skip data */
                    i = av_len(skip_data_av);
                    while (i-- > -1) {
                        skip_sv = av_shift(skip_data_av);
                        frq_out->write_vint(frq_out, SvIV(skip_sv) );
                        SvREFCNT_dec(skip_sv);
                    }

                    /* update the filepointer for the file we just wrote to */
                    frq_ptr = frq_out->tell(frq_out);
                }
            }

            /* init skip data in preparation for the next term */
            last_skip_doc     = 0;
            last_skip_frq_ptr = frq_ptr;
            last_skip_prx_ptr = prx_ptr;

            /* hand off to TermInfosWriter */
            Kino1_TInfosWriter_add(tinfos_writer, last_termstring, tinfo);

            /* start each term afresh */
            tinfo->doc_freq      = 0;
            tinfo->frq_fileptr   = frq_ptr;
            tinfo->prx_fileptr   = prx_ptr;
            tinfo->skip_offset   = 0;
            tinfo->index_fileptr = 0;

            /* remember the termstring so we can write string diffs */
            Kino1_BB_assign_string(last_termstring, termstring->ptr,
                termstring->size);

            last_doc_num    = 0;
        }

        /* break out of loop on last iter before writing invalid data */
        if (iter == -1) {
            Kino1_TInfo_destroy(tinfo);
            Kino1_BB_destroy(termstring);
            Kino1_BB_destroy(last_termstring);
            Kino1_BB_destroy(positions);
            Kino1_BB_destroy(posting);
            SvREFCNT_dec( (SV*)skip_data_av );
            return;
        }

        /*  write positions data */
        Kino1_PostWriter_write_positions(prx_out, positions);

        /* write freq data */
        /* doc_code is delta doc_num, shifted left by 1. */
        if (freq == 1) {
            U32 doc_code = (doc_num - last_doc_num) << 1;
            /* set low bit of doc_code to 1 to indicate freq of 1 */
            doc_code += 1;
            frq_out->write_vint(frq_out, doc_code);
        }
        else {
            U32 doc_code = (doc_num - last_doc_num) << 1;
            /* leave low bit of doc_code at 0, record explicit freq */
            frq_out->write_vint(frq_out, doc_code);
            frq_out->write_vint(frq_out, freq);
        }

        /* remember last doc num because we need it for delta encoding */
        last_doc_num = doc_num;
    }
}

/* Pull apart a serialized posting into its component parts */

#define DOC_NUM_LEN 4
#define TEXT_LEN_LEN 2
#define NULL_BYTE_LEN 1 

void
Kino1_PostWriter_add_segment(SortExternal *sort_pool, SegTermEnum* term_enum, 
                            TermDocs *term_docs, SV *doc_map_ref) {
    I32        *doc_map;
    I32         doc_num, max_doc;
    char        doc_num_buf[4];
    char        text_len_buf[4];
    SV         *positions_sv, *doc_map_sv;
    ByteBuf    *posting;
    TermBuffer *term_buf;
    char       *positions_ptr;
    STRLEN      len, common_len, positions_len;

    /* extract the doc number remapping array */
    doc_map_sv = SvRV(doc_map_ref);
    doc_map    = (I32*)SvPV(doc_map_sv, len);
    max_doc    = len / sizeof(I32);

    term_buf   = term_enum->term_buf;
    posting    = Kino1_BB_new_string("", 0);

    while (Kino1_SegTermEnum_next(term_enum)) {
        /* start with the termstring and the null byte */
        Kino1_encode_bigend_U16(term_buf->text_len, text_len_buf);
        common_len = term_buf->text_len + KINO_FIELD_NUM_LEN;
        Kino1_BB_assign_string(posting, term_buf->termstring->ptr, common_len);
        Kino1_BB_cat_string(posting, "\0", NULL_BYTE_LEN);
        common_len += NULL_BYTE_LEN;

        term_docs->seek_tinfo(term_docs, term_enum->tinfo);
        while (term_docs->next(term_docs)) {
            posting->size = common_len; /* can't ever be gt posting->cap */

            /* concat the remapped doc number */
            doc_num = term_docs->get_doc(term_docs);
            if (doc_num == -1)
                continue;
            if (doc_num > max_doc) 
                Kino1_confess("doc_num > max_doc: %d %d", doc_num, max_doc);
            doc_num = doc_map[doc_num];
            Kino1_encode_bigend_U32(doc_num, doc_num_buf);
            Kino1_BB_cat_string(posting, doc_num_buf, DOC_NUM_LEN); 

            /* concat the positions */
            positions_sv = term_docs->get_positions(term_docs);
            positions_ptr = SvPV(positions_sv, positions_len);
            Kino1_BB_cat_string(posting, positions_ptr, positions_len);

            /* concat the term_length */
            Kino1_BB_cat_string(posting, text_len_buf, TEXT_LEN_LEN);

            /* add the posting to the sortpool */
            sort_pool->feed(sort_pool, posting->ptr, posting->size);
        }
    }
    Kino1_BB_destroy(posting);
}

static void 
Kino1_PostWriter_deserialize(ByteBuf *posting, ByteBuf *termstring, 
                            ByteBuf *positions,
                            U32 *doc_num_ptr, U32 *freq_ptr) {
    char    *ptr;
    STRLEN   len;

    /* extract termstring_len, decoding packed 'n', assign termstring */
    ptr = posting->ptr + posting->size - TEXT_LEN_LEN;
    termstring->size = Kino1_decode_bigend_U16(ptr) + KINO_FIELD_NUM_LEN;
    Kino1_BB_assign_view(termstring, posting->ptr, termstring->size);

    /* extract and assign doc_num, decoding packed 'N' */
    ptr = posting->ptr + termstring->size + NULL_BYTE_LEN;
    *doc_num_ptr  = Kino1_decode_bigend_U32(ptr);

    /* make positions ByteBuf a view of the positional data in the posting */
    ptr = posting->ptr + termstring->size + NULL_BYTE_LEN + DOC_NUM_LEN;
    len = posting->size 
            - termstring->size 
            - NULL_BYTE_LEN 
            - DOC_NUM_LEN 
            - TEXT_LEN_LEN;
    Kino1_BB_assign_view(positions, ptr, len);
    
    /* calculate freq by counting the number of positions, assign */
    *freq_ptr = len / 4;
}

/* Write out the positions data using delta encoding.
 */
static void
Kino1_PostWriter_write_positions(OutStream *prx_out, ByteBuf *positions) {
    U32     *current_pos_ptr, *end;
    U32      last_pos;
    U32      pos_delta;

    /* extract 32 bit unsigned integers from positions_sv.  */
    current_pos_ptr = (U32*)positions->ptr;
    end             = current_pos_ptr + (positions->size / 4);
    last_pos        = 0;
    while (current_pos_ptr < end) {
        /* get delta and write out as VInt */
        pos_delta = *current_pos_ptr - last_pos;
        prx_out->write_vint(prx_out, pos_delta);

        /* advance pointers */
        last_pos = *current_pos_ptr;
        current_pos_ptr++;
    }
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::PostingsWriter - write postings data to an invindex

==head1 DESCRIPTION

PostingsWriter creates posting lists.  It writes the frequency and and
positional data files, plus feeds data to TermInfosWriter.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

