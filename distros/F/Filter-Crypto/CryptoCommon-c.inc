/*============================================================================
 *
 * CryptoCommon-c.inc
 *
 * DESCRIPTION
 *   Common C code for Filter::Crypto modules.
 *
 * COPYRIGHT
 *   Copyright (C) 2004-2009, 2012-2014 Steve Hay.  All rights reserved.
 *
 * LICENCE
 *   You may distribute under the terms of either the GNU General Public License
 *   or the Artistic License, as specified in the LICENCE file.
 *
 *============================================================================*/

/* Uncomment (or build with --debug-mode option) for debugging. */
/* #define FILTER_CRYPTO_DEBUG_MODE /**/

/* Uncomment for fixed (dummy) salt and/or IV for debugging purposes. */
/* #define FILTER_CRYPTO_NO_RAND_BYTES /**/

#include <memory.h>                     /* For memset().                      */
#include <stdarg.h>                     /* For va_list/va_start()/va_end().   */
#include <stdio.h>                      /* For snprintf().                    */
#include <stdlib.h>                     /* For atoi() and RAND_MAX.           */
#include <time.h>                       /* For time().                        */

                                        /* For getpid() and pid_t.            */
#ifdef WIN32
#  include <process.h>
#  ifndef __MINGW32__
     typedef int pid_t;
#  endif
#else
#  include <unistd.h>
#endif

/* For the ERR_*(), EVP_*() and RAND_*() functions. */
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

#define PERL_NO_GET_CONTEXT             /* To get interp context efficiently. */
#define PERLIO_NOT_STDIO 0              /* To allow use of PerlIO and stdio.  */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags               /* For SvPV{X}_{nolen_}const().       */
#define NEED_PL_parser                  /* For PL_rsfp_filters.               */
#include "ppport.h"

#include "CipherConfig.h"               /* For the cipher details.            */

                                        /* RAND_MAX does not exist on SunOS.  */
#ifndef RAND_MAX
#  include <limits.h>
#  if INT_MAX == 32767
#    define RAND_MAX 32767
#  else
#    define RAND_MAX 0x7fffffff
#  endif
#endif

                                        /* snprintf() is an IEEE Std          */
                                        /* 1003.1-2001 extension to the ISO C */
                                        /* standard (ISO/IEC 9899:1999), and  */
                                        /* is called _snprintf() on Win32.    */
#ifdef WIN32
#  define snprintf _snprintf
#endif

#define FILTER_CRYPTO_OPENSSL_ERR_STR \
    (ERR_reason_error_string(FilterCrypto_GetLastSSLError()))

                                        /* Macro to set the CUR length in an  */
                                        /* SV whose string space has been     */
                                        /* manipulated directly.  Also adds a */
                                        /* NUL terminator in case the string  */
                                        /* gets used as a C "string" later.   */
#define FilterCrypto_SvSetCUR(sv, len) STMT_START { \
    if (SvPOK(sv)) {                                \
        char * const p = SvPVX(sv);                 \
        SvCUR_set(sv, len);                         \
        p[len] = '\0';                              \
    }                                               \
} STMT_END

#define FILTER_CRYPTO_NEED_RANDOM_SALT FILTER_CRYPTO_USING_PBE
#define FILTER_CRYPTO_NEED_RANDOM_IV   FILTER_CRYPTO_NEED_IV

                                        /* Convert between bytes and          */
                                        /* lowercase hexadecimal digits,      */
                                        /* assuming an ASCII character set.   */
#define B2H(b) (((b) >= 10) ? ('a' - 10 + (b)) : ('0' + (b)))
#define H2B(h) (((h) >= 'a') ? ((h) - 'a' + 10) : ((h) - '0'))

typedef enum {
    FILTER_CRYPTO_MODE_DECRYPT = 0,
    FILTER_CRYPTO_MODE_ENCRYPT
} FILTER_CRYPTO_MODE;

typedef struct {
    EVP_CIPHER_CTX *cipher_ctx;
    SV *salt_sv;
    int required_salt_len;
    SV *iv_sv;
    int required_iv_len;
    FILTER_CRYPTO_MODE crypt_mode;
    bool cipher_initialized;
} FILTER_CRYPTO_CCTX;

static FILTER_CRYPTO_CCTX *FilterCrypto_CryptoAlloc(pTHX);
static bool FilterCrypto_CryptoInit(pTHX_ FILTER_CRYPTO_CCTX *ctx,
    FILTER_CRYPTO_MODE crypt_mode);
static bool FilterCrypto_CryptoInitCipher(pTHX_ FILTER_CRYPTO_CCTX *ctx,
    SV *in_sv, SV *out_sv);
