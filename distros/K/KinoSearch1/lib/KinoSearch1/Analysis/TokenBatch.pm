package KinoSearch1::Analysis::TokenBatch;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

1;

__END__

__XS__

MODULE = KinoSearch1   PACKAGE = KinoSearch1::Analysis::TokenBatch

void
new(either_sv)
    SV *either_sv;
PREINIT:
    const char *class;
    TokenBatch *batch;
PPCODE:
    /* determine the class */
    class = sv_isobject(either_sv) 
        ? sv_reftype(either_sv, 0) 
        : SvPV_nolen(either_sv);
    /* build object */
    batch = Kino1_TokenBatch_new();
    ST(0)   = sv_newmortal();
    sv_setref_pv(ST(0), class, (void*)batch);
    XSRETURN(1);

void
append(batch, text_sv, start_offset, end_offset, ...)
    TokenBatch *batch;
    SV         *text_sv;
    I32         start_offset;
    I32         end_offset;
PREINIT:
    char   *text;
    STRLEN  len;
    I32     pos_inc = 1;
    Token  *token;
PPCODE:
    text  = SvPV(text_sv, len);
    if (items == 5)
        pos_inc = SvIV( ST(4) );
    else if (items > 5)
        Kino1_confess("Too many arguments: %d", items);

    token = Kino1_Token_new(text, len, start_offset, end_offset, pos_inc);
    Kino1_TokenBatch_append(batch, token);

=for comment

Add many tokens to the batch, by supplying the string to be tokenized, and
arrays of token starts and token ends (specified in bytes).

=cut

void
add_many_tokens(batch, string_sv, starts_av, ends_av)
    TokenBatch *batch;
    SV         *string_sv;
    AV         *starts_av;
    AV         *ends_av;
PREINIT:
    char   *string_start;
    STRLEN  len, start_offset, end_offset;
    I32     i, max;
    SV    **start_sv_ptr;
    SV    **end_sv_ptr;
    Token  *token;
PPCODE:
{
    string_start = SvPV(string_sv, len);

    max = av_len(starts_av);
    for (i = 0; i <= max; i++) {
        /* retrieve start */
        start_sv_ptr = av_fetch(starts_av, i, 0);
        if (start_sv_ptr == NULL)
            Kino1_confess("Failed to retrieve @starts array element");
        start_offset = SvIV(*start_sv_ptr);

        /* retrieve end */
        end_sv_ptr = av_fetch(ends_av, i, 0);
        if (end_sv_ptr == NULL)
            Kino1_confess("Failed to retrieve @ends array element");
        end_offset = SvIV(*end_sv_ptr);

        /* sanity check the offsets to make sure they're inside the string */
        if (start_offset > len)
            Kino1_confess("start_offset > len (%d > %"UVuf")", 
                start_offset, (UV)len);
        if (end_offset > len)
            Kino1_confess("end_offset > len (%d > %"UVuf")", 
                end_offset, (UV)len);

        /* calculate the start of the substring and add the token */
        token = Kino1_Token_new(
            (string_start + start_offset), 
            (end_offset - start_offset), 
            start_offset, 
            end_offset,
            1
        );
        Kino1_TokenBatch_append(batch, token);
    }
}

=begin comment

Add the postings to the segment.  Postings are serialized and dumped into a
SortExternal sort pool.  The actual writing takes place later.

The serialization algo is designed so that postings emerge from the sort
pool in the order ideal for writing an index after a  simple lexical sort.
The concatenated components are:

    field number
    term text 
    null byte
    document number
    positions (C array of U32)
    term length

=end comment
=cut

void
build_posting_list(batch, doc_num, field_num)
    TokenBatch *batch;
    U32         doc_num;
    U16         field_num;
PPCODE:
    Kino1_TokenBatch_build_plist(batch, doc_num, field_num);

void
set_all_texts(batch, texts_av)
    TokenBatch *batch;
    AV         *texts_av;
PREINIT:
    Token  *token;
    I32     i, max;
    SV    **sv_ptr;
    char   *text;
    STRLEN  len;
