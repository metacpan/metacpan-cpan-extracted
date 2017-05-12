/*============================================================================
 *
 * Decrypt/Decrypt.xs
 *
 * DESCRIPTION
 *   C and XS portions of Filter::Crypto::Decrypt module.
 *
 * COPYRIGHT
 *   Copyright (C) 2004-2009, 2012, 2014 Steve Hay.  All rights reserved.
 *
 * LICENCE
 *   You may distribute under the terms of either the GNU General Public License
 *   or the Artistic License, as specified in the LICENCE file.
 *
 *============================================================================*/

/*============================================================================
 * C CODE SECTION
 *============================================================================*/

#include "../CryptoCommon-c.inc"

#define FILTER_CRYPTO_FILTER_COUNT \
    (PL_rsfp_filters ? av_len(PL_rsfp_filters) : 0)

typedef enum {
    FILTER_CRYPTO_STATUS_NOT_STARTED,
    FILTER_CRYPTO_STATUS_STARTED,
    FILTER_CRYPTO_STATUS_FINISHED
} FILTER_CRYPTO_STATUS;

typedef struct {
    MAGIC *mg_ptr;
    FILTER_CRYPTO_CCTX *crypto_ctx;
    SV *encrypt_sv;
    SV *decrypt_sv;
    SV *encode_sv;
    int filter_count;
    FILTER_CRYPTO_STATUS filter_status;
} FILTER_CRYPTO_FCTX;

static I32 FilterCrypto_ReadBlock(pTHX_ int idx, SV *sv, int want_size);
static FILTER_CRYPTO_FCTX *FilterCrypto_FilterAlloc(pTHX);
static bool FilterCrypto_FilterInit(pTHX_ FILTER_CRYPTO_FCTX *ctx,
    FILTER_CRYPTO_MODE crypt_mode);
static bool FilterCrypto_FilterUpdate(pTHX_ FILTER_CRYPTO_FCTX *ctx);
static bool FilterCrypto_FilterFinal(pTHX_ FILTER_CRYPTO_FCTX *ctx);
static void FilterCrypto_FilterFree(pTHX_ FILTER_CRYPTO_FCTX *ctx);
static int FilterCrypto_FilterSvMgFree(pTHX_ SV *sv, MAGIC *mg);
static I32 FilterCrypto_FilterDecrypt(pTHX_ int idx, SV *buf_sv, int max_len);
static bool FilterCrypto_IsDebugPerl(pTHX);
static const char *FilterCrypto_GetErrStr(pTHX);

/* Magic virtual table to have the filter context pointed to by the filter's SV
 * automatically freed when the SV is destroyed. */
static const MGVTBL FilterCrypto_FilterSvMgVTBL = {
    NULL,                           /* Get   */
    NULL,                           /* Set   */
    NULL,                           /* Len   */
    NULL,                           /* Clear */
    FilterCrypto_FilterSvMgFree     /* Free  */
};

/*
 * Function to read exactly want_size bytes (or up to want_size bytes if a read
 * error occurs or EOF is reached) from the specified filter into the given SV.
 * Returns the number of bytes written to the SV, or 0 if EOF was reached before
 * anything was written, or <0 on failure.
 */

static I32 FilterCrypto_ReadBlock(pTHX_ int idx, SV *sv, int want_size) {
    I32 n;
    I32 read_size;

    /* Initialize the number of bytes read to zero. */
    read_size = 0;

    while (1) {
        /* Check if we have read the required number of bytes yet. */
        if (read_size == want_size) {
#ifdef FILTER_CRYPTO_DEBUG_MODE
            FilterCrypto_HexDumpSV(aTHX_ sv,
                "Read %"IVdf" bytes from input stream", (IV)read_size
            );
#endif
            return read_size;
        }

        /* Attempt to read the remaining number of bytes still required. */
        n = FILTER_READ(idx, sv, want_size - read_size);

        /* Check for read errors or EOF. */
        if (n <= 0) {
#ifdef FILTER_CRYPTO_DEBUG_MODE
            FilterCrypto_HexDumpSV(aTHX_ sv,
                "Read %"IVdf" bytes from input stream (%s)",
                (IV)read_size, n < 0 ? "Got read error" : "Reached EOF"
            );
#endif

            if (n < 0)
                FilterCrypto_SetErrStr(aTHX_
                    "Read error on input stream (%"IVdf")\n", (IV)n
                );

            return read_size > 0 ? read_size : n;
        }

#if 0
        if (n < want_size)
            warn("(Read %"IVdf" bytes from input stream)\n", (IV)n);
#endif

        /* Increment read_size by the number of bytes just read. */
        read_size += n;
    }
}

