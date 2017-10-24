#define PERL_NO_GET_CONTEXT 1     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <marpaESLIF.h>
#include <genericLogger.h>
#include <genericStack.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

#include "c-constant-types.inc"
#include "c-event-types.inc"
#include "c-value-types.inc"
#include "c-loggerLevel-types.inc"
#include "c-rulePropertyBitSet-types.inc"
#include "c-symbolPropertyBitSet-types.inc"
#include "c-symbol-types.inc"

/* Perl wrapper around malloc, free, etc... are just painful for genericstack, which is */
/* is implemented using header files, not a library... */
#ifdef malloc
#define current_malloc malloc
#endif
#ifdef calloc
#define current_calloc calloc
#endif
#ifdef realloc
#define current_realloc realloc
#endif
#ifdef free
#define current_free free
#endif
#ifdef memset
#define current_memset memset
#endif
#ifdef memcpy
#define current_memcpy memcpy
#endif
#ifdef memmove
#define current_memmove memmove
#endif

#undef malloc
#undef calloc
#undef realloc
#undef free
#undef memset
#undef memcpy
#undef memmove

static void *marpaESLIF_GENERICSTACK_NEW() {
  genericStack_t *stackp;

  GENERICSTACK_NEW(stackp);

  return stackp;
}

static void marpaESLIF_SYSTEM_FREE(void *p) {
  free(p);
}

static void marpaESLIF_GENERICSTACK_FREE(genericStack_t *stackp) {
  GENERICSTACK_FREE(stackp);
}

static void *marpaESLIF_GENERICSTACK_GET_PTR(genericStack_t *stackp, int indicei) {
  return GENERICSTACK_GET_PTR(stackp, indicei);
}

static void *marpaESLIF_GENERICSTACK_POP_PTR(genericStack_t *stackp) {
  return GENERICSTACK_POP_PTR(stackp);
}

static short marpaESLIF_GENERICSTACK_IS_PTR(genericStack_t *stackp, int indicei) {
  return GENERICSTACK_IS_PTR(stackp, indicei);
}

static void marpaESLIF_GENERICSTACK_PUSH_PTR(genericStack_t *stackp, void *p) {
  GENERICSTACK_PUSH_PTR(stackp, p);
}

static void marpaESLIF_GENERICSTACK_SET_PTR(genericStack_t *stackp, void *p, int i) {
  GENERICSTACK_SET_PTR(stackp, p, i);
}

static void marpaESLIF_GENERICSTACK_SET_NA(genericStack_t *stackp, int indicei) {
  GENERICSTACK_SET_NA(stackp, indicei);
}

static short marpaESLIF_GENERICSTACK_ERROR(genericStack_t *stackp) {
  return GENERICSTACK_ERROR(stackp);
}

static int marpaESLIF_GENERICSTACK_USED(genericStack_t *stackp) {
  return GENERICSTACK_USED(stackp);
}

static int marpaESLIF_GENERICSTACK_SET_USED(genericStack_t *stackp, int usedi) {
  return GENERICSTACK_USED(stackp) = usedi;
}

#ifdef current_malloc
#define malloc current_malloc
#endif
#ifdef current_calloc
#define calloc current_calloc
#endif
#ifdef current_free
#define free current_free
#endif
#ifdef current_memset
#define memset current_memset
#endif
#ifdef current_memcpy
#define memcpy current_memcpy
#endif
#ifdef current_memmove
#define memmove current_memmove
#endif

/* ESLIF context */
typedef struct MarpaX_ESLIF_Engine {
  SV              *Perl_loggerInterfacep;    /* inc()/dec()'ed to ensure proper DESTROY order */
  genericLogger_t *genericLoggerp;
  marpaESLIF_t    *marpaESLIFp;
} MarpaX_ESLIF_Engine_t;

/* Nothing special for the grammar type */
typedef struct MarpaX_ESLIF_Grammar {
  SV                  *Perl_MarpaX_ESLIF_Enginep;    /* inc()/dec()'ed to ensure proper DESTROY order */
  marpaESLIFGrammar_t *marpaESLIFGrammarp;
} MarpaX_ESLIF_Grammar_t;

/* Recognizer context */
typedef struct MarpaX_ESLIF_Recognizer {
  SV                     *Perl_MarpaX_ESLIF_Grammarp; /* inc()/dec()'ed to ensure proper DESTROY order */
  SV                     *Perl_recognizerInterfacep;  /* inc()/dec()'ed to ensure proper DESTROY order */
  SV                     *previous_Perl_datap;
  SV                     *previous_Perl_encodingp;
  genericStack_t         *lexemeStackp;
  marpaESLIFRecognizer_t *marpaESLIFRecognizerp;
  short                   exhaustedb;
  short                   canContinueb;
} MarpaX_ESLIF_Recognizer_t;

/* Value context */
typedef struct MarpaX_ESLIF_Value {
  SV                     *Perl_valueInterfacep;          /* inc()/dec()'ed to ensure proper DESTROY order */
  SV                     *Perl_MarpaX_ESLIF_Recognizerp; /* inc()/dec()'ed to ensure proper DESTROY order - can be NULL */
  SV                     *Perl_MarpaX_ESLIF_Grammarp;    /* inc()/dec()'ed to ensure proper DESTROY order */
  char                   *actions;                       /* Shallow copy of last resolved name */
  void                   *previous_strings;              /* Latest stringification result */
  marpaESLIFValue_t      *marpaESLIFValuep;
  short                   canSetSymbolNameb;
  short                   canSetSymbolNumberb;
  short                   canSetRuleNameb;
  short                   canSetRuleNumberb;
  short                   canSetGrammarb;
  char                   *symbols;
  int                     symboli;
  char                   *rules;
  int                     rulei;
} MarpaX_ESLIF_Value_t;

/* For typemap */
typedef MarpaX_ESLIF_Engine_t     *MarpaX_ESLIF_Engine;
typedef MarpaX_ESLIF_Grammar_t    *MarpaX_ESLIF_Grammar;
typedef MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizer;
typedef MarpaX_ESLIF_Value_t      *MarpaX_ESLIF_Value;

/* Static functions declarations */
static int                             marpaESLIF_getTypei(pTHX_ SV* svp);
static short                           marpaESLIF_canb(pTHX_ SV *svp, char *methods);
static void                            marpaESLIF_call_methodv(pTHX_ SV *interfacep, char *methods, SV *argsvp);
static SV                             *marpaESLIF_call_methodp(pTHX_ SV *interfacep, char *methods);
static SV                             *marpaESLIF_call_actionp(pTHX_ SV *interfacep, char *methods, AV *avp, MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep);
static IV                              marpaESLIF_call_methodi(pTHX_ SV *interfacep, char *methods);
static short                           marpaESLIF_call_methodb(pTHX_ SV *interfacep, char *methods);
static void                            marpaESLIF_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static short                           marpaESLIF_recognizerReaderCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingOfEncodingsp, char **encodingsp, size_t *encodinglp);
static marpaESLIFValueRuleCallback_t   marpaESLIF_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static marpaESLIFValueSymbolCallback_t marpaESLIF_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static marpaESLIFValueFreeCallback_t   marpaESLIF_valueFreeActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static SV                             *marpaESLIF_getSvFromStack(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep, marpaESLIFValue_t *marpaESLIFValuep, int i, char *bytep, size_t bytel);
static short                           marpaESLIF_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                           marpaESLIF_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *bytep, size_t bytel, int resulti);
static void                            marpaESLIF_valueFreeCallbackv(void *userDatavp, int contexti, void *p, size_t sizel);
static void                            marpaESLIF_ContextFreev(pTHX_ MarpaX_ESLIF_Engine_t *Perl_MarpaX_ESLIF_Enginep);
static void                            marpaESLIF_grammarContextFreev(pTHX_ MarpaX_ESLIF_Grammar_t *Perl_MarpaX_ESLIF_Grammarp);
static void                            marpaESLIF_valueContextFreev(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep, short onStackb);
static void                            marpaESLIF_valueContextCleanupv(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep);
static void                            marpaESLIF_recognizerContextFreev(pTHX_ MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp, short onStackb);
static void                            marpaESLIF_recognizerContextCleanupv(pTHX_ MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp);
static void                            marpaESLIF_grammarContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Enginep, MarpaX_ESLIF_Grammar_t *Perl_MarpaX_ESLIF_Grammarp);
static void                            marpaESLIF_recognizerContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp);
static void                            marpaESLIF_valueContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Recognizerp, SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_valueInterfacep, MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep);
static void                            marpaESLIF_paramIsGrammarv(pTHX_ SV *sv);
static void                            marpaESLIF_paramIsEncodingv(pTHX_ SV *sv);
static short                           marpaESLIF_paramIsLoggerInterfaceOrUndefv(pTHX_ SV *sv);
static void                            marpaESLIF_paramIsRecognizerInterfacev(pTHX_ SV *sv);
static void                            marpaESLIF_paramIsValueInterfacev(pTHX_ SV *sv);
static short                           marpaESLIF_representation(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp);
static char                           *marpaESLIF_sv2byte(pTHX_ SV *svp, char **bytepp, size_t *bytelp, short encodingInformationb, short *characterStreambp, char **encodingOfEncodingsp, char **encodingsp, size_t *encodinglp, short warnIsFatalb);

/* Static constants */
static const char   *UTF8s = "UTF-8";
static const size_t  UTF8l = 5; /* "UTF-8" is 5 bytes in ASCII encoding */
static const char   *ASCIIs = "ASCII";

/*****************************************************************************/
/* Static variables initialized at boot                                      */
/*****************************************************************************/
SV *boot_MarpaX__ESLIF__Grammar__Properties_svp;
SV *boot_MarpaX__ESLIF__Grammar__Rule__Properties_svp;
SV *boot_MarpaX__ESLIF__Grammar__Symbol__Properties_svp;

/*****************************************************************************/
/* Macros                                                                    */
/*****************************************************************************/
#define MARPAESLIF_FILENAMES "ESLIF.xs"

#define MARPAESLIF_CROAK(msgs)       croak("[In %s at %s:%d] %s", funcs, MARPAESLIF_FILENAMES, __LINE__, msgs)
#define MARPAESLIF_CROAKF(fmts, ...) croak("[In %s at %s:%d] " fmts, funcs, MARPAESLIF_FILENAMES, __LINE__, __VA_ARGS__)
#define MARPAESLIF_WARN(msgs)        warn("[In %s at %s:%d] %s", funcs, MARPAESLIF_FILENAMES, __LINE__, msgs)
#define MARPAESLIF_WARNF(fmts, ...)  warn("[In %s at %s:%d] " fmts, funcs, MARPAESLIF_FILENAMES, __LINE__, __VA_ARGS__)
#define MARPAESLIF_REFCNT_DEC(svp) do {          \
    SV *_svp = svp;                              \
    if (((_svp) != NULL)         &&              \
        ((_svp) != &PL_sv_undef) &&              \
        ((_svp) != &PL_sv_yes) &&                \
        ((_svp) != &PL_sv_no)) {                 \
      SvREFCNT_dec(_svp);                        \
    }                                            \
  } while (0)

#define MARPAESLIF_IS_PTR(marpaESLIFValuep, indicei, rcb) do {          \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (_marpaESLIFValueResultp == NULL) {                              \
      MARPAESLIF_CROAKF("marpaESLIFValue_stack_getp failure, %s", strerror(errno)); \
    }                                                                   \
                                                                        \
    rcb = (_marpaESLIFValueResultp->type == MARPAESLIF_VALUE_TYPE_PTR); \
  } while (0)

#define MARPAESLIF_IS_UNDEF(marpaESLIFValuep, indicei, rcb) do {        \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (_marpaESLIFValueResultp == NULL) {                              \
      MARPAESLIF_CROAKF("marpaESLIFValue_stack_getp failure, %s", strerror(errno)); \
    }                                                                   \
                                                                        \
    rcb = (_marpaESLIFValueResultp->type == MARPAESLIF_VALUE_TYPE_UNDEF); \
  } while (0)

#define MARPAESLIF_GET_PTR(marpaESLIFValuep, indicei, _p) do {          \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (_marpaESLIFValueResultp == NULL) {                              \
      MARPAESLIF_CROAKF("marpaESLIFValue_stack_getp failure, %s", strerror(errno)); \
    }                                                                   \
                                                                        \
    if (_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_PTR) {   \
      MARPAESLIF_CROAKF("marpaESLIFValueResultp->type is not PTR (got %d)", _marpaESLIFValueResultp->type); \
    }                                                                   \
                                                                        \
    _p = _marpaESLIFValueResultp->u.p;                                  \
  } while (0)

#define MARPAESLIF_SET_PTR(marpaESLIFValuep, indicei, _contexti, _representationp, _p) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.contexti        = _contexti;                 \
    _marpaESLIFValueResult.sizel           = 0;                         \
    _marpaESLIFValueResult.representationp = _representationp;          \
    _marpaESLIFValueResult.shallowb        = 0;                         \
    _marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_PTR; \
    _marpaESLIFValueResult.u.p             = _p;                        \
                                                                        \
    if (! marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult)) { \
      MARPAESLIF_CROAKF("marpaESLIFValue_stack_setb failure, %s", strerror(errno)); \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_GET_ARRAY(marpaESLIFValuep, indicei, _p, _l) do {    \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (_marpaESLIFValueResultp == NULL) {                              \
      MARPAESLIF_CROAKF("marpaESLIFValue_stack_getp failure, %s", strerror(errno)); \
    }                                                                   \
                                                                        \
    if (_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_ARRAY) { \
      MARPAESLIF_CROAKF("marpaESLIFValueResultp->type is not ARRAY (got %d)", _marpaESLIFValueResultp->type); \
    }                                                                   \
                                                                        \
    _p = _marpaESLIFValueResultp->u.p;                                  \
    _l = _marpaESLIFValueResultp->sizel;                                \
  } while (0)

/* In this macro we hack the difference between hv_store and av_push by testing xvp type */
/* Remember that hv_store() and av_push() takes over one reference count. */
#define MARPAESLIF_XV_STORE(xvp, key, svp) do {         \
    if (SvTYPE((SV *)xvp) == SVt_PVHV) {                \
      hv_store((HV *) xvp, key, strlen(key), svp, 0);   \
    } else {                                            \
      av_push((AV *) xvp, newSVpvn(key, strlen(key)));  \
      av_push((AV *) xvp, svp);                         \
    }                                                   \
  } while (0)

