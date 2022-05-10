#include <locale.h>
#include <stdlib.h>
#include "json_encode_extended_grammar.c"
#include "json_decode_extended_grammar.c"
#include "json_encode_strict_grammar.c"
#include "json_decode_strict_grammar.c"

#undef  FILENAMES
#define FILENAMES "json.c" /* For logging */

typedef struct marpaESLIFJSONDecodeDepositCallbackContext marpaESLIFJSONDecodeDepositCallbackContext_t;
typedef struct marpaESLIFJSONDecodeDeposit                marpaESLIFJSONDecodeDeposit_t;
typedef struct marpaESLIFJSONDecodeContext                marpaESLIFJSONDecodeContext_t;
typedef short (*marpaESLIFJSONDecodeDepositCallback_t)(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *contextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp);
typedef struct marpaESLIFJSONEncodeContext                marpaESLIFJSONEncodeContext_t;

#define MARPAESLIFJSON_ARRAYL_IN_STRUCTURE 128
#define MARPAESLIFJSON_STRINGALLOCL_DEFAULT_VALUE 128
struct marpaESLIFJSONDecodeContext {
  marpaESLIF_t                      *marpaESLIFp;
  marpaESLIFJSONDecodeOption_t      *marpaESLIFJSONDecodeOptionp;
  marpaESLIFRecognizerOption_t      *marpaESLIFRecognizerOptionp;
  marpaESLIFValueOption_t           *marpaESLIFValueOptionp;
  marpaESLIFReaderDispose_t          readerDisposep;
  marpaESLIFRepresentationDispose_t  representationDisposep;
  marpaESLIF_uint32_t               *uint32p;
  genericStack_t                   _depositStack;
  genericStack_t                   *depositStackp;
  size_t                             currentDepthl;
  size_t                             numberallocl; /* Used when we analyse a number */
  size_t                             stringallocl; /* Used when we iterate within string */
  size_t                             uint32allocl; /* Used when we iterate within string and compute series of \\uXXXX */
  marpaESLIFValueResult_t            currentValue; /* Temporary work area - UNDEF at beginning, always reset to UNDEF when commited */
  marpaESLIF_uint32_t               _uint32p[MARPAESLIFJSON_ARRAYL_IN_STRUCTURE + 1]; /* Ditto */
  marpaESLIFValueResult_t            import;
};

struct marpaESLIFJSONEncodeContext {
  marpaESLIFValueOption_t           *marpaESLIFValueOptionp;
  marpaESLIFRepresentationDispose_t  representationDisposep;
};

struct marpaESLIFJSONDecodeDepositCallbackContext {
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp;
  short                          keyb; /* MUST BE INITIALIZED to 1 (case when destination is a table) */
  size_t                         allocl;
};
  
struct marpaESLIFJSONDecodeDeposit {
  marpaESLIFValueResult_t                      *dstp;
  marpaESLIFJSONDecodeDepositCallbackContext_t *contextp;
  marpaESLIFJSONDecodeDepositCallback_t         actionp;
};

static const char MARPAESLIFJSON_DQUOTE          = '"';
static const char MARPAESLIFJSON_BACKSLASH       = '\\';
static const char MARPAESLIFJSON_SLASH           = '/';
static const char MARPAESLIFJSON_BACKSPACE       = '\x08';
static const char MARPAESLIFJSON_FORMFEED        = '\x0C';
static const char MARPAESLIFJSON_LINEFEED        = '\x0A';
static const char MARPAESLIFJSON_CARRIAGE_RETURN = '\x0D';
static const char MARPAESLIFJSON_HORIZONTAL_TAB  = '\x09';

/* For the \uXXXX case in string */
#define MARPAESLIFJSON_DST_OR_VALCHAR(marpaESLIFJSONDecodeContextp, dst, valchar) do { \
    unsigned char _valchar = (unsigned char) (valchar);                 \
    switch (_valchar) {                                                 \
    case '0':                                                           \
      dst |= 0x00;                                                      \
      break;                                                            \
    case '1':                                                           \
      dst |= 0x01;                                                      \
      break;                                                            \
    case '2':                                                           \
      dst |= 0x02;                                                      \
      break;                                                            \
    case '3':                                                           \
      dst |= 0x03;                                                      \
      break;                                                            \
    case '4':                                                           \
      dst |= 0x04;                                                      \
      break;                                                            \
    case '5':                                                           \
      dst |= 0x05;                                                      \
      break;                                                            \
    case '6':                                                           \
      dst |= 0x06;                                                      \
      break;                                                            \
    case '7':                                                           \
      dst |= 0x07;                                                      \
      break;                                                            \
    case '8':                                                           \
      dst |= 0x08;                                                      \
      break;                                                            \
    case '9':                                                           \
      dst |= 0x09;                                                      \
      break;                                                            \
    case 'a':                                                           \
    case 'A':                                                           \
      dst |= 0x0A;                                                      \
      break;                                                            \
    case 'b':                                                           \
    case 'B':                                                           \
      dst |= 0x0B;                                                      \
      break;                                                            \
    case 'c':                                                           \
    case 'C':                                                           \
      dst |= 0x0C;                                                      \
      break;                                                            \
    case 'd':                                                           \
    case 'D':                                                           \
      dst |= 0x0D;                                                      \
      break;                                                            \
    case 'e':                                                           \
    case 'E':                                                           \
      dst |= 0x0E;                                                      \
      break;                                                            \
    case 'f':                                                           \
    case 'F':                                                           \
      dst |= 0x0F;                                                      \
      break;                                                            \
    default:                                                            \
      MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Unsupported hexadecimal character '%c' (0x%lx)", _valchar, (unsigned long) _valchar); \
      goto err;                                                         \
    }                                                                   \
  } while (0)

static void                                 _marpaESLIFJSONReaderDisposev(void *userDatavp, char *inputcp, size_t inputl, short eofb, short characterStreamb, char *encodings, size_t encodingl);
static short                                _marpaESLIFJSONDecodeReaderb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp, marpaESLIFReaderDispose_t *disposeCallbackpp);

/* Decoder specific actions */
static marpaESLIFRecognizerRegexCallback_t  _marpaESLIFJSONDecodeRegexActionResolverp(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static short                                _marpaESLIFJSONDecodeRegexCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static inline short                         _marpaESLIFJSONDecodeIncb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static inline short                         _marpaESLIFJSONDecodeDecb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static inline short                         _marpaESLIFJSONDecodeSetPositiveInfinityb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeSetNegativeInfinityb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeSetPositiveNanb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeSetNegativeNanb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeSetNumberb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, size_t incl);
static inline short                         _marpaESLIFJSONDecodeAppendCharb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONProposalAction_t proposalp, char *inputs, size_t inputl, marpaESLIFValueResult_t *currentValuep, short confidenceb);
static inline short                         _marpaESLIFJSONDecodeSetConstantb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl);
static inline short                         _marpaESLIFJSONDecodeDepositStackPushb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp);
static inline short                         _marpaESLIFJSONDecodeDepositStackGetLastb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp);
static inline short                         _marpaESLIFJSONDecodeDepositStackPopb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp);
static short                                _marpaESLIFJSONDecodeSetValueCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp);
static short                                _marpaESLIFJSONDecodePushRowCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp);
static short                                _marpaESLIFJSONDecodeSetHashCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp);
static inline short                         _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFValueResult_t *marpaESLIFValueresultp);
static short                                _marpaESLIFJSONDecodeValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb);
static short                                _marpaESLIFJSONDecodeValueResultInternalImportb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb);
static short                                _marpaESLIFJSONDecodeRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp);
static void                                 _marpaESLIFJSONDecodeRepresentationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis);
static inline short                          _marpaESLIFJSONDecodeDepositInitb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *depositp, marpaESLIFJSONDecodeDepositCallback_t actionp);
static inline void                          _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *depositp);
static short                                _marpaESLIFJSONEncodeValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb);
static short                                _marpaESLIFJSONEncodeRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp);
static void                                 _marpaESLIFJSONEncodeRepresentationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis);
static inline short                         _marpaESLIFJSONDecodeObjectOpeningb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static inline short                         _marpaESLIFJSONDecodeObjectClosingb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static inline short                         _marpaESLIFJSONDecodeArrayOpeningb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static inline short                         _marpaESLIFJSONDecodeArrayClosingb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp);
static        short                         _marpaESLIFJSONDecodeSymbolImportProxyb(marpaESLIFSymbol_t *marpaESLIFSymbolp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb);

/*****************************************************************************/
static inline marpaESLIFGrammar_t *_marpaESLIFJSON_decode_newp(marpaESLIF_t *marpaESLIFp, short strictb)
/*****************************************************************************/
{
  marpaESLIFGrammar_t       *marpaESLIFJSONp             = NULL;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;

  if (MARPAESLIF_UNLIKELY(marpaESLIFp == NULL)) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFGrammarOption.bytep     = strictb ? (char *) marpaESLIFJSON_decode_strict_grammars : (char *) marpaESLIFJSON_decode_extended_grammars;
  marpaESLIFGrammarOption.bytel     = strlen((const char *) marpaESLIFGrammarOption.bytep);
  marpaESLIFGrammarOption.encodings = "ASCII";
  marpaESLIFGrammarOption.encodingl = 5; /* strlen("ASCII") */

  marpaESLIFJSONp = _marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption, NULL /* L */, 0 /* bootstrapb */, 0 /* rememberGrammarUtf8b */, NULL /* forcedStartSymbols */, -1 /* forcedStartSymbolLeveli */, NULL /* marpaESLIFGrammar_bootstrapp */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFJSONp == NULL)) {
    goto err;
  }

  /* Fill shallow pointers what what is precomputed in marpaESLIF */
  if (strictb) {
    marpaESLIFJSONp->jsonStringp             = marpaESLIFp->jsonStringpp[MARPAESLIF_JSON_TYPE_STRICT];
    marpaESLIFJSONp->jsonConstantOrNumberp   = marpaESLIFp->jsonConstantOrNumberpp[MARPAESLIF_JSON_TYPE_STRICT];
  } else {
    marpaESLIFJSONp->jsonStringp             = marpaESLIFp->jsonStringpp[MARPAESLIF_JSON_TYPE_EXTENDED];
    marpaESLIFJSONp->jsonConstantOrNumberp   = marpaESLIFp->jsonConstantOrNumberpp[MARPAESLIF_JSON_TYPE_EXTENDED];
  }
  goto done;

 err:
  marpaESLIFGrammar_freev(marpaESLIFJSONp);
  marpaESLIFJSONp = NULL;

 done:
  return marpaESLIFJSONp;
}

