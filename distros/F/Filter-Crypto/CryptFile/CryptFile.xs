/*============================================================================
 *
 * CryptFile/CryptFile.xs
 *
 * DESCRIPTION
 *   C and XS portions of Filter::Crypto::CryptFile module.
 *
 * COPYRIGHT
 *   Copyright (C) 2004-2009, 2012, 2014 Steve Hay.  All rights reserved.
 *
 * LICENCE
 *   This file is free software; you can redistribute it and/or modify it under
 *   the same terms as Perl itself, i.e. under the terms of either the GNU
 *   General Public License or the Artistic License, as specified in the LICENCE
 *   file.
 *
 *============================================================================*/

/*============================================================================
 * C CODE SECTION
 *============================================================================*/


#ifdef WIN32
#  include <io.h>                       /* For _chsize().                     */
#else
#  include <unistd.h>                   /* For ftruncate().                   */
#endif
#include <stdlib.h>                     /* For errno.                         */
#include <string.h>                     /* For strerror() and strlen().       */

#include "../CryptoCommon-c.inc"

/* Define some extra crypt modes.  The decrypt mode and encrypt mode values
 * match the corresponding filter crypto modes, and three new modes are added
 * here for convenience. */
typedef enum {
    FILTER_CRYPTO_MODE_EX_AUTO       = -1,
    FILTER_CRYPTO_MODE_EX_DECRYPT,   /* FILTER_CRYPTO_MODE_DECRYPT value is 0 */
    FILTER_CRYPTO_MODE_EX_ENCRYPT,   /* FILTER_CRYPTO_MODE_ENCRYPT value is 1 */
    FILTER_CRYPTO_MODE_EX_DECRYPTED,
    FILTER_CRYPTO_MODE_EX_ENCRYPTED,
} FILTER_CRYPTO_MODE_EX;

/* The crypt modes are exported to Perl with different names.  We need #define
 * definitions of the names to be exported anyway, otherwise the #ifdef tests
 * done in constant() do not work.  Make the definitions *before* we pull in
 * "const-c.inc" below. */
#define CRYPT_MODE_AUTO      FILTER_CRYPTO_MODE_EX_AUTO
#define CRYPT_MODE_DECRYPT   FILTER_CRYPTO_MODE_EX_DECRYPT
#define CRYPT_MODE_ENCRYPT   FILTER_CRYPTO_MODE_EX_ENCRYPT
#define CRYPT_MODE_DECRYPTED FILTER_CRYPTO_MODE_EX_DECRYPTED
#define CRYPT_MODE_ENCRYPTED FILTER_CRYPTO_MODE_EX_ENCRYPTED

#include "const-c.inc"

/* On systems that do not have chsize() we #define chsize() to be ftruncate() if
 * that's available, or else my_chsize() if F_FREESP is defined (see the
 * my_chsize() and pp_truncate() functions in Perl for details).  Failing that
 * we just have to croak() via a macro with a non-void type to match the context
 * in which chsize() is called. */
#if (!defined(HAS_CHSIZE))
#  ifdef HAS_TRUNCATE
#    define chsize(fd, size) ftruncate((fd), (size))
#  elif defined(F_FREESP)
#    define chsize(fd, size) my_chsize((fd), (size))
#  else
#    define chsize(fd, size) (croak("chsize/truncate not implemented"), 0)
#  endif
#endif

/* On Win32 chsize() is #defined as win32_chsize() when PERL_IMPLICIT_SYS is not
 * #defined, but unfortunately that was mistakenly not exported from the Perl
 * library before Perl 5.8.5.  Therefore, in that situation we have to fall back
 * on the standard Microsoft C library function chsize(), referred to by its
 * Microsoft-specific name _chsize(). */
#if defined(WIN32) && !defined(PERL_IMPLICIT_SYS) && PERL_REVISION == 5 && \
        PERL_VERSION == 8 && PERL_SUBVERSION < 5
#  undef  chsize
#  define chsize(fd, size) _chsize((fd), (size))
#endif

#define FILTER_CRYPTO_SYS_ERR_STR (strerror(errno))