#define MARPAESLIF_XV_STORE_ACTION(hvp, key, actionp) do {              \
    SV *_svp;                                                           \
                                                                        \
    if (actionp != NULL) {                                              \
      switch (actionp->type) {                                          \
      case MARPAESLIF_ACTION_TYPE_NAME:                                 \
        MARPAESLIF_XV_STORE(hvp, key, newSVpv(actionp->u.names, 0));    \
        break;                                                          \
      case MARPAESLIF_ACTION_TYPE_STRING:                               \
        _svp = newSVpvn(actionp->u.stringp->bytep, actionp->u.stringp->bytel); \
        if (is_utf8_string((const U8 *) actionp->u.stringp->bytep, (STRLEN) actionp->u.stringp->bytel)) { \
          SvUTF8_on(_svp);                                              \
        }                                                               \
        MARPAESLIF_XV_STORE(hvp, key, _svp);                            \
        break;                                                          \
      default:                                                          \
        warn("Unsupported action type %d", actionp->type);              \
        MARPAESLIF_XV_STORE(hvp, key, newSVsv(&PL_sv_undef));           \
        break;                                                          \
      }                                                                 \
    } else {                                                            \
      MARPAESLIF_XV_STORE(hvp, key, newSVsv(&PL_sv_undef));             \
    }                                                                   \
  } while (0)

#define MARPAESLIF_XV_STORE_STRING(hvp, key, stringp) do {              \
    SV *_svp;                                                           \
                                                                        \
    if (stringp != NULL) {                                              \
      _svp = newSVpvn(stringp->bytep, stringp->bytel);                  \
      if (is_utf8_string((const U8 *) stringp->bytep, (STRLEN) stringp->bytel)) { \
        SvUTF8_on(_svp);                                                \
      }                                                                 \
      MARPAESLIF_XV_STORE(hvp, key, _svp);                              \
    } else {                                                            \
      MARPAESLIF_XV_STORE(hvp, key, newSVsv(&PL_sv_undef));             \
    }                                                                   \
  } while (0)

#define MARPAESLIF_XV_STORE_ASCIISTRING(hvp, key, asciis) do {          \
    if (asciis != NULL) {                                               \
      MARPAESLIF_XV_STORE(hvp, key, newSVpv(asciis, 0));                \
    } else {                                                            \
      MARPAESLIF_XV_STORE(hvp, key, newSVsv(&PL_sv_undef));             \
    }                                                                   \
  } while (0)

#define MARPAESLIF_XV_STORE_IV(hvp, key, iv) do {                       \
    MARPAESLIF_XV_STORE(hvp, key, newSViv((IV) iv));                    \
  } while (0)

#define MARPAESLIF_XV_STORE_IVARRAY(hvp, key, ivl, ivp) do {            \
    AV *_avp;                                                           \
    size_t _i;                                                          \
                                                                        \
    _avp = newAV();                                                     \
    if (ivp != NULL) {                                                  \
      for (_i = 0; _i < ivl; _i++) {                                    \
        av_push(_avp, newSViv((IV) ivp[_i]));                           \
      }                                                                 \
    }                                                                   \
    MARPAESLIF_XV_STORE(hvp, key, newRV_inc((SV *) _avp));              \
  } while (0)

/*****************************************************************************/
/* Copy of Params-Validate-1.26/lib/Params/Validate/XS.xs                    */
/*****************************************************************************/
#define SCALAR    1
#define ARRAYREF  2
#define HASHREF   4
#define CODEREF   8
#define GLOB      16
#define GLOBREF   32
#define SCALARREF 64
#define UNKNOWN   128
#define UNDEF     256
#define OBJECT    512
static int marpaESLIF_getTypei(pTHX_ SV* svp) {
  int type = 0;

  if (SvTYPE(svp) == SVt_PVGV) {
    return GLOB;
  }
  if (!SvOK(svp)) {
    return UNDEF;
  }
  if (!SvROK(svp)) {
    return SCALAR;
  }

  switch (SvTYPE(SvRV(svp))) {
  case SVt_NULL:
  case SVt_IV:
  case SVt_NV:
  case SVt_PV:
#if PERL_VERSION <= 10
  case SVt_RV:
#endif
  case SVt_PVMG:
  case SVt_PVIV:
  case SVt_PVNV:
#if PERL_VERSION <= 8
  case SVt_PVBM:
#elif PERL_VERSION >= 11
  case SVt_REGEXP:
#endif
    type = SCALARREF;
    break;
  case SVt_PVAV:
    type = ARRAYREF;
    break;
  case SVt_PVHV:
    type = HASHREF;
    break;
  case SVt_PVCV:
    type = CODEREF;
    break;
  case SVt_PVGV:
    type = GLOBREF;
    break;
    /* Perl 5.10 has a bunch of new types that I don't think will ever
       actually show up here (I hope), but not handling them makes the
       C compiler cranky. */
  default:
    type = UNKNOWN;
    break;
  }

  if (type) {
    if (sv_isobject(svp)) return type | OBJECT;
    return type;
  }

  /* Getting here should not be possible */
  return UNKNOWN;
}

/*****************************************************************************/
static short marpaESLIF_canb(pTHX_ SV *svp, char *methods)
/*****************************************************************************/
{
  AV *list = newAV();
  SV *rcp;
  int type;

  /*
    fprintf(stderr, "START marpaESLIF_canb(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  /* We always check methods that have ASCII only characters */
  av_push(list, newSVpv(methods, 0));
  rcp = marpaESLIF_call_actionp(aTHX_ svp, "can", list, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(list);

  type = marpaESLIF_getTypei(aTHX_ rcp);
  MARPAESLIF_REFCNT_DEC(rcp);

  /*
    fprintf(stderr, "END marpaESLIF_canb(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  return (type & CODEREF) == CODEREF;
}

/*****************************************************************************/
static void marpaESLIF_call_methodv(pTHX_ SV *interfacep, char *methods, SV *argsvp)
/*****************************************************************************/
{
  dSP;

  /*
    fprintf(stderr, "START marpaESLIF_call_methodv(pTHX_ SV *svp, \"%s\", SV *argsvp)\n", methods);
  */
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1 + ((argsvp != NULL) ? 1 : 0));
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  if (argsvp != NULL) {
    PUSHs(sv_2mortal(newSVsv(argsvp)));
  }
  PUTBACK;

  call_method(methods, G_DISCARD);

  FREETMPS;
  LEAVE;
  /*
    fprintf(stderr, "END marpaESLIF_call_methodv(pTHX_ SV *svp, \"%s\", SV *argsvp)\n", methods);
  */
}

/*****************************************************************************/
static SV *marpaESLIF_call_methodp(pTHX_ SV *interfacep, char *methods)
/*****************************************************************************/
{
  SV *rcp;

  /*
    fprintf(stderr, "START marpaESLIF_call_methodp(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  rcp = marpaESLIF_call_actionp(aTHX_ interfacep, methods, NULL /* avp */, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  /*
    fprintf(stderr, "END marpaESLIF_call_methodp(pTHX_ SV *svp, \"%s\")\n", methods);
  */

  return rcp;
}

/*****************************************************************************/
static SV *marpaESLIF_call_actionp(pTHX_ SV *interfacep, char *methods, AV *avp, MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep)
/*****************************************************************************/
{
  static const char        *funcs      = "marpaESLIF_call_actionp";
  SSize_t                   avsizel    = (avp != NULL) ? av_len(avp) + 1 : 0;
  SV                      **svargs     = NULL;
  SV                       *rcp;
  SV                       *Perl_valueInterfacep;
  SV                       *Perl_MarpaX_ESLIF_Grammarp;
  SV                       *svlocalp;
  char                     *symbols;
  int                       symboli;
  char                     *rules;
  int                       rulei;
  SSize_t                   aviteratorl;
  dSP;

  ENTER;
  SAVETMPS;

  if (Perl_MarpaX_ESLIF_Valuep != NULL) {
    /* This is an action context - we localize some variable */
    /* For GV_ADD: calue is created once if needed - Perl will destroy it at exit */

    Perl_valueInterfacep       = Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep;
    Perl_MarpaX_ESLIF_Grammarp = Perl_MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Grammarp;

    symbols = Perl_MarpaX_ESLIF_Valuep->symbols;
    svlocalp = get_sv("MarpaX::ESLIF::Context::symbolName", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    if (symbols != NULL) {
      sv_setpvn(svlocalp, symbols, strlen(symbols));
    } else {
      sv_setsv(svlocalp, &PL_sv_undef);
    }
    if (Perl_MarpaX_ESLIF_Valuep->canSetSymbolNameb) {
      marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setSymbolName", svlocalp);
    }

    symboli = Perl_MarpaX_ESLIF_Valuep->symboli;
    svlocalp = get_sv("MarpaX::ESLIF::Context::symbolNumber", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setiv(svlocalp, symboli);
    if (Perl_MarpaX_ESLIF_Valuep->canSetSymbolNumberb) {
      marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setSymbolNumber", svlocalp);
    }

    rules = Perl_MarpaX_ESLIF_Valuep->rules;
    svlocalp = get_sv("MarpaX::ESLIF::Context::ruleName", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    if (rules != NULL) {
      sv_setpvn(svlocalp, rules, strlen(rules));
    } else {
      sv_setsv(svlocalp, &PL_sv_undef);
    }
    if (Perl_MarpaX_ESLIF_Valuep->canSetRuleNameb) {
      marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setRuleName", svlocalp);
    }

    rulei = Perl_MarpaX_ESLIF_Valuep->rulei;
    svlocalp = get_sv("MarpaX::ESLIF::Context::ruleNumber", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setiv(svlocalp, rulei);
    if (Perl_MarpaX_ESLIF_Valuep->canSetRuleNumberb) {
      marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setRuleNumber", svlocalp);
    }

    svlocalp = get_sv("MarpaX::ESLIF::Context::grammar", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setsv(svlocalp, Perl_MarpaX_ESLIF_Grammarp);
    if (Perl_MarpaX_ESLIF_Valuep->canSetGrammarb) {
      marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setGrammar", svlocalp);
    }

  }

  PUSHMARK(SP);
  EXTEND(SP, 1 + avsizel);
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  for (aviteratorl = 0; aviteratorl < avsizel; aviteratorl++) {
    SV **svpp = av_fetch(avp, aviteratorl, 0); /* We manage ourself the avp, SV's are real */
    if (svpp == NULL) {
      MARPAESLIF_CROAK("av_fetch returned NULL");
    }
    PUSHs(sv_2mortal(newSVsv(*svpp)));
  }
  PUTBACK;

  call_method(methods, G_SCALAR);

  SPAGAIN;

  rcp = SvREFCNT_inc(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;


  return rcp;
}

/*****************************************************************************/
static IV marpaESLIF_call_methodi(pTHX_ SV *interfacep, char *methods)
/*****************************************************************************/
{
  IV rci;
  dSP;

  /*
    fprintf(stderr, "START marpaESLIF_call_methodi(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  PUTBACK;

  call_method(methods, G_SCALAR);

  SPAGAIN;

  rci = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  /*
    fprintf(stderr, "END marpaESLIF_call_methodi(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  return rci;
}

/*****************************************************************************/
static short marpaESLIF_call_methodb(pTHX_ SV *interfacep, char *methods)
/*****************************************************************************/
{
  short rcb;
  dSP;

  /*
    fprintf(stderr, "START marpaESLIF_call_methodb(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  PUTBACK;

  call_method(methods, G_SCALAR);

  SPAGAIN;

  rcb = (POPi != 0);

  PUTBACK;
  FREETMPS;
  LEAVE;

  /*
    fprintf(stderr, "END marpaESLIF_call_methodb(pTHX_ SV *svp, \"%s\")\n", methods);
  */
  return rcb;
}

/*****************************************************************************/
static void marpaESLIF_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs)
/*****************************************************************************/
{
  SV   *Perl_loggerInterfacep = (SV *) userDatavp;
  char *method;

  switch (logLeveli) {
  case GENERICLOGGER_LOGLEVEL_TRACE:     method = "trace";     break;
  case GENERICLOGGER_LOGLEVEL_DEBUG:     method = "debug";     break;
  case GENERICLOGGER_LOGLEVEL_INFO:      method = "info";      break;
  case GENERICLOGGER_LOGLEVEL_NOTICE:    method = "notice";    break;
  case GENERICLOGGER_LOGLEVEL_WARNING:   method = "warning";   break;
  case GENERICLOGGER_LOGLEVEL_ERROR:     method = "error";     break;
  case GENERICLOGGER_LOGLEVEL_CRITICAL:  method = "critical";  break;
  case GENERICLOGGER_LOGLEVEL_ALERT:     method = "alert";     break;
  case GENERICLOGGER_LOGLEVEL_EMERGENCY: method = "emergency"; break;
  default:                               method = NULL;        break;
  }

  if (method != NULL) {
    /* It should never happen that method is NULL -; */
    dTHX;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVsv(Perl_loggerInterfacep)));
    /* We always log only with ASCII characters */
    PUSHs(sv_2mortal(newSVpv(msgs,0)));
    PUTBACK;

    call_method(method, G_DISCARD);

    FREETMPS;
    LEAVE;
  }
}

/*****************************************************************************/
static short marpaESLIF_recognizerReaderCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingOfEncodingsp, char **encodingsp, size_t *encodinglp)
/*****************************************************************************/
{
  static const char         *funcs = "marpaESLIF_recognizerReaderCallbackb";
  MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp;
  SV                        *Perl_recognizerInterfacep;
  SV                        *Perl_datap;
  SV                        *Perl_encodingp;
  char                      *inputs = NULL;
  STRLEN                     inputl = 0;
  char                      *encodingOfEncodings = NULL;
  char                      *encodings = NULL;
  STRLEN                     encodingl = 0;
  int                        type;
  dTHX;

  Perl_MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  Perl_recognizerInterfacep   = Perl_MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep;

  marpaESLIF_recognizerContextCleanupv(aTHX_ Perl_MarpaX_ESLIF_Recognizerp);

  /* Call the read interface */
  if (! marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "read")) {
    MARPAESLIF_CROAK("Recognizer->read() method failure");
  }

  /* Call the data interface */
  Perl_datap = marpaESLIF_call_methodp(aTHX_ Perl_recognizerInterfacep, "data");
  type = marpaESLIF_getTypei(aTHX_ Perl_datap);
  if ((type & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((type & UNDEF) != UNDEF) {
      MARPAESLIF_CROAK("Recognizer->data() method must return a scalar or undef");
    }
  }
  if (SvOK(Perl_datap)) {
    inputs = SvPV(Perl_datap, inputl);
  }

  /* Call the encoding interface */
  Perl_encodingp  = marpaESLIF_call_methodp(aTHX_ Perl_recognizerInterfacep, "encoding");
  type = marpaESLIF_getTypei(aTHX_ Perl_datap);
  if ((type & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((type & UNDEF) != UNDEF) {
      MARPAESLIF_CROAK("Recognizer->encoding() method must return a scalar or undef");
    }
  }
  if (SvOK(Perl_encodingp)) {
    encodings = SvPV(Perl_encodingp, encodingl); /* May be {NULL, 0} */
    encodingOfEncodings = DO_UTF8(Perl_encodingp) ? (char *) UTF8s : (char *) ASCIIs;
  } else {
    /* User gave no encoding hint - we can use Perl_datap itself */
    /* This will be ignored if *characterStreambp is false */
    if ((inputs != NULL) && DO_UTF8(Perl_datap)) {
      encodingOfEncodings = (char *) ASCIIs;
      encodings           = (char *) UTF8s;
      encodingl           = UTF8l;
    }
  }

  *inputcpp             = inputs;
  *inputlp              = (size_t) inputl;
  *eofbp                = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isEof");
  *characterStreambp    = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isCharacterStream");
  *encodingOfEncodingsp = encodingOfEncodings;
  *encodingsp           = encodings;
  *encodinglp           = encodingl;

  Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_datap     = Perl_datap;
  Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_encodingp = Perl_encodingp;

  return 1;
}

/*****************************************************************************/
static marpaESLIFValueRuleCallback_t  marpaESLIF_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  Perl_MarpaX_ESLIF_Valuep->actions = actions;

  return marpaESLIF_valueRuleCallbackb;
}

/*****************************************************************************/
static marpaESLIFValueSymbolCallback_t marpaESLIF_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  Perl_MarpaX_ESLIF_Valuep->actions = actions;

  return marpaESLIF_valueSymbolCallbackb;
}

/*****************************************************************************/
static marpaESLIFValueFreeCallback_t marpaESLIF_valueFreeActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;

  /* It HAS to be ":defaultFreeActions" */
  if (strcmp(actions, ":defaultFreeActions") != 0) {
    return NULL;
  }

  /* Remember the action name - perl will croak if calling this method fails */
  Perl_MarpaX_ESLIF_Valuep->actions = actions;

  

  return marpaESLIF_valueFreeCallbackv;
}

/*****************************************************************************/
static SV *marpaESLIF_getSvFromStack(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep, marpaESLIFValue_t *marpaESLIFValuep, int i, char *bytep, size_t bytel)
/*****************************************************************************/
/* This function is guaranteed to return an SV in any case, it will HAVE TO BE refcount_dec'ed */
{
  static const char       *funcs = "marpaESLIF_getSvFromStack";
  SV                      *objectp;
  short                    ptrb;
  short                    undefb;
  marpaESLIFValueResult_t *marpaESLIFValueResultp;

  /* fprintf(stderr, "In %s for indice %d, bytep %p, bytel %ld\n", funcs, i, bytep, (unsigned long) bytel); */
  if (bytep != NULL) {
    /* Go immediately to array processing */
    goto is_array;
  }
  MARPAESLIF_IS_PTR(marpaESLIFValuep, i, ptrb);
  if (ptrb) {
    MARPAESLIF_GET_PTR(marpaESLIFValuep, i, objectp);
    objectp = SvREFCNT_inc(objectp);
  } else {
    /* This must be a lexeme, undef (result of a nullable or ::concat that failed) or user-land object (always in the form of an array) */
    MARPAESLIF_IS_UNDEF(marpaESLIFValuep, i, undefb);
    if (undefb) {
      objectp = &PL_sv_undef;
    } else {
      MARPAESLIF_GET_ARRAY(marpaESLIFValuep, i, bytep, bytel);
  is_array:
      /* Either bytel is > 0, then this is the input, else this is a user-defined object */
      if (bytel > 0) {
        objectp = newSVpvn(bytep, bytel);
        if (is_utf8_string((const U8 *) bytep, (STRLEN) bytel)) {
          SvUTF8_on(objectp);
        }
      } else {
        marpaESLIFValueResultp = (marpaESLIFValueResult_t *) bytep;
        if (marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_PTR) {
          MARPAESLIF_CROAKF("User-defined value type is not MARPAESLIF_VALUE_TYPE_PTR but %d", marpaESLIFValueResultp->type);
        }
        objectp = (SV *) marpaESLIFValueResultp->u.p;
        objectp = SvREFCNT_inc(objectp);
      }
    }
  }

  /*
  if (objectp != NULL) {
    if (SvOK(objectp)) {
      char *s;
      STRLEN l;
      s = SvPV(objectp, l);
      fprintf(stderr, "... ... Retreived %s\n", s);
    } else {
      fprintf(stderr, "... ... OUPS !?\n");
      sv_dump(objectp);
    }
  } else {
    fprintf(stderr, "... ... Retreived NULL\n");
  }
  */

  return objectp;
}


/*****************************************************************************/
static short marpaESLIF_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  dTHX;
  static const char        *funcs                    = "marpaESLIF_valueRuleCallbackb";
  MarpaX_ESLIF_Value_t     *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  SV                       *Perl_valueInterfacep     = Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep;
  AV                       *list                     = NULL;
  SV                       *actionResult;
  SV                       *svp;
  int                       i;

  /* Get value context */
  if (! marpaESLIFValue_contextb(marpaESLIFValuep, &(Perl_MarpaX_ESLIF_Valuep->symbols), &(Perl_MarpaX_ESLIF_Valuep->symboli), &(Perl_MarpaX_ESLIF_Valuep->rules), &(Perl_MarpaX_ESLIF_Valuep->rulei))) {
    MARPAESLIF_CROAKF("marpaESLIFValue_contextb failure, %s", strerror(errno));
  }

  if (! nullableb) {
    list = newAV();
    for (i = arg0i; i <= argni; i++) {
      svp = marpaESLIF_getSvFromStack(aTHX_ Perl_MarpaX_ESLIF_Valuep, marpaESLIFValuep, i, NULL /* bytep */, 0 /* bytel */);
      /*
        sv_dump(svp);
      */
      av_push(list, svp);
    }
  }

  actionResult = marpaESLIF_call_actionp(aTHX_ Perl_valueInterfacep, Perl_MarpaX_ESLIF_Valuep->actions, list, Perl_MarpaX_ESLIF_Valuep);
  if (list != NULL) {
    av_undef(list);
  }

  MARPAESLIF_SET_PTR(marpaESLIFValuep, resulti, 1 /* context: any value != 0 */, marpaESLIF_representation, actionResult);

  return 1;
}

/*****************************************************************************/
static short marpaESLIF_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *bytep, size_t bytel, int resulti)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIF_valueRuleCallbackb except that we construct a list of one element containing a byte array that we do ourself */
  static const char        *funcs                    = "marpaESLIF_valueSymbolCallbackb";
  MarpaX_ESLIF_Value_t     *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  AV                       *list                     = NULL;
  SV                       *actionResult;
  dTHX;

  /* Get value context */
  if (! marpaESLIFValue_contextb(marpaESLIFValuep, &(Perl_MarpaX_ESLIF_Valuep->symbols), &(Perl_MarpaX_ESLIF_Valuep->symboli), &(Perl_MarpaX_ESLIF_Valuep->rules), &(Perl_MarpaX_ESLIF_Valuep->rulei))) {
    MARPAESLIF_CROAKF("marpaESLIFValue_contextb failure, %s", strerror(errno));
  }

  list = newAV();
  av_push(list, marpaESLIF_getSvFromStack(aTHX_ Perl_MarpaX_ESLIF_Valuep, marpaESLIFValuep, -1 /* not used */, bytep, bytel));
  actionResult = marpaESLIF_call_actionp(aTHX_ Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep, Perl_MarpaX_ESLIF_Valuep->actions, list, Perl_MarpaX_ESLIF_Valuep);
  av_undef(list);

  MARPAESLIF_SET_PTR(marpaESLIFValuep, resulti, 1 /* context: any value != 0 */, marpaESLIF_representation, actionResult);

  return 1;
}

/*****************************************************************************/
static void marpaESLIF_valueFreeCallbackv(void *userDatavp, int contexti, void *p, size_t sizel)
/*****************************************************************************/
{
  dTHX;

  /* We are called when valuation is doing to withdraw an item in the stack that is a PTR or an ARRAY that we own */
  /* It is guaranteed to be non-NULL at this stage. Nevertheless there some SV* in perl that are just pointers */
  /* to constants: undef, yes, no (we do not use placeholder). */
  /*
  fprintf(stderr, "------------\n");
  fprintf(stderr, "Withdrawing:\n");
  sv_dump((SV *) p);
  fprintf(stderr, "------------\n");
  */
  MARPAESLIF_REFCNT_DEC(p);
}

/*****************************************************************************/
static void marpaESLIF_ContextFreev(pTHX_ MarpaX_ESLIF_Engine_t *Perl_MarpaX_ESLIF_Enginep)
/*****************************************************************************/
{
  if (Perl_MarpaX_ESLIF_Enginep != NULL) {
    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Enginep->Perl_loggerInterfacep);
    if (Perl_MarpaX_ESLIF_Enginep->marpaESLIFp != NULL) {
      marpaESLIF_freev(Perl_MarpaX_ESLIF_Enginep->marpaESLIFp);
    }
    genericLogger_freev(&(Perl_MarpaX_ESLIF_Enginep->genericLoggerp)); /* This is NULL aware */
    Safefree(Perl_MarpaX_ESLIF_Enginep);
  }
}

/*****************************************************************************/
static void marpaESLIF_grammarContextFreev(pTHX_ MarpaX_ESLIF_Grammar_t *Perl_MarpaX_ESLIF_Grammarp)
/*****************************************************************************/
{
  if (Perl_MarpaX_ESLIF_Grammarp != NULL) {
    SV *Perl_MarpaX_ESLIF_Enginep = Perl_MarpaX_ESLIF_Grammarp->Perl_MarpaX_ESLIF_Enginep;

    if (Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp != NULL) {
      marpaESLIFGrammar_freev(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp);
    }
    Safefree(Perl_MarpaX_ESLIF_Grammarp);

    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Enginep);
  }
}
 
/*****************************************************************************/
static void marpaESLIF_valueContextFreev(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep, short onStackb)
/*****************************************************************************/
{
  if (Perl_MarpaX_ESLIF_Valuep != NULL) {
    SV *Perl_MarpaX_ESLIF_Recognizerp = Perl_MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Recognizerp;
    SV *Perl_MarpaX_ESLIF_Grammarp    = Perl_MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Grammarp;
    SV *Perl_valueInterfacep          = Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep;

    if (Perl_MarpaX_ESLIF_Valuep->previous_strings != NULL) {
      Safefree(Perl_MarpaX_ESLIF_Valuep->previous_strings);
      Perl_MarpaX_ESLIF_Valuep->previous_strings = NULL;
    }
    if (Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep != NULL) {
      marpaESLIFValue_freev(Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep);
    }
    MARPAESLIF_REFCNT_DEC(Perl_valueInterfacep);
    /* Note that Perl_MarpaX_ESLIF_Recognizerp is NULL in case of parse() */
    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Recognizerp);
    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Grammarp);
    if (! onStackb) {
      Safefree(Perl_MarpaX_ESLIF_Valuep);
    }
  }
}
 
/*****************************************************************************/
static void marpaESLIF_valueContextCleanupv(pTHX_ MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep)
/*****************************************************************************/
{
  if (Perl_MarpaX_ESLIF_Valuep != NULL) {
    if (Perl_MarpaX_ESLIF_Valuep->previous_strings != NULL) {
      Safefree(Perl_MarpaX_ESLIF_Valuep->previous_strings);
      Perl_MarpaX_ESLIF_Valuep->previous_strings = NULL;
    }
  }
}

/*****************************************************************************/
static void marpaESLIF_recognizerContextFreev(pTHX_ MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp, short onStackb)
/*****************************************************************************/
{
  int             i;
  SV             *svp;
  genericStack_t *lexemeStackp;

  if (Perl_MarpaX_ESLIF_Recognizerp != NULL) {
    SV *Perl_MarpaX_ESLIF_Grammarp = Perl_MarpaX_ESLIF_Recognizerp->Perl_MarpaX_ESLIF_Grammarp;
    SV *Perl_recognizerInterfacep  = Perl_MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep;

    marpaESLIF_recognizerContextCleanupv(aTHX_ Perl_MarpaX_ESLIF_Recognizerp);
    lexemeStackp = Perl_MarpaX_ESLIF_Recognizerp->lexemeStackp;
    if (lexemeStackp != NULL) {
      /* It is important to delete references in the reverse order of their creation */
      while (marpaESLIF_GENERICSTACK_USED(lexemeStackp) > 0) {
        /* Last indice ... */
        i = marpaESLIF_GENERICSTACK_USED(lexemeStackp) - 1;
        /* ... is cleared ... */
        if (marpaESLIF_GENERICSTACK_IS_PTR(lexemeStackp, i)) {
          svp = (SV *) marpaESLIF_GENERICSTACK_GET_PTR(lexemeStackp, i);
          MARPAESLIF_REFCNT_DEC(svp);
        }
        /* ... and becomes current used size */
        marpaESLIF_GENERICSTACK_SET_USED(lexemeStackp, i);
      }
      marpaESLIF_GENERICSTACK_FREE(Perl_MarpaX_ESLIF_Recognizerp->lexemeStackp);
    }
    if (Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp != NULL) {
      marpaESLIFRecognizer_freev(Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp);
    }
    MARPAESLIF_REFCNT_DEC(Perl_recognizerInterfacep);
    /* Note that Perl_MarpaX_ESLIF_Grammarp is NULL in the context of parse() */
    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Grammarp);
    if (! onStackb) {
      Safefree(Perl_MarpaX_ESLIF_Recognizerp);
    }
  }
}

/*****************************************************************************/
static void marpaESLIF_recognizerContextCleanupv(pTHX_ MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp)
/*****************************************************************************/
{
  if (Perl_MarpaX_ESLIF_Recognizerp != NULL) {

    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_datap);
    Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_datap = NULL;

    MARPAESLIF_REFCNT_DEC(Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_encodingp);
    Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_encodingp = NULL;

  }
}

/*****************************************************************************/
static void marpaESLIF_grammarContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Enginep, MarpaX_ESLIF_Grammar_t *Perl_MarpaX_ESLIF_Grammarp)
/*****************************************************************************/
{
  Perl_MarpaX_ESLIF_Grammarp->Perl_MarpaX_ESLIF_Enginep = SvREFCNT_inc(Perl_MarpaX_ESLIF_Enginep);
  Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp = NULL;
}

/*****************************************************************************/
static void marpaESLIF_recognizerContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizer_t *Perl_MarpaX_ESLIF_Recognizerp)
/*****************************************************************************/
{
  /* Perl_MarpaX_ESLIF_Grammarp is NULL in the context of parseb() */
  Perl_MarpaX_ESLIF_Recognizerp->Perl_MarpaX_ESLIF_Grammarp = (Perl_MarpaX_ESLIF_Grammarp != NULL) ? SvREFCNT_inc(Perl_MarpaX_ESLIF_Grammarp) : NULL;
  Perl_MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep  = SvREFCNT_inc(Perl_recognizerInterfacep);
  Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_datap        = NULL;
  Perl_MarpaX_ESLIF_Recognizerp->previous_Perl_encodingp    = NULL;
  Perl_MarpaX_ESLIF_Recognizerp->lexemeStackp               = NULL;
  Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp      = NULL;
  Perl_MarpaX_ESLIF_Recognizerp->exhaustedb                 = 0;
  Perl_MarpaX_ESLIF_Recognizerp->canContinueb               = 0;
}

/*****************************************************************************/
static void marpaESLIF_valueContextInit(pTHX_ SV *Perl_MarpaX_ESLIF_Recognizerp, SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_valueInterfacep, MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_valueContextInit";

  /* Perl_MarpaX_ESLIF_Recognizerp is NULL in the context of parseb() */
  Perl_MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Recognizerp = (Perl_MarpaX_ESLIF_Recognizerp != NULL) ? SvREFCNT_inc(Perl_MarpaX_ESLIF_Recognizerp) : NULL;
  Perl_MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Grammarp    = SvREFCNT_inc(Perl_MarpaX_ESLIF_Grammarp);
  Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep          = SvREFCNT_inc(Perl_valueInterfacep);
  Perl_MarpaX_ESLIF_Valuep->actions                       = NULL;
  Perl_MarpaX_ESLIF_Valuep->previous_strings              = NULL;
  Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep              = NULL;
  Perl_MarpaX_ESLIF_Valuep->canSetSymbolNameb             = marpaESLIF_canb(aTHX_ Perl_valueInterfacep, "setSymbolName");
  Perl_MarpaX_ESLIF_Valuep->canSetSymbolNumberb           = marpaESLIF_canb(aTHX_ Perl_valueInterfacep, "setSymbolNumber");
  Perl_MarpaX_ESLIF_Valuep->canSetRuleNameb               = marpaESLIF_canb(aTHX_ Perl_valueInterfacep, "setRuleName");
  Perl_MarpaX_ESLIF_Valuep->canSetRuleNumberb             = marpaESLIF_canb(aTHX_ Perl_valueInterfacep, "setRuleNumber");
  Perl_MarpaX_ESLIF_Valuep->canSetGrammarb                = marpaESLIF_canb(aTHX_ Perl_valueInterfacep, "setGrammar");
  Perl_MarpaX_ESLIF_Valuep->symbols                       = NULL;
  Perl_MarpaX_ESLIF_Valuep->symboli                       = -1;
  Perl_MarpaX_ESLIF_Valuep->rules                         = NULL;
  Perl_MarpaX_ESLIF_Valuep->rulei                         = -1;
}

/*****************************************************************************/
static void marpaESLIF_paramIsGrammarv(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_paramIsGrammarv";
  int                type  = marpaESLIF_getTypei(aTHX_ sv);

  if ((type & SCALAR) != SCALAR) {
    MARPAESLIF_CROAK("Grammar must be a scalar");
  }
}

/*****************************************************************************/
static void marpaESLIF_paramIsEncodingv(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_paramIsEncodingv";
  int                type  = marpaESLIF_getTypei(aTHX_ sv);

  if ((type & SCALAR) != SCALAR) {
    MARPAESLIF_CROAK("Encoding must be a scalar");
  }
}

/*****************************************************************************/
static short marpaESLIF_paramIsLoggerInterfaceOrUndefv(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_paramIsLoggerInterfaceOrUndefv";
  int                type  = marpaESLIF_getTypei(aTHX_ sv);

  if ((type & UNDEF) == UNDEF) {
    return 0;
  }

  if ((type & OBJECT) != OBJECT) {
    MARPAESLIF_CROAK("Logger interface must be an object");
  }

  if (! marpaESLIF_canb(aTHX_ sv, "trace"))     MARPAESLIF_CROAK("Logger interface must be an object that can do \"trace\"");
  if (! marpaESLIF_canb(aTHX_ sv, "debug"))     MARPAESLIF_CROAK("Logger interface must be an object that can do \"debug\"");
  if (! marpaESLIF_canb(aTHX_ sv, "info"))      MARPAESLIF_CROAK("Logger interface must be an object that can do \"info\"");
  if (! marpaESLIF_canb(aTHX_ sv, "notice"))    MARPAESLIF_CROAK("Logger interface must be an object that can do \"notice\"");
  if (! marpaESLIF_canb(aTHX_ sv, "warning"))   MARPAESLIF_CROAK("Logger interface must be an object that can do \"warning\"");
  if (! marpaESLIF_canb(aTHX_ sv, "error"))     MARPAESLIF_CROAK("Logger interface must be an object that can do \"error\"");
  if (! marpaESLIF_canb(aTHX_ sv, "critical"))  MARPAESLIF_CROAK("Logger interface must be an object that can do \"critical\"");
  if (! marpaESLIF_canb(aTHX_ sv, "alert"))     MARPAESLIF_CROAK("Logger interface must be an object that can do \"alert\"");
  if (! marpaESLIF_canb(aTHX_ sv, "emergency")) MARPAESLIF_CROAK("Logger interface must be an object that can do \"emergency\"");

  return 1;
}

/*****************************************************************************/
static void marpaESLIF_paramIsRecognizerInterfacev(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_paramIsRecognizerInterfacev";
  int                type  = marpaESLIF_getTypei(aTHX_ sv);

  if ((type & OBJECT) != OBJECT) {
    MARPAESLIF_CROAK("Recognizer interface must be an object");
  }

  if (! marpaESLIF_canb(aTHX_ sv, "read"))                   MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"read\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isEof"))                  MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isEof\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isCharacterStream"))      MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isCharacterStream\"");
  if (! marpaESLIF_canb(aTHX_ sv, "encoding"))               MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"encoding\"");
  if (! marpaESLIF_canb(aTHX_ sv, "data"))                   MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"data\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithDisableThreshold")) MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isWithDisableThreshold\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithExhaustion"))       MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isWithExhaustion\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithNewline"))          MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isWithNewline\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithTrack"))            MARPAESLIF_CROAK("Recognizer interface must be an object that can do \"isWithTrack\"");
}

/*****************************************************************************/
static void marpaESLIF_paramIsValueInterfacev(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_paramIsValueInterfacev";
  int                type  = marpaESLIF_getTypei(aTHX_ sv);

  if ((type & OBJECT) != OBJECT) {
    MARPAESLIF_CROAK("Value interface must be an object");
  }

  if (! marpaESLIF_canb(aTHX_ sv, "isWithHighRankOnly")) MARPAESLIF_CROAK("Value interface must be an object that can do \"isWithHighRankOnly\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithOrderByRank"))  MARPAESLIF_CROAK("Value interface must be an object that can do \"isWithOrderByRank\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithAmbiguous"))    MARPAESLIF_CROAK("Value interface must be an object that can do \"isWithAmbiguous\"");
  if (! marpaESLIF_canb(aTHX_ sv, "isWithNull"))         MARPAESLIF_CROAK("Value interface must be an object that can do \"isWithNull\"");
  if (! marpaESLIF_canb(aTHX_ sv, "maxParses"))          MARPAESLIF_CROAK("Value interface must be an object that can do \"maxParses\"");
  if (! marpaESLIF_canb(aTHX_ sv, "setResult"))          MARPAESLIF_CROAK("Value interface must be an object that can do \"setResult\"");
  if (! marpaESLIF_canb(aTHX_ sv, "getResult"))          MARPAESLIF_CROAK("Value interface must be an object that can do \"getResult\"");
}

/*****************************************************************************/
static short marpaESLIF_representation(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp)
/*****************************************************************************/
{
  static const char    *funcs                    = "marpaESLIF_representation";
  MarpaX_ESLIF_Value_t *Perl_MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  dTHX;

  marpaESLIF_valueContextCleanupv(aTHX_ Perl_MarpaX_ESLIF_Valuep);

  /* We always push a PTR */
  if (marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_PTR) {
    MARPAESLIF_CROAKF("User-defined value type is not MARPAESLIF_VALUE_TYPE_PTR but %d", marpaESLIFValueResultp->type);
  }
  Perl_MarpaX_ESLIF_Valuep->previous_strings = marpaESLIF_sv2byte(aTHX_ (SV *) marpaESLIFValueResultp->u.p, inputcpp, inputlp, 0 /* encodingInformationb */, NULL /* characterStreambp */, NULL /* encodingOfEncodingsp */, NULL /* encodingsp */, NULL /* encodinglp */, 0 /* warnIsFatalb */);

  /* Always return a true value, else ::concat will abort */
  return 1;
}

/*****************************************************************************/
static char *marpaESLIF_sv2byte(pTHX_ SV *svp, char **bytepp, size_t *bytelp, short encodingInformationb, short *characterStreambp, char **encodingOfEncodingsp, char **encodingsp, size_t *encodinglp, short warnIsFatalb)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIF_sv2byte";
  char              *rcp = NULL;
  short              okb   = 0;
  SV                *svtmp;
  char              *strings;
  STRLEN             len;
  char              *bytep;
  size_t             bytel;
  short              characterStreamb;
  char              *encodingOfEncodings;
  char              *encodings;
  size_t             encodingl;

  /* svp == NULL should never happen because we always push an SV* out of actions
     but &PL_sv_undef is of course possible */
  if ((svp == NULL) || (svp == &PL_sv_undef)) {
    return NULL;
  }
  
  /* Because of the sv_mortalcopy below */
  SAVETMPS;

  svtmp = sv_mortalcopy(svp);
  strings = SvPV(svtmp, len);

  if ((strings != NULL) && (len > 0)) {
    okb = 1;
    if (encodingInformationb && DO_UTF8(svtmp)) {
      characterStreamb    = 1;
      encodingOfEncodings = (char *) ASCIIs;
      encodings           = (char *) UTF8s;
      encodingl           = UTF8l;
    } else {
      characterStreamb    = 0;
      encodingOfEncodings = NULL;
      encodings           = NULL;
      encodingl           = 0;
    }
  } else {
    if (warnIsFatalb) {
      MARPAESLIF_CROAKF("SvPV() returned {pointer,length}={%p,%ld}", strings, (unsigned long) len);
    }
  }

  if (okb) { /* Else nothing will be appended */
    Newx(rcp, (int) len, char);
    bytep = CopyD(strings, rcp, (int) len, char);
    bytel = (size_t) len;
  }

  /* This will free the svtmp SV */
  FREETMPS;

  if (okb) {
    if (bytepp != NULL) {
      *bytepp = bytep;
    }
    if (bytelp != NULL) {
      *bytelp = bytel;
    }
    if (characterStreambp != NULL) {
      *characterStreambp = characterStreamb;
    }
    if (encodingOfEncodingsp != NULL) {
      *encodingOfEncodingsp = encodingOfEncodings;
    }
    if (encodingsp != NULL) {
      *encodingsp = encodings;
    }
    if (encodinglp != NULL) {
      *encodinglp = encodingl;
    }
  }

  return rcp;
}

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Engine                                                   */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Engine

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Engine::allocate                                         */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, ...)
  SV *Perl_packagep;
PREINIT:
  SV *Perl_loggerInterfacep = &PL_sv_undef;
CODE:
  static const char  *funcs = "MarpaX::ESLIF::Engine::allocate";
  MarpaX_ESLIF_Engine Perl_MarpaX_ESLIF_Enginep;
  marpaESLIFOption_t  marpaESLIFOption;
  short               loggerInterfaceIsObjectb = 0;

  if(items > 1) {
    loggerInterfaceIsObjectb = marpaESLIF_paramIsLoggerInterfaceOrUndefv(aTHX_ Perl_loggerInterfacep = ST(1));
  }

  Newx(Perl_MarpaX_ESLIF_Enginep, 1, MarpaX_ESLIF_Engine_t);
  Perl_MarpaX_ESLIF_Enginep->Perl_loggerInterfacep = &PL_sv_undef;
  Perl_MarpaX_ESLIF_Enginep->genericLoggerp        = NULL;
  Perl_MarpaX_ESLIF_Enginep->marpaESLIFp           = NULL;

  /* ------------- */
  /* genericLogger */
  /* ------------- */
  if (loggerInterfaceIsObjectb) {
    Perl_MarpaX_ESLIF_Enginep->Perl_loggerInterfacep = SvREFCNT_inc(Perl_loggerInterfacep);
    Perl_MarpaX_ESLIF_Enginep->genericLoggerp        = genericLogger_newp(marpaESLIF_genericLoggerCallbackv,
                                                                   Perl_MarpaX_ESLIF_Enginep->Perl_loggerInterfacep,
                                                                   GENERICLOGGER_LOGLEVEL_TRACE);
    if (Perl_MarpaX_ESLIF_Enginep->genericLoggerp == NULL) {
      int save_errno = errno;
      marpaESLIF_ContextFreev(aTHX_ Perl_MarpaX_ESLIF_Enginep);
      MARPAESLIF_CROAKF("genericLogger_newp failure, %s", strerror(save_errno));
    }
  }

  /* ---------- */
  /* marpaESLIF */
  /* ---------- */
  marpaESLIFOption.genericLoggerp = Perl_MarpaX_ESLIF_Enginep->genericLoggerp;
  Perl_MarpaX_ESLIF_Enginep->marpaESLIFp = marpaESLIF_newp(&marpaESLIFOption);
  if (Perl_MarpaX_ESLIF_Enginep->marpaESLIFp == NULL) {
    int save_errno = errno;
    marpaESLIF_ContextFreev(aTHX_ Perl_MarpaX_ESLIF_Enginep);
    MARPAESLIF_CROAKF("marpaESLIF_newp failure, %s", strerror(save_errno));
  }

  RETVAL = Perl_MarpaX_ESLIF_Enginep;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Engine::dispose                                          */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(Perl_packagep, Perl_MarpaX_ESLIF_Enginep)
  SV *Perl_packagep;
  void *Perl_MarpaX_ESLIF_Enginep;