/*****************************************************************************/
static inline marpaESLIFGrammar_t *_marpaESLIFJSON_encode_newp(marpaESLIF_t *marpaESLIFp, short strictb)
/*****************************************************************************/
{
  marpaESLIFGrammar_t       *marpaESLIFJSONp             = NULL;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;

  if (MARPAESLIF_UNLIKELY(marpaESLIFp == NULL)) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFGrammarOption.bytep     = strictb ? (char *) marpaESLIFJSON_encode_strict_grammars : (char *) marpaESLIFJSON_encode_extended_grammars;
  marpaESLIFGrammarOption.bytel     = strlen((const char *) marpaESLIFGrammarOption.bytep);
  marpaESLIFGrammarOption.encodings = "ASCII";
  marpaESLIFGrammarOption.encodingl = 5; /* strlen("ASCII") */

  marpaESLIFJSONp = _marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption, NULL /* L */, 0 /* bootstrapb */, 0 /* rememberGrammarUtf8b */, NULL /* forcedStartSymbols */, -1 /* forcedStartSymbolLeveli */, NULL /* marpaESLIFGrammar_bootstrapp */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFJSONp == NULL)) {
    goto err;
  }

  goto done;

 err:
  marpaESLIFGrammar_freev(marpaESLIFJSONp);
  marpaESLIFJSONp = NULL;

 done:
  return marpaESLIFJSONp;
}

