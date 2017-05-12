package KinoSearch1::Store::OutStream;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

sub close {
    my $self = shift;
    $self->flush;
    CORE::close $self->get_fh;
}

1;

__END__

__XS__

MODULE = KinoSearch1     PACKAGE = KinoSearch1::Store::OutStream

=for comment
Constructor - takes one arg: a filehandle.

=cut

OutStream*
new(class, fh_sv)
    char *class;
    SV   *fh_sv;
CODE:
    RETVAL = Kino1_OutStream_new(class, fh_sv);
OUTPUT: RETVAL

void
seek(outstream, target)
    OutStream *outstream;
    double     target;
PPCODE:
    outstream->seek(outstream, target);

double
tell(outstream)
    OutStream *outstream;
CODE:
    RETVAL = outstream->tell(outstream);
OUTPUT: RETVAL

double
length(outstream)
    OutStream *outstream;
CODE:
    RETVAL = Kino1_OutStream_length(outstream);
OUTPUT: RETVAL

void
flush(outstream);
    OutStream *outstream;
PPCODE:
    Kino1_OutStream_flush(outstream);

=for comment
Write the entire contents of an instream to an outstream.

=cut

void
absorb(outstream, instream)
    OutStream *outstream;
    InStream  *instream;
PPCODE:
    Kino1_OutStream_absorb(outstream, instream);

SV*
_set_or_get(outstream, ...)
    OutStream *outstream;
ALIAS:
    set_fh       = 1
    get_fh       = 2
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  Kino1_confess("Can't set_fh");
             /* fall through */
    case 2:  RETVAL = newSVsv(outstream->fh_sv);
             break;
    
    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL


=begin comment

    $outstream->lu_write( TEMPLATE, LIST );

Write the items in LIST to the OutStream using the serialization schemes
specified by TEMPLATE.

=end comment
=cut

void
lu_write (outstream, template_sv, ...)
    OutStream *outstream;
    SV        *template_sv;
PREINIT:
    STRLEN   tpt_len;      /* bytelength of template */
    char    *template;     /* ptr to a spot in the template */
    char    *tpt_end;      /* ptr to the end of the template */
    int      repeat_count; /* number of times to repeat sym */
    int      item_count;   /* current place in @_ */
    char     sym;          /* the current symbol in the template */
    char     countsym;     /* used when calculating repeat counts */
    I32      aI32;
    U32      aU32;
    double   aDouble;
    SV      *aSV;
    char    *string;
    STRLEN   string_len;