CODE:
  marpaESLIF_ContextFreev(aTHX_ (MarpaX_ESLIF_Engine) Perl_MarpaX_ESLIF_Enginep);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Engine::version                                          */
  /* ----------------------------------------------------------------------- */
=cut

const char *
version()
CODE:
  RETVAL = marpaESLIF_versions();
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Grammar                                                  */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Grammar

PROTOTYPES: ENABLE

BOOT:
  boot_MarpaX__ESLIF__Grammar__Properties_svp = newSVpvn("MarpaX::ESLIF::Grammar::Properties", strlen("MarpaX::ESLIF::Grammar::Properties"));
  boot_MarpaX__ESLIF__Grammar__Rule__Properties_svp    = newSVpvn("MarpaX::ESLIF::Grammar::Rule::Properties", strlen("MarpaX::ESLIF::Grammar::Rule::Properties"));
  boot_MarpaX__ESLIF__Grammar__Symbol__Properties_svp  = newSVpvn("MarpaX::ESLIF::Grammar::Symbol::Properties", strlen("MarpaX::ESLIF::Grammar::Symbol::Properties"));

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::_new                                            */
  /* ----------------------------------------------------------------------- */
=cut

MarpaX_ESLIF_Grammar
_new(Perl_packagep, Perl_MarpaX_ESLIF_Enginep, Perl_grammarp, ...)
  SV   *Perl_packagep;
  void *Perl_MarpaX_ESLIF_Enginep;
  SV   *Perl_grammarp;
PREINIT:
  SV *Perl_encodingp = &PL_sv_undef;
CODE:
  static const char           *funcs = "MarpaX::ESLIF::Grammar::_new";
  MarpaX_ESLIF_Grammar_t      *Perl_MarpaX_ESLIF_Grammarp;
  marpaESLIFGrammar_t         *marpaESLIFGrammarp;
  marpaESLIFGrammarOption_t    marpaESLIFGrammarOption;
  int                          ngrammari;
  int                          i;
  marpaESLIFGrammarDefaults_t  marpaESLIFGrammarDefaults;
  void                        *string1s = NULL;
  void                        *string2s = NULL;
  void                        *string3s = NULL;
  marpaESLIFAction_t           defaultFreeAction;

  marpaESLIF_paramIsGrammarv(aTHX_ Perl_grammarp);
  if (items > 3) {
    marpaESLIF_paramIsEncodingv(aTHX_ Perl_encodingp = ST(3));
    string1s = marpaESLIF_sv2byte(aTHX_ Perl_encodingp,
                                  &(marpaESLIFGrammarOption.encodings),
                                  &(marpaESLIFGrammarOption.encodingl),
                                  1, /* encodingInformationb */
                                  NULL, /* characterStreambp */
                                  &(marpaESLIFGrammarOption.encodingOfEncodings),
                                  NULL, /* encodingsp */
                                  NULL, /* encodinglp */
                                  1 /* warnIsFatalb */);
    string2s = marpaESLIF_sv2byte(aTHX_ Perl_grammarp,
                                  (char **) &(marpaESLIFGrammarOption.bytep),
                                  &(marpaESLIFGrammarOption.bytel),
                                  0, /* encodingInformationb */
                                  NULL, /* characterStreambp */
                                  NULL, /* encodingOfEncodingsp */
                                  NULL, /* encodingsp */
                                  NULL, /* encodinglp */
                                  1 /* warnIsFatalb */);
  } else {
    string3s = marpaESLIF_sv2byte(aTHX_ Perl_grammarp,
                                  (char **) &(marpaESLIFGrammarOption.bytep),
                                  &(marpaESLIFGrammarOption.bytel),
                                  1, /* encodingInformationb */
                                  NULL, /* characterStreambp */
                                  &(marpaESLIFGrammarOption.encodingOfEncodings),
                                  &(marpaESLIFGrammarOption.encodings),
                                  &(marpaESLIFGrammarOption.encodingl),
                                  1 /* warnIsFatalb */);
  }

  Newx(Perl_MarpaX_ESLIF_Grammarp, 1, MarpaX_ESLIF_Grammar_t);
  marpaESLIF_grammarContextInit(aTHX_ ST(1) /* SV of eslif */, Perl_MarpaX_ESLIF_Grammarp);

  /* We use the "unsafe" version because we made sure in ESLIF.pm that marpaESLIFp was reallocated at every new interpreter (== perl thread) */
  marpaESLIFGrammarp = marpaESLIFGrammar_unsafe_newp(((MarpaX_ESLIF_Engine) Perl_MarpaX_ESLIF_Enginep)->marpaESLIFp, &marpaESLIFGrammarOption);
  if (marpaESLIFGrammarp == NULL) {
    int save_errno = errno;
    marpaESLIF_grammarContextFreev(aTHX_ Perl_MarpaX_ESLIF_Grammarp);
    MARPAESLIF_CROAKF("marpaESLIFGrammar_newp failure, %s", strerror(save_errno));
  }
  Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp = marpaESLIFGrammarp;

  /* We want to take control over the free default action, and put something that is illegal via normal parse */
  if (! marpaESLIFGrammar_ngrammarib(marpaESLIFGrammarp, &ngrammari)) {
    int save_errno = errno;
    marpaESLIF_grammarContextFreev(aTHX_ Perl_MarpaX_ESLIF_Grammarp);
    if (string1s != NULL) { Safefree(string1s); }
    if (string2s != NULL) { Safefree(string2s); }
    if (string3s != NULL) { Safefree(string3s); }
    MARPAESLIF_CROAKF("marpaESLIFGrammar_ngrammarib failure, %s", strerror(save_errno));
  }
  for (i = 0; i < ngrammari; i++) {
    if (! marpaESLIFGrammar_defaults_by_levelb(marpaESLIFGrammarp, &marpaESLIFGrammarDefaults, i, NULL /* descp */)) {
      int save_errno = errno;
      marpaESLIF_grammarContextFreev(aTHX_ Perl_MarpaX_ESLIF_Grammarp);
      if (string1s != NULL) { Safefree(string1s); }
      if (string2s != NULL) { Safefree(string2s); }
      if (string3s != NULL) { Safefree(string3s); }
      MARPAESLIF_CROAKF("marpaESLIFGrammar_defaults_by_levelb failure, %s", strerror(save_errno));
    }
    defaultFreeAction.type    = MARPAESLIF_ACTION_TYPE_NAME;
    defaultFreeAction.u.names = ":defaultFreeActions";
    marpaESLIFGrammarDefaults.defaultFreeActionp = &defaultFreeAction;
    if (! marpaESLIFGrammar_defaults_by_level_setb(marpaESLIFGrammarp, &marpaESLIFGrammarDefaults, i, NULL /* descp */)) {
      int save_errno = errno;
      marpaESLIF_grammarContextFreev(aTHX_ Perl_MarpaX_ESLIF_Grammarp);
      if (string1s != NULL) { Safefree(string1s); }
      if (string2s != NULL) { Safefree(string2s); }
      if (string3s != NULL) { Safefree(string3s); }
      MARPAESLIF_CROAKF("marpaESLIFGrammar_defaults_by_levelb failure, %s", strerror(save_errno));
    }
  }

  if (string1s != NULL) { Safefree(string1s); }
  if (string2s != NULL) { Safefree(string2s); }
  if (string3s != NULL) { Safefree(string3s); }

  RETVAL = Perl_MarpaX_ESLIF_Grammarp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::DESTROY                                         */
  /* ----------------------------------------------------------------------- */
=cut