/*****************************************************************************/
short marpaESLIFJSON_encodeb(marpaESLIFGrammar_t *marpaESLIFGrammarJSONp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueOption_t *marpaESLIFValueOptionp)
/*****************************************************************************/
/* Strict or not, encode grammar is always at level 10                       */
/*****************************************************************************/
{
  marpaESLIFRecognizer_t        *marpaESLIFRecognizerp = NULL;
  marpaESLIFValue_t             *marpaESLIFValuep      = NULL;
  short                          rcb;
  marpaESLIFAlternative_t        marpaESLIFAlternative;
  marpaESLIFValueOption_t        marpaESLIFValueOption;
  marpaESLIFJSONEncodeContext_t  marpaESLIFJSONEncodeContext;

  marpaESLIFJSONEncodeContext.marpaESLIFValueOptionp = marpaESLIFValueOptionp;
  marpaESLIFJSONEncodeContext.representationDisposep = NULL;

  if (MARPAESLIF_UNLIKELY((marpaESLIFGrammarJSONp == NULL) || (marpaESLIFValueResultp == NULL) || (marpaESLIFValueOptionp == NULL))) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFValueOption                           = *marpaESLIFValueOptionp;
  marpaESLIFValueOption.userDatavp                = &marpaESLIFJSONEncodeContext;
  marpaESLIFValueOption.ruleActionResolverp       = NULL; /* Not used */
  marpaESLIFValueOption.symbolActionResolverp     = NULL; /* We use the native ::transfer action */
  marpaESLIFValueOption.importerp                 = ((marpaESLIFValueOptionp != NULL) && (marpaESLIFValueOptionp->importerp != NULL)) ? _marpaESLIFJSONEncodeValueResultImportb : NULL;
  marpaESLIFValueOption.highRankOnlyb             = 1; /* Fixed */
  marpaESLIFValueOption.orderByRankb              = 1; /* Fixed */
  marpaESLIFValueOption.ambiguousb                = 0; /* Fixed */
  marpaESLIFValueOption.nullb                     = 0; /* Fixed */
  marpaESLIFValueOption.maxParsesi                = 0; /* Fixed */

  marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(marpaESLIFGrammarJSONp, NULL);
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp == NULL)) {
    goto err;
  }

  /* Insert a lexeme with length 0 in the input, though length 1 in the grammar */
  marpaESLIFAlternative.names          = "INPUT";
  marpaESLIFAlternative.value          = *marpaESLIFValueResultp;
  marpaESLIFAlternative.grammarLengthl = 1;
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 0 /* lengthl */))) {
    goto err;
  }

  marpaESLIFValuep = _marpaESLIFValue_newp(marpaESLIFRecognizerp, &marpaESLIFValueOption, 0 /* silentb */, 0 /* fakeb */, 0 /* directTransferb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFValuep == NULL)) {
    goto err;
  }

  /* Set-up proxy representation */
  marpaESLIFValuep->proxyRepresentationp = _marpaESLIFJSONEncodeRepresentationb;

  if (MARPAESLIF_UNLIKELY(! marpaESLIFValue_valueb(marpaESLIFValuep))) {
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (marpaESLIFValuep != NULL) {
    marpaESLIFValue_freev(marpaESLIFValuep);
  }
  if (marpaESLIFRecognizerp != NULL) {
    marpaESLIFRecognizer_freev(marpaESLIFRecognizerp);
  }
  return rcb;
}

/*****************************************************************************/
short marpaESLIFJSON_decodeb(marpaESLIFGrammar_t *marpaESLIFGrammarJSONp, marpaESLIFJSONDecodeOption_t *marpaESLIFJSONDecodeOptionp, marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp, marpaESLIFValueOption_t *marpaESLIFValueOptionp)
/*****************************************************************************/
{
  static const char                            *funcs                 = "marpaESLIFJSON_decodeb";
  marpaESLIFValue_t                            *marpaESLIFValuep      = NULL;
  marpaESLIFRecognizer_t                       *marpaESLIFRecognizerp = NULL;
  short                                         continueb             = 1;
  char                                         *inputs;
  size_t                                        inputl                = 0;
  marpaESLIFSymbol_t                            jsonString;
  marpaESLIFSymbol_t                            jsonConstantOrNumber;
  marpaESLIFRecognizerOption_t                  marpaESLIFRecognizerOption;
  marpaESLIFValueOption_t                       marpaESLIFValueOption;
  marpaESLIFJSONDecodeContext_t                 marpaESLIFJSONDecodeContext;
  marpaESLIFJSONDecodeDeposit_t                 marpaESLIFJSONDecodeDeposit;
  marpaESLIFJSONDecodeDepositCallbackContext_t  marpaESLIFJSONDecodeDepositCallbackContext;
  short                                         isEofb;
  short                                         isStartCompleteb;
  marpaESLIFValueResult_t                      *finalValuep; /* Shallow pointer - c.f. dispose of memory at the end */
  marpaESLIFAlternative_t                       marpaESLIFAlternative;
  short                                         matchb;
  size_t                                        discardl;
  int                                           depositStackpUsedi;
  short                                         rcb;

  /* This is vicious but we do not want to recompute the symbols. Since we are internal */
  /* we just get symbol content and overwrite the symbol option importer to our proxy.  */
  jsonString = *(marpaESLIFGrammarJSONp->jsonStringp);
  jsonConstantOrNumber = *(marpaESLIFGrammarJSONp->jsonConstantOrNumberp);

  /* Whatever happens, we take entire control on the callbacks so that we have our own context on top of it */
  marpaESLIFJSONDecodeContext.marpaESLIFp                 = marpaESLIFGrammarJSONp->marpaESLIFp;
  marpaESLIFJSONDecodeContext.marpaESLIFJSONDecodeOptionp = marpaESLIFJSONDecodeOptionp;
  marpaESLIFJSONDecodeContext.marpaESLIFRecognizerOptionp = marpaESLIFRecognizerOptionp;
  marpaESLIFJSONDecodeContext.marpaESLIFValueOptionp      = marpaESLIFValueOptionp;
  marpaESLIFJSONDecodeContext.readerDisposep              = NULL;
  marpaESLIFJSONDecodeContext.representationDisposep      = NULL;
  marpaESLIFJSONDecodeContext.uint32p                     = NULL;
  marpaESLIFJSONDecodeContext.depositStackp               = &(marpaESLIFJSONDecodeContext._depositStack);
  marpaESLIFJSONDecodeContext.currentDepthl               = 0;
  marpaESLIFJSONDecodeContext.numberallocl                = 0;
  marpaESLIFJSONDecodeContext.stringallocl                = 0;
  marpaESLIFJSONDecodeContext.uint32allocl                = 0;
  marpaESLIFJSONDecodeContext.currentValue                = marpaESLIFValueResultUndef;

  GENERICSTACK_INIT(marpaESLIFJSONDecodeContext.depositStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFJSONDecodeContext.depositStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFGrammarJSONp->marpaESLIFp, "depositStackp initialization failure, %s", strerror(errno));
    marpaESLIFJSONDecodeContext.depositStackp = NULL;
    goto err;
  }

  if (MARPAESLIF_UNLIKELY((marpaESLIFGrammarJSONp                       == NULL) ||
                          (marpaESLIFJSONDecodeOptionp                  == NULL) ||
                          (marpaESLIFRecognizerOptionp                  == NULL) ||
                          (marpaESLIFRecognizerOptionp->readerCallbackp == NULL) ||
                          (marpaESLIFValueOptionp                       == NULL))) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFRecognizerOption                      = *marpaESLIFRecognizerOptionp;
  marpaESLIFRecognizerOption.userDatavp           = &marpaESLIFJSONDecodeContext;
  marpaESLIFRecognizerOption.readerCallbackp      = _marpaESLIFJSONDecodeReaderb;
  marpaESLIFRecognizerOption.ifActionResolverp    = NULL; /* Our grammar has no if-action anyway */
  marpaESLIFRecognizerOption.eventActionResolverp = NULL;
  marpaESLIFRecognizerOption.regexActionResolverp = _marpaESLIFJSONDecodeRegexActionResolverp;
  marpaESLIFRecognizerOption.importerp            = _marpaESLIFJSONDecodeValueResultInternalImportb;

  marpaESLIFRecognizerp = _marpaESLIFRecognizer_newp(marpaESLIFGrammarJSONp->marpaESLIFp, marpaESLIFGrammarJSONp->grammarp, &marpaESLIFRecognizerOption, 0 /* discardb */, 0 /* noEventb */, 0 /* silentb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp == NULL)) {
    goto err;
  }

  /* We push marpaESLIFRecognizerp as the symbol import context to be able to proxy to it */
  jsonString.marpaESLIFSymbolOption.userDatavp = marpaESLIFRecognizerp;
  jsonString.marpaESLIFSymbolOption.importerp = _marpaESLIFJSONDecodeSymbolImportProxyb;

  jsonConstantOrNumber.marpaESLIFSymbolOption.userDatavp = marpaESLIFRecognizerp;
  jsonConstantOrNumber.marpaESLIFSymbolOption.importerp = _marpaESLIFJSONDecodeSymbolImportProxyb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  marpaESLIFJSONDecodeDepositCallbackContext.marpaESLIFJSONDecodeContextp  = &marpaESLIFJSONDecodeContext;
  marpaESLIFJSONDecodeDepositCallbackContext.keyb                          = 1;
  marpaESLIFJSONDecodeDepositCallbackContext.allocl                        = 0;

  finalValuep = marpaESLIFJSONDecodeDeposit.dstp = (marpaESLIFValueResult_t *) malloc(sizeof(marpaESLIFValueResult_t));
  if (MARPAESLIF_UNLIKELY(marpaESLIFJSONDecodeDeposit.dstp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFGrammarJSONp->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  *(marpaESLIFJSONDecodeDeposit.dstp) = marpaESLIFValueResultUndef;

  marpaESLIFJSONDecodeDeposit.contextp = (marpaESLIFJSONDecodeDepositCallbackContext_t *) malloc(sizeof(marpaESLIFJSONDecodeDepositCallbackContext_t));
  if (MARPAESLIF_UNLIKELY(marpaESLIFJSONDecodeDeposit.contextp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFGrammarJSONp->marpaESLIFp, "malloc failure, %s", strerror(errno));
    free(marpaESLIFJSONDecodeDeposit.dstp);
    goto err;
  }

  marpaESLIFJSONDecodeDeposit.actionp          = _marpaESLIFJSONDecodeSetValueCallbackv;

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackPushb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext, &marpaESLIFJSONDecodeDeposit))) {
    goto err;
  }

  /* We do the loop on input ourself and use current character to do branch prediction */
  marpaESLIFAlternative.value          = marpaESLIFValueResultUndef;
  marpaESLIFAlternative.grammarLengthl = 1;

  while (1) {
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &inputs, &inputl))) {
      goto err;
    }
  check_input:
    if (inputl <= 0) {
      /* Read more data unless we are at eof */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_isEofb(marpaESLIFRecognizerp, &isEofb))) {
        goto err;
      }
      if (isEofb) {
        break;
      }
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_readb(marpaESLIFRecognizerp, &inputs, &inputl))) {
        goto err;
      }
      goto check_input;
    }

    /* Branch prediction */
    switch (inputs[0]) {

    case '{':
      marpaESLIFAlternative.names = "LBRACKET";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeObjectOpeningb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext))) {
        goto err;
      }
      break;

    case '}':
      marpaESLIFAlternative.names = "RBRACKET";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeObjectClosingb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext))) {
        goto err;
      }
      break;

    case '[':
      marpaESLIFAlternative.names = "LSQUARE";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeArrayOpeningb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext))) {
        goto err;
      }
      break;

    case ']':
      marpaESLIFAlternative.names = "RSQUARE";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeArrayClosingb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext))) {
        goto err;
      }
      break;

    case ':':
      marpaESLIFAlternative.names = "COLUMN";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      break;

    case '"':
      /* The external symbol has regex callouts */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_symbol_tryb(marpaESLIFRecognizerp, &jsonString, &matchb))) {
        goto err;
      }
      if (! matchb) {
        /* Bad string - common case is that a user put a valid JSON isn't it. */
        _marpaESLIFRecognizer_errorv(marpaESLIFRecognizerp);
        goto err;
      }
      /* Inject it in the recognizer */
      marpaESLIFAlternative.names = "STRING";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, marpaESLIFJSONDecodeContext.import.u.a.sizel))) {
        goto err;
      }
      break;

    case ',':
      marpaESLIFAlternative.names = "COMMA";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 1 /* lengthl */))) {
        goto err;
      }
      break;

    case 't': /* True */
    case 'T': /* True - Only extended grammar will accept it */
    case 'f': /* False */
    case 'F': /* False - Only extended grammar will accept it */
    case 'n': /* Null or NaN - Only extended grammar will accept the nan case */
    case 'N': /* Null or NaN - Only extended grammar will accept the case insensitive nan case */
    case '-': /* Number */
    case '0': /* Number */
    case '1': /* Number */
    case '+': /* Number - Only extended grammar will accept it */
    case '2': /* Number - Only extended grammar will accept it */
    case '3': /* Number - Only extended grammar will accept it */
    case '4': /* Number - Only extended grammar will accept it */
    case '5': /* Number - Only extended grammar will accept it */
    case '6': /* Number - Only extended grammar will accept it */
    case '7': /* Number - Only extended grammar will accept it */
    case '8': /* Number - Only extended grammar will accept it */
    case '9': /* Number - Only extended grammar will accept it */
    case 'i': /* Infinity - Only extended grammar will accept it */
    case 'I': /* Infinity - Only extended grammar will accept it */
      /* The external symbol has regex callouts */
      if (MARPAESLIF_UNLIKELY(! marpaESLIFRecognizer_symbol_tryb(marpaESLIFRecognizerp, &jsonConstantOrNumber, &matchb))) {
        goto err;
      }
      if (! matchb) {
        /* Bad constant or number - common case is that a user put a valid JSON isn't it. */
        _marpaESLIFRecognizer_errorv(marpaESLIFRecognizerp);
        goto err;
      }
      /* Inject it in the recognizer */
      marpaESLIFAlternative.names = "CONSTANT_OR_NUMBER";
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_alternative_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, marpaESLIFJSONDecodeContext.import.u.a.sizel))) {
        goto err;
      }
      break;

    default:
      /* This must be ok for :discard */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_discardb(marpaESLIFRecognizerp, &discardl))) {
        goto err;
      }
      if (discardl <= 0) {
        /* Nothing discarded ? Then it is garbage */
        _marpaESLIFRecognizer_errorv(marpaESLIFRecognizerp);
        goto err;
      }
    }
  }

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Number of items in depositStackp: %d", GENERICSTACK_USED(marpaESLIFJSONDecodeContext.depositStackp));

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_checkStartCompletionb(marpaESLIFRecognizerp, 0 /* lengthl */))) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_isStartCompleteb(marpaESLIFRecognizerp, &isStartCompleteb))) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_isEofb(marpaESLIFRecognizerp, &isEofb))) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, NULL, &inputl))) {
    goto err;
  }
  depositStackpUsedi = GENERICSTACK_USED(marpaESLIFJSONDecodeContext.depositStackp);

  /* Parsing is ok if:            */
  /* - start symbol is complete   */
  /* - eof is reached             */
  /* - all data is consumed       */
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "isStartCompleteb  = %d", (int) isStartCompleteb);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "isEofb            = %d", (int) isEofb);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "inputl            = %ld", (unsigned long) inputl);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "depositStack size = %d", depositStackpUsedi);

  if ((! isStartCompleteb) || (! isEofb) || (inputl > 0) || (depositStackpUsedi != 1)) {
    MARPAESLIF_ERROR(marpaESLIFGrammarJSONp->marpaESLIFp, "Incomplete parsing");
    _marpaESLIFRecognizer_errorv(marpaESLIFRecognizerp);
    goto err;
  }

  /* Here by definition, there is only one item remaining in deposit stack */
  /* Verify valuation */
  marpaESLIFValueOption                           = *marpaESLIFValueOptionp;
  marpaESLIFValueOption.userDatavp                = &marpaESLIFJSONDecodeContext;
  marpaESLIFValueOption.ruleActionResolverp       = NULL;
  marpaESLIFValueOption.symbolActionResolverp     = NULL;
  marpaESLIFValueOption.importerp                 = ((marpaESLIFValueOptionp != NULL) && (marpaESLIFValueOptionp->importerp != NULL)) ? _marpaESLIFJSONDecodeValueResultImportb : NULL;
  marpaESLIFValueOption.highRankOnlyb             = 1; /* Fixed */
  marpaESLIFValueOption.orderByRankb              = 1; /* Fixed */
  marpaESLIFValueOption.ambiguousb                = 0; /* Fixed */
  marpaESLIFValueOption.nullb                     = 0; /* Fixed */
  marpaESLIFValueOption.maxParsesi                = 0; /* Fixed */

  marpaESLIFValuep = _marpaESLIFValue_newp(marpaESLIFRecognizerp, &marpaESLIFValueOption, 0 /* silentb */, 1 /* fakeb */, 0 /* directTransferb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFValuep == NULL)) {
    goto err;
  }

  /* Set-up proxy representation */
  marpaESLIFValuep->proxyRepresentationp = _marpaESLIFJSONDecodeRepresentationb;

  /* Call for import (no-op if end-user has set no importer */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_importb(marpaESLIFValuep, finalValuep))) {
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (marpaESLIFValuep != NULL) {
    marpaESLIFValue_freev(marpaESLIFValuep);
  }
  if (marpaESLIFJSONDecodeContext.depositStackp != NULL) {
    /* It is in theory impossible that marpaESLIFRecognizerp is NULL if marpaESLIFJSONDecodeContext.depositStackp is not NULL */
    if (marpaESLIFRecognizerp != NULL) {
      /* All entries contain abused marpaESLIFValueResult's that are allocated except the one on the top */
      while (GENERICSTACK_USED(marpaESLIFJSONDecodeContext.depositStackp) > 0) {
        if (_marpaESLIFJSONDecodeDepositStackPopb(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext, &marpaESLIFJSONDecodeDeposit)) {
          _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, &marpaESLIFJSONDecodeContext, &marpaESLIFJSONDecodeDeposit);
        }
      }
    }
    GENERICSTACK_RESET(marpaESLIFJSONDecodeContext.depositStackp);
  }
  if (marpaESLIFJSONDecodeContext.uint32p != NULL) {
    free(marpaESLIFJSONDecodeContext.uint32p);
  }
  if (marpaESLIFJSONDecodeContext.currentValue.type != MARPAESLIF_VALUE_TYPE_UNDEF) {
      MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "Freeing currentValue content");
      _marpaESLIFRecognizer_marpaESLIFValueResult_freeb(marpaESLIFRecognizerp, &(marpaESLIFJSONDecodeContext.currentValue), 1 /* deepb */);
    }
  /* Note that finalValuep is automatically freed when scanning the deposit stack */

  if (marpaESLIFRecognizerp != NULL) {
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
    MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
    marpaESLIFRecognizer_freev(marpaESLIFRecognizerp);
  }

  return rcb;
}