PPCODE:
{
    /* require an object, a template, and at least 1 item */
    if (items < 2) {
        Kino1_confess("lu_write error: too few arguments");
    }

    /* prepare the template and get pointers */
    template = SvPV(template_sv, tpt_len);
    tpt_end  = template + tpt_len;

    /* reject an empty template */
    if (tpt_len == 0) {
        Kino1_confess("lu_write error: TEMPLATE cannot be empty string");
    }
        
    /* init counters */
    repeat_count = 0;
    item_count   = 2;

    while (1) {
        /* only process template if we're not in the midst of a repeat */
        if (repeat_count == 0) {
            /* fast-forward past space characters */
            while (*template == ' ' && template < tpt_end) {
                template++;
            }

            /* if we're done, return or throw error */
            if (template == tpt_end || item_count == items) {
                if (item_count != items) {
                    Kino1_confess(
                      "lu_write error: Too many ITEMS, not enough TEMPLATE");
                }
                else if (template != tpt_end) {
                    Kino1_confess(
                      "lu_write error: Too much TEMPLATE, not enough ITEMS");
                }
                else { /* success! */
                    break;
                }
            }

            /* derive the current symbol and a possible digit repeat sym */
            sym      = *template++;
            countsym = *template;

            if (template == tpt_end) { /* sym is last char in template */
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


        switch(sym) {

        case 'a': /* arbitrary binary data */
            aSV  = ST(item_count);
            if (!SvOK(aSV)) {
                Kino1_confess("Internal error: undef at lu_write 'a'");
            }
            string     = SvPV(aSV, string_len);
            if (repeat_count != string_len) {
                Kino1_confess(
                    "lu_write error: repeat_count != string_len: %d %d", 
                    repeat_count, string_len);
            }
            Kino1_OutStream_write_bytes(outstream, string, string_len);
            /* trigger next sym */
            repeat_count = 1; 
            break;

        case 'b': /* signed byte */
        case 'B': /* unsigned byte */
            aI32 = SvIV( ST(item_count) );
            Kino1_OutStream_write_byte(outstream, (char)(aI32 & 0xff));
            break;

        case 'i': /* signed 32-bit integer */
            aI32 = SvIV( ST(item_count) );
            Kino1_OutStream_write_int(outstream, (U32)aI32);
            break;
            

        case 'I': /* unsigned 32-bit integer */
            aU32 = SvUV( ST(item_count) );
            Kino1_OutStream_write_int(outstream, aU32);
            break;
            
        case 'Q': /* unsigned "64-bit" integer */
            aDouble = SvNV( ST(item_count) );
            Kino1_OutStream_write_long(outstream, aDouble);
            break;
        
        case 'V': /* VInt */
            aU32 = SvUV( ST(item_count) );
            Kino1_OutStream_write_vint(outstream, aU32);
            break;

        case 'W': /* VLong */
            aDouble = SvNV( ST(item_count) );
            Kino1_OutStream_write_vlong(outstream, aDouble);
            break;

        case 'T': /* string */
            aSV        = ST(item_count);
            string     = SvPV(aSV, string_len);
            Kino1_OutStream_write_string(outstream, string, string_len);
            break;

        default: 
            Kino1_confess("Illegal character in template: %c", sym);
        }

        /* use up one repeat_count and one item from the stack */
        repeat_count--;
        item_count++;
    }
}

void
DESTROY(outstream)
    OutStream *outstream;
PPCODE:
    Kino1_OutStream_destroy(outstream);

__H__


#ifndef H_KINOIO
#define H_KINOIO 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMathUtils.h"

typedef struct outstream {
    PerlIO  *fh;
    SV      *fh_sv;
    char    *buf;
    Off_t    buf_start;
    int      buf_pos;
    void   (*seek)        (struct outstream*, double);
    double (*tell)        (struct outstream*);
    void   (*write_byte)  (struct outstream*, char);
    void   (*write_bytes) (struct outstream*, char*, STRLEN);
    void   (*write_int)   (struct outstream*, U32);
    void   (*write_long)  (struct outstream*, double);
    void   (*write_vint)  (struct outstream*, U32);
    void   (*write_vlong) (struct outstream*, double);
    void   (*write_string)(struct outstream*, char*, STRLEN);
} OutStream;

OutStream* Kino1_OutStream_new          (char*, SV*);
void       Kino1_OutStream_seek         (OutStream*, double);
double     Kino1_OutStream_tell         (OutStream*);
double     Kino1_OutStream_length       (OutStream*);
void       Kino1_OutStream_flush        (OutStream*);
void       Kino1_OutStream_absorb       (OutStream*, InStream*);
void       Kino1_OutStream_write_byte   (OutStream*, char);
void       Kino1_OutStream_write_bytes  (OutStream*, char*, STRLEN);
void       Kino1_OutStream_write_int    (OutStream*, U32);
void       Kino1_OutStream_write_long   (OutStream*, double);
void       Kino1_OutStream_write_vint   (OutStream*, U32);
int        Kino1_OutStream_encode_vint  (U32, char*);
void       Kino1_OutStream_write_vlong  (OutStream*, double);
void       Kino1_OutStream_write_string (OutStream*, char*, STRLEN);
void       Kino1_OutStream_destroy      (OutStream*);

#endif /* include guard */


__C__

#include "KinoSearch1StoreOutStream.h"

OutStream*
Kino1_OutStream_new(char* class, SV* fh_sv) {
    OutStream *outstream;

    /* allocate */
    Kino1_New(0, outstream, 1, OutStream);

    /* assign */
    outstream->fh_sv       = newSVsv(fh_sv);
    outstream->fh          = IoOFP( sv_2io(fh_sv) );

    /* init buffer */
    Kino1_New(0, outstream->buf, KINO_IO_STREAM_BUF_SIZE, char);
    outstream->buf_start = 0;
    outstream->buf_pos   = 0;

    /* assign methods */
    outstream->seek         = Kino1_OutStream_seek;
    outstream->tell         = Kino1_OutStream_tell;
    outstream->write_byte   = Kino1_OutStream_write_byte;
    outstream->write_bytes  = Kino1_OutStream_write_bytes;
    outstream->write_int    = Kino1_OutStream_write_int;
    outstream->write_long   = Kino1_OutStream_write_long;
    outstream->write_vint   = Kino1_OutStream_write_vint;
    outstream->write_vlong  = Kino1_OutStream_write_vlong;
    outstream->write_string = Kino1_OutStream_write_string;

    return outstream;

}

void 
Kino1_OutStream_seek(OutStream *outstream, double target) {
    Kino1_OutStream_flush(outstream);
    outstream->buf_start = target;
    PerlIO_seek(outstream->fh, target, 0);
}

double
Kino1_OutStream_tell(OutStream *outstream) {
    return outstream->buf_start + outstream->buf_pos;
}

double
Kino1_OutStream_length(OutStream *outstream) {
    double len;

    /* flush, go to end, note length, return to bookmark */
    Kino1_OutStream_flush(outstream);
    PerlIO_seek(outstream->fh, 0, 2);
    len = PerlIO_tell(outstream->fh);
    PerlIO_seek(outstream->fh, outstream->buf_start, 0);

    return len;
}

void
Kino1_OutStream_flush(OutStream *outstream) {
    PerlIO_write(outstream->fh, outstream->buf, outstream->buf_pos);
    outstream->buf_start += outstream->buf_pos;
    outstream->buf_pos = 0;
}

void 
Kino1_OutStream_absorb(OutStream *outstream, InStream *instream) {
    double  bytes_left, bytes_this_iter;
    char   *buf;
    int     check_val;

    /* flush, then "borrow" the buffer */
    Kino1_OutStream_flush(outstream);
    buf = outstream->buf;
    
    bytes_left = instream->len;

    while (bytes_left > 0) {
        bytes_this_iter = bytes_left < KINO_IO_STREAM_BUF_SIZE 
            ? bytes_left 
            : KINO_IO_STREAM_BUF_SIZE;
        instream->read_bytes(instream, buf, bytes_this_iter);
        check_val = PerlIO_write(outstream->fh, buf, bytes_this_iter);
        if (check_val != bytes_this_iter) {
            Kino1_confess("outstream->absorb error: %"UVuf", %d", 
                (UV)bytes_this_iter, check_val);
        }
        bytes_left -= bytes_this_iter;
        outstream->buf_start += bytes_this_iter;
    }
}

void
Kino1_OutStream_write_byte(OutStream *outstream, char aChar) {
    if (outstream->buf_pos >= KINO_IO_STREAM_BUF_SIZE)
        Kino1_OutStream_flush(outstream);
    outstream->buf[ outstream->buf_pos++ ] = aChar;
}

void
Kino1_OutStream_write_bytes(OutStream *outstream, char *bytes, STRLEN len) {
    /* if this data is larger than the buffer size, flush and write */
    if (len >= KINO_IO_STREAM_BUF_SIZE) {
        int check_val;
        Kino1_OutStream_flush(outstream);
        check_val = PerlIO_write(outstream->fh, bytes, len);
        if (check_val != len) {
            Kino1_confess("Write error: tried to write %"UVuf", got %d", 
                (UV)len, check_val);
        }
        outstream->buf_start += len;
    }
    /* if there's not enough room in the buffer, flush then add */
    else if (outstream->buf_pos + len >= KINO_IO_STREAM_BUF_SIZE) {
        Kino1_OutStream_flush(outstream);
        Copy(bytes, (outstream->buf + outstream->buf_pos), len, char);
        outstream->buf_pos += len;
    }
    /* if there's room, just add these bytes to the buffer */
    else {
        Copy(bytes, (outstream->buf + outstream->buf_pos), len, char);
        outstream->buf_pos += len;
    }
}

void 
Kino1_OutStream_write_int(OutStream *outstream, U32 aU32) {
    unsigned char buf[4];
    Kino1_encode_bigend_U32(aU32, buf);
    outstream->write_bytes(outstream, (char*)buf, 4);
}

void
Kino1_OutStream_write_long(OutStream *outstream, double aDouble) {
    unsigned char buf[8];
    U32 aU32;

    /* derive the upper 4 bytes by truncating a quotient */
    aU32 = floor( ldexp( aDouble, -32 ) );
    Kino1_encode_bigend_U32(aU32, buf);
    
    /* derive the lower 4 bytes by taking a modulus against 2**32 */
    aU32 = fmod(aDouble, (pow(2.0, 32.0)));
    Kino1_encode_bigend_U32(aU32, &buf[4]);

    /* print encoded Long to the output handle */
    outstream->write_bytes(outstream, (char*)buf, 8);
}

void
Kino1_OutStream_write_vint(OutStream *outstream, U32 aU32) {
    char buf[5];
    int num_bytes;
    num_bytes = Kino1_OutStream_encode_vint(aU32, buf);
    outstream->write_bytes(outstream, buf, num_bytes);
}

/* Encode a VInt.  buf must have room for at 5 bytes. 
 */
int
Kino1_OutStream_encode_vint(U32 aU32, char *buf) {
    int num_bytes = 0;

    while ((aU32 & ~0x7f) != 0) {
        buf[num_bytes++] = ( (aU32 & 0x7f) | 0x80 );
        aU32 >>= 7;
    }
    buf[num_bytes++] = aU32 & 0x7f;

    return num_bytes;
}

void
Kino1_OutStream_write_vlong(OutStream *outstream, double aDouble) {
    unsigned char buf[10];
    int num_bytes = 0;
    U32 aU32;

    while (aDouble > 127.0) {
        /* take modulus of num against 128 */
        aU32 = fmod(aDouble, 128);
        buf[num_bytes++] = ( (aU32 & 0x7f) | 0x80 );
        /* right shift for floating point! */
        aDouble = floor( ldexp( aDouble, -7 ) );
    }
    buf[num_bytes++] = aDouble;

    outstream->write_bytes(outstream, (char*)buf, num_bytes);
}

void
Kino1_OutStream_write_string(OutStream *outstream, char *string, STRLEN len) {
    Kino1_OutStream_write_vint(outstream, (U32)len);
    Kino1_OutStream_write_bytes(outstream, string, len);
}

void
Kino1_OutStream_destroy(OutStream *outstream) {
    Kino1_OutStream_flush(outstream);
    SvREFCNT_dec(outstream->fh_sv);
    Kino1_Safefree(outstream->buf);
    Kino1_Safefree(outstream);
}

__POD__


==begin devdocs

==head1 NAME

KinoSearch1::Store::OutStream - filehandles for writing invindexes

==head1 SYNOPSIS

    # isa blessed filehandle

    my $outstream = $invindex->open_outstream( $filename );
    $outstream->lu_write( 'V8', @eight_vints );

==head1 DESCRIPTION

The OutStream class abstracts all of KinoSearch1's output operations.  It is
akin to a narrowly-implemented, specialized IO::File.

Unlike its counterpart InStream, OutStream cannot be assigned an arbitrary
C<length> or C<offset>.

==head2 lu_write / lu_read template

lu_write and it's opposite number, InStream's lu_read, provide a
pack/unpack-style interface for handling primitive data types required by the
Lucene index file format.  The most notable of these specialized data types is
the VInt, or Variable Integer, which is similar to the BER compressed integer
(pack template 'w').

All fixed-width integer formats are stored in big-endian order (high-byte
first).  Signed integers use twos-complement encoding.  The maximum allowable
value both Long and VLong is 2**52 because it is stored inside the NV (double)
storage pocket of a perl Scalar, which has a 53-bit mantissa.
 
    a   Arbitrary binary data, copied to/from the scalar's PV (string)

    b   8-bit  integer, signed
    B   8-bit  integer, unsigned

    i   32-bit integer, signed
    I   32-bit integer, unsigned

    Q   64-bit integer, unsigned                (max value 2**52)

    V   VInt   variable-width integer, unsigned (max value 2**32)
    W   VLong  variable-width integer, unsigned (max value 2**52)

    T   Lucene string, which is a VInt indicating the length in bytes 
        followed by the string.  The string must be valid UTF-8.

Numeric repeat counts are supported:

    $outstream->lu_write( 'V2 T', 0, 1, "a string" );
     
Other features of pack/unpack such as parentheses, infinite repeats via '*',
and slash notation are not.  A numeric repeat count following 'a' indicates
how many bytes to read, while a count following any other symbol indicates how
many scalars of that type to return.

    ( $three_byte_string, @eight_vints ) = $instream->lu_read('a3V8');

The behavior of lu_read and lu_write is much more strict with regards to a
mismatch between TEMPLATE and LIST than pack/unpack, which are fairly
forgiving in what they will accept.  lu_read will confess() if it cannot read
all the items specified by TEMPLATE from the InStream, and lu_write will
confess() if the number of items in LIST does not match the expression in
TEMPLATE.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

