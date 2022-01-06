/* Shall this module determine automatically string encoding ? */
/* #define MARPAESLIFPERL_AUTO_ENCODING_DETECT */

/* When we receive a string claimed to be in UTF-8, shall we cross check ? */
/* #define MARPAESLIFPERL_UTF8_CROSSCHECK */

/* As a general note, we maintain object dependencies in perl itself, because  */
/* EVERY object is a hash that has an 'args_ref' member, the later containting */
/* a reference to all arguments. */

#define PERL_NO_GET_CONTEXT 1     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newSVpvn_flags
#include "ppport.h"

/* We use the internal configuration of ESLIF to benefit for discovery of __builtin_expect() and inline */
#include "marpaESLIF/internal/config.h"

#include <marpaESLIF.h>
#include <genericLogger.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <float.h>
#include <limits.h>
/* #include <valgrind/callgrind.h> */

/* Perl wrapper around malloc, free, etc... are just painful for genericStack, which is */
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

#include <genericStack.h>

static inline void   marpaESLIFPerl_SYSTEM_FREE(void *p)                                         { free(p);                                      }
static inline void   marpaESLIFPerl_GENERICSTACK_INIT(genericStack_t *stackp)                    { GENERICSTACK_INIT(stackp);                    }
static inline void   marpaESLIFPerl_GENERICSTACK_RESET(genericStack_t *stackp)                   { GENERICSTACK_RESET(stackp);                   }
static inline void   marpaESLIFPerl_GENERICSTACK_FREE(genericStack_t *stackp)                    { GENERICSTACK_FREE(stackp);                    }
static inline void  *marpaESLIFPerl_GENERICSTACK_GET_PTR(genericStack_t *stackp, int indicei)    { return GENERICSTACK_GET_PTR(stackp, indicei); }
static inline void  *marpaESLIFPerl_GENERICSTACK_POP_PTR(genericStack_t *stackp)                 { return GENERICSTACK_POP_PTR(stackp);          }
static inline short  marpaESLIFPerl_GENERICSTACK_IS_PTR(genericStack_t *stackp, int indicei)     { return GENERICSTACK_IS_PTR(stackp, indicei);  }
static inline void   marpaESLIFPerl_GENERICSTACK_PUSH_PTR(genericStack_t *stackp, void *p)       { GENERICSTACK_PUSH_PTR(stackp, p);             }
static inline void   marpaESLIFPerl_GENERICSTACK_SET_PTR(genericStack_t *stackp, void *p, int i) { GENERICSTACK_SET_PTR(stackp, p, i);           }
static inline void   marpaESLIFPerl_GENERICSTACK_SET_NA(genericStack_t *stackp, int indicei)     { GENERICSTACK_SET_NA(stackp, indicei);         }
static inline short  marpaESLIFPerl_GENERICSTACK_ERROR(genericStack_t *stackp)                   { return GENERICSTACK_ERROR(stackp);            }
static inline int    marpaESLIFPerl_GENERICSTACK_USED(genericStack_t *stackp)                    { return GENERICSTACK_USED(stackp);             }
static inline int    marpaESLIFPerl_GENERICSTACK_SET_USED(genericStack_t *stackp, int usedi)     { return GENERICSTACK_USED(stackp) = usedi;     }

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

#define MARPAESLIFPERL_CHUNKED_SIZE_UPPER(size, chunk) ((size) < (chunk)) ? (chunk) : ((1 + ((size) / (chunk))) * (chunk))

/* For perl interpret retrieval */
#ifndef tTHX
#  define marpaESLIFPerlTHX PerlInterpreter*
#else
#  define marpaESLIFPerlTHX tTHX
#endif
#ifdef PERL_IMPLICIT_CONTEXT
#  define marpaESLIFPerlaTHX aTHX
#else
#  define marpaESLIFPerlaTHX NULL
#endif

/* Interpret specific things */
typedef struct MarpaX_ESLIF_constants {
  SV *MarpaX__ESLIF_svp;
  SV *MarpaX__ESLIF__is_bool_svp;
  SV *MarpaX__ESLIF__UTF_8_svp;
  SV *Math__BigFloat_svp;
  SV *Math__BigFloat__new_svp;
  SV *Math__BigInt_svp;
  SV *Math__BigInt__new_svp;
  SV *Math__BigInt__binf_svp;
  SV *Math__BigInt__bnan_svp;
  short nvtype_is_long_doubleb;
  short nvtype_is___float128;
  SV *MarpaX__ESLIF__true_svp;
  SV *MarpaX__ESLIF__false_svp;
  SV *MarpaX__ESLIF__Grammar__Properties_svp;
  SV *MarpaX__ESLIF__Grammar__Rule__Properties_svp;
  SV *MarpaX__ESLIF__Grammar__Symbol__Properties_svp;
  SV *MarpaX__ESLIF__String_svp;
  SV *MarpaX__ESLIF__String__new_svp;
  SV *MarpaX__ESLIF__String__encoding_svp;
  SV *MarpaX__ESLIF__String__value_svp;
  SV *Encode_svp;
  SV *Encode__decode_svp;
  SV *MarpaX__ESLIF__Recognizer_svp;
  SV *MarpaX__ESLIF__Recognizer__SHALLOW_svp;
} MarpaX_ESLIF_constants_t;

typedef struct marpaESLIFPerl_stringGeneratorContext {
  char             *s;      /* Pointer */
  size_t            l;      /* Used size */
  short             okb;    /* Status */
  size_t            allocl; /* Allocated size */
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX PerlInterpreterp;
#endif
} marpaESLIFPerl_stringGeneratorContext_t;

typedef struct marpaESLIFPerl_importContext {
  marpaESLIF_t             *marpaESLIFp;
  genericStack_t           *stackp;
  MarpaX_ESLIF_constants_t *constantsp;
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX         PerlInterpreterp;
#endif
} marpaESLIFPerl_importContext_t;


#include "c-constant-types.inc"
#include "c-event-types.inc"
#include "c-value-types.inc"
#include "c-loggerLevel-types.inc"
#include "c-rulePropertyBitSet-types.inc"
#include "c-symbolPropertyBitSet-types.inc"
#include "c-symbolEventBitSet-types.inc"
#include "c-symbol-types.inc"

/* Encode constants as per the documentation */
#define MARPAESLIFPERL_ENCODE_DIE_ON_ERR    0x0001
#define MARPAESLIFPERL_ENCODE_WARN_ON_ERR   0x0002
#define MARPAESLIFPERL_ENCODE_RETURN_ON_ERR 0x0004
#define MARPAESLIFPERL_ENCODE_LEAVE_SRC     0x0008
#define MARPAESLIFPERL_ENCODE_PERLQQ        0x0100
#define MARPAESLIFPERL_ENCODE_HTMLCREF      0x0200
#define MARPAESLIFPERL_ENCODE_XMLCREF       0x0400

#define MARPAESLIFPERL_ENCODE_FB_DEFAULT    0
#define MARPAESLIFPERL_ENCODE_FB_CROAK      MARPAESLIFPERL_ENCODE_DIE_ON_ERR
#define MARPAESLIFPERL_ENCODE_FB_QUIET      MARPAESLIFPERL_ENCODE_RETURN_ON_ERR
#define MARPAESLIFPERL_ENCODE_FB_WARN       MARPAESLIFPERL_ENCODE_RETURN_ON_ERR | MARPAESLIFPERL_ENCODE_WARN_ON_ERR
#define MARPAESLIFPERL_ENCODE_FB_PERLQQ     MARPAESLIFPERL_ENCODE_LEAVE_SRC     | MARPAESLIFPERL_ENCODE_PERLQQ

#define MARPAESLIFPERL_NEWSVPVN_UTF8(keys, sizel) newSVpvn_flags((const char *) keys, (STRLEN) sizel, is_utf8_string((const U8 *) keys, (STRLEN) sizel) ? SVf_UTF8 : 0)

/* Use the inc and dec macros that fit the best our code */
#ifdef SvREFCNT_dec_NN
#  define MARPAESLIFPERL_SvREFCNT_dec(svp) SvREFCNT_dec_NN(svp)
#else
#  define MARPAESLIFPERL_SvREFCNT_dec(svp) SvREFCNT_dec(svp)
#endif

/* Why is there no need for encodingl ? Because it is guaranteed that encodings */
/* is a NUL terminated ASCII string. So when character at position i is != '\0' */
/* then the character at position i+1 exists (and it may be the NUL byte...).   */
/* We do not rely on strcasecmp, _stricmp etc...  not in C std and too much     */
/* bound to locale.                                                             */
/* In addition you may wonder why I both to do strcmp() because the case        */
/* insensitive version. This is because almost nobody export UTF-8 as something */
/* else but "UTF-8". So the probability to have strcmp() successful when it is  */
/* an UTF-8 string is unvaluable compared to somebody that would use "utf-8".   */
/* And of course strcmp() is bound by any compiler to an optimized assemby      */
/* version ;)                                                                   */
/* Note that we do NOT test if encodings is != NULL because when ESLIF exports  */
/* a marpaESLIFValueResult of type STRING it guarantees that encodingasciis is  */
/* set.                                                                         */
#define MARPAESLIFPERL_ENCODING_IS_UTF8(encodings)                      \
  ((strcmp(encodings, "UTF-8") == 0)                                    \
   ||                                                                   \
   (                                                                    \
    ((encodings[0] == 'U') || (encodings[0] == 'u')) &&                 \
    ((encodings[1] == 'T') || (encodings[1] == 't')) &&                 \
    ((encodings[2] == 'F') || (encodings[2] == 'f')) &&                 \
    (((encodings[3] == '-') && (encodings[4] == '8') && (encodings[5] == '\0')) /* UTF-8 */ \
     ||                                                                 \
     ((encodings[3] == '8') && (encodings[4] == '\0')) /* UTF8 */       \
    )                                                                   \
   )                                                                    \
  )


#if defined(SvREFCNT_inc_simple_void_NN)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_simple_void_NN(svp)
#elif defined(SvREFCNT_inc_void_NN)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_void_NN(svp)
#elif defined(SvREFCNT_inc_simple_NN)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_simple_NN(svp)
#elif defined(SvREFCNT_inc_NN)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_NN(svp)
#elif defined(SvREFCNT_inc_simple_void)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_simple_void(svp)
#elif defined(SvREFCNT_inc_void)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_void(svp)
#elif defined(SvREFCNT_inc_simple)
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc_simple(svp)
#else
#  define MARPAESLIFPERL_SvREFCNT_inc(svp) SvREFCNT_inc(svp)
#endif

/* ESLIF context */
static char _MARPAESLIFPERL_CONTEXT;
#define MARPAESLIFPERL_CONTEXT &_MARPAESLIFPERL_CONTEXT

typedef struct MarpaX_ESLIF {
  SV                      *Perl_loggerInterfacep;
  genericLogger_t         *genericLoggerp;
  marpaESLIF_t            *marpaESLIFp;
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX        PerlInterpreterp;
#endif
  MarpaX_ESLIF_constants_t constants;
} MarpaX_ESLIF_t;

/* Nothing special for the grammar type */
typedef struct MarpaX_ESLIF_Grammar {
  SV                       *Perl_MarpaX_ESLIFp;
  MarpaX_ESLIF_t           *MarpaX_ESLIFp;
  marpaESLIFGrammar_t      *marpaESLIFGrammarp;
  MarpaX_ESLIF_constants_t *constantsp;
} MarpaX_ESLIF_Grammar_t, MarpaX_ESLIF_JSON_Encoder_t, MarpaX_ESLIF_JSON_Decoder_t;

/* Symbol type */
typedef struct MarpaX_ESLIF_Symbol {
  SV                       *Perl_MarpaX_ESLIFp;
  MarpaX_ESLIF_t           *MarpaX_ESLIFp;
  marpaESLIFSymbol_t       *marpaESLIFSymbolp;
  MarpaX_ESLIF_constants_t *constantsp;
  genericStack_t            _internalStack;
  genericStack_t           *internalStackp;
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX         PerlInterpreterp;
#endif
} MarpaX_ESLIF_Symbol_t;

/* Recognizer context */
typedef struct MarpaX_ESLIF_Recognizer {
  MarpaX_ESLIF_Grammar_t   *MarpaX_ESLIF_Grammarp;
  MarpaX_ESLIF_t           *MarpaX_ESLIFp;
  marpaESLIFRecognizer_t   *marpaESLIFRecognizerp;
  marpaESLIFRecognizer_t   *marpaESLIFRecognizerBackupp; /* Used recognizer callbacks */
  marpaESLIFRecognizer_t   *marpaESLIFRecognizerLastp; /* Last used marpaESLIFRecognizerp in recognizer callbacks */
  SV                       *Perl_MarpaX_ESLIF_Grammarp;
  SV                       *Perl_recognizerInterfacep;
  SV                       *Perl_recognizer_origp;
  char                     *actions;                    /* Shallow copy of last resolved name */
  SV                       *Perl_datap;
  SV                       *Perl_encodingp;
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX         PerlInterpreterp;
#endif
  genericStack_t            _internalStack;
  genericStack_t           *internalStackp;
  /* For regex callback, we store the stash pointer of MarpaX::ESLIF::RegexCallout */
  MarpaX_ESLIF_constants_t *constantsp;
  SV                       *readSvp;
  SV                       *isEofSvp;
  SV                       *isCharacterStreamSvp;
  SV                       *encodingSvp;
  SV                       *dataSvp;
  SV                       *isWithDisableThresholdSvp;
  SV                       *isWithExhaustionSvp;
  SV                       *isWithNewlineSvp;
  SV                       *isWithTrackSvp;
  SV                       *setRecognizerSvp;
} MarpaX_ESLIF_Recognizer_t;

/* Value context */
typedef struct MarpaX_ESLIF_Value {
  SV                        *Perl_valueInterfacep;
  MarpaX_ESLIF_t            *MarpaX_ESLIFp;
  SV                        *Perl_MarpaX_ESLIF_Grammarp;
  char                      *actions;                       /* Shallow copy of last resolved name */
  marpaESLIFValue_t         *marpaESLIFValuep;
  short                      canSetSymbolNameb;
  short                      canSetSymbolNumberb;
  short                      canSetRuleNameb;
  short                      canSetRuleNumberb;
  short                      canSetGrammarb;
  SV                        *setSymbolNameSvp;
  SV                        *setSymbolNumberSvp;
  SV                        *setRuleNameSvp;
  SV                        *setRuleNumberSvp;
  SV                        *setGrammarSvp;
  char                      *symbols;
  int                        symboli;
  char                      *rules;
  int                        rulei;
  genericStack_t             _internalStack;
  genericStack_t            *internalStackp;
#ifdef PERL_IMPLICIT_CONTEXT
  marpaESLIFPerlTHX          PerlInterpreterp;
#endif
  MarpaX_ESLIF_constants_t  *constantsp;
  SV                        *isWithHighRankOnlySvp;
  SV                        *isWithOrderByRankSvp;
  SV                        *isWithAmbiguousSvp;
  SV                        *isWithNullSvp;
  SV                        *maxParsesSvp;
  SV                        *setResultSvp;
  SV                        *getResultSvp;
} MarpaX_ESLIF_Value_t;