/* Our _crypt_fh() and _crypt_fhs() XSUBs use the typemap INPUT types
 * InputStream, OutputStream and InOutStream for convenience, so we must provide
 * definitions for these "types".                                             */
#ifndef InputStream
  typedef PerlIO* InputStream;
#endif
#ifndef OutputStream
  typedef PerlIO* OutputStream;
#endif
#ifndef InOutStream
  typedef PerlIO* InOutStream;
#endif

static bool FilterCrypto_CryptFh(pTHX_ PerlIO *in_fh, PerlIO *out_fh,
    FILTER_CRYPTO_MODE_EX crypt_mode_ex, SV* num_bytes);
static bool FilterCrypto_OutputData(pTHX_ SV *from_sv, bool encode_mode,
    bool update_mode, PerlIO *to_fh, SV *to_sv, SV* num_bytes);

static const char *filter_crypto_use_text = "use Filter::Crypto::Decrypt;\n";

/*
 * Function to encrypt or decrypt data from one filehandle to either another
 * filehandle or back to itself.
 * Returns a bool to indicate success or failure and sets *num_bytes to the
 * number of bytes written.
 */

static bool FilterCrypto_CryptFh(pTHX_ PerlIO *in_fh, PerlIO *out_fh,
    FILTER_CRYPTO_MODE_EX crypt_mode_ex, SV* num_bytes)
{
    bool encode_mode;
    bool update_mode = FALSE;
    bool have_in_text = FALSE;
    FILTER_CRYPTO_CCTX *ctx;
    FILTER_CRYPTO_MODE crypt_mode;
    SV *in_sv  = sv_2mortal(newSV(BUFSIZ));
    SV *in2_sv = sv_2mortal(newSV(BUFSIZ * 2));
    SV *out_sv = sv_2mortal(newSV(BUFSIZ));
    SV *buf_sv;
    int in_len;
    int buf_len;
    int use_len = strlen(filter_crypto_use_text);
    unsigned char *in_text  = (unsigned char *)SvPVX(in_sv);
    const unsigned char *buf_text;

    SvIOK_only_UV(num_bytes);
    sv_setuv(num_bytes, 0);

    SvPOK_only(in_sv);
    SvPOK_only(in2_sv);
    SvPOK_only(out_sv);

    /* If there is no output filehandle supplied then we are in "update mode",
     * and need to create a temporary output buffer. */
    if (out_fh == (PerlIO *)NULL) {
        update_mode = TRUE;
        buf_sv = sv_2mortal(newSV(BUFSIZ));
        SvPOK_only(buf_sv);
    }

    /* Read as many bytes from the input filehandle as the header line would be
     * if the file were already encrypted.  Compare what we have read with the
     * header line itself: If they match then the input is probably already
     * encrypted. */
    if ((in_len = PerlIO_read(in_fh, in_text, use_len)) < 0) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't read from input filehandle: %s", FILTER_CRYPTO_SYS_ERR_STR
        );
        return FALSE;
    }

#ifdef FILTER_CRYPTO_DEBUG_MODE
    FilterCrypto_HexDump(aTHX_ in_text, in_len,
        "Read %d bytes from input stream", in_len
    );