/*****************************************************************************/
static void _marpaESLIFJSONReaderDisposev(void *userDatavp, char *inputcp, size_t inputl, short eofb, short characterStreamb, char *encodings, size_t encodingl)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONReaderDisposev";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;

  /* Proxy to caller's read disposer */
  if (marpaESLIFJSONDecodeContextp->readerDisposep != NULL) {
    marpaESLIFJSONDecodeContextp->readerDisposep(marpaESLIFJSONDecodeContextp->marpaESLIFRecognizerOptionp->userDatavp,
                                                 inputcp,
                                                 inputl,
                                                 eofb,
                                                 characterStreamb,
                                                 encodings,
                                                 encodingl);
  }
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeReaderb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp, marpaESLIFReaderDispose_t *disposeCallbackpp)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONDecodeReaderb";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;
  short                          rcb;

  /* Proxy to caller's recognizer */
  rcb = marpaESLIFJSONDecodeContextp->marpaESLIFRecognizerOptionp->readerCallbackp(marpaESLIFJSONDecodeContextp->marpaESLIFRecognizerOptionp->userDatavp,
                                                                                   inputcpp,
                                                                                   inputlp,
                                                                                   eofbp,
                                                                                   characterStreambp,
                                                                                   encodingsp,
                                                                                   encodinglp,
                                                                                   &(marpaESLIFJSONDecodeContextp->readerDisposep));

  *disposeCallbackpp = _marpaESLIFJSONReaderDisposev;

  return rcb;
}

/*****************************************************************************/
static marpaESLIFRecognizerRegexCallback_t _marpaESLIFJSONDecodeRegexActionResolverp(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  static const char                   *funcs = "_marpaESLIFJSONDecodeRegexActionResolverp";
  marpaESLIFRecognizerRegexCallback_t  rcp;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  rcp = _marpaESLIFJSONDecodeRegexCallbackb;

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %p", rcp);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);

  return rcp;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeRegexCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodeRegexCallbackb";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;
  long                           blockNumberl;
  char                          *subjects;
  char                          *matchs;
  size_t                         matchl;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  switch ((blockNumberl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CALLOUT_NUMBER].value.u.l)) {

  case 50:
    /* ============================ */
    /* String initialization        */
    /* ============================ */
    MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "String initialization");
    marpaESLIFJSONDecodeContextp->stringallocl = 0;
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeAppendCharb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, NULL, 0))) {
      goto err;
    }
    break;

  case 51:
    /* ============================ */
    /* String component             */
    /* ============================ */
    /* If there is a match it is complete, it is the second in the ovector per construction */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects + marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_OFFSET_VECTOR].value.u.r.p[2].u.l;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_OFFSET_VECTOR].value.u.r.p[3].u.l - marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_OFFSET_VECTOR].value.u.r.p[2].u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "String component on %ld bytes at positions [%ld-%ld]", (unsigned long) matchl, (unsigned long) marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_OFFSET_VECTOR].value.u.r.p[2].u.l, (unsigned long) (marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_OFFSET_VECTOR].value.u.r.p[3].u.l - 1));
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeAppendCharb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl))) {
      goto err;
    }
    break;

  case 52:
    /* ============================ */
    /* String finalization          */
    /* ============================ */
    MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "String finalization");
    marpaESLIFJSONDecodeContextp->currentValue.u.s.p[marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel] = '\0';
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 60:
    /* ============================ */
    /* True                         */
    /* ============================ */
    MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "True");
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFRecognizerp->marpaESLIFp->marpaESLIFValueResultTrue;
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 61:
    /* ============================ */
    /* False                        */
    /* ============================ */
    MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "False");
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFRecognizerp->marpaESLIFp->marpaESLIFValueResultFalse;
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 62:
    /* ============================ */
    /* Null                         */
    /* ============================ */
    MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "Null");
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 63:
    /* ============================ */
    /* Number                       */
    /* ============================ */
    /* If there is a match it is complete, i.e. current position is the full length - no need to have match group */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CURRENT_POSITION].value.u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Number on %ld bytes", (unsigned long) matchl);
    if (! _marpaESLIFJSONDecodeSetNumberb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl)) {
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 64:
    /* ============================ */
    /* Positive infinity            */
    /* ============================ */
    /* If there is a match it is complete, i.e. current position is the full length - no need to have match group */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CURRENT_POSITION].value.u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Positive infinity on %ld bytes", (unsigned long) matchl);
    if (! _marpaESLIFJSONDecodeSetPositiveInfinityb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl)) {
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 65:
    /* ============================ */
    /* Negative infinity            */
    /* ============================ */
    /* If there is a match it is complete, i.e. current position is the full length - no need to have match group */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CURRENT_POSITION].value.u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Negative infinity on %ld bytes", (unsigned long) matchl);
    if (! _marpaESLIFJSONDecodeSetNegativeInfinityb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl)) {
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 66:
    /* ============================ */
    /* Positive nan                 */
    /* ============================ */
    /* If there is a match it is complete, i.e. current position is the full length - no need to have match group */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CURRENT_POSITION].value.u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Positive nan on %ld bytes", (unsigned long) matchl);
    if (! _marpaESLIFJSONDecodeSetPositiveNanb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl)) {
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  case 67:
    /* ============================ */
    /* Negative                 nan */
    /* ============================ */
    /* If there is a match it is complete, i.e. current position is the full length - no need to have match group */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_inputb(marpaESLIFRecognizerp, &subjects, NULL))) {
      goto err;
    }
    matchs = subjects;
    matchl = marpaESLIFCalloutBlockp->u.t.p[MARPAESLIFCALLOUTBLOCK_CURRENT_POSITION].value.u.l;
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Negative nan on %ld bytes", (unsigned long) matchl);
    if (! _marpaESLIFJSONDecodeSetNegativeNanb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, matchs, matchl)) {
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &(marpaESLIFJSONDecodeContextp->currentValue)))) {
      goto err;
    }
    break;

  default:
    /* ============================ */
    /* >>> Unknown case <<<         */
    /* ============================ */
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Invalid callout block number %ld", (unsigned long) blockNumberl);
    goto err;
  }

  *marpaESLIFValueResultOutp = 0;
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
#ifndef MARPAESLIF_NTRACE
  if (rcb) {
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d, *marpaESLIFValueResultOutp=%d", (int) rcb, (int) *marpaESLIFValueResultOutp);
  } else {
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  }
#endif
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return 1;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeIncb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeIncb";
  size_t             currentDepthl;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->maxDepthl > 0) {
    currentDepthl = marpaESLIFJSONDecodeContextp->currentDepthl;
    if (MARPAESLIF_UNLIKELY(++currentDepthl < marpaESLIFJSONDecodeContextp->currentDepthl)) {
      MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing currentDepthl");
      rcb = 0;
    } else {
      marpaESLIFJSONDecodeContextp->currentDepthl = currentDepthl;
      if (MARPAESLIF_UNLIKELY(currentDepthl > marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->maxDepthl)) {
        MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Maximum depth %ld reached", (unsigned long) marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->maxDepthl);
        errno = EINVAL;
	rcb = 0;
      } else {
	rcb = 1;
      }
    }
  } else {
    rcb = 1;
  }

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeDecb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeDecb";

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->maxDepthl > 0) {
    /* No need to check size_t turnaround: currentDepthl can only be decrease if this was successfuly increased previously */
    --marpaESLIFJSONDecodeContextp->currentDepthl;
  }

  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "return 1");
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return 1;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetPositiveInfinityb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIFJSONDecodeSetPositiveInfinityb";
  short              confidenceb;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

#ifdef MARPAESLIF_INFINITY
  marpaESLIFJSONDecodeContextp->currentValue.contextp        = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.representationp = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFJSONDecodeContextp->currentValue.u.f             = marpaESLIFRecognizerp->marpaESLIFp->positiveinfinityf;
  confidenceb = 1;
#else
  marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
  confidenceb = 0;
#endif

  rcb = _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizerp,
                                       marpaESLIFJSONDecodeContextp,
                                       marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->positiveInfinityActionp,
                                       inputs,
                                       inputl,
                                       &(marpaESLIFJSONDecodeContextp->currentValue),
                                       confidenceb);

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetNegativeInfinityb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIFJSONDecodeSetNegativeInfinityb";
  short              confidenceb;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

#ifdef MARPAESLIF_INFINITY
  marpaESLIFJSONDecodeContextp->currentValue.contextp        = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.representationp = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFJSONDecodeContextp->currentValue.u.f             = marpaESLIFRecognizerp->marpaESLIFp->negativeinfinityf;
  confidenceb = 1;
#else
  marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
  confidenceb = 0;
#endif

  rcb = _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizerp,
                                       marpaESLIFJSONDecodeContextp,
                                       marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->negativeInfinityActionp,
                                       inputs,
                                       inputl,
                                       &(marpaESLIFJSONDecodeContextp->currentValue),
                                       confidenceb);

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetPositiveNanb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIFJSONDecodeSetPositiveNanb";
  short              confidenceb;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

#ifdef MARPAESLIF_INFINITY
  marpaESLIFJSONDecodeContextp->currentValue.contextp        = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.representationp = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFJSONDecodeContextp->currentValue.u.f             = marpaESLIFRecognizerp->marpaESLIFp->positivenanf;
  confidenceb = marpaESLIFRecognizerp->marpaESLIFp->nanconfidenceb;
#else
  marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
  confidenceb = 0;
#endif

  rcb = _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizerp,
                                       marpaESLIFJSONDecodeContextp,
                                       marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->positiveNanActionp,
                                       inputs,
                                       inputl,
                                       &(marpaESLIFJSONDecodeContextp->currentValue),
                                       confidenceb);

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetNegativeNanb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIFJSONDecodeSetNegativeNanb";
  short              confidenceb;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