/* Static functions declarations */
static inline void                            marpaESLIFPerl_constants_initv(pTHX_ MarpaX_ESLIF_constants_t *constantsp);
static inline void                            marpaESLIFPerl_constants_disposev(pTHX_ MarpaX_ESLIF_constants_t *constantsp);
static inline int                             marpaESLIFPerl_getTypei(pTHX_ SV* svp);
static inline short                           marpaESLIFPerl_canb(pTHX_ SV *svp, const char *methods, SV **svpp);
static inline void                            marpaESLIFPerl_call_methodv(pTHX_ SV *interfacep, const char *methods, SV *argsvp, SV *subSvp);
static inline SV                             *marpaESLIFPerl_call_methodp(pTHX_ SV *interfacep, const char *methods, SV *subSvp);
static inline SV                             *marpaESLIFPerl_call_actionp(pTHX_ SV *interfacep, const char *methods, AV *avp, MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, short evalb, short evalSilentb, SV *subSvp);
static inline SV                             *marpaESLIFPerl_recognizerCallbackActionp(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, AV *avp);
static inline IV                              marpaESLIFPerl_call_methodi(pTHX_ SV *interfacep, const char *methods, SV *subSvp);
static inline short                           marpaESLIFPerl_call_methodb(pTHX_ SV *interfacep, const char *methods, SV *subSvp);
static inline void                            marpaESLIFPerl_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static inline void                            marpaESLIFPerl_readerCallbackDisposev(void *userDatavp, char *inputcp, size_t inputl, short eofb, short characterStreamb, char *encodings, size_t encodingl);
static inline short                           marpaESLIFPerl_readerCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp, marpaESLIFReaderDispose_t *disposeCallbackpp);
static inline marpaESLIFValueRuleCallback_t   marpaESLIFPerl_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static inline marpaESLIFValueSymbolCallback_t marpaESLIFPerl_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static inline marpaESLIFRecognizerIfCallback_t marpaESLIFPerl_recognizerIfActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static inline marpaESLIFRecognizerEventCallback_t marpaESLIFPerl_recognizerEventActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static inline marpaESLIFRecognizerRegexCallback_t marpaESLIFPerl_recognizerRegexActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static inline marpaESLIFRecognizerGeneratorCallback_t marpaESLIFPerl_recognizerGeneratorActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static inline SV                             *marpaESLIFPerl_valueGetSvp(pTHX_ marpaESLIFValue_t *marpaESLIFValuep, genericStack_t *internalStackp, int stackindicei, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep);
static inline SV                             *marpaESLIFPerl_recognizerGetSvp(pTHX_ marpaESLIFRecognizer_t *marpaESLIFRecognizerp, genericStack_t *internalStackp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline short                           marpaESLIFPerl_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static inline short                           marpaESLIFPerl_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static inline short                           marpaESLIFPerl_recognizerIfCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static inline short                           marpaESLIFPerl_recognizerEventCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static inline short                           marpaESLIFPerl_recognizerRegexCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static inline short                           marpaESLIFPerl_recognizerGeneratorCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp);
static inline void                            marpaESLIFPerl_genericFreeCallbackv(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline void                            marpaESLIFPerl_ContextInitv(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp);
static inline void                            marpaESLIFPerl_ContextFreev(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp);
static inline void                            marpaESLIFPerl_grammarContextFreev(pTHX_ MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp);
static inline void                            marpaESLIFPerl_symbolContextFreev(pTHX_ MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp);
static inline void                            marpaESLIFPerl_valueContextFreev(pTHX_ MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, short onStackb);
static inline void                            marpaESLIFPerl_recognizerContextFreev(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, short onStackb);
static inline void                            marpaESLIFPerl_resetInternalStackv(pTHX_ genericStack_t *internalStackp);
static inline void                            marpaESLIFPerl_grammarContextInitv(pTHX_ SV *Perl_MarpaX_ESLIFp, MarpaX_ESLIF_t *MarpaX_ESLIFp, MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp, MarpaX_ESLIF_constants_t *constantsp);
static inline void                            marpaESLIFPerl_symbolContextInitv(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp, SV *Perl_MarpaX_ESLIFp, MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp, MarpaX_ESLIF_constants_t *constantsp);
static inline void                            marpaESLIFPerl_recognizerContextInitv(pTHX_ MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp, SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, SV *Perl_recognizer_origp, MarpaX_ESLIF_constants_t *constantsp, MarpaX_ESLIF_t *MarpaX_ESLIFp);
static inline void                            marpaESLIFPerl_valueContextInitv(pTHX_ SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_valueInterfacep, MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, MarpaX_ESLIF_constants_t *constantsp, MarpaX_ESLIF_t *MarpaX_ESLIFp);
static inline void                            marpaESLIFPerl_paramIsGrammarv(pTHX_ SV *sv);
static inline void                            marpaESLIFPerl_paramIsEncodingv(pTHX_ SV *sv);
static inline short                           marpaESLIFPerl_paramIsLoggerInterfaceOrUndefb(pTHX_ SV *sv);
static inline void                            marpaESLIFPerl_representationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis);
static inline short                           marpaESLIFPerl_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp);
static inline char                           *marpaESLIFPerl_sv2byte(pTHX_ marpaESLIF_t *marpaESLIFp, SV *svp, char **bytepp, size_t *bytelp, short encodingInformationb, short *characterStreambp, char **encodingsp, size_t *encodinglp, short warnIsFatalb, short marpaESLIFStringb, MarpaX_ESLIF_constants_t *constantsp);
static inline short                           marpaESLIFPerl_valueImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline short                           marpaESLIFPerl_recognizerImportb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline short                           marpaESLIFPerl_symbolImportb(marpaESLIFSymbol_t *marpaESLIFSymbolp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline short                           marpaESLIFPerl_importb(pTHX_ marpaESLIFPerl_importContext_t *importContextp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short arraycopyb);
static inline void                            marpaESLIFPerl_generateStringWithLoggerCallback(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static inline short                           marpaESLIFPerl_appendOpaqueDataToStringGenerator(marpaESLIFPerl_stringGeneratorContext_t *marpaESLIFPerl_stringGeneratorContextp, char *p, size_t sizel);
static inline short                           marpaESLIFPerl_is_scalar_string_only(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_undef(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_arrayref(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_MarpaX__ESLIF__String(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_Math__BigInt(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_Math__BigFloat(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_hashref(pTHX_ SV *svp, int typei);
static inline short                           marpaESLIFPerl_is_bool(pTHX_ SV *svp, int typei, MarpaX_ESLIF_constants_t *constantsp);
static inline SV                             *marpaESLIFPerl_true(pTHX_ MarpaX_ESLIF_constants_t *constantsp);
static inline SV                             *marpaESLIFPerl_false(pTHX_ MarpaX_ESLIF_constants_t *constantsp);
static inline void                            marpaESLIFPerl_stack_setv(pTHX_ marpaESLIF_t *marpaESLIFp, marpaESLIFValue_t *marpaESLIFValuep, int resulti, SV *svp, marpaESLIFValueResult_t *marpaESLIFValueResultOutputp, short incb, MarpaX_ESLIF_constants_t *constantsp);
static inline short                           marpaESLIFPerl_JSONDecodePositiveInfinityAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb);
static inline short                           marpaESLIFPerl_JSONDecodeNegativeInfinityAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb);
static inline short                           marpaESLIFPerl_JSONDecodePositiveNanAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb);
static inline short                           marpaESLIFPerl_JSONDecodeNegativeNanAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb);
static inline short                           marpaESLIFPerl_JSONDecodeNumberAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb);
static inline void                           *marpaESLIFPerl_Perl2enginep(pTHX_ SV *Perl_argumentp);
static inline SV                             *marpaESLIFPerl_engine2Perlp(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp);
static inline void                            marpaESLIFPerl_setRecognizerEngineForCallbackv(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static inline void                            marpaESLIFPerl_restoreRecognizerEngineForCallbackv(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp);
static inline SV                             *marpaESLIFPerl_arraycopyp(pTHX_ char *p, STRLEN sizel, short arraycopyb);


/* Static constants */
static const char   *UTF8s = "UTF-8";
static const size_t  UTF8l = 5; /* "UTF-8" is 5 bytes in ASCII encoding */

/*****************************************************************************/
/* Static variables initialized at boot                                      */
/*****************************************************************************/

/*****************************************************************************/
/* Macros                                                                    */
/*****************************************************************************/
#define MARPAESLIFPERL_FILENAMES "ESLIF.xs"

#define MARPAESLIFPERL_CROAK(msgs)       croak("[In %s at %s:%d] %s", funcs, MARPAESLIFPERL_FILENAMES, __LINE__, msgs)
#define MARPAESLIFPERL_CROAKF(fmts, ...) croak("[In %s at %s:%d] " fmts, funcs, MARPAESLIFPERL_FILENAMES, __LINE__, __VA_ARGS__)
#define MARPAESLIFPERL_WARN(msgs)        warn("[In %s at %s:%d] %s", funcs, MARPAESLIFPERL_FILENAMES, __LINE__, msgs)
#define MARPAESLIFPERL_WARNF(fmts, ...)  warn("[In %s at %s:%d] " fmts, funcs, MARPAESLIFPERL_FILENAMES, __LINE__, __VA_ARGS__)
#define MARPAESLIFPERL_FREE_SVP(svp) do {        \
    SV *_svp = svp;                              \
    if (((_svp) != NULL)         &&              \
        ((_svp) != &PL_sv_undef) &&              \
        ((_svp) != &PL_sv_yes) &&                \
        ((_svp) != &PL_sv_no)) {                 \
      while (SvREFCNT(_svp) > 0) {               \
        MARPAESLIFPERL_SvREFCNT_dec(_svp);       \
      }                                          \
    }                                            \
  } while (0)

#define MARPAESLIFPERL_REFCNT_DEC(svp) do {      \
    SV *_svp = svp;                              \
    if (((_svp) != NULL)         &&              \
        ((_svp) != &PL_sv_undef) &&              \
        ((_svp) != &PL_sv_yes) &&                \
        ((_svp) != &PL_sv_no)) {                 \
      if (SvREFCNT(_svp) > 0) {                  \
        MARPAESLIFPERL_SvREFCNT_dec(_svp);       \
      }                                          \
    }                                            \
  } while (0)

#define MARPAESLIFPERL_REFCNT_INC(svp) do {      \
    SV *_svp = svp;                              \
    if (((_svp) != NULL)         &&              \
        ((_svp) != &PL_sv_undef) &&              \
        ((_svp) != &PL_sv_yes) &&                \
        ((_svp) != &PL_sv_no)) {                 \
      MARPAESLIFPERL_SvREFCNT_inc(_svp);         \
    }                                            \
  } while (0)

/* In this macro we hack the difference between hv_store and av_push by testing xvp type */
/* Remember that hv_store() and av_push() takes over one reference count. */
#define MARPAESLIFPERL_XV_STORE(xvp, key, svp) do {     \
    if (SvTYPE((SV *)xvp) == SVt_PVHV) {                \
      hv_store((HV *) xvp, key, strlen(key), (svp == &PL_sv_undef) ? newSV(0) : svp, 0); \
    } else {                                            \
      av_push((AV *) xvp, MARPAESLIFPERL_NEWSVPVN_UTF8(key, strlen(key))); \
      av_push((AV *) xvp, (svp == &PL_sv_undef) ? newSV(0) : svp);	\
    }                                                   \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_UNDEF(xvp, key) MARPAESLIFPERL_XV_STORE(xvp, key, &PL_sv_undef)

#define MARPAESLIFPERL_XV_STORE_ACTION(hvp, key, actionp) do {          \
    SV *_svp;                                                           \
                                                                        \
    if (actionp != NULL) {                                              \
      switch (actionp->type) {                                          \
      case MARPAESLIF_ACTION_TYPE_NAME:                                 \
        MARPAESLIFPERL_XV_STORE(hvp, key, newSVpv(actionp->u.names, 0)); \
        break;                                                          \
      case MARPAESLIF_ACTION_TYPE_STRING:                               \
        _svp = MARPAESLIFPERL_NEWSVPVN_UTF8(actionp->u.stringp->bytep, actionp->u.stringp->bytel); \
        MARPAESLIFPERL_XV_STORE(hvp, key, _svp);                        \
        break;                                                          \
      case MARPAESLIF_ACTION_TYPE_LUA:                                  \
        MARPAESLIFPERL_XV_STORE(hvp, key, newSVpv(actionp->u.luas, 0)); \
        break;                                                          \
      case MARPAESLIF_ACTION_TYPE_LUA_FUNCTION:                         \
        MARPAESLIFPERL_XV_STORE(hvp, key, newSVpv(actionp->u.luaFunction.luas, 0)); \
        break;                                                          \
      default:                                                          \
        warn("Unsupported action type %d", actionp->type);              \
        MARPAESLIFPERL_XV_STORE_UNDEF(hvp, key);                        \
        break;                                                          \
      }                                                                 \
    } else {                                                            \
      MARPAESLIFPERL_XV_STORE_UNDEF(hvp, key);                          \
    }                                                                   \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_STRING(hvp, key, stringp) do {          \
    SV *_svp;                                                           \
                                                                        \
    if (stringp != NULL) {                                              \
      _svp = MARPAESLIFPERL_NEWSVPVN_UTF8(stringp->bytep, stringp->bytel); \
      MARPAESLIFPERL_XV_STORE(hvp, key, _svp);                          \
    } else {                                                            \
      MARPAESLIFPERL_XV_STORE_UNDEF(hvp, key);                          \
    }                                                                   \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_ASCIISTRING(hvp, key, asciis) do {      \
    if (asciis != NULL) {                                               \
      MARPAESLIFPERL_XV_STORE(hvp, key, newSVpv(asciis, 0));            \
    } else {                                                            \
      MARPAESLIFPERL_XV_STORE_UNDEF(hvp, key);                          \
    }                                                                   \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_IV(hvp, key, iv) do {                   \
    MARPAESLIFPERL_XV_STORE(hvp, key, newSViv((IV) iv));                \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_YESNO(hvp, key, yesno) do {             \
    MARPAESLIFPERL_XV_STORE(hvp, key, ((yesno) ? &PL_sv_yes : &PL_sv_no)); \
  } while (0)

#define MARPAESLIFPERL_XV_STORE_IVARRAY(hvp, key, ivl, ivp) do {        \
    AV *_avp;                                                           \
    size_t _i;                                                          \
                                                                        \
    if (ivp != NULL) {                                                  \
      _avp = newAV();                                                   \
      if (ivl > 0) {                                                    \
        for (_i = 0; _i < ivl; _i++) {                                  \
          av_push(_avp, newSViv((IV) ivp[_i]));                         \
        }                                                               \
      }                                                                 \
      MARPAESLIFPERL_XV_STORE(hvp, key, newRV_inc((SV *) _avp));        \
    } else {                                                            \
      MARPAESLIFPERL_XV_STORE_UNDEF(hvp, key);                          \
    }                                                                   \
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
static inline int marpaESLIFPerl_getTypei(pTHX_ SV* svp) {
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
static inline short marpaESLIFPerl_canb(pTHX_ SV *svp, const char *methods, SV **svpp)
/*****************************************************************************/
{
  AV *list = newAV();
  SV *rcp;
  int type;

  /* We always check methods that have ASCII only characters */
  av_push(list, newSVpv(methods, 0));
  rcp = marpaESLIFPerl_call_actionp(aTHX_ svp, "can", list, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(list);

  type = marpaESLIFPerl_getTypei(aTHX_ rcp);
  if (svpp != NULL) {
    *svpp = rcp;
  } else {
    MARPAESLIFPERL_REFCNT_DEC(rcp);
  }

  return (type & CODEREF) == CODEREF;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_call_methodv(pTHX_ SV *interfacep, const char *methods, SV *argsvp, SV *subSvp)
/*****************************************************************************/
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1 + ((argsvp != NULL) ? 1 : 0));
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  if (argsvp != NULL) {
    PUSHs(sv_2mortal(newSVsv(argsvp)));
  }
  PUTBACK;

  if (subSvp != NULL) {
    call_sv(subSvp, G_DISCARD);
  } else {
    call_method(methods, G_DISCARD);
  }

  FREETMPS;
  LEAVE;
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_call_methodp(pTHX_ SV *interfacep, const char *methods, SV *subSvp)
/*****************************************************************************/
{
  SV *rcp;

  rcp = marpaESLIFPerl_call_actionp(aTHX_ interfacep, methods, NULL /* avp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, subSvp);

  return rcp;
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_call_actionp(pTHX_ SV *interfacep, const char *methods, AV *avp, MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, short evalb, short evalSilentb, SV *subSvp)
/*****************************************************************************/
{
  static const char         *funcs      = "marpaESLIFPerl_call_actionp";
  SSize_t                    avsizel    = (avp != NULL) ? av_len(avp) + 1 : 0;
  SV                       **svargs     = NULL;
  I32                        flags      = G_SCALAR;
  SV                        *rcp;
  SV                        *Perl_valueInterfacep;
  SV                        *Perl_MarpaX_ESLIF_Grammarp;
  SV                        *svlocalp;
  char                      *symbols;
  int                        symboli;
  char                      *rules;
  int                        rulei;
  SSize_t                    aviteratorl;
  SV                         *err_tmp;
  dSP;

  if (evalb) {
    flags |= G_EVAL;
  }

  ENTER;
  SAVETMPS;

  if (MarpaX_ESLIF_Valuep != NULL) {
    /* This is an action context - we localize some variable */
    /* For GV_ADD: value is created once if needed - Perl will destroy it at exit */

    Perl_valueInterfacep = MarpaX_ESLIF_Valuep->Perl_valueInterfacep;
    Perl_MarpaX_ESLIF_Grammarp = MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Grammarp;

    symbols = MarpaX_ESLIF_Valuep->symbols;
    svlocalp = get_sv("MarpaX::ESLIF::Context::symbolName", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    if (symbols != NULL) {
      sv_setpvn(svlocalp, symbols, strlen(symbols));
    } else {
      sv_setsv(svlocalp, &PL_sv_undef);
    }
    if (MarpaX_ESLIF_Valuep->canSetSymbolNameb) {
      marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setSymbolName", svlocalp, MarpaX_ESLIF_Valuep->setSymbolNameSvp);
    }

    symboli = MarpaX_ESLIF_Valuep->symboli;
    svlocalp = get_sv("MarpaX::ESLIF::Context::symbolNumber", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setiv(svlocalp, symboli);
    if (MarpaX_ESLIF_Valuep->canSetSymbolNumberb) {
      marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setSymbolNumber", svlocalp, MarpaX_ESLIF_Valuep->setSymbolNumberSvp);
    }

    rules = MarpaX_ESLIF_Valuep->rules;
    svlocalp = get_sv("MarpaX::ESLIF::Context::ruleName", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    if (rules != NULL) {
      sv_setpvn(svlocalp, rules, strlen(rules));
    } else {
      sv_setsv(svlocalp, &PL_sv_undef);
    }
    if (MarpaX_ESLIF_Valuep->canSetRuleNameb) {
      marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setRuleName", svlocalp, MarpaX_ESLIF_Valuep->setRuleNameSvp);
    }

    rulei = MarpaX_ESLIF_Valuep->rulei;
    svlocalp = get_sv("MarpaX::ESLIF::Context::ruleNumber", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setiv(svlocalp, rulei);
    if (MarpaX_ESLIF_Valuep->canSetRuleNumberb) {
      marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setRuleNumber", svlocalp, MarpaX_ESLIF_Valuep->setRuleNumberSvp);
    }

    svlocalp = get_sv("MarpaX::ESLIF::Context::grammar", GV_ADD);
    save_item(svlocalp); /* We control this variable - no magic involved */
    sv_setsv(svlocalp, Perl_MarpaX_ESLIF_Grammarp);
    if (MarpaX_ESLIF_Valuep->canSetGrammarb) {
      marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setGrammar", svlocalp, MarpaX_ESLIF_Valuep->setGrammarSvp);
    }
  }

  PUSHMARK(SP);
  if (interfacep != NULL) {
    EXTEND(SP, 1 + avsizel);
    PUSHs(sv_2mortal(newSVsv(interfacep)));
    for (aviteratorl = 0; aviteratorl < avsizel; aviteratorl++) {
      SV **svpp = av_fetch(avp, aviteratorl, 0); /* We manage ourself the avp, SV's are real */
      if (MARPAESLIF_UNLIKELY(svpp == NULL)) {
        MARPAESLIFPERL_CROAKF("av_fetch returned NULL during arguments preparation for method %s", (methods != NULL) ? methods : "undef");
      }
      PUSHs(sv_2mortal(newSVsv(*svpp)));
    }
  } else {
    if (avsizel > 0) {
      EXTEND(SP, avsizel);
      for (aviteratorl = 0; aviteratorl < avsizel; aviteratorl++) {
        SV **svpp = av_fetch(avp, aviteratorl, 0); /* We manage ourself the avp, SV's are real */
        if (MARPAESLIF_UNLIKELY(svpp == NULL)) {
          MARPAESLIFPERL_CROAKF("av_fetch returned NULL during arguments preparation for method %s", (methods != NULL) ? methods : "undef");
        }
        PUSHs(sv_2mortal(newSVsv(*svpp)));
      }
    }
  }
  PUTBACK;

  if (subSvp) {
    call_sv(subSvp, flags);
  } else if (interfacep != NULL) {
    call_method(methods, flags);
  } else {
    call_pv(methods, flags);
  }

  if (evalb && (! evalSilentb)) {
    /* Check the eval */
    err_tmp = ERRSV;
    if (SvTRUE(err_tmp)) {
      warn("%s\n", SvPV_nolen(err_tmp));
     }
  }

  SPAGAIN;

  rcp = POPs;
  MARPAESLIFPERL_REFCNT_INC(rcp);

  PUTBACK;
  FREETMPS;
  LEAVE;


  return rcp;
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_recognizerCallbackActionp(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, AV *avp)
/*****************************************************************************/
{
  SV *svp;

  marpaESLIFPerl_setRecognizerEngineForCallbackv(aTHX_ MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizerp);
  svp = marpaESLIFPerl_call_actionp(aTHX_ MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep,
                                    MarpaX_ESLIF_Recognizerp->actions,
                                    avp,
                                    NULL, /* MarpaX_ESLIF_Valuep */
                                    0, /* evalb */
                                    0, /* evalSilentb */
                                    NULL /* subSvp */);
  marpaESLIFPerl_restoreRecognizerEngineForCallbackv(aTHX_ MarpaX_ESLIF_Recognizerp);

  return svp;
}

/*****************************************************************************/
static inline IV marpaESLIFPerl_call_methodi(pTHX_ SV *interfacep, const char *methods, SV *subSvp)
/*****************************************************************************/
{
  IV rci;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  PUTBACK;

  if (subSvp != NULL) {
    call_sv(subSvp, G_SCALAR);
  } else {
    call_method(methods, G_SCALAR);
  }

  SPAGAIN;

  rci = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return rci;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_call_methodb(pTHX_ SV *interfacep, const char *methods, SV *subSvp)
/*****************************************************************************/
{
  short rcb;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(sv_2mortal(newSVsv(interfacep)));
  PUTBACK;

  if (subSvp != NULL) {
    call_sv(subSvp, G_SCALAR);
  } else {
    call_method(methods, G_SCALAR);
  }

  SPAGAIN;

  rcb = (POPi != 0);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return rcb;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs)
/*****************************************************************************/
{
  MarpaX_ESLIF_t *MarpaX_ESLIFp         = (MarpaX_ESLIF_t *) userDatavp;
  SV             *Perl_loggerInterfacep = MarpaX_ESLIFp->Perl_loggerInterfacep;
  char *method;
  dTHXa(MarpaX_ESLIFp->PerlInterpreterp); /* dNOOP if no PERL_IMPLICIT_CONTEXT */

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
    /* In addition ESLIF rarelly logs, propagating envp in the context */
    /* is an optimization that is almost useless */
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
static inline void marpaESLIFPerl_readerCallbackDisposev(void *userDatavp, char *inputcp, size_t inputl, short eofb, short characterStreamb, char *encodings, size_t encodingl)
/*****************************************************************************/
{
  static const char         *funcs = "marpaESLIFPerl_readerCallbackDisposev";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  SV                        *Perl_recognizerInterfacep = MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (MarpaX_ESLIF_Recognizerp != NULL) {

    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->Perl_datap);
    MarpaX_ESLIF_Recognizerp->Perl_datap = NULL;

    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->Perl_encodingp);
    MarpaX_ESLIF_Recognizerp->Perl_encodingp = NULL;
  }
}

/*****************************************************************************/
static inline short marpaESLIFPerl_readerCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp, marpaESLIFReaderDispose_t *disposeCallbackpp)
/*****************************************************************************/
{
  static const char         *funcs = "marpaESLIFPerl_readerCallbackb";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  SV                        *Perl_recognizerInterfacep = MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep;
  SV                        *Perl_datap;
  SV                        *Perl_encodingp;
  char                      *inputs = NULL;
  STRLEN                     inputl = 0;
  char                      *encodings = NULL;
  STRLEN                     encodingl = 0;
  int                        type;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  /* Call the read interface */
  if (! marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "read", MarpaX_ESLIF_Recognizerp->readSvp)) {
    MARPAESLIFPERL_CROAK("Recognizer->read() method failure");
  }

  /* Call the data interface */
  Perl_datap = marpaESLIFPerl_call_methodp(aTHX_ Perl_recognizerInterfacep, "data", MarpaX_ESLIF_Recognizerp->dataSvp);
  type = marpaESLIFPerl_getTypei(aTHX_ Perl_datap);
  if ((type & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((type & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("Recognizer->data() method must return a scalar or undef");
    }
  }
  if (SvOK(Perl_datap)) {
    inputs = SvPV(Perl_datap, inputl);
  }

  /* Call the encoding interface */
  Perl_encodingp  = marpaESLIFPerl_call_methodp(aTHX_ Perl_recognizerInterfacep, "encoding", MarpaX_ESLIF_Recognizerp->encodingSvp);
  type = marpaESLIFPerl_getTypei(aTHX_ Perl_datap);
  if ((type & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((type & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("Recognizer->encoding() method must return a scalar or undef");
    }
  }
  if (SvOK(Perl_encodingp)) {
    encodings = SvPV(Perl_encodingp, encodingl); /* May be {NULL, 0} */
  } else {
    /* User gave no encoding hint - we can use Perl_datap itself */
    /* This will be ignored if *characterStreambp is false */
    if ((inputs != NULL) && DO_UTF8(Perl_datap)) {
      encodings           = (char *) UTF8s;
      encodingl           = UTF8l;
    }
  }

  *inputcpp             = inputs;
  *inputlp              = (size_t) inputl;
  *eofbp                = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isEof", MarpaX_ESLIF_Recognizerp->isEofSvp);
  *characterStreambp    = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isCharacterStream", MarpaX_ESLIF_Recognizerp->isCharacterStreamSvp);
  *encodingsp           = encodings;
  *encodinglp           = encodingl;
  *disposeCallbackpp    = marpaESLIFPerl_readerCallbackDisposev;

  MarpaX_ESLIF_Recognizerp->Perl_datap     = Perl_datap;
  MarpaX_ESLIF_Recognizerp->Perl_encodingp = Perl_encodingp;

  return 1;
}

/*****************************************************************************/
static inline marpaESLIFValueRuleCallback_t  marpaESLIFPerl_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Valuep->actions = actions;

  return marpaESLIFPerl_valueRuleCallbackb;
}

/*****************************************************************************/
static inline marpaESLIFValueSymbolCallback_t marpaESLIFPerl_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Valuep->actions = actions;

  return marpaESLIFPerl_valueSymbolCallbackb;
}

/*****************************************************************************/
static inline marpaESLIFRecognizerIfCallback_t marpaESLIFPerl_recognizerIfActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Recognizerp->actions = actions;

  return marpaESLIFPerl_recognizerIfCallbackb;
}

/*****************************************************************************/
static inline marpaESLIFRecognizerEventCallback_t marpaESLIFPerl_recognizerEventActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Recognizerp->actions = actions;

  return marpaESLIFPerl_recognizerEventCallbackb;
}

/*****************************************************************************/
static inline marpaESLIFRecognizerRegexCallback_t marpaESLIFPerl_recognizerRegexActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Recognizerp->actions = actions;

  return marpaESLIFPerl_recognizerRegexCallbackb;
}

/*****************************************************************************/
static inline marpaESLIFRecognizerGeneratorCallback_t marpaESLIFPerl_recognizerGeneratorActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;

  /* Just remember the action name - perl will croak if calling this method fails */
  MarpaX_ESLIF_Recognizerp->actions = actions;

  return marpaESLIFPerl_recognizerGeneratorCallbackb;
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_valueGetSvp(pTHX_ marpaESLIFValue_t *marpaESLIFValuep, genericStack_t *internalStackp, int stackindicei, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep)
/*****************************************************************************/
/* This function is guaranteed to return an SV in any case that will HAVE TO BE refcount_dec'ed: either this is a new SV, either this is a casted SV. */
/* The ref count of the returned SV is always incremented (1 when it is new, ++ when this is a casted SV) */
{
  static const char       *funcs = "marpaESLIFPerl_valueGetSvp";
  marpaESLIFValueResult_t *marpaESLIFValueResultp;

  if (marpaESLIFValueResultLexemep != NULL) {
    marpaESLIFValueResultp = marpaESLIFValueResultLexemep;
  } else {
    marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, stackindicei);
    if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultp == NULL)) {
      MARPAESLIFPERL_CROAKF("marpaESLIFValueResultp is NULL at stack indice %d", stackindicei);
    }
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFValue_importb(marpaESLIFValuep, marpaESLIFValueResultp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFValue_importb failure, %s", strerror(errno));
  }

  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(internalStackp) != 1)) {
    MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(internalStackp));
  }

  return (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(internalStackp);
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_recognizerGetSvp(pTHX_ marpaESLIFRecognizer_t *marpaESLIFRecognizerp, genericStack_t *internalStackp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
/* This function is guaranteed to return an SV in any case that will HAVE TO BE refcount_dec'ed: either this is a new SV, either this is a casted SV. */
/* The ref count of the returned SV is always incremented (1 when it is new, ++ when this is a casted SV) */
{
  static const char *funcs = "marpaESLIFPerl_recognizerGetSvp";

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_importb(marpaESLIFRecognizerp, marpaESLIFValueResultp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_importb failure, %s", strerror(errno));
  }

  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(internalStackp) != 1)) {
    MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(internalStackp));
  }

  return (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(internalStackp);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  static const char        *funcs                = "marpaESLIFPerl_valueRuleCallbackb";
  MarpaX_ESLIF_Value_t     *MarpaX_ESLIF_Valuep  = (MarpaX_ESLIF_Value_t *) userDatavp;
  SV                       *Perl_valueInterfacep = MarpaX_ESLIF_Valuep->Perl_valueInterfacep;
  genericStack_t           *internalStackp       = MarpaX_ESLIF_Valuep->internalStackp;
  AV                       *list                 = NULL;
  SV                       *actionResult;
  SV                       *svp;
  int                       i;
  dTHXa(MarpaX_ESLIF_Valuep->PerlInterpreterp);

  /* Get value context */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFValue_contextb(marpaESLIFValuep, &(MarpaX_ESLIF_Valuep->symbols), &(MarpaX_ESLIF_Valuep->symboli), &(MarpaX_ESLIF_Valuep->rules), &(MarpaX_ESLIF_Valuep->rulei)))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFValue_contextb failure, %s", strerror(errno));
  }

  if (! nullableb) {
    list = newAV();
    for (i = arg0i; i <= argni; i++) {
      svp = marpaESLIFPerl_valueGetSvp(aTHX_ marpaESLIFValuep, internalStackp, i, NULL /* marpaESLIFValueResultLexemep */);
      /* One reference count ownership is transfered to the array */
      av_push(list, (svp == &PL_sv_undef) ? newSV(0) : svp);
    }
  }

  actionResult = marpaESLIFPerl_call_actionp(aTHX_ Perl_valueInterfacep, MarpaX_ESLIF_Valuep->actions, list, MarpaX_ESLIF_Valuep, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  if (list != NULL) {
    /* This will decrement all elements reference count */
    av_undef(list);
  }

  marpaESLIFPerl_stack_setv(aTHX_ marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFValue_recognizerp(MarpaX_ESLIF_Valuep->marpaESLIFValuep))), marpaESLIFValuep, resulti, actionResult, NULL /* marpaESLIFValueResultOutputp */, 0 /* incb */, MarpaX_ESLIF_Valuep->constantsp);

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIFPerl_valueRuleCallbackb except that we construct a list of one element containing a byte array that we do ourself */
  static const char        *funcs               = "marpaESLIFPerl_valueSymbolCallbackb";
  MarpaX_ESLIF_Value_t     *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  genericStack_t           *internalStackp      = MarpaX_ESLIF_Valuep->internalStackp;
  AV                       *list                = NULL;
  SV                       *svp;
  SV                       *actionResult;
  dTHXa(MarpaX_ESLIF_Valuep->PerlInterpreterp);

  /* Get value context */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFValue_contextb(marpaESLIFValuep, &(MarpaX_ESLIF_Valuep->symbols), &(MarpaX_ESLIF_Valuep->symboli), &(MarpaX_ESLIF_Valuep->rules), &(MarpaX_ESLIF_Valuep->rulei)))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFValue_contextb failure, %s", strerror(errno));
  }

  list = newAV();
  svp = marpaESLIFPerl_valueGetSvp(aTHX_ marpaESLIFValuep, internalStackp, -1 /* stackindicei */, marpaESLIFValueResultp);
  /* One reference count ownership is transfered to the array */
  av_push(list, (svp == &PL_sv_undef) ? newSV(0) : svp);
  actionResult = marpaESLIFPerl_call_actionp(aTHX_ MarpaX_ESLIF_Valuep->Perl_valueInterfacep, MarpaX_ESLIF_Valuep->actions, list, MarpaX_ESLIF_Valuep, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  /* This will decrement by one the inner element reference count */
  av_undef(list);

  marpaESLIFPerl_stack_setv(aTHX_ marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFValue_recognizerp(MarpaX_ESLIF_Valuep->marpaESLIFValuep))), marpaESLIFValuep, resulti, actionResult, NULL /* marpaESLIFValueResultOutputp */, 0 /* incb */, MarpaX_ESLIF_Valuep->constantsp);

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_recognizerIfCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIFPerl_valueSymbolCallbackb */
  static const char         *funcs                    = "marpaESLIFPerl_recognizerIfCallbackb";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  genericStack_t            *internalStackp           = MarpaX_ESLIF_Recognizerp->internalStackp;
  AV                        *list                     = NULL;
  SV                        *svp;
  SV                        *actionResult;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  list = newAV();
  svp = marpaESLIFPerl_recognizerGetSvp(aTHX_ marpaESLIFRecognizerp, internalStackp, marpaESLIFValueResultLexemep);
  /* One reference count ownership is transfered to the array */
  av_push(list, svp);
  actionResult = marpaESLIFPerl_recognizerCallbackActionp(aTHX_ MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizerp, list);
  /* This will decrement by one the inner element reference count */
  av_undef(list);

  *marpaESLIFValueResultBoolp = SvTRUE(actionResult) ? MARPAESLIFVALUERESULTBOOL_TRUE : MARPAESLIFVALUERESULTBOOL_FALSE;

  MARPAESLIFPERL_REFCNT_DEC(actionResult);

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_recognizerEventCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIFPerl_recognizerIfCallbackb */
  static const char         *funcs                    = "marpaESLIFPerl_recognizerEventCallbackb";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  AV                        *list                     = NULL;
  HV                        *hv;
  size_t                     i;
  SV                        *svp;
  SV                        *actionResult;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  list = newAV();

  for (i = 0; i < eventArrayl; i++) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "type", strlen("type"), newSViv(eventArrayp[i].type), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for type => %d", eventArrayp[i].type);
    }

    if (eventArrayp[i].symbols != NULL) {
      svp = newSVpv(eventArrayp[i].symbols, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].symbols, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = newSV(0);
    }
    if (MARPAESLIF_UNLIKELY(hv_store(hv, "symbol", strlen("symbol"), svp, 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for symbol => %s", (eventArrayp[i].symbols != NULL) ? eventArrayp[i].symbols : "");
    }

    if (eventArrayp[i].events != NULL) {
      svp = newSVpv(eventArrayp[i].events, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].events, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = newSV(0);
    }
    if (MARPAESLIF_UNLIKELY(hv_store(hv, "event",  strlen("event"),  svp, 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for event => %s", (eventArrayp[i].events != NULL) ? eventArrayp[i].events : "");
    }

    av_push(list, newRV((SV *)hv));
  }
  actionResult = marpaESLIFPerl_recognizerCallbackActionp(aTHX_ MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizerp, list);
  /* This will decrement by one the inner elements reference count */
  av_undef(list);

  *marpaESLIFValueResultBoolp = SvTRUE(actionResult) ? MARPAESLIFVALUERESULTBOOL_TRUE : MARPAESLIFVALUERESULTBOOL_FALSE;

  MARPAESLIFPERL_REFCNT_DEC(actionResult);

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_recognizerRegexCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIFPerl_recognizerIfCallbackb */
  static const char         *funcs                    = "marpaESLIFPerl_recognizerRegexCallbackb";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  genericStack_t            *internalStackp           = MarpaX_ESLIF_Recognizerp->internalStackp;
  AV                        *list                     = NULL;
  SV                        *svp;
  SV                        *actionResult;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  list = newAV();
  /* Note that by definition svp is a reference to a hash - we bless it to MarpaX::ESLIF::RegexCallout - svp count is unaffected */
  svp = sv_bless(marpaESLIFPerl_recognizerGetSvp(aTHX_ marpaESLIFRecognizerp,
                                                 internalStackp,
                                                 marpaESLIFCalloutBlockp),
                 gv_stashpv("MarpaX::ESLIF::RegexCallout", 0));
  /* One reference count ownership is transfered to the array */
  av_push(list, svp);
  actionResult = marpaESLIFPerl_recognizerCallbackActionp(aTHX_ MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizerp, list);

  /* This will decrement by one the inner element reference count */
  av_undef(list);

  *marpaESLIFValueResultOutp = (marpaESLIFValueResultInt_t) SvIV(actionResult);

  MARPAESLIFPERL_REFCNT_DEC(actionResult);

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_recognizerGeneratorCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  /* Almost exactly like marpaESLIFPerl_recognizerIfCallbackb */
  static const char         *funcs                    = "marpaESLIFPerl_recognizerGeneratorCallbackb";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  genericStack_t            *internalStackp           = MarpaX_ESLIF_Recognizerp->internalStackp;
  AV                        *list                     = NULL;
  /* Note that ESLIF guarantees that contextp is never NULL and is of type ROW */
  size_t                     nargs                    = contextp->u.r.sizel;
  size_t                     i;
  SV                        *svp;
  SV                        *actionResult;
  int                        typei;
  char                      *strings = NULL;
  STRLEN                     stringl = 0;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  list = newAV();
  for (i = 0; i < nargs; i++) {
    svp = marpaESLIFPerl_recognizerGetSvp(aTHX_ marpaESLIFRecognizerp, internalStackp, &(contextp->u.r.p[i]));
    /* One reference count ownership is transfered to the array */
    av_push(list, svp);
  }

  actionResult = marpaESLIFPerl_recognizerCallbackActionp(aTHX_ MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizerp, list);
  /* This will decrement by one the inner element reference count */
  av_undef(list);

  typei = marpaESLIFPerl_getTypei(aTHX_ actionResult);

  /* Call explicitly for stringification. If no encoding can be set, ESLIF will guess. */
  marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFRecognizerp)),
                         actionResult,
                         (char **) &(marpaESLIFValueResultOutp->p),
                         &(marpaESLIFValueResultOutp->sizel),
                         1 /* encodingInformationb */,
                         NULL /* characterStreambp */,
                         &(marpaESLIFValueResultOutp->encodingasciis),
                         NULL /* encodinglp */,
                         0 /* warnIsFatalb */,
                         marpaESLIFPerl_is_MarpaX__ESLIF__String(aTHX_ actionResult, typei) /* marpaESLIFStringb */,
                         MarpaX_ESLIF_Recognizerp->constantsp);

  /* Prepare for the callback: ESLIF will call for destruction after it is processed */
  marpaESLIFValueResultOutp->freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultOutp->freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
  marpaESLIFValueResultOutp->shallowb       = 0;

  MARPAESLIFPERL_REFCNT_DEC(actionResult);

  return 1;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_genericFreeCallbackv(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  dTHXa(userDatavp);

  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_PTR:
    MARPAESLIFPERL_REFCNT_DEC(marpaESLIFValueResultp->u.p.p);
    break;
  case MARPAESLIF_VALUE_TYPE_ARRAY:
    if (marpaESLIFValueResultp->u.a.p != NULL) {
      /* We use marpaESLIFPerl_sv2byte() to get the pointer out of an SV, and this */
      /* may become an ARRAY type if there is no encoding */
      Safefree(marpaESLIFValueResultp->u.a.p);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_STRING:
    if (marpaESLIFValueResultp->u.s.p != NULL) {
      Safefree(marpaESLIFValueResultp->u.s.p);
    }
    /* encoding may refer to the constant UTF8s */
    if ((marpaESLIFValueResultp->u.s.encodingasciis != NULL) && (marpaESLIFValueResultp->u.s.encodingasciis != UTF8s)) {
      Safefree(marpaESLIFValueResultp->u.s.encodingasciis);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_ROW:
    if (marpaESLIFValueResultp->u.r.p != NULL) {
      Safefree(marpaESLIFValueResultp->u.r.p);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_TABLE:
    if (marpaESLIFValueResultp->u.t.p != NULL) {
      Safefree(marpaESLIFValueResultp->u.t.p);
    }
    break;
  default:
    break;
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_ContextInitv(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp)
/*****************************************************************************/
{
  MarpaX_ESLIFp->Perl_loggerInterfacep = &PL_sv_undef;
  MarpaX_ESLIFp->genericLoggerp        = NULL;
  MarpaX_ESLIFp->marpaESLIFp           = NULL;
#ifdef PERL_IMPLICIT_CONTEXT
  MarpaX_ESLIFp->PerlInterpreterp      = aTHX;
#endif
  marpaESLIFPerl_constants_initv(aTHX_ &(MarpaX_ESLIFp->constants));
}

/*****************************************************************************/
static inline void marpaESLIFPerl_ContextFreev(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp)
/*****************************************************************************/
{
  if (MarpaX_ESLIFp != NULL) {
    if (MarpaX_ESLIFp->marpaESLIFp != NULL) {
      marpaESLIF_freev(MarpaX_ESLIFp->marpaESLIFp);
    }
    genericLogger_freev(&(MarpaX_ESLIFp->genericLoggerp)); /* This is NULL aware */
    marpaESLIFPerl_constants_disposev(aTHX_ &(MarpaX_ESLIFp->constants));
    Safefree(MarpaX_ESLIFp);
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_grammarContextFreev(pTHX_ MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp)
/*****************************************************************************/
{
  if (MarpaX_ESLIF_Grammarp != NULL) {
    if (MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp != NULL) {
      marpaESLIFGrammar_freev(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp);
    }
    Safefree(MarpaX_ESLIF_Grammarp);
  }
}
 
/*****************************************************************************/
static inline void marpaESLIFPerl_symbolContextFreev(pTHX_ MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp)
/*****************************************************************************/
{
  if (MarpaX_ESLIF_Symbolp != NULL) {
    marpaESLIFPerl_resetInternalStackv(aTHX_ MarpaX_ESLIF_Symbolp->internalStackp);

    if (MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp != NULL) {
      marpaESLIFSymbol_freev(MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp);
    }

    Safefree(MarpaX_ESLIF_Symbolp);
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_valueContextFreev(pTHX_ MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, short onStackb)
/*****************************************************************************/
{
  if (MarpaX_ESLIF_Valuep != NULL) {
    marpaESLIFPerl_resetInternalStackv(aTHX_ MarpaX_ESLIF_Valuep->internalStackp);

    if (MarpaX_ESLIF_Valuep->marpaESLIFValuep != NULL) {
      marpaESLIFValue_freev(MarpaX_ESLIF_Valuep->marpaESLIFValuep);
    }

    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setSymbolNameSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setSymbolNumberSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setRuleNameSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setRuleNumberSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setGrammarSvp);

    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->isWithHighRankOnlySvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->isWithOrderByRankSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->isWithAmbiguousSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->isWithNullSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->maxParsesSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->setResultSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Valuep->getResultSvp);

    if (! onStackb) {
      Safefree(MarpaX_ESLIF_Valuep);
    }
  }
}
 
/*****************************************************************************/
static inline void marpaESLIFPerl_recognizerContextFreev(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, short onStackb)
/*****************************************************************************/
{
  if (MarpaX_ESLIF_Recognizerp != NULL) {
    marpaESLIFPerl_resetInternalStackv(aTHX_ MarpaX_ESLIF_Recognizerp->internalStackp);

    if (MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp != NULL) {
      marpaESLIFRecognizer_freev(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp);
    }

    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->readSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isEofSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isCharacterStreamSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->encodingSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->dataSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isWithDisableThresholdSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isWithExhaustionSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isWithNewlineSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->isWithTrackSvp);
    MARPAESLIFPERL_REFCNT_DEC(MarpaX_ESLIF_Recognizerp->setRecognizerSvp);

    if (! onStackb) {
      Safefree(MarpaX_ESLIF_Recognizerp);
    }
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_resetInternalStackv(pTHX_ genericStack_t *internalStackp)
/*****************************************************************************/
{
  int  i;
  SV  *svp;

  if (internalStackp != NULL) {
    /* It is important to delete references in the reverse order of their creation */
    while (marpaESLIFPerl_GENERICSTACK_USED(internalStackp) > 0) {
      /* Last indice ... */
      i = marpaESLIFPerl_GENERICSTACK_USED(internalStackp) - 1;
      /* ... is cleared ... */
      if (marpaESLIFPerl_GENERICSTACK_IS_PTR(internalStackp, i)) {
        svp = (SV *) marpaESLIFPerl_GENERICSTACK_GET_PTR(internalStackp, i);
        MARPAESLIFPERL_FREE_SVP(svp);
      }
      /* ... and becomes current used size */
      marpaESLIFPerl_GENERICSTACK_SET_USED(internalStackp, i);
    }
    marpaESLIFPerl_GENERICSTACK_RESET(internalStackp);
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_grammarContextInitv(pTHX_ SV *Perl_MarpaX_ESLIFp, MarpaX_ESLIF_t *MarpaX_ESLIFp, MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp, MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  MarpaX_ESLIF_Grammarp->Perl_MarpaX_ESLIFp = Perl_MarpaX_ESLIFp;
  MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp      = MarpaX_ESLIFp;
  MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp = NULL;
  MarpaX_ESLIF_Grammarp->constantsp         = constantsp;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_symbolContextInitv(pTHX_ MarpaX_ESLIF_t *MarpaX_ESLIFp, SV *Perl_MarpaX_ESLIFp, MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp, MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  static const char *funcs          = "marpaESLIFPerl_symbolContextInitv";
  genericStack_t    *internalStackp = &(MarpaX_ESLIF_Symbolp->_internalStack);

  marpaESLIFPerl_GENERICSTACK_INIT(internalStackp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(internalStackp))) {
    int save_errno = errno;
    MARPAESLIFPERL_CROAKF("GENERICSTACK_INIT() failure, %s", strerror(save_errno));
  }

  MarpaX_ESLIF_Symbolp->Perl_MarpaX_ESLIFp = Perl_MarpaX_ESLIFp;
  MarpaX_ESLIF_Symbolp->MarpaX_ESLIFp      = MarpaX_ESLIFp;
  MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp  = NULL;
  MarpaX_ESLIF_Symbolp->constantsp         = constantsp;
  MarpaX_ESLIF_Symbolp->internalStackp     = &(MarpaX_ESLIF_Symbolp->_internalStack);
#ifdef PERL_IMPLICIT_CONTEXT
  MarpaX_ESLIF_Symbolp->PerlInterpreterp   = aTHX;
#endif
}

/*****************************************************************************/
static inline void marpaESLIFPerl_recognizerContextInitv(pTHX_ MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp, SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, SV *Perl_recognizer_origp, MarpaX_ESLIF_constants_t *constantsp, MarpaX_ESLIF_t *MarpaX_ESLIFp)
/*****************************************************************************/
{
  static const char *funcs          = "marpaESLIFPerl_recognizerContextInitv";
  genericStack_t    *internalStackp = &(MarpaX_ESLIF_Recognizerp->_internalStack);
  int                type           = marpaESLIFPerl_getTypei(aTHX_ Perl_recognizerInterfacep);

  if ((type & OBJECT) != OBJECT) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object");
  }

  marpaESLIFPerl_GENERICSTACK_INIT(internalStackp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(internalStackp))) {
    int save_errno = errno;
    MARPAESLIFPERL_CROAKF("GENERICSTACK_INIT() failure, %s", strerror(save_errno));
  }

  MarpaX_ESLIF_Recognizerp->MarpaX_ESLIF_Grammarp         = MarpaX_ESLIF_Grammarp;
  MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp                 = MarpaX_ESLIFp;
  MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp         = NULL;
  MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerBackupp   = NULL;
  MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerLastp     = NULL;
  MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep     = Perl_recognizerInterfacep;
  MarpaX_ESLIF_Recognizerp->Perl_MarpaX_ESLIF_Grammarp    = Perl_MarpaX_ESLIF_Grammarp;
  MarpaX_ESLIF_Recognizerp->Perl_recognizer_origp         = Perl_recognizer_origp;
  MarpaX_ESLIF_Recognizerp->Perl_datap                    = NULL;
  MarpaX_ESLIF_Recognizerp->Perl_encodingp                = NULL;
#ifdef PERL_IMPLICIT_CONTEXT
  MarpaX_ESLIF_Recognizerp->PerlInterpreterp              = aTHX;
#endif
  MarpaX_ESLIF_Recognizerp->internalStackp                = &(MarpaX_ESLIF_Recognizerp->_internalStack);
  MarpaX_ESLIF_Recognizerp->constantsp                    = constantsp;
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "read", &(MarpaX_ESLIF_Recognizerp->readSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"read\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isEof", &(MarpaX_ESLIF_Recognizerp->isEofSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isEof\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isCharacterStream", &(MarpaX_ESLIF_Recognizerp->isCharacterStreamSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isCharacterStream\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "encoding", &(MarpaX_ESLIF_Recognizerp->encodingSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"encoding\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "data", &(MarpaX_ESLIF_Recognizerp->dataSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"data\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isWithDisableThreshold", &(MarpaX_ESLIF_Recognizerp->isWithDisableThresholdSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isWithDisableThreshold\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isWithExhaustion", &(MarpaX_ESLIF_Recognizerp->isWithExhaustionSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isWithExhaustion\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isWithNewline", &(MarpaX_ESLIF_Recognizerp->isWithNewlineSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isWithNewline\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "isWithTrack", &(MarpaX_ESLIF_Recognizerp->isWithTrackSvp))) {
    MARPAESLIFPERL_CROAK("Recognizer interface must be an object that can do \"isWithTrack\"");
  }
  /* It is not illegal to not have the setRecognizer method */
  marpaESLIFPerl_canb(aTHX_ Perl_recognizerInterfacep, "setRecognizer", &(MarpaX_ESLIF_Recognizerp->setRecognizerSvp));
}

/*****************************************************************************/
static inline void marpaESLIFPerl_valueContextInitv(pTHX_ SV *Perl_MarpaX_ESLIF_Grammarp, SV *Perl_valueInterfacep, MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep, MarpaX_ESLIF_constants_t *constantsp, MarpaX_ESLIF_t *MarpaX_ESLIFp)
/*****************************************************************************/
{
  static const char *funcs          = "marpaESLIFPerl_valueContextInitv";
  genericStack_t    *internalStackp = &(MarpaX_ESLIF_Valuep->_internalStack);
  int                type;

  if (Perl_valueInterfacep != NULL) {
    type = marpaESLIFPerl_getTypei(aTHX_ Perl_valueInterfacep);
    if ((type & OBJECT) != OBJECT) {
      MARPAESLIFPERL_CROAK("Value interface must be an object");
    }
  }

  marpaESLIFPerl_GENERICSTACK_INIT(internalStackp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(internalStackp))) {
    MARPAESLIFPERL_CROAKF("GENERICSTACK_INIT() failure, %s", strerror(errno));
  }

  /* All SVs are SvRV's */

  MarpaX_ESLIF_Valuep->Perl_valueInterfacep          = Perl_valueInterfacep;
  MarpaX_ESLIF_Valuep->MarpaX_ESLIFp                 = MarpaX_ESLIFp;
  MarpaX_ESLIF_Valuep->Perl_MarpaX_ESLIF_Grammarp    = Perl_MarpaX_ESLIF_Grammarp;
  MarpaX_ESLIF_Valuep->actions                       = NULL;
  MarpaX_ESLIF_Valuep->marpaESLIFValuep              = NULL;
  MarpaX_ESLIF_Valuep->canSetSymbolNameb             = (Perl_valueInterfacep != NULL) ? marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setSymbolName", &(MarpaX_ESLIF_Valuep->setSymbolNameSvp)) : 0;
  MarpaX_ESLIF_Valuep->canSetSymbolNumberb           = (Perl_valueInterfacep != NULL) ? marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setSymbolNumber", &(MarpaX_ESLIF_Valuep->setSymbolNumberSvp)) : 0;
  MarpaX_ESLIF_Valuep->canSetRuleNameb               = (Perl_valueInterfacep != NULL) ? marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setRuleName", &(MarpaX_ESLIF_Valuep->setRuleNameSvp)) : 0;
  MarpaX_ESLIF_Valuep->canSetRuleNumberb             = (Perl_valueInterfacep != NULL) ? marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setRuleNumber", &(MarpaX_ESLIF_Valuep->setRuleNumberSvp)) : 0;
  MarpaX_ESLIF_Valuep->canSetGrammarb                = (Perl_valueInterfacep != NULL) ? marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setGrammar", &(MarpaX_ESLIF_Valuep->setGrammarSvp)) : 0;
  MarpaX_ESLIF_Valuep->symbols                       = NULL;
  MarpaX_ESLIF_Valuep->symboli                       = -1;
  MarpaX_ESLIF_Valuep->rules                         = NULL;
  MarpaX_ESLIF_Valuep->rulei                         = -1;
#ifdef PERL_IMPLICIT_CONTEXT
  MarpaX_ESLIF_Valuep->PerlInterpreterp              = aTHX;
#endif
  MarpaX_ESLIF_Valuep->internalStackp                = &(MarpaX_ESLIF_Valuep->_internalStack);
  MarpaX_ESLIF_Valuep->constantsp                    = constantsp;

  if (Perl_valueInterfacep != NULL) {
    MarpaX_ESLIF_Valuep->canSetSymbolNameb             = marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setSymbolName", &(MarpaX_ESLIF_Valuep->setSymbolNameSvp));
    MarpaX_ESLIF_Valuep->canSetSymbolNumberb           = marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setSymbolNumber", &(MarpaX_ESLIF_Valuep->setSymbolNumberSvp));
    MarpaX_ESLIF_Valuep->canSetRuleNameb               = marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setRuleName", &(MarpaX_ESLIF_Valuep->setRuleNameSvp));
    MarpaX_ESLIF_Valuep->canSetRuleNumberb             = marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setRuleNumber", &(MarpaX_ESLIF_Valuep->setRuleNumberSvp));
    MarpaX_ESLIF_Valuep->canSetGrammarb                = marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setGrammar", &(MarpaX_ESLIF_Valuep->setGrammarSvp));
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "isWithHighRankOnly", &(MarpaX_ESLIF_Valuep->isWithHighRankOnlySvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"isWithHighRankOnly\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "isWithOrderByRank", &(MarpaX_ESLIF_Valuep->isWithOrderByRankSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"isWithOrderByRank\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "isWithAmbiguous", &(MarpaX_ESLIF_Valuep->isWithAmbiguousSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"isWithAmbiguous\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "isWithNull", &(MarpaX_ESLIF_Valuep->isWithNullSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"isWithNull\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "maxParses", &(MarpaX_ESLIF_Valuep->maxParsesSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"maxParses\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "setResult", &(MarpaX_ESLIF_Valuep->setResultSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"setResult\"");
    }
    if (! marpaESLIFPerl_canb(aTHX_ Perl_valueInterfacep, "getResult", &(MarpaX_ESLIF_Valuep->getResultSvp))) {
      MARPAESLIFPERL_CROAK("Value interface must be an object that can do \"getResult\"");
    }
  } else {
    MarpaX_ESLIF_Valuep->canSetSymbolNameb     = 0;
    MarpaX_ESLIF_Valuep->canSetSymbolNumberb   = 0;
    MarpaX_ESLIF_Valuep->canSetRuleNameb       = 0;
    MarpaX_ESLIF_Valuep->canSetRuleNumberb     = 0;
    MarpaX_ESLIF_Valuep->canSetGrammarb        = 0;
    MarpaX_ESLIF_Valuep->setSymbolNameSvp      = NULL;
    MarpaX_ESLIF_Valuep->setSymbolNumberSvp    = NULL;
    MarpaX_ESLIF_Valuep->setRuleNameSvp        = NULL;
    MarpaX_ESLIF_Valuep->setRuleNumberSvp      = NULL;
    MarpaX_ESLIF_Valuep->setGrammarSvp         = NULL;
    MarpaX_ESLIF_Valuep->isWithHighRankOnlySvp = NULL;
    MarpaX_ESLIF_Valuep->isWithOrderByRankSvp  = NULL;
    MarpaX_ESLIF_Valuep->isWithAmbiguousSvp    = NULL;
    MarpaX_ESLIF_Valuep->isWithNullSvp         = NULL;
    MarpaX_ESLIF_Valuep->maxParsesSvp          = NULL;
    MarpaX_ESLIF_Valuep->setResultSvp          = NULL;
    MarpaX_ESLIF_Valuep->getResultSvp          = NULL;
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_paramIsGrammarv(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_paramIsGrammarv";
  int                type  = marpaESLIFPerl_getTypei(aTHX_ sv);

  if ((type & SCALAR) != SCALAR) {
    MARPAESLIFPERL_CROAK("Grammar must be a scalar");
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_paramIsEncodingv(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_paramIsEncodingv";
  int                type  = marpaESLIFPerl_getTypei(aTHX_ sv);

  if ((type & SCALAR) != SCALAR) {
    MARPAESLIFPERL_CROAK("Encoding must be a scalar");
  }
}

/*****************************************************************************/
static inline short marpaESLIFPerl_paramIsLoggerInterfaceOrUndefb(pTHX_ SV *sv)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_paramIsLoggerInterfaceOrUndefb";
  int                type  = marpaESLIFPerl_getTypei(aTHX_ sv);

  if ((type & UNDEF) == UNDEF) {
    return 0;
  }

  if ((type & OBJECT) != OBJECT) {
    MARPAESLIFPERL_CROAK("Logger interface must be an object");
  }

  if (! marpaESLIFPerl_canb(aTHX_ sv, "trace", NULL))     MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"trace\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "debug", NULL))     MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"debug\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "info", NULL))      MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"info\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "notice", NULL))    MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"notice\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "warning", NULL))   MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"warning\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "error", NULL))     MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"error\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "critical", NULL))  MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"critical\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "alert", NULL))     MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"alert\"");
  if (! marpaESLIFPerl_canb(aTHX_ sv, "emergency", NULL)) MARPAESLIFPERL_CROAK("Logger interface must be an object that can do \"emergency\"");

  return 1;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_representationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis)
/*****************************************************************************/
{
  static const char    *funcs               = "marpaESLIFPerl_representationDisposev";
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  dTHXa(MarpaX_ESLIF_Valuep->PerlInterpreterp);

  if (inputcp != NULL) {
    Safefree(inputcp);
  }
  /* encoding may refer to the constant UTF8s */
  if ((encodingasciis != NULL) && (encodingasciis != UTF8s)) {
    Safefree(encodingasciis);
  }
}

/*****************************************************************************/
static inline short marpaESLIFPerl_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp)
/*****************************************************************************/
{
  static const char    *funcs               = "marpaESLIFPerl_representationb";
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  marpaESLIF_t         *marpaESLIFp;
  SV                   *svp;
  int                   typei;
  dTHXa(MarpaX_ESLIF_Valuep->PerlInterpreterp);

  /* We always push a PTR */
  if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_PTR)) {
    MARPAESLIFPERL_CROAKF("User-defined value type is not MARPAESLIF_VALUE_TYPE_PTR but %d", marpaESLIFValueResultp->type);
  }
  /* Our context is always MARPAESLIFPERL_CONTEXT */
  if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultp->contextp != MARPAESLIFPERL_CONTEXT)) {
    MARPAESLIFPERL_CROAKF("User-defined value context is not MARPAESLIFPERL_CONTEXT but %p", marpaESLIFValueResultp->contextp);
  }
  marpaESLIFp = marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFValue_recognizerp(MarpaX_ESLIF_Valuep->marpaESLIFValuep)));
  svp = (SV *) marpaESLIFValueResultp->u.p.p;
  marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFp, svp, inputcpp, inputlp, 1 /* encodingInformationb */, NULL /* characterStreambp */, encodingasciisp, NULL /* encodinglp */, 0 /* warnIsFatalb */, 0 /* marpaESLIFStringb */, MarpaX_ESLIF_Valuep->constantsp);

  /* We overwrite *stringbp only when we are sure that the context is truely a number. This can happen only on */
  /* SVs that derive from Math::BigInt or Math::BigFloat, that we explicitly inject as PTR in ESLIF.           */
  typei = marpaESLIFPerl_getTypei(aTHX_ svp);
  if (marpaESLIFPerl_is_Math__BigInt(aTHX_ svp, typei) || marpaESLIFPerl_is_Math__BigFloat(aTHX_ svp, typei)) {
    *stringbp = 0;
  }

  *disposeCallbackpp = marpaESLIFPerl_representationDisposev;

  return 1;
}

/*****************************************************************************/
static inline char *marpaESLIFPerl_sv2byte(pTHX_ marpaESLIF_t *marpaESLIFp, SV *svp, char **bytepp, size_t *bytelp, short encodingInformationb, short *characterStreambp, char **encodingsp, size_t *encodinglp, short warnIsFatalb, short marpaESLIFStringb, MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_sv2byte";
  char              *rcp = NULL;
  short              okb   = 0;
  char              *strings;
  STRLEN             stringl;
  char              *bytep;
  size_t             bytel;
  short              characterStreamb;
  char              *encodings;
  size_t             encodingl;
  SV                *encodingp;
  SV                *valuep;
  char              *tmps;
  STRLEN             tmpl;
#ifdef MARPAESLIFPERL_AUTO_ENCODING_DETECT
  char              *guessedencodings;
#endif

  /* svp == NULL should never happen because we always push an SV* out of actions
     but &PL_sv_undef is of course possible */
  if (MARPAESLIF_UNLIKELY((svp == NULL) || (svp == &PL_sv_undef))) {
    return NULL;
  }

  if (marpaESLIFStringb) {
    /* Caller guarantees that the svp is a MarpaX::ESLIF::String instance. This is not crosschecked. */
    if (encodingInformationb) {
      encodingp = marpaESLIFPerl_call_actionp(aTHX_ svp, "encoding", NULL /* avp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->MarpaX__ESLIF__String__encoding_svp);
    }
    valuep    = marpaESLIFPerl_call_actionp(aTHX_ svp, "value", NULL /* avp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->MarpaX__ESLIF__String__value_svp);

    /* Duplicate value */
    tmps = SvPV(valuep, tmpl);
    if ((tmps == NULL) || (tmpl <= 0)) {
      /* Empty string */
      Newx(bytep, 1, char); /* Hiden NUL byte */
      bytep[0] = '\0';
      bytel = 0;
    } else {
      /* Copy */
      Newx(bytep, (int) (tmpl + 1), char); /* Hiden NUL byte */
      bytel = (size_t) tmpl;
      Copy(tmps, bytep, tmpl, char);
      bytep[tmpl] = '\0';
    }
    rcp = bytep;
    MARPAESLIFPERL_REFCNT_DEC(valuep);

    if (encodingInformationb) {
      /* Check encoding */
      tmps = SvPV(encodingp, tmpl);
      if ((tmps == NULL) || (tmpl <= 0)) {
#ifdef MARPAESLIFPERL_AUTO_ENCODING_DETECT
	/* Guess */
	guessedencodings = marpaESLIF_encodings(marpaESLIFp, bytep, bytel);
	if (guessedencodings != NULL) {
	  /* fprintf(stderr, "==> Encoding (MarpaX::ESLIF::String guess): %s\n", guessedencodings); */
	  characterStreamb = 1;
	  encodingl = strlen(guessedencodings);
	  Newx(encodings, (int) (encodingl + 1), char);
	  Copy(guessedencodings, encodings, encodingl, char);
	  encodings[encodingl] = '\0';
	  marpaESLIFPerl_SYSTEM_FREE(guessedencodings);
	} else {
#else
          /* fprintf(stderr, "==> Encoding (MarpaX::ESLIF::String) : undef\n"); */
#endif
	  characterStreamb = 0;
	  encodings = NULL;
	  encodingl = 0;
#ifdef MARPAESLIFPERL_AUTO_ENCODING_DETECT
	}
#endif
      } else {
	/* Copy */
	/* fprintf(stderr, "==> Encoding (MarpaX::ESLIF::String) : %s\n", tmps); */
	characterStreamb = 1;
	Newx(encodings, (int) (tmpl + 1), char); /* ASCII is NUL byte terminated */
	encodingl = (size_t) tmpl;
	Copy(tmps, encodings, tmpl, char);
	encodings[encodingl] = '\0';
      }
      MARPAESLIFPERL_REFCNT_DEC(encodingp);
    } else {
      characterStreamb = 0;
      encodings = NULL;
      encodingl = 0;
    }

    okb = 1;
    goto ok;
  }

  strings = SvPV(svp, stringl);

  if (strings != NULL) {
    okb = 1;
    /* We assume there is no character outside of UTF-8 (utf8 != UTF-8 -;) */
    if (encodingInformationb) {
      /* We want to respect the eventual bytes pragma, so we use DO_UTF8 */
      if (DO_UTF8(svp)) {
	/* Declared UTF-8 as per perl - trust it and assume perl's utf8 == UTF-8, i.e. no more than 4 bytes for a bytecode -; */
	/* fprintf(stderr, "==> Encoding (perl SvUTF8) : %s\n", UTF8s); */
	characterStreamb    = 1;
	encodings           = (char *) UTF8s;
	encodingl           = UTF8l;
      } else {
#ifdef MARPAESLIFPERL_AUTO_ENCODING_DETECT
	/* Guess */
	guessedencodings = marpaESLIF_encodings(marpaESLIFp, strings, stringl);
	if (guessedencodings != NULL) {
	  /* In perl, only the utf8 attribute can be attached to a string - else it has to be an object aka MarpaX::ESLIF::String */
	  if (strcmp(guessedencodings, "UTF-8") == 0) {
	    /* fprintf(stderr, "==> Encoding (perl guess): %s\n", guessedencodings); */
	    characterStreamb = 1;
	    encodingl= strlen(guessedencodings);
	    Newx(encodings, (int) (encodingl + 1), char);
	    Copy(guessedencodings, encodings, encodingl, char);
	    encodings[encodingl] = '\0';
	  } else {
	    /* fprintf(stderr, "==> Encoding (perl guess REJECTED): %s\n", guessedencodings); */
	    characterStreamb = 0;
	    encodings        = NULL;
	    encodingl        = 0;
	  }
	  marpaESLIFPerl_SYSTEM_FREE(guessedencodings);
	} else {
#endif
	  characterStreamb = 0;
	  encodings        = NULL;
	  encodingl        = 0;
#ifdef MARPAESLIFPERL_AUTO_ENCODING_DETECT
	}
#endif
      }
    } else {
      characterStreamb    = 0;
      encodings           = NULL;
      encodingl           = 0;
    }
  } else {
    if (warnIsFatalb) {
      MARPAESLIFPERL_CROAKF("SvPV() returned {pointer,length}={%p,%ld}", strings, (unsigned long) stringl);
    }
  }

  if (okb) { /* Else nothing will be appended */
    Newx(rcp, (int) (stringl + 1), char); /* Hiden NUL byte */
    if (stringl > 0) {
      bytep = CopyD(strings, rcp, (int) stringl, char);
    } else {
      bytep = rcp;
    }
    bytep[stringl] = '\0';
    bytel = (size_t) stringl;
  }

 ok:

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
    if (encodingsp != NULL) {
      *encodingsp = encodings;
    }
    if (encodinglp != NULL) {
      *encodinglp = encodingl;
    }
  }

  return rcp;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_importb(pTHX_ marpaESLIFPerl_importContext_t *importContextp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short arraycopyb)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFPerl_importb";
  genericStack_t                   *importStackp = importContextp->stackp;
  MarpaX_ESLIF_constants_t         *constantsp = importContextp->constantsp;;
  AV                               *avp;
  HV                               *hvp;
  SV                               *keyp;
  SV                               *valuep;
  SV                               *svp;
  SV                               *stringp;
  SV                               *encodingp;
  AV                               *listp;
#if defined(MARPAESLIFPERL_UTF8_CROSSCHECK) && !defined(is_strict_utf8_string)
  SV                               *checkp;
#endif
  size_t                            i;
  size_t                            j;
  short                             utf8b;
  marpaESLIFPerl_stringGeneratorContext_t  marpaESLIFPerl_stringGeneratorContext;
  genericLogger_t                  *genericLoggerp;
  IV                                ivdummy;
  char                             *s;

  /*
    marpaESLIF Type                    C type    C nb_bits      Perl Type

    MARPAESLIF_VALUE_TYPE_UNDEF                                 newSV(0)
    MARPAESLIF_VALUE_TYPE_CHAR         char      CHAR_BIT       PV*
    MARPAESLIF_VALUE_TYPE_SHORT        short     >= 16          IV or Math::BigInt
    MARPAESLIF_VALUE_TYPE_INT          int       >= 16          IV or Math::BigInt
    MARPAESLIF_VALUE_TYPE_LONG         long      >= 32          IV or Math::BigInt
    MARPAESLIF_VALUE_TYPE_FLOAT        float     depends        NV (because NV is at least a double in perl)
    MARPAESLIF_VALUE_TYPE_DOUBLE       double    depends        NV (because NV is at least a double in perl)
    MARPAESLIF_VALUE_TYPE_PTR          char*                    SV* or PTR2IV()
    MARPAESLIF_VALUE_TYPE_ARRAY                                 PV*
    MARPAESLIF_VALUE_TYPE_BOOL                                  $MarpaX::ESLIF::true or $MarpaX::ESLIF::false
    MARPAESLIF_VALUE_TYPE_STRING                                PV* or MarpaX::ESLIF::String instance
    MARPAESLIF_VALUE_TYPE_ROW                                   AV*
    MARPAESLIF_VALUE_TYPE_TABLE                                 HV*
    MARPAESLIF_VALUE_TYPE_LONG_DOUBLE                           NV* or Math::BigFloat
    MARPAESLIF_VALUE_TYPE_LONG_LONG    long long >= 64          IV or Math::BigInt

  */

  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_UNDEF:
    svp = newSV(0);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_CHAR:
    svp = newSVpvn((const char *) &(marpaESLIFValueResultp->u.c), (STRLEN) 1);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_SHORT:
    if (sizeof(ivdummy) >= sizeof(short)) {
      svp = newSViv((IV) marpaESLIFValueResultp->u.b);
    } else {
      /* Switch to Math::BigInt - we must first generate a string representation of this short. */
#ifdef PERL_IMPLICIT_CONTEXT
      marpaESLIFPerl_stringGeneratorContext.PerlInterpreterp = importContextp->PerlInterpreterp;
#endif
      marpaESLIFPerl_stringGeneratorContext.s      = NULL;
      marpaESLIFPerl_stringGeneratorContext.l      = 0;
      marpaESLIFPerl_stringGeneratorContext.okb    = 0;
      marpaESLIFPerl_stringGeneratorContext.allocl = 0;
      genericLoggerp = GENERICLOGGER_CUSTOM(marpaESLIFPerl_generateStringWithLoggerCallback, (void *) &marpaESLIFPerl_stringGeneratorContext, GENERICLOGGER_LOGLEVEL_TRACE);
      if (MARPAESLIF_UNLIKELY(genericLoggerp == NULL)) {
        MARPAESLIFPERL_CROAKF("GENERICLOGGER_CUSTOM failure, %s", strerror(errno));
      }
      GENERICLOGGER_TRACEF(genericLoggerp, "%d", (int) marpaESLIFValueResultp->u.b); /* This will croak by itself if needed */
      if (MARPAESLIF_UNLIKELY((marpaESLIFPerl_stringGeneratorContext.s == NULL) || (marpaESLIFPerl_stringGeneratorContext.l <= 1))) {
        /* This should never happen */
        GENERICLOGGER_FREE(genericLoggerp);
        MARPAESLIFPERL_CROAKF("Internal error when doing string representation of short %d", (int) marpaESLIFValueResultp->u.b);
      }
      stringp = newSVpvn((const char *) marpaESLIFPerl_stringGeneratorContext.s, (STRLEN) (marpaESLIFPerl_stringGeneratorContext.l - 1));
      free(marpaESLIFPerl_stringGeneratorContext.s);
      marpaESLIFPerl_stringGeneratorContext.s = NULL;
      GENERICLOGGER_FREE(genericLoggerp);

      /* Representation is in stringp. Call Math::BigInt->new(stringp). */
      listp = newAV();
      av_push(listp, stringp); /* Ref count of stringp is transfered to av -; */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__new_svp);
      av_undef(listp);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_INT:
    if (sizeof(ivdummy) >= sizeof(int)) {
      svp = newSViv((IV) marpaESLIFValueResultp->u.i);
    } else {
      /* Switch to Math::BigInt - we must first generate a string representation of this int. */
#ifdef PERL_IMPLICIT_CONTEXT
      marpaESLIFPerl_stringGeneratorContext.PerlInterpreterp = importContextp->PerlInterpreterp;
#endif
      marpaESLIFPerl_stringGeneratorContext.s      = NULL;
      marpaESLIFPerl_stringGeneratorContext.l      = 0;
      marpaESLIFPerl_stringGeneratorContext.okb    = 0;
      marpaESLIFPerl_stringGeneratorContext.allocl = 0;
      genericLoggerp = GENERICLOGGER_CUSTOM(marpaESLIFPerl_generateStringWithLoggerCallback, (void *) &marpaESLIFPerl_stringGeneratorContext, GENERICLOGGER_LOGLEVEL_TRACE);
      if (MARPAESLIF_UNLIKELY(genericLoggerp == NULL)) {
        MARPAESLIFPERL_CROAKF("GENERICLOGGER_CUSTOM failure, %s", strerror(errno));
      }
      GENERICLOGGER_TRACEF(genericLoggerp, "%d", marpaESLIFValueResultp->u.i); /* This will croak by itself if needed */
      if (MARPAESLIF_UNLIKELY((marpaESLIFPerl_stringGeneratorContext.s == NULL) || (marpaESLIFPerl_stringGeneratorContext.l <= 1))) {
        /* This should never happen */
        GENERICLOGGER_FREE(genericLoggerp);
        MARPAESLIFPERL_CROAKF("Internal error when doing string representation of int %d", marpaESLIFValueResultp->u.i);
      }
      stringp = newSVpvn((const char *) marpaESLIFPerl_stringGeneratorContext.s, (STRLEN) (marpaESLIFPerl_stringGeneratorContext.l - 1));
      free(marpaESLIFPerl_stringGeneratorContext.s);
      marpaESLIFPerl_stringGeneratorContext.s = NULL;
      GENERICLOGGER_FREE(genericLoggerp);

      /* Representation is in stringp. Call Math::BigInt->new(stringp). */
      listp = newAV();
      av_push(listp, stringp); /* Ref count of stringp is transfered to av -; */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__new_svp);
      av_undef(listp);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_LONG:
    if (sizeof(ivdummy) >= sizeof(long)) {
      svp = newSViv((IV) marpaESLIFValueResultp->u.l);
    } else {
      /* Switch to Math::BigInt - we must first generate a string representation of this long. */
#ifdef PERL_IMPLICIT_CONTEXT
      marpaESLIFPerl_stringGeneratorContext.PerlInterpreterp = importContextp->PerlInterpreterp;
#endif
      marpaESLIFPerl_stringGeneratorContext.s      = NULL;
      marpaESLIFPerl_stringGeneratorContext.l      = 0;
      marpaESLIFPerl_stringGeneratorContext.okb    = 0;
      marpaESLIFPerl_stringGeneratorContext.allocl = 0;
      genericLoggerp = GENERICLOGGER_CUSTOM(marpaESLIFPerl_generateStringWithLoggerCallback, (void *) &marpaESLIFPerl_stringGeneratorContext, GENERICLOGGER_LOGLEVEL_TRACE);
      if (MARPAESLIF_UNLIKELY(genericLoggerp == NULL)) {
        MARPAESLIFPERL_CROAKF("GENERICLOGGER_CUSTOM failure, %s", strerror(errno));
      }
      GENERICLOGGER_TRACEF(genericLoggerp, "%ld", marpaESLIFValueResultp->u.l); /* This will croak by itself if needed */
      if (MARPAESLIF_UNLIKELY((marpaESLIFPerl_stringGeneratorContext.s == NULL) || (marpaESLIFPerl_stringGeneratorContext.l <= 1))) {
        /* This should never happen */
        GENERICLOGGER_FREE(genericLoggerp);
        MARPAESLIFPERL_CROAKF("Internal error when doing string representation of long %ld", marpaESLIFValueResultp->u.l);
      }
      stringp = newSVpvn((const char *) marpaESLIFPerl_stringGeneratorContext.s, (STRLEN) (marpaESLIFPerl_stringGeneratorContext.l - 1));
      free(marpaESLIFPerl_stringGeneratorContext.s);
      marpaESLIFPerl_stringGeneratorContext.s = NULL;
      GENERICLOGGER_FREE(genericLoggerp);

      /* Representation is in stringp. Call Math::BigInt->new(stringp). */
      listp = newAV();
      av_push(listp, stringp); /* Ref count of stringp is transfered to av -; */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__new_svp);
      av_undef(listp);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_FLOAT:
    /* NVTYPE is at least double */
    svp = newSVnv((NVTYPE) marpaESLIFValueResultp->u.f);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_DOUBLE:
    /* NVTYPE is at least double */
    svp = newSVnv((NVTYPE) marpaESLIFValueResultp->u.d);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_PTR:
    if (marpaESLIFValueResultp->contextp == MARPAESLIFPERL_CONTEXT) {
      /* This is an SV that we pushed */
      svp = (SV *) marpaESLIFValueResultp->u.p.p;
      /* Increase ref count */
      MARPAESLIFPERL_REFCNT_INC(svp);
    } else {
      /* This is a pointer coming from another source */
      svp = newSViv(PTR2IV(marpaESLIFValueResultp->u.p.p));
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_ARRAY:
    if ((marpaESLIFValueResultp->u.a.p != NULL) && (marpaESLIFValueResultp->u.a.sizel > 0)) {
      svp = marpaESLIFPerl_arraycopyp(aTHX_ marpaESLIFValueResultp->u.a.p, (STRLEN) marpaESLIFValueResultp->u.a.sizel, arraycopyb);
    } else {
      /* Empty string */
      svp = newSVpv("", 0);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_BOOL:
    svp = (marpaESLIFValueResultp->u.y == MARPAESLIFVALUERESULTBOOL_FALSE) ? marpaESLIFPerl_false(aTHX_ constantsp) : marpaESLIFPerl_true(aTHX_ constantsp);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_STRING:
    if ((marpaESLIFValueResultp->u.s.p != NULL) && (marpaESLIFValueResultp->u.s.sizel > 0)) {
      stringp = marpaESLIFPerl_arraycopyp(aTHX_ marpaESLIFValueResultp->u.s.p, (STRLEN) marpaESLIFValueResultp->u.s.sizel, arraycopyb);
    } else {
      /* Empty string */
      stringp = newSVpv("", 0);
    }
    utf8b = 0;
    if (MARPAESLIFPERL_ENCODING_IS_UTF8(marpaESLIFValueResultp->u.s.encodingasciis)) {
#ifdef MARPAESLIFPERL_UTF8_CROSSCHECK
      /* Cross-check it is a strict UTF-8 string */
#ifdef is_strict_utf8_string
      /* Since perl-5.26 */
      if (is_strict_utf8_string((const U8 *) marpaESLIFValueResultp->u.s.p, (STRLEN) marpaESLIFValueResultp->u.s.sizel)) {
        svp = stringp;
        SvUTF8_on(svp);
        utf8b = 1;
      } else {
	warn("is_strict_utf8_string() failure on a string claimed to be in UTF encoding\n");
      }
#else
      /* Use Encode::decode("UTF-8", octets, CHECK) - Note that Encode module is always loaded, c.f. MarpaX::ESLIF::String */
      listp = newAV();
      av_push(listp, newSVsv(constantsp->MarpaX__ESLIF__UTF_8_svp));
      av_push(listp, newSVsv(stringp));
      av_push(listp, newSViv(MARPAESLIFPERL_ENCODE_FB_CROAK));
      /* Call Encode::decode static method */
      checkp = marpaESLIFPerl_call_actionp(aTHX_ NULL /* interfacep */, "Encode::decode", listp, NULL /* MarpaX_ESLIF_Valuep */, 1 /* evalb */, 0 /* evalSilentb */, constantsp->Encode__decode_svp);
      /* The object also has an utf8 flag */
      av_undef(listp);
      /* If we are here this did not croak -; */
      if (SvOK(checkp) && (! SvROK(checkp))) {
	/* It returned a defined scalar, so this is ok */
        svp = stringp;
        SvUTF8_on(svp);
        utf8b = 1;
      }
      MARPAESLIFPERL_REFCNT_DEC(checkp);
#endif /* is_strict_utf8_string */
#else
      /* We trust the encoding */
      svp = stringp;
      SvUTF8_on(svp);
      utf8b = 1;
      /* fprintf(stderr, "SvUTF8_on(\"%s\")\n", marpaESLIFValueResultp->u.s.p); */
#endif
    }
    if (! utf8b) {
      /* fprintf(stderr, "MarpaX::ESLIF::String->new(\"%s\", \"%s\")\n", marpaESLIFValueResultp->u.s.p, marpaESLIFValueResultp->u.s.encodingasciis); */
      /* This will be a MarpaX::ESLIF::String */
      encodingp = newSVpv(marpaESLIFValueResultp->u.s.encodingasciis, 0);
      listp = newAV();
      av_push(listp, stringp);
      av_push(listp, encodingp);
      /* Gets the object and create a reference to it */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__String_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->MarpaX__ESLIF__String__new_svp);
      /* The object also has an utf8 flag */
      av_undef(listp);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_ROW:
    /* We received elements in order: first, second, etc..., we pushed that in internalStack, so pop will say last, beforelast, etc..., second, first */
    avp = newAV();
    if (marpaESLIFValueResultp->u.r.sizel > 0) {
      j = marpaESLIFValueResultp->u.r.sizel - 1;
#ifdef av_extend
      /* Size argument is the last indice */
      av_extend(avp, (SSize_t) j);
#endif
      for (i = 0; i < marpaESLIFValueResultp->u.r.sizel; i++, j--) {
	svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(importStackp);
        /* No need to MARPAESLIFPERL_REFCNT_INC(svp) because we always increase any SV that it is internalStack */
	/* MARPAESLIFPERL_REFCNT_INC(svp); */
	if (MARPAESLIF_UNLIKELY(av_store(avp, (SSize_t) j, (svp == &PL_sv_undef) ? newSV(0) : svp) == NULL)) {
	  /* MARPAESLIFPERL_REFCNT_DEC(svp); */
	  MARPAESLIFPERL_CROAKF("av_store failure at indice %ld", (unsigned long) i);
	}
      }
    }
    svp = newRV((SV *)avp);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_TABLE:
    /* We received elements in order: firstkey, firstvalue, secondkey, secondvalue, etc..., we pushed that in internalStack, so pop will say lastvalue, lastkey, ..., firstvalue, firstkey */
    hvp = newHV();
#ifdef hv_ksplit
    /* Size argument seems to be the last indice + 1, i.e. the number of elements */
    hv_ksplit(hvp, (IV) marpaESLIFValueResultp->u.t.sizel);
#endif
    for (i = 0; i < marpaESLIFValueResultp->u.t.sizel; i++) {
      /* Note that importStackp contains only new SV's, or &PL_sv_undef, &PL_sv_yes, &PL_sv_no */
      /* This is why it is not necessary to SvREFCNT_inc/SvREFCNT_dec on valuep: all we do is create an SV and move it in the hash */
      valuep = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(importStackp);
      keyp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(importStackp);
      if (MARPAESLIF_UNLIKELY(hv_store_ent(hvp, keyp, (valuep == &PL_sv_undef) ? newSV(0) : valuep, 0) == NULL)) {
        /* We never play with tied hashes, so hv_store_ent() must return a non-NULL value */
        MARPAESLIFPERL_CROAK("hv_store_ent failure");
      }
    }
    svp = newRV((SV *)hvp);
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
  case MARPAESLIF_VALUE_TYPE_LONG_DOUBLE:
    /* Note that typecast ld to f is always ok for +/-Infinity or NaN, because they remains +/-Infinity or NaN */
    if ((! constantsp->nvtype_is_long_doubleb) &&
        (! constantsp->nvtype_is___float128) &&
        (! marpaESLIFValueResult_isinfb(importContextp->marpaESLIFp, marpaESLIFValueResultp)) &&
        (! marpaESLIFValueResult_isnanb(importContextp->marpaESLIFp, marpaESLIFValueResultp))) {
      /* Switch to Math::BigFloat - we must first generate a string representation of this long double. */
#ifdef PERL_IMPLICIT_CONTEXT
      marpaESLIFPerl_stringGeneratorContext.PerlInterpreterp = importContextp->PerlInterpreterp;
#endif
      s = marpaESLIF_ldtos(importContextp->marpaESLIFp, marpaESLIFValueResultp->u.ld);
      if (MARPAESLIF_UNLIKELY(s == NULL)) {
        MARPAESLIFPERL_CROAKF("Failed to get string representation of long double %Lf", marpaESLIFValueResultp->u.ld);
      }
      stringp = newSVpv((const char *) s, 0);
      free(s);
      s = NULL;

      /* Representation is in stringp. Call Math::BigFloat->new(stringp). */
      listp = newAV();
      av_push(listp, stringp); /* Ref count of stringp is transfered to av -; */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigFloat_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigFloat__new_svp);
      av_undef(listp);

    } else {
      /* NVTYPE here is long double or __float128 */
      svp = newSVnv((NVTYPE) marpaESLIFValueResultp->u.ld);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
#ifdef MARPAESLIF_HAVE_LONG_LONG
  case MARPAESLIF_VALUE_TYPE_LONG_LONG:
    if (sizeof(ivdummy) >= sizeof(MARPAESLIF_LONG_LONG)) {
      svp = newSViv((IV) marpaESLIFValueResultp->u.ll);
    } else {
      /* Switch to Math::BigInt - we must first generate a string representation of this long. */
#ifdef PERL_IMPLICIT_CONTEXT
      marpaESLIFPerl_stringGeneratorContext.PerlInterpreterp = importContextp->PerlInterpreterp;
#endif
      marpaESLIFPerl_stringGeneratorContext.s      = NULL;
      marpaESLIFPerl_stringGeneratorContext.l      = 0;
      marpaESLIFPerl_stringGeneratorContext.okb    = 0;
      marpaESLIFPerl_stringGeneratorContext.allocl = 0;
      genericLoggerp = GENERICLOGGER_CUSTOM(marpaESLIFPerl_generateStringWithLoggerCallback, (void *) &marpaESLIFPerl_stringGeneratorContext, GENERICLOGGER_LOGLEVEL_TRACE);
      if (MARPAESLIF_UNLIKELY(genericLoggerp == NULL)) {
        MARPAESLIFPERL_CROAKF("GENERICLOGGER_CUSTOM failure, %s", strerror(errno));
      }
      GENERICLOGGER_TRACEF(genericLoggerp, MARPAESLIF_LONG_LONG_FMT, marpaESLIFValueResultp->u.ll); /* This will croak by itself if needed */
      if (MARPAESLIF_UNLIKELY((marpaESLIFPerl_stringGeneratorContext.s == NULL) || (marpaESLIFPerl_stringGeneratorContext.l <= 1))) {
        /* This should never happen */
        GENERICLOGGER_FREE(genericLoggerp);
        MARPAESLIFPERL_CROAKF("Internal error when doing string representation of long %lld", marpaESLIFValueResultp->u.ll);
      }
      stringp = newSVpvn((const char *) marpaESLIFPerl_stringGeneratorContext.s, (STRLEN) (marpaESLIFPerl_stringGeneratorContext.l - 1));
      free(marpaESLIFPerl_stringGeneratorContext.s);
      marpaESLIFPerl_stringGeneratorContext.s = NULL;
      GENERICLOGGER_FREE(genericLoggerp);

      /* Representation is in stringp. Call Math::BigInt->new(stringp). */
      listp = newAV();
      av_push(listp, stringp); /* Ref count of stringp is transfered to av -; */
      svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__new_svp);
      av_undef(listp);
    }
    marpaESLIFPerl_GENERICSTACK_PUSH_PTR(importStackp, svp);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(importStackp))) {
      MARPAESLIFPERL_CROAKF("importStackp push failure, %s", strerror(errno));
    }
    break;
#endif /* MARPAESLIF_HAVE_LONG_LONG */
  default:
    break;
  }

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_valueImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char              *funcs               = "marpaESLIFPerl_valueImportb";
  MarpaX_ESLIF_Value_t           *MarpaX_ESLIF_Valuep = (MarpaX_ESLIF_Value_t *) userDatavp;
  marpaESLIFPerl_importContext_t  importContext;
  dTHXa(MarpaX_ESLIF_Valuep->PerlInterpreterp);

  importContext.marpaESLIFp      = marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFValue_recognizerp(MarpaX_ESLIF_Valuep->marpaESLIFValuep)));
  importContext.stackp           = MarpaX_ESLIF_Valuep->internalStackp;
  importContext.constantsp       = MarpaX_ESLIF_Valuep->constantsp;
#ifdef PERL_IMPLICIT_CONTEXT
  importContext.PerlInterpreterp = MarpaX_ESLIF_Valuep->PerlInterpreterp;
#endif

  return marpaESLIFPerl_importb(aTHX_ &importContext, marpaESLIFValueResultp, 1 /* arraycopyb */);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_recognizerImportb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char              *funcs                    = "marpaESLIFPerl_recognizerImportb";
  MarpaX_ESLIF_Recognizer_t      *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  marpaESLIFPerl_importContext_t  importContext;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  importContext.marpaESLIFp      = marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp));
  importContext.stackp           = MarpaX_ESLIF_Recognizerp->internalStackp;
  importContext.constantsp       = MarpaX_ESLIF_Recognizerp->constantsp;
#ifdef PERL_IMPLICIT_CONTEXT
  importContext.PerlInterpreterp = MarpaX_ESLIF_Recognizerp->PerlInterpreterp;
#endif

  return marpaESLIFPerl_importb(aTHX_ &importContext, marpaESLIFValueResultp, 0 /* arraycopyb */);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_symbolImportb(marpaESLIFSymbol_t *marpaESLIFSymbolp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char              *funcs                = "marpaESLIFPerl_symbolImportb";
  MarpaX_ESLIF_Symbol_t          *MarpaX_ESLIF_Symbolp = (MarpaX_ESLIF_Symbol_t *) userDatavp;
  marpaESLIFPerl_importContext_t  importContext;
  dTHXa(MarpaX_ESLIF_Symbolp->PerlInterpreterp);

  importContext.marpaESLIFp      = marpaESLIFSymbol_eslifp(MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp);
  importContext.stackp           = MarpaX_ESLIF_Symbolp->internalStackp;
  importContext.constantsp       = MarpaX_ESLIF_Symbolp->constantsp;
#ifdef PERL_IMPLICIT_CONTEXT
  importContext.PerlInterpreterp = MarpaX_ESLIF_Symbolp->PerlInterpreterp;
#endif

  return marpaESLIFPerl_importb(aTHX_ &importContext, marpaESLIFValueResultp, 1 /* arraycopyb */);
}

/*****************************************************************************/
static inline void marpaESLIFPerl_generateStringWithLoggerCallback(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs)
/*****************************************************************************/
{
  marpaESLIFPerl_appendOpaqueDataToStringGenerator((marpaESLIFPerl_stringGeneratorContext_t *) userDatavp, (char *) msgs, strlen(msgs));
}

/*****************************************************************************/
static inline short marpaESLIFPerl_appendOpaqueDataToStringGenerator(marpaESLIFPerl_stringGeneratorContext_t *marpaESLIFPerl_stringGeneratorContextp, char *p, size_t sizel)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_appendOpaqueDataToStringGenerator";
  char              *tmpp;
  short              rcb;
  size_t             allocl;
  size_t             wantedl;
  dTHXa(marpaESLIFPerl_stringGeneratorContextp->PerlInterpreterp);

  /* Note: caller must guarantee that marpaESLIFPerl_stringGeneratorContextp->p != NULL and l > 0 */

  if (marpaESLIFPerl_stringGeneratorContextp->s == NULL) {
    /* Get an allocl that is a multiple of 1024, taking into account the hiden NUL byte */
    /* 1023 -> 1024 */
    /* 1024 -> 2048 */
    /* 2047 -> 2048 */
    /* 2048 -> 3072 */
    /* ... */
    /* i.e. this is the upper multiple of 1024 and have space for the NUL byte */
    allocl = MARPAESLIFPERL_CHUNKED_SIZE_UPPER(sizel, 1024);
    /* Check for turn-around, should never happen */
    if (MARPAESLIF_UNLIKELY(allocl < sizel)) {
      MARPAESLIFPERL_CROAK("size_t turnaround detected");
      goto err;
    }
    marpaESLIFPerl_stringGeneratorContextp->s  = malloc(allocl);
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_stringGeneratorContextp->s == NULL)) {
      MARPAESLIFPERL_CROAKF("malloc failure, %s", strerror(errno));
      goto err;
    }
    memcpy(marpaESLIFPerl_stringGeneratorContextp->s, p, sizel);
    marpaESLIFPerl_stringGeneratorContextp->l      = sizel + 1;  /* NUL byte is set at exit of the routine */
    marpaESLIFPerl_stringGeneratorContextp->allocl = allocl;
    marpaESLIFPerl_stringGeneratorContextp->okb    = 1;
  } else if (MARPAESLIF_LIKELY(marpaESLIFPerl_stringGeneratorContextp->okb)) {
    wantedl = marpaESLIFPerl_stringGeneratorContextp->l + sizel; /* +1 for the NUL is already accounted in marpaESLIFPerl_stringGeneratorContextp->l */
    allocl = MARPAESLIFPERL_CHUNKED_SIZE_UPPER(wantedl, 1024);
    /* Check for turn-around, should never happen */
    if (MARPAESLIF_UNLIKELY(allocl < wantedl)) {
      MARPAESLIFPERL_CROAK("size_t turnaround detected");
      goto err;
    }
    if (allocl > marpaESLIFPerl_stringGeneratorContextp->allocl) {
      tmpp = realloc(marpaESLIFPerl_stringGeneratorContextp->s, allocl); /* The +1 for the NULL byte is already in */
      if (MARPAESLIF_UNLIKELY(tmpp == NULL)) {
        MARPAESLIFPERL_CROAKF("realloc failure, %s", strerror(errno));
        goto err;
      }
      marpaESLIFPerl_stringGeneratorContextp->s      = tmpp;
      marpaESLIFPerl_stringGeneratorContextp->allocl = allocl;
    }
    memcpy(marpaESLIFPerl_stringGeneratorContextp->s + marpaESLIFPerl_stringGeneratorContextp->l - 1, p, sizel);
    marpaESLIFPerl_stringGeneratorContextp->l = wantedl; /* Already contains the +1 fir the NUL byte */
  } else {
    MARPAESLIFPERL_CROAKF("Invalid internal call to %s", funcs);
    goto err;
  }

  marpaESLIFPerl_stringGeneratorContextp->s[marpaESLIFPerl_stringGeneratorContextp->l - 1] = '\0';
  rcb = 1;
  goto done;

 err:
  if (marpaESLIFPerl_stringGeneratorContextp->s != NULL) {
    free(marpaESLIFPerl_stringGeneratorContextp->s);
    marpaESLIFPerl_stringGeneratorContextp->s = NULL;
  }
  marpaESLIFPerl_stringGeneratorContextp->okb    = 0;
  marpaESLIFPerl_stringGeneratorContextp->l      = 0;
  marpaESLIFPerl_stringGeneratorContextp->allocl = 0;
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_scalar_string_only(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  /* It must have been created as a PV or coerced to it at least once */
  return (typei == SCALAR) && SvPOK(svp);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_undef(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (typei == UNDEF);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_arrayref(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (typei == ARRAYREF);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_MarpaX__ESLIF__String(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (((typei & OBJECT) == OBJECT) && sv_derived_from(svp, "MarpaX::ESLIF::String"));
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_Math__BigInt(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (((typei & OBJECT) == OBJECT) && sv_derived_from(svp, "Math::BigInt"));
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_Math__BigFloat(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (((typei & OBJECT) == OBJECT) && sv_derived_from(svp, "Math::BigFloat"));
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_hashref(pTHX_ SV *svp, int typei)
/*****************************************************************************/
{
  return (typei == HASHREF);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_is_bool(pTHX_ SV *svp, int typei, MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  AV    *avp;
  short rcb;

  /* We request that at least it has be an object - the MarpaX::ESLIF::is_bool will check object nature itself */
  if ((typei & OBJECT) == OBJECT) {
    avp = newAV();
    av_push(avp, (svp == &PL_sv_undef) ? newSV(0) : newSVsv(svp)); /* Ref count of stringp is transfered to av -; */
    svp = marpaESLIFPerl_call_actionp(aTHX_ NULL /* interfacep */, "MarpaX::ESLIF::is_bool", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->MarpaX__ESLIF__is_bool_svp);
    av_undef(avp);
    rcb = SvTRUE(svp);
    MARPAESLIFPERL_REFCNT_DEC(svp);
  } else {
    rcb = 0;
  }

  return rcb;
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_true(pTHX_ MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  return newSVsv(constantsp->MarpaX__ESLIF__true_svp);
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_false(pTHX_ MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  return newSVsv(constantsp->MarpaX__ESLIF__false_svp);
}

/*****************************************************************************/
static inline void marpaESLIFPerl_stack_setv(pTHX_ marpaESLIF_t *marpaESLIFp, marpaESLIFValue_t *marpaESLIFValuep, int resulti, SV *svp, marpaESLIFValueResult_t *marpaESLIFValueResultOutputp, short incb, MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
/* Take care: IF resulti is >= 0, then marpaESLIFValuep must be != NULL      */
/*****************************************************************************/
{
  static const char       *funcs = "marpaESLIFPerl_stack_setv";
  genericStack_t           marpaESLIFValueResultStack;
  genericStack_t          *marpaESLIFValueResultStackp = &marpaESLIFValueResultStack;
  genericStack_t           svStack;
  genericStack_t          *svStackp = &svStack;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIFValueResult_t *marpaESLIFValueResultp;
  int                      typei;
  short                    eslifb;
  char                    *bytep;
  size_t                   bytel;
  char                    *encodings;
  IV                       iv;
  NV                       nv;
  HV                      *hvp;
  size_t                   iterl;
  char                    *keys;
  I32                      reti;
  SV                      *iterp;
  AV                      *avp;
  SSize_t                  aviteratorl;
  short                    marpaESLIFStringb;

  /* We maintain in parallel a marpaESLIFValueResult and an SV stacks */
  marpaESLIFPerl_GENERICSTACK_INIT(marpaESLIFValueResultStackp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(marpaESLIFValueResultStackp))) {
    MARPAESLIFPERL_CROAKF("GENERICSTACK_INIT() failure, %s", strerror(errno));
  }

  marpaESLIFPerl_GENERICSTACK_INIT(svStackp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(svStackp))) {
    MARPAESLIFPERL_CROAKF("GENERICSTACK_INIT() failure, %s", strerror(errno));
  }

  marpaESLIFPerl_GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, &marpaESLIFValueResult);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(marpaESLIFValueResultStackp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFValueResultStackp push failure, %s", strerror(errno));
  }

  marpaESLIFPerl_GENERICSTACK_PUSH_PTR(svStackp, svp);
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(svStackp))) {
    MARPAESLIFPERL_CROAKF("svStackp push failure, %s", strerror(errno));
  }

  while (marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueResultStackp) > 0) {
    marpaESLIFValueResultp = (marpaESLIFValueResult_t *) marpaESLIFPerl_GENERICSTACK_POP_PTR(marpaESLIFValueResultStackp);
    svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(svStackp);
    if (incb) {
      MARPAESLIFPERL_REFCNT_INC(svp);
    }
    typei = marpaESLIFPerl_getTypei(aTHX_ svp);

    eslifb = 0;
    if (marpaESLIFPerl_is_undef(aTHX_ svp, typei)) {
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_UNDEF;
      marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      eslifb = 1;
    } else if (marpaESLIFPerl_is_hashref(aTHX_ svp, typei)) {
      hvp = (HV *) SvRV(svp);
      marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_TABLE;
      marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
      marpaESLIFValueResultp->representationp    = NULL;
      marpaESLIFValueResultp->u.t.sizel          = (size_t) HvKEYS(hvp);
      marpaESLIFValueResultp->u.t.shallowb       = 0;
      marpaESLIFValueResultp->u.t.freeUserDatavp = marpaESLIFPerlaTHX;
      marpaESLIFValueResultp->u.t.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
      if (marpaESLIFValueResultp->u.t.sizel > 0) {
        Newx(marpaESLIFValueResultp->u.t.p, marpaESLIFValueResultp->u.t.sizel, marpaESLIFValueResultPair_t);
        iterl = 0;
        /* Note: we never do sv_2mortal, because either we successfully converted an svp, then MARPAESLIFPERL_REFCNT_DEC(svp) is called, */
        /* either we need it alive because it does not have an ESLIF equivalent */
        hv_iterinit(hvp);
        while ((iterp = hv_iternextsv(hvp, &keys, &reti)) != NULL) {
          if (MARPAESLIF_UNLIKELY(iterl >= marpaESLIFValueResultp->u.t.sizel)) {
            /* This should not happen */
            MARPAESLIFPERL_CROAKF("Iterating over hash reaches more than %ld coming from HvKEYS()", (unsigned long) marpaESLIFValueResultp->u.t.sizel);
          }
          /* Keep svStackp and marpaESLIFValueResultStackp in synch */
          /* - Key */
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(svStackp, (void *) MARPAESLIFPERL_NEWSVPVN_UTF8(keys, reti));
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(svStackp))) {
            MARPAESLIFPERL_CROAKF("svStackp push failure, %s", strerror(errno));
          }
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, (void *) &(marpaESLIFValueResultp->u.t.p[iterl].key));
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(marpaESLIFValueResultStackp))) {
            MARPAESLIFPERL_CROAKF("marpaESLIFValueResultStackp push failure, %s", strerror(errno));
          }
          /* - Value */
          iterp = newSVsv(iterp);
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(svStackp, (void *) iterp);
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(svStackp))) {
            MARPAESLIFPERL_CROAKF("svStackp push failure, %s", strerror(errno));
          }
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, (void *) &(marpaESLIFValueResultp->u.t.p[iterl].value));
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(marpaESLIFValueResultStackp))) {
            MARPAESLIFPERL_CROAKF("marpaESLIFValueResultStackp push failure, %s", strerror(errno));
          }
          ++iterl;
        }
      } else {
        marpaESLIFValueResultp->u.t.p = NULL;
      }
      eslifb = 1;

    } else if (marpaESLIFPerl_is_arrayref(aTHX_ svp, typei)) {
      avp = (AV *) SvRV(svp);
      marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_ROW;
      marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
      marpaESLIFValueResultp->representationp    = NULL;
      marpaESLIFValueResultp->u.r.sizel          = (size_t) (av_len(avp) + 1);
      marpaESLIFValueResultp->u.r.shallowb       = 0;
      marpaESLIFValueResultp->u.r.freeUserDatavp = marpaESLIFPerlaTHX;
      marpaESLIFValueResultp->u.r.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
      if (marpaESLIFValueResultp->u.r.sizel > 0) {
        Newx(marpaESLIFValueResultp->u.r.p, marpaESLIFValueResultp->u.r.sizel, marpaESLIFValueResult_t);
        for (aviteratorl = 0; aviteratorl < marpaESLIFValueResultp->u.r.sizel; aviteratorl++) {
          SV **svpp = av_fetch(avp, aviteratorl, 0);
          if (MARPAESLIF_UNLIKELY(svpp == NULL)) {
            MARPAESLIFPERL_CROAKF("av_fetch returned NULL during export at indice %ld", (unsigned long) aviteratorl);
          }
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(svStackp, (void *) newSVsv(*svpp));
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(svStackp))) {
            MARPAESLIFPERL_CROAKF("svStackp push failure, %s", strerror(errno));
          }
          marpaESLIFPerl_GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, (void *) &(marpaESLIFValueResultp->u.r.p[aviteratorl]));
          if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_ERROR(marpaESLIFValueResultStackp))) {
            MARPAESLIFPERL_CROAKF("marpaESLIFValueResultStackp push failure, %s", strerror(errno));
          }
        }
      } else {
        marpaESLIFValueResultp->u.r.p = NULL;
      }
      eslifb = 1;
    } else if (marpaESLIFPerl_is_bool(aTHX_ svp, typei, constantsp)) {
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_BOOL;
      marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      /* Since boolean is not a true type in Perl, most booleans involves magic */
      SvGETMAGIC(svp);
      marpaESLIFValueResultp->u.y             = SvTRUE(svp) ? MARPAESLIFVALUERESULTBOOL_TRUE : MARPAESLIFVALUERESULTBOOL_FALSE;
      eslifb = 1;
    } else if ((typei == SCALAR) && SvNOK(svp)) {
      nv = SvNVX(svp);
      if (constantsp->nvtype_is_long_doubleb) {
        /* NVTYPE is long double -; */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG_DOUBLE;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.ld            = (long double) nv;
        eslifb = 1;
      } else if (! constantsp->nvtype_is___float128) {
        /* NVTYPE is double -; */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_DOUBLE;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.d             = (double) nv;
        eslifb = 1;
      }
    } else if ((typei == SCALAR) && SvIOK(svp)) {
      iv = SvIVX(svp);
      if ((iv >= SHRT_MIN) && (iv <= SHRT_MAX)) {
        /* Ok if it fits into [SHRT_MIN,SHRT_MAX] */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_SHORT;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.b             = (short) iv;
        eslifb = 1;
      } else if ((iv >= INT_MIN) && (iv <= INT_MAX)) {
      /* Ok if it fits into [INT_MIN,INT_MAX] */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_INT;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.i             = (int) iv;
        eslifb = 1;
      } else if ((iv >= LONG_MIN) && (iv <= LONG_MAX)) {
        /* Ok if it fits into [LONG_MIN,LONG_MAX] */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.l             = (long) iv;
        eslifb = 1;
#ifdef MARPAESLIF_HAVE_LONG_LONG
      } else if ((iv >= MARPAESLIF_LLONG_MIN) && (iv <= MARPAESLIF_LLONG_MAX)) {
        /* Ok if it fits into [MARPAESLIF_LLONG_MIN,MARPAESLIF_LLONG_MAX] */
        marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG_LONG;
        marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
        marpaESLIFValueResultp->representationp = NULL;
        marpaESLIFValueResultp->u.ll            = (MARPAESLIF_LONG_LONG) iv;
        eslifb = 1;
#endif
      }
    } else if ((marpaESLIFStringb = marpaESLIFPerl_is_MarpaX__ESLIF__String(aTHX_ svp, typei)) /* Must be first because of marpaESLIFStringb */ || marpaESLIFPerl_is_scalar_string_only(aTHX_ svp, typei)) {

      /* fprintf(stderr, "marpaESLIFStringb=%d\n", marpaESLIFStringb); */
      if (marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFp, svp, &bytep, &bytel, 1 /* encodingInformationb */, NULL /* characterStreambp */, &encodings, NULL /* encodinglp */, 0 /* warnIsFatalb */, marpaESLIFStringb, constantsp) != NULL) {
        /* fprintf(stderr, "==> STRING, ENCODING=%s\n", encodings != NULL ? encodings : "(null)"); */
        if (encodings != NULL) {
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_STRING;
          marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.s.p              = (unsigned char*) bytep;
          marpaESLIFValueResultp->u.s.sizel          = bytel;
          marpaESLIFValueResultp->u.s.encodingasciis = encodings;
          marpaESLIFValueResultp->u.s.shallowb       = 0;
	  marpaESLIFValueResultp->u.s.freeUserDatavp = marpaESLIFPerlaTHX;
	  marpaESLIFValueResultp->u.s.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
          eslifb = 1;
        } else if (bytep != NULL) {
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_ARRAY;
          marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.a.p              = (char *) bytep;
          marpaESLIFValueResultp->u.a.sizel          = bytel;
          marpaESLIFValueResultp->u.a.shallowb       = 0;
	  marpaESLIFValueResultp->u.a.freeUserDatavp = marpaESLIFPerlaTHX;
	  marpaESLIFValueResultp->u.a.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
          eslifb = 1;
        }
      }
    }

    if (! eslifb) {
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_PTR;
      marpaESLIFValueResultp->contextp        = MARPAESLIFPERL_CONTEXT;
      marpaESLIFValueResultp->representationp = marpaESLIFPerl_representationb;
      marpaESLIFValueResultp->u.p.p           = svp;
      marpaESLIFValueResultp->u.p.shallowb    = 0;
      marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
      marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;
    } else {
      /* We do not need this svp anymore */
      MARPAESLIFPERL_REFCNT_DEC(svp);
    }
  }

  if (resulti >= 0) {
    if (MARPAESLIF_UNLIKELY(! marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult))) {
      MARPAESLIFPERL_CROAKF("marpaESLIFValue_stack_setb failure, %s", strerror(errno));
    }
  }
  if (marpaESLIFValueResultOutputp != NULL) {
    *marpaESLIFValueResultOutputp = marpaESLIFValueResult;
  }

  marpaESLIFPerl_GENERICSTACK_RESET(svStackp);
  marpaESLIFPerl_GENERICSTACK_RESET(marpaESLIFValueResultStackp);
}

/*****************************************************************************/
static inline short marpaESLIFPerl_JSONDecodeNumberAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb)
/*****************************************************************************/
{
  /* We always use Math::BigFloat->new(strings) */
  static const char         *funcs                    = "marpaESLIFPerl_JSONDecodeNumberAction";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  MarpaX_ESLIF_constants_t  *constantsp               = MarpaX_ESLIF_Recognizerp->constantsp;
  AV                        *listp;
  SV                        *svp;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (confidenceb) {
    return 1;
  }

  listp = newAV();
  av_push(listp, newSVpvn((const char *) strings, (STRLEN) stringl)); /* Ref count of string is transfered to listp */
  svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigFloat_svp, "new", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigFloat__new_svp);
  av_undef(listp);

  marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
  marpaESLIFValueResultp->representationp    = marpaESLIFPerl_representationb;
  marpaESLIFValueResultp->u.p.p              = svp;
  marpaESLIFValueResultp->u.p.shallowb       = 0;
  marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_JSONDecodePositiveInfinityAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb)
/*****************************************************************************/
{
  /* We always use Math::BigInt->binf() */
  static const char         *funcs                    = "marpaESLIFPerl_JSONDecodePositiveInfinityAction";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  MarpaX_ESLIF_constants_t  *constantsp               = MarpaX_ESLIF_Recognizerp->constantsp;
  SV                        *svp;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (confidenceb) {
    return 1;
  }

  svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "binf", NULL /* svp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__binf_svp);

  marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
  marpaESLIFValueResultp->representationp    = marpaESLIFPerl_representationb;
  marpaESLIFValueResultp->u.p.p              = svp;
  marpaESLIFValueResultp->u.p.shallowb       = 0;
  marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_JSONDecodeNegativeInfinityAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb)
/*****************************************************************************/
{
  /* We always give priority to Math::BigInt->binf('-') */
  static const char         *funcs                    = "marpaESLIFPerl_JSONDecodeNegativeInfinityAction";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  MarpaX_ESLIF_constants_t  *constantsp               = MarpaX_ESLIF_Recognizerp->constantsp;
  AV                        *listp;
  SV                        *svp;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (confidenceb) {
    return 1;
  }

  listp = newAV();
  av_push(listp, newSVpvn((const char *) "-", (STRLEN) 1)); /* Ref count of string is transfered to listp */
  svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "binf", listp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__binf_svp);
  av_undef(listp);

  marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
  marpaESLIFValueResultp->representationp    = marpaESLIFPerl_representationb;
  marpaESLIFValueResultp->u.p.p              = svp;
  marpaESLIFValueResultp->u.p.shallowb       = 0;
  marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_JSONDecodePositiveNanAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb)
/*****************************************************************************/
{
  /* We always give priority to Math::BigInt->bnan() */
  static const char         *funcs                    = "marpaESLIFPerl_JSONDecodePositiveNanAction";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  MarpaX_ESLIF_constants_t  *constantsp               = MarpaX_ESLIF_Recognizerp->constantsp;
  SV                        *svp;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (confidenceb) {
    return 1;
  }

  svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "bnan", NULL /* svp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__bnan_svp);

  marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
  marpaESLIFValueResultp->representationp    = marpaESLIFPerl_representationb;
  marpaESLIFValueResultp->u.p.p              = svp;
  marpaESLIFValueResultp->u.p.shallowb       = 0;
  marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;

  return 1;
}

/*****************************************************************************/
static inline short marpaESLIFPerl_JSONDecodeNegativeNanAction(void *userDatavp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp, short confidenceb)
/*****************************************************************************/
{
  /* We always give priority to Math::BigInt->bnan('-') */
  static const char         *funcs                    = "marpaESLIFPerl_JSONDecodeNegativeNanAction";
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = (MarpaX_ESLIF_Recognizer_t *) userDatavp;
  MarpaX_ESLIF_constants_t  *constantsp               = MarpaX_ESLIF_Recognizerp->constantsp;
  SV                        *svp;
  dTHXa(MarpaX_ESLIF_Recognizerp->PerlInterpreterp);

  if (confidenceb) {
    /* This will be injected as a float for sure. Take care Perl may very represent it a "NaN" */
    /* instead of "-NaN" though.                                                               */
    return 1;
  }

  marpaESLIFPerl_genericLoggerCallbackv(MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp, GENERICLOGGER_LOGLEVEL_WARNING, "Negative NaN converted to Math::BigInt->bnan()");

  /* Take care! Math::BigInt do not have a notion of negative nan */
  svp = marpaESLIFPerl_call_actionp(aTHX_ constantsp->Math__BigInt_svp, "bnan", NULL /* svp */, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, constantsp->Math__BigInt__bnan_svp);

  marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
  marpaESLIFValueResultp->contextp           = MARPAESLIFPERL_CONTEXT;
  marpaESLIFValueResultp->representationp    = marpaESLIFPerl_representationb;
  marpaESLIFValueResultp->u.p.p              = svp;
  marpaESLIFValueResultp->u.p.shallowb       = 0;
  marpaESLIFValueResultp->u.p.freeUserDatavp = marpaESLIFPerlaTHX;
  marpaESLIFValueResultp->u.p.freeCallbackp  = marpaESLIFPerl_genericFreeCallbackv;

  return 1;
}

/*****************************************************************************/
static inline void *marpaESLIFPerl_Perl2enginep(pTHX_ SV *Perl_argumentp)
/*****************************************************************************/
{
  static const char  *funcs = "marpaESLIFPerl_Perl2enginep";
  int                 typei;
  HV                 *hvp;
  SV                **svpp;

  typei = marpaESLIFPerl_getTypei(aTHX_ Perl_argumentp);
  if (MARPAESLIF_UNLIKELY((typei & HASHREF) != HASHREF)) {
    MARPAESLIFPERL_CROAK("Argument is not a HASH reference");
  }

  hvp = (HV *) SvRV(Perl_argumentp);
  svpp = hv_fetch(hvp, "engine", 6, 0);
  if (MARPAESLIF_UNLIKELY(svpp == NULL)) {
    MARPAESLIFPERL_CROAK("No 'engine' key in hash");
  }
  
  return INT2PTR(void *, SvIV(*svpp));
}

/*****************************************************************************/
static inline void marpaESLIFPerl_constants_initv(pTHX_ MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_constants_initv";

  constantsp->MarpaX__ESLIF_svp  = newSVpvn("MarpaX::ESLIF", strlen("MarpaX::ESLIF"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->MarpaX__ESLIF_svp, "is_bool", &(constantsp->MarpaX__ESLIF__is_bool_svp))) {
    MARPAESLIFPERL_CROAK("MarpaX::ESLIF must do \"is_bool\"");
  }
  constantsp->MarpaX__ESLIF__UTF_8_svp  = newSVpvn("UTF-8", strlen("UTF-8"));
  constantsp->Math__BigFloat_svp = newSVpvn("Math::BigFloat", strlen("Math::BigFloat"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->Math__BigFloat_svp, "new", &(constantsp->Math__BigFloat__new_svp))) {
    MARPAESLIFPERL_CROAK("Math::BigFloat must do \"new\"");
  }
  constantsp->Math__BigInt_svp = newSVpvn("Math::BigInt", strlen("Math::BigInt"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->Math__BigInt_svp, "new", &(constantsp->Math__BigInt__new_svp))) {
    MARPAESLIFPERL_CROAK("Math::BigInt must do \"new\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->Math__BigInt_svp, "binf", &(constantsp->Math__BigInt__binf_svp))) {
    MARPAESLIFPERL_CROAK("Math::BigInt must do \"binf\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->Math__BigInt_svp, "bnan", &(constantsp->Math__BigInt__bnan_svp))) {
    MARPAESLIFPERL_CROAK("Math::BigInt must do \"bnan\"");
  }
  constantsp->nvtype_is_long_doubleb = marpaESLIFPerl_call_methodb(aTHX_ constantsp->MarpaX__ESLIF_svp, "_nvtype_is_long_double", NULL /* subSvp */);
  constantsp->nvtype_is___float128 = marpaESLIFPerl_call_methodb(aTHX_ constantsp->MarpaX__ESLIF_svp, "_nvtype_is___float128", NULL /* subSvp */);
  constantsp->MarpaX__ESLIF__true_svp = get_sv("MarpaX::ESLIF::true", 0);
  constantsp->MarpaX__ESLIF__false_svp = get_sv("MarpaX::ESLIF::false", 0);
  constantsp->MarpaX__ESLIF__Grammar__Properties_svp = newSVpvn("MarpaX::ESLIF::Grammar::Properties", strlen("MarpaX::ESLIF::Grammar::Properties"));
  constantsp->MarpaX__ESLIF__Grammar__Rule__Properties_svp    = newSVpvn("MarpaX::ESLIF::Grammar::Rule::Properties", strlen("MarpaX::ESLIF::Grammar::Rule::Properties"));
  constantsp->MarpaX__ESLIF__Grammar__Symbol__Properties_svp  = newSVpvn("MarpaX::ESLIF::Grammar::Symbol::Properties", strlen("MarpaX::ESLIF::Grammar::Symbol::Properties"));
  constantsp->MarpaX__ESLIF__String_svp  = newSVpvn("MarpaX::ESLIF::String", strlen("MarpaX::ESLIF::String"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->MarpaX__ESLIF__String_svp, "new", &(constantsp->MarpaX__ESLIF__String__new_svp))) {
    MARPAESLIFPERL_CROAK("MarpaX::ESLIF::String must do \"new\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->MarpaX__ESLIF__String_svp, "encoding", &(constantsp->MarpaX__ESLIF__String__encoding_svp))) {
    MARPAESLIFPERL_CROAK("MarpaX::ESLIF::String must do \"encoding\"");
  }
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->MarpaX__ESLIF__String_svp, "value", &(constantsp->MarpaX__ESLIF__String__value_svp))) {
    MARPAESLIFPERL_CROAK("MarpaX::ESLIF::String must do \"value\"");
  }
  constantsp->Encode_svp  = newSVpvn("Encode", strlen("Encode"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->Encode_svp, "decode", &(constantsp->Encode__decode_svp))) {
    MARPAESLIFPERL_CROAK("Encode must do \"decode\"");
  }
  constantsp->MarpaX__ESLIF__Recognizer_svp  = newSVpvn("MarpaX::ESLIF::Recognizer", strlen("MarpaX::ESLIF::Recognizer"));
  if (! marpaESLIFPerl_canb(aTHX_ constantsp->MarpaX__ESLIF__Recognizer_svp, "SHALLOW", &(constantsp->MarpaX__ESLIF__Recognizer__SHALLOW_svp))) {
    MARPAESLIFPERL_CROAK("MarpaX::ESLIF::Recognizer must do \"SHALLOW\"");
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_constants_disposev(pTHX_ MarpaX_ESLIF_constants_t *constantsp)
/*****************************************************************************/
{
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__is_bool_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__UTF_8_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigFloat_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigFloat__new_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigInt_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigInt__new_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigInt__binf_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Math__BigInt__bnan_svp);
  /*
  constantsp->nvtype_is_long_doubleb = 0;
  constantsp->nvtype_is___float128 = 0;
  */
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__true_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__false_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__Grammar__Properties_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__Grammar__Rule__Properties_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__Grammar__Symbol__Properties_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__String_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__String__new_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__String__encoding_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__String__value_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Encode_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->Encode__decode_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__Recognizer_svp);
  MARPAESLIFPERL_REFCNT_DEC(constantsp->MarpaX__ESLIF__Recognizer__SHALLOW_svp);
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_engine2Perlp(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_engine2Perlp";
  AV                *avp;
  SV                *svp;

  avp = newAV();
  av_push(avp, newSViv(PTR2IV(MarpaX_ESLIF_Recognizerp)));
  svp = marpaESLIFPerl_call_actionp(aTHX_ MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp->constants.MarpaX__ESLIF__Recognizer_svp,
                                    "SHALLOW", /* methods */
                                    avp,
                                    NULL, /* MarpaX_ESLIF_Valuep */
                                    0, /* evalb */
                                    0, /* evalSilentb */
                                    MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp->constants.MarpaX__ESLIF__Recognizer__SHALLOW_svp);
  av_undef(avp);

  return svp;
}

/*****************************************************************************/
static inline void marpaESLIFPerl_setRecognizerEngineForCallbackv(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_setRecognizerEngineForCallbackv";
  SV                *shallowp;

  if (MarpaX_ESLIF_Recognizerp->setRecognizerSvp != &PL_sv_undef) {
    /* MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp MAY BE NULL when we are called back via the parse interface   */
    /* When we the user is doing an explicit new MarpaX::ESLIF::Recognizer(), then marpaESLIFRecognizerp is equal to */
    /* MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp. But take care: newFrom will create a recognizer that is      */
    /* sharing the userDatavp of its parent, that is pointer to original's MarpaX_ESLIF_Recognizerp that will point  */
    /* to... original's marpaESLIFRecognizerp. This is why it is always vital to do:                                 */
    /* marpaESLIFPerl_setRecognizerEngineForCallbackv()                                                              */
    /* { your work }                                                                                                 */
    /* There is no consequence to overwrite MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp in any case:             */
    /* - Either we are an explicit MarpaX::ESLIF::Recognizer::new or newFrom and it is a no-op                       */
    /* - Either we are created by MarpaX::ESLIF::Recognizer::parse internally and we are never going to be DESTROYed */
    /* (then the context in on the stack in this method in fact).                                                    */
    MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerBackupp = MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp;
    MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp = marpaESLIFRecognizerp;

    if (MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerLastp != marpaESLIFRecognizerp) {
      shallowp = marpaESLIFPerl_engine2Perlp(aTHX_ MarpaX_ESLIF_Recognizerp);
      marpaESLIFPerl_call_methodv(aTHX_ MarpaX_ESLIF_Recognizerp->Perl_recognizerInterfacep,
                                  "setRecognizer",
                                  shallowp,
                                  MarpaX_ESLIF_Recognizerp->setRecognizerSvp);
      MARPAESLIFPERL_REFCNT_DEC(shallowp);
      MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerLastp = marpaESLIFRecognizerp;
    }
  }
}

/*****************************************************************************/
static inline void marpaESLIFPerl_restoreRecognizerEngineForCallbackv(pTHX_ MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_restoreRecognizerEngineForCallbackv";

  if (MarpaX_ESLIF_Recognizerp->setRecognizerSvp != &PL_sv_undef) {
    MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp = MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerBackupp;
  }
}

/*****************************************************************************/
static inline SV *marpaESLIFPerl_arraycopyp(pTHX_ char *p, STRLEN sizel, short arraycopyb)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFPerl_arraycopyp";
  SV                *svp;

  if (arraycopyb) {
    /* We want an explicit copy */
    svp = newSVpvn(p, sizel);
  } else {
    /* We do not really want memcpy - we do an import based on the address. */
    /* C.f .https://codeverge.com/perl.perl5.porters/xs-question/200124 */
    svp = newSV(0);
    SvUPGRADE(svp, SVt_PV);
    SvPOK_only(svp);
    SvPV_set(svp, p);
    SvLEN_set(svp, 0);
    SvCUR_set(svp, sizel);
    SvREADONLY_on(svp);
  }

  return svp;
}

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF                                                           */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::allocate                                                 */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, ...)
  SV *Perl_packagep;
PREINIT:
  static const char  *funcs = "MarpaX::ESLIF::allocate";
CODE:
  SV                 *Perl_loggerInterfacep    = &PL_sv_undef;
  short               loggerInterfaceIsObjectb = 0;
  MarpaX_ESLIF_t     *MarpaX_ESLIFp;
  marpaESLIFOption_t  marpaESLIFOption;

  if(items > 1) {
    loggerInterfaceIsObjectb = marpaESLIFPerl_paramIsLoggerInterfaceOrUndefb(aTHX_ Perl_loggerInterfacep = ST(1));
  }

  Newx(MarpaX_ESLIFp, 1, MarpaX_ESLIF_t);
  marpaESLIFPerl_ContextInitv(aTHX_ MarpaX_ESLIFp);

  /* ------------- */
  /* genericLogger */
  /* ------------- */
  if (loggerInterfaceIsObjectb) {
    MarpaX_ESLIFp->Perl_loggerInterfacep = Perl_loggerInterfacep;
    MarpaX_ESLIFp->genericLoggerp        = genericLogger_newp(marpaESLIFPerl_genericLoggerCallbackv, MarpaX_ESLIFp, GENERICLOGGER_LOGLEVEL_TRACE);
    if (MARPAESLIF_UNLIKELY(MarpaX_ESLIFp->genericLoggerp == NULL)) {
      int save_errno = errno;
      marpaESLIFPerl_ContextFreev(aTHX_ MarpaX_ESLIFp);
      MARPAESLIFPERL_CROAKF("genericLogger_newp failure, %s", strerror(save_errno));
    }
  }

  /* ---------- */
  /* marpaESLIF */
  /* ---------- */
  marpaESLIFOption.genericLoggerp = MarpaX_ESLIFp->genericLoggerp;
  MarpaX_ESLIFp->marpaESLIFp = marpaESLIF_newp(&marpaESLIFOption);
  if (MARPAESLIF_UNLIKELY(MarpaX_ESLIFp->marpaESLIFp == NULL)) {
    int save_errno = errno;
    marpaESLIFPerl_ContextFreev(aTHX_ MarpaX_ESLIFp);
    MARPAESLIFPERL_CROAKF("marpaESLIF_newp failure, %s", strerror(save_errno));
  }

  RETVAL = MarpaX_ESLIFp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::dispose                                                  */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(p)
  SV *p;
PREINIT:
  static const char  *funcs = "MarpaX::ESLIF::dispose";
CODE:
  MarpaX_ESLIF_t *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  marpaESLIFPerl_ContextFreev(aTHX_ MarpaX_ESLIFp);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::version                                                  */
  /* ----------------------------------------------------------------------- */
=cut

char *
version(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::version";
CODE:
  MarpaX_ESLIF_t *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char           *versions;

  if (MARPAESLIF_UNLIKELY(! marpaESLIF_versionb(MarpaX_ESLIFp->marpaESLIFp, &versions))) {
    MARPAESLIFPERL_CROAKF("marpaESLIF_versionb failure, %s", strerror(errno));
  }
  RETVAL = versions;
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::JSON::Encoder                                            */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::JSON::Encoder

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::JSON::Encoder::allocate                                  */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, p, ...)
  SV *Perl_packagep;
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::JSON::Encoder::allocate";
CODE:
  MarpaX_ESLIF_t              *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIF_t                *marpaESLIFp    = MarpaX_ESLIFp->marpaESLIFp;
  MarpaX_ESLIF_JSON_Encoder_t *MarpaX_ESLIF_JSON_Encoderp;
  marpaESLIFGrammar_t         *marpaESLIFGrammarp;
  short                        strictb = 1;

  if(items > 2) {
    strictb = SvTRUE(ST(2)) ? 1 : 0;
  }

  Newx(MarpaX_ESLIF_JSON_Encoderp, 1, MarpaX_ESLIF_JSON_Encoder_t);
  marpaESLIFPerl_grammarContextInitv(aTHX_ p, MarpaX_ESLIFp, MarpaX_ESLIF_JSON_Encoderp, &(MarpaX_ESLIFp->constants));

  marpaESLIFGrammarp = marpaESLIFJSON_encode_newp(marpaESLIFp, strictb);
  if (MARPAESLIF_UNLIKELY(marpaESLIFGrammarp == NULL)) {
    MARPAESLIFPERL_CROAKF("marpaESLIFJSON_encode_newp failure, %s", strerror(errno));
  }
  MarpaX_ESLIF_JSON_Encoderp->marpaESLIFGrammarp = marpaESLIFGrammarp;

  RETVAL = MarpaX_ESLIF_JSON_Encoderp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::JSON::Encoder::encode                                    */
  /* ----------------------------------------------------------------------- */
=cut

SV *
encode(p, Perl_inputp)
  SV *p;
  SV *Perl_inputp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::JSON::Encoder::encode";
CODE:
  MarpaX_ESLIF_JSON_Encoder_t  *MarpaX_ESLIF_JSON_Encoderp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  MarpaX_ESLIF_Value_t          marpaESLIFValueContext;
  marpaESLIFValueResult_t       marpaESLIFValueResult;
  SV                           *svp;

  marpaESLIFPerl_valueContextInitv(aTHX_ p, NULL /* SV of value interface */, &marpaESLIFValueContext, MarpaX_ESLIF_JSON_Encoderp->constantsp, MarpaX_ESLIF_JSON_Encoderp->MarpaX_ESLIFp);

  marpaESLIFValueOption.userDatavp             = &marpaESLIFValueContext;
  marpaESLIFValueOption.importerp              = marpaESLIFPerl_valueImportb;

  /* Create a marpaESLIFValueResult from Perl_inputp */
  marpaESLIFPerl_stack_setv(aTHX_ marpaESLIFGrammar_eslifp(MarpaX_ESLIF_JSON_Encoderp->marpaESLIFGrammarp), NULL /* marpaESLIFValuep */, -1 /* resulti */, Perl_inputp, &marpaESLIFValueResult, 1 /* incb */, MarpaX_ESLIF_JSON_Encoderp->constantsp);
  if (MARPAESLIF_UNLIKELY(! marpaESLIFJSON_encodeb(MarpaX_ESLIF_JSON_Encoderp->marpaESLIFGrammarp, &marpaESLIFValueResult, &marpaESLIFValueOption))) {
    marpaESLIFPerl_valueContextFreev(aTHX_ &marpaESLIFValueContext, 1 /* onStackb */);
    MARPAESLIFPERL_CROAK("marpaESLIFJSON_encodeb failure");
  }

  /* Propagate the result to Perl */
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp) != 1)) {
    MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp));
  }
  svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(marpaESLIFValueContext.internalStackp);

  marpaESLIFPerl_valueContextFreev(aTHX_ &marpaESLIFValueContext, 1 /* onStackb */);

  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::JSON::Decoder                                            */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::JSON::Decoder

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::JSON::Decoder::allocate                                  */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, p, ...)
  SV *Perl_packagep;
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::JSON::Decoder::allocate";
CODE:
  MarpaX_ESLIF_t              *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIF_t                *marpaESLIFp   = MarpaX_ESLIFp->marpaESLIFp;
  MarpaX_ESLIF_JSON_Decoder_t *MarpaX_ESLIF_JSON_Decoderp;
  marpaESLIFGrammar_t         *marpaESLIFGrammarp;
  short                        strictb = 1;

  if(items > 2) {
    strictb = SvTRUE(ST(2)) ? 1 : 0;
  }

  Newx(MarpaX_ESLIF_JSON_Decoderp, 1, MarpaX_ESLIF_JSON_Decoder_t);
  marpaESLIFPerl_grammarContextInitv(aTHX_ p, MarpaX_ESLIFp, MarpaX_ESLIF_JSON_Decoderp, &(MarpaX_ESLIFp->constants));

  marpaESLIFGrammarp = marpaESLIFJSON_decode_newp(marpaESLIFp, strictb);
  if (MARPAESLIF_UNLIKELY(marpaESLIFGrammarp == NULL)) {
    MARPAESLIFPERL_CROAKF("marpaESLIFJSON_decode_newp failure, %s", strerror(errno));
  }
  MarpaX_ESLIF_JSON_Decoderp->marpaESLIFGrammarp = marpaESLIFGrammarp;

  RETVAL = MarpaX_ESLIF_JSON_Decoderp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::JSON::Decoder::_decode                                   */
  /* ----------------------------------------------------------------------- */
=cut

SV *
_decode(p, Perl_recognizerInterfacep, Perl_disallowDupkeysp, Perl_maxDepthp, Perl_noReplacementCharacterp)
  SV *p;
  SV *Perl_recognizerInterfacep;
  SV *Perl_disallowDupkeysp;
  SV *Perl_maxDepthp;
  SV *Perl_noReplacementCharacterp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::JSON::Decoder::_decode";
CODE:
  MarpaX_ESLIF_JSON_Decoder_t  *MarpaX_ESLIF_JSON_Decoderp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  MarpaX_ESLIF_Value_t          marpaESLIFValueContext;
  MarpaX_ESLIF_Recognizer_t     marpaESLIFRecognizerContext;
  marpaESLIFJSONDecodeOption_t  marpaESLIFJSONDecodeOption;
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  SV                           *svp;
  int                           typei;
  size_t                        maxDepthl = 0;

  /*
  CALLGRIND_START_INSTRUMENTATION;
  CALLGRIND_TOGGLE_COLLECT;
  */

  marpaESLIFPerl_recognizerContextInitv(aTHX_ MarpaX_ESLIF_JSON_Decoderp, p, Perl_recognizerInterfacep, &marpaESLIFRecognizerContext, NULL, MarpaX_ESLIF_JSON_Decoderp->constantsp, MarpaX_ESLIF_JSON_Decoderp->MarpaX_ESLIFp);
  marpaESLIFPerl_valueContextInitv(aTHX_ p, NULL /* SV of value interface */, &marpaESLIFValueContext, MarpaX_ESLIF_JSON_Decoderp->constantsp, MarpaX_ESLIF_JSON_Decoderp->MarpaX_ESLIFp);

  /* maxDepth option verification */
  typei = marpaESLIFPerl_getTypei(aTHX_ Perl_maxDepthp);
  if ((typei != SCALAR) || (!SvIOK(svp))) {
    /* This is an error unless it is undef */
    if (! marpaESLIFPerl_is_undef(aTHX_ Perl_maxDepthp, typei)) {
      MARPAESLIFPERL_CROAK("maxDepth option must be an integer scalar or undef");
    }
  } else {
    maxDepthl = (size_t) SvIVX(svp);
  }
  marpaESLIFJSONDecodeOption.disallowDupkeysb                = SvTRUE(Perl_disallowDupkeysp) ? 1 : 0;
  marpaESLIFJSONDecodeOption.maxDepthl                       = maxDepthl;
  marpaESLIFJSONDecodeOption.noReplacementCharacterb         = SvTRUE(Perl_noReplacementCharacterp) ? 1 : 0;
  marpaESLIFJSONDecodeOption.positiveInfinityActionp         = marpaESLIFPerl_JSONDecodePositiveInfinityAction;
  marpaESLIFJSONDecodeOption.negativeInfinityActionp         = marpaESLIFPerl_JSONDecodeNegativeInfinityAction;
  marpaESLIFJSONDecodeOption.positiveNanActionp              = marpaESLIFPerl_JSONDecodePositiveNanAction;
  marpaESLIFJSONDecodeOption.negativeNanActionp              = marpaESLIFPerl_JSONDecodeNegativeNanAction;
  marpaESLIFJSONDecodeOption.numberActionp                   = marpaESLIFPerl_JSONDecodeNumberAction;

  marpaESLIFRecognizerOption.userDatavp               = &marpaESLIFRecognizerContext;
  marpaESLIFRecognizerOption.readerCallbackp          = marpaESLIFPerl_readerCallbackb;
  marpaESLIFRecognizerOption.disableThresholdb        = 1;
  marpaESLIFRecognizerOption.exhaustedb               = 0;
  marpaESLIFRecognizerOption.newlineb                 = 1;
  marpaESLIFRecognizerOption.trackb                   = 0;
  marpaESLIFRecognizerOption.bufsizl                  = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci          = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci              = 50; /* Recommended value */
  marpaESLIFRecognizerOption.ifActionResolverp        = NULL;
  marpaESLIFRecognizerOption.eventActionResolverp     = NULL;
  marpaESLIFRecognizerOption.regexActionResolverp     = NULL;
  marpaESLIFRecognizerOption.generatorActionResolverp = NULL;
  marpaESLIFRecognizerOption.importerp                = NULL;
  
  marpaESLIFValueOption.userDatavp             = &marpaESLIFValueContext;
  marpaESLIFValueOption.importerp              = marpaESLIFPerl_valueImportb;

  if (! marpaESLIFJSON_decodeb(MarpaX_ESLIF_JSON_Decoderp->marpaESLIFGrammarp, &marpaESLIFJSONDecodeOption, &marpaESLIFRecognizerOption, &marpaESLIFValueOption)) {
    MARPAESLIFPERL_CROAK("marpaESLIFJSON_decodeb failure");
  }

  /* Propagate the result to Perl */
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp) != 1)) {
    MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp));
  }
  svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(marpaESLIFValueContext.internalStackp);

  marpaESLIFPerl_valueContextFreev(aTHX_ &marpaESLIFValueContext, 1 /* onStackb */);
  marpaESLIFPerl_recognizerContextFreev(aTHX_ &marpaESLIFRecognizerContext, 1 /* onStackb */);

  RETVAL = svp;
  /*
  CALLGRIND_TOGGLE_COLLECT;
  CALLGRIND_STOP_INSTRUMENTATION;
  */
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Grammar                                                  */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Grammar

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::allocate                                        */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, p, Perl_grammarp, ...)
  SV *Perl_packagep;
  SV *p;
  SV *Perl_grammarp;
PREINIT:
  static const char           *funcs          = "MarpaX::ESLIF::Grammar::allocate";
CODE:
  MarpaX_ESLIF_t              *MarpaX_ESLIFp  = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  SV                          *Perl_encodingp = &PL_sv_undef;
  marpaESLIF_t                *marpaESLIFp    = MarpaX_ESLIFp->marpaESLIFp;
  void                        *string1s       = NULL;
  void                        *string2s       = NULL;
  void                        *string3s       = NULL;
  MarpaX_ESLIF_Grammar_t      *MarpaX_ESLIF_Grammarp;
  marpaESLIFGrammar_t         *marpaESLIFGrammarp;
  marpaESLIFGrammarOption_t    marpaESLIFGrammarOption;

  marpaESLIFPerl_paramIsGrammarv(aTHX_ Perl_grammarp);
  if (items > 3) {
    marpaESLIFPerl_paramIsEncodingv(aTHX_ Perl_encodingp = ST(3));
    string1s = marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFp,
				      Perl_encodingp,
				      &(marpaESLIFGrammarOption.encodings),
				      &(marpaESLIFGrammarOption.encodingl),
				      1, /* encodingInformationb */
				      NULL, /* characterStreambp */
				      NULL, /* encodingsp */
				      NULL, /* encodinglp */
				      1, /* warnIsFatalb */
				      0, /* marpaESLIFStringb */
                                      &(MarpaX_ESLIFp->constants));
    string2s = marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFp,
				      Perl_grammarp,
				      (char **) &(marpaESLIFGrammarOption.bytep),
				      &(marpaESLIFGrammarOption.bytel),
				      0, /* encodingInformationb */
				      NULL, /* characterStreambp */
				      NULL, /* encodingsp */
				      NULL, /* encodinglp */
				      1, /* warnIsFatalb */
				      0, /* marpaESLIFStringb */
                                      &(MarpaX_ESLIFp->constants));
  } else {
    string3s = marpaESLIFPerl_sv2byte(aTHX_ marpaESLIFp,
				      Perl_grammarp,
				      (char **) &(marpaESLIFGrammarOption.bytep),
				      &(marpaESLIFGrammarOption.bytel),
				      1, /* encodingInformationb */
				      NULL, /* characterStreambp */
				      &(marpaESLIFGrammarOption.encodings),
				      &(marpaESLIFGrammarOption.encodingl),
				      1, /* warnIsFatalb */
				      0, /* marpaESLIFStringb */
                                      &(MarpaX_ESLIFp->constants));
  }

  Newx(MarpaX_ESLIF_Grammarp, 1, MarpaX_ESLIF_Grammar_t);
  marpaESLIFPerl_grammarContextInitv(aTHX_ p, MarpaX_ESLIFp, MarpaX_ESLIF_Grammarp, &(MarpaX_ESLIFp->constants));

  marpaESLIFGrammarp = marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption);
  if (MARPAESLIF_UNLIKELY(marpaESLIFGrammarp == NULL)) {
    int save_errno = errno;
    marpaESLIFPerl_grammarContextFreev(aTHX_ MarpaX_ESLIF_Grammarp);
    MARPAESLIFPERL_CROAKF("marpaESLIFGrammar_newp failure, %s", strerror(save_errno));
  }
  MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp = marpaESLIFGrammarp;

  if (string1s != NULL) { Safefree(string1s); }
  if (string2s != NULL) { Safefree(string2s); }
  if (string3s != NULL) { Safefree(string3s); }

  RETVAL = MarpaX_ESLIF_Grammarp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::dispose                                         */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::dispose";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  marpaESLIFPerl_grammarContextFreev(aTHX_ MarpaX_ESLIF_Grammarp);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ngrammar                                        */
  /* ----------------------------------------------------------------------- */
=cut

IV
ngrammar(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ngrammar";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                     ngrammari;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ngrammarib(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ngrammari))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ngrammarib failure");
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
currentLevel(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                     leveli;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammar_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammar_currentb failure");
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
currentDescription(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentDescription";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFString_t     *descp;
  SV                     *svp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammar_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, NULL, &descp))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammar_currentb failure");
  }
  /* It is in the same encoding as original grammar */
  svp = MARPAESLIFPERL_NEWSVPVN_UTF8(descp->bytep, descp->bytel);
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::descriptionByLevel                              */
  /* ----------------------------------------------------------------------- */
=cut

SV *
descriptionByLevel(p, Perl_leveli)
  SV *p;
  IV  Perl_leveli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::descriptionByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFString_t     *descp;
  SV                     *svp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammar_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_leveli, NULL, NULL, &descp))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammar_by_levelb failure");
  }
  /* It is in the same encoding as original grammar */
  svp = MARPAESLIFPERL_NEWSVPVN_UTF8(descp->bytep, descp->bytel);
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentRuleIds                                  */
  /* ----------------------------------------------------------------------- */
=cut

