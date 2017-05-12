package KinoSearch1::Store::InStream;
use base qw( KinoSearch1::Util::CClass );
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;

sub close { CORE::close shift->get_fh }

=for comment
Dupe the filehandle and create a new object around the dupe.  Seek the dupe
to the same spot as the original.

=cut

sub clone_stream {
    my $self = shift;
    open( my $duped_fh, '<&=', $self->get_fh )
        or confess("Couldn't dupe filehandle: $!");
    my $evil_twin
        = __PACKAGE__->new( $duped_fh, $self->get_offset, $self->length, );
    $evil_twin->seek( $self->tell );
    return $evil_twin;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Store::InStream

=begin comment

    my $instream = KinoSearch1::Store::Instream->new( 
        $filehandle, $offset, $length 
    );

Constructor.  Takes 1-3 arguments, and unlike most classes in the KinoSearch1
suite, the arguments to the constructor are not labeled parameters.

The second argument, an offset, defaults to 0 if not supplied.  Non-zero
offsets get factored in when calling seek and tell.

The last argument, a length, is the length of the "file" in bytes.  Supplying
an explicit value is only essential for InStreams which are assigned to read a
portion of a compound file -- otherwise, the length gets auto-calculated
correctly.

=end comment
=cut

InStream*
new(class, fh_sv, ...)
    char   *class;
    SV     *fh_sv;
PREINIT:
    double  offset = 0;
    double  len    = -1;
CODE:
    if (items > 2) {
        SV* offset_sv;
        offset_sv = ST(2);
        if (SvOK(offset_sv))
            offset = SvNV(offset_sv);
    }
    if (items > 3) {
        SV *len_sv;
        len_sv = ST(3);
        if (SvOK(len_sv))
            len = SvNV(len_sv);
    }
    RETVAL = Kino1_InStream_new(class, fh_sv, offset, len);
OUTPUT: RETVAL


=for comment
Seek to target plus the object's start offset.

=cut

void
seek(instream, target)
    InStream *instream;
    double    target;
PPCODE:
    instream->seek(instream, target);

=for comment
Return the filehandle's position minus the offset.

=cut

double
tell(instream)
    InStream *instream;
CODE:
    RETVAL = instream->tell(instream);
OUTPUT: RETVAL

=for comment
Return the length of the "file" in bytes, factoring in the offset.

=cut

double
length(instream)
    InStream *instream;
CODE:
    RETVAL = instream->len;
OUTPUT: RETVAL

=begin comment

    @items = $instream->lu_read( TEMPLATE );

Read the items specified by TEMPLATE from the InStream.

=end comment
=cut

SV*
_set_or_get(instream, ...)
    InStream *instream;
ALIAS:
    set_len      = 1
    get_len      = 2
    set_offset   = 3
    get_offset   = 4
    set_fh       = 5
    get_fh       = 6
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  instream->len = SvNV( ST(1) );
             /* fall through */
    case 2:  RETVAL = newSVnv(instream->len);
             break;
    
    case 3:  instream->offset = SvNV( ST(1) );
             /* fall through */
    case 4:  RETVAL = newSVnv(instream->offset);
             break;
    
    case 5:  Kino1_confess("Can't set_fh");
             /* fall through */
    case 6:  RETVAL = newSVsv(instream->fh_sv);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL


void
lu_read (instream, template_sv)
    InStream *instream;
    SV       *template_sv
PREINIT:
    STRLEN    tpt_len;      /* bytelength of template */
    char     *template;     /* ptr to a spot in the template */
    char     *tpt_end;      /* ptr to the end of the template */
    int       repeat_count; /* number of times to repeat sym */
    char      sym;          /* the current symbol in the template */
    char      countsym;     /* used when calculating repeat counts */
    IV        aIV;
    SV       *aSV;
    char      aChar;
    char*     string;
    STRLEN    len;
PPCODE:
{
    /* prepare template string pointers */
    template    = SvPV(template_sv, tpt_len);
    tpt_end     = SvEND(template_sv);

    repeat_count = 0;
    while (1) {
        if (repeat_count == 0) {
            /* fast-forward past space characters */
            while (*template == ' ' && template < tpt_end) {
                template++;
            }

            /* break out of the loop if we've exhausted the template */
            if (template == tpt_end) {
                break;
            }
            
            /* derive the current symbol and a possible digit repeat sym */
            sym      = *template++;
            countsym = *template;

            if (template == tpt_end) { 
                /* sym is last char in template, so process once */
                repeat_count = 1;
            }
            else if (countsym >= '0' && countsym <= '9') {
                /* calculate numerical repeat count */
                repeat_count = countsym - KINO_NUM_CHAR_OFFSET;
                countsym = *(++template);
                while (  template <= tpt_end 
                      && countsym >= '0' 
                      && countsym <= '9'
                ) {
                    repeat_count = (repeat_count * 10) 
                        + (countsym - KINO_NUM_CHAR_OFFSET);
                    countsym = *(++template);
                }
            }
            else { /* no numeric repeat count, so process sym only once */
                repeat_count = 1;
            }
        }

        /* thwart potential infinite loop */
        if (repeat_count < 1)
            Kino1_confess( "invalid repeat_count: %d", repeat_count);
        
        switch(sym) {

        case 'a': /* arbitrary binary data */
            len = repeat_count;
            repeat_count = 1;
            aSV = newSV(len + 1);
            SvCUR_set(aSV, len);
            SvPOK_on(aSV);
            string = SvPVX(aSV);
            instream->read_bytes(instream, string, len);
            break;

        case 'b': /* signed byte */
        case 'B': /* unsigned byte */
            aChar = instream->read_byte(instream);
            if (sym == 'b') 
                aIV = (signed char)aChar;
            else
                aIV = (unsigned char)aChar;
            aSV = newSViv(aIV);
            break;

        case 'i': /* signed 32-bit integer */
            aSV = newSViv( (I32)instream->read_int(instream) );
            break;
            
        case 'I': /* unsigned 32-bit integer */
            aSV = newSVuv( instream->read_int(instream) );
            break;

        case 'Q': /* unsigned "64-bit integer" */
            aSV = newSVnv( instream->read_long(instream) );
            break;

        case 'T': /* string */
            len = instream->read_vint(instream);
            aSV = newSV(len + 1);
            SvCUR_set(aSV, len);
            SvPOK_on(aSV);
            string = SvPVX(aSV);
            instream->read_chars(instream, string, 0, len);
            break;

        case 'V': /* VInt */
            aSV = newSVuv( instream->read_vint(instream) );
            break;

        case 'W': /* VLong */
            aSV = newSVnv( instream->read_vlong(instream) );
            break;

        default: 
            aSV = NULL; /* suppress unused var compiler warning */
            Kino1_confess("Invalid type in template: '%c'", sym);
        }

        /* Put a scalar on the stack, use up one symbol or repeater */
        XPUSHs( sv_2mortal(aSV) );
        repeat_count -= 1;
    }
}

void
DESTROY(instream)
    InStream *instream;
PPCODE:
    Kino1_InStream_destroy(instream);

__H__


#ifndef H_KINOSEARCH_STORE_INSTREAM
#define H_KINOSEARCH_STORE_INSTREAM 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMathUtils.h"

/* Detect whether we're on an ASCII or EBCDIC machine. */
#if '0' == 240
#define KINO_NUM_CHAR_OFFSET 240
#else
#define KINO_NUM_CHAR_OFFSET 48
#endif

#define KINO_IO_STREAM_BUF_SIZE 1024

typedef struct instream {
    PerlIO  *fh;
    SV      *fh_sv;
    double   offset;
    double   len;
    char    *buf;          
    Off_t    buf_start;    /* file position of start of buffer */
    int      buf_len;      /* number of valid bytes in the buffer */
    int      buf_pos;      /* next byte to read */
    void   (*seek)(struct instream*, double);
    double (*tell)(struct instream*);
    char   (*read_byte)(struct instream*);
    void   (*read_bytes)(struct instream*, char*, STRLEN);
    void   (*read_chars)(struct instream*, char*, STRLEN, STRLEN);
    U32    (*read_int)(struct instream*);
    double (*read_long)(struct instream*);
    U32    (*read_vint)(struct instream*);
    double (*read_vlong)(struct instream*);
} InStream;

InStream* Kino1_InStream_new     (char*, SV*, double, double);
void   Kino1_InStream_seek       (InStream*, double);
double Kino1_InStream_tell       (InStream*);
void   Kino1_InStream_refill     (InStream*);
char   Kino1_InStream_read_byte  (InStream*);
void   Kino1_InStream_read_bytes (InStream*, char*, STRLEN);
void   Kino1_InStream_read_chars (InStream*, char*, STRLEN, STRLEN);
U32    Kino1_InStream_read_int   (InStream*);
double Kino1_InStream_read_long  (InStream*);
U32    Kino1_InStream_decode_vint(char**);
U32    Kino1_InStream_read_vint  (InStream*);
double Kino1_InStream_read_vlong (InStream*);
void   Kino1_InStream_destroy    (InStream*);

#endif /* include guard */

__C__

#include "KinoSearch1StoreInStream.h"


InStream*
Kino1_InStream_new(char *class, SV *fh_sv, double offset, double len ) {
    InStream *instream;

    /* allocate */
    Kino1_New(0, instream, 1, InStream);

    /* assign */
    instream->fh_sv       = newSVsv(fh_sv);
    instream->fh          = IoIFP( sv_2io(fh_sv) );
    instream->offset      = offset;

    /* init buffer */
    instream->buf       = NULL;
    instream->buf_start = 0;
    instream->buf_len   = 0;
    instream->buf_pos   = 0;

    /* seek */
    if (offset != 0) {
        PerlIO_seek(instream->fh, offset, 0);
    }

    /* calculate len if an (intentionally) invalid value was supplied */
    if (len < 0.0) {
        double bookmark = PerlIO_tell(instream->fh);
        PerlIO_seek(instream->fh, 0, 2);
        len = PerlIO_tell(instream->fh);
        PerlIO_seek(instream->fh, bookmark, 0);
    }
    instream->len = len;

    /* assign methods */
    instream->seek       = Kino1_InStream_seek;
    instream->tell       = Kino1_InStream_tell;
    instream->read_byte  = Kino1_InStream_read_byte;
    instream->read_bytes = Kino1_InStream_read_bytes;
    instream->read_chars = Kino1_InStream_read_chars;
    instream->read_int   = Kino1_InStream_read_int;
    instream->read_long  = Kino1_InStream_read_long;
    instream->read_vint  = Kino1_InStream_read_vint;
    instream->read_vlong = Kino1_InStream_read_vlong;

    return instream;
}

void
Kino1_InStream_seek(InStream *instream, double target) {
    /* seek within buffer if possible */
    if (   (target >= instream->buf_start)
        && (target <  (instream->buf_start + instream->buf_pos))
    ) {
        instream->buf_pos = target - instream->buf_start;
    }
    /* nope, not possible, so seek within file and prepare to refill */
    else {
        instream->buf_start = target;
        instream->buf_pos   = 0;
        instream->buf_len   = 0;
        PerlIO_seek(instream->fh, target + instream->offset, 0);
    }
}

double
Kino1_InStream_tell(InStream *instream) {
    return instream->buf_start + instream->buf_pos;
}

void
Kino1_InStream_refill(InStream *instream) {
    int check_val;

    /* wait to allocate buffer until it's needed */
    if (instream->buf == NULL)
        Kino1_New(0, instream->buf, KINO_IO_STREAM_BUF_SIZE, char);

    /* add bytes read to file position, reset */
    instream->buf_start += instream->buf_pos;
    instream->buf_pos = 0;

    /* calculate the number of bytes to read */
    if (KINO_IO_STREAM_BUF_SIZE < instream->len - instream->buf_start)
        instream->buf_len = KINO_IO_STREAM_BUF_SIZE;
    else
        instream->buf_len = instream->len - instream->buf_start;

    /* perform the file operations */
    PerlIO_seek(instream->fh, 0, 1);
    check_val = PerlIO_seek(instream->fh, 
        (instream->buf_start + instream->offset), 0);
    if (check_val == -1)
        Kino1_confess("refill: PerlIO_seek failed: %d", errno);
    check_val = PerlIO_read(instream->fh, instream->buf, instream->buf_len);
    if (check_val != instream->buf_len) 
        Kino1_confess("refill: tried to read %d bytes, got %d: %d", 
            instream->buf_len, check_val, errno);
}

char
Kino1_InStream_read_byte(InStream *instream) {
    if (instream->buf_pos >= instream->buf_len)
        Kino1_InStream_refill(instream);
    return instream->buf[ instream->buf_pos++ ];
}

void
Kino1_InStream_read_bytes (InStream *instream, char* buf, STRLEN len) {
    if (instream->buf_pos + len < instream->buf_len) {
        /* request is entirely within buffer, so copy */
        Copy((instream->buf + instream->buf_pos), buf, len, char);
        instream->buf_pos += len;
    }
    else {
        /* get the request from the file and reset buffer */
        int check_val;
        Off_t start;
        start = instream->tell(instream);
        check_val = PerlIO_seek(instream->fh, (start + instream->offset), 0);
        if (check_val == -1)
            Kino1_confess("read_bytes: PerlIO_seek failed: %d", errno );
        check_val = PerlIO_read(instream->fh, buf, len);
        if (check_val < len)
            Kino1_confess("read_bytes: tried to read %"UVuf" bytes, got %d", 
                (UV)len, check_val);
        
        /* reset vars and refill if there's more in the file */
        instream->buf_start = start + len;
        instream->buf_pos   = 0;
        instream->buf_len   = 0;
        if (instream->buf_start < instream->len)
            Kino1_InStream_refill(instream);
    }
}

/* This is just a wrapper for read_bytes, but that may change.  It should
 * be used whenever Lucene character data is being read, typically after
 * read_vint as part of a String read. If and when a change does come, it will
 * be a lot easier to track down all the relevant code fragments if read_chars
 * gets used consistently. 
 */
void
Kino1_InStream_read_chars(InStream *instream, char *buf, STRLEN start, 
                         STRLEN len) {
    buf += start;
    instream->read_bytes(instream, buf, len);
}

U32
Kino1_InStream_read_int (InStream *instream) {
    unsigned char buf[4];
    instream->read_bytes(instream, (char*)buf, 4);
    return Kino1_decode_bigend_U32(buf);
}

double
Kino1_InStream_read_long (InStream *instream) {
    unsigned char buf[8];
    double        aDouble;

    /* get 8 bytes from the stream */
    instream->read_bytes(instream, (char*)buf, 8);
 
    /* get high 4 bytes, multiply by 2**32 */
    aDouble = Kino1_decode_bigend_U32(buf);
    aDouble = aDouble * pow(2.0, 32.0);
    
    /* decode low four bytes as unsigned int and add to total */
    aDouble += Kino1_decode_bigend_U32(&buf[4]);

    return aDouble;
}

/* read in a Variable INTeger, stored in 1-5 bytes */
U32 
Kino1_InStream_read_vint (InStream *instream) {
    unsigned char aUChar;
    int           bitshift;
    U32           aU32;

    /* start by reading one byte; use the lower 7 bits */
    aUChar = (unsigned char)instream->read_byte(instream);
    aU32 = aUChar & 0x7f;

    /* keep reading and shifting as long as the high bit is set */
    for (bitshift = 7; (aUChar & 0x80) != 0; bitshift += 7) {
        aUChar = (unsigned char)instream->read_byte(instream);
        aU32 |= (aUChar & 0x7f) << bitshift;
    }
    return aU32;
}

U32
Kino1_InStream_decode_vint(char **source_ptr) {
    char *source;
    int   bitshift;
    U32   aU32;
    
    source = *source_ptr;
    aU32 = (unsigned char)*source & 0x7f;
    for (bitshift = 7; (*source & 0x80) != 0; bitshift += 7) {
        source++;
         aU32 |= ((unsigned char)*source & 0x7f) << bitshift;
    }
    source++;
    *source_ptr = source;
    return aU32;
}

double
Kino1_InStream_read_vlong (InStream *instream) {
    unsigned char aUChar;
    int           bitshift;
    double        aDouble;

    aUChar = (unsigned char)instream->read_byte(instream);
    aDouble = aUChar & 0x7f;
    for (bitshift = 7; (aUChar & 0x80) != 0; bitshift += 7) {
        aUChar = (unsigned char)instream->read_byte(instream);
        aDouble += (aUChar & 0x7f) * pow(2, bitshift);
    }
    return aDouble;
}


void
Kino1_InStream_destroy(InStream* instream) {
    SvREFCNT_dec(instream->fh_sv);
    Kino1_Safefree(instream->buf);
    Kino1_Safefree(instream);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Store::InStream - filehandles for reading invindexes

==head1 SYNOPSIS
    
    # isa blessed filehandle
    
    my $instream  = $invindex->open_instream( $filehandle, $offset, $length );
    my @ten_vints = $instream->lu_read('V10');

==head1 DESCRIPTION

The InStream class abstracts out all input operations to KinoSearch1.

InStream is implemented as a inside-out object around a blessed filehandle.
It would almost be possible to use an ordinary filehandle, but the
objectification is necessary because InStreams have to be capable of
pretending that they are acting upon a distinct file when in reality they may
be reading only a portion of a compound file.

For the template used by lu_read, see InStream's companion,
L<OutStream|KinoSearch1::Store::OutStream>.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

