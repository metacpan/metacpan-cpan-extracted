package KinoSearch1::Index::SegTermEnum;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        finfos   => undef,
        instream => undef,
        is_index => 0,
    );
}
our %instance_vars;

use KinoSearch1::Index::Term;
use KinoSearch1::Index::TermInfo;
use KinoSearch1::Index::TermBuffer;

sub new {
    # verify params
    my $ignore = shift;
    my %args = ( %instance_vars, @_ );
    confess kerror() unless verify_args( \%instance_vars, %args );

    # get a TermBuffer helper object
    my $term_buffer
        = KinoSearch1::Index::TermBuffer->new( finfos => $args{finfos}, );

    return _new_helper( @args{ 'instream', 'is_index', 'finfos', },
        $term_buffer );
}

sub clone_enum {
    my $self = shift;

    # dupe instream and seek it to the start of the file, so init works right
    my $instream   = $self->_get_instream;
    my $new_stream = $instream->clone_stream;
    $new_stream->seek(0);

    # create a new object and seek it to the right term/terminfo
    my $evil_twin = __PACKAGE__->new(
        finfos   => $self->_get_finfos,
        instream => $new_stream,
        is_index => $self->is_index,
    );
    $evil_twin->seek(
        $instream->tell,       $self->_get_position,
        $self->get_termstring, $self->get_term_info
    );
    return $evil_twin;
}

# Locate the Enum to a particular spot.
sub seek {
    my ( $self, $pointer, $position, $termstring, $tinfo ) = @_;

    # seek the filehandle
    my $instream = $self->_get_instream;
    $instream->seek($pointer);

    # set values as if we'd scanned here from the start of the Enum
    $self->_set_position($position);
    $self->_set_termstring($termstring);
    $self->_set_term_info($tinfo);
}

sub close {
    my $instream = $_[0]->_get_instream;
    $instream->close;
}

# return a Term, if the Enum is currently valid.
sub get_term {
    my $self       = shift;
    my $termstring = $self->get_termstring;
    return unless defined $termstring;
    return KinoSearch1::Index::Term->new_from_string( $termstring,
        $self->_get_finfos );
}

1;

__END__

__XS__

MODULE = KinoSearch1   PACKAGE = KinoSearch1::Index::SegTermEnum 


SegTermEnum*
_new_helper(instream_sv, is_index, finfos_sv, term_buffer_sv)
    SV         *instream_sv;
    I32         is_index;
    SV         *finfos_sv
    SV         *term_buffer_sv;
CODE:
    RETVAL = Kino1_SegTermEnum_new_helper(instream_sv, is_index, finfos_sv,
        term_buffer_sv);
OUTPUT: RETVAL


=for comment

fill_cache() loads the entire Enum into memory.  This should only be called
for index Enums -- never for primary Enums.

=cut

void
fill_cache(obj)
    SegTermEnum *obj;
PPCODE:
    Kino1_SegTermEnum_fill_cache(obj);


=begin comment

scan_to() iterates through the Enum until the Enum's state is ge the target.
This is called on the main Enum, after seek() has gotten it close.  You don't
want to scan through the entire main Enum, just through a small part.

Scanning through an Enum is an involved process, due to the heavy data
compression.  See the Java Lucene File Format definition for details.

=end comment
=cut

void
scan_to(obj, target_termstring_sv)
    SegTermEnum *obj;
    SV          *target_termstring_sv;
PREINIT:
    char *ptr;
    STRLEN len;
PPCODE:
    ptr = SvPV(target_termstring_sv, len);
    if (len < 2)
        Kino1_confess("length of termstring < 2: %"UVuf, (UV)len);
    Kino1_SegTermEnum_scan_to(obj, ptr, len);


=for comment

Reset the Enum to the top, so that after next() is called, the Enum is located
at the first term in the segment.

=cut

void
reset(obj)
    SegTermEnum *obj;
PPCODE:
    Kino1_SegTermEnum_reset(obj);


=for comment

next() advances the state of the Enum one term.  If the current position of
the Enum is valid, it returns 1; when the Enum is exhausted, it returns 0.

=cut

IV
next(obj)
    SegTermEnum *obj;
CODE:
    RETVAL = Kino1_SegTermEnum_next(obj);
OUTPUT: RETVAL


=for comment

For an Enum which has been loaded into memory, scan to the target as quickly
as possible.

=cut