AV *
currentRuleIds(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentRuleIds";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                    *ruleip;
  size_t                  rulel;
  size_t                  i;
  AV                     *av;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_rulearray_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ruleip, &rulel))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_rulearray_currentb failure");
  }
  if (MARPAESLIF_UNLIKELY(rulel <= 0)) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_rulearray_currentb returned no rule");
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
ruleIdsByLevel(p, Perl_leveli)
  SV *p;
  IV  Perl_leveli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleIdsByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                    *ruleip;
  size_t                  rulel;
  size_t                  i;
  AV                     *av;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_rulearray_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &ruleip, &rulel, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_rulearray_by_levelb failure");
  }
  if (MARPAESLIF_UNLIKELY(rulel <= 0)) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_rulearray_by_levelb returned no rule");
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
currentSymbolIds(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentSymbolIds";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                    *symbolip;
  size_t                  symboll;
  size_t                  i;
  AV                     *av;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symbolarray_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &symbolip, &symboll))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolarray_currentb failure");
  }
  if (MARPAESLIF_UNLIKELY(symboll <= 0)) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolarray_currentb returned no symbol");
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
symbolIdsByLevel(p, Perl_leveli)
  SV *p;
  IV  Perl_leveli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolIdsByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                    *symbolip;
  size_t                  symboll;
  size_t                  i;
  AV                     *av;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symbolarray_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &symbolip, &symboll, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolarray_by_levelb failure");
  }
  if (MARPAESLIF_UNLIKELY(symboll <= 0)) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolarray_by_levelb returned no symbol");
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
currentProperties(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentProperties";
CODE:
  MarpaX_ESLIF_Grammar_t      *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t    *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFGrammarProperty_t  grammarProperty;
  AV                          *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammarproperty_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &grammarProperty))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammarproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "level",               grammarProperty.leveli);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "maxLevel",            grammarProperty.maxLeveli);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",         grammarProperty.descp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "latm",                grammarProperty.latmb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardIsFallback",   grammarProperty.discardIsFallbackb);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultEventAction",  grammarProperty.defaultEventActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultRegexAction",  grammarProperty.defaultRegexActionp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "startId",             grammarProperty.starti);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardId",           grammarProperty.discardi);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "defaultEncoding",     grammarProperty.defaultEncodings);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "fallbackEncoding",    grammarProperty.fallbackEncodings);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::propertiesByLevel                               */
  /* ----------------------------------------------------------------------- */
=cut

SV *
propertiesByLevel(p, Perl_leveli)
  SV *p;
  IV  Perl_leveli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::propertiesByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t      *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t    *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFGrammarProperty_t  grammarProperty;
  AV                          *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammarproperty_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &grammarProperty, (int) Perl_leveli, NULL /* descp */))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammarproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "level",               grammarProperty.leveli);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "maxLevel",            grammarProperty.maxLeveli);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",         grammarProperty.descp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "latm",                grammarProperty.latmb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardIsFallback",   grammarProperty.discardIsFallbackb);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultEventAction",  grammarProperty.defaultEventActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "defaultRegexAction",  grammarProperty.defaultRegexActionp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "startId",             grammarProperty.starti);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardId",           grammarProperty.discardi);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "defaultEncoding",     grammarProperty.defaultEncodings);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "fallbackEncoding",    grammarProperty.fallbackEncodings);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentRuleProperties                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentRuleProperties(p, Perl_rulei)
  SV *p;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentRuleProperties";
CODE:
  MarpaX_ESLIF_Grammar_t   *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFRuleProperty_t  ruleProperty;
  AV                       *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruleproperty_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleProperty))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruleproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "id",                       ruleProperty.idi);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",              ruleProperty.descp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "show",                     ruleProperty.asciishows);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "separatorId",              ruleProperty.separatori);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "skipIndices",              ruleProperty.nrhsl, ruleProperty.skipbp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "action",                   ruleProperty.actionp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "rank",                     ruleProperty.ranki);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "proper",                   ruleProperty.properb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "minimum",                  ruleProperty.minimumi);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "hideseparator",            ruleProperty.hideseparatorb);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Rule__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::rulePropertiesByLevel                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
rulePropertiesByLevel(p, Perl_leveli, Perl_rulei)
  SV *p;
  IV  Perl_leveli;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::rulePropertiesByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t   *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFRuleProperty_t  ruleProperty;
  AV                       *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruleproperty_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleProperty, (int) Perl_leveli, NULL /* descp */))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruleproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "id",                       ruleProperty.idi);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",              ruleProperty.descp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "show",                     ruleProperty.asciishows);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "separatorId",              ruleProperty.separatori);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIFPERL_XV_STORE_IVARRAY    (avp, "skipIndices",              ruleProperty.nrhsl, ruleProperty.skipbp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "action",                   ruleProperty.actionp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "rank",                     ruleProperty.ranki);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "proper",                   ruleProperty.properb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "minimum",                  ruleProperty.minimumi);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "hideseparator",            ruleProperty.hideseparatorb);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Rule__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::currentSymbolProperties                         */
  /* ----------------------------------------------------------------------- */
=cut

SV *
currentSymbolProperties(p, Perl_symboli)
  SV *p;
  IV  Perl_symboli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::currentSymbolProperties";
CODE:
  MarpaX_ESLIF_Grammar_t     *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t   *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFSymbolProperty_t  symbolProperty;
  AV                         *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symbolproperty_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symbolProperty))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolproperty_currentb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "type",                       symbolProperty.type);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "start",                      symbolProperty.startb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discard",                    symbolProperty.discardb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lhs",                        symbolProperty.lhsb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "top",                        symbolProperty.topb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "id",                         symbolProperty.idi);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",                symbolProperty.descp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "priority",                   symbolProperty.priorityi);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "propertyBitSet",             symbolProperty.propertyBitSet);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventBitSet",                symbolProperty.eventBitSet);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "symbolAction",               symbolProperty.symbolActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "ifAction",                   symbolProperty.ifActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "generatorAction",            symbolProperty.generatorActionp);
  MARPAESLIFPERL_XV_STORE_YESNO      (avp, "verbose",                    symbolProperty.verboseb);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Symbol__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::symbolPropertiesByLevel                           */
  /* ----------------------------------------------------------------------- */
=cut

SV *
symbolPropertiesByLevel(p, Perl_leveli, Perl_symboli)
  SV *p;
  IV  Perl_leveli;
  IV  Perl_symboli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolPropertiesByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t     *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_constants_t   *constantsp            = MarpaX_ESLIF_Grammarp->constantsp;
  marpaESLIFSymbolProperty_t  symbolProperty;
  AV                         *avp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symbolproperty_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symbolProperty, (int) Perl_leveli, NULL /* descp */))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symbolproperty_by_levelb failure");
  }

  avp = newAV();
  MARPAESLIFPERL_XV_STORE_IV         (avp, "type",                       symbolProperty.type);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "start",                      symbolProperty.startb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discard",                    symbolProperty.discardb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lhs",                        symbolProperty.lhsb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "top",                        symbolProperty.topb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "id",                         symbolProperty.idi);
  MARPAESLIFPERL_XV_STORE_STRING     (avp, "description",                symbolProperty.descp);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIFPERL_XV_STORE_ASCIISTRING(avp, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "priority",                   symbolProperty.priorityi);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "propertyBitSet",             symbolProperty.propertyBitSet);
  MARPAESLIFPERL_XV_STORE_IV         (avp, "eventBitSet",                symbolProperty.eventBitSet);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "symbolAction",               symbolProperty.symbolActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "ifAction",                   symbolProperty.ifActionp);
  MARPAESLIFPERL_XV_STORE_ACTION     (avp, "generatorAction",            symbolProperty.generatorActionp);
  MARPAESLIFPERL_XV_STORE_YESNO      (avp, "verbose",                    symbolProperty.verboseb);

  RETVAL = marpaESLIFPerl_call_actionp(aTHX_ constantsp->MarpaX__ESLIF__Grammar__Symbol__Properties_svp, "new", avp, NULL /* MarpaX_ESLIF_Valuep */, 0 /* evalb */, 0 /* evalSilentb */, NULL /* subSvp */);
  av_undef(avp);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Grammar::ruleDisplay                                     */
  /* ----------------------------------------------------------------------- */
=cut

char *
ruleDisplay(p, Perl_rulei)
  SV *p;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleDisplay";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *ruledisplays;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruledisplayform_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruledisplays))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruledisplayform_currentb failure");
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
symbolDisplay(p, Perl_symboli)
  SV *p;
  IV  Perl_symboli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolDisplay";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *symboldisplays;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symboldisplayform_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symboldisplays))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symboldisplayform_currentb failure");
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
ruleShow(p, Perl_rulei)
  SV *p;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleShow";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *ruleshows;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruleshowform_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleshows))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruleshowform_currentb failure");
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
ruleDisplayByLevel(p, Perl_leveli, Perl_rulei)
  SV *p;
  IV  Perl_leveli;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleDisplayByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *ruledisplays;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruledisplayform_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruledisplays, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruledisplayform_by_levelb failure");
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
symbolDisplayByLevel(p, Perl_leveli, Perl_symboli)
  SV *p;
  IV  Perl_leveli;
  IV  Perl_symboli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::symbolDisplayByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *symboldisplays;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_symboldisplayform_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_symboli, &symboldisplays, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_symboldisplayform_by_levelb failure");
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
ruleShowByLevel(p, Perl_leveli, Perl_rulei)
  SV *p;
  IV  Perl_leveli;
  IV  Perl_rulei;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::ruleShowByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *ruleshows;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_ruleshowform_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, (int) Perl_rulei, &ruleshows, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruleshowform_by_levelb failure");
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
show(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::show";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *shows;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammarshowform_currentb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &shows))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_ruleshowform_by_levelb failure");
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
showByLevel(p, Perl_leveli)
  SV *p;
  IV  Perl_leveli;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::showByLevel";
CODE:
  MarpaX_ESLIF_Grammar_t *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                   *shows;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFGrammar_grammarshowform_by_levelb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &shows, (int) Perl_leveli, NULL))) {
    MARPAESLIFPERL_CROAK("marpaESLIFGrammar_grammarshowform_by_levelb failure");
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
parse(p, Perl_recognizerInterfacep, Perl_valueInterfacep)
  SV *p;
  SV *Perl_recognizerInterfacep;
  SV *Perl_valueInterfacep;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Grammar::parse";
CODE:
  MarpaX_ESLIF_Grammar_t       *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  MarpaX_ESLIF_Recognizer_t     marpaESLIFRecognizerContext;
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  MarpaX_ESLIF_Value_t          marpaESLIFValueContext;
  bool                          rcb;
  SV                           *svp;

  marpaESLIFPerl_recognizerContextInitv(aTHX_ MarpaX_ESLIF_Grammarp, p, Perl_recognizerInterfacep, &marpaESLIFRecognizerContext, NULL, MarpaX_ESLIF_Grammarp->constantsp, MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp);
  marpaESLIFPerl_valueContextInitv(aTHX_ p, Perl_valueInterfacep, &marpaESLIFValueContext, MarpaX_ESLIF_Grammarp->constantsp, MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp);
  
  marpaESLIFRecognizerOption.userDatavp               = &marpaESLIFRecognizerContext;
  marpaESLIFRecognizerOption.readerCallbackp          = marpaESLIFPerl_readerCallbackb;
marpaESLIFRecognizerOption.disableThresholdb          = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithDisableThreshold", NULL /* subSvp */);
  marpaESLIFRecognizerOption.exhaustedb               = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithExhaustion", NULL /* subSvp */);
  marpaESLIFRecognizerOption.newlineb                 = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithNewline", NULL /* subSvp */);
  marpaESLIFRecognizerOption.trackb                   = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithTrack", NULL /* subSvp */);
  marpaESLIFRecognizerOption.bufsizl                  = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci          = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci              = 50; /* Recommended value */
  marpaESLIFRecognizerOption.ifActionResolverp        = marpaESLIFPerl_recognizerIfActionResolver;
  marpaESLIFRecognizerOption.eventActionResolverp     = marpaESLIFPerl_recognizerEventActionResolver;
  marpaESLIFRecognizerOption.regexActionResolverp     = marpaESLIFPerl_recognizerRegexActionResolver;
  marpaESLIFRecognizerOption.generatorActionResolverp = marpaESLIFPerl_recognizerGeneratorActionResolver;
  marpaESLIFRecognizerOption.importerp                = marpaESLIFPerl_recognizerImportb;
  
  marpaESLIFValueOption.userDatavp             = &marpaESLIFValueContext;
  marpaESLIFValueOption.ruleActionResolverp    = marpaESLIFPerl_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp  = marpaESLIFPerl_valueSymbolActionResolver;
  marpaESLIFValueOption.importerp              = marpaESLIFPerl_valueImportb;
  marpaESLIFValueOption.highRankOnlyb          = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithHighRankOnly", NULL /* subSvp */);
  marpaESLIFValueOption.orderByRankb           = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithOrderByRank", NULL /* subSvp */);
  marpaESLIFValueOption.ambiguousb             = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithAmbiguous", NULL /* subSvp */);
  marpaESLIFValueOption.nullb                  = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithNull", NULL /* subSvp */);
  marpaESLIFValueOption.maxParsesi             = (int) marpaESLIFPerl_call_methodi(aTHX_ Perl_valueInterfacep, "maxParses", NULL /* subSvp */);

  if (! marpaESLIFGrammar_parseb(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption, &marpaESLIFValueOption, NULL)) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp) != 1)) {
    MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(marpaESLIFValueContext.internalStackp));
  }
  svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(marpaESLIFValueContext.internalStackp);
  marpaESLIFPerl_call_methodv(aTHX_ Perl_valueInterfacep, "setResult", svp, marpaESLIFValueContext.setResultSvp);

  rcb = 1;
  goto done;

  err:
  rcb = 0;

  done:
  marpaESLIFPerl_valueContextFreev(aTHX_ &marpaESLIFValueContext, 1 /* onStackb */);
  marpaESLIFPerl_recognizerContextFreev(aTHX_ &marpaESLIFRecognizerContext, 1 /* onStackb */);
  RETVAL = rcb;
OUTPUT:
  RETVAL

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Symbol                                                   */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Symbol

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::string_allocate                                  */
  /* ----------------------------------------------------------------------- */
=cut

void *
string_allocate(Perl_packagep, p, bytep, bytel, encodingasciisp, modifiersp)
  SV     *Perl_packagep;
  SV     *p;
  char   *bytep;
  size_t  bytel;
  SV     *encodingasciisp;
  SV     *modifiersp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Symbol::string_allocate";
CODE:
  MarpaX_ESLIF_t             *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIF_t               *marpaESLIFp   = MarpaX_ESLIFp->marpaESLIFp;
  marpaESLIFSymbol_t         *marpaESLIFSymbolp;
  marpaESLIFString_t          marpaESLIFString;
  MarpaX_ESLIF_Symbol_t      *MarpaX_ESLIF_Symbolp;
  int                         typei;
  char                       *encodingasciis = NULL;
  char                       *modifiers = NULL;
  marpaESLIFSymbolOption_t    marpaESLIFSymbolOption;

  typei = marpaESLIFPerl_getTypei(aTHX_ encodingasciisp);
  if ((typei & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((typei & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("encoding must be a scalar or undef");
    }
  }
  if (SvOK(encodingasciisp)) {
    encodingasciis = SvPV_nolen(encodingasciisp);
  }

  typei = marpaESLIFPerl_getTypei(aTHX_ modifiersp);
  if ((typei & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((typei & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("modifiers must be a scalar or undef");
    }
  }
  if (SvOK(modifiersp)) {
    modifiers = SvPV_nolen(modifiersp);
  }

  Newx(MarpaX_ESLIF_Symbolp, 1, MarpaX_ESLIF_Symbol_t);
  marpaESLIFPerl_symbolContextInitv(aTHX_ MarpaX_ESLIFp, p, MarpaX_ESLIF_Symbolp, &(MarpaX_ESLIFp->constants));

  marpaESLIFString.bytep          = bytep;
  marpaESLIFString.bytel          = bytel;
  marpaESLIFString.encodingasciis = encodingasciis;
  marpaESLIFString.asciis         = NULL;

  marpaESLIFSymbolOption.userDatavp = (void *) MarpaX_ESLIF_Symbolp;
  marpaESLIFSymbolOption.importerp  = marpaESLIFPerl_symbolImportb;

  marpaESLIFSymbolp = marpaESLIFSymbol_string_newp(marpaESLIFp, &marpaESLIFString, modifiers, &marpaESLIFSymbolOption);
  if (MARPAESLIF_UNLIKELY(marpaESLIFSymbolp == NULL)) {
    marpaESLIFPerl_symbolContextFreev(aTHX_ MarpaX_ESLIF_Symbolp);
    MARPAESLIFPERL_CROAKF("marpaESLIFSymbol_string_newp failure, %s", strerror(errno));
  }
  MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp = marpaESLIFSymbolp;

  RETVAL = MarpaX_ESLIF_Symbolp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::regex_allocate                                   */
  /* ----------------------------------------------------------------------- */
=cut

void *
regex_allocate(Perl_packagep, p, bytep, bytel, encodingasciisp, modifiersp)
  SV     *Perl_packagep;
  SV     *p;
  char   *bytep;
  size_t  bytel;
  SV     *encodingasciisp;
  SV     *modifiersp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Symbol::regex_allocate";
CODE:
  MarpaX_ESLIF_t             *MarpaX_ESLIFp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIF_t               *marpaESLIFp   = MarpaX_ESLIFp->marpaESLIFp;
  marpaESLIFSymbol_t         *marpaESLIFSymbolp;
  marpaESLIFString_t          marpaESLIFString;
  MarpaX_ESLIF_Symbol_t      *MarpaX_ESLIF_Symbolp;
  int                         typei;
  char                       *encodingasciis = NULL;
  char                       *modifiers = NULL;
  marpaESLIFSymbolOption_t    marpaESLIFSymbolOption;

  typei = marpaESLIFPerl_getTypei(aTHX_ encodingasciisp);
  if ((typei & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((typei & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("encoding must be a scalar or undef");
    }
  }
  if (SvOK(encodingasciisp)) {
    encodingasciis = SvPV_nolen(encodingasciisp);
  }

  typei = marpaESLIFPerl_getTypei(aTHX_ modifiersp);
  if ((typei & SCALAR) != SCALAR) {
    /* This is an error unless it is undef */
    if ((typei & UNDEF) != UNDEF) {
      MARPAESLIFPERL_CROAK("modifiers must be a scalar or undef");
    }
  }
  if (SvOK(modifiersp)) {
    modifiers = SvPV_nolen(modifiersp);
  }

  Newx(MarpaX_ESLIF_Symbolp, 1, MarpaX_ESLIF_Symbol_t);
  marpaESLIFPerl_symbolContextInitv(aTHX_ MarpaX_ESLIFp, p, MarpaX_ESLIF_Symbolp, &(MarpaX_ESLIFp->constants));

  marpaESLIFString.bytep          = bytep;
  marpaESLIFString.bytel          = bytel;
  marpaESLIFString.encodingasciis = encodingasciis;
  marpaESLIFString.asciis         = NULL;

  marpaESLIFSymbolOption.userDatavp = (void *) MarpaX_ESLIF_Symbolp;
  marpaESLIFSymbolOption.importerp  = marpaESLIFPerl_symbolImportb;

  marpaESLIFSymbolp = marpaESLIFSymbol_regex_newp(marpaESLIFp, &marpaESLIFString, modifiers, &marpaESLIFSymbolOption);
  if (MARPAESLIF_UNLIKELY(marpaESLIFSymbolp == NULL)) {
    marpaESLIFPerl_symbolContextFreev(aTHX_ MarpaX_ESLIF_Symbolp);
    MARPAESLIFPERL_CROAKF("marpaESLIFSymbol_regex_newp failure, %s", strerror(errno));
  }
  MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp = marpaESLIFSymbolp;

  RETVAL = MarpaX_ESLIF_Symbolp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::meta_allocate                                    */
  /* ----------------------------------------------------------------------- */
=cut

void *
meta_allocate(Perl_packagep, p, g, symbolsp)
  SV     *Perl_packagep;
  SV     *p;
  SV     *g;
  SV     *symbolsp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Symbol::meta_allocate";
CODE:
  MarpaX_ESLIF_t             *MarpaX_ESLIFp         = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_Grammar_t     *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ g);
  marpaESLIF_t               *marpaESLIFp           = MarpaX_ESLIFp->marpaESLIFp;
  marpaESLIFGrammar_t        *marpaESLIFGrammarp    = MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp;
  marpaESLIFSymbol_t         *marpaESLIFSymbolp;
  MarpaX_ESLIF_Symbol_t      *MarpaX_ESLIF_Symbolp;
  int                         typei;
  char                       *symbols = NULL;
  marpaESLIFSymbolOption_t    marpaESLIFSymbolOption;

  typei = marpaESLIFPerl_getTypei(aTHX_ symbolsp);
  if ((typei & SCALAR) != SCALAR) {
    MARPAESLIFPERL_CROAK("symbol must be a scalar");
  }
  symbols = SvPV_nolen(symbolsp);

  Newx(MarpaX_ESLIF_Symbolp, 1, MarpaX_ESLIF_Symbol_t);
  marpaESLIFPerl_symbolContextInitv(aTHX_ MarpaX_ESLIFp, p, MarpaX_ESLIF_Symbolp, &(MarpaX_ESLIFp->constants));

  marpaESLIFSymbolOption.userDatavp = (void *) MarpaX_ESLIF_Symbolp;
  marpaESLIFSymbolOption.importerp  = marpaESLIFPerl_symbolImportb;

  marpaESLIFSymbolp = marpaESLIFSymbol_meta_newp(marpaESLIFp, marpaESLIFGrammarp, symbols, &marpaESLIFSymbolOption);
  if (MARPAESLIF_UNLIKELY(marpaESLIFSymbolp == NULL)) {
    marpaESLIFPerl_symbolContextFreev(aTHX_ MarpaX_ESLIF_Symbolp);
    MARPAESLIFPERL_CROAKF("marpaESLIFSymbol_meta_newp failure, %s", strerror(errno));
  }
  MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp = marpaESLIFSymbolp;

  RETVAL = MarpaX_ESLIF_Symbolp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::try                                              */
  /* ----------------------------------------------------------------------- */
=cut

SV *
try(p, Perl_inputp)
  SV *p;
  SV *Perl_inputp;
PREINIT:
  static const char     *funcs = "MarpaX::ESLIF::Symbol::try";
CODE:
  MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                  *inputs;
  size_t                 inputl;
  short                  matchb;
  int                    typei;

  typei = marpaESLIFPerl_getTypei(aTHX_ Perl_inputp);
  if ((typei & SCALAR) != SCALAR) {
    MARPAESLIFPERL_CROAK("input must be a scalar");
  }
  inputs = SvPV(Perl_inputp, inputl);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFSymbol_tryb(MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp, inputs, inputl, &matchb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIF_symbol_tryb failure, %s", strerror(errno));
  }

  if (matchb) {
    /* Take care, as per the doc it is using the symbol's importer */
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Symbolp->internalStackp) != 1)) {
      MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Symbolp->internalStackp));
    }
    RETVAL = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(MarpaX_ESLIF_Symbolp->internalStackp);
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::dispose                                          */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Symbol::dispose";
CODE:
  MarpaX_ESLIF_Symbol_t *MarpaX_ESLIF_Symbolp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  marpaESLIFPerl_symbolContextFreev(aTHX_ MarpaX_ESLIF_Symbolp);

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Recognizer

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::allocate                                     */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, p, Perl_recognizerInterfacep)
  SV *Perl_packagep;
  SV *p;
  SV *Perl_recognizerInterfacep;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::allocate";
CODE:
  MarpaX_ESLIF_Grammar_t       *MarpaX_ESLIF_Grammarp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  MarpaX_ESLIF_Recognizer_t    *MarpaX_ESLIF_Recognizerp;

  Newx(MarpaX_ESLIF_Recognizerp, 1, MarpaX_ESLIF_Recognizer_t);
  marpaESLIFPerl_recognizerContextInitv(aTHX_ MarpaX_ESLIF_Grammarp, p, Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizerp, NULL, MarpaX_ESLIF_Grammarp->constantsp, MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp);

  marpaESLIFRecognizerOption.userDatavp               = MarpaX_ESLIF_Recognizerp;
  marpaESLIFRecognizerOption.readerCallbackp          = marpaESLIFPerl_readerCallbackb;
  marpaESLIFRecognizerOption.disableThresholdb        = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithDisableThreshold", NULL /* subSvp */);
  marpaESLIFRecognizerOption.exhaustedb               = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithExhaustion", NULL /* subSvp */);
  marpaESLIFRecognizerOption.newlineb                 = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithNewline", NULL /* subSvp */);
  marpaESLIFRecognizerOption.trackb                   = marpaESLIFPerl_call_methodb(aTHX_ Perl_recognizerInterfacep, "isWithTrack", NULL /* subSvp */);
  marpaESLIFRecognizerOption.bufsizl                  = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci          = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci              = 50; /* Recommended value */
  marpaESLIFRecognizerOption.ifActionResolverp        = marpaESLIFPerl_recognizerIfActionResolver;
  marpaESLIFRecognizerOption.eventActionResolverp     = marpaESLIFPerl_recognizerEventActionResolver;
  marpaESLIFRecognizerOption.regexActionResolverp     = marpaESLIFPerl_recognizerRegexActionResolver;
  marpaESLIFRecognizerOption.generatorActionResolverp = marpaESLIFPerl_recognizerGeneratorActionResolver;
  marpaESLIFRecognizerOption.importerp                = marpaESLIFPerl_recognizerImportb;

  MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption);
  if (MARPAESLIF_UNLIKELY(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp == NULL)) {
    int save_errno = errno;
    marpaESLIFPerl_recognizerContextFreev(aTHX_ MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_newp failure, %s", strerror(errno));
  }

  RETVAL = MarpaX_ESLIF_Recognizerp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::allocate_newFrom                             */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate_newFrom(p1, p2)
  SV *p1;
  SV *p2;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::newFrom";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizer_origp = marpaESLIFPerl_Perl2enginep(aTHX_ p1);
  MarpaX_ESLIF_Grammar_t    *MarpaX_ESLIF_Grammarp         = marpaESLIFPerl_Perl2enginep(aTHX_ p2);
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp;

  Newx(MarpaX_ESLIF_Recognizerp, 1, MarpaX_ESLIF_Recognizer_t);
  marpaESLIFPerl_recognizerContextInitv(aTHX_ MarpaX_ESLIF_Grammarp, p2, MarpaX_ESLIF_Recognizer_origp->Perl_recognizerInterfacep, MarpaX_ESLIF_Recognizerp, p1, MarpaX_ESLIF_Grammarp->constantsp, MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp);

  MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp = marpaESLIFRecognizer_newFromp(MarpaX_ESLIF_Grammarp->marpaESLIFGrammarp, MarpaX_ESLIF_Recognizer_origp->marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp == NULL)) {
    int save_errno = errno;
    marpaESLIFPerl_recognizerContextFreev(aTHX_ MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_newp failure, %s", strerror(save_errno));
  }

  RETVAL = MarpaX_ESLIF_Recognizerp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::set_exhausted_flag                           */
  /* ----------------------------------------------------------------------- */
=cut

void
set_exhausted_flag(p, flag)
  SV   *p;
  bool  flag;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::set_exhausted_flag";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_set_exhausted_flagb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, flag ? 1 : 0))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_set_exhausted_flagb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::share                                        */
  /* ----------------------------------------------------------------------- */
=cut

void
share(p1, p2)
  SV *p1;
  SV *p2;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::share";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp       = marpaESLIFPerl_Perl2enginep(aTHX_ p1);

  if (SvTRUE(p2)) {
    MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_RecognizerOrigp = marpaESLIFPerl_Perl2enginep(aTHX_ p2);
    if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_shareb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, MarpaX_ESLIF_RecognizerOrigp->marpaESLIFRecognizerp))) {
      MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_shareb failure, %s", strerror(errno));
    }
  } else {
    if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_shareb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL))) {
      MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_shareb failure, %s", strerror(errno));
    }
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::unshare                                      */
  /* ----------------------------------------------------------------------- */