void
DESTROY(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  marpaESLIF_grammarContextFreev(aTHX_ Perl_MarpaX_ESLIF_Grammarp);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ngrammar                                        */
  /* ----------------------------------------------------------------------- */
=cut

IV
ngrammar(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ngrammar";
  int                ngrammari;

  if (! marpaESLIFGrammar_ngrammarib(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ngrammari)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ngrammarib failure");
  }

  RETVAL = (IV) ngrammari;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentLevel                                    */
  /* ----------------------------------------------------------------------- */
=cut

IV
currentLevel(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentLevel";
  int                leveli;

  if (! marpaESLIFGrammar_grammar_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammar_currentb failure");
  }
  RETVAL = (IV) leveli;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentDescription                              */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentDescription(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::currentDescription";
  marpaESLIFString_t  *descp;
  SV                  *svp;

  if (! marpaESLIFGrammar_grammar_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, NULL, &descp)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammar_currentb failure");
  }
  /* It is in the same encoding as original grammar */
  svp = newSVpvn(descp->bytep, descp->bytel);
  if (is_utf8_string((const U8 *) descp->bytep, (STRLEN) descp->bytel)) {
    SvUTF8_on(svp);
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::descriptionByLevel                              */
  /* ----------------------------------------------------------------------- */
=cut

SV *
descriptionByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::descriptionByLevel";
  marpaESLIFString_t  *descp;
  SV                  *svp;

  if (! marpaESLIFGrammar_grammar_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_leveli, NULL, NULL, &descp)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammar_by_levelb failure");
  }
  /* It is in the same encoding as original grammar */
  svp = newSVpvn(descp->bytep, descp->bytel);
  if (is_utf8_string((const U8 *) descp->bytep, (STRLEN) descp->bytel)) {
    SvUTF8_on(svp);
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentRuleIds                                  */
  /* ----------------------------------------------------------------------- */
=cut

AV *
currentRuleIds(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::currentRuleIds";
  int                 *ruleip;
  size_t               rulel;
  size_t               i;
  AV                  *av;

  if (! marpaESLIFGrammar_rulearray_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ruleip, &rulel)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_rulearray_currentb failure");
  }
  if (rulel <= 0) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_rulearray_currentb returned no rule");
  }
  av = newAV();
  for (i = 0; i < rulel; i++) {
    av_push(av, newSViv((IV) ruleip[i]));
  }
  RETVAL = av;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleIdsByLevel                                  */
  /* ----------------------------------------------------------------------- */
=cut

AV *
ruleIdsByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::ruleIdsByLevel";
  int                 *ruleip;
  size_t               rulel;
  size_t               i;
  AV                  *av;

  if (! marpaESLIFGrammar_rulearray_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ruleip, &rulel, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_rulearray_by_levelb failure");
  }
  if (rulel <= 0) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_rulearray_by_levelb returned no rule");
  }
  av = newAV();
  for (i = 0; i < rulel; i++) {
    av_push(av, newSViv((IV) ruleip[i]));
  }
  RETVAL = av;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentSymbolIds                                */
  /* ----------------------------------------------------------------------- */
=cut

AV *
currentSymbolIds(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::currentSymbolIds";
  int                 *symbolip;
  size_t               symboll;
  size_t               i;
  AV                  *av;

  if (! marpaESLIFGrammar_symbolarray_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &symbolip, &symboll)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolarray_currentb failure");
  }
  if (symboll <= 0) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolarray_currentb returned no symbol");
  }
  av = newAV();
  for (i = 0; i < symboll; i++) {
    av_push(av, newSViv((IV) symbolip[i]));
  }
  RETVAL = av;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::symbolIdsByLevel                                */
  /* ----------------------------------------------------------------------- */
=cut

AV *
symbolIdsByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
CODE:
  static const char   *funcs = "MarpaX::ESLIF::Grammar::symbolIdsByLevel";
  int                 *symbolip;
  size_t               symboll;
  size_t               i;
  AV                  *av;

  if (! marpaESLIFGrammar_symbolarray_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &symbolip, &symboll, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolarray_by_levelb failure");
  }
  if (symboll <= 0) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolarray_by_levelb returned no symbol");
  }
  av = newAV();
  for (i = 0; i < symboll; i++) {
    av_push(av, newSViv((IV) symbolip[i]));
  }
  RETVAL = av;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentProperties                               */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentProperties(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char           *funcs = "MarpaX::ESLIF::Grammar::currentProperties";
  marpaESLIFGrammarProperty_t  grammarProperty;
  AV                          *avp;

  if (! marpaESLIFGrammar_grammarproperty_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &grammarProperty)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammarproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV     (avp, "level",               grammarProperty.leveli);
  MARPAESLIF_XV_STORE_IV     (avp, "maxLevel",            grammarProperty.maxLeveli);
  MARPAESLIF_XV_STORE_STRING (avp, "description",         grammarProperty.descp);
  MARPAESLIF_XV_STORE_IV     (avp, "latm",                grammarProperty.latmb);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultFreeAction",   grammarProperty.defaultFreeActionp);
  MARPAESLIF_XV_STORE_IV     (avp, "startId",             grammarProperty.starti);
  MARPAESLIF_XV_STORE_IV     (avp, "discardId",           grammarProperty.discardi);
  MARPAESLIF_XV_STORE_IVARRAY(avp, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIF_XV_STORE_IVARRAY(avp, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::propertiesByLevel                               */
  /* ----------------------------------------------------------------------- */
=cut

SV *
propertiesByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
CODE:
  static const char           *funcs = "MarpaX::ESLIF::Grammar::propertiesByLevel";
  marpaESLIFGrammarProperty_t  grammarProperty;
  AV                          *avp;

  if (! marpaESLIFGrammar_grammarproperty_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &grammarProperty, (int) Perl_leveli, NULL /* descp */)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammarproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV     (avp, "level",               grammarProperty.leveli);
  MARPAESLIF_XV_STORE_IV     (avp, "maxLevel",            grammarProperty.maxLeveli);
  MARPAESLIF_XV_STORE_STRING (avp, "description",         grammarProperty.descp);
  MARPAESLIF_XV_STORE_IV     (avp, "latm",                grammarProperty.latmb);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIF_XV_STORE_ACTION (avp, "defaultFreeAction",   grammarProperty.defaultFreeActionp);
  MARPAESLIF_XV_STORE_IV     (avp, "startId",             grammarProperty.starti);
  MARPAESLIF_XV_STORE_IV     (avp, "discardId",           grammarProperty.discardi);
  MARPAESLIF_XV_STORE_IVARRAY(avp, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIF_XV_STORE_IVARRAY(avp, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentRuleProperties                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentRuleProperties(Perl_MarpaX_ESLIF_Grammarp, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_rulei;
CODE:
  static const char        *funcs = "MarpaX::ESLIF::Grammar::currentRuleProperties";
  marpaESLIFRuleProperty_t  ruleProperty;
  AV                       *avp;

  if (! marpaESLIFGrammar_ruleproperty_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleProperty)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruleproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV         (avp, "id",                       ruleProperty.idi);
  MARPAESLIF_XV_STORE_STRING     (avp, "description",              ruleProperty.descp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "show",                     ruleProperty.asciishows);
  MARPAESLIF_XV_STORE_IV         (avp, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIF_XV_STORE_IV         (avp, "separatorId",              ruleProperty.separatori);
  MARPAESLIF_XV_STORE_IVARRAY    (avp, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIF_XV_STORE_IV         (avp, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIF_XV_STORE_ACTION     (avp, "action",                   ruleProperty.actionp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIF_XV_STORE_IV         (avp, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIF_XV_STORE_IV         (avp, "rank",                     ruleProperty.ranki);
  MARPAESLIF_XV_STORE_IV         (avp, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIF_XV_STORE_IV         (avp, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIF_XV_STORE_IV         (avp, "proper",                   ruleProperty.properb);
  MARPAESLIF_XV_STORE_IV         (avp, "minimum",                  ruleProperty.minimumi);
  MARPAESLIF_XV_STORE_IV         (avp, "internal",                 ruleProperty.internalb);
  MARPAESLIF_XV_STORE_IV         (avp, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIF_XV_STORE_IV         (avp, "hideseparator",            ruleProperty.hideseparatorb);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Rule__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::rulePropertiesByLevel                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
rulePropertiesByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
  IV                   Perl_rulei;
CODE:
  static const char        *funcs = "MarpaX::ESLIF::Grammar::rulePropertiesByLevel";
  marpaESLIFRuleProperty_t  ruleProperty;
  AV                       *avp;

  if (! marpaESLIFGrammar_ruleproperty_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleProperty, (int) Perl_leveli, NULL /* descp */)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruleproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV         (avp, "id",                       ruleProperty.idi);
  MARPAESLIF_XV_STORE_STRING     (avp, "description",              ruleProperty.descp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "show",                     ruleProperty.asciishows);
  MARPAESLIF_XV_STORE_IV         (avp, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIF_XV_STORE_IV         (avp, "separatorId",              ruleProperty.separatori);
  MARPAESLIF_XV_STORE_IVARRAY    (avp, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIF_XV_STORE_IV         (avp, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIF_XV_STORE_ACTION     (avp, "action",                   ruleProperty.actionp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIF_XV_STORE_IV         (avp, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIF_XV_STORE_IV         (avp, "rank",                     ruleProperty.ranki);
  MARPAESLIF_XV_STORE_IV         (avp, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIF_XV_STORE_IV         (avp, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIF_XV_STORE_IV         (avp, "proper",                   ruleProperty.properb);
  MARPAESLIF_XV_STORE_IV         (avp, "minimum",                  ruleProperty.minimumi);
  MARPAESLIF_XV_STORE_IV         (avp, "internal",                 ruleProperty.internalb);
  MARPAESLIF_XV_STORE_IV         (avp, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIF_XV_STORE_IV         (avp, "hideseparator",            ruleProperty.hideseparatorb);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Rule__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentSymbolProperties                         */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentSymbolProperties(Perl_MarpaX_ESLIF_Grammarp, Perl_symboli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_symboli;
CODE:
  static const char          *funcs = "MarpaX::ESLIF::Grammar::currentSymbolProperties";
  marpaESLIFSymbolProperty_t  symbolProperty;
  AV                         *avp;

  if (! marpaESLIFGrammar_symbolproperty_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symbolProperty)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV         (avp, "type",                       symbolProperty.type);
  MARPAESLIF_XV_STORE_IV         (avp, "start",                      symbolProperty.startb);
  MARPAESLIF_XV_STORE_IV         (avp, "discard",                    symbolProperty.discardb);
  MARPAESLIF_XV_STORE_IV         (avp, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIF_XV_STORE_IV         (avp, "lhs",                        symbolProperty.lhsb);
  MARPAESLIF_XV_STORE_IV         (avp, "top",                        symbolProperty.topb);
  MARPAESLIF_XV_STORE_IV         (avp, "id",                         symbolProperty.idi);
  MARPAESLIF_XV_STORE_STRING     (avp, "description",                symbolProperty.descp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIF_XV_STORE_IV         (avp, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIF_XV_STORE_IV         (avp, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIF_XV_STORE_IV         (avp, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIF_XV_STORE_IV         (avp, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIF_XV_STORE_IV         (avp, "priority",                   symbolProperty.priorityi);
  MARPAESLIF_XV_STORE_ACTION     (avp, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIF_XV_STORE_IV         (avp, "propertyBitSet",             symbolProperty.propertyBitSet);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Symbol__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::symbolPropertiesByLevel                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
symbolPropertiesByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli, Perl_symboli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
  IV                   Perl_symboli;
CODE:
  static const char        *funcs = "MarpaX::ESLIF::Grammar::symbolPropertiesByLevel";
  marpaESLIFSymbolProperty_t  symbolProperty;
  AV                       *avp;

  if (! marpaESLIFGrammar_symbolproperty_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symbolProperty, (int) Perl_leveli, NULL /* descp */)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symbolproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIF_XV_STORE_IV         (avp, "type",                       symbolProperty.type);
  MARPAESLIF_XV_STORE_IV         (avp, "start",                      symbolProperty.startb);
  MARPAESLIF_XV_STORE_IV         (avp, "discard",                    symbolProperty.discardb);
  MARPAESLIF_XV_STORE_IV         (avp, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIF_XV_STORE_IV         (avp, "lhs",                        symbolProperty.lhsb);
  MARPAESLIF_XV_STORE_IV         (avp, "top",                        symbolProperty.topb);
  MARPAESLIF_XV_STORE_IV         (avp, "id",                         symbolProperty.idi);
  MARPAESLIF_XV_STORE_STRING     (avp, "description",                symbolProperty.descp);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIF_XV_STORE_IV         (avp, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIF_XV_STORE_IV         (avp, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIF_XV_STORE_IV         (avp, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIF_XV_STORE_ASCIISTRING(avp, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIF_XV_STORE_IV         (avp, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIF_XV_STORE_IV         (avp, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIF_XV_STORE_IV         (avp, "priority",                   symbolProperty.priorityi);
  MARPAESLIF_XV_STORE_ACTION     (avp, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIF_XV_STORE_IV         (avp, "propertyBitSet",             symbolProperty.propertyBitSet);

  RETVAL = marpaESLIF_call_actionp(aTHX_ boot_MarpaX__ESLIF__Grammar__Symbol__Properties_svp, "new", avp, NULL /* Perl_MarpaX_ESLIF_Valuep */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleDisplay                                     */
  /* ----------------------------------------------------------------------- */
=cut

char *
ruleDisplay(Perl_MarpaX_ESLIF_Grammarp, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_rulei;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleDisplay";
  char              *ruledisplays;

  if (! marpaESLIFGrammar_ruledisplayform_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruledisplays)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruledisplayform_currentb failure");
  }
  RETVAL = ruledisplays;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::symbolDisplay                                   */
  /* ----------------------------------------------------------------------- */
=cut

char *
symbolDisplay(Perl_MarpaX_ESLIF_Grammarp, Perl_symboli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_symboli;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolDisplay";
  char              *symboldisplays;

  if (! marpaESLIFGrammar_symboldisplayform_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symboldisplays)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symboldisplayform_currentb failure");
  }
  RETVAL = symboldisplays;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleShow                                        */
  /* ----------------------------------------------------------------------- */
=cut

char *
ruleShow(Perl_MarpaX_ESLIF_Grammarp, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_rulei;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleShow";
  char              *ruleshows;

  if (! marpaESLIFGrammar_ruleshowform_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleshows)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruleshowform_currentb failure");
  }
  RETVAL = ruleshows;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleDisplayByLevel                              */
  /* ----------------------------------------------------------------------- */
=cut

char *
ruleDisplayByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
  IV                   Perl_rulei;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleDisplayByLevel";
  char              *ruledisplays;

  if (! marpaESLIFGrammar_ruledisplayform_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruledisplays, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruledisplayform_by_levelb failure");
  }
  RETVAL = ruledisplays;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::symbolDisplayByLevel                            */
  /* ----------------------------------------------------------------------- */
=cut

char *
symbolDisplayByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli, Perl_symboli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
  IV                   Perl_symboli;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolDisplayByLevel";
  char              *symboldisplays;

  if (! marpaESLIFGrammar_symboldisplayform_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symboldisplays, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_symboldisplayform_by_levelb failure");
  }
  RETVAL = symboldisplays;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleShowByLevel                                 */
  /* ----------------------------------------------------------------------- */
=cut

char *
ruleShowByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli, Perl_rulei)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
  IV                   Perl_rulei;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleShowByLevel";
  char              *ruleshows;

  if (! marpaESLIFGrammar_ruleshowform_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleshows, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruleshowform_by_levelb failure");
  }
  RETVAL = ruleshows;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::show                                            */
  /* ----------------------------------------------------------------------- */
=cut

char *
show(Perl_MarpaX_ESLIF_Grammarp)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::show";
  char              *shows;

  if (! marpaESLIFGrammar_grammarshowform_currentb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &shows)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_ruleshowform_by_levelb failure");
  }
  RETVAL = shows;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::showByLevel                                     */
  /* ----------------------------------------------------------------------- */
=cut

char *
showByLevel(Perl_MarpaX_ESLIF_Grammarp, Perl_leveli)
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  IV                   Perl_leveli;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::showByLevel";
  char              *shows;

  if (! marpaESLIFGrammar_grammarshowform_by_levelb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &shows, (int) Perl_leveli, NULL)) {
    MARPAESLIF_CROAK("marpaESLIFGrammar_grammarshowform_by_levelb failure");
  }
  RETVAL = shows;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::parse                                           */
  /* ----------------------------------------------------------------------- */
=cut

bool
parse(Perl_MarpaX_ESLIF_Grammarp, Perl_recognizerInterfacep, Perl_valueInterfacep)
  MarpaX_ESLIF_Grammar  Perl_MarpaX_ESLIF_Grammarp;
  SV                   *Perl_recognizerInterfacep;
  SV                   *Perl_valueInterfacep;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Grammar::parse";
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  marpaESLIFValueResult_t       marpaESLIFValueResult;
  MarpaX_ESLIF_Recognizer_t     marpaESLIFRecognizerContext;
  MarpaX_ESLIF_Value_t          marpaESLIFValueContext;
  short                         exhaustedb;
  SV                           *svp;
  bool                          rcb;

  marpaESLIF_paramIsRecognizerInterfacev(aTHX_ Perl_recognizerInterfacep);
  marpaESLIF_paramIsValueInterfacev(aTHX_ Perl_valueInterfacep);

  marpaESLIF_recognizerContextInit(aTHX_ ST(0) /* SV of grammar */, ST(1) /* SV of recognizer interface */, &marpaESLIFRecognizerContext);
  marpaESLIF_valueContextInit(aTHX_ NULL /* No recognizer */, ST(0) /* SV of grammar */, ST(2) /* SV of value interface */, &marpaESLIFValueContext);
  
  marpaESLIFRecognizerOption.userDatavp                = &marpaESLIFRecognizerContext;
  marpaESLIFRecognizerOption.marpaESLIFReaderCallbackp = marpaESLIF_recognizerReaderCallbackb;
  marpaESLIFRecognizerOption.disableThresholdb         = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithDisableThreshold");
  marpaESLIFRecognizerOption.exhaustedb                = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithExhaustion");
  marpaESLIFRecognizerOption.newlineb                  = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithNewline");
  marpaESLIFRecognizerOption.trackb                    = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithTrack");
  marpaESLIFRecognizerOption.bufsizl                   = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci           = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci               = 50; /* Recommended value */
  
  marpaESLIFValueOption.userDatavp                     = &marpaESLIFValueContext;
  marpaESLIFValueOption.ruleActionResolverp            = marpaESLIF_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp          = marpaESLIF_valueSymbolActionResolver;
  marpaESLIFValueOption.freeActionResolverp            = marpaESLIF_valueFreeActionResolver;
  marpaESLIFValueOption.highRankOnlyb                  = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithHighRankOnly");
  marpaESLIFValueOption.orderByRankb                   = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithOrderByRank");
  marpaESLIFValueOption.ambiguousb                     = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithAmbiguous");
  marpaESLIFValueOption.nullb                          = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithNull");
  marpaESLIFValueOption.maxParsesi                     = (int) marpaESLIF_call_methodi(aTHX_ Perl_valueInterfacep, "maxParses");

  if (! marpaESLIFGrammar_parseb(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption, &marpaESLIFValueOption, &exhaustedb, &marpaESLIFValueResult)) {
    goto err;
  }
  /* It is our responsbility to free the final value */
  switch (marpaESLIFValueResult.type) {
  case MARPAESLIF_VALUE_TYPE_PTR:
    /* This is a user-defined object */
    svp = (SV *) marpaESLIFValueResult.u.p;
    marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setResult", svp);
    MARPAESLIF_REFCNT_DEC(svp);
    break;
  case MARPAESLIF_VALUE_TYPE_ARRAY:
    /* This is a lexeme, or a concatenation of lexemes */
    svp = newSVpvn(marpaESLIFValueResult.u.p, marpaESLIFValueResult.sizel);
    if (is_utf8_string((const U8 *) marpaESLIFValueResult.u.p, (STRLEN) marpaESLIFValueResult.sizel)) {
      SvUTF8_on(svp);
    }
    marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setResult", svp);
    MARPAESLIF_REFCNT_DEC(svp);
    if (marpaESLIFValueResult.u.p != NULL) {
      marpaESLIF_SYSTEM_FREE(marpaESLIFValueResult.u.p);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_UNDEF: /* In the extreme case where symbol-action catched up everything */
    marpaESLIF_call_methodv(aTHX_ Perl_valueInterfacep, "setResult", &PL_sv_undef);
    break;
  default:
    MARPAESLIF_CROAKF("marpaESLIFValueResult.type is not MARPAESLIF_VALUE_TYPE_PTR, MARPAESLIF_VALUE_TYPE_ARRAY nor MARPAESLIF_VALUE_TYPE_UNDEF but %d", marpaESLIFValueResult.type);
  }

  rcb = 1;
  goto done;

  err:
  rcb = 0;

  done:
  marpaESLIF_valueContextFreev(aTHX_ &marpaESLIFValueContext, 1 /* onStackb */);
  marpaESLIF_recognizerContextFreev(aTHX_ &marpaESLIFRecognizerContext, 1 /* onStackb */);
  RETVAL = rcb;
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Recognizer                                               */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Recognizer

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::new                                          */
  /* ----------------------------------------------------------------------- */
=cut

MarpaX_ESLIF_Recognizer
new(Perl_packagep, Perl_MarpaX_ESLIF_Grammarp, Perl_recognizerInterfacep)
  SV *Perl_packagep;
  MarpaX_ESLIF_Grammar Perl_MarpaX_ESLIF_Grammarp;
  SV *Perl_recognizerInterfacep;
CODE:
  static const char            *funcs = "MarpaX::ESLIF::Recognizer::new";
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  MarpaX_ESLIF_Recognizer_t    *Perl_MarpaX_ESLIF_Recognizerp;

  marpaESLIF_paramIsRecognizerInterfacev(aTHX_ Perl_recognizerInterfacep);

  Newx(Perl_MarpaX_ESLIF_Recognizerp, 1, MarpaX_ESLIF_Recognizer_t);
  marpaESLIF_recognizerContextInit(aTHX_ ST(1) /* SV of MarpaX::ESLIF::Grammar */, ST(2) /* SV of recognizer interface */, Perl_MarpaX_ESLIF_Recognizerp);

  /* We need a lexeme stack in this mode (in contrary to the parse() method never calls back) */
  Perl_MarpaX_ESLIF_Recognizerp->lexemeStackp = marpaESLIF_GENERICSTACK_NEW();
  if (Perl_MarpaX_ESLIF_Recognizerp->lexemeStackp == NULL) {
    int save_errno = errno;
    marpaESLIF_recognizerContextFreev(aTHX_ Perl_MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);
    MARPAESLIF_CROAKF("GENERICSTACK_NEW() failure, %s", strerror(save_errno));
  }

  marpaESLIFRecognizerOption.userDatavp                = Perl_MarpaX_ESLIF_Recognizerp;
  marpaESLIFRecognizerOption.marpaESLIFReaderCallbackp = marpaESLIF_recognizerReaderCallbackb;
  marpaESLIFRecognizerOption.disableThresholdb         = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithDisableThreshold");
  marpaESLIFRecognizerOption.exhaustedb                = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithExhaustion");
  marpaESLIFRecognizerOption.newlineb                  = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithNewline");
  marpaESLIFRecognizerOption.trackb                    = marpaESLIF_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithTrack");
  marpaESLIFRecognizerOption.bufsizl                   = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci           = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci               = 50; /* Recommended value */

  Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(Perl_MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption);
  if (Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp == NULL) {
    int save_errno = errno;
    marpaESLIF_recognizerContextFreev(aTHX_ Perl_MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_newp failure, %s", strerror(errno));
  }

  RETVAL = Perl_MarpaX_ESLIF_Recognizerp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::DESTROY                                      */
  /* ----------------------------------------------------------------------- */
=cut

void
DESTROY(Perl_MarpaX_ESLIF_Recognizerp)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizerp;
CODE:
  marpaESLIF_recognizerContextFreev(aTHX_ Perl_MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isCanContinue                                */
  /* ----------------------------------------------------------------------- */
=cut

bool
isCanContinue(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  RETVAL = (bool) Perl_MarpaX_ESLIF_Recognizer->canContinueb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isExhausted                                  */
  /* ----------------------------------------------------------------------- */
=cut

bool
isExhausted(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  RETVAL = (bool) Perl_MarpaX_ESLIF_Recognizer->exhaustedb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::scan                                         */
  /* ----------------------------------------------------------------------- */
=cut

bool
scan(Perl_MarpaX_ESLIF_Recognizer, ...)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::scan";
  short initialEventsb;

  if (items > 1) {
    SV *Perl_initialEvents = ST(1);
    if ((marpaESLIF_getTypei(aTHX_ Perl_initialEvents) & SCALAR) != SCALAR) {
      MARPAESLIF_CROAK("First argument must be a scalar");
    }
    initialEventsb = SvIV(Perl_initialEvents) ? 1 : 0;
  } else {
    initialEventsb = 0;
  }

  RETVAL = (bool) marpaESLIFRecognizer_scanb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, initialEventsb, &(Perl_MarpaX_ESLIF_Recognizer->canContinueb), &(Perl_MarpaX_ESLIF_Recognizer->exhaustedb));
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::resume                                       */
  /* ----------------------------------------------------------------------- */
=cut

bool
resume(Perl_MarpaX_ESLIF_Recognizer, ...)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::resume";
  int deltaLength;

  if (items > 1) {
    SV *Perl_deltaLength = ST(1);
    if ((marpaESLIF_getTypei(aTHX_ Perl_deltaLength) & SCALAR) != SCALAR) {
      MARPAESLIF_CROAK("First argument must be a scalar");
    }
    deltaLength = (int) SvIV(Perl_deltaLength);
  } else {
    deltaLength = 0;
  }

  if (deltaLength < 0) {
    MARPAESLIF_CROAK("Resume delta length cannot be negative");
  }
  RETVAL = (bool) marpaESLIFRecognizer_resumeb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, (size_t) deltaLength, &(Perl_MarpaX_ESLIF_Recognizer->canContinueb), &(Perl_MarpaX_ESLIF_Recognizer->exhaustedb));
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::events                                       */
  /* ----------------------------------------------------------------------- */
=cut

SV *
events(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::events";
  AV                *list = (AV *)sv_2mortal((SV *)newAV());
  HV                *hv;
  size_t             i;
  size_t             eventArrayl;
  marpaESLIFEvent_t *eventArrayp;
  SV                *svp;

  if (! marpaESLIFRecognizer_eventb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &eventArrayl, &eventArrayp)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_eventb failure, %s", strerror(errno));
  }
  for (i = 0; i < eventArrayl; i++) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    if (hv_store(hv, "type", strlen("type"), newSViv(eventArrayp[i].type), 0) == NULL) {
      MARPAESLIF_CROAKF("hv_store failure for type => %d", eventArrayp[i].type);
    }

    if (eventArrayp[i].symbols != NULL) {
      svp = newSVpv(eventArrayp[i].symbols, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].symbols, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = &PL_sv_undef;
    }
    if (hv_store(hv, "symbol", strlen("symbol"), svp, 0) == NULL) {
      MARPAESLIF_CROAKF("hv_store failure for symbol => %s", (eventArrayp[i].symbols != NULL) ? eventArrayp[i].symbols : "");
    }

    if (eventArrayp[i].events != NULL) {
      svp = newSVpv(eventArrayp[i].events, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].events, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = &PL_sv_undef;
    }
    if (hv_store(hv, "event",  strlen("event"),  svp, 0) == NULL) {
      MARPAESLIF_CROAKF("hv_store failure for event => %s", (eventArrayp[i].events != NULL) ? eventArrayp[i].events : "");
    }

    av_push(list, newRV((SV *)hv));
  }

  RETVAL = newRV((SV *)list);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::eventOnOff                                   */
  /* ----------------------------------------------------------------------- */
=cut

void
eventOnOff(Perl_MarpaX_ESLIF_Recognizer, symbol, eventTypes, onOff)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *symbol;
  AV                     *eventTypes;
  bool                    onOff;
CODE:
  static const char     *funcs = "MarpaX::ESLIF::Recognizer::eventOnOff";
  SSize_t                avsizel = av_len(eventTypes) + 1;
  SSize_t                aviteratorl;
  marpaESLIFEventType_t  eventSeti  = MARPAESLIF_EVENTTYPE_NONE;

  for (aviteratorl = 0; aviteratorl < avsizel; aviteratorl++) {
    int  codei;
    SV **svpp = av_fetch(eventTypes, aviteratorl, 0);
    if (svpp == NULL) {
      MARPAESLIF_CROAK("av_fetch returned NULL");
    }
    if ((marpaESLIF_getTypei(aTHX_ *svpp) & SCALAR) != SCALAR) {
      MARPAESLIF_CROAKF("Element No %d of array must be a scalar", (int) aviteratorl);
    }
    codei = (int) SvIV(*svpp);
    switch (codei) {
    case MARPAESLIF_EVENTTYPE_NONE:
      break;
    case MARPAESLIF_EVENTTYPE_COMPLETED:
    case MARPAESLIF_EVENTTYPE_NULLED:
    case MARPAESLIF_EVENTTYPE_PREDICTED:
    case MARPAESLIF_EVENTTYPE_BEFORE:
    case MARPAESLIF_EVENTTYPE_AFTER:
    case MARPAESLIF_EVENTTYPE_EXHAUSTED:
    case MARPAESLIF_EVENTTYPE_DISCARD:
      eventSeti |= codei;
      break;
    default:
      MARPAESLIF_CROAKF("Unknown code %d", (int) codei);
      break;
    }
  }

  if (! marpaESLIFRecognizer_event_onoffb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, symbol, eventSeti, onOff ? 1 : 0)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_event_onoffb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeAlternative                            */
  /* ----------------------------------------------------------------------- */
=cut

bool
lexemeAlternative(Perl_MarpaX_ESLIF_Recognizer, name, sv, ...)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
  SV                     *sv;
CODE:
  static const char       *funcs = "MarpaX::ESLIF::Recognizer::lexemeAlternative";
  marpaESLIFAlternative_t  marpaESLIFAlternative;
  int                      grammarLength;

  if (items > 3) {
    SV *Perl_grammarLength = ST(3);
    if ((marpaESLIF_getTypei(aTHX_ Perl_grammarLength) & SCALAR) != SCALAR) {
      MARPAESLIF_CROAK("Third argument must be a scalar");
    }
    grammarLength = (int) SvIV(Perl_grammarLength);
  } else {
    grammarLength = 1;
  }

  if (grammarLength <= 0) {
    MARPAESLIF_CROAK("grammarLength cannot be <= 0");
  }
  /* We maintain lifetime of this object */
  sv = SvREFCNT_inc(sv);
  marpaESLIF_GENERICSTACK_PUSH_PTR(Perl_MarpaX_ESLIF_Recognizer->lexemeStackp, sv);
  if (marpaESLIF_GENERICSTACK_ERROR(Perl_MarpaX_ESLIF_Recognizer->lexemeStackp)) {
    MARPAESLIF_CROAKF("Perl_MarpaX_ESLIF_Recognizer->lexemeStackp push failure, %s", strerror(errno));
  }

  marpaESLIFAlternative.lexemes               = (char *) name;
  marpaESLIFAlternative.value.type            = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFAlternative.value.u.p             = sv;
  marpaESLIFAlternative.value.contexti        = 0; /* Not used */
  marpaESLIFAlternative.value.sizel           = 0; /* Not used */
  marpaESLIFAlternative.value.representationp = marpaESLIF_representation;
  marpaESLIFAlternative.grammarLengthl        = (size_t) grammarLength;

  RETVAL = (bool) marpaESLIFRecognizer_lexeme_alternativeb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &marpaESLIFAlternative);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeComplete                               */
  /* ----------------------------------------------------------------------- */
=cut

bool
lexemeComplete(Perl_MarpaX_ESLIF_Recognizer, length)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  int                     length;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lexemeComplete";

  if (length < 0) {
    MARPAESLIF_CROAK("Length cannot be < 0");
  }

  RETVAL = (bool) marpaESLIFRecognizer_lexeme_completeb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, (size_t) length);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeRead                                   */
  /* ----------------------------------------------------------------------- */
=cut

bool
lexemeRead(Perl_MarpaX_ESLIF_Recognizer, name, sv, length, ...)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
  SV                     *sv;
  int                     length;
CODE:
  static const char       *funcs = "MarpaX::ESLIF::Recognizer::lexemeRead";
  marpaESLIFAlternative_t  marpaESLIFAlternative;
  int                      grammarLength = 1;

  if (items > 4) {
    SV *Perl_grammarLength = ST(4);
    if ((marpaESLIF_getTypei(aTHX_ Perl_grammarLength) & SCALAR) != SCALAR) {
      MARPAESLIF_CROAK("Fourth argument must be a scalar");
    }
    grammarLength = (int) SvIV(Perl_grammarLength);
  }

  if (grammarLength <= 0) {
    MARPAESLIF_CROAK("grammarLength cannot be <= 0");
  }
  /* We maintain lifetime of this object */
  sv = SvREFCNT_inc(sv);
  marpaESLIF_GENERICSTACK_PUSH_PTR(Perl_MarpaX_ESLIF_Recognizer->lexemeStackp, sv);
  if (marpaESLIF_GENERICSTACK_ERROR(Perl_MarpaX_ESLIF_Recognizer->lexemeStackp)) {
    MARPAESLIF_CROAKF("Perl_MarpaX_ESLIF_Recognizer->lexemeStackp push failure, %s", strerror(errno));
  }

  marpaESLIFAlternative.lexemes               = (char *) name;
  marpaESLIFAlternative.value.type            = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFAlternative.value.u.p             = sv;
  marpaESLIFAlternative.value.contexti        = 0; /* Not used */
  marpaESLIFAlternative.value.sizel           = 0; /* Not used */
  marpaESLIFAlternative.value.representationp = marpaESLIF_representation;
  marpaESLIFAlternative.grammarLengthl        = (size_t) grammarLength;

  RETVAL = (bool) marpaESLIFRecognizer_lexeme_readb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &marpaESLIFAlternative, (size_t) length);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeTry                                    */
  /* ----------------------------------------------------------------------- */
=cut

bool
lexemeTry(Perl_MarpaX_ESLIF_Recognizer, name)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lexemeTry";
  short              rcb;

  if (! marpaESLIFRecognizer_lexeme_tryb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, name, &rcb)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_lexeme_tryb failure, %s", strerror(errno));
  }
  RETVAL = (bool) rcb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::discardTry                                   */
  /* ----------------------------------------------------------------------- */
=cut

bool
discardTry(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discardTry";
  short              rcb;

  if (! marpaESLIFRecognizer_discard_tryb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &rcb)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_discard_tryb failure, %s", strerror(errno));
  }
  RETVAL = (bool) rcb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeExpected                               */
  /* ----------------------------------------------------------------------- */
=cut

SV *
lexemeExpected(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lexemeExpected";
  AV                *list = (AV *)sv_2mortal((SV *)newAV());
  size_t             nLexeme;
  size_t             i;
  char             **lexemesArrayp;
  SV                *svp;

  if (! marpaESLIFRecognizer_lexeme_expectedb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &nLexeme, &lexemesArrayp)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_lexeme_expectedb failure, %s", strerror(errno));
  }
  if (nLexeme > 0) {
    EXTEND(sp, (int) nLexeme);
    for (i = 0; i < nLexeme; i++) {
      if (lexemesArrayp[i] != NULL) {
        svp = newSVpv(lexemesArrayp[i], 0);
        if (is_utf8_string((const U8 *) lexemesArrayp[i], 0)) {
          SvUTF8_on(svp);
        }
      } else {
        svp = &PL_sv_undef;
      }
      av_push(list, svp);
    }
  }
  RETVAL = newRV((SV *)list);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeLastPause                              */
  /* ----------------------------------------------------------------------- */
=cut

SV *
lexemeLastPause(Perl_MarpaX_ESLIF_Recognizer, lexeme)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *lexeme;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lexemeLastPause";
  char              *pauses;
  size_t             pausel;
  SV                *svp;

  if (!  marpaESLIFRecognizer_lexeme_last_pauseb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, (char *) lexeme, &pauses, &pausel)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_lexeme_last_pauseb failure, %s", strerror(errno));
  }
  if ((pauses != NULL) && (pausel > 0)) {
    svp = newSVpvn(pauses, pausel);
    if (is_utf8_string((const U8 *) pauses, (STRLEN) pausel)) {
      SvUTF8_on(svp);
    }
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lexemeLastTry                                */
  /* ----------------------------------------------------------------------- */
=cut

SV *
lexemeLastTry(Perl_MarpaX_ESLIF_Recognizer, lexeme)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *lexeme;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lexemeLastTry";
  char              *trys;
  size_t             tryl;
  SV                *svp;

  if (!  marpaESLIFRecognizer_lexeme_last_tryb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, (char *) lexeme, &trys, &tryl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_lexeme_last_tryb failure, %s", strerror(errno));
  }
  if ((trys != NULL) && (tryl > 0)) {
    svp = newSVpvn(trys, tryl);
    if (is_utf8_string((const U8 *) trys, (STRLEN) tryl)) {
      SvUTF8_on(svp);
    }
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::discardLastTry                               */
  /* ----------------------------------------------------------------------- */
=cut

SV *
discardLastTry(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discardLastTry";
  char              *discards;
  size_t             discardl;
  SV                *svp;

  if (!  marpaESLIFRecognizer_discard_last_tryb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &discards, &discardl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_discard_last_tryb failure, %s", strerror(errno));
  }
  if ((discards != NULL) && (discardl > 0)) {
    svp = newSVpvn(discards, discardl);
    if (is_utf8_string((const U8 *) discards, (STRLEN) discardl)) {
      SvUTF8_on(svp);
    }
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isEof                                        */
  /* ----------------------------------------------------------------------- */
=cut

bool
isEof(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::isEof";
  short              eofb;

  if (! marpaESLIFRecognizer_isEofb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &eofb)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_isEofb failure, %s", strerror(errno));
  }
  RETVAL = (bool) eofb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::read                                         */
  /* ----------------------------------------------------------------------- */
=cut

bool
read(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::read";

  RETVAL = (bool) marpaESLIFRecognizer_readb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, NULL, NULL);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::input                                        */
  /* ----------------------------------------------------------------------- */
=cut

SV *
input(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::input";
  char              *inputs;
  size_t             inputl;
  SV                *svp;

  if (! marpaESLIFRecognizer_inputb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &inputs, &inputl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_inputb failure, %s", strerror(errno));
  }
  if ((inputs != NULL) && (inputl > 0)) {
    svp = newSVpvn(inputs, inputl);
    if (is_utf8_string((const U8 *) inputs, (STRLEN) inputl)) {
      SvUTF8_on(svp);
    }
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::progressLog                                  */
  /* ----------------------------------------------------------------------- */
=cut

void
progressLog(Perl_MarpaX_ESLIF_Recognizer, start, end, level)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  int                     start;
  int                     end;
  int                     level;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::progressLog";

  switch (level) {
  case GENERICLOGGER_LOGLEVEL_TRACE:
  case GENERICLOGGER_LOGLEVEL_DEBUG:
  case GENERICLOGGER_LOGLEVEL_INFO:
  case GENERICLOGGER_LOGLEVEL_NOTICE:
  case GENERICLOGGER_LOGLEVEL_WARNING:
  case GENERICLOGGER_LOGLEVEL_ERROR:
  case GENERICLOGGER_LOGLEVEL_CRITICAL:
  case GENERICLOGGER_LOGLEVEL_ALERT:
  case GENERICLOGGER_LOGLEVEL_EMERGENCY:
    break;
  default:
    MARPAESLIF_CROAKF("Unknown logger level %d", (int) level);
    break;
  }

  if (! marpaESLIFRecognizer_progressLogb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, (int) start, (int) end, (int) level)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_progressLogb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lastCompletedOffset                          */
  /* ----------------------------------------------------------------------- */
=cut

IV
lastCompletedOffset(Perl_MarpaX_ESLIF_Recognizer, name)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedOffset";
  char              *offsetp;

  if (!  marpaESLIFRecognizer_last_completedb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, name, &offsetp, NULL /* lengthlp */)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
  }
  RETVAL = PTR2IV(offsetp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lastCompletedLength                          */
  /* ----------------------------------------------------------------------- */
=cut

IV
lastCompletedLength(Perl_MarpaX_ESLIF_Recognizer, name)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedLength";
  size_t             lengthl;

  if (!  marpaESLIFRecognizer_last_completedb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, name, NULL /* offsetpp */, &lengthl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
  }
  RETVAL = (IV) lengthl;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lastCompletedLocation                        */
  /* ----------------------------------------------------------------------- */
=cut

void
lastCompletedLocation(Perl_MarpaX_ESLIF_Recognizer, name)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  char                   *name;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedLocation";
  size_t             lengthl;
  char              *offsetp;
PPCODE:
  if (!  marpaESLIFRecognizer_last_completedb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, name, &offsetp, &lengthl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
  }
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(PTR2IV(offsetp))));
  PUSHs(sv_2mortal(newSViv((IV) lengthl)));

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::line                                         */
  /* ----------------------------------------------------------------------- */
=cut

IV
line(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::line";
  size_t             linel;

  if (!  marpaESLIFRecognizer_locationb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &linel, NULL /* columnlp */)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
  }
  RETVAL = (IV) linel;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::column                                       */
  /* ----------------------------------------------------------------------- */
=cut

IV
column(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
CODE:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::column";
  size_t             columnl;

  if (!  marpaESLIFRecognizer_locationb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, NULL /* linelp */, &columnl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
  }
  RETVAL = (IV) columnl;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::location                                     */
  /* ----------------------------------------------------------------------- */
=cut

void
location(Perl_MarpaX_ESLIF_Recognizer)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::location";
  size_t             linel;
  size_t             columnl;
PPCODE:
  if (!  marpaESLIFRecognizer_locationb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, &linel, &columnl)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
  }
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv((IV) linel)));
  PUSHs(sv_2mortal(newSViv((IV) columnl)));

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::hookDiscard                                  */
  /* ----------------------------------------------------------------------- */
=cut

void
hookDiscard(Perl_MarpaX_ESLIF_Recognizer, discardOnOffb)
  MarpaX_ESLIF_Recognizer Perl_MarpaX_ESLIF_Recognizer;
  short discardOnOffb;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::hookDiscard";
PPCODE:
  if (!  marpaESLIFRecognizer_hook_discardb(Perl_MarpaX_ESLIF_Recognizer->marpaESLIFRecognizerp, discardOnOffb)) {
    MARPAESLIF_CROAKF("marpaESLIFRecognizer_hook_discardb failure, %s", strerror(errno));
  }

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Value

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::new                                               */
  /* ----------------------------------------------------------------------- */
=cut

MarpaX_ESLIF_Value
new(Perl_packagep, Perl_MarpaX_ESLIF_Recognizerp, Perl_valueInterfacep)
  SV                      *Perl_packagep;
  MarpaX_ESLIF_Recognizer  Perl_MarpaX_ESLIF_Recognizerp;
  SV                      *Perl_valueInterfacep;
CODE:
  static const char        *funcs = "MarpaX::ESLIF::Value::new";
  MarpaX_ESLIF_Value        Perl_MarpaX_ESLIF_Valuep;
  marpaESLIFValueOption_t   marpaESLIFValueOption;

  marpaESLIF_paramIsValueInterfacev(aTHX_ Perl_valueInterfacep);

  Newx(Perl_MarpaX_ESLIF_Valuep, 1, MarpaX_ESLIF_Value_t);
  marpaESLIF_valueContextInit(aTHX_ ST(1) /* SV of recognizer */, Perl_MarpaX_ESLIF_Recognizerp->Perl_MarpaX_ESLIF_Grammarp, ST(2) /* SV of value interface */, Perl_MarpaX_ESLIF_Valuep);

  marpaESLIFValueOption.userDatavp            = Perl_MarpaX_ESLIF_Valuep;
  marpaESLIFValueOption.ruleActionResolverp   = marpaESLIF_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp = marpaESLIF_valueSymbolActionResolver;
  marpaESLIFValueOption.freeActionResolverp   = marpaESLIF_valueFreeActionResolver;
  marpaESLIFValueOption.highRankOnlyb         = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithHighRankOnly");
  marpaESLIFValueOption.orderByRankb          = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithOrderByRank");
  marpaESLIFValueOption.ambiguousb            = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithAmbiguous");
  marpaESLIFValueOption.nullb                 = marpaESLIF_call_methodb(aTHX_ Perl_valueInterfacep, "isWithNull");
  marpaESLIFValueOption.maxParsesi            = (int) marpaESLIF_call_methodi(aTHX_ Perl_valueInterfacep, "maxParses");

  Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep = marpaESLIFValue_newp(Perl_MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &marpaESLIFValueOption);
  if (Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep == NULL) {
    int save_errno = errno;
    marpaESLIF_valueContextFreev(aTHX_ Perl_MarpaX_ESLIF_Valuep, 0 /* onStackb */);
    MARPAESLIF_CROAKF("marpaESLIFValue_newp failure, %s", strerror(save_errno));
  }

  RETVAL = Perl_MarpaX_ESLIF_Valuep;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::DESTROY                                           */
  /* ----------------------------------------------------------------------- */
=cut

void
DESTROY(Perl_MarpaX_ESLIF_Valuep)
  MarpaX_ESLIF_Value Perl_MarpaX_ESLIF_Valuep;
CODE:
  marpaESLIF_valueContextFreev(aTHX_ Perl_MarpaX_ESLIF_Valuep, 0 /* onStackb */);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::value                                             */
  /* ----------------------------------------------------------------------- */
=cut

bool
value(Perl_MarpaX_ESLIF_Valuep)
  MarpaX_ESLIF_Value Perl_MarpaX_ESLIF_Valuep;
CODE:
  static const char       *funcs = "MarpaX::ESLIF::Value::value";
  short                    valueb;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  SV                      *svp;

  valueb = marpaESLIFValue_valueb(Perl_MarpaX_ESLIF_Valuep->marpaESLIFValuep, &marpaESLIFValueResult);
  if (valueb < 0) {
    MARPAESLIF_CROAKF("marpaESLIFValue_valueb failure, %s", strerror(errno));
  }
  if (valueb > 0) {
    /* It is our responsbility to free the final value */
    switch (marpaESLIFValueResult.type) {
    case MARPAESLIF_VALUE_TYPE_PTR:
      /* This is a user-defined object */
      svp = (SV *) marpaESLIFValueResult.u.p;
      marpaESLIF_call_methodv(aTHX_ Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep, "setResult", svp);
      MARPAESLIF_REFCNT_DEC(svp);
      break;
    case MARPAESLIF_VALUE_TYPE_ARRAY:
      /* This is a lexeme, or a concatenation of lexemes */
      svp = newSVpvn(marpaESLIFValueResult.u.p, marpaESLIFValueResult.sizel);
      if (is_utf8_string((const U8 *) marpaESLIFValueResult.u.p, (STRLEN) marpaESLIFValueResult.sizel)) {
        SvUTF8_on(svp);
      }
      marpaESLIF_call_methodv(aTHX_ Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep, "setResult", svp);
      MARPAESLIF_REFCNT_DEC(svp);
      if (marpaESLIFValueResult.u.p != NULL) {
        marpaESLIF_SYSTEM_FREE(marpaESLIFValueResult.u.p);
      }
      break;
  case MARPAESLIF_VALUE_TYPE_UNDEF: /* In the extreme case where symbol-action catched up everything */
      marpaESLIF_call_methodv(aTHX_ Perl_MarpaX_ESLIF_Valuep->Perl_valueInterfacep, "setResult", &PL_sv_undef);
      break;
    default:
      MARPAESLIF_CROAKF("marpaESLIFValueResult.type is not MARPAESLIF_VALUE_TYPE_PTR, MARPAESLIF_VALUE_TYPE_ARRAY nor MARPAESLIF_VALUE_TYPE_UNDEF but %d", marpaESLIFValueResult.type);
    }
    RETVAL = (bool) 1;
  } else {
   RETVAL = (bool) 0;
  }
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Event::Type                                              */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Event::Type

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Event::Type::constant                                    */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-event-types.inc

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Value::Type                                              */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Value::Type

PROTOTYPES: ENABLE


=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::Type::constant                                    */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-value-types.inc

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Logger::Level                                            */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Logger::Level

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Logger::Level::constant                                  */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-loggerLevel-types.inc

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Rule::PropertyBitSet                                     */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Rule::PropertyBitSet

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Rule::PropertyBitSet::constant                           */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-rulePropertyBitSet-types.inc

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Symbol::PropertyBitSet                                   */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Symbol::PropertyBitSet

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::PropertyBitSet::constant                         */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-symbolPropertyBitSet-types.inc

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Symbol::Type                                             */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Symbol::Type

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::Type::constant                                   */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-symbol-types.inc