static bool FilterCrypto_CryptoUpdate(pTHX_ FILTER_CRYPTO_CCTX *ctx, SV *in_sv,
    SV *out_sv);
static bool FilterCrypto_CryptoFinal(pTHX_ FILTER_CRYPTO_CCTX *ctx, SV *out_sv);
static void FilterCrypto_CryptoFree(pTHX_ FILTER_CRYPTO_CCTX *ctx);
static bool FilterCrypto_CipherInit(pTHX_ EVP_CIPHER_CTX *ctx, SV *salt_sv,
    SV *iv_sv, FILTER_CRYPTO_MODE crypt_mode);
static bool FilterCrypto_CipherUpdate(pTHX_ EVP_CIPHER_CTX *ctx, SV *in_sv,
    SV *out_sv);
static bool FilterCrypto_CipherFinal(pTHX_ EVP_CIPHER_CTX *ctx, SV *out_sv);
static bool FilterCrypto_PRNGInit(pTHX);
static int FilterCrypto_GetRandNum(pTHX_ int min, int max);
static unsigned long FilterCrypto_GetLastSSLError(void);
static void FilterCrypto_SetErrStr(pTHX_ const char *value, ...);
static void FilterCrypto_EncodeSV(pTHX_ const SV *in_sv, SV *out_sv);
static bool FilterCrypto_DecodeSV(pTHX_ const SV *in_sv, SV *out_sv);
#ifdef FILTER_CRYPTO_DEBUG_MODE
static void FilterCrypto_vHexDump(pTHX_ const unsigned char *data,
    unsigned int len, const char *title, va_list args);
static void FilterCrypto_HexDump(pTHX_ const unsigned char *data,
    unsigned int len, const char *title, ...);
static void FilterCrypto_HexDumpSV(pTHX_ const SV *sv, const char *title, ...);
#endif

/* Fully-qualified name of the relevant Perl module's $ErrStr variable.  This is
 * set at boot time from the (hard-coded) unqualified name and the package name
 * #defined in the individual XS files and is not subsequently changed, so is
 * virtually a "const" and is therefore thread-safe. */
static char *filter_crypto_errstr_var = NULL;

/*
 * Function to allocate a new crypto context.
 * Returns a pointer to the allocated structure.
 */

static FILTER_CRYPTO_CCTX *FilterCrypto_CryptoAlloc(pTHX) {
    FILTER_CRYPTO_CCTX *ctx;

    /* Allocate the new crypto context. */
    Newxz(ctx, 1, FILTER_CRYPTO_CCTX);

    /* Allocate the cipher context. */
    Newxz(ctx->cipher_ctx, 1, EVP_CIPHER_CTX);

    /* Allocate a pair of SVs with enough string space to hold a salt and an
     * initialization vector (IV) respectively, and store their required
     * lengths.  Mark each one as being a string only. */
#if FILTER_CRYPTO_NEED_RANDOM_SALT
    ctx->salt_sv = newSV(PKCS5_SALT_LEN);
    SvPOK_only(ctx->salt_sv);
    ctx->required_salt_len = PKCS5_SALT_LEN;
#endif

#if FILTER_CRYPTO_NEED_RANDOM_IV
    ctx->iv_sv = newSV(EVP_CIPHER_iv_length(FILTER_CRYPTO_CIPHER_FUNC));
    SvPOK_only(ctx->iv_sv);
    ctx->required_iv_len = EVP_CIPHER_iv_length(FILTER_CRYPTO_CIPHER_FUNC);
#endif

    return ctx;
}

/*
 * Function to initialize the given crypto context in the given mode.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CryptoInit(pTHX_ FILTER_CRYPTO_CCTX *ctx,
    FILTER_CRYPTO_MODE crypt_mode)
{
    /* The cipher context gets initialized later (by
     * FilterCrypto_CryptoInitCipher(), called from FilterCrypto_CryptoUpdate())
     * rather than now because we do not necessarily have all the required
     * information to do it now. */

    /* Initialize the salt and IV. */
#if FILTER_CRYPTO_NEED_RANDOM_SALT
    FilterCrypto_SvSetCUR(ctx->salt_sv, 0);
#else
    ctx->salt_sv = (SV *)NULL;
#endif
#if FILTER_CRYPTO_NEED_RANDOM_IV
    FilterCrypto_SvSetCUR(ctx->iv_sv,   0);
#else
    ctx->iv_sv = (SV *)NULL;
#endif

    /* Initialize the crypt mode and cipher context initialization status. */
    ctx->crypt_mode         = crypt_mode;
    ctx->cipher_initialized = FALSE;

    /* Clear the current thread's OpenSSL/SSLeay error queue. */
    ERR_clear_error();

    /* Clear our own last error message. */
    FilterCrypto_SetErrStr(aTHX_ "");
    return TRUE;
}