/*
 * Function to allocate a new filter context.
 * Returns a pointer to the allocated structure.
 */

static FILTER_CRYPTO_FCTX *FilterCrypto_FilterAlloc(pTHX) {
    FILTER_CRYPTO_FCTX *ctx;

    /* Allocate the new filter context. */
    Newxz(ctx, 1, FILTER_CRYPTO_FCTX);

    /* Allocate the crypto context. */
    ctx->crypto_ctx = FilterCrypto_CryptoAlloc(aTHX);

    /* Allocate the encrypt, decrypt and encode buffers. */
    ctx->encrypt_sv = newSV(BUFSIZ);
    ctx->decrypt_sv = newSV(BUFSIZ);
    ctx->encode_sv = newSV(BUFSIZ * 2);
    SvPOK_only(ctx->encrypt_sv);
    SvPOK_only(ctx->decrypt_sv);
    SvPOK_only(ctx->encode_sv);

    return ctx;
}

/*
 * Function to initialize the given filter context in the given mode.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_FilterInit(pTHX_ FILTER_CRYPTO_FCTX *ctx,
    FILTER_CRYPTO_MODE crypt_mode)
{
    /* Initialize the crypto context. */
    if (!FilterCrypto_CryptoInit(aTHX_ ctx->crypto_ctx, crypt_mode))
        return FALSE;

    /* Initialize the encrypt, decrypt and encode buffers. */
    FilterCrypto_SvSetCUR(ctx->encrypt_sv, 0);
    FilterCrypto_SvSetCUR(ctx->decrypt_sv, 0);
    FilterCrypto_SvSetCUR(ctx->encode_sv, 0);

    /* Initialize the filter count and status. */
    ctx->filter_count = FILTER_CRYPTO_FILTER_COUNT;
    ctx->filter_status = FILTER_CRYPTO_STATUS_NOT_STARTED;

    return TRUE;
}

/*
 * Function to update the given filter context with encrypted data given in an
 * SV within the filter context.  This data is not assumed to be
 * null-terminated, so the correct length must be set in SvCUR(ctx->encrypt_sv).
 * The decrypted output data will be written into an SV within the filter
 * context.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_FilterUpdate(pTHX_ FILTER_CRYPTO_FCTX *ctx) {
    return FilterCrypto_CryptoUpdate(aTHX_ ctx->crypto_ctx, ctx->encrypt_sv,
            ctx->decrypt_sv);
}

/*
 * Function to finalize the given filter context.  The decrypted output data
 * will be written into an SV within the filter context.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_FilterFinal(pTHX_ FILTER_CRYPTO_FCTX *ctx) {
    return FilterCrypto_CryptoFinal(aTHX_ ctx->crypto_ctx, ctx->decrypt_sv);
}

/*
 * Function to free the given filter context.
 */

static void FilterCrypto_FilterFree(pTHX_ FILTER_CRYPTO_FCTX *ctx) {
    /* Free the encode, decrypt and encrypt buffers by decrementing their
     * reference counts (to zero). */
    SvREFCNT_dec(ctx->encode_sv);
    SvREFCNT_dec(ctx->decrypt_sv);
    SvREFCNT_dec(ctx->encrypt_sv);

    /* Free the crypto context. */
    FilterCrypto_CryptoFree(aTHX_ ctx->crypto_ctx);
    ctx->crypto_ctx = NULL;

    /* Free the filter context. */
    Safefree(ctx);
    ctx = NULL;
}