I32
scan_cache(obj, target_termstring_sv)
    SegTermEnum  *obj;
    SV           *target_termstring_sv;
PREINIT:
    char *ptr;
    STRLEN len;
CODE:
    ptr = SvPV(target_termstring_sv, len);
    if (len < 2)
        Kino1_confess("length of termstring < 2: %"UVuf, (UV)len);
    RETVAL = Kino1_SegTermEnum_scan_cache(obj, ptr, len);
OUTPUT: RETVAL


=for comment

Setters and getters for members in the SegTermEnum struct. Not all of these 
are useful.

=cut

SV*
_set_or_get(obj, ...)
    SegTermEnum *obj;
ALIAS:
        _set_instream        = 1
        _get_instream        = 2
        _set_finfos          = 3
        _get_finfos          = 4
        _set_size            = 5
    get_size                 = 6  
        _set_termstring      = 7
    get_termstring           = 8
        _set_term_info       = 9
    get_term_info            = 10
        _set_index_interval  = 11
    get_index_interval       = 12
        _set_skip_interval   = 13
    get_skip_interval        = 14
        _set_position        = 15
        _get_position        = 16
        _set_is_index        = 17
    is_index                 = 18
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 0:  croak("can't call _get_or_set on it's own");
             break; /* probably unreachable */

    case 1:  SvREFCNT_dec(obj->instream_sv);
             obj->instream_sv = newSVsv( ST(1) );
             /* fall through */
    case 2:  RETVAL = newSVsv(obj->instream_sv); 
             break;

    case 3:  SvREFCNT_dec(obj->finfos);
             obj->finfos = newSVsv( ST(1) );
             /* fall through */
    case 4:  RETVAL = newSVsv(obj->finfos); 
             break;

    case 5:  obj->enum_size = (I32)SvIV( ST(1) ); 
             /* fall through */
    case 6:  RETVAL = newSViv(obj->enum_size); 
             break;

    case 7:  if ( SvOK( ST(1) ) ) {
                 STRLEN len = SvCUR( ST(1) );
                 if (len < KINO_FIELD_NUM_LEN)
                    Kino1_confess("Internal error: termstring too short");
                 Kino1_TermBuf_set_termstring(obj->term_buf, 
                    SvPVX(ST(1)), len);
             }
             else {
                 Kino1_TermBuf_reset(obj->term_buf);
             }
             /* fall through */
    case 8:  RETVAL = (obj->term_buf->termstring == NULL) 
                 ? &PL_sv_undef
                 : newSVpv( obj->term_buf->termstring->ptr,
                     obj->term_buf->termstring->size ); 
             break;

    case 9:  {
                TermInfo* new_tinfo;
                Kino1_extract_struct( ST(1), new_tinfo, TermInfo*, 
                    "KinoSearch1::Index::TermInfo");
                Kino1_TInfo_destroy(obj->tinfo);
                obj->tinfo = Kino1_TInfo_dupe(new_tinfo);
             }
             /* fall through */
    case 10: {
                TermInfo* new_tinfo;
                RETVAL = newSV(0);
                new_tinfo = Kino1_TInfo_dupe(obj->tinfo);
                sv_setref_pv(RETVAL, "KinoSearch1::Index::TermInfo", 
                              (void*)new_tinfo);
             }
             break;

    case 11: obj->index_interval = SvIV( ST(1) );
             /* fall through */
    case 12: RETVAL = newSViv(obj->index_interval);
             break;

    case 13: obj->skip_interval = SvIV( ST(1) );
             /* fall through */
    case 14: RETVAL = newSViv(obj->skip_interval);
             break;

    case 15: obj->position = SvIV( ST(1) );
             /* fall through */
    case 16: RETVAL = newSViv(obj->position);
             break;

    case 17: Kino1_confess("can't set is_index");
             /* fall through */
    case 18: RETVAL = newSViv(obj->is_index);
             break;
    
    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL


void
DESTROY(obj)
    SegTermEnum* obj;
PPCODE:
    Kino1_SegTermEnum_destroy(obj);

__H__

#ifndef H_KINOSEARCH_INDEX_SEG_TERM_ENUM
#define H_KINOSEARCH_INDEX_SEG_TERM_ENUM 1

#include "EXTERN.h"
#include "perl.h"
#include "KinoSearch1IndexTermBuffer.h"
#include "KinoSearch1IndexTermInfo.h"
#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1UtilByteBuf.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilCClass.h"
#include "KinoSearch1UtilMemManager.h"
#include "KinoSearch1UtilStringHelper.h"