/*
 * Function to initialize the cipher context within the given crypto context.
 * This is called automatically from FilterCrypto_CryptoUpdate() since when
 * decrypting, a salt and/or an IV may need to be recovered from the given input
 * SV that is passed to FilterCrypto_CryptoUpdate().  In that case, the salt
 * and/or IV will be removed from the start of the input SV, leaving any further
 * data in place for FilterCrypto_CryptoUpdate() to process afterwards.  When
 * encrypting, it may be necessary to have a salt and/or IV randomly generated.
 * In that case, they will be written to the start of the given output SV, which
 * will be grown accordingly to accomodate them as well as the output data that
 * it should already be large enough for.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CryptoInitCipher(pTHX_ FILTER_CRYPTO_CCTX *ctx,
    SV *in_sv, SV *out_sv)
{
    /* If we're using password-based encryption (PBE) then a salt is required
     * for the key derivation.  It must be randomly generated when encrypting,
     * and output with the encrypted data so that it can be read back in and
     * used again for decrypting.  We also need an IV, which must be handled in
     * the same way. */
#if (FILTER_CRYPTO_NEED_RANDOM_SALT || FILTER_CRYPTO_NEED_RANDOM_IV)
    switch (ctx->crypt_mode) {
        case FILTER_CRYPTO_MODE_ENCRYPT: {
#  if FILTER_CRYPTO_NEED_RANDOM_SALT
            unsigned char *salt_text = (unsigned char *)SvPVX(ctx->salt_sv);
#  endif
#  if FILTER_CRYPTO_NEED_RANDOM_IV
            unsigned char *iv_text   = (unsigned char *)SvPVX(ctx->iv_sv);
#  endif

            /* Ensure the pseudo-random number generator (PRNG) is seeded. */
            if (!FilterCrypto_PRNGInit(aTHX))
                return FALSE;

#  if FILTER_CRYPTO_NEED_RANDOM_SALT
#    if defined(FILTER_CRYPTO_NO_RAND_BYTES)
            memset(salt_text, '*', ctx->required_salt_len);
#    else
            if (!RAND_bytes(salt_text, ctx->required_salt_len)) {
                if (!RAND_pseudo_bytes(salt_text, ctx->required_salt_len)) {
                    FilterCrypto_SetErrStr(aTHX_
                        "Can't generate %d-byte random salt: %s",
                        ctx->required_salt_len, FILTER_CRYPTO_OPENSSL_ERR_STR
                    );
                    return FALSE;
                }
                warn("Random salt may not be cryptographically strong");
            }
#    endif
            FilterCrypto_SvSetCUR(ctx->salt_sv, ctx->required_salt_len);

            /* Grow the output SV's buffer enough to hold the salt as well as
             * the output data that it should already be large enough for. */
            SvGROW(out_sv, SvLEN(out_sv) + ctx->required_salt_len);

            sv_catpvn(out_sv, salt_text, ctx->required_salt_len);

#    ifdef FILTER_CRYPTO_DEBUG_MODE
            FilterCrypto_HexDump(aTHX_ salt_text, ctx->required_salt_len,
                "Generated %d-byte salt", ctx->required_salt_len
            );
#    endif
#  endif

#  if FILTER_CRYPTO_NEED_RANDOM_IV
#    if defined(FILTER_CRYPTO_NO_RAND_BYTES)
            memset(iv_text, '*', ctx->required_iv_len);
#    else
            if (!RAND_bytes(iv_text, ctx->required_iv_len)) {
                if (!RAND_pseudo_bytes(iv_text, ctx->required_iv_len)) {
                    FilterCrypto_SetErrStr(aTHX_
                        "Can't generate %d-byte random IV: %s",
                        ctx->required_iv_len, FILTER_CRYPTO_OPENSSL_ERR_STR
                    );
                    return FALSE;
                }
                warn("Random IV may not be cryptographically strong");
            }
#    endif
            FilterCrypto_SvSetCUR(ctx->iv_sv, ctx->required_iv_len);

            /* Grow the output SV's buffer enough to hold the IV as well as the
             * output data that it should already be large enough for. */
            SvGROW(out_sv, SvLEN(out_sv) + ctx->required_iv_len);

            sv_catpvn(out_sv, iv_text, ctx->required_iv_len);

#    ifdef FILTER_CRYPTO_DEBUG_MODE
            FilterCrypto_HexDump(aTHX_ iv_text, ctx->required_iv_len,
                "Generated %d-byte IV", ctx->required_iv_len
            );
#    endif
#  endif

            break;
        }

        case FILTER_CRYPTO_MODE_DECRYPT: {
#  if FILTER_CRYPTO_NEED_RANDOM_SALT
            int missing_salt_len;
#  endif
#  if FILTER_CRYPTO_NEED_RANDOM_IV
            int missing_iv_len;
#  endif
            int in_len;
            const unsigned char *in_text;

#  if FILTER_CRYPTO_NEED_RANDOM_SALT
            missing_salt_len = ctx->required_salt_len - SvCUR(ctx->salt_sv);
            if (missing_salt_len > 0) {
                in_len = SvCUR(in_sv);
                in_text = (const unsigned char *)SvPVX_const(in_sv);
                if (missing_salt_len <= in_len) {
                    sv_catpvn(ctx->salt_sv, in_text, missing_salt_len);
                    sv_chop(in_sv, (char *)in_text + missing_salt_len);
                }
                else {
                    sv_catpvn(ctx->salt_sv, in_text, in_len);
                    FilterCrypto_SvSetCUR(in_sv, 0);

                    /* We have not fully populated the salt yet so just return
                     * success for now.  We'll be called again later. */
                    return TRUE;
                }

#    ifdef FILTER_CRYPTO_DEBUG_MODE
                FilterCrypto_HexDumpSV(aTHX_ ctx->salt_sv,
                    "Recovered %d-byte salt", SvCUR(ctx->salt_sv)
                );
#    endif
            }
#  endif

#  if FILTER_CRYPTO_NEED_RANDOM_IV
            missing_iv_len = ctx->required_iv_len - SvCUR(ctx->iv_sv);
            if (missing_iv_len > 0) {
                in_len = SvCUR(in_sv);
                in_text = (const unsigned char *)SvPVX_const(in_sv);
                if (missing_iv_len <= in_len) {
                    sv_catpvn(ctx->iv_sv, in_text, missing_iv_len);
                    sv_chop(in_sv, (char *)in_text + missing_iv_len);
                }
                else {
                    sv_catpvn(ctx->iv_sv, in_text, in_len);
                    FilterCrypto_SvSetCUR(in_sv, 0);

                    /* We have not fully populated the IV yet so just return
                     * success for now.  We'll be called again later. */
                    return TRUE;
                }

#    ifdef FILTER_CRYPTO_DEBUG_MODE
                FilterCrypto_HexDumpSV(aTHX_ ctx->iv_sv,
                    "Recovered %d-byte IV", SvCUR(ctx->iv_sv)
                );
#    endif
            }
#  endif

            /* Make sure the in_sv's OOK flag is turned off in case it was set
             * by the use of sv_chop() above.  This copies any bytes remaining
             * in in_sv's PV slot to the start of that slot so that they are
             * still available for FilterCrypto_CryptoUpdate(). */
            SvOOK_off(in_sv);

            break;
        }

        default:
            croak("Unknown crypto context mode '%d'", ctx->crypt_mode);
    }
#endif

    if (!FilterCrypto_CipherInit(aTHX_ ctx->cipher_ctx, ctx->salt_sv,
            ctx->iv_sv, ctx->crypt_mode))
        return FALSE;

    ctx->cipher_initialized = TRUE;

    return TRUE;
}

/*
 * Function to update the given crypto context with data in the given input SV.
 * This data is not assumed to be null-terminated, so the correct length must be
 * set in SvCUR(in_sv).  Likewise for the data written into the output SV:
 * SvCUR(out_sv) will be set correctly by this function.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CryptoUpdate(pTHX_ FILTER_CRYPTO_CCTX *ctx, SV *in_sv,
    SV *out_sv)
{
    /* If the cipher context is not yet initialized then use the data in the
     * input SV to initialize it now. */
    if (!ctx->cipher_initialized) {
        if (!FilterCrypto_CryptoInitCipher(aTHX_ ctx, in_sv, out_sv))
            return FALSE;
    }

    /* If there is any data left in the input SV after the above initialization
     * has potentially been run then use it to update the cipher context.
     * Otherwise just return success. */
    if (SvCUR(in_sv))
        return FilterCrypto_CipherUpdate(aTHX_ ctx->cipher_ctx, in_sv, out_sv);
    else
        return TRUE;
}

/*
 * Function to finalize the given crypto context.  The data written into the
 * output SV is not assumed to be null-terminated, so SvCUR(out_sv) will be set
 * correctly by this function.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CryptoFinal(pTHX_ FILTER_CRYPTO_CCTX *ctx, SV *out_sv)
{
    if (ctx->cipher_initialized == TRUE)
        return FilterCrypto_CipherFinal(aTHX_ ctx->cipher_ctx, out_sv);
    else
        return TRUE;
}

/*
 * Function to free the given crypto context.
 */