/*
 * Function to free the filter context pointed to by the given MAGIC.
 * Note: This function's signature and return value are determined by the mgvtbl
 * structure in Perl.
 */

static int FilterCrypto_FilterSvMgFree(pTHX_ SV *sv, MAGIC *mg) {
    FILTER_CRYPTO_FCTX *ctx;

    if ((ctx = (FILTER_CRYPTO_FCTX *)(mg->mg_ptr)) && ctx->mg_ptr == mg) {
        FilterCrypto_FilterFree(aTHX_ ctx);
        ctx = NULL;
        mg->mg_ptr = NULL;
    }
    return 1;
}

/*
 * Function to perform the source code decryption filtering.  Data is first read
 * from the input stream into an encode buffer within the filter context
 * containing a plain ASCII encoding of the encrypted data, and then decoded
 * into an encrypt buffer within the filter context.  It is then decrypted into
 * a decrypt buffer within the filter context, and is finally written to the
 * output stream buffer (which is the buf_sv argument).
 * Returns the number of bytes written to the output stream buffer, or 0 if EOF
 * was reached before anything was written, or croak()s on failure.
 * The filter is deleted when the decryption is finished or an error occurs.
 * Note: This function's signature and return value are determined by the
 * Perl_filter_read() function in Perl.  There is a suggestion there that this
 * function should return <0 on failure, but if that were done then the parser
 * is not actually alerted to the failure (S_filter_gets() simply passes it the
 * NULL pointer in that case), so anything previously written to the output
 * stream buffer (and hence passed onto the parser) will be run without
 * informing the user that there is anything wrong.  Instead, as stated above,
 * we simply croak() on failure.  This is on the advice of Paul Marquess on the
 * "perl5-porters" mailing list, 13 Oct 2004.
 */