typedef struct segtermenum {
    SV         *finfos;
    SV         *instream_sv;
    SV         *term_buf_ref;
    TermBuffer *term_buf;
    TermInfo   *tinfo;
    InStream   *instream;
    I32         is_index;
    I32         enum_size;
    I32         position;
    I32         index_interval;
    I32         skip_interval;
    ByteBuf   **termstring_cache;
    TermInfo  **tinfos_cache;
} SegTermEnum;


SegTermEnum* Kino1_SegTermEnum_new_helper(SV*, I32, SV*, SV*);
void Kino1_SegTermEnum_reset(SegTermEnum*);
I32  Kino1_SegTermEnum_next(SegTermEnum*);
void Kino1_SegTermEnum_fill_cache(SegTermEnum*);
void Kino1_SegTermEnum_scan_to(SegTermEnum*, char*, I32);
I32  Kino1_SegTermEnum_scan_cache(SegTermEnum*, char*, I32);
void Kino1_SegTermEnum_destroy(SegTermEnum*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexSegTermEnum.h"

SegTermEnum*
Kino1_SegTermEnum_new_helper(SV *instream_sv, I32 is_index, SV *finfos_sv,
                            SV *term_buffer_sv) {
    I32           format;
    InStream     *instream;
    SegTermEnum  *obj;

    /* allocate */
    Kino1_New(0, obj, 1, SegTermEnum);
    obj->tinfo = Kino1_TInfo_new();

    /* init */
    obj->tinfos_cache     = NULL;
    obj->termstring_cache = NULL;

    /* save instream, finfos, and term_buffer, incrementing refcounts */
    obj->instream_sv  = newSVsv(instream_sv);
    obj->finfos       = newSVsv(finfos_sv);
    obj->term_buf_ref = newSVsv(term_buffer_sv);
    Kino1_extract_struct(term_buffer_sv, obj->term_buf, TermBuffer*, 
        "KinoSearch1::Index::TermBuffer");
    Kino1_extract_struct(instream_sv, obj->instream, InStream*, 
        "KinoSearch1::Store::InStream");
    instream = obj->instream;

    /* determine whether this is a primary or index enum */
    obj->is_index = is_index;

    /* reject older or newer index formats */
    format = (I32)instream->read_int(instream);
    if (format != -2)
        Kino1_confess("Unsupported index format: %d", format);

    /* read in some vars */
    obj->enum_size      = instream->read_long(instream);
    obj->index_interval = instream->read_int(instream);
    obj->skip_interval  = instream->read_int(instream);

    /* define the position of the Enum as "not yet started" */
    obj->position = -1;
    
    return obj;
}

#define KINO_SEG_TERM_ENUM_HEADER_LEN 20 

void
Kino1_SegTermEnum_reset(SegTermEnum* obj) {
    obj->position = -1;
    obj->instream->seek(obj->instream, KINO_SEG_TERM_ENUM_HEADER_LEN);
    Kino1_TermBuf_reset(obj->term_buf);
    Kino1_TInfo_reset(obj->tinfo);
}

I32 
Kino1_SegTermEnum_next(SegTermEnum *obj) {
    InStream *instream;
    TermInfo *tinfo;

    /* make some local copies for clarity of code */
    instream = obj->instream;
    tinfo    = obj->tinfo;

    /* if we've run out of terms, null out the termstring and return */
    if (++obj->position >= obj->enum_size) {
        Kino1_TermBuf_reset(obj->term_buf);
        return 0;
    }

    /* read in the term */
    Kino1_TermBuf_read(obj->term_buf, instream);

    /* read doc freq */
    tinfo->doc_freq = instream->read_vint(instream);

    /* adjust file pointers. */
    tinfo->frq_fileptr += instream->read_vlong(instream);
    tinfo->prx_fileptr += instream->read_vlong(instream);

    /* read skip data (which doesn't do anything right now) */
    if (tinfo->doc_freq >= obj->skip_interval)
        tinfo->skip_offset = instream->read_vint(instream);
    else
        tinfo->skip_offset = 0;

    /* read filepointer to main enum if this is an index enum */
    if (obj->is_index)
        tinfo->index_fileptr += instream->read_vlong(instream);

    return 1;
}

void
Kino1_SegTermEnum_fill_cache(SegTermEnum* obj) {
    TermBuffer  *term_buf;
    TermInfo    *tinfo;
    TermInfo   **tinfos_cache;
    ByteBuf    **termstring_cache;

    /* allocate caches */
    if (obj->tinfos_cache != NULL)
        Kino1_confess("Internal error: cache already filled");
    Kino1_New(0, obj->termstring_cache, obj->enum_size, ByteBuf*); 
    Kino1_New(0, obj->tinfos_cache, obj->enum_size, TermInfo*);

    /* make some local copies */
    tinfo                = obj->tinfo;
    term_buf             = obj->term_buf;
    tinfos_cache         = obj->tinfos_cache;
    termstring_cache     = obj->termstring_cache;

    while (Kino1_SegTermEnum_next(obj)) {
        /* copy tinfo and termstring into caches */
        *tinfos_cache++     = Kino1_TInfo_dupe(tinfo);
        *termstring_cache++ = Kino1_BB_clone(term_buf->termstring);
    }
}

void
Kino1_SegTermEnum_scan_to(SegTermEnum *obj, char *target_termstring, 
                         I32 target_termstring_len) {
    TermBuffer *term_buf = obj->term_buf;
    ByteBuf     target;

    /* make convenience copies */
    target.ptr  = target_termstring;
    target.size = target_termstring_len;

    /* keep looping until the termstring is lexically ge target */
    do {
        const I32 comparison = Kino1_BB_compare(term_buf->termstring, &target);

        if ( comparison >= 0 &&  obj->position != -1) {
            break;
        }
    } while (Kino1_SegTermEnum_next(obj));
}

I32
Kino1_SegTermEnum_scan_cache(SegTermEnum *obj, char *target_termstring, 
                            I32 target_len) {
    TermBuffer  *term_buf = obj->term_buf;
    ByteBuf    **termstrings = obj->termstring_cache;
    ByteBuf      target;
    I32          lo       = 0;
    I32          hi       = obj->enum_size - 1;
    I32          result   = -100;
    I32          mid, comparison;

    /* make convenience copies */
    target.ptr  = target_termstring;
    target.size = target_len;
    if (obj->tinfos_cache == NULL)
        Kino1_confess("Internal Error: fill_cache hasn't been called yet"); 
    
    /* divide and conquer */
    while (hi >= lo) {
        mid        = (lo + hi) >> 1;
        comparison = Kino1_BB_compare(&target, termstrings[mid]);
        if (comparison < 0) 
            hi = mid - 1;
        else if (comparison > 0)
            lo = mid + 1;
        else {
            result = mid;
            break;
        }
    }
    result = hi     == -1   ? 0  /* indicating that target lt first entry */
           : result == -100 ? hi /* if result is still -100, it wasn't set */
           : result;
    
    /* set the state of the Enum/TermBuffer as if we'd called scan_to */
    obj->position  = result;
    Kino1_TermBuf_set_termstring(term_buf, termstrings[result]->ptr,
        termstrings[result]->size);
    Kino1_TInfo_destroy(obj->tinfo);
    obj->tinfo = Kino1_TInfo_dupe( obj->tinfos_cache[result] );

    return result;
}

void
Kino1_SegTermEnum_destroy(SegTermEnum *obj) {
    /* put out the garbage for collection */
    SvREFCNT_dec(obj->finfos);
    SvREFCNT_dec(obj->instream_sv);
    SvREFCNT_dec(obj->term_buf_ref);

    Kino1_TInfo_destroy(obj->tinfo);

    /* if fill_cache was called, free all of that... */
    if (obj->tinfos_cache != NULL) {
        I32         iter;
        ByteBuf   **termstring_cache = obj->termstring_cache;
        TermInfo  **tinfos_cache     = obj->tinfos_cache;
        for (iter = 0; iter < obj->enum_size; iter++) {
            Kino1_BB_destroy(*termstring_cache++);
            Kino1_TInfo_destroy(*tinfos_cache++);
        }
        Kino1_Safefree(obj->tinfos_cache);
        Kino1_Safefree(obj->termstring_cache);
    }

    /* last, the SegTermEnum object itself */
    Kino1_Safefree(obj);
}


__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::SegTermEnum - single-segment TermEnum

==head1 DESCRIPTION

Single-segment implementation of KinoSearch1::Index::TermEnum.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut


