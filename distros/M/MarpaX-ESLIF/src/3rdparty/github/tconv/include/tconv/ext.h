#ifndef TCONV_EXT_H
#define TCONV_EXT_H

#include <stddef.h>
#include <tconv/export.h>

typedef struct tconv *tconv_t;
typedef void (*tconvTraceCallback_t)(void *userDatavp, const char *msgs);

/*****************************/
/* Charset detection options */
/*****************************/
typedef void *(*tconv_charset_new_t) (tconv_t tconvp, void *optionp);
typedef char *(*tconv_charset_run_t) (tconv_t tconvp, void *contextp, char *bytep, size_t bytel);
typedef void  (*tconv_charset_free_t)(tconv_t tconvp, void *contextp);

/* ------------------------- */
/* External charset          */
/* ------------------------- */
typedef struct tconv_charset_external {
  void                *optionp;
  tconv_charset_new_t  tconv_charset_newp;
  tconv_charset_run_t  tconv_charset_runp;
  tconv_charset_free_t tconv_charset_freep;
} tconv_charset_external_t;

/* ------------------------- */
/* Plugin charset            */
/* ------------------------- */
typedef struct tconv_charset_plugin {
  void *optionp;
  char *news;
  char *runs;
  char *frees;
  char *filenames;
} tconv_charset_plugin_t;

/* ------------------------- */
/* Buit-in charset           */
/* ------------------------- */
#include <tconv/charset/cchardet.h>
#include <tconv/charset/ICU.h>

/* ------------------------------- */
/* Global charset option structure */
/* ------------------------------- */
typedef enum tconv_charset_enum {
    /* Default:
       TCONV_CHARSET_ICU if found, else
       TCONV_CHARSET_CCHARDET
    */
    TCONV_CHARSET_EXTERNAL = 0,
    TCONV_CHARSET_PLUGIN,
    TCONV_CHARSET_ICU,
    TCONV_CHARSET_CCHARDET
} tconv_charset_enum_t;

typedef struct tconv_charset {
  tconv_charset_enum_t charseti;
  union {
    tconv_charset_external_t         external;
    tconv_charset_plugin_t           plugin;
    tconv_charset_ICU_option_t      *ICUOptionp;
    tconv_charset_cchardet_option_t *cchardetOptionp;
  } u;
} tconv_charset_t;

/**********************/
/* Conversion options */
/**********************/

typedef void   *(*tconv_convert_new_t) (tconv_t tconvp, const char *tocodes, const char *fromcodes, void *optionp);
typedef size_t  (*tconv_convert_run_t) (tconv_t tconvp, void *contextp, char **inbufsp, size_t *inbytesleftlp, char **outbufsp, size_t *outbytesleftlp);
typedef int     (*tconv_convert_free_t)(tconv_t tconvp, void *contextp);

/* ------------------ */
/* External converter */
/* ------------------ */
typedef struct tconv_convert_external {
  void                 *optionp;
  tconv_convert_new_t  tconv_convert_newp;
  tconv_convert_run_t  tconv_convert_runp;
  tconv_convert_free_t tconv_convert_freep;
} tconv_convert_external_t;

/* ------------------ */
/* Plugin converter   */
/* ------------------ */
typedef struct tconv_convert_plugin {
  void *optionp;
  char *news;
  char *runs;
  char *frees;
  char *filenames;
} tconv_convert_plugin_t;

/* ------------------ */
/* Built-in converter */
/* ------------------ */
#include <tconv/convert/iconv.h>
#include <tconv/convert/ICU.h>

/* --------------------------------- */
/* Global converter option structure */
/* --------------------------------- */
typedef enum tconv_convert_enum {
	/* Default: ICU if found, else ICONV if found, else -1 */
    TCONV_CONVERT_EXTERNAL = 0,
    TCONV_CONVERT_PLUGIN,
    TCONV_CONVERT_ICU,
    TCONV_CONVERT_ICONV
} tconv_convert_enum_t;

typedef struct tconv_convert {
  tconv_convert_enum_t converti;
  union {
    tconv_convert_external_t      external;
    tconv_convert_plugin_t        plugin;
    tconv_convert_ICU_option_t   *ICUOptionp;
    tconv_convert_iconv_option_t *iconvOptionp;
  } u;
} tconv_convert_t;

/* -------------- */
/* Global options */
/* -------------- */
typedef struct tconv_option {
  tconv_charset_t      *charsetp;
  tconv_convert_t      *convertp;
  /* This must be set to have tracing */
  tconvTraceCallback_t  traceCallbackp;
  /* This is the tracing callback opaque data, can be NULL */
  void                 *traceUserDatavp;
  /* Fallback charset when from charset is NULL and guess fails */
  const char           *fallbacks;
} tconv_option_t;

tconv_EXPORT tconv_t tconv_open_ext(const char *tocodes, const char *fromcodes, tconv_option_t *tconvOptionp);

/**********************************************************************/
/* For plugins wanting to trace                                       */
/* If environment variable TCONV_ENV_TRACE exist and is a true value, */
/* then trace is on by default, otherwise it is off by default        */
/**********************************************************************/
tconv_EXPORT void tconv_trace_on(tconv_t tconvp);
tconv_EXPORT void tconv_trace_off(tconv_t tconvp);

/**********************************************************************/
/* The only way to have tracing is:                                   */
/* - trace flag is on                                                 */
/* - traceCallbackp is set                                            */
/* trconv itself will also trace IF it is compiled without #define    */
/* TCONV_NTRACE, including its built-in plugins                       */
/**********************************************************************/
tconv_EXPORT void tconv_trace(tconv_t tconvp, const char *fmts, ...);

/**********************************************************************/
/* Plugins can (and should) set the last error string using           */
/* tconv_error_set(). truncated to 1023 bytes (1 is reserved for NUL).*/
/* At every call to every engine, tconv reset the last error string.  */
/* If any call to any engine fails, and if this string is not set,    */
/* tconv will automatically store the result of last errno string.    */
/*                                                                    */
/* Retreival of last error string is done via tconv_error().          */
/**********************************************************************/
tconv_EXPORT char *tconv_error_set(tconv_t tconvp, const char *msgs);
tconv_EXPORT char *tconv_error(tconv_t tconvp);

/**********************************************************************/
/* Since origin charset may be NULL, it may be interesting to know    */
/* what tconv think it was.                                           */
/* Destination charset is available for symmetry.                     */
/**********************************************************************/
tconv_EXPORT char *tconv_fromcode(tconv_t tconvp);
tconv_EXPORT char *tconv_tocode(tconv_t tconvp);

/**********************************************************************/
/* Helper                                                             */
/**********************************************************************/
typedef struct tconv_helper tconv_helper_t;
typedef short (*tconv_producer_t)(tconv_helper_t *tconv_helperp, void *contextp, char **bufpp, size_t *countlp);
typedef short (*tconv_consumer_t)(tconv_helper_t *tconv_helperp, void *contextp, char *bufp, size_t countl, size_t *countlp);

tconv_EXPORT tconv_helper_t *tconv_helper_newp(tconv_t tconvp, void *contextp, tconv_producer_t producerp, tconv_consumer_t consumerp);
tconv_EXPORT short           tconv_helper_runb(tconv_helper_t *tconv_helperp);
tconv_EXPORT tconv_t         tconv_helper_tconvp(tconv_helper_t *tconv_helperp);
tconv_EXPORT short           tconv_helper_pauseb(tconv_helper_t *tconv_helperp);
tconv_EXPORT short           tconv_helper_endb(tconv_helper_t *tconv_helperp);
tconv_EXPORT short           tconv_helper_stopb(tconv_helper_t *tconv_helperp);
tconv_EXPORT void            tconv_helper_freev(tconv_helper_t *tconv_helperp);

#endif /* TCONV_EXT_H */