static I32 FilterCrypto_FilterDecrypt(pTHX_ int idx, SV *buf_sv, int max_len) {
    FILTER_CRYPTO_FCTX *ctx;
    SV *filter_sv = FILTER_DATA(idx);
    MAGIC *mg;
    I32 m;
    I32 n;
    I32 num_bytes;
    const unsigned char *out_ptr;
    const char *nl = "\n";
    char *p;

    /* Recover the filter context pointer that is held within the MAGIC of the
     * filter's SV, and verify that we have found the correct MAGIC. */
    if (!(mg = mg_find(filter_sv, PERL_MAGIC_ext))) {
        filter_del(FilterCrypto_FilterDecrypt);
        croak("Can't find MAGIC in decryption filter's SV");
    }
    if (!(ctx = (FILTER_CRYPTO_FCTX *)(mg->mg_ptr))) {
        filter_del(FilterCrypto_FilterDecrypt);
        croak("Found wrong MAGIC in decryption filter's SV: No valid mg_ptr");
    }
    if (ctx->mg_ptr != mg) {
        filter_del(FilterCrypto_FilterDecrypt);
        croak("Found wrong MAGIC in decryption filter's SV: Wrong mg_ptr "
              "\"signature\"");
    }

    /* Reinitialize the encode and encrypt buffers. */
    FilterCrypto_SvSetCUR(ctx->encode_sv, 0);
    FilterCrypto_SvSetCUR(ctx->encrypt_sv, 0);

    /* Check if this is the first time through. */
    if (ctx->filter_status == FILTER_CRYPTO_STATUS_NOT_STARTED) {
#ifdef FILTER_CRYPTO_DEBUG_MODE
        warn("Starting filter\n");
#endif

        /* Mild paranoia mode - ensure that no extra filters have been applied
         * on the same line as our filter. */
        if (FILTER_CRYPTO_FILTER_COUNT > ctx->filter_count) {
            filter_del(FilterCrypto_FilterDecrypt);
            croak("Can't run with extra filters");
        }

        ctx->filter_status = FILTER_CRYPTO_STATUS_STARTED;
    }

    while (1) {
        /* If there is anything currently in the decrypt buffer then write (part
         * of) it to the output stream buffer.  How much we write depends on
         * what perl has asked for. */
        if ((m = SvCUR(ctx->decrypt_sv)) > 0) {
            out_ptr = (const unsigned char *)SvPVX_const(ctx->decrypt_sv);

            if (max_len) {
                /* Perl has asked for a block of up to max_len bytes. */
                num_bytes = m > max_len ? max_len : m;

                sv_catpvn(buf_sv, out_ptr, num_bytes);

#ifdef FILTER_CRYPTO_DEBUG_MODE
                FilterCrypto_HexDump(aTHX_ out_ptr, num_bytes,
                    "Wrote block (%"IVdf" bytes) to output stream",
                    (IV)num_bytes
                );
#endif

                /* Chop the number of bytes that we have just written from the
                 * start of the decrypt buffer. */
                sv_chop(ctx->decrypt_sv, (char *)out_ptr + num_bytes);

                /* We have written up to max_len bytes to the output stream
                 * buffer as required, so return the size of that buffer. */
                return SvCUR(buf_sv);
            }
            else {
                /* Perl has asked for a complete line of source code.  We must
                 * not return here if the decrypt buffer does not hold at least
                 * one complete line because perl compiles each line as it is
                 * returned and hence would generate a syntax error if we have
                 * written only part of a line to the output stream buffer.
                 * Instead, we must carry on and read some more data from the
                 * input stream and have another go at completing the line the
                 * next time around. */
                if ((p = ninstr(out_ptr, out_ptr + m, nl, nl + 1))) {
                    /* There is a newline character in the decrypt buffer, so
                     * copy everything up to it to the output stream buffer. */
                    num_bytes = (unsigned char *)p - out_ptr + 1;

                    sv_catpvn(buf_sv, out_ptr, num_bytes);

#ifdef FILTER_CRYPTO_DEBUG_MODE
                    FilterCrypto_HexDump(aTHX_ out_ptr, num_bytes,
                        "Wrote line (%"IVdf" bytes) to output stream "
                        "(Reached EOL)", (IV)num_bytes
                    );
#endif

                    /* Chop the number of bytes that we have just written from
                     * the start of the decrypt buffer. */
                    sv_chop(ctx->decrypt_sv, (char *)out_ptr + num_bytes);

                    /* We have written a complete line to the output stream
                     * buffer as required, so return the size of that buffer. */
                    return SvCUR(buf_sv);
                }
                else {
                    /* There is no newline character in the decrypt buffer, so
                     * copy the whole buffer to the output stream buffer. */
                    num_bytes = m;

                    sv_catpvn(buf_sv, out_ptr, num_bytes);

#ifdef FILTER_CRYPTO_DEBUG_MODE
                    FilterCrypto_HexDump(aTHX_ out_ptr, num_bytes,
                        "Wrote line (%"IVdf" bytes) to output stream "
                        "(Not yet reached EOL)", (IV)num_bytes
                    );
#endif

                    /* Chop the number of bytes that we have just written from
                     * the start of the decrypt buffer. */
                    sv_chop(ctx->decrypt_sv, (char *)out_ptr + num_bytes);

                    /* We have not written a complete line to the output stream
                     * buffer as required, so carry on to try to read some more
                     * data from the input stream. */
                }
            }
        }

        /* If the filter status is finished then either return the size of the
         * output stream buffer if there is anything left in it (for example, an
         * incomplete line that could not be completed because the decrypted
         * source does not end with a newline), or otherwise delete the filter
         * and return zero for EOF. */
        if (ctx->filter_status == FILTER_CRYPTO_STATUS_FINISHED) {
            if (SvCUR(buf_sv)) {
                return SvCUR(buf_sv);
            }
            else {
#ifdef FILTER_CRYPTO_DEBUG_MODE
                warn("Deleting filter\n");
#endif

                filter_del(FilterCrypto_FilterDecrypt);
                return 0;
            }
        }

        /* Clear the decrypt buffer before we start decoding and decrypting data
         * read from the input stream into it and make sure the OOK flag is
         * turned off too in case it was set by the use of sv_chop() above.
         * (Zero the buffer's current length first to avoid the otherwise
         * wasteful copy of data back to the start of the buffer.) */
        FilterCrypto_SvSetCUR(ctx->decrypt_sv, 0);
        SvOOK_off(ctx->decrypt_sv);

        n = FilterCrypto_ReadBlock(aTHX_ idx + 1, ctx->encode_sv, BUFSIZ * 2);
        if (n > 0) {
            /* We have read a new block of data from the input stream into the
             * encode buffer, so set the length of the encode buffer and decode
             * it into the encrypt buffer. */
            FilterCrypto_SvSetCUR(ctx->encode_sv, n);
            if (!FilterCrypto_DecodeSV(aTHX_ ctx->encode_sv, ctx->encrypt_sv)) {
                filter_del(FilterCrypto_FilterDecrypt);
                croak("Can't continue decryption: %s",
                      FilterCrypto_GetErrStr(aTHX));
            }

            /* The decoding succeeded, so zero the encode buffer's length ready
             * for the next call to FilterCrypto_ReadBlock(). */
            FilterCrypto_SvSetCUR(ctx->encode_sv, 0);

            /* We have decoded a new block of data from the encode buffer into
             * the encrypt buffer, so decrypt it into the decrypt buffer. */
            if (!FilterCrypto_FilterUpdate(aTHX_ ctx)) {
                filter_del(FilterCrypto_FilterDecrypt);
                croak("Can't continue decryption: %s",
                      FilterCrypto_GetErrStr(aTHX));
            }

            /* The decryption succeeded, so zero the encrypt buffer's length
             * ready for the next call to FilterCrypto_ReadBlock(). */
            FilterCrypto_SvSetCUR(ctx->encrypt_sv, 0);
        }
        else if (n == 0) {
            /* We did not read any data from the input stream, and have now
             * reached EOF, so decrypt the final block into the decrypt
             * buffer. */
            if (!FilterCrypto_FilterFinal(aTHX_ ctx)) {
                filter_del(FilterCrypto_FilterDecrypt);
                croak("Can't complete decryption: %s",
                      FilterCrypto_GetErrStr(aTHX));
            }

            /* Set the filter status "finished" to remember that we have now
             * read all the data and finalized the crypt context, with the final
             * block written to the decrypt buffer.  All that remains to be done
             * is for that to be written to the output stream buffer. */
            ctx->filter_status = FILTER_CRYPTO_STATUS_FINISHED;
        }
        else {
            /* We had a read error. */
            filter_del(FilterCrypto_FilterDecrypt);
            croak("Can't continue decryption: %s",
                  FilterCrypto_GetErrStr(aTHX));
        }
    }
}

/*
 * Function to determine whether the perl running it is a DEBUGGING build.  This
 * is tested by trying out the "hash dump" debugging feature, which should usurp
 * the built-in values() function if and only if this is a DEBUGGING perl, thus
 * providing a more reliable (though clearly still not infallible) indicator
 * than inspecting the contents of Config.pm.
 *
 * Thanks to Nicholas Clark for this trick.
 */

static bool FilterCrypto_IsDebugPerl(pTHX) {
    return SvTRUE(eval_pv(
        "local $^D = 8192; my %h = (1 => 2); (values %h)[0] == 2 ? 0 : 1", 0
    ));
}

/*
 * Function to get the Perl module's $ErrStr variable.
 */

static const char *FilterCrypto_GetErrStr(pTHX) {
    /* Get the Perl module's $ErrStr variable and return the string in it. */
    return SvPV_nolen_const(get_sv(filter_crypto_errstr_var, TRUE));
}

/*============================================================================*/

MODULE = Filter::Crypto::Decrypt PACKAGE = Filter::Crypto::Decrypt     

#===============================================================================
# XS CODE SECTION
#===============================================================================

PROTOTYPES:   ENABLE
VERSIONCHECK: ENABLE

INCLUDE: ../CryptoCommon-xs.inc

BOOT:
{
#ifndef FILTER_CRYPTO_DEBUG_MODE
    /* C compile-time check that this not a DEBUGGING perl.
     * i.e. built with -DDEBUGGING. */
#  ifdef DEBUGGING
#    error Do not build with DEBUGGING perl!
#  endif

    /* Check that we are not running with DEBUGGING flags enabled.
     * e.g. perl -Dp <script>
     * Do this check before the check for a DEBUGGING perl below because that
     * check currently seems to always trigger this check to fail even though
     * its alteration of $^D is local()ized. */
    if (PL_debug)
        croak("Can't run with DEBUGGING flags");

    /* Check that we are not running under a DEBUGGING perl.
     * i.e. built with -DDEBUGGING. */
    if (FilterCrypto_IsDebugPerl(aTHX))
        croak("Can't run with DEBUGGING perl");

    /* Check that we are not running with the Perl debugger enabled.
     * e.g. perl -d:ptkdb <script> */
    if (PL_perldb)
        croak("Can't run with Perl debugger");

    /* Check that we are not running with the Perl compiler backend enabled.
     * e.g. perl -MO=Deparse <script> */
#  ifndef FILTER_CRYPTO_UNSAFE_MODE
    if (get_sv("B::VERSION", FALSE))
        croak("Can't run with Perl compiler backend");
#  endif
#endif
}