#endif

    if (in_len == use_len && strnEQ(in_text, filter_crypto_use_text, use_len)) {
        /* The input is probably in an encrypted state. */
        switch (crypt_mode_ex) {
            case FILTER_CRYPTO_MODE_EX_AUTO:
                crypt_mode = FILTER_CRYPTO_MODE_DECRYPT;
                break;

            case FILTER_CRYPTO_MODE_EX_DECRYPT:
                crypt_mode = FILTER_CRYPTO_MODE_DECRYPT;
                break;

            case FILTER_CRYPTO_MODE_EX_ENCRYPT:
                crypt_mode = FILTER_CRYPTO_MODE_ENCRYPT;
                warn("Input data already contains decryption filter");
                break;

            case FILTER_CRYPTO_MODE_EX_DECRYPTED:
                crypt_mode = FILTER_CRYPTO_MODE_DECRYPT;
                break;

            case FILTER_CRYPTO_MODE_EX_ENCRYPTED:
                FilterCrypto_SetErrStr(aTHX_
                    "Input data was already encrypted"
                );
                return TRUE;

            default:
                croak("Unknown crypt mode '%d'", crypt_mode_ex);
        }
    }
    else {
        /* The input is probably in an decrypted state. */
        switch (crypt_mode_ex) {
            case FILTER_CRYPTO_MODE_EX_AUTO:
                crypt_mode = FILTER_CRYPTO_MODE_ENCRYPT;
                break;

            case FILTER_CRYPTO_MODE_EX_DECRYPT:
                crypt_mode = FILTER_CRYPTO_MODE_DECRYPT;
                warn("Input data does not contain decryption filter");
                break;

            case FILTER_CRYPTO_MODE_EX_ENCRYPT:
                crypt_mode = FILTER_CRYPTO_MODE_ENCRYPT;
                break;

            case FILTER_CRYPTO_MODE_EX_DECRYPTED:
                FilterCrypto_SetErrStr(aTHX_
                    "Input data was already decrypted"
                );
                return TRUE;

            case FILTER_CRYPTO_MODE_EX_ENCRYPTED:
                crypt_mode = FILTER_CRYPTO_MODE_ENCRYPT;
                break;

            default:
                croak("Unknown crypt mode '%d'", crypt_mode_ex);
        }
    }

    switch (crypt_mode) {
        case FILTER_CRYPTO_MODE_DECRYPT:
            /* The header line has already been read from the input filehandle,
             * as required.  We can start decrypting the remainder next. */

            /* Set the encode mode to off so that the decrypted data is written
             * out in plain text form. */
            encode_mode = FALSE;

            break;

        case FILTER_CRYPTO_MODE_ENCRYPT:
            /* Write the header line to the output buffer or filehandle before
             * we start encrypting the remainder. */
            if (update_mode) {
                sv_setpvn(buf_sv, filter_crypto_use_text, use_len);

#ifdef FILTER_CRYPTO_DEBUG_MODE
                FilterCrypto_HexDump(aTHX_ filter_crypto_use_text, use_len,
                    "Appended %d-byte header line to output buffer", use_len
                );
#endif
            }
            else {
                if (PerlIO_write(out_fh, filter_crypto_use_text, use_len) <
                        use_len)
                {
                    FilterCrypto_SetErrStr(aTHX_
                        "Can't write header line to output filehandle: %s",
                        FILTER_CRYPTO_SYS_ERR_STR
                    );
                    return FALSE;
                }

#ifdef FILTER_CRYPTO_DEBUG_MODE
                FilterCrypto_HexDump(aTHX_ filter_crypto_use_text, use_len,
                    "Wrote %d-byte header line to output stream", use_len
                );
#endif
            }

            sv_setuv(num_bytes, SvUV(num_bytes) + use_len);

            /* Remember that we have input data in in_text that still needs to
             * be encrypted and output. */
            have_in_text = TRUE;

            /* Set the encode mode to on so that the encrypted data is written
             * out in encoded form (for safe reading back on systems with "text
             * mode" input). */
            encode_mode = TRUE;

            break;

        default:
            croak("Unknown crypt mode '%d'", crypt_mode);
    }

    /* Allocate and initialize the crypto context. */
    ctx = FilterCrypto_CryptoAlloc(aTHX);

    if (!FilterCrypto_CryptoInit(aTHX_ ctx, crypt_mode)) {
        FilterCrypto_CryptoFree(aTHX_ ctx);
        ctx = NULL;
        return FALSE;
    }

    /* Process the (remainder of the) input data. */
    for (;;) {
        if (have_in_text || (in_len = PerlIO_read(in_fh, in_text, BUFSIZ)) > 0)
        {
#ifdef FILTER_CRYPTO_DEBUG_MODE
            if (!have_in_text)
                FilterCrypto_HexDump(aTHX_ in_text, in_len,
                    "Read %d bytes from input stream", in_len
                );
#endif

            have_in_text = FALSE;

            /* We have read a new block of data from the input filehandle into
             * the input SV, so set the input length in the input SV and process
             * it into the output SV. */
            FilterCrypto_SvSetCUR(in_sv, in_len);

            /* If we are decrypting then decode the input SV into the secondary
             * input SV prior to decryption; otherwise just copy it. */
            if (crypt_mode == FILTER_CRYPTO_MODE_DECRYPT) {
                if (!FilterCrypto_DecodeSV(aTHX_ in_sv, in2_sv)) {
                    FilterCrypto_CryptoFree(aTHX_ ctx);
                    ctx = NULL;
                    return FALSE;
                }
            }
            else {
                SvSetSV_nosteal(in2_sv, in_sv);
            }

            if (!FilterCrypto_CryptoUpdate(aTHX_ ctx, in2_sv, out_sv)) {
                FilterCrypto_CryptoFree(aTHX_ ctx);
                ctx = NULL;
                return FALSE;
            }

            /* Write the output to the temporary output buffer or output
             * filehandle as appropriate. */
            if (!FilterCrypto_OutputData(aTHX_ out_sv, encode_mode, update_mode,
                    out_fh, buf_sv, num_bytes))
            {
                FilterCrypto_CryptoFree(aTHX_ ctx);
                ctx = NULL;
                return FALSE;
            }
        }
        else if (in_len == 0) {
            /* We did not read any data from the input stream, and have now
             * reached EOF, so break out of the "for" loop and finalize the
             * crypto context. */
#ifdef FILTER_CRYPTO_DEBUG_MODE
            warn("Reached EOF on input stream\n");
#endif
            break;
        }
        else {
            /* We had a read error, so return failure. */
            FilterCrypto_SetErrStr(aTHX_
                "Can't read from input filehandle: %s",
                FILTER_CRYPTO_SYS_ERR_STR
            );
            FilterCrypto_CryptoFree(aTHX_ ctx);
            ctx = NULL;
            return FALSE;
        }
    }

    /* Encrypt or decrypt the final block (held within the crypto context) into
     * the output SV. */
    if (!FilterCrypto_CryptoFinal(aTHX_ ctx, out_sv)) {
        FilterCrypto_CryptoFree(aTHX_ ctx);
        ctx = NULL;
        return FALSE;
    }

    /* Write the final block of output to the temporary output buffer or output
     * filehandle as appropriate. */
    if (!FilterCrypto_OutputData(aTHX_ out_sv, encode_mode, update_mode, out_fh,
            buf_sv, num_bytes))
    {
        FilterCrypto_CryptoFree(aTHX_ ctx);
        ctx = NULL;
        return FALSE;
    }

    /* Free the crypto context. */
    FilterCrypto_CryptoFree(aTHX_ ctx);
    ctx = NULL;

    /* If we are in update mode then rewind and truncate the filehandle, and
     * write the output buffer back to the filehandle. */
    if (update_mode) {
        PerlIO_rewind(in_fh);
        if (chsize(PerlIO_fileno(in_fh), 0) == -1) {
            FilterCrypto_SetErrStr(aTHX_
                "Can't truncate filehandle: %s", FILTER_CRYPTO_SYS_ERR_STR
            );
            return FALSE;
        }

        buf_text = (const unsigned char *)SvPVX_const(buf_sv);
        buf_len = SvCUR(buf_sv);
        if (PerlIO_write(in_fh, buf_text, buf_len) < buf_len) {
            FilterCrypto_SetErrStr(aTHX_
                "Can't write to filehandle: %s", FILTER_CRYPTO_SYS_ERR_STR
            );
            return FALSE;
        }

#ifdef FILTER_CRYPTO_DEBUG_MODE
        FilterCrypto_HexDump(aTHX_ buf_text, buf_len,
            "Wrote %d-byte output buffer to output stream", buf_len
        );
#endif
    }

    return TRUE;
}