static void FilterCrypto_CryptoFree(pTHX_ FILTER_CRYPTO_CCTX *ctx) {
    /* Free the IV and salt by decrementing their reference counts (to zero). */
#if FILTER_CRYPTO_NEED_RANDOM_IV
    SvREFCNT_dec(ctx->iv_sv);
#endif
#if FILTER_CRYPTO_NEED_RANDOM_SALT
    SvREFCNT_dec(ctx->salt_sv);
#endif

    /* Free the cipher context. */
    Safefree(ctx->cipher_ctx);
    ctx->cipher_ctx = NULL;

    /* Free the crypto context. */
    Safefree(ctx);
    ctx = NULL;
}

/*
 * Function to initialize the given cipher context in the given mode using the
 * given salt and/or IV if necessary.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CipherInit(pTHX_ EVP_CIPHER_CTX *ctx, SV *salt_sv,
    SV *iv_sv, FILTER_CRYPTO_MODE crypt_mode)
{
    const EVP_CIPHER *cipher_func = FILTER_CRYPTO_CIPHER_FUNC;
#if FILTER_CRYPTO_KEY_LEN == 0
    unsigned char *key = NULL;
#else
    unsigned char key[FILTER_CRYPTO_KEY_LEN];
#endif
#if FILTER_CRYPTO_NEED_RANDOM_SALT
    unsigned char *salt = (unsigned char *)SvPVX(salt_sv);
    int salt_len = SvCUR(salt_sv);
#endif
#if FILTER_CRYPTO_NEED_RANDOM_IV
    unsigned char *iv = (unsigned char *)SvPVX(iv_sv);
#else
    unsigned char *iv = NULL;
#endif

    /* Derive the key from the given password.  PBE should really be initialized
     * with PKCS5_pbe2_set() and EVP_PBE_CipherInit().  The former generates a
     * random IV, while the latter derives a key from the given password by a
     * PKCS#5 v2.0 key derivation algorithm (via PKCS5_v2_PBE_keyivgen() and
     * ultimately PKCS5_PBKDF2_HMAC_SHA1()).  There is currently (as of 0.9.7e)
     * a problem with PKCS5_pbe2_set() in that the IV cannot be user-specified,
     * but this could be overcome by DER-encoding the X509_ALGOR structure
     * returned by it and writing/reading this when encrypting/decrypting as we
     * currently do with the salt and/or IV.  However, there is another problem,
     * with PKCS5_v2_PBE_keyivgen(), which cannot be overcome so easily: it only
     * works with the default key length of the given cipher, so we would lose
     * the ability to set the key length differently for those algorithms with
     * variable key lengths.  There are also problems using EVP_PBE_CipherInit()
     * at all with some ciphers because it relies on the ASN1 code, which, as
     * the "BUGS" section of the EVP_EncryptInit.pod in recent OpenSSL
     * distributions says, is incomplete and sometimes inaccurate.  Therefore,
     * we use the standard EVP_CipherInit[_ex]() functions, and call
     * PKCS5_PBKDF2_HMAC_SHA1() directly ourselves to do the PKCS#5 v2.0 key
     * derivation.
     * See the exchanges between myself and Steve Henson on the "openssl-users"
     * mailing list, 08-13 Sep 2004, for more details on all of this. */

    /* The EVP library API has facilities for modifying the key length for
     * variable key length ciphers and for modifying other cipher parameters, so
     * to start with we just specify which cipher we are using.  Then we can set
     * the key length and other parameters in the cipher context structure thus
     * created, and then finally derive the key and set both it and the IV in
     * the cipher context structure. */
