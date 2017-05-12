package KinoSearch1::Index::TermInfosWriter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        invindex       => undef,
        seg_name       => undef,
        is_index       => 0,
        index_interval => 1024,
        skip_interval  => 16,
    );
}
our %instance_vars;

sub new {
    my $class = shift;
    confess kerror() unless verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );
    my $invindex = $args{invindex};

    # open an outstream
    my $suffix = $args{is_index} ? 'tii' : 'tis';
    my $filename = "$args{seg_name}.$suffix";
    $invindex->delete_file($filename) if $invindex->file_exists($filename);
    my $outstream = $args{invindex}->open_outstream($filename);

    my $self = _new( $outstream,
        @args{qw( is_index index_interval skip_interval )} );

    # create the tii doppelganger
    if ( !$args{is_index} ) {
        my $other = __PACKAGE__->new(
            invindex => $invindex,
            seg_name => $args{seg_name},
            is_index => 1,
        );
        $self->_set_other($other);
        $other->_set_other($self);
    }

    return $self;
}

sub finish {
    my $self      = shift;
    my $outstream = $self->_get_outstream;

    # seek to near the head and write the number of terms processed
    $outstream->seek(4);
    $outstream->lu_write( 'Q', $self->_get_size );

    # cue the doppelganger's exit
    if ( !$self->_get_is_index ) {
        $self->_get_other()->finish;
    }

    $outstream->close;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::TermInfosWriter

TermInfosWriter*
_new(outstream_sv, is_index, index_interval, skip_interval)
    SV  *outstream_sv;
    I32  is_index;
    I32  index_interval;
    I32  skip_interval;
CODE:
    RETVAL = Kino1_TInfosWriter_new(outstream_sv, is_index, index_interval, 
        skip_interval);
OUTPUT: RETVAL

=for comment

Add a Term (encoded as a termstring) and its associated TermInfo.

=cut 

void
add(obj, termstring_sv, tinfo)
    TermInfosWriter *obj;
    SV              *termstring_sv;
    TermInfo        *tinfo;
PREINIT:
    ByteBuf bb;
    STRLEN len;
PPCODE:
    bb.ptr  = SvPV(termstring_sv, len);
    bb.size = len;
    Kino1_TInfosWriter_add(obj, &bb, tinfo);

=for comment

Export the FORMAT constant to Perl.

=cut

IV
FORMAT()
CODE:
    RETVAL = KINO_TINFOS_FORMAT;
OUTPUT: RETVAL


SV*
_set_or_get(obj, ...)
    TermInfosWriter *obj;
ALIAS:
    _set_other     = 1
    _get_other     = 2
    _get_outstream = 4
    _get_is_index  = 6
    _get_size      = 8
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  SvREFCNT_dec(obj->other_sv);
             obj->other_sv = newSVsv( ST(1) );
             Kino1_extract_struct(obj->other_sv, obj->other, TermInfosWriter*,
                "KinoSearch1::Index::TermInfosWriter");
             /* fall through */
    case 2:  RETVAL = newSVsv(obj->other_sv);
             break;

    case 4:  RETVAL = newSVsv(obj->fh_sv);
             break;

    case 6:  RETVAL = newSViv(obj->is_index);
             break;

    case 8:  RETVAL = newSViv(obj->size);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL


void
DESTROY(obj)
    TermInfosWriter *obj;
PPCODE:
    Kino1_TInfosWriter_destroy(obj);

__H__

#ifndef H_KINO_TERM_INFOS_WRITER
#define H_KINO_TERM_INFOS_WRITER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexTerm.h"
#include "KinoSearch1IndexTermInfo.h"
#include "KinoSearch1StoreOutStream.h"
#include "KinoSearch1UtilByteBuf.h"
#include "KinoSearch1UtilCClass.h"
#include "KinoSearch1UtilMathUtils.h"
#include "KinoSearch1UtilMemManager.h"
#include "KinoSearch1UtilStringHelper.h"

#define KINO_TINFOS_FORMAT -2

typedef struct terminfoswriter {
    OutStream *fh;
    SV        *fh_sv;
    I32        is_index;
    I32        index_interval;
    I32        skip_interval;
    struct terminfoswriter* other;
    SV        *other_sv;
    ByteBuf   *last_termstring;
    TermInfo  *last_tinfo;
    I32        last_fieldnum;
    double     last_tis_ptr;
    I32        size;
} TermInfosWriter;

TermInfosWriter* Kino1_TInfosWriter_new(SV*, I32, I32, I32);
void Kino1_TInfosWriter_add(TermInfosWriter*, ByteBuf*, TermInfo*);
void Kino1_TInfosWriter_destroy(TermInfosWriter*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexTermInfosWriter.h"

TermInfosWriter*
Kino1_TInfosWriter_new(SV *outstream_sv, I32 is_index, I32 index_interval, 
                      I32 skip_interval) {
    TermInfosWriter *obj;

    /* allocate */
    Kino1_New(0, obj, 1, TermInfosWriter);

    /* assign */
    obj->is_index       = is_index;
    obj->index_interval = index_interval;
    obj->skip_interval  = skip_interval;
    obj->fh_sv          = newSVsv(outstream_sv);
    Kino1_extract_struct(obj->fh_sv, obj->fh, OutStream*,
        "KinoSearch1::Store::OutStream");
    /* NOTE: this value forces the first field_num in the .tii file to -1.
     * Do not change it. */
    obj->last_termstring    = Kino1_BB_new_string("\xff\xff", 2);
    obj->last_tinfo         = Kino1_TInfo_new();
    obj->last_fieldnum      = -1;
    obj->last_tis_ptr       = 0,
    obj->size               = 0;
    obj->other              = NULL;
    obj->other_sv           = &PL_sv_undef;
 
    /* write file header */
    obj->fh->write_int(obj->fh, KINO_TINFOS_FORMAT);
    obj->fh->write_long(obj->fh, 0.0); /* return to fill in later */
    obj->fh->write_int(obj->fh, index_interval);
    obj->fh->write_int(obj->fh, skip_interval);

    return obj;
}


/* Write out a term/terminfo combo. */
void 
Kino1_TInfosWriter_add(TermInfosWriter* obj, ByteBuf* termstring_bb,
                      TermInfo* tinfo) {
    char      *termstring, *last_tstring;
    STRLEN     termstring_len, last_tstring_len;

    I32        field_num;
    I32        overlap;
    char      *diff_start_str;
    STRLEN     diff_len;
    OutStream* fh;

    /* make local copy */
    fh = obj->fh;

    /* write a subset of the entries to the .tii index */
    if (    (obj->size % obj->index_interval == 0)
         && (!obj->is_index)               
    ) {
        Kino1_TInfosWriter_add(obj->other, obj->last_termstring,
        obj->last_tinfo);
    }

    /* extract string pointers and string lengths */
    termstring       = termstring_bb->ptr;
    last_tstring     = obj->last_termstring->ptr;
    termstring_len   = termstring_bb->size;
    last_tstring_len = obj->last_termstring->size;

    /* to obtain field number, decode packed 'n' at top of termstring */
    field_num = (I16)Kino1_decode_bigend_U16(termstring);

    /* move past field_num */
    termstring       += KINO_FIELD_NUM_LEN;
    last_tstring     += KINO_FIELD_NUM_LEN;
    termstring_len   -= KINO_FIELD_NUM_LEN;
    last_tstring_len -= KINO_FIELD_NUM_LEN;

    /* count how many bytes the strings share at the top */ 
    overlap = Kino1_StrHelp_string_diff(last_tstring, termstring,
        last_tstring_len, termstring_len);
    diff_start_str = termstring + overlap;
    diff_len       = termstring_len - overlap;

    /* write number of common bytes */
    fh->write_vint(fh, overlap);

    /* write common bytes */
    fh->write_string(fh, diff_start_str, diff_len);
    
    /* write field number and doc_freq */
    fh->write_vint(fh, field_num);
    fh->write_vint(fh, tinfo->doc_freq);

    /* delta encode filepointers */
    fh->write_vlong(fh, (tinfo->frq_fileptr - obj->last_tinfo->frq_fileptr) );
    fh->write_vlong(fh, (tinfo->prx_fileptr - obj->last_tinfo->prx_fileptr) );

    /* write skipdata */
    if (tinfo->doc_freq >= obj->skip_interval)
        fh->write_vint(fh, tinfo->skip_offset);

    /* the .tii index file gets a pointer to the location of the primary */
    if (obj->is_index) {
        double tis_ptr;

        tis_ptr = obj->other->fh->tell(obj->other->fh);
        obj->fh->write_vlong(obj->fh, (tis_ptr - obj->last_tis_ptr));
        obj->last_tis_ptr = tis_ptr;
    }

    /* track number of terms */
    obj->size++;

    /* remember for delta encoding */
    Kino1_BB_assign_string(obj->last_termstring, termstring_bb->ptr,
        termstring_bb->size);
    StructCopy(tinfo, obj->last_tinfo, TermInfo);
}

void
Kino1_TInfosWriter_destroy(TermInfosWriter *obj) {
    SvREFCNT_dec(obj->fh_sv);
    SvREFCNT_dec(obj->other_sv);
    Kino1_BB_destroy(obj->last_termstring);
    Kino1_TInfo_destroy(obj->last_tinfo);
    Kino1_Safefree(obj);
}


__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermInfosWriter - write a term dictionary

==head1 DESCRIPTION

The TermInfosWriter write both parts of the term dictionary.  The primary
instance creates a shadow TermInfosWriter that writes the index.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