/*
 * Function to output data from a given SV to either a filehandle or to another
 * SV.  The output bytes can be optionally encoded as pairs of hexadecimal
 * digits.  Zeroes the length of the given SV after output.
 * Returns a bool to indicate success or failure and adds the number of bytes
 * written to a third given SV.
 */

static bool FilterCrypto_OutputData(pTHX_ SV *from_sv, bool encode_mode,
    bool update_mode, PerlIO *to_fh, SV *to_sv, SV* num_bytes)
{
    SV *from2_sv = sv_2mortal(newSV(BUFSIZ * 2));
    SvPOK_only(from2_sv);

    /* If we are encoding then encode the from SV into the secondary from SV
     * prior to output; otherwise just copy it. */
    if (encode_mode) {
        FilterCrypto_EncodeSV(aTHX_ from_sv, from2_sv);
    }
    else {
        SvSetSV_nosteal(from2_sv, from_sv);
    }

    if (update_mode) {
        sv_catsv(to_sv, from2_sv);

#ifdef FILTER_CRYPTO_DEBUG_MODE
        FilterCrypto_HexDumpSV(aTHX_ from2_sv,
            "Appended %d bytes to output buffer", SvCUR(from2_sv)
        );
#endif

        sv_setuv(num_bytes, SvUV(num_bytes) + SvCUR(from2_sv));
    }
    else {
        /* Get the data and length to output. */
        const unsigned char *from2_text =
            (const unsigned char *)SvPVX_const(from2_sv);
        int from2_len = SvCUR(from2_sv);

        if (PerlIO_write(to_fh, from2_text, from2_len) < from2_len) {
            FilterCrypto_SetErrStr(aTHX_
                "Can't write to output filehandle: %s",
                FILTER_CRYPTO_SYS_ERR_STR
            );
            return FALSE;
        }

#ifdef FILTER_CRYPTO_DEBUG_MODE
        FilterCrypto_HexDump(aTHX_ from2_text, from2_len,
            "Wrote %d bytes to output stream", from2_len
        );
#endif

        sv_setuv(num_bytes, SvUV(num_bytes) + from2_len);
    }

    FilterCrypto_SvSetCUR(from_sv, 0);

    return TRUE;
}