PPCODE:
{
    token = batch->first;
    max = av_len(texts_av);
    for (i = 0; i <= max; i++) {
        if (token == NULL) {
            Kino1_confess("Batch size %d doesn't match array size %d",
                batch->size, (max + 1));
        }
        sv_ptr = av_fetch(texts_av, i, 0);
        if (sv_ptr == NULL) {
            Kino1_confess("Encountered a null SV* pointer");
        }
        text = SvPV(*sv_ptr, len);
        Kino1_Safefree(token->text);
        token->text = Kino1_savepvn(text, len);
        token->len = len;
        token = token->next;
    }
}

void
get_all_texts(batch)
    TokenBatch *batch;
PREINIT: 
    Token *token;
    AV *out_av;
PPCODE:
{
    out_av = newAV();
    token = batch->first;
    while (token != NULL) {
        SV *text = newSVpvn(token->text, token->len);
        av_push(out_av, text);
        token = token->next;
    }
    XPUSHs(sv_2mortal( newRV_noinc((SV*)out_av) ));
    XSRETURN(1);
}


SV*
_set_or_get(batch, ...) 
    TokenBatch *batch;
ALIAS:
    set_text         = 1
    get_text         = 2
    set_start_offset = 3
    get_start_offset = 4
    set_end_offset   = 5
    get_end_offset   = 6
    set_pos_inc      = 7
    get_pos_inc      = 8
    set_size         = 9
    get_size         = 10
    set_postings     = 11
    get_postings     = 12
    set_tv_string    = 13
    get_tv_string    = 14
