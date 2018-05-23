#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <brotli/decode.h>
#include <brotli/encode.h>

#define BUFFER_SIZE 1048576

typedef struct brotli_decoder {
    BrotliDecoderState *decoder;
}* IO__Uncompress__Brotli;

typedef struct brotli_encoder {
    BrotliEncoderState *encoder;
}* IO__Compress__Brotli;


MODULE = IO::Compress::Brotli		PACKAGE = IO::Uncompress::Brotli
PROTOTYPES: ENABLE

SV*
unbro(buffer, decoded_size)
    SV* buffer
    size_t decoded_size
  PREINIT:
    STRLEN encoded_size;
    uint8_t *encoded_buffer, *decoded_buffer;
  CODE:
    encoded_buffer = (uint8_t*) SvPV(buffer, encoded_size);
    Newx(decoded_buffer, decoded_size, uint8_t);
    if(!BrotliDecoderDecompress(encoded_size, encoded_buffer, &decoded_size, decoded_buffer)){
        croak("Error in BrotliDecoderDecompress");
    }
    RETVAL = newSV(0);
    sv_usepvn(RETVAL, decoded_buffer, decoded_size);
  OUTPUT:
    RETVAL

IO::Uncompress::Brotli
create(class)
    SV* class
  CODE:
    Newx(RETVAL, 1, struct brotli_decoder);
    RETVAL->decoder = BrotliDecoderCreateInstance(NULL, NULL, NULL);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    IO::Uncompress::Brotli self
  CODE:
    BrotliDecoderDestroyInstance(self->decoder);
    Safefree(self);

SV*
decompress(self, in)
    IO::Uncompress::Brotli self
    SV* in
  PREINIT:
    uint8_t *next_in, *next_out, *buffer;
    size_t available_in, available_out;
    BrotliDecoderResult result;
  CODE:
    next_in = (uint8_t*) SvPV(in, available_in);
    Newx(buffer, BUFFER_SIZE, uint8_t);
    RETVAL = newSVpv("", 0);
    result = BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT;
    while(result == BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT) {
        next_out = buffer;
        available_out=BUFFER_SIZE;
        result = BrotliDecoderDecompressStream( self->decoder,
                                                &available_in,
                                                (const uint8_t**) &next_in,
                                                &available_out,
                                                &next_out,
                                                NULL );
        if(!result){
            Safefree(buffer);
            croak("Error in BrotliDecoderDecompressStream");
        }
        sv_catpvn(RETVAL, (const char*)buffer, BUFFER_SIZE-available_out);
    }
    Safefree(buffer);
  OUTPUT:
    RETVAL


MODULE = IO::Compress::Brotli		PACKAGE = IO::Compress::Brotli
PROTOTYPES: ENABLE

SV*
bro(buffer, quality=BROTLI_DEFAULT_QUALITY, lgwin=BROTLI_DEFAULT_WINDOW)
    SV* buffer
    U32 quality
    U32 lgwin
  PREINIT:
    size_t encoded_size;
    STRLEN decoded_size;
    uint8_t *encoded_buffer, *decoded_buffer;
    BROTLI_BOOL result;
  CODE:
    if( quality < BROTLI_MIN_QUALITY || quality > BROTLI_MAX_QUALITY ) {
        croak("Invalid quality value");
    }
    if( lgwin < BROTLI_MIN_WINDOW_BITS || lgwin > BROTLI_MAX_WINDOW_BITS ) {
        croak("Invalid window value");
    }
    decoded_buffer = (uint8_t*) SvPV(buffer, decoded_size);
    encoded_size = BrotliEncoderMaxCompressedSize(decoded_size);
    if(!encoded_size){
        croak("Compressed size overflow");
    }
    Newx(encoded_buffer, encoded_size+1, uint8_t);
    result = BrotliEncoderCompress( quality,
                                    lgwin,
                                    BROTLI_DEFAULT_MODE,
                                    decoded_size,
                                    decoded_buffer,
                                    &encoded_size,
                                    encoded_buffer );
    if(!result){
        Safefree(buffer);
        croak("Error in BrotliEncoderCompress");
    }
    encoded_buffer[encoded_size]=0;
    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, encoded_buffer, encoded_size, SV_SMAGIC | SV_HAS_TRAILING_NUL);
  OUTPUT:
    RETVAL

IO::Compress::Brotli
create(class)
    SV* class
  CODE:
    Newx(RETVAL, 1, struct brotli_encoder);
    RETVAL->encoder = BrotliEncoderCreateInstance(NULL, NULL, NULL);
  OUTPUT:
    RETVAL

bool BrotliEncoderSetParameter(self, value)
    IO::Compress::Brotli self
    U32 value
  ALIAS:
    window  = 1
    quality = 2
    _mode   = 3
  PREINIT:
    BrotliEncoderParameter param;
  INIT:
    switch(ix){
    case 0:
        croak("BrotliEncoderSetParameter may not be called directly");
        break;
    case 1:
        if( value < BROTLI_MIN_WINDOW_BITS || value > BROTLI_MAX_WINDOW_BITS ) {
            croak("Invalid window value");
        }
        param = BROTLI_PARAM_LGWIN;
        break;
    case 2:
        if( value < BROTLI_MIN_QUALITY || value > BROTLI_MAX_QUALITY ) {
            croak("Invalid quality value");
        }
        param = BROTLI_PARAM_QUALITY;
        break;
    case 3:
        /* Validation done on Perl side */
        param = BROTLI_PARAM_MODE;
        break;
    default:
        croak("Impossible ix in BrotliEncoderSetParameter");
        break;
    }
  C_ARGS:
    self->encoder, param, value

SV*
_compress(self, in = &PL_sv_undef)
    IO::Compress::Brotli self
    SV* in
  ALIAS:
    compress = 1
    flush = 2
    finish = 3
  PREINIT:
    uint8_t *next_in, *next_out, *buffer;
    size_t available_in, available_out;
    BROTLI_BOOL result;
    BrotliEncoderOperation op;
  CODE:
    switch(ix) {
    case 0:
        croak("_compress may not be called directly");
        break;
    case 1:
        op = BROTLI_OPERATION_PROCESS;
        break;
    case 2:
        op = BROTLI_OPERATION_FLUSH;
        break;
    case 3:
        op = BROTLI_OPERATION_FINISH;
        break;
    default:
        croak("Impossible ix in _compress");
        break;
    }

    Newx(buffer, BUFFER_SIZE, uint8_t);
    if(in == &PL_sv_undef)
        next_in = (uint8_t*) buffer, available_in = 0;
    else
        next_in = (uint8_t*) SvPV(in, available_in);
    RETVAL = newSVpv("", 0);
    while(1) {
        next_out = buffer;
        available_out = BUFFER_SIZE;
        result = BrotliEncoderCompressStream( self->encoder,
                                              (BrotliEncoderOperation) op,
                                              &available_in,
                                              (const uint8_t**) &next_in,
                                              &available_out,
                                              &next_out,
                                              NULL );
        if(!result) {
            Safefree(buffer);
            croak("Error in BrotliEncoderCompressStream");
        }

        if( available_out != BUFFER_SIZE ) {
            sv_catpvn(RETVAL, (const char*)buffer, BUFFER_SIZE-available_out);
        }

        if(
            BrotliEncoderIsFinished(self->encoder) ||
            (!available_in && !BrotliEncoderHasMoreOutput(self->encoder))
        ) break;
    }
    Safefree(buffer);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    IO::Compress::Brotli self
  CODE:
    BrotliEncoderDestroyInstance(self->encoder);
    Safefree(self);