/*============================================================================*/

MODULE = Filter::Crypto::CryptFile PACKAGE = Filter::Crypto::CryptFile     

#===============================================================================
# XS CODE SECTION
#===============================================================================

PROTOTYPES:   ENABLE
VERSIONCHECK: ENABLE

INCLUDE: const-xs.inc
INCLUDE: ../CryptoCommon-xs.inc

# Private function to expose the FILTER_CRYPTO_DEBUG_MODE constant.

void
_debug_mode();
    PROTOTYPE: 

    PPCODE:
    {
#ifdef FILTER_CRYPTO_DEBUG_MODE
    XSRETURN_YES;
#else
    XSRETURN_EMPTY;
#endif
    }

# Private function to expose the FilterCrypto_CryptFh() function above, as
# called with one in-out filehandle.

void
_crypt_fh(fh, crypt_mode_ex, num_bytes);
    PROTOTYPE: $$$

    INPUT:
        InOutStream fh;
        FILTER_CRYPTO_MODE_EX crypt_mode_ex
        SV* num_bytes

    PPCODE:
    {
        if (FilterCrypto_CryptFh(aTHX_ fh, (PerlIO *)NULL, crypt_mode_ex,
                num_bytes))
            XSRETURN_YES;
        else
            XSRETURN_EMPTY;
    }

# Private function to expose the FilterCrypto_CryptFh() function above, as
# called with one input filehandle and one output filehandle.

void
_crypt_fhs(in_fh, out_fh, crypt_mode_ex, num_bytes);
    PROTOTYPE: $$$$

    INPUT:
        InputStream in_fh;
        OutputStream out_fh;
        FILTER_CRYPTO_MODE_EX crypt_mode_ex;
        SV* num_bytes;

    PPCODE:
    {
        if (FilterCrypto_CryptFh(aTHX_ in_fh, out_fh, crypt_mode_ex, num_bytes))
            XSRETURN_YES;
        else
            XSRETURN_EMPTY;
    }

#===============================================================================