=cut

void
unshare(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::unshare";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_shareb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_shareb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::peek                                         */
  /* ----------------------------------------------------------------------- */
=cut

void
peek(p1, p2)
  SV *p1;
  SV *p2;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::peek";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp       = marpaESLIFPerl_Perl2enginep(aTHX_ p1);

  if (SvTRUE(p2)) {
    MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_RecognizerOrigp = marpaESLIFPerl_Perl2enginep(aTHX_ p2);
    if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_peekb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, MarpaX_ESLIF_RecognizerOrigp->marpaESLIFRecognizerp))) {
      MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_peekb failure, %s", strerror(errno));
    }
  } else {
    if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_peekb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL))) {
      MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_peekb failure, %s", strerror(errno));
    }
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::unpeek                                       */
  /* ----------------------------------------------------------------------- */
=cut

void
unpeek(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::unpeek";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_peekb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_peekb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::symbolTry                                    */
  /* ----------------------------------------------------------------------- */
=cut

SV *
symbolTry(p1, p2)
  SV *p1;
  SV *p2;
PREINIT:
  static const char           *funcs = "MarpaX::ESLIF::Recognizer::symbolTry";
CODE:
  MarpaX_ESLIF_Recognizer_t   *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p1);
  MarpaX_ESLIF_Symbol_t       *MarpaX_ESLIF_Symbolp     = marpaESLIFPerl_Perl2enginep(aTHX_ p2);
  short                        matchb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_symbol_tryb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, MarpaX_ESLIF_Symbolp->marpaESLIFSymbolp, &matchb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_symbol_tryb failure, %s", strerror(errno));
  }

  if (matchb) {
    /* Take care, as per the doc it is using the recognizer's importer */
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Recognizerp->internalStackp) != 1)) {
      MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Recognizerp->internalStackp));
    }
    RETVAL = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(MarpaX_ESLIF_Recognizerp->internalStackp);
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::dispose                                      */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::dispose";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  marpaESLIFPerl_recognizerContextFreev(aTHX_ MarpaX_ESLIF_Recognizerp, 0 /* onStackb */);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isCanContinue                                */
  /* ----------------------------------------------------------------------- */
=cut

bool
isCanContinue(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::isCanContinue";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      isCanContinueb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_isCanContinueb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &(isCanContinueb)))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_isCanContinueb failure, %s", strerror(errno));
  }
  RETVAL = (bool) isCanContinueb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isExhausted                                  */
  /* ----------------------------------------------------------------------- */
=cut

bool
isExhausted(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::isExhausted";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      exhaustedb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_isExhaustedb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &(exhaustedb)))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_isExhaustedb failure, %s", strerror(errno));
  }
  RETVAL = (bool) exhaustedb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::scan                                         */
  /* ----------------------------------------------------------------------- */
=cut

bool
scan(p, ...)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::scan";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      initialEventsb;

  if (items > 1) {
    SV *Perl_initialEvents = ST(1);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_initialEvents) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("First argument must be a scalar");
    }
    initialEventsb = SvIV(Perl_initialEvents) ? 1 : 0;
  } else {
    initialEventsb = 0;
  }

  RETVAL = (bool) marpaESLIFRecognizer_scanb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, initialEventsb, NULL /* continuebp */, NULL /* exhaustedbp */);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::resume                                       */
  /* ----------------------------------------------------------------------- */
=cut

bool
resume(p, ...)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::resume";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                        deltaLength;

  if (items > 1) {
    SV *Perl_deltaLength = ST(1);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_deltaLength) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("First argument must be a scalar");
    }
    deltaLength = (int) SvIV(Perl_deltaLength);
  } else {
    deltaLength = 0;
  }

  if (deltaLength < 0) {
    MARPAESLIFPERL_CROAK("Resume delta length cannot be negative");
  }
  RETVAL = (bool) marpaESLIFRecognizer_resumeb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, (size_t) deltaLength, NULL /* continuebp */, NULL /* exhaustedbp */);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::events                                       */
  /* ----------------------------------------------------------------------- */
=cut

SV *
events(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::events";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  AV                        *list;
  HV                        *hv;
  size_t                     i;
  size_t                     eventArrayl;
  marpaESLIFEvent_t         *eventArrayp;
  SV                        *svp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_eventb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &eventArrayl, &eventArrayp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_eventb failure, %s", strerror(errno));
  }

  list = newAV();
  for (i = 0; i < eventArrayl; i++) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "type", strlen("type"), newSViv(eventArrayp[i].type), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for type => %d", eventArrayp[i].type);
    }

    if (eventArrayp[i].symbols != NULL) {
      svp = newSVpv(eventArrayp[i].symbols, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].symbols, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = newSV(0);
    }
    if (MARPAESLIF_UNLIKELY(hv_store(hv, "symbol", strlen("symbol"), svp, 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for symbol => %s", (eventArrayp[i].symbols != NULL) ? eventArrayp[i].symbols : "");
    }

    if (eventArrayp[i].events != NULL) {
      svp = newSVpv(eventArrayp[i].events, 0);
      if (is_utf8_string((const U8 *) eventArrayp[i].events, 0)) {
        SvUTF8_on(svp);
      }
    } else {
      svp = newSV(0);
    }
    if (MARPAESLIF_UNLIKELY(hv_store(hv, "event",  strlen("event"),  svp, 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for event => %s", (eventArrayp[i].events != NULL) ? eventArrayp[i].events : "");
    }

    av_push(list, newRV((SV *)hv));
  }

  RETVAL = newRV_noinc((SV *)list);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::eventOnOff                                   */
  /* ----------------------------------------------------------------------- */
=cut

void
eventOnOff(p, symbol, eventTypes, onOff)
  SV   *p;
  char *symbol;
  AV   *eventTypes;
  bool  onOff;
PREINIT:
  static const char     *funcs     = "MarpaX::ESLIF::Recognizer::eventOnOff";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFEventType_t      eventSeti = MARPAESLIF_EVENTTYPE_NONE;
  SSize_t                    avsizel   = av_len(eventTypes) + 1;
  SSize_t                    aviteratorl;

  for (aviteratorl = 0; aviteratorl < avsizel; aviteratorl++) {
    int  codei;
    SV **svpp = av_fetch(eventTypes, aviteratorl, 0);
    if (MARPAESLIF_UNLIKELY(svpp == NULL)) {
      MARPAESLIFPERL_CROAK("av_fetch returned NULL");
    }
    if ((marpaESLIFPerl_getTypei(aTHX_ *svpp) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAKF("Element No %d of array must be a scalar", (int) aviteratorl);
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
      MARPAESLIFPERL_CROAKF("Unknown code %d", (int) codei);
      break;
    }
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_event_onoffb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, symbol, eventSeti, onOff ? 1 : 0))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_event_onoffb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::alternative                                  */
  /* ----------------------------------------------------------------------- */
=cut

bool
alternative(p, names, svp, ...)
  SV   *p;
  char *names;
  SV   *svp;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::alternative";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  marpaESLIFAlternative_t    marpaESLIFAlternative;
  int                        grammarLength;

  if (items > 3) {
    SV *Perl_grammarLength = ST(3);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_grammarLength) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("Third argument must be a scalar");
    }
    grammarLength = (int) SvIV(Perl_grammarLength);
  } else {
    grammarLength = 1;
  }

  if (grammarLength <= 0) {
    MARPAESLIFPERL_CROAK("grammarLength cannot be <= 0");
  }

  marpaESLIFAlternative.names          = (char *) names;
  marpaESLIFAlternative.grammarLengthl = (size_t) grammarLength;
  marpaESLIFPerl_stack_setv(aTHX_ marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp)), NULL /* marpaESLIFValuep */, -1 /* resulti */, svp, &(marpaESLIFAlternative.value), 1 /* incb */, MarpaX_ESLIF_Recognizerp->constantsp);

  RETVAL = (bool) marpaESLIFRecognizer_alternativeb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &marpaESLIFAlternative);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::alternativeComplete                          */
  /* ----------------------------------------------------------------------- */
=cut

bool
alternativeComplete(p, length)
  SV  *p;
  int  length;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::alternativeComplete";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (length < 0) {
    MARPAESLIFPERL_CROAK("Length cannot be < 0");
  }

  RETVAL = (bool) marpaESLIFRecognizer_alternative_completeb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, (size_t) length);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::alternativeRead                              */
  /* ----------------------------------------------------------------------- */
=cut

bool
alternativeRead(p, names, svp, length, ...)
  SV   *p;
  char *names;
  SV   *svp;
  int   length;
PREINIT:
  static const char       *funcs         = "MarpaX::ESLIF::Recognizer::alternativeRead";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  int                        grammarLength = 1;
  marpaESLIFAlternative_t    marpaESLIFAlternative;

  if (items > 4) {
    SV *Perl_grammarLength = ST(4);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_grammarLength) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("Fourth argument must be a scalar");
    }
    grammarLength = (int) SvIV(Perl_grammarLength);
  }

  if (grammarLength <= 0) {
    MARPAESLIFPERL_CROAK("grammarLength cannot be <= 0");
  }

  marpaESLIFAlternative.names          = (char *) names;
  marpaESLIFAlternative.grammarLengthl = (size_t) grammarLength;
  marpaESLIFPerl_stack_setv(aTHX_ marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp)), NULL /* marpaESLIFValuep */, -1 /* resulti */, svp, &(marpaESLIFAlternative.value), 1 /* incb */, MarpaX_ESLIF_Recognizerp->constantsp);

  RETVAL = (bool) marpaESLIFRecognizer_alternative_readb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &marpaESLIFAlternative, (size_t) length);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::nameTry                                      */
  /* ----------------------------------------------------------------------- */
=cut

bool
nameTry(p, name)
  SV   *p;
  char *name;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::nameTry";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      rcb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_name_tryb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, name, &rcb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_name_tryb failure, %s", strerror(errno));
  }
  RETVAL = (bool) rcb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::discard                                      */
  /* ----------------------------------------------------------------------- */
=cut

STRLEN
discard(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discard";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     discardl;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_discardb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &discardl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_discardb failure, %s", strerror(errno));
  }
  RETVAL = (STRLEN) discardl;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::discardTry                                   */
  /* ----------------------------------------------------------------------- */
=cut

bool
discardTry(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discardTry";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      rcb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_discard_tryb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &rcb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_discard_tryb failure, %s", strerror(errno));
  }
  RETVAL = (bool) rcb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::nameExpected                                 */
  /* ----------------------------------------------------------------------- */
=cut

SV *
nameExpected(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::nameExpected";
CODE:
  MarpaX_ESLIF_Recognizer_t  *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  AV                         *list;
  size_t                      nLexeme;
  size_t                      i;
  char                      **lexemesArrayp;
  SV                         *svp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_name_expectedb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &nLexeme, &lexemesArrayp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_name_expectedb failure, %s", strerror(errno));
  }

  list  = newAV();
  if (nLexeme > 0) {
    for (i = 0; i < nLexeme; i++) {
      if (lexemesArrayp[i] != NULL) {
        svp = newSVpv(lexemesArrayp[i], 0);
        if (is_utf8_string((const U8 *) lexemesArrayp[i], 0)) {
          SvUTF8_on(svp);
        }
      } else {
        svp = newSV(0);
      }
      av_push(list, svp);
    }
  }
  RETVAL = newRV_noinc((SV *)list);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::nameLastPause                                */
  /* ----------------------------------------------------------------------- */
=cut

SV *
nameLastPause(p, lexeme)
  SV   *p;
  char *lexeme;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::nameLastPause";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                      *pauses;
  size_t                     pausel;
  SV                         *svp;

  if (MARPAESLIF_UNLIKELY(!  marpaESLIFRecognizer_name_last_pauseb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, (char *) lexeme, &pauses, &pausel))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_name_last_pauseb failure, %s", strerror(errno));
  }
  if ((pauses != NULL) && (pausel > 0)) {
    svp = MARPAESLIFPERL_NEWSVPVN_UTF8(pauses, pausel);
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::nameLastTry                                  */
  /* ----------------------------------------------------------------------- */
=cut

SV *
nameLastTry(p, lexeme)
  SV   *p;
  char *lexeme;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::nameLastTry";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                      *trys;
  size_t                     tryl;
  SV                        *svp;

  if (MARPAESLIF_UNLIKELY(!  marpaESLIFRecognizer_name_last_tryb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, (char *) lexeme, &trys, &tryl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_name_last_tryb failure, %s", strerror(errno));
  }
  if ((trys != NULL) && (tryl > 0)) {
    svp = MARPAESLIFPERL_NEWSVPVN_UTF8(trys, tryl);
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
discardLastTry(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discardLastTry";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                      *discards;
  size_t                     discardl;
  SV                        *svp;

  if (MARPAESLIF_UNLIKELY(!  marpaESLIFRecognizer_discard_last_tryb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &discards, &discardl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_discard_last_tryb failure, %s", strerror(errno));
  }
  if ((discards != NULL) && (discardl > 0)) {
    svp = MARPAESLIFPERL_NEWSVPVN_UTF8(discards, discardl);
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::discardLast                                  */
  /* ----------------------------------------------------------------------- */
=cut

SV *
discardLast(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::discardLast";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                      *lasts;
  size_t                     lastl;
  SV                        *svp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_discard_lastb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &lasts, &lastl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_discard_lastb failure, %s", strerror(errno));
  }
  if ((lasts != NULL) && (lastl > 0)) {
    svp = MARPAESLIFPERL_NEWSVPVN_UTF8(lasts, lastl);
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
isEof(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::isEof";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      eofb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_isEofb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &eofb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_isEofb failure, %s", strerror(errno));
  }
  RETVAL = (bool) eofb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::isStartComplete                              */
  /* ----------------------------------------------------------------------- */
=cut

bool
isStartComplete(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::isStartComplete";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                      completeb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_isStartCompleteb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &completeb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_isStartCompleteb failure, %s", strerror(errno));
  }
  RETVAL = (bool) completeb;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::read                                         */
  /* ----------------------------------------------------------------------- */
=cut

bool
read(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::read";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  RETVAL = (bool) marpaESLIFRecognizer_readb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL, NULL);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::input                                        */
  /* ----------------------------------------------------------------------- */
=cut

SV *
input(p, ...)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::input";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  SV                        *Perl_offset;
  int                        offset;
  SV                        *Perl_length;
  int                        length;
  char                      *inputs;
  size_t                     inputl;
  char                      *realinputs;
  size_t                     realinputl;
  size_t                     deltal;
  char                      *maxinputs;
  SV                        *svp;

  /* Note that perl guarantees that items is >= 1 */
  if (items == 1) {
    offset = 0;
    length = 0;
  } else if (items == 2) {
    Perl_offset = ST(1);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_offset) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("Offset argument must be a scalar");
    }
    offset = (int) SvIV(Perl_offset);
    length = 0;
  } else if (items >= 3) {
    Perl_offset = ST(1);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_offset) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("Offset argument must be a scalar");
    }
    offset = (int) SvIV(Perl_offset);

    Perl_length = ST(2);
    if ((marpaESLIFPerl_getTypei(aTHX_ Perl_length) & SCALAR) != SCALAR) {
      MARPAESLIFPERL_CROAK("Length argument must be a scalar");
    }
    length = (int) SvIV(Perl_length);
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_inputb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &inputs, &inputl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_inputb failure, %s", strerror(errno));
  }

  /* inputs is a direct pointer to memory */
  if ((inputs != NULL) && (inputl > 0)) {
    maxinputs = inputs + inputl - 1;
    /* Apply offset parameter */
    realinputs = inputs;
    if (offset < 0) {
      realinputs += inputl;
    }
    realinputs += offset;
    if ((realinputs < inputs) || (realinputs > maxinputs)) {
      if (MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp->Perl_loggerInterfacep != NULL) {
        marpaESLIFPerl_genericLoggerCallbackv(MarpaX_ESLIF_Recognizerp->MarpaX_ESLIFp, GENERICLOGGER_LOGLEVEL_WARNING, "input() goes beyond either end of input buffer");
      }
      svp = &PL_sv_undef;
    } else {
      /* Adapt input length to the modified start offset */
      if (realinputs > inputs) {
        deltal = realinputs - inputs;
        inputl -= deltal;
      }
      /* Apply length parameter */
      if (length == 0) {
        realinputl = inputl; /* All bytes available */
      } else if (length > 0) {
        if (length < inputl) {
          realinputl = length; /* Remains more bytes than what the user want */
        } else {
          realinputl = inputl; /* Remains less bytes than what the user want */
        }
      } else {
        length = -length;
        if (length < inputl) {
          deltal = inputl - length; 
          realinputl = deltal; /* Skip length last bytes */
        } else {
          realinputl = 0; /* Skipping more bytes that what is available */
        }
      }
      svp = marpaESLIFPerl_arraycopyp(aTHX_ realinputs, realinputl, 0 /* arraycopyb */);
    }
  } else {
    svp = &PL_sv_undef;
  }
  RETVAL = svp;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::inputLength                                  */
  /* ----------------------------------------------------------------------- */
=cut

STRLEN
inputLength(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::inputLength";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     inputl;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_inputb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL, &inputl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_inputb failure, %s", strerror(errno));
  }
  RETVAL = (STRLEN) inputl;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::error                                        */
  /* ----------------------------------------------------------------------- */
=cut

void
error(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::error";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_errorb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_errorb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::progressLog                                  */
  /* ----------------------------------------------------------------------- */
=cut

void
progressLog(p, start, end, level)
  SV  *p;
  int  start;
  int  end;
  int  level;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::progressLog";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

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
    MARPAESLIFPERL_CROAKF("Unknown logger level %d", (int) level);
    break;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_progressLogb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, (int) start, (int) end, (int) level))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_progressLogb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::progress                                     */
  /* ----------------------------------------------------------------------- */
=cut

SV *
progress(p, start, end)
  SV  *p;
  int  start;
  int  end;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::progress";
CODE:
  MarpaX_ESLIF_Recognizer_t      *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                          progressl;
  marpaESLIFRecognizerProgress_t *progressp;
  size_t                          i;
  AV                             *list;
  HV                             *hv;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_progressb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, start, end, &progressl, &progressp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_progressb failure, %s", strerror(errno));
  }

  /* We return an array of hashes */
  list = newAV();
  for (i = 0; i < progressl; i++) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "earleySetId", strlen("earleySetId"), newSViv(progressp[i].earleySetIdi), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for earleySetId => %d", progressp[i].earleySetIdi);
    }

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "earleySetOrigId", strlen("earleySetOrigId"), newSViv(progressp[i].earleySetOrigIdi), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for earleySetOrigId => %d", progressp[i].earleySetOrigIdi);
    }

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "rule", strlen("rule"), newSViv(progressp[i].rulei), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for rule => %d", progressp[i].rulei);
    }

    if (MARPAESLIF_UNLIKELY(hv_store(hv, "position", strlen("position"), newSViv(progressp[i].positioni), 0) == NULL)) {
      MARPAESLIFPERL_CROAKF("hv_store failure for position => %d", progressp[i].positioni);
    }

    av_push(list, newRV((SV *)hv));
  }

  RETVAL = newRV_noinc((SV *)list);
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lastCompletedLength                          */
  /* ----------------------------------------------------------------------- */
=cut

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::lastCompletedOffset                          */
  /* ----------------------------------------------------------------------- */
=cut

IV
lastCompletedOffset(p, name)
  SV   *p;
  char *name;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedOffset";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  char                      *offsetp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_last_completedb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, name, &offsetp, NULL /* lengthlp */))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
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
lastCompletedLength(p, name)
  SV   *p;
  char *name;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedLength";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     lengthl;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_last_completedb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, name, NULL /* offsetpp */, &lengthl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
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
lastCompletedLocation(p, name)
  SV   *p;
  char *name;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::lastCompletedLocation";
PPCODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     lengthl;
  char                      *offsetp;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_last_completedb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, name, &offsetp, &lengthl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
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
line(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::line";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     linel;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_locationb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &linel, NULL /* columnlp */))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
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
column(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::column";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     columnl;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_locationb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, NULL /* linelp */, &columnl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
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
location(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::location";
PPCODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  size_t                     linel;
  size_t                     columnl;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_locationb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &linel, &columnl))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
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
hookDiscard(p, discardOnOffb)
  SV    *p;
  short  discardOnOffb;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::hookDiscard";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_hook_discardb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, discardOnOffb))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_hook_discardb failure, %s", strerror(errno));
  }

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Recognizer::hookDiscardSwitch                            */
  /* ----------------------------------------------------------------------- */
=cut

void
hookDiscardSwitch(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Recognizer::hookDiscardSwitch";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_hook_discard_switchb(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp))) {
    MARPAESLIFPERL_CROAKF("marpaESLIFRecognizer_hook_discard_switchb failure, %s", strerror(errno));
  }

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Value

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::allocate                                          */
  /* ----------------------------------------------------------------------- */
=cut

void *
allocate(Perl_packagep, p, Perl_valueInterfacep)
  SV *Perl_packagep;
  SV *p;
  SV *Perl_valueInterfacep;
PREINIT:
  static const char        *funcs = "MarpaX::ESLIF::Value::allocate";
CODE:
  MarpaX_ESLIF_Recognizer_t *MarpaX_ESLIF_Recognizerp = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  MarpaX_ESLIF_Value_t      *MarpaX_ESLIF_Valuep;
  marpaESLIFValueOption_t    marpaESLIFValueOption;

  Newx(MarpaX_ESLIF_Valuep, 1, MarpaX_ESLIF_Value_t);
  marpaESLIFPerl_valueContextInitv(aTHX_ MarpaX_ESLIF_Recognizerp->Perl_MarpaX_ESLIF_Grammarp, Perl_valueInterfacep, MarpaX_ESLIF_Valuep, MarpaX_ESLIF_Recognizerp->constantsp, MarpaX_ESLIF_Recognizerp->MarpaX_ESLIF_Grammarp->MarpaX_ESLIFp);

  marpaESLIFValueOption.userDatavp            = MarpaX_ESLIF_Valuep;
  marpaESLIFValueOption.ruleActionResolverp   = marpaESLIFPerl_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp = marpaESLIFPerl_valueSymbolActionResolver;
  marpaESLIFValueOption.importerp             = marpaESLIFPerl_valueImportb;
  marpaESLIFValueOption.highRankOnlyb         = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithHighRankOnly", NULL /* subSvp */);
  marpaESLIFValueOption.orderByRankb          = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithOrderByRank", NULL /* subSvp */);
  marpaESLIFValueOption.ambiguousb            = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithAmbiguous", NULL /* subSvp */);
  marpaESLIFValueOption.nullb                 = marpaESLIFPerl_call_methodb(aTHX_ Perl_valueInterfacep, "isWithNull", NULL /* subSvp */);
  marpaESLIFValueOption.maxParsesi            = (int) marpaESLIFPerl_call_methodi(aTHX_ Perl_valueInterfacep, "maxParses", NULL /* subSvp */);

  MarpaX_ESLIF_Valuep->marpaESLIFValuep = marpaESLIFValue_newp(MarpaX_ESLIF_Recognizerp->marpaESLIFRecognizerp, &marpaESLIFValueOption);
  if (MARPAESLIF_UNLIKELY(MarpaX_ESLIF_Valuep->marpaESLIFValuep == NULL)) {
    int save_errno = errno;
    marpaESLIFPerl_valueContextFreev(aTHX_ MarpaX_ESLIF_Valuep, 0 /* onStackb */);
    MARPAESLIFPERL_CROAKF("marpaESLIFValue_newp failure, %s", strerror(save_errno));
  }

  RETVAL = MarpaX_ESLIF_Valuep;
OUTPUT:
  RETVAL

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::dispose                                           */
  /* ----------------------------------------------------------------------- */
=cut

void
dispose(p)
  SV *p;
PREINIT:
  static const char  *funcs = "MarpaX::ESLIF::Value::dispose";
CODE:
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = marpaESLIFPerl_Perl2enginep(aTHX_ p);

  marpaESLIFPerl_valueContextFreev(aTHX_ MarpaX_ESLIF_Valuep, 0 /* onStackb */);

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Value::value                                             */
  /* ----------------------------------------------------------------------- */
=cut

bool
value(p)
  SV *p;
PREINIT:
  static const char *funcs = "MarpaX::ESLIF::Value::value";
CODE:
  MarpaX_ESLIF_Value_t *MarpaX_ESLIF_Valuep = marpaESLIFPerl_Perl2enginep(aTHX_ p);
  short                 valueb;
  SV                    *svp;

  valueb = marpaESLIFValue_valueb(MarpaX_ESLIF_Valuep->marpaESLIFValuep);
  if (valueb < 0) {
    MARPAESLIFPERL_CROAKF("marpaESLIFValue_valueb failure, %s", strerror(errno));
  }
  if (valueb > 0) {
    if (MARPAESLIF_UNLIKELY(marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Valuep->internalStackp) != 1)) {
      MARPAESLIFPERL_CROAKF("Internal value stack is %d instead of 1", marpaESLIFPerl_GENERICSTACK_USED(MarpaX_ESLIF_Valuep->internalStackp));
    }
    svp = (SV *) marpaESLIFPerl_GENERICSTACK_POP_PTR(MarpaX_ESLIF_Valuep->internalStackp);
    marpaESLIFPerl_call_methodv(aTHX_ MarpaX_ESLIF_Valuep->Perl_valueInterfacep, "setResult", svp, MarpaX_ESLIF_Valuep->setResultSvp);
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
  /* MarpaX::ESLIF::Symbol::EventBitSet                                      */
  /* ======================================================================= */
=cut

MODULE = MarpaX::ESLIF            PACKAGE = MarpaX::ESLIF::Symbol::EventBitSet

PROTOTYPES: ENABLE

=for comment
  /* ----------------------------------------------------------------------- */
  /* MarpaX::ESLIF::Symbol::EventBitSet::constant                            */
  /* ----------------------------------------------------------------------- */
=cut

INCLUDE: xs-symbolEventBitSet-types.inc

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

=for comment
  /* ======================================================================= */
  /* MarpaX::ESLIF::Grammar::Symbol                                          */
  /* ======================================================================= */
=cut

INCLUDE: xs-symbol-types.inc