# Import function, automatically called by perl when processing the
# "use Filter::Crypto::Decrypt;" line, to initialize the decryption filter's
# context.

void
import(module, ...)
    PROTOTYPE: $;@

    INPUT:
        SV *module;

    CODE:
    {
        FILTER_CRYPTO_FCTX *ctx;
        SV *filter_sv;
        MAGIC *mg;

        /* Allocate and initialize (in decrypt mode) a filter context. */
        ctx = FilterCrypto_FilterAlloc(aTHX);
        if (!FilterCrypto_FilterInit(aTHX_ ctx, FILTER_CRYPTO_MODE_DECRYPT)) {
            FilterCrypto_FilterFree(aTHX_ ctx);
            ctx = NULL;
            croak("Can't start decryption: %s", FilterCrypto_GetErrStr(aTHX));
        }

        /* Allocate a new SV storing a pointer to the filter context.  Make the
         * SV magical so that the filter context that it stores a pointer to can
         * be automatically freed when the SV is destroyed, and store the
         * pointer within the MAGIC (specifically, as the mg_ptr member) so that
         * it cannot be messed with.
         * Pass 0 as the length of the mg_ptr member-to-be so that it is stored
         * as-is, rather than a savepvn() copy of it being stored. */
        filter_sv = newSV(0);
        if (!(mg = sv_magicext(filter_sv, (SV *)NULL, PERL_MAGIC_ext,
                (MGVTBL *)&FilterCrypto_FilterSvMgVTBL, (char *)ctx, 0)))
        {
            FilterCrypto_FilterFree(aTHX_ ctx);
            ctx = NULL;
            croak("Can't add MAGIC to decryption filter's SV");
        }

        /* Store a pointer back to the MAGIC within the filter context structure
         * itself so that we can verify later that we have retrieved the correct
         * MAGIC from the SV since multiple MAGICs, even of the same type, can
         * be added to a single SV. */
        ctx->mg_ptr = mg;

        /* Add the new SV, together with our FilterCrypto_FilterDecrypt()
         * function, as a new source code filter.  In this way, each filter gets
         * its own decryption context.  This is necessary to avoid clashes
         * between filters that run interleaved, for example, the case of one
         * file require()ing another where both need filtering. */
        filter_add(FilterCrypto_FilterDecrypt, filter_sv);

        /* Increment the filter count to account for our new filter. */
        ctx->filter_count += 1;
    }

#===============================================================================
