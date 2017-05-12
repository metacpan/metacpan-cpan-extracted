package KinoSearch1::Index::TermBuffer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        finfos => undef,
    );
}
our %instance_vars;

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my %args = ( %instance_vars, @_ );
    confess kerror() unless verify_args( \%instance_vars, %args );
    my $self = _new( $class, $args{finfos}->size );
    return $self;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::TermBuffer

void
_new(class, finfos_size) 
    char *class;
    I32   finfos_size;
PREINIT:
    TermBuffer *term_buf;
PPCODE:
    term_buf = Kino1_TermBuf_new(finfos_size);
    ST(0)   = sv_newmortal();
    sv_setref_pv(ST(0), class, (void*)term_buf);
    XSRETURN(1);
    

void
DESTROY(term_buf)
    TermBuffer *term_buf;
PPCODE:
    Kino1_TermBuf_destroy(term_buf);

__H__

#ifndef H_KINOSEARCH_INDEX_TERM_BUFFER
#define H_KINOSEARCH_INDEX_TERM_BUFFER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexTerm.h"
#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1UtilByteBuf.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct termbuffer {
    ByteBuf *termstring;
    I32      text_len;
    I32      max_field_num;
} TermBuffer;

TermBuffer* Kino1_TermBuf_new(I32);
void Kino1_TermBuf_read(TermBuffer*, InStream*);
void Kino1_TermBuf_reset(TermBuffer*);
void Kino1_TermBuf_set_termstring(TermBuffer*, char*, I32);
void Kino1_TermBuf_destroy(TermBuffer*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexTermBuffer.h"

static void Kino1_TermBuf_set_text_len(TermBuffer*, I32);

TermBuffer*
Kino1_TermBuf_new(I32 finfos_size) {
    TermBuffer *term_buf;

    /* allocate */
    Kino1_New(0, term_buf, 1, TermBuffer);

    /* reset the TermBuffer */
    term_buf->termstring = NULL;
    Kino1_TermBuf_reset(term_buf);

    /* derive max_field_num */
    term_buf->max_field_num = finfos_size - 1;

    return term_buf;
}

/* Decode the next term in a term dictionary file (.tii, .tis), but don't turn
 * it into a full-fledged Term object. */
void
Kino1_TermBuf_read(TermBuffer *term_buf, InStream *instream) {
    I32 text_overlap, finish_chars_len, total_text_len, field_num;

    /* read bytes which are shared between the last term text and this */
    text_overlap     = instream->read_vint(instream);
    finish_chars_len = instream->read_vint(instream);
    total_text_len   = text_overlap + finish_chars_len;
    Kino1_TermBuf_set_text_len(term_buf, total_text_len);
    instream->read_chars(instream, term_buf->termstring->ptr, 
        (text_overlap + KINO_FIELD_NUM_LEN),
        finish_chars_len);

    /* read field num */
    field_num = instream->read_vint(instream);
    if (field_num > term_buf->max_field_num && field_num != -1)
        Kino1_confess("Internal error: field_num %d > max_field_num %d",
            field_num, term_buf->max_field_num);

    Kino1_encode_bigend_U16( (U16)field_num, term_buf->termstring->ptr);
}

/* Set the TermBuffer object to a sentinel state, indicating that it does not
 * hold a valid Term */
void
Kino1_TermBuf_reset(TermBuffer *term_buf) {
    if (term_buf->termstring != NULL) {
        Kino1_BB_destroy(term_buf->termstring);
        term_buf->termstring = NULL;
    }
    term_buf->text_len   = 0;
}

void
Kino1_TermBuf_set_termstring(TermBuffer *term_buf, char* ptr, I32 len) {
    /* the passed in len includes the length of the encoded field num */
    if (len < 2)
        Kino1_confess("can't set_termstring with a len < 2: %d", len);
    Kino1_TermBuf_set_text_len(term_buf, len - KINO_FIELD_NUM_LEN);

    Kino1_BB_assign_string(term_buf->termstring, ptr, len);
}

/* Set the length of the term text, and ensure that there's enough memory
 * allocated to hold term text that size. */
static void 
Kino1_TermBuf_set_text_len(TermBuffer *term_buf, I32 new_len) {
    ByteBuf* termstring = term_buf->termstring;

    /* initialize if necessary, with a field number of 0 */
    if (termstring == NULL) {
        termstring = Kino1_BB_new_string("\0\0", 2);
        term_buf->termstring = termstring;
    }

    /* realloc and set lengths */
    Kino1_BB_grow(termstring, new_len + KINO_FIELD_NUM_LEN);
    termstring->size   = new_len + KINO_FIELD_NUM_LEN;
    term_buf->text_len = new_len;

    /* null-terminate */
    termstring->ptr[ termstring->size ] = '\0';
}

void 
Kino1_TermBuf_destroy(TermBuffer *term_buf) {
    Kino1_TermBuf_reset(term_buf);
    Kino1_Safefree(term_buf);
}

__POD__


==begin devdocs

==head1 NAME

KinoSearch1::Index::TermBuffer - decode a term dictionary one Term at a time

==head1 DESCRIPTION

A TermBuffer iterates through a term dictionary, holding one current term in a
buffer.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