CODE:
{
    /* fail if looking for info on a single token but there isn't one */
    if ((ix < 7) && (batch->current == NULL))
        Kino1_confess("TokenBatch doesn't currently hold a valid token");

    KINO_START_SET_OR_GET_SWITCH

    case 1:  {
                Token *current = batch->current;
                char   *text;
                Kino1_Safefree(current->text);
                text = SvPV( ST(1), current->len );
                current->text = Kino1_savepvn( text, current->len );
             }
             /* fall through */
    case 2:  RETVAL = newSVpvn(batch->current->text, batch->current->len);
             break;

    case 3:  batch->current->start_offset = SvIV( ST(1) );
             /* fall through */
    case 4:  RETVAL = newSViv(batch->current->start_offset);
             break;

    case 5:  batch->current->end_offset = SvIV( ST(1) );
             /* fall through */
    case 6:  RETVAL = newSViv(batch->current->end_offset);
             break;

    case 7:  batch->current->pos_inc = SvIV( ST(1) );
             /* fall through */
    case 8:  RETVAL = newSViv(batch->current->pos_inc);
             break;

    case 9:  Kino1_confess("Can't set size on a TokenBatch object");
             /* fall through */
    case 10: RETVAL = newSVuv(batch->size);
             break;
    
    case 11: Kino1_confess("can't set_postings");
             /* fall through */
    case 12: RETVAL = newRV_inc( (SV*)batch->postings );
             break;

    case 13: Kino1_confess("can't set_tv_string");
             /* fall through */
    case 14: RETVAL = newSVsv(batch->tv_string);
             break;
    
    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

void
reset(batch)
    TokenBatch *batch;
PPCODE:
    Kino1_TokenBatch_reset(batch);

I32
next(batch)
    TokenBatch *batch;
CODE:
    RETVAL = Kino1_TokenBatch_next(batch);
OUTPUT: RETVAL

void
DESTROY(batch)
    TokenBatch *batch;
PPCODE:
    Kino1_TokenBatch_destroy(batch);


__H__

#ifndef H_KINOSEARCH_ANALYSIS_TOKENBATCH
#define H_KINOSEARCH_ANALYSIS_TOKENBATCH 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "KinoSearch1AnalysisToken.h"
#include "KinoSearch1IndexTerm.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMathUtils.h"
#include "KinoSearch1UtilMemManager.h"
#include "KinoSearch1UtilStringHelper.h"

typedef struct tokenbatch {
    Token   *first;
    Token   *last;
    Token   *current;
    I32      size;
    I32      initialized;
    AV      *postings;
    SV      *tv_string;
} TokenBatch;

TokenBatch* Kino1_TokenBatch_new();
void   Kino1_TokenBatch_destroy(TokenBatch *batch);
void   Kino1_TokenBatch_append(TokenBatch *batch, Token *token);
I32    Kino1_TokenBatch_next(TokenBatch *batch);
void   Kino1_TokenBatch_reset(TokenBatch *batch);
void   Kino1_TokenBatch_build_plist(TokenBatch*, U32, U16);

#endif /* include guard */

__C__

#include "KinoSearch1AnalysisTokenBatch.h"

TokenBatch*
Kino1_TokenBatch_new() {
    TokenBatch *batch;

    /* allocate */
    Kino1_New(0, batch, 1, TokenBatch);

    /* init */
    batch->first        = NULL;
    batch->last         = NULL;
    batch->current      = NULL;
    batch->size         = 0;
    batch->initialized  = 0;
    batch->tv_string    = &PL_sv_undef;
    batch->postings     = (AV*)&PL_sv_undef;

    return batch;
}


void
Kino1_TokenBatch_destroy(TokenBatch *batch) {
    Token *token = batch->first;
    while (token != NULL) {
        Token *next = token->next;
        Kino1_Token_destroy(token);
        token = next;
    }
    SvREFCNT_dec( (SV*)batch->postings );
    SvREFCNT_dec(batch->tv_string);
    Kino1_Safefree(batch);
}

I32
Kino1_TokenBatch_next(TokenBatch *batch) {
    /* enter iterative mode */
    if (batch->initialized == 0) {
        batch->current = batch->first;
        batch->initialized = 1;
    }
    /* continue iterative mode */
    else {
        batch->current = batch->current->next;
    }
    return batch->current == NULL ? 0 : 1;
}

void
Kino1_TokenBatch_reset(TokenBatch *batch) {
    batch->initialized = 0;
}

void
Kino1_TokenBatch_append(TokenBatch *batch, Token *token) {
    token->next  = NULL;
    token->prev  = batch->last;

    /* if this is the first token added, init */
    if (batch->first == NULL) {
        batch->first   = token;
        batch->last    = token;
    }
    else {
        batch->last->next = token;
        batch->last       = token;
    }

    batch->size++;
}

#define POSDATA_LEN 12 
#define DOC_NUM_LEN 4
#define NULL_BYTE_LEN 1
#define TEXT_LEN_LEN 2

/* Encode postings in the serialized format expected by PostingsWriter, plus 
 * the term vector expected by FieldsWriter. */
void
Kino1_TokenBatch_build_plist(TokenBatch *batch, U32 doc_num, U16 field_num) {
    char     doc_num_buf[4];
    char     field_num_buf[2];
    char     text_len_buf[2];
    char     vint_buf[5];
    HV      *pos_hash;
    HE      *he;
    AV      *out_av;
    I32      i = 0;
    I32      overlap, num_bytes, num_positions;
    I32      num_postings = 0;
    SV     **sv_ptr;
    char    *text, *source_ptr, *dest_ptr, *end_ptr;
    char    *last_text = "";
    STRLEN   text_len, len, fake_len;
    STRLEN   last_len = 0;
    SV      *serialized_sv;
    SV      *tv_string_sv;
    U32     *source_u32, *dest_u32, *end_u32;

    /* prepare doc num and field num in anticipation of upcoming loop */
    Kino1_encode_bigend_U32(doc_num, doc_num_buf);
    Kino1_encode_bigend_U16(field_num, field_num_buf);


    /* build a posting list hash. */
    pos_hash = newHV();
    while (Kino1_TokenBatch_next(batch)) {
        Token* token = batch->current;
        /* either start a new hash entry or retrieve an existing one */
        if (!hv_exists(pos_hash, token->text, token->len)) {
            /* the values are the serialized scalars */
            if (token->len > 65535) 
                Kino1_confess("Maximum token length is 65535; got %d", 
                    token->len);
            Kino1_encode_bigend_U16(token->len, text_len_buf);

            /* allocate the serialized scalar */
            len =   TEXT_LEN_LEN       /* for now, put text_len at top */
                  + KINO_FIELD_NUM_LEN /* encoded field number */
                  + token->len         /* term text */
                  + NULL_BYTE_LEN      /* the term text's null byte */
                  + DOC_NUM_LEN 
                  + POSDATA_LEN
                  + TEXT_LEN_LEN       /* eventually, text_len goes at end */
                  + NULL_BYTE_LEN;     /* the scalar's null byte */ 
            serialized_sv = newSV(len);
            SvPOK_on(serialized_sv);
            source_ptr = SvPVX(serialized_sv);
            dest_ptr   = source_ptr;

            /* concatenate a bunch of stuff onto the serialized scalar */
            Copy(text_len_buf, dest_ptr, TEXT_LEN_LEN, char);
            dest_ptr += TEXT_LEN_LEN;
            Copy(field_num_buf, dest_ptr, KINO_FIELD_NUM_LEN, char);
            dest_ptr += KINO_FIELD_NUM_LEN;
            Copy(token->text, dest_ptr, token->len, char);
            dest_ptr += token->len;
            *dest_ptr = '\0';
            dest_ptr += NULL_BYTE_LEN;
            Copy(doc_num_buf, dest_ptr, DOC_NUM_LEN, char);
            dest_ptr += DOC_NUM_LEN;
            SvCUR_set(serialized_sv, (dest_ptr - source_ptr)); 


            /* store the text => serialized_sv pair in the pos_hash */
            (void)hv_store(pos_hash, token->text, token->len, serialized_sv, 0); 
        }
        else {
            /* retrieve the serialized scalar and allocate more space */
            sv_ptr = hv_fetch(pos_hash, token->text, token->len, 0);
            if (sv_ptr == NULL) 
                Kino1_confess("unexpected null sv_ptr");
            serialized_sv = *sv_ptr;
            len = SvCUR(serialized_sv)
                + POSDATA_LEN    /* allocate space for upcoming posdata */
                + TEXT_LEN_LEN   /* extra space for encoded text length */
                + NULL_BYTE_LEN; 
            SvGROW( serialized_sv, len );
        }

        /* append position, start offset, end offset to the serialized_sv */
        dest_u32 = (U32*)SvEND(serialized_sv);
        *dest_u32++ = (U32)i;
        i += token->pos_inc;
        *dest_u32++ = token->start_offset;
        *dest_u32++ = token->end_offset;
        len = SvCUR(serialized_sv) + POSDATA_LEN;
        SvCUR_set(serialized_sv, len);

        /* destroy the token, because nobody else will -- XXX MAYBE? */
        /* Kino1_Token_destroy(token); */
    }

    /* allocate and presize the array to hold the output */
    num_postings = hv_iterinit(pos_hash);
    out_av = newAV();
    av_extend(out_av, num_postings);

    /* collect serialized scalars into an array */
    i = 0;
    while ((he = hv_iternext(pos_hash))) {
        serialized_sv = HeVAL(he);

        /* transfer text_len to end of serialized scalar */
        source_ptr = SvPVX(serialized_sv);
        dest_ptr   = SvEND(serialized_sv);
        Copy(source_ptr, dest_ptr, TEXT_LEN_LEN, char);
        SvCUR(serialized_sv) += TEXT_LEN_LEN;
        source_ptr += TEXT_LEN_LEN;
        sv_chop(serialized_sv, source_ptr);

        SvREFCNT_inc(serialized_sv);
        av_store(out_av, i, serialized_sv);
        i++;
    }

    /* we're done with the positions hash, so kill it off */
    SvREFCNT_dec(pos_hash);

    /* start the term vector string */
    tv_string_sv = newSV(20);
    SvPOK_on(tv_string_sv);
    num_bytes = Kino1_OutStream_encode_vint(num_postings, vint_buf);
    sv_catpvn(tv_string_sv, vint_buf, num_bytes);

    /* sort the posting lists lexically */
    sortsv(AvARRAY(out_av), num_postings, Perl_sv_cmp);

    /* iterate through the array, making changes to the serialized scalars */
    for (i = 0; i < num_postings; i++) {
        serialized_sv = *(av_fetch(out_av, i, 0));

        /* find the beginning of the term text */
        text = SvPV(serialized_sv, fake_len);
        text += KINO_FIELD_NUM_LEN;

        /* save the text_len; we'll move it forward later */
        end_ptr = SvEND(serialized_sv) - TEXT_LEN_LEN;
        text_len = Kino1_decode_bigend_U16( end_ptr );
        Kino1_encode_bigend_U16(text_len, text_len_buf);

        source_ptr = SvPVX(serialized_sv) + 
            KINO_FIELD_NUM_LEN + text_len + NULL_BYTE_LEN + DOC_NUM_LEN;
        source_u32 = (U32*)source_ptr;
        dest_u32   = source_u32;
        end_u32    = (U32*)end_ptr;

        /* append the string diff to the tv_string */
        overlap = Kino1_StrHelp_string_diff(last_text, text, 
            last_len, text_len);
        num_bytes = Kino1_OutStream_encode_vint(overlap, vint_buf);
        sv_catpvn( tv_string_sv, vint_buf, num_bytes );
        num_bytes = Kino1_OutStream_encode_vint(
            (text_len - overlap), vint_buf );
        sv_catpvn( tv_string_sv, vint_buf, num_bytes );
        sv_catpvn( tv_string_sv, (text + overlap), (text_len - overlap) );

        /* append the number of positions for this term */
        num_positions =   SvCUR(serialized_sv) 
                        - KINO_FIELD_NUM_LEN
                        - text_len 
                        - NULL_BYTE_LEN
                        - DOC_NUM_LEN 
                        - TEXT_LEN_LEN;
        num_positions /= POSDATA_LEN;
        num_bytes = Kino1_OutStream_encode_vint(num_positions, vint_buf);
        sv_catpvn( tv_string_sv, vint_buf, num_bytes );

        while (source_u32 < end_u32) {
            /* keep only the positions in the serialized scalars */
            num_bytes = Kino1_OutStream_encode_vint(*source_u32, vint_buf);
            sv_catpvn( tv_string_sv, vint_buf, num_bytes );
            *dest_u32++ = *source_u32++;

            /* add start_offset to tv_string */
            num_bytes = Kino1_OutStream_encode_vint(*source_u32, vint_buf);
            sv_catpvn( tv_string_sv, vint_buf, num_bytes );
            source_u32++;

            /* add end_offset to tv_string */
            num_bytes = Kino1_OutStream_encode_vint(*source_u32, vint_buf);
            sv_catpvn( tv_string_sv, vint_buf, num_bytes );
            source_u32++;
        }

        /* restore the text_len and close the scalar */
        dest_ptr = (char*)dest_u32;
        Copy(text_len_buf, dest_ptr, TEXT_LEN_LEN, char);
        dest_ptr += TEXT_LEN_LEN;
        len = dest_ptr - SvPVX(serialized_sv);
        SvCUR_set(serialized_sv, len);

        last_text = text;
        last_len  = text_len;
    }
    
    /* store the postings array and the term vector string */
    SvREFCNT_dec(batch->tv_string);
    batch->tv_string = tv_string_sv;
    SvREFCNT_dec(batch->postings);
    batch->postings = out_av;
}

__POD__

=head1 NAME

KinoSearch1::Analysis::TokenBatch - a collection of tokens

=head1 SYNOPSIS

    while ( $batch->next ) {
        $batch->set_text( lc( $batch->get_text ) );
    }

=head1 EXPERIMENTAL API 

TokenBatch's API should be considered experimental and is likely to change.

=head1 DESCRIPTION

A TokenBatch is a collection of L<Tokens|KinoSearch1::Analysis::Token> which
you can add to, then iterate over.  

=head1 METHODS

=head2 new

    my $batch = KinoSearch1::Analysis::TokenBatch->new;

Constructor.

=head2 append 

    $batch->append( $text, $start_offset, $end_offset, $pos_inc );

Add a Token to the end of the batch.  Accepts either three or four arguments:
text, start_offset, end_offset, and an optional position increment which
defaults to 1 if not supplied.  For a description of what these arguments
mean, see the docs for L<Token|KinoSearch1::Analysis::Token>.

=head2 next

    while ( $batch->next ) {
        # ...
    }

Proceed to the next token in the TokenBatch.  Returns true if the TokenBatch
ends up located at valid token.

=head1 ACCESSOR METHODS

All of TokenBatch's accessor methods affect the current Token.  Calling any of
these methods when the TokenBatch is not located at a valid Token will trigger
an exception.

=head2 set_text get_text 

Set/get the text of the current Token.

=head2 set_start_offset get_start_offset

Set/get the start_offset of the current Token.

=head2 set_end_offset get_end_offset

Set/get the end_offset of the current Token.

=head2 set_pos_inc get_pos_inc

Set/get the position increment of the current Token.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