#ifdef MARPAESLIF_INFINITY
  marpaESLIFJSONDecodeContextp->currentValue.contextp        = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.representationp = NULL;
  marpaESLIFJSONDecodeContextp->currentValue.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFJSONDecodeContextp->currentValue.u.f             = marpaESLIFRecognizerp->marpaESLIFp->negativenanf;
  confidenceb = marpaESLIFRecognizerp->marpaESLIFp->nanconfidenceb;
#else
  marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
  confidenceb = 0;
#endif

  rcb = _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizerp,
                                       marpaESLIFJSONDecodeContextp,
                                       marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->negativeNanActionp,
                                       inputs,
                                       inputl,
                                       &(marpaESLIFJSONDecodeContextp->currentValue),
                                       confidenceb);

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetNumberb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIFJSONDecodeSetNumberb";
  short              confidenceb = 1; /* Set to 0 only when we got through the double case */
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* Note that the grammar made sure that the number respect the strict mode or not, therefore parsing */
  /* the string with the non-strict mode used by _marpaESLIF_numberb() will work regardless of the     */
  /* strict mode.                                                                                      */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_numberb(marpaESLIFRecognizerp->marpaESLIFp,
                                                inputs,
                                                inputl,
                                                &(marpaESLIFJSONDecodeContextp->currentValue),
                                                &confidenceb))) {
    goto err;
  }

  rcb = _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizerp,
                                       marpaESLIFJSONDecodeContextp,
                                       marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->numberActionp,
                                       inputs,
                                       inputl,
                                       &(marpaESLIFJSONDecodeContextp->currentValue),
                                       confidenceb);
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, size_t incl)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeExtendStringContainerb";
  size_t             wantedl;
  size_t             heapl;
  unsigned char     *tmps;
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (marpaESLIFJSONDecodeContextp->stringallocl <= 0) {
    if (incl > MARPAESLIFJSON_STRINGALLOCL_DEFAULT_VALUE) {
      /* Initial increase of more than MARPAESLIFJSON_STRINGALLOCL_DEFAULT_VALUE */
      heapl = _marpaESLIF_next_power_of_twob(marpaESLIFRecognizerp->marpaESLIFp, incl);
    } else {
      heapl = MARPAESLIFJSON_STRINGALLOCL_DEFAULT_VALUE;
    }
    marpaESLIFJSONDecodeContextp->currentValue.u.s.p = (unsigned char *) malloc(heapl + 1); /* +1 for NUL byte */
    if (MARPAESLIF_UNLIKELY(marpaESLIFJSONDecodeContextp->currentValue.u.s.p == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated current value u.s.p to %p", marpaESLIFJSONDecodeContextp->currentValue.u.s.p);
    marpaESLIFJSONDecodeContextp->currentValue.contextp           = NULL;
    marpaESLIFJSONDecodeContextp->currentValue.representationp    = NULL;
    marpaESLIFJSONDecodeContextp->currentValue.type               = MARPAESLIF_VALUE_TYPE_STRING;
    marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel          = incl;
    marpaESLIFJSONDecodeContextp->currentValue.u.s.shallowb       = 0;
    marpaESLIFJSONDecodeContextp->currentValue.u.s.freeUserDatavp = marpaESLIFRecognizerp->marpaESLIFp;
    marpaESLIFJSONDecodeContextp->currentValue.u.s.freeCallbackp  = _marpaESLIF_generic_freeCallbackv;
    marpaESLIFJSONDecodeContextp->currentValue.u.s.encodingasciis = (char *) MARPAESLIF_UTF8_STRING;

    marpaESLIFJSONDecodeContextp->stringallocl = heapl;
  } else {
    wantedl = marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel + incl;
    if (wantedl < marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel) {
      MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing string size");
      goto err;
    }

    if (wantedl > marpaESLIFJSONDecodeContextp->stringallocl) {
      heapl = _marpaESLIF_next_power_of_twob(marpaESLIFRecognizerp->marpaESLIFp, wantedl);
      if (MARPAESLIF_UNLIKELY(heapl <= 0)) {
        goto err;
      }

      tmps = (unsigned char *) realloc(marpaESLIFJSONDecodeContextp->currentValue.u.s.p, heapl + 1); /* +1 for NUL byte */
      if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "realloc failure, %s", strerror(errno));
        goto err;
      }
      MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Reallocated current value u.s.p from %p to %p", marpaESLIFJSONDecodeContextp->currentValue.u.s.p, tmps);
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p = tmps;
      marpaESLIFJSONDecodeContextp->stringallocl = heapl;
    }
    marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel = wantedl;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeAppendCharb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
/* Cases are:                                                                */
/* - First character is     '\': this is an escaped character                */
/* - First character is not '\': the whole match is ASCII chars              */
/* Caller is responsible to have set stringallocl correctly.                 */
/*****************************************************************************/
{
  static const char       *funcs = "_marpaESLIFJSONDecodeAppendCharb";
  marpaESLIF_uint32_t     *uint32p;
  marpaESLIF_uint32_t     *tmpp;
  size_t                   uint32l;
  size_t                   heapl;
  size_t                   dstl;
  marpaESLIF_uint32_t      c;
  char                    *p;
  unsigned char           *q;
  size_t                   i;
  size_t                   j;
  size_t                   previousSizel;
  short                    rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* We re-process input only when this is an escaped character */
  if (inputs == NULL) {
    /* ------------------------- */
    /* String initialization     */
      /* ------------------------- */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 0 /* incl */))) {
      goto err;
    }
  } else if (inputs[0] != '\\') {
    /* ------------------------- */
    /* Unescaped character       */
    /* ------------------------- */
    previousSizel = marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel;
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, inputl /* incl */))) {
      goto err;
    }
    memcpy(&(marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel]), inputs, inputl);
  } else {
    /* By definition there is something else after */
    previousSizel = marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel;

    switch (inputs[1]) {

    case '"':
      /* ------------------------- */
      /* Escaped double quote      */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_DQUOTE;
      break;

    case '\\':
      /* ------------------------- */
      /* Escaped backslash         */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_BACKSLASH;
      break;

    case '/':
      /* ------------------------- */
      /* Escaped slash             */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_SLASH;
      break;

    case 'b':
      /* ------------------------- */
      /* Escaped backspace         */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_BACKSPACE;
      break;

    case 'f':
      /* ------------------------- */
      /* Escaped formfeed          */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_FORMFEED;
      break;

    case 'r':
      /* ------------------------- */
      /* Escaped carriage return   */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_CARRIAGE_RETURN;
      break;

    case 'n':
      /* ------------------------- */
      /* Escaped line feed         */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_LINEFEED;
      break;

    case 't':
      /* ------------------------- */
      /* Escaped horizontal tab    */
      /* ------------------------- */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, 1 /* incl */))) {
        goto err;
      }
      marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel] = MARPAESLIFJSON_HORIZONTAL_TAB;
      break;

    default:
      /* ------------------------- */
      /* Escaped UTF-16 characters */
      /* ------------------------- */

      /* It is a sequence of '\uXXXX' by definition, i.e. 6 bytes - so there are inputl/6 hex digits */
      uint32l = inputl / 6;

      if (uint32l <= MARPAESLIFJSON_ARRAYL_IN_STRUCTURE) {
        uint32p = marpaESLIFJSONDecodeContextp->_uint32p;
      } else {
        heapl = _marpaESLIF_next_power_of_twob(marpaESLIFRecognizerp->marpaESLIFp, uint32l);
        if (heapl <= 0) {
          goto err;
        }
        if (marpaESLIFJSONDecodeContextp->uint32p == NULL) {
          marpaESLIFJSONDecodeContextp->uint32p = (marpaESLIF_uint32_t *) malloc(heapl * sizeof(marpaESLIF_uint32_t));
          if (MARPAESLIF_UNLIKELY(marpaESLIFJSONDecodeContextp->uint32p == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "malloc failure, %s", strerror(errno));
            goto err;
          }
          MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated marpaESLIFJSONDecodeContextp->uint32p to %p", marpaESLIFJSONDecodeContextp->uint32p);
          uint32p = marpaESLIFJSONDecodeContextp->uint32p;
          marpaESLIFJSONDecodeContextp->uint32allocl = heapl;
        } else if (marpaESLIFJSONDecodeContextp->uint32allocl < heapl) {
          tmpp = (marpaESLIF_uint32_t *) realloc(marpaESLIFJSONDecodeContextp->uint32p, heapl * sizeof(marpaESLIF_uint32_t));
          if (MARPAESLIF_UNLIKELY(tmpp == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "realloc failure, %s", strerror(errno));
            goto err;
          }
          MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Reallocated marpaESLIFJSONDecodeContextp->uint32p from %p to %p", marpaESLIFJSONDecodeContextp->uint32p, tmpp);
          uint32p = marpaESLIFJSONDecodeContextp->uint32p = tmpp;
          marpaESLIFJSONDecodeContextp->uint32allocl = heapl;
        } else {
          uint32p = marpaESLIFJSONDecodeContextp->uint32p;
        }
      }

      for (i = 0, p = inputs + 2; i < uint32l; i++, p += 2) {
        c = 0;

        MARPAESLIFJSON_DST_OR_VALCHAR(marpaESLIFJSONDecodeContextp, c, *p++);
        c <<= 4;
        MARPAESLIFJSON_DST_OR_VALCHAR(marpaESLIFJSONDecodeContextp, c, *p++);
        c <<= 4;
        MARPAESLIFJSON_DST_OR_VALCHAR(marpaESLIFJSONDecodeContextp, c, *p++);
        c <<= 4;
        MARPAESLIFJSON_DST_OR_VALCHAR(marpaESLIFJSONDecodeContextp, c, *p++);

        uint32p[i] = c;
      }

      /* Worst case is three UTF-8 bytes per UTF-16 character */
      dstl = uint32l * 3;

      /* Make sure there is enough room */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeExtendStringContainerb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, dstl /* incl */))) {
        goto err;
      }

      /* Restore initial size */
      marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel = previousSizel;

      /* Based on efi_utf16_to_utf8 from Linux kernel */
      q = &(marpaESLIFJSONDecodeContextp->currentValue.u.s.p[previousSizel]);
      for (i = 0, j = 1; i < uint32l; i++, j++) {
        c = uint32p[i];

        if ((c >= 0xD800) && (c <= 0xDBFF) && (j < uint32l) && (uint32p[j] >= 0xDC00) && (uint32p[j] <= 0xDFFF)) {
          /* Surrogate UTF-16 pair */
          c = 0x10000 + ((c & 0x3FF) << 10) + (uint32p[j] & 0x3FF);
          ++i;
          ++j;
        }

        if ((c >= 0xD800) && (c <= 0xDFFF)) {
          if (marpaESLIFJSONDecodeContextp->marpaESLIFJSONDecodeOptionp->noReplacementCharacterb) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp,
                              "Invalid UTF-16 character \\%c%c%c%c%c",
                              inputs[(i * 6) + 1],
                              inputs[(i * 6) + 2],
                              inputs[(i * 6) + 3],
                              inputs[(i * 6) + 4],
                              inputs[(i * 6) + 5]);
            goto err;
          } else {
            MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp,
                                        funcs,
                                        "Invalid UTF-16 character \\%c%c%c%c%c replaced by 0xFFFD",
                                        inputs[(i * 6) + 1],
                                        inputs[(i * 6) + 2],
                                        inputs[(i * 6) + 3],
                                        inputs[(i * 6) + 4],
                                        inputs[(i * 6) + 5]);
            c = 0xFFFD; /* Replacement character */
          }
        }

        if (c < 0x80) {
          *q++ = c;
          marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
          continue;
        }

        if (c < 0x800) {
          *q++ = 0xC0 + (c >> 6);
          marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
          goto t1;
        }

        if (c < 0x10000) {
          *q++ = 0xE0 + (c >> 12);
          marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
          goto t2;
        }

        *q++ = 0xF0 + (c >> 18);
        marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
        *q++ = 0x80 + ((c >> 12) & 0x3F);
        marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
      t2:
        *q++ = 0x80 + ((c >> 6) & 0x3F);
        marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
      t1:
        *q++ = 0x80 + (c & 0x3F);
        marpaESLIFJSONDecodeContextp->currentValue.u.s.sizel++;
      }

      break;
    }
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeProposalb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONProposalAction_t proposalp, char *inputs, size_t inputl, marpaESLIFValueResult_t *currentValuep, short confidenceb)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeProposalb";
  short rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (proposalp != NULL) {
    if (MARPAESLIF_UNLIKELY(! proposalp(marpaESLIFJSONDecodeContextp->marpaESLIFRecognizerOptionp->userDatavp,
                                        inputs,
                                        inputl,
                                        currentValuep,
                                        confidenceb))) {
      MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "%s: Callback failure", inputs);
      goto err;
    }
  } else if (currentValuep->type == MARPAESLIF_VALUE_TYPE_UNDEF) {
    MARPAESLIF_WARNF(marpaESLIFRecognizerp->marpaESLIFp, "%.*s: Parsing failure, using undefined value", (int) inputl, inputs);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeSetConstantb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, char *inputs, size_t inputl)
/*****************************************************************************/
{
  static const char *funcs = "__marpaESLIFJSONDecodeSetConstantb";
  short              rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  switch (inputs[0]) {
  case 't':
  case 'T':
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFRecognizerp->marpaESLIFp->marpaESLIFValueResultTrue;
    break;
  case 'f':
  case 'F':
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFRecognizerp->marpaESLIFp->marpaESLIFValueResultFalse;
    break;
  case 'n':
  case 'N':
    marpaESLIFJSONDecodeContextp->currentValue = marpaESLIFValueResultUndef;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp,
                      "Invalid constant first character '%c'",
                      inputs[0]);
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeDepositStackPushb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp)
/*****************************************************************************/
/* We abuse marpaESLIFValueResult_t:                                         */
/*                                                                           */
/*          marpaESLIFValueResult_t             marpaESLIFJSONDeposit_t      */
/*            representationp                     dstp                       */
/*            contextp                            contextp                   */
/*            u.p.p                               actionp                    */
/*****************************************************************************/
{
  static const char       *funcs = "_marpaESLIFJSONDecodeDepositStackPushb";
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  short                    rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  marpaESLIFValueResult.representationp  = (marpaESLIFRepresentation_t) marpaESLIFJSONDecodeDepositp->dstp;
  marpaESLIFValueResult.contextp         = marpaESLIFJSONDecodeDepositp->contextp;
  marpaESLIFValueResult.u.p.p            = marpaESLIFJSONDecodeDepositp->actionp;

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Pushing depositStackp[%d]->dstp              = %p of type %s", GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp), marpaESLIFJSONDecodeDepositp->dstp, _marpaESLIF_value_types(marpaESLIFJSONDecodeDepositp->dstp->type));
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Pushing depositStackp[%d]->contextp          = %p", GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp), marpaESLIFJSONDecodeDepositp->contextp);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Pushing depositStackp[%d]->contextp->keyb    = %d", GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp), (int) marpaESLIFJSONDecodeDepositp->contextp->keyb);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Pushing depositStackp[%d]->contextp->alllocl = %ld", GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp), (unsigned long) marpaESLIFJSONDecodeDepositp->contextp->allocl);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Pushing depositStackp[%d]->actionp           = %p", GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp), marpaESLIFJSONDecodeDepositp->actionp);

  GENERICSTACK_PUSH_CUSTOM(marpaESLIFJSONDecodeContextp->depositStackp, marpaESLIFValueResult);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFJSONDecodeContextp->depositStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "depositStackp push failure, %s", strerror(errno));
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeDepositStackGetLastb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp)
/*****************************************************************************/
/* We abuse marpaESLIFValueResult_t:                                         */
/*                                                                           */
/*          marpaESLIFValueResult_t             marpaESLIFJSONDeposit_t      */
/*            representationp                     dstp                       */
/*            contextp                            contextp                   */
/*            u.p.p                               actionp                    */
/*****************************************************************************/
{
  static const char       *funcs   = "_marpaESLIFJSONDecodeDepositStackGetLastb";
  int                      indicei = GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp) - 1;
  marpaESLIFValueResult_t *marpaESLIFValueResultp;
  short                    rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  marpaESLIFValueResultp = GENERICSTACK_GET_CUSTOMP(marpaESLIFJSONDecodeContextp->depositStackp, indicei);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFJSONDecodeContextp->depositStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "depositStackp get failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFJSONDecodeDepositp->dstp     = (marpaESLIFValueResult_t *) marpaESLIFValueResultp->representationp;
  marpaESLIFJSONDecodeDepositp->contextp = marpaESLIFValueResultp->contextp;
  marpaESLIFJSONDecodeDepositp->actionp  = (marpaESLIFJSONDecodeDepositCallback_t) marpaESLIFValueResultp->u.p.p;

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Got depositStackp[%d]->dstp             = %p of type %s", indicei, marpaESLIFJSONDecodeDepositp->dstp, _marpaESLIF_value_types(marpaESLIFJSONDecodeDepositp->dstp->type));
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Got depositStackp[%d]->contextp         = %p", indicei, marpaESLIFJSONDecodeDepositp->contextp);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Got depositStackp[%d]->contextp->keyb   = %d", indicei, (int) marpaESLIFJSONDecodeDepositp->contextp->keyb);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Got depositStackp[%d]->contextp->allocl = %ld", indicei, (unsigned long) marpaESLIFJSONDecodeDepositp->contextp->allocl);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Got depositStackp[%d]->actionp          = %p", indicei, marpaESLIFJSONDecodeDepositp->actionp);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeDepositStackPopb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *marpaESLIFJSONDecodeDepositp)
/*****************************************************************************/
/* We abuse marpaESLIFValueResult_t:                                         */
/*                                                                           */
/*          marpaESLIFValueResult_t             marpaESLIFJSONDeposit_t      */
/*            representationp                     dstp                       */
/*            contextp                            contextp                   */
/*            u.p.p                               actionp                    */
/*****************************************************************************/
{
  static const char       *funcs   = "_marpaESLIFJSONDecodeDepositStackPopb";
  int                      indicei = GENERICSTACK_USED(marpaESLIFJSONDecodeContextp->depositStackp);
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  short                    rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  marpaESLIFValueResult = GENERICSTACK_POP_CUSTOM(marpaESLIFJSONDecodeContextp->depositStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFJSONDecodeContextp->depositStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "depositStackp pop failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFJSONDecodeDepositp->dstp     = (marpaESLIFValueResult_t *) marpaESLIFValueResult.representationp;
  marpaESLIFJSONDecodeDepositp->contextp = marpaESLIFValueResult.contextp;
  marpaESLIFJSONDecodeDepositp->actionp  = (marpaESLIFJSONDecodeDepositCallback_t) marpaESLIFValueResult.u.p.p;

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Popped depositStackp[%d]->dstp             = %p of type %s", indicei - 1, marpaESLIFJSONDecodeDepositp->dstp, _marpaESLIF_value_types(marpaESLIFJSONDecodeDepositp->dstp->type));
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Popped depositStackp[%d]->contextp         = %p", indicei - 1, marpaESLIFJSONDecodeDepositp->contextp);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Popped depositStackp[%d]->contextp->keyb   = %d", indicei - 1, (int) marpaESLIFJSONDecodeDepositp->contextp->keyb);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Popped depositStackp[%d]->contextp->allocl = %ld", indicei - 1, (unsigned long) marpaESLIFJSONDecodeDepositp->contextp->allocl);
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Popped depositStackp[%d]->actionp          = %p", indicei - 1, marpaESLIFJSONDecodeDepositp->actionp);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeSetValueCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeSetValueCallbackv";

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Setting value of type %s", _marpaESLIF_value_types(srcp->type));
  *dstp = *srcp;

  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "return 1");
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return 1;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodePushRowCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp)
/*****************************************************************************/
{
  static const char       *funcs = "_marpaESLIFJSONDecodePushRowCallbackv";
  size_t                   nextSizel;
  size_t                   nextAllocl;
  marpaESLIFValueResult_t *marpaESLIFValueResultTmpp;
  size_t                   indicel;
  short                    rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (srcp == NULL) {
    /* Container initalization */
    dstp->contextp           = NULL;
    dstp->representationp    = NULL;
    dstp->type               = MARPAESLIF_VALUE_TYPE_ROW;
    dstp->u.r.p              = NULL;
    dstp->u.r.shallowb       = 0;
    dstp->u.r.freeUserDatavp = marpaESLIFRecognizerp->marpaESLIFp;
    dstp->u.r.freeCallbackp  = _marpaESLIF_generic_freeCallbackv;
    dstp->u.r.sizel          = 0;
  } else {
    if (marpaESLIFJSONDecodeDepositCallbackContextp->allocl <= 0) {
      /* First time */
      dstp->u.r.p = (marpaESLIFValueResult_t *) malloc(sizeof(marpaESLIFValueResult_t));
      if (MARPAESLIF_UNLIKELY(dstp->u.r.p == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated destination %p->u.r.p to %p", dstp, dstp->u.r.p);
      dstp->u.r.sizel          = 1;

      marpaESLIFJSONDecodeDepositCallbackContextp->allocl = 1;
    } else {
      nextSizel = dstp->u.r.sizel + 1;
      /* Paranoid mode */
      if (MARPAESLIF_UNLIKELY(nextSizel < dstp->u.r.sizel)) {
        MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing nextSizel");
        goto err;
      }

      if (nextSizel > marpaESLIFJSONDecodeDepositCallbackContextp->allocl) {
        nextAllocl = marpaESLIFJSONDecodeDepositCallbackContextp->allocl * 2;
        /* Paranoid mode */
        if (MARPAESLIF_UNLIKELY(nextAllocl < marpaESLIFJSONDecodeDepositCallbackContextp->allocl * 2)) {
          MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing nextAllocl");
          goto err;
        }
        marpaESLIFValueResultTmpp = (marpaESLIFValueResult_t *) realloc(dstp->u.r.p, nextAllocl * sizeof(marpaESLIFValueResult_t));
        if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultTmpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "realloc failure, %s", strerror(errno));
          goto err;
        }

        MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Reallocated destination %p->u.r.p from %p to %p", dstp, dstp->u.r.p, marpaESLIFValueResultTmpp);
        dstp->u.r.p = marpaESLIFValueResultTmpp;

        /* It is not a hasard that MARPAESLIF_VALUE_TYPE_UNDEF is 0... */
        if (marpaESLIFRecognizerp->marpaESLIFp->NULLisZeroBytesb && marpaESLIFRecognizerp->marpaESLIFp->ZeroIntegerisZeroBytesb) {
          memset(&(dstp->u.r.p[marpaESLIFJSONDecodeDepositCallbackContextp->allocl]), '\0', marpaESLIFJSONDecodeDepositCallbackContextp->allocl * sizeof(marpaESLIFValueResult_t));
        } else {
          for (indicel = marpaESLIFJSONDecodeDepositCallbackContextp->allocl; indicel < nextAllocl; indicel++) {
            dstp->u.r.p[indicel] = marpaESLIFValueResultUndef;
          }
        }
        marpaESLIFJSONDecodeDepositCallbackContextp->allocl = nextAllocl;
      }

      dstp->u.r.sizel = nextSizel;
    }

    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Setting value of type %s at array indice %ld", _marpaESLIF_value_types(srcp->type), (unsigned long) (dstp->u.r.sizel - 1));
    dstp->u.r.p[dstp->u.r.sizel - 1] = *srcp;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeSetHashCallbackv(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp, marpaESLIFValueResult_t *dstp, marpaESLIFValueResult_t *srcp)
/*****************************************************************************/
{
  static const char           *funcs                                 = "_marpaESLIFJSONDecodeSetHashCallbackv";
  size_t                       nextSizel;
  size_t                       nextAllocl;
  marpaESLIFValueResultPair_t *marpaESLIFValueResultPairTmpp;
  size_t                       indicel;
  short                        rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (srcp == NULL) {
    /* Container initalization */
    dstp->contextp           = NULL;
    dstp->representationp    = NULL;
    dstp->type               = MARPAESLIF_VALUE_TYPE_TABLE;
    dstp->u.t.p              = NULL;
    dstp->u.t.shallowb       = 0;
    dstp->u.t.freeUserDatavp = marpaESLIFRecognizerp->marpaESLIFp;
    dstp->u.t.freeCallbackp  = _marpaESLIF_generic_freeCallbackv;
    dstp->u.t.sizel          = 0;
  } else {
    if (marpaESLIFJSONDecodeDepositCallbackContextp->keyb) {
      if (marpaESLIFJSONDecodeDepositCallbackContextp->allocl <= 0) {
        /* First time */

        /* It is not a hasard that MARPAESLIF_VALUE_TYPE_UNDEF is 0... */
        if (marpaESLIFRecognizerp->marpaESLIFp->NULLisZeroBytesb && marpaESLIFRecognizerp->marpaESLIFp->ZeroIntegerisZeroBytesb) {
          dstp->u.t.p = (marpaESLIFValueResultPair_t *) calloc(1, sizeof(marpaESLIFValueResultPair_t));
          if (MARPAESLIF_UNLIKELY(dstp->u.t.p == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "calloc failure, %s", strerror(errno));
            goto err;
          }
        } else {
          dstp->u.t.p = (marpaESLIFValueResultPair_t *) malloc(sizeof(marpaESLIFValueResultPair_t));
          if (MARPAESLIF_UNLIKELY(dstp->u.t.p == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "calloc failure, %s", strerror(errno));
            goto err;
          }
          dstp->u.t.p->key   = marpaESLIFValueResultUndef;
          dstp->u.t.p->value = marpaESLIFValueResultUndef;
        }

        MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated destination %p->u.t.p to %p", dstp, dstp->u.t.p);
        dstp->u.t.sizel          = 1;

        marpaESLIFJSONDecodeDepositCallbackContextp->allocl = 1;

      } else {
        nextSizel = dstp->u.t.sizel + 1;
        /* Paranoid mode */
        if (MARPAESLIF_UNLIKELY(nextSizel < dstp->u.t.sizel)) {
          MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing nextSizel");
          goto err;
        }

        if (nextSizel > marpaESLIFJSONDecodeDepositCallbackContextp->allocl) {
          nextAllocl = marpaESLIFJSONDecodeDepositCallbackContextp->allocl * 2;
          /* Paranoid mode */
          if (MARPAESLIF_UNLIKELY(nextAllocl < marpaESLIFJSONDecodeDepositCallbackContextp->allocl * 2)) {
            MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing nextAllocl");
            goto err;
          }
          marpaESLIFValueResultPairTmpp = (marpaESLIFValueResultPair_t *) realloc(dstp->u.t.p, nextAllocl * sizeof(marpaESLIFValueResultPair_t));
          if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultPairTmpp == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "realloc failure, %s", strerror(errno));
            goto err;
          }

          MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Reallocated destination %p->u.t.p from %p to %p", dstp, dstp->u.t.p, marpaESLIFValueResultPairTmpp);
          dstp->u.t.p = marpaESLIFValueResultPairTmpp;

          /* It is not a hasard that MARPAESLIF_VALUE_TYPE_UNDEF is 0... */
          if (marpaESLIFRecognizerp->marpaESLIFp->NULLisZeroBytesb && marpaESLIFRecognizerp->marpaESLIFp->ZeroIntegerisZeroBytesb) {
            memset(&(dstp->u.t.p[marpaESLIFJSONDecodeDepositCallbackContextp->allocl]), '\0', marpaESLIFJSONDecodeDepositCallbackContextp->allocl * sizeof(marpaESLIFValueResultPair_t));
          } else {
            for (indicel = marpaESLIFJSONDecodeDepositCallbackContextp->allocl; indicel < nextAllocl; indicel++) {
              dstp->u.t.p[indicel].key   = marpaESLIFValueResultUndef;
              dstp->u.t.p[indicel].value = marpaESLIFValueResultUndef;
            }
          }

          marpaESLIFJSONDecodeDepositCallbackContextp->allocl = nextAllocl;
        }
        dstp->u.t.sizel = nextSizel;
      }

      MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Setting key of type %s at array indice %ld", _marpaESLIF_value_types(srcp->type), (unsigned long) (dstp->u.t.sizel - 1));
      dstp->u.t.p[dstp->u.t.sizel - 1].key = *srcp;
      marpaESLIFJSONDecodeDepositCallbackContextp->keyb = 0;
    } else {
      MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Setting value of type %s at array indice %ld", _marpaESLIF_value_types(srcp->type), (unsigned long) (dstp->u.t.sizel - 1));
      dstp->u.t.p[dstp->u.t.sizel - 1].value = *srcp;
      marpaESLIFJSONDecodeDepositCallbackContextp->keyb = 1;
    }
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFValueResult_t *marpaESLIFValueresultp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodePropagateValueb";
  marpaESLIFJSONDecodeDeposit_t  marpaESLIFJSONDecodeDeposit;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackGetLastb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFJSONDecodeDeposit.actionp(marpaESLIFRecognizerp, marpaESLIFJSONDecodeDeposit.contextp, marpaESLIFJSONDecodeDeposit.dstp, marpaESLIFValueresultp))) {
    goto err;
  }

  /* Re-initialise the source */
  *marpaESLIFValueresultp = marpaESLIFValueResultUndef;
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeValueResultInternalImportb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb)
/*****************************************************************************/
/* Internal importer used for marpaESLIFRecognizer_symbol_tryb               */
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONDecodeValueResultImportb";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* We expect a marpaESLIFValueResult_t of type ARRAY and nothing else because by definition the recognizer is a top-level recognizer */
  if (marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_ARRAY) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "marpaESLIFValueResultp->type is not ARRAY (got %d, %s)",
                      marpaESLIFValueResultp->type,
                      _marpaESLIF_value_types(marpaESLIFValueResultp->type));
    goto err;
  }

  marpaESLIFJSONDecodeContextp->import = *marpaESLIFValueResultp;
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONDecodeValueResultImportb";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;

  /* Proxy to user-defined importb */
  return marpaESLIFJSONDecodeContextp->marpaESLIFValueOptionp->importerp(marpaESLIFValuep,
                                                                         marpaESLIFJSONDecodeContextp->marpaESLIFValueOptionp->userDatavp,
                                                                         marpaESLIFValueResultp,
                                                                         haveUndefb);
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONDecodeRepresentationb";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;
  marpaESLIFValueOption_t       *marpaESLIFValueOptionp       = marpaESLIFJSONDecodeContextp->marpaESLIFValueOptionp;
  short                          rcb;

  /* Proxy to caller's representation */
  rcb = marpaESLIFValueResultp->representationp(marpaESLIFValueOptionp->userDatavp,
                                                marpaESLIFValueResultp,
                                                inputcpp,
                                                inputlp,
                                                encodingasciisp,
                                                &(marpaESLIFJSONDecodeContextp->representationDisposep),
                                                stringbp);

  *disposeCallbackpp = _marpaESLIFJSONDecodeRepresentationDisposev;

  return rcb;
}

/*****************************************************************************/
static void _marpaESLIFJSONDecodeRepresentationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONDecodeRepresentationDisposev";
  marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp = (marpaESLIFJSONDecodeContext_t *) userDatavp;
  marpaESLIFValueOption_t       *marpaESLIFValueOptionp       = marpaESLIFJSONDecodeContextp->marpaESLIFValueOptionp;

  /* Proxy to caller's representation disposer */
  if (marpaESLIFJSONDecodeContextp->representationDisposep != NULL) {
    marpaESLIFJSONDecodeContextp->representationDisposep(marpaESLIFValueOptionp->userDatavp,
                                                         inputcp,
                                                         inputl,
                                                         encodingasciis);
  }
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeDepositInitb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *depositp, marpaESLIFJSONDecodeDepositCallback_t actionp)
/*****************************************************************************/
{
  static const char                            *funcs = "_marpaESLIFJSONEncodeRepresentationDisposev";
  marpaESLIFValueResult_t                      *dstp;
  marpaESLIFJSONDecodeDepositCallbackContext_t *marpaESLIFJSONDecodeDepositCallbackContextp;
  short                                         rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  dstp = (marpaESLIFValueResult_t *) malloc(sizeof(marpaESLIFValueResult_t));
  if (MARPAESLIF_UNLIKELY(dstp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  *dstp = marpaESLIFValueResultUndef;
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated destination dstp to %p, initialized to UNDEF", dstp);

  marpaESLIFJSONDecodeDepositCallbackContextp = (marpaESLIFJSONDecodeDepositCallbackContext_t *) malloc(sizeof(marpaESLIFJSONDecodeDepositCallbackContext_t));
  if (MARPAESLIF_UNLIKELY(marpaESLIFJSONDecodeDepositCallbackContextp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Allocated callback context to %p", marpaESLIFJSONDecodeDepositCallbackContextp);

  marpaESLIFJSONDecodeDepositCallbackContextp->marpaESLIFJSONDecodeContextp = marpaESLIFJSONDecodeContextp;
  marpaESLIFJSONDecodeDepositCallbackContextp->keyb                         = 1;
  marpaESLIFJSONDecodeDepositCallbackContextp->allocl                       = 0;
      
  depositp->dstp             = dstp;
  depositp->contextp         = marpaESLIFJSONDecodeDepositCallbackContextp;
  depositp->actionp          = actionp;

  rcb = 1;
  goto done;

 err:
  if (dstp != NULL) {
    free(dstp);
  }
  rcb = 0;
  /* marpaESLIFJSONDecodeDepositCallbackContextp cannot be NULL if we are in err */

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline void _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit_t *depositp)
/*****************************************************************************/
{
  static const char *funcs = "_marpaESLIFJSONDecodeDepositDisposev";

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  if (depositp->contextp != NULL) {
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Freeing deposit context %p", depositp->contextp);
    free(depositp->contextp);
  }
  if (depositp->dstp != NULL) {
    if (depositp->dstp->type != MARPAESLIF_VALUE_TYPE_UNDEF) {
      MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Freeing deposit dstp %p content", depositp->dstp);
      _marpaESLIFRecognizer_marpaESLIFValueResult_freeb(marpaESLIFRecognizerp, depositp->dstp, 1 /* deepb */);
    }
    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Freeing deposit dstp %p", depositp->dstp);
    free(depositp->dstp);
  }

  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "return");
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
}

/*****************************************************************************/
static short _marpaESLIFJSONEncodeValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONEncodeValueResultImportb";
  marpaESLIFJSONEncodeContext_t *marpaESLIFJSONEncodeContextp = (marpaESLIFJSONEncodeContext_t *) userDatavp;

  /* Proxy to user-defined importb */
  return marpaESLIFJSONEncodeContextp->marpaESLIFValueOptionp->importerp(marpaESLIFValuep,
                                                                         marpaESLIFJSONEncodeContextp->marpaESLIFValueOptionp->userDatavp,
                                                                         marpaESLIFValueResultp,
                                                                         haveUndefb);
}

/*****************************************************************************/
static short _marpaESLIFJSONEncodeRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONEncodeRepresentationb";
  marpaESLIFJSONEncodeContext_t *marpaESLIFJSONEncodeContextp = (marpaESLIFJSONEncodeContext_t *) userDatavp;
  marpaESLIFValueOption_t       *marpaESLIFValueOptionp       = marpaESLIFJSONEncodeContextp->marpaESLIFValueOptionp;
  short                          rcb;

  /* Proxy to caller's representation */
  rcb = marpaESLIFValueResultp->representationp(marpaESLIFValueOptionp->userDatavp,
                                                marpaESLIFValueResultp,
                                                inputcpp,
                                                inputlp,
                                                encodingasciisp,
                                                &(marpaESLIFJSONEncodeContextp->representationDisposep),
                                                stringbp);

  *disposeCallbackpp = _marpaESLIFJSONEncodeRepresentationDisposev;

  return rcb;
}

/*****************************************************************************/
static void _marpaESLIFJSONEncodeRepresentationDisposev(void *userDatavp, char *inputcp, size_t inputl, char *encodingasciis)
/*****************************************************************************/
{
  static const char             *funcs                        = "_marpaESLIFJSONEncodeRepresentationDisposev";
  marpaESLIFJSONEncodeContext_t *marpaESLIFJSONEncodeContextp = (marpaESLIFJSONEncodeContext_t *) userDatavp;
  marpaESLIFValueOption_t       *marpaESLIFValueOptionp       = marpaESLIFJSONEncodeContextp->marpaESLIFValueOptionp;

  /* Proxy to caller's representation disposer */
  if (marpaESLIFJSONEncodeContextp->representationDisposep != NULL) {
    marpaESLIFJSONEncodeContextp->representationDisposep(marpaESLIFValueOptionp->userDatavp,
                                                         inputcp,
                                                         inputl,
                                                         encodingasciis);
  }
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeObjectOpeningb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodeRegexCallbackb";
  marpaESLIFJSONDecodeDeposit_t  marpaESLIFJSONDecodeDeposit;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* Increase level */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeIncb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp))) {
    goto err;
  }

  /* Create an object container and push it */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositInitb(marpaESLIFRecognizerp,
                                                              marpaESLIFJSONDecodeContextp,
                                                              &marpaESLIFJSONDecodeDeposit,
                                                              _marpaESLIFJSONDecodeSetHashCallbackv))) {
    goto err;
  }
  /* Initialize the container */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFJSONDecodeDeposit.actionp(marpaESLIFRecognizerp, marpaESLIFJSONDecodeDeposit.contextp, marpaESLIFJSONDecodeDeposit.dstp, NULL))) {
    _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);
    goto err;
  }

  /* Remember the container */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackPushb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit))) {
    _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeObjectClosingb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodeObjectClosingb";
  marpaESLIFJSONDecodeDeposit_t  marpaESLIFJSONDecodeDeposit;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* Decrease level */
  if (MARPAESLIF_UNLIKELY(MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDecb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp)))) {
    goto err;
  }

  /* Pop container and propage current value to it */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackPopb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit.dstp))) {
    goto err;
  }

  /* Clean deposit - by definition _marpaESLIFJSONDecodePropagateValueb, when successfull, changes marpaESLIFJSONDecodeDeposit.dstp->type to MARPAESLIF_VALUE_TYPE_UNDEF */
  _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeArrayOpeningb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodeArrayOpeningb";
  marpaESLIFJSONDecodeDeposit_t  marpaESLIFJSONDecodeDeposit;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* Increase level */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeIncb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp))) {
    goto err;
  }

  /* Create an object container and push it */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositInitb(marpaESLIFRecognizerp,
                                                              marpaESLIFJSONDecodeContextp,
                                                              &marpaESLIFJSONDecodeDeposit,
                                                              _marpaESLIFJSONDecodePushRowCallbackv))) {
    goto err;
  }

  /* Initialize the container */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFJSONDecodeDeposit.actionp(marpaESLIFRecognizerp, marpaESLIFJSONDecodeDeposit.contextp, marpaESLIFJSONDecodeDeposit.dstp, NULL))) {
    _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);
    goto err;
  }

  /* Remember the container */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackPushb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit))) {
    _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIFJSONDecodeArrayClosingb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFJSONDecodeContext_t *marpaESLIFJSONDecodeContextp)
/*****************************************************************************/
{
  static const char             *funcs = "_marpaESLIFJSONDecodeArrayClosingb";
  marpaESLIFJSONDecodeDeposit_t  marpaESLIFJSONDecodeDeposit;
  short                          rcb;

  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_INC(marpaESLIFRecognizerp);
  MARPAESLIFRECOGNIZER_TRACE(marpaESLIFRecognizerp, funcs, "start");

  /* Decrease level */
  if (MARPAESLIF_UNLIKELY(MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDecb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp)))) {
    goto err;
  }

  /* Pop container and propage current value to it */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodeDepositStackPopb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFJSONDecodePropagateValueb(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, marpaESLIFJSONDecodeDeposit.dstp))) {
    goto err;
  }

  /* Clean deposit - by definition _marpaESLIFJSONDecodePropagateValueb, when successfull, changes marpaESLIFJSONDecodeDeposit.dstp->type to MARPAESLIF_VALUE_TYPE_UNDEF */
  _marpaESLIFJSONDecodeDepositDisposev(marpaESLIFRecognizerp, marpaESLIFJSONDecodeContextp, &marpaESLIFJSONDecodeDeposit);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "return %d", (int) rcb);
  MARPAESLIFRECOGNIZER_CALLSTACKCOUNTER_DEC(marpaESLIFRecognizerp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONDecodeSymbolImportProxyb(marpaESLIFSymbol_t *marpaESLIFSymbolp, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb)
/*****************************************************************************/
/* We want to proxy the the internal JSON Decoder recognizer.                */
/*****************************************************************************/
{
  return _marpaESLIFRecognizer_importb((marpaESLIFRecognizer_t *) userDatavp, marpaESLIFValueResultp);
}