#  if FILTER_CRYPTO_OPENSSL_VERSION < 90700
    if (!EVP_CipherInit(ctx, cipher_func, NULL, NULL, crypt_mode)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't initialize cipher context in crypt mode '%d': %s",
            crypt_mode, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  else
    EVP_CIPHER_CTX_init(ctx);

    if (!EVP_CipherInit_ex(ctx, cipher_func, NULL, NULL, NULL, crypt_mode)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't initialize cipher context in crypt mode '%d': %s",
            crypt_mode, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  endif

    /* Now we can modify the parameters for the chosen cipher.  First, set the
     * key length. */
    if (!EVP_CIPHER_CTX_set_key_length(ctx, FILTER_CRYPTO_KEY_LEN)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't set key length to %d: %s",
            FILTER_CRYPTO_KEY_LEN, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }

    /* Now modify any other cipher-specific parameters that we have. */
#  if defined(FILTER_CRYPTO_RC2_KEY_BITS)
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_SET_RC2_KEY_BITS,
            FILTER_CRYPTO_RC2_KEY_BITS, NULL))
    {
        FilterCrypto_SetErrStr(aTHX_
            "Can't set RC2 effective key bits to %d: %s",
            FILTER_CRYPTO_RC2_KEY_BITS, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  elif defined(FILTER_CRYPTO_RC5_ROUNDS)
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_SET_RC5_ROUNDS,
            FILTER_CRYPTO_RC5_ROUNDS, NULL))
    {
        FilterCrypto_SetErrStr(aTHX_
            "Can't set RC5 number of rounds to %d: %s",
            FILTER_CRYPTO_RC5_ROUNDS, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  endif

    /* We have finished modifying the cipher parameters, so we can now
     * finish the initialization of the cipher context by deriving the key
     * and setting both it and the IV. */
#  if FILTER_CRYPTO_USING_PBE
    if (PKCS5_PBKDF2_HMAC_SHA1(filter_crypto_pswd, sizeof(filter_crypto_pswd),
            salt, salt_len, PKCS5_DEFAULT_ITER, FILTER_CRYPTO_KEY_LEN, key) !=
            1)
    {
        FilterCrypto_SetErrStr(aTHX_
            "Can't derive %d-byte key: %s",
            FILTER_CRYPTO_KEY_LEN, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  else
    Copy(filter_crypto_key, key, FILTER_CRYPTO_KEY_LEN, unsigned char);
#  endif

#  if FILTER_CRYPTO_OPENSSL_VERSION < 90700
    if (!EVP_CipherInit(ctx, NULL, key, iv, crypt_mode)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't initialize cipher context in crypt mode '%d' using %d-byte "
            "key: %s",
            crypt_mode, FILTER_CRYPTO_KEY_LEN, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  else
    if (!EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, crypt_mode)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't initialize cipher context in crypt mode '%d' using %d-byte "
            "key: %s",
            crypt_mode, FILTER_CRYPTO_KEY_LEN, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#  endif

    /* Wipe the key from memory now that it has been set in the cipher context.
     * It's still around somewhere, of course, but at least this is one place
     * less that it might be found. */
    Poison(key, FILTER_CRYPTO_KEY_LEN, unsigned char);

    return TRUE;
}

/*
 * Function to update the given cipher context with the data in the given input
 * SV.  This data is not assumed to be null-terminated, so the correct length
 * must be set in SvCUR(in_sv).  Likewise for the data written into the output
 * SV: SvCUR(out_sv) will be set correctly by this function.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CipherUpdate(pTHX_ EVP_CIPHER_CTX *ctx, SV *in_sv,
    SV *out_sv)
{
#if FILTER_CRYPTO_OPENSSL_VERSION < 90700
    unsigned char *in_text = (unsigned char *)SvPVX(in_sv);
#else
    const unsigned char *in_text = (const unsigned char *)SvPVX_const(in_sv);
#endif
    unsigned char *out_text;
    int in_len = SvCUR(in_sv);
    int orig_out_len;
    int out_len;

    /* Up to in_len + EVP_CIPHER_CTX_block_size(ctx) - 1 bytes may be written
     * when encrypting, and up to in_len + EVP_CIPHER_CTX_block_size(ctx) bytes
     * may be written when decrypting, so ensure that the output buffer is big
     * enough (plus space for a NUL terminator). */
    out_text = (unsigned char *)SvGROW(
        out_sv, (STRLEN)(in_len + EVP_CIPHER_CTX_block_size(ctx) + 1)
    );

    /* Advance the out_text pointer to the end of any existing output since the
     * output buffer may already have a salt and/or an IV in it if we have just
     * initialized an encryption process. */
    orig_out_len = SvCUR(out_sv);
    out_text += orig_out_len;

    if (!EVP_CipherUpdate(ctx, out_text, &out_len, in_text, in_len)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't update cipher context with %d bytes of in-text: %s",
            in_len, FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }

#ifdef FILTER_CRYPTO_DEBUG_MODE
    FilterCrypto_HexDump(aTHX_ out_text, out_len,
        "Converted %d bytes to %d bytes", in_len, out_len
    );
#endif

    /* Set the output length in the output SV, again accounting for any output
     * that already existed. */
    FilterCrypto_SvSetCUR(out_sv, orig_out_len + out_len);

    return TRUE;
}

/*
 * Function to finalize the given cipher context.  The data written into the
 * output SV is not assumed to be null-terminated, so SvCUR(out_sv) will be set
 * correctly by this function.
 * Returns a bool to indicate success or failure.
 */

static bool FilterCrypto_CipherFinal(pTHX_ EVP_CIPHER_CTX *ctx, SV *out_sv) {
    unsigned char *out_text;
    int out_len;

    /* Up to EVP_CIPHER_CTX_block_size(ctx) bytes may be written when encrypting
     * or decrypting, so ensure that the output buffer is big enough (plus space
     * for a NUL terminator). */
    out_text = (unsigned char *)SvGROW(
        out_sv, (STRLEN)(EVP_CIPHER_CTX_block_size(ctx) + 1)
    );

#if FILTER_CRYPTO_OPENSSL_VERSION < 90700
    if (!EVP_CipherFinal(ctx, out_text, &out_len)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't finalize cipher context: %s", FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#else
    if (!EVP_CipherFinal_ex(ctx, out_text, &out_len)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't finalize cipher context: %s", FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }

    if (!EVP_CIPHER_CTX_cleanup(ctx)) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't cleanup cipher context: %s", FILTER_CRYPTO_OPENSSL_ERR_STR
        );
        return FALSE;
    }
#endif

#ifdef FILTER_CRYPTO_DEBUG_MODE
    FilterCrypto_HexDump(aTHX_ out_text, out_len,
        "Converted final block to %d bytes", out_len
    );
#endif

    /* Set the output length in the output SV. */
    FilterCrypto_SvSetCUR(out_sv, out_len);

    return TRUE;
}

/*
 * Function to initialize the OpenSSL PRNG.
 * Returns a bool to indicate success or failure.
 *
 * This function is based on code taken from the ssl_rand_seed() function in
 * Apache httpd (version 2.4.9).
 */

static bool FilterCrypto_PRNGInit(pTHX) {
    /* The PRNG is seeded transparently for us on some OSes (e.g. using UNIX's
     * /dev/urandom or /dev/random devices or Win32's Crypto API) in some
     * versions of OpenSSL and SSLeay, but in other cases we must do it
     * manually.  RAND_status() reports whether the PRNG is seeded. */
    if (RAND_status())
        return TRUE;

    /* Win32 has a RAND_screen() function for seeding the PRNG.  In other cases
     * we just have to manage ourselves. */
#ifdef WIN32
    RAND_screen();
#else
    {
        struct {
            time_t t;
            pid_t pid;
        } my_seed;
        int n;
        unsigned char stackdata[256];

        my_seed.t = time(NULL);
        my_seed.pid = getpid();
        RAND_seed((unsigned char *)&my_seed, sizeof(my_seed));

        n = FilterCrypto_GetRandNum(aTHX_ 0, sizeof(stackdata) - 128 - 1);
        RAND_seed(stackdata + n, 128);
    }
#endif

    /* Check whether we have seeded the PRNG with enough entropy. */
    if (RAND_status()) {
        return TRUE;
    }
    else {
        FilterCrypto_SetErrStr(aTHX_ "Can't initialize PRNG");
        return FALSE;
    }
}

/*
 * Function to return a random number between min and max.
 *
 * This function is based on the ssl_rand_choosenum() function in Apache httpd
 * (version 2.4.9).
 */

static int FilterCrypto_GetRandNum(pTHX_ int min, int max) {
    char buf[50];
    int n;

    seedDrand01((Rand_seed_t)time(NULL));
    PL_srand_called = TRUE;

    snprintf(buf, sizeof(buf), "%.0f", Drand01() * (max - min));

    n = atoi(buf) + 1;

    if (n < min)
        n = min;

    if (n > max)
        n = max;

    return n;
}

/*
 * Function to get the last (most recent) OpenSSL error from the current
 * thread's error queue.
 */

static unsigned long FilterCrypto_GetLastSSLError(void) {
#if FILTER_CRYPTO_OPENSSL_VERSION >= 90700
    return ERR_peek_last_error();
#else
    unsigned long err;
    unsigned long last_err = 0;
    /* There are no ERR_peek_last_*() functions before 0.9.7, so we have to get
     * the errors (removing them from the queue) from the earliest to the last
     * instead.  We probably ought to put them back again afterwards, but it
     * does not really matter. */
    while ((err = ERR_get_error()))
        last_err = err;
    return last_err;
#endif
}

/*
 * Function to set the relevant Perl module's $ErrStr variable to the given
 * value.
 */

static void FilterCrypto_SetErrStr(pTHX_ const char *value, ...) {
    va_list args;

    /* Get the relevant Perl module's $ErrStr variable and set an appropriate
     * value in it. */
    va_start(args, value);
    sv_vsetpvf(get_sv(filter_crypto_errstr_var, TRUE), value, &args);
    va_end(args);
}

/*
 * Function to encode the text from one SV into another SV.  Each byte is
 * encoded as a pair of hexadecimal digits.
 */

static void FilterCrypto_EncodeSV(pTHX_ const SV *in_sv, SV *out_sv)
{
    const unsigned char *in_text;
    unsigned char *out_text;
    STRLEN in_len;
    STRLEN out_len;
    unsigned int i;

    /* Clear the output SV before encoding into it. */
    FilterCrypto_SvSetCUR(out_sv, 0);

    in_text = (const unsigned char *)SvPVX_const(in_sv);
    out_text = (unsigned char *)SvPVX(out_sv);
    in_len = SvCUR(in_sv);
    out_len = SvCUR(out_sv);

    for (i = 0; i < in_len; i++) {
        out_text[2 * i]     = B2H((in_text[i] & 0xf0) >> 4);
        out_text[2 * i + 1] = B2H( in_text[i] & 0x0f);
        out_len += 2;
    }

#ifdef FILTER_CRYPTO_DEBUG_MODE
    FilterCrypto_HexDump(aTHX_ out_text, out_len,
        "Encoded %d bytes to %d bytes", in_len, out_len
    );
#endif

    /* Set the output length in the output SV. */
    FilterCrypto_SvSetCUR(out_sv, out_len);
}

/*
 * Function to decode the text from one SV into another SV.  Inverse function
 * of FilterCrypto_EncodeSV().
 */

static bool FilterCrypto_DecodeSV(pTHX_ const SV *in_sv, SV *out_sv) {
    const unsigned char *in_text;
    unsigned char *out_text;
    STRLEN in_len;
    STRLEN out_len;
    unsigned int i;

    /* Clear the output SV before decoding into it. */
    FilterCrypto_SvSetCUR(out_sv, 0);

    in_text = (const unsigned char *)SvPVX_const(in_sv);
    out_text = (unsigned char *)SvPVX(out_sv);
    in_len = SvCUR(in_sv);
    out_len = SvCUR(out_sv);

    if (in_len % 2) {
        FilterCrypto_SetErrStr(aTHX_
            "Can't decode odd-numbered (%d-byte) length hexadecimal text",
            in_len
        );
        return FALSE;
    }

    for (i = 0; i < in_len; i++) {
        if (!isXDIGIT(in_text[i])) {
            FilterCrypto_SetErrStr(aTHX_
                "Can't decode non-hexadecimal digit (byte %02x at position %d) "
                "in hexadecimal text", in_text[i], i + 1
            );
            return FALSE;
        }
    }

    for (i = 0; i < in_len; i += 2) {
        out_text[i/2] = (H2B(in_text[i]) << 4) | H2B(in_text[i + 1]);
        out_len++;
    }

#ifdef FILTER_CRYPTO_DEBUG_MODE
    FilterCrypto_HexDump(aTHX_ out_text, out_len,
        "Decoded %d bytes to %d bytes", in_len, out_len
    );
#endif

    /* Set the output length in the output SV. */
    FilterCrypto_SvSetCUR(out_sv, out_len);

    return TRUE;
}

#ifdef FILTER_CRYPTO_DEBUG_MODE
/*
 * Function to print a dump of the given data.  Each character (octet) is shown
 * as itself if it is "printable"; otherwise it is shown as its hexadecimal
 * code.  An optional title can be printed first.  Pass NULL as the third
 * argument to omit the title.
 * Use this via either FilterCrypto_HexDump() or FilterCrypto_HexDumpSV().
 */

static void FilterCrypto_vHexDump(pTHX_ const unsigned char *data,
    unsigned int len, const char *title, va_list args)
{
    unsigned int i;

    if (title) {
        PerlIO_vprintf(PerlIO_stderr(), title, args);
        PerlIO_printf(PerlIO_stderr(), ":\n");
    }

    for (i = 0; i < len; ++i) {
        if (i % 16 == 0)
            PerlIO_printf(PerlIO_stderr(), "%s%08x", i == 0 ? "" : "\n", i);

        if (data[i] >= 32 && data[i] <= 127)
            PerlIO_printf(PerlIO_stderr(), " %2c", data[i]);
        else
            PerlIO_printf(PerlIO_stderr(), " %02x", data[i]);
    }

    PerlIO_printf(PerlIO_stderr(), "%s%08x\n", i == 0 ? "" : "\n", i);
}

/*
 * Function to print a dump of the given data.
 */

static void FilterCrypto_HexDump(pTHX_ const unsigned char *data,
    unsigned int len, const char *title, ...)
{
    va_list args;

    va_start(args, title);
    FilterCrypto_vHexDump(aTHX_ data, len, title, args);
    va_end(args);
}

/*
 * Function to print a dump of the data in the given SV.
 */

static void FilterCrypto_HexDumpSV(pTHX_ const SV *sv, const char *title, ...) {
    STRLEN len;
    const unsigned char *data;
    va_list args;

    data = (const unsigned char *)SvPVX_const(sv);
    len = SvCUR(sv);
    va_start(args, title);
    FilterCrypto_vHexDump(aTHX_ data, len, title, args);
    va_end(args);
}
#endif

/*============================================================================*/
