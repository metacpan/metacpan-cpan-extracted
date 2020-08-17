#include <locale.h>
#include <stdlib.h>

#undef  FILENAMES
#define FILENAMES "json.c" /* For logging */

static short                                _marpaESLIFJSONReaderb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp);
static marpaESLIFRecognizerEventCallback_t  _marpaESLIFJSONRecognizerEventActionResolverp(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static short                                _marpaESLIFJSONRecognizerEventCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short                                _marpaESLIFJSON_incb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short                                _marpaESLIFJSON_decb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static marpaESLIFValueRuleCallback_t        _marpaESLIFJSONValueRuleActionResolverp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static short                                _marpaESLIFJSONValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static short                                _marpaESLIFJSON_membersb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_numberb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_unicodeb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_positive_infinityb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_negative_infinityb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_positive_nanb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_negative_nanb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                                _marpaESLIFJSON_proposalb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFJSONProposalAction_t proposalp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static short                                _marpaESLIFJSONRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp);

typedef struct marpaESLIFJSONContext {
  size_t                        currentDepthl;
  marpaESLIFJSONDecodeOption_t *marpaESLIFJSONDecodeOptionp;
  marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp;
  marpaESLIFValueOption_t      *marpaESLIFValueOptionp;
  /* For number parsing, we are unfortunately dependant on locale */
  char                          decimalPointc;
} marpaESLIFJSONContext_t;

static const char *marpaESLIFJSON_encode_extended_grammars =
  "input ::= INPUT action => ::jsonf\n"
  "INPUT   ~ [\\s\\S]\n"
  ;

static const char *marpaESLIFJSON_decode_extended_grammars =
  "#\n"
  "# Default action is to propagate the first RHS value\n"
  "#\n"
  ":default ::= action => ::shift event-action => marpaESLIFJsonEventAction fallback-encoding => UTF-8\n"
  "\n"
  "                   #######################################################\n"
  "                   # >>>>>>>>>>>>>>>> Strict JSON Grammar <<<<<<<<<<<<<<<<\n"
  "                   #######################################################\n"
  "\n"
  "# ----------------\n"
  "# Start is a value\n"
  "# ----------------\n"
  ":start ::= value\n"
  "\n"
  "# -------------------\n"
  "# Composite separator\n"
  "# -------------------\n"
  "comma    ::= ','                                                                    action          => ::undef  # Never needed in any case\n"
  "\n"
  "# ----------\n"
  "# JSON value\n"
  "# ----------\n"
  "value    ::= string\n"
  "           | number\n"
  "           | object\n"
  "           | array\n"
  "           | 'true'                                                                 action         => ::true\n"
  "           | 'false'                                                                action         => ::false\n"
  "           | 'null'                                                                 action         => ::undef\n"
  "\n"
  "# -----------\n"
  "# JSON object\n"
  "# -----------\n"
  "object   ::= '{' members '}'                                                        action         => ::copy[1]\n"
  "members  ::= pairs*                                                                 action         => members   # Returns { @{pair1}, ..., @{pair2} }\n"
  "                                                                                    separator      => commas    # ... separated by comma(s)\n"
  "                                                                                    proper         => 0         # ... with eventual trailing separator\n"
  "                                                                                    hide-separator => 1         # ... and hide separator in the action\n"
  "\n"
  "pairs    ::= string (-':'-) value                                                   action         => ::row     # Returns [ string, value ]\n"
  "\n"
  "# -----------\n"
  "# JSON Arrays\n"
  "# -----------\n"
  "array    ::= '[' elements ']'                                                       action         => ::copy[1] # Returns elements\n"
  "elements ::= value*                                                                 action         => ::row     # Returns [ value1, ..., valuen ]\n"
  "                                                                                    separator      => commas    # ... separated by comma(s)\n"
  "                                                                                    proper         => 0        # ... with eventual trailing separator\n"
  "                                                                                    hide-separator => 1         # ... and hide separator in the action\n"
  "\n"
  "# -----------\n"
  "# JSON Number\n"
  "# -----------\n"
  "number ::= /-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/                  action => number\n"
  "\n"
  "# -----------\n"
  "# JSON String\n"
  "# -----------\n"
  "string ::= (- '\"' -) chars (- '\"' -)                                              action => ::convert[UTF-8]\n"
  "\n"
  ":terminal ::= '\"' pause => after event => :discard[switch]\n"
  "\n"
  "chars   ::= filled\n"
  "filled  ::= char+                                                                   action => ::concat\n"
  "chars   ::=                                                                         action => ::u8\"\"\n"
  "char    ::= /[^\"\\\\\\x00-\\x1F]+/                                                 # ::shift (default action) - take care PCRE2 [:cntrl:] includes DEL character\n"
  "          | '\\\\' '\"'                             action => ::copy[1]             # Returns double quote, already ok in data\n"
  "          | '\\\\' '\\\\'                           action => ::copy[1]             # Returns backslash, already ok in data\n"
  "          | '\\\\' '/'                              action => ::copy[1]             # Returns slash, already ok in data\n"
  "          | '\\\\' 'b'                              action => ::u8\"\\x{08}\"\n"
  "          | '\\\\' 'f'                              action => ::u8\"\\x{0C}\"\n"
  "          | '\\\\' 'n'                              action => ::u8\"\\x{0A}\"\n"
  "          | '\\\\' 'r'                              action => ::u8\"\\x{0D}\"\n"
  "          | '\\\\' 't'                              action => ::u8\"\\x{09}\"\n"
  "          | /(?:\\\\u[[:xdigit:]]{4})+/             action => unicode\n"
  "\n"
  "# -------------------------\n"
  "# Unsignificant whitespaces\n"
  "# -------------------------\n"
  ":discard ::= /[\\x{9}\\x{A}\\x{D}\\x{20}]+/\n"
  "\n"
  "# --------------------------\n"
  "# Unlimited commas extension\n"
  "# --------------------------\n"
  "commas   ::= comma+\n"
  "\n"
  "# --------------------------\n"
  "# Perl comment extension\n"
  "# --------------------------\n"
  ":discard ::= /(?:(?:#)(?:[^\\n]*)(?:\\n|\\z))/u\n"
  "\n"
  "# --------------------------\n"
  "# C++ comment extension\n"
  "# --------------------------\n"
  ":discard ::= /(?:(?:(?:\\/\\/)(?:[^\\n]*)(?:\\n|\\z))|(?:(?:\\/\\*)(?:(?:[^\\*]+|\\*(?!\\/))*)(?:\\*\\/)))/\n"
  "\n"
  "# --------------------------\n"
  "# Max depth limit (does not change the grammar)\n"
  "# --------------------------\n"
  ":terminal ::= '[' pause => after event => inc[]\n"
  ":terminal ::= ']' pause => after event => dec[]\n"
  ":terminal ::= '{' pause => after event => inc[]\n"
  ":terminal ::= '}' pause => after event => dec[]\n"
  "\n"
  "# ----------------\n"
  "# Infinity extension\n"
  "# ----------------\n"
  "number   ::= '-Infinity':i                                     action => negative_infinity\n"
  "           | '-Inf':i                                          action => negative_infinity\n"
  "           | '+Infinity':i                                     action => positive_infinity\n"
  "           | '+Inf':i                                          action => positive_infinity\n"
  "           | 'Infinity':i                                      action => positive_infinity\n"
  "           | 'Inf':i                                           action => positive_infinity\n"
  "\n"
  "# ----------------\n"
  "# Nan extension\n"
  "# ----------------\n"
  "number   ::= '-NaN':i                                          action => negative_nan\n"
  "           | 'NaN':i                                           action => positive_nan\n"
  "           | '+NaN':i                                          action => positive_nan\n"
  "\n"
  "# -----------------\n"
  "# Control character\n"
  "# -----------------\n"
  "char      ::= /[\\x00-\\x1F]/                                                          # Because [:cntrl:] includes DEL (x7F)\n"
  "\n"
  ;

static const char *marpaESLIFJSON_encode_strict_grammars =
  "input ::= INPUT action => ::json\n"
  "INPUT   ~ [\\s\\S]\n"
  ;
static const char *marpaESLIFJSON_decode_strict_grammars =
  "#\n"
  "# Default action is to propagate the first RHS value\n"
  "#\n"
  ":default ::= action => ::shift event-action => marpaESLIFJsonEventAction fallback-encoding => UTF-8\n"
  "\n"
  "                   #######################################################\n"
  "                   # >>>>>>>>>>>>>>>> Strict JSON Grammar <<<<<<<<<<<<<<<<\n"
  "                   #######################################################\n"
  "\n"
  "# ----------------\n"
  "# Start is a value\n"
  "# ----------------\n"
  ":start ::= value\n"
  "\n"
  "# -------------------\n"
  "# Composite separator\n"
  "# -------------------\n"
  "comma    ::= ','                                                                    action          => ::undef  # Never needed in any case\n"
  "\n"
  "# ----------\n"
  "# JSON value\n"
  "# ----------\n"
  "value    ::= string\n"
  "           | number\n"
  "           | object\n"
  "           | array\n"
  "           | 'true'                                                                 action         => ::true\n"
  "           | 'false'                                                                action         => ::false\n"
  "           | 'null'                                                                 action         => ::undef\n"
  "\n"
  "# -----------\n"
  "# JSON object\n"
  "# -----------\n"
  "object   ::= '{' members '}'                                                        action         => ::copy[1]\n"
  "members  ::= pairs*                                                                 action         => members   # Returns { @{pair1}, ..., @{pair2} }\n"
  "                                                                                    separator      => comma     # ... separated by comma\n"
  "                                                                                    proper         => 1         # ... with no trailing separator\n"
  "                                                                                    hide-separator => 1         # ... and hide separator in the action\n"
  "\n"
  "pairs    ::= string (-':'-) value                                                   action         => ::row     # Returns [ string, value ]\n"
  "\n"
  "# -----------\n"
  "# JSON Arrays\n"
  "# -----------\n"
  "array    ::= '[' elements ']'                                                       action         => ::copy[1] # Returns elements\n"
  "elements ::= value*                                                                 action         => ::row     # Returns [ value1, ..., valuen ]\n"
  "                                                                                    separator      => comma     # ... separated by comma\n"
  "                                                                                    proper         => 1         # ... with no trailing separator\n"
  "                                                                                    hide-separator => 1         # ... and hide separator in the action\n"
  "\n"
  "# -----------\n"
  "# JSON Number\n"
  "# -----------\n"
  "number ::= /-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/                  action => number\n"
  "\n"
  "# -----------\n"
  "# JSON String\n"
  "# -----------\n"
  "string ::= (- '\"' -) chars (- '\"' -)                                              action => ::convert[UTF-8]\n"
  "\n"
  ":terminal ::= '\"' pause => after event => :discard[switch]\n"
  "\n"
  "chars   ::= filled\n"
  "filled  ::= char+                                                                   action => ::concat\n"
  "chars   ::=                                                                         action => ::u8\"\"\n"
  "char    ::= /[^\"\\\\\\x00-\\x1F]+/                                                 # ::shift (default action) - take care PCRE2 [:cntrl:] includes DEL character\n"
  "          | '\\\\' '\"'                             action => ::copy[1]             # Returns double quote, already ok in data\n"
  "          | '\\\\' '\\\\'                           action => ::copy[1]             # Returns backslash, already ok in data\n"
  "          | '\\\\' '/'                              action => ::copy[1]             # Returns slash, already ok in data\n"
  "          | '\\\\' 'b'                              action => ::u8\"\\x{08}\"\n"
  "          | '\\\\' 'f'                              action => ::u8\"\\x{0C}\"\n"
  "          | '\\\\' 'n'                              action => ::u8\"\\x{0A}\"\n"
  "          | '\\\\' 'r'                              action => ::u8\"\\x{0D}\"\n"
  "          | '\\\\' 't'                              action => ::u8\"\\x{09}\"\n"
  "          | /(?:\\\\u[[:xdigit:]]{4})+/             action => unicode\n"
  "\n"
  "# -------------------------\n"
  "# Unsignificant whitespaces\n"
  "# -------------------------\n"
  ":discard ::= /[\\x{9}\\x{A}\\x{D}\\x{20}]+/\n"
  "\n"
  "# --------------------------\n"
  "# Max depth limit (does not change the grammar)\n"
  "# --------------------------\n"
  ":terminal ::= '[' pause => after event => inc[]\n"
  ":terminal ::= ']' pause => after event => dec[]\n"
  ":terminal ::= '{' pause => after event => inc[]\n"
  ":terminal ::= '}' pause => after event => dec[]\n"
  "\n"
  ;

#define MARPAESLIFJSON_DST_OR_VALCHAR(dst, valchar) do {                \
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
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported hexadecimal character '%c' (0x%lx)", _valchar, (unsigned long) _valchar); \
      goto err;                                                         \
    }                                                                   \
  } while (0)

/*****************************************************************************/
static inline marpaESLIFGrammar_t *_marpaESLIFJSON_decode_newp(marpaESLIF_t *marpaESLIFp, short strictb)
/*****************************************************************************/
{
  marpaESLIFGrammar_t       *marpaESLIFJSONp             = NULL;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;

  if (marpaESLIFp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFGrammarOption.bytep     = strictb ? (char *) marpaESLIFJSON_decode_strict_grammars : (char *) marpaESLIFJSON_decode_extended_grammars;
  marpaESLIFGrammarOption.bytel     = strlen(marpaESLIFGrammarOption.bytep);
  marpaESLIFGrammarOption.encodings = "ASCII";
  marpaESLIFGrammarOption.encodingl = 5; /* strlen("ASCII") */

  marpaESLIFJSONp = _marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption, NULL /* marpaESLIfGrammarPreviousp */);
  if (marpaESLIFJSONp == NULL) {
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
static inline marpaESLIFGrammar_t *_marpaESLIFJSON_encode_newp(marpaESLIF_t *marpaESLIFp, short strictb)
/*****************************************************************************/
{
  marpaESLIFGrammar_t       *marpaESLIFJSONp             = NULL;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;

  if (marpaESLIFp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFGrammarOption.bytep     = strictb ? (char *) marpaESLIFJSON_encode_strict_grammars : (char *) marpaESLIFJSON_encode_extended_grammars;
  marpaESLIFGrammarOption.bytel     = strlen(marpaESLIFGrammarOption.bytep);
  marpaESLIFGrammarOption.encodings = "ASCII";
  marpaESLIFGrammarOption.encodingl = 5; /* strlen("ASCII") */

  marpaESLIFJSONp = _marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption, NULL /* marpaESLIFGrammarPreviousp */);
  if (marpaESLIFJSONp == NULL) {
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
short marpaESLIFJSON_decodeb(marpaESLIFGrammar_t *marpaESLIFGrammarJSONp, marpaESLIFJSONDecodeOption_t *marpaESLIFJSONDecodeOptionp, marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp, marpaESLIFValueOption_t *marpaESLIFValueOptionp)
/*****************************************************************************/
{
  marpaESLIFRecognizer_t       *marpaESLIFRecognizerp = NULL;
  marpaESLIFValue_t            *marpaESLIFValuep      = NULL;
  short                         rcb;
  marpaESLIFRecognizerOption_t  marpaESLIFRecognizerOption;
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  marpaESLIFJSONContext_t       marpaESLIFJSONContext;
  short                         continueb;

  if ((marpaESLIFGrammarJSONp == NULL) || (marpaESLIFJSONDecodeOptionp == NULL) || (marpaESLIFRecognizerOptionp == NULL) || (marpaESLIFRecognizerOptionp->readerCallbackp == NULL) || (marpaESLIFValueOptionp == NULL)) {
    errno = EINVAL;
    goto err;
  }

  /* Whatever happens, we take entire control on the callbacks so that we have our own context on top of it */
  marpaESLIFJSONContext.currentDepthl               = 0;
  marpaESLIFJSONContext.marpaESLIFJSONDecodeOptionp = marpaESLIFJSONDecodeOptionp;
  marpaESLIFJSONContext.marpaESLIFRecognizerOptionp = marpaESLIFRecognizerOptionp;
  marpaESLIFJSONContext.marpaESLIFValueOptionp      = marpaESLIFValueOptionp;
  marpaESLIFJSONContext.decimalPointc               = MARPAESLIF_DECIMAL_POINT(marpaESLIFGrammarJSONp->marpaESLIFp);

  marpaESLIFRecognizerOption                      = *marpaESLIFRecognizerOptionp;
  marpaESLIFRecognizerOption.userDatavp           = &marpaESLIFJSONContext;
  marpaESLIFRecognizerOption.readerCallbackp      = _marpaESLIFJSONReaderb;
  marpaESLIFRecognizerOption.ifActionResolverp    = NULL; /* Our grammar has no if-action anyway */
  marpaESLIFRecognizerOption.eventActionResolverp = _marpaESLIFJSONRecognizerEventActionResolverp;

  marpaESLIFValueOption                           = *marpaESLIFValueOptionp;
  marpaESLIFValueOption.userDatavp                = &marpaESLIFJSONContext;
  marpaESLIFValueOption.ruleActionResolverp       = _marpaESLIFJSONValueRuleActionResolverp;
  marpaESLIFValueOption.symbolActionResolverp     = NULL; /* We use the default "::transfer" */
  marpaESLIFValueOption.importerp                 = ((marpaESLIFValueOptionp != NULL) && (marpaESLIFValueOptionp->importerp != NULL)) ? _marpaESLIFJSONValueResultImportb : NULL;
  marpaESLIFValueOption.highRankOnlyb             = 1; /* Fixed */
  marpaESLIFValueOption.orderByRankb              = 1; /* Fixed */
  marpaESLIFValueOption.ambiguousb                = 0; /* Fixed */
  marpaESLIFValueOption.nullb                     = 0; /* Fixed */
  marpaESLIFValueOption.maxParsesi                = 0; /* Fixed */

  if (marpaESLIFJSONDecodeOptionp->maxDepthl == 0) {
    /* No need of any event: the grammar parse method is the fastest */
    rcb = marpaESLIFGrammar_parseb(marpaESLIFGrammarJSONp, &marpaESLIFRecognizerOption, &marpaESLIFValueOption, NULL /* exhaustedbp */);
    goto done;
  }

  /* We need to loop using a recognizer to catch the events */
  marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(marpaESLIFGrammarJSONp, &marpaESLIFRecognizerOption);
  if (marpaESLIFRecognizerp == NULL) {
    goto err;
  }
  if (! marpaESLIFRecognizer_scanb(marpaESLIFRecognizerp, 1 /* initialEventsb */, &continueb, NULL /* exhaustedbp */)) {
    goto err;
  }
  while (continueb) {
    if (! marpaESLIFRecognizer_resumeb(marpaESLIFRecognizerp, 0 /* deltaLengthl */, &continueb, NULL /* exhaustedbp */)) {
      goto err;
    }
  }
  marpaESLIFValuep = marpaESLIFValue_newp(marpaESLIFRecognizerp, &marpaESLIFValueOption);
  if (marpaESLIFValuep == NULL) {
    goto err;
  }
  /* Set-up proxy representation */
  marpaESLIFValuep->proxyRepresentationp = _marpaESLIFJSONRepresentationb;
  if (! marpaESLIFValue_valueb(marpaESLIFValuep)) {
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
short marpaESLIFJSON_encodeb(marpaESLIFGrammar_t *marpaESLIFGrammarJSONp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueOption_t *marpaESLIFValueOptionp)
/*****************************************************************************/
/* Strict or not, encode grammar is always at level 10                       */
/*****************************************************************************/
{
  marpaESLIFRecognizer_t       *marpaESLIFRecognizerp = NULL;
  marpaESLIFValue_t            *marpaESLIFValuep      = NULL;
  short                         rcb;
  marpaESLIFAlternative_t       marpaESLIFAlternative;
  marpaESLIFValueOption_t       marpaESLIFValueOption;
  marpaESLIFJSONContext_t       marpaESLIFJSONContext;

  if ((marpaESLIFGrammarJSONp == NULL) || (marpaESLIFValueResultp == NULL) || (marpaESLIFValueOptionp == NULL)) {
    errno = EINVAL;
    goto err;
  }

  marpaESLIFJSONContext.currentDepthl               = 0; /* Not used */
  marpaESLIFJSONContext.marpaESLIFJSONDecodeOptionp = NULL; /* Not used */
  marpaESLIFJSONContext.marpaESLIFRecognizerOptionp = NULL; /* Not used */
  marpaESLIFJSONContext.marpaESLIFValueOptionp      = marpaESLIFValueOptionp;
  marpaESLIFJSONContext.decimalPointc               = '.'; /* Not used */

  marpaESLIFValueOption                           = *marpaESLIFValueOptionp;
  marpaESLIFValueOption.userDatavp                = &marpaESLIFJSONContext;
  marpaESLIFValueOption.ruleActionResolverp       = NULL; /* Not used */
  marpaESLIFValueOption.symbolActionResolverp     = NULL; /* We use the native ::transfer action */
  marpaESLIFValueOption.importerp                 = ((marpaESLIFValueOptionp != NULL) && (marpaESLIFValueOptionp->importerp != NULL)) ? _marpaESLIFJSONValueResultImportb : NULL;
  marpaESLIFValueOption.highRankOnlyb             = 1; /* Fixed */
  marpaESLIFValueOption.orderByRankb              = 1; /* Fixed */
  marpaESLIFValueOption.ambiguousb                = 0; /* Fixed */
  marpaESLIFValueOption.nullb                     = 0; /* Fixed */
  marpaESLIFValueOption.maxParsesi                = 0; /* Fixed */

  marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(marpaESLIFGrammarJSONp, NULL);
  if (marpaESLIFRecognizerp == NULL) {
    goto err;
  }

  /* Insert a lexeme with length 0 in the input, though length 1 in the grammar */
  marpaESLIFAlternative.lexemes        = "INPUT";
  marpaESLIFAlternative.value          = *marpaESLIFValueResultp;
  marpaESLIFAlternative.grammarLengthl = 1;
  if (! marpaESLIFRecognizer_lexeme_readb(marpaESLIFRecognizerp, &marpaESLIFAlternative, 0 /* lengthl */)) {
    goto err;
  }
  marpaESLIFValuep = marpaESLIFValue_newp(marpaESLIFRecognizerp, &marpaESLIFValueOption);
  /* Set-up proxy representation */
  marpaESLIFValuep->proxyRepresentationp = _marpaESLIFJSONRepresentationb;
  if (marpaESLIFValuep == NULL) {
    goto err;
  }
  if (! marpaESLIFValue_valueb(marpaESLIFValuep)) {
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
static short _marpaESLIFJSONReaderb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t      *marpaESLIFJSONContextp      = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp = marpaESLIFJSONContextp->marpaESLIFRecognizerOptionp;

  /* Proxy to caller's recognizer */
  return marpaESLIFRecognizerOptionp->readerCallbackp(marpaESLIFRecognizerOptionp->userDatavp, inputcpp, inputlp, eofbp, characterStreambp, encodingsp, encodinglp);
}

/*****************************************************************************/
static marpaESLIFRecognizerEventCallback_t _marpaESLIFJSONRecognizerEventActionResolverp(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  marpaESLIFRecognizerEventCallback_t  rcp;

  if (strcmp(actions, "marpaESLIFJsonEventAction") == 0) {
    rcp = _marpaESLIFJSONRecognizerEventCallbackb;
  } else {
    MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Unrecognized event-action \"%s\"", actions);
    goto err;
  }

  goto done;

 err:
  rcp = NULL;
  
 done:
  return rcp;
}

/*****************************************************************************/
static short _marpaESLIFJSONRecognizerEventCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  size_t                   i;
  short                    rcb;

  for (i = 0; i < eventArrayl; i++) {
    if (eventArrayp[i].events != NULL) {
      if (strcmp(eventArrayp[i].events, "inc[]") == 0) {
        if (! _marpaESLIFJSON_incb(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultBoolp)) {
          goto err;
        }
      } else if (strcmp(eventArrayp[i].events, "dec[]") == 0) {
        if (! _marpaESLIFJSON_decb(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultBoolp)) {
          goto err;
        }
      } else {
        MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Unrecognized event \"%s\"", eventArrayp[i].events);
        goto err;
      }
    }
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_incb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  size_t                   currentDepthl = marpaESLIFJSONContextp->currentDepthl;

  if (++currentDepthl < marpaESLIFJSONContextp->currentDepthl) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing currentDepthl");
    *marpaESLIFValueResultBoolp = MARPAESLIFVALUERESULTBOOL_FALSE;
  } else {
    marpaESLIFJSONContextp->currentDepthl = currentDepthl;
    if (currentDepthl > marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->maxDepthl) {
      MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "Maximum depth %ld reached", (unsigned long) marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->maxDepthl);
      errno = EINVAL;
      *marpaESLIFValueResultBoolp = MARPAESLIFVALUERESULTBOOL_FALSE;
    } else {
      *marpaESLIFValueResultBoolp = MARPAESLIFVALUERESULTBOOL_TRUE;
    }
  }

  return 1;
}

/*****************************************************************************/
static short _marpaESLIFJSON_decb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  size_t                   currentDepthl = marpaESLIFJSONContextp->currentDepthl;

  if (--currentDepthl > marpaESLIFJSONContextp->currentDepthl) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "size_t turnaround when computing currentDepthl");
    *marpaESLIFValueResultBoolp = MARPAESLIFVALUERESULTBOOL_FALSE;
    errno = EINVAL;
  } else {
    marpaESLIFJSONContextp->currentDepthl = currentDepthl;
    *marpaESLIFValueResultBoolp = MARPAESLIFVALUERESULTBOOL_TRUE;
  }

  return 1;
}

/*****************************************************************************/
static marpaESLIFValueRuleCallback_t _marpaESLIFJSONValueRuleActionResolverp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t       *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueRuleCallback_t  rcp;

  if (strcmp(actions, "members") == 0) {
    rcp = _marpaESLIFJSON_membersb;
  } else if (strcmp(actions, "number") == 0) {
    rcp = _marpaESLIFJSON_numberb;
  } else if (strcmp(actions, "unicode") == 0) {
    rcp = _marpaESLIFJSON_unicodeb;
  } else if (strcmp(actions, "positive_infinity") == 0) {
    rcp = _marpaESLIFJSON_positive_infinityb;
  } else if (strcmp(actions, "negative_infinity") == 0) {
    rcp = _marpaESLIFJSON_negative_infinityb;
  } else if (strcmp(actions, "positive_nan") == 0) {
    rcp = _marpaESLIFJSON_positive_nanb;
  } else if (strcmp(actions, "negative_nan") == 0) {
    rcp = _marpaESLIFJSON_negative_nanb;
  } else {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unrecognized action \"%s\"", actions);
    goto err;
  }

  goto done;

 err:
  rcp = NULL;
  
 done:
  return rcp;
}

/*****************************************************************************/
static short _marpaESLIFJSON_membersb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* members  ::= pairs* action => members   # Returns { @{pair1}, ..., @{pair2} } */
  marpaESLIFJSONContext_t       *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  short                          disallowDupkeysb       = marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->disallowDupkeysb;
  marpaESLIFValueResult_t        marpaESLIFValueResult;
  marpaESLIFValueResult_t       *marpaESLIFValueResultp;
  int                            i;
  int                            j;
  int                            currentTableIndicei;
  short                         *origshallowbp[2];
  short                          rcb;
  marpaESLIFValueResultString_t *previousKeyp;
  marpaESLIFValueResultString_t *currentKeyp;
  marpaESLIF_string_t           *stringp;

  marpaESLIFValueResult.type               = MARPAESLIF_VALUE_TYPE_TABLE;
  marpaESLIFValueResult.contextp           = NULL;
  marpaESLIFValueResult.representationp    = NULL;
  marpaESLIFValueResult.u.t.p              = NULL;
  marpaESLIFValueResult.u.t.freeUserDatavp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFValueResult.u.t.freeCallbackp  = _marpaESLIF_generic_freeCallbackv;
  marpaESLIFValueResult.u.t.shallowb       = 0;
  marpaESLIFValueResult.u.t.sizel          = 0;

  /* We receive a list of rows that we want to flatten */
  if ((! nullableb) && (argni >= arg0i)) {
    marpaESLIFValueResult.u.t.sizel = argni - arg0i + 1;
    marpaESLIFValueResult.u.t.p = (marpaESLIFValueResultPair_t *) malloc(marpaESLIFValueResult.u.t.sizel * sizeof(marpaESLIFValueResultPair_t));
    if (marpaESLIFValueResult.u.t.p == NULL) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }

    for (i = arg0i, currentTableIndicei = 0; i<= argni; i++, currentTableIndicei++) {
      marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, i);
      if (marpaESLIFValueResultp == NULL) {
        goto err;
      }

      /* No need to check that - this is ok per definition */
      /*
      if (marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_ROW) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not ROW (got %d, %s)", marpaESLIFValueResultp->type, _marpaESLIF_value_types(marpaESLIFValueResultp->type));
        goto err;
      }

      if (marpaESLIFValueResultp->u.r.sizel != 2) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "row size is %ld and not 2", (unsigned long) marpaESLIFValueResultp->u.r.sizel);
        goto err;
      }
      */

      /* We have to take care of members's shallow status: the table becomes the owner in any case */
      for (j = 0; j < 2; j++) {
        origshallowbp[j] = NULL;
        switch (marpaESLIFValueResultp->u.r.p[j].type) {
        case MARPAESLIF_VALUE_TYPE_PTR:
          origshallowbp[j] = &(marpaESLIFValueResultp->u.r.p[j].u.p.shallowb);
          break;
        case MARPAESLIF_VALUE_TYPE_ARRAY:
          origshallowbp[j] = &(marpaESLIFValueResultp->u.r.p[j].u.a.shallowb);
          break;
        case MARPAESLIF_VALUE_TYPE_STRING:
          origshallowbp[j] = &(marpaESLIFValueResultp->u.r.p[j].u.s.shallowb);
          break;
        case MARPAESLIF_VALUE_TYPE_ROW:
          origshallowbp[j] = &(marpaESLIFValueResultp->u.r.p[j].u.t.shallowb);
          break;
        case MARPAESLIF_VALUE_TYPE_TABLE:
          origshallowbp[j] = &(marpaESLIFValueResultp->u.r.p[j].u.t.shallowb);
          break;
        default:
          break;
        }
      }

      marpaESLIFValueResult.u.t.p[currentTableIndicei].key   = marpaESLIFValueResultp->u.r.p[0];
      marpaESLIFValueResult.u.t.p[currentTableIndicei].value = marpaESLIFValueResultp->u.r.p[1];

      if (origshallowbp[0] != NULL) {
        *(origshallowbp[0]) = 1;
      }

      if (origshallowbp[1] != NULL) {
        *(origshallowbp[1]) = 1;
      }

      if (disallowDupkeysb && (currentTableIndicei > 0)) {
        /* By definition keys are always strings coming from parsing, i.e. STRING type with encoding UTF-8 */
        currentKeyp = &(marpaESLIFValueResult.u.t.p[currentTableIndicei].key.u.s);
        for (j = 0; j < currentTableIndicei; j++) {
          previousKeyp = &(marpaESLIFValueResult.u.t.p[j].key.u.s);
          if (((previousKeyp->p == NULL) && (currentKeyp->p == NULL))
              ||
              ((previousKeyp->p != NULL) && (currentKeyp->p != NULL)
               &&
               (previousKeyp->sizel == currentKeyp->sizel)
               &&
               (
                (previousKeyp->sizel == 0)
                ||
                (memcmp((char *) previousKeyp->p, (char *) currentKeyp->p, previousKeyp->sizel) == 0)
                )
               )
              ) {
            stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, previousKeyp->encodingasciis, (char *) previousKeyp->p, previousKeyp->sizel);
            if (stringp == NULL) {
              /* Say there is a duplicate key anway */
              MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Duplicate key");
            } else {
              MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Duplicate key %s", stringp->asciis);
              _marpaESLIF_string_freev(stringp, 0 /* onStstackb */);
            }
            goto err;
          }
        }
      }
    }
  }

  if (! _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  if (marpaESLIFValueResult.u.t.p != NULL) {
    free(marpaESLIFValueResult.u.t.p);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_numberb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t            *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
#if defined(C_STRTOD) && defined(MARPAESLIF_HUGE_VAL)
  short                               decimalPointb;
  char                               *decimalPoints;
  char                               *endptrp;
  char                               *endptrendp;
  double                              d;
#endif
  marpaESLIFValueResult_t             marpaESLIFValueResult;
  marpaESLIFValueResult_t            *marpaESLIFValueResultInputp;
  short                               rcb;

  /* Input is of type array by definition, UTF-8 encoded */
  marpaESLIFValueResultInputp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultInputp == NULL) {
    goto err;
  }

  endptrendp = marpaESLIFValueResultInputp->u.a.p + marpaESLIFValueResultInputp->u.a.sizel;

#if defined(C_STRTOD) && defined(MARPAESLIF_HUGE_VAL)
  /* Do we have to change the decimal point representation ? */
  decimalPoints = strchr(marpaESLIFValueResultInputp->u.a.p, '.');
  decimalPointb = ((decimalPoints != NULL) && (*decimalPoints != marpaESLIFJSONContextp->decimalPointc)) ? 1 : 0;
  if (decimalPointb) {
    *decimalPoints = marpaESLIFJSONContextp->decimalPointc;
  }

  endptrp = NULL;
  errno = 0;    /* To distinguish success/failure after call */
  d = C_STRTOD(marpaESLIFValueResultInputp->u.a.p, &endptrp);
  if (! ((endptrp != endptrendp) /* Parsing error */
         ||
         ((errno == ERANGE) && ((d == MARPAESLIF_HUGE_VAL) || (d == -MARPAESLIF_HUGE_VAL))) /* Overflow */
         ||
         ((d == 0.) && (errno != 0)) /* Underflow */
         )) {
    marpaESLIFValueResult.contextp        = NULL;
    marpaESLIFValueResult.representationp = NULL;
    marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_DOUBLE;
    marpaESLIFValueResult.u.d             = d;
  } else {
    marpaESLIFValueResult.contextp        = NULL;
    marpaESLIFValueResult.representationp = NULL;
    marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
  }
  if (decimalPointb) {
    *decimalPoints = '.';
  }
#else /* C_STRTOD && MARPAESLIF_HUGE_VAL */
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
#endif /* C_STRTOD && MARPAESLIF_HUGE_VAL */


  if (! _marpaESLIFJSON_proposalb(userDatavp,
                                  marpaESLIFValuep,
                                  marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->numberActionp,
                                  marpaESLIFValueResultInputp->u.a.p,
                                  marpaESLIFValueResultInputp->u.a.sizel,
                                  &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONValueResultImportb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;

  /* Proxy to user-defined importb */
  return marpaESLIFJSONContextp->marpaESLIFValueOptionp->importerp(marpaESLIFValuep, marpaESLIFJSONContextp->marpaESLIFValueOptionp->userDatavp, marpaESLIFValueResultp);
}

/*****************************************************************************/
static short _marpaESLIFJSON_unicodeb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* char ::= /(?:\\u[[:xdigit:]]{4})+/ action => unicode\n" */
  static const char       *funcs                  = "_marpaESLIFJSON_unicodeb";
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  unsigned char           *dstp                   = NULL;
  size_t                   dstl;
  marpaESLIFValueResult_t *marpaESLIFValueResultp;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIF_uint32_t     *uint32p;
  size_t                   uint32l;
  marpaESLIF_uint32_t      c;
  char                    *p;
  unsigned char           *q;
  size_t                   i;
  size_t                   j;
  short                    rcb;

  /* Input is of type array by definition, UTF-8 encoded, containing only ASCII characters */
  marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultp == NULL) {
    goto err;
  }

  /* It is a sequence of '\uXXXX' by definition, i.e. 6 bytes - so there are (marpaESLIFValueResultp->u.a.sizel / 6) hex digits */
  uint32l = marpaESLIFValueResultp->u.a.sizel / 6;
  uint32p = (marpaESLIF_uint32_t *) malloc(sizeof(marpaESLIF_uint32_t) * uint32l);
  if (uint32p == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  for (i = 0, p = marpaESLIFValueResultp->u.a.p + 2; i < uint32l; i++, p += 2) {
    c = 0;

    MARPAESLIFJSON_DST_OR_VALCHAR(c, *p++);
    c <<= 4;
    MARPAESLIFJSON_DST_OR_VALCHAR(c, *p++);
    c <<= 4;
    MARPAESLIFJSON_DST_OR_VALCHAR(c, *p++);
    c <<= 4;
    MARPAESLIFJSON_DST_OR_VALCHAR(c, *p++);

    uint32p[i] = c;
  }

  /* Worst case is four UTF-8 bytes */
  dstl = uint32l * 4;
  dstp = (unsigned char *) malloc(sizeof(unsigned char) * dstl);
  if (dstp == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  /* Based on efi_utf16_to_utf8 from Linux kernel */
  q = dstp;
  for (i = 0, j = 1; i < uint32l; i++, j++) {
    c = uint32p[i];

    if ((j < uint32l) && (c >= 0xD800) && (c <= 0xDBFF) && (uint32p[j] >= 0xDC00) && (uint32p[j] <= 0xDFFF)) {
      /* Surrogate UTF-16 pair */
      c = 0x10000 + ((c & 0x3FF) << 10) + (uint32p[j] & 0x3FF);
      ++i;
      ++j;
    }

    if ((c >= 0xD800) && (c <= 0xDFFFF)) {
      if (marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->noReplacementCharacterb) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid UTF-16 character \\%c%c%c%c%c", marpaESLIFValueResultp->u.a.p[(i * 6) + 1], marpaESLIFValueResultp->u.a.p[(i * 6) + 2], marpaESLIFValueResultp->u.a.p[(i * 6) + 3], marpaESLIFValueResultp->u.a.p[(i * 6) + 4], marpaESLIFValueResultp->u.a.p[(i * 6) + 5]);
        goto err;
      } else {
        MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Invalid UTF-16 character \\%c%c%c%c%c replaced by 0xFFFD", marpaESLIFValueResultp->u.a.p[(i * 6) + 1], marpaESLIFValueResultp->u.a.p[(i * 6) + 2], marpaESLIFValueResultp->u.a.p[(i * 6) + 3], marpaESLIFValueResultp->u.a.p[(i * 6) + 4], marpaESLIFValueResultp->u.a.p[(i * 6) + 5]);
        c = 0xFFFD; /* Replacement character */
      }
    }

    if (c < 0x80) {
      *q++ = c;
      continue;
    }

    if (c < 0x800) {
      *q++ = 0xC0 + (c >> 6);
      goto t1;
    }

    if (c < 0x10000) {
      *q++ = 0xE0 + (c >> 12);
      goto t2;
    }

    *q++ = 0xF0 + (c >> 18);
    *q++ = 0x80 + ((c >> 12) & 0x3F);
  t2:
    *q++ = 0x80 + ((c >> 6) & 0x3F);
  t1:
    *q++ = 0x80 + (c & 0x3F);
  }

  marpaESLIFValueResult.type               = MARPAESLIF_VALUE_TYPE_STRING;
  marpaESLIFValueResult.contextp           = NULL;
  marpaESLIFValueResult.representationp    = NULL;
  marpaESLIFValueResult.u.s.p              = dstp;
  marpaESLIFValueResult.u.s.sizel          = q - dstp;
  marpaESLIFValueResult.u.s.encodingasciis = (char *) MARPAESLIF_UTF8_STRING;
  marpaESLIFValueResult.u.s.shallowb       = 0;
  marpaESLIFValueResult.u.s.freeUserDatavp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFValueResult.u.s.freeCallbackp  = _marpaESLIF_generic_freeCallbackv;

  if (! _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult)) {
    goto err;
  }

  /* dstp is now managed by ESLIF */
  dstp = NULL;

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (uint32p != NULL) {
    free(uint32p);
  }
  if (dstp != NULL) {
    free(dstp);
  }
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_positive_infinityb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIFValueResult_t *marpaESLIFValueResultInputp;
  short                    rcb;

  /* Input is of type array by definition, UTF-8 encoded */
  marpaESLIFValueResultInputp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultInputp == NULL) {
    goto err;
  }

#ifdef MARPAESLIF_INFINITY
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFValueResult.u.f             = MARPAESLIF_INFINITY;
#else
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
#endif

  if (! _marpaESLIFJSON_proposalb(userDatavp,
                                  marpaESLIFValuep,
                                  marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->positiveInfinityActionp,
                                  marpaESLIFValueResultInputp->u.a.p,
                                  marpaESLIFValueResultInputp->u.a.sizel,
                                  &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_negative_infinityb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIFValueResult_t *marpaESLIFValueResultInputp;
  short                    rcb;

  /* Input is of type array by definition, UTF-8 encoded */
  marpaESLIFValueResultInputp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultInputp == NULL) {
    goto err;
  }

#ifdef MARPAESLIF_INFINITY
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFValueResult.u.f             = -MARPAESLIF_INFINITY;
#else
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
#endif

  if (! _marpaESLIFJSON_proposalb(userDatavp,
                                  marpaESLIFValuep,
                                  marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->negativeInfinityActionp,
                                  marpaESLIFValueResultInputp->u.a.p,
                                  marpaESLIFValueResultInputp->u.a.sizel,
                                  &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_positive_nanb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIFValueResult_t *marpaESLIFValueResultInputp;
  short                    rcb;

  /* Input is of type array by definition, UTF-8 encoded */
  marpaESLIFValueResultInputp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultInputp == NULL) {
    goto err;
  }

#ifdef MARPAESLIF_NAN
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFValueResult.u.f             = MARPAESLIF_NAN;
#else
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
#endif

  if (! _marpaESLIFJSON_proposalb(userDatavp,
                                  marpaESLIFValuep,
                                  marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->positiveNanActionp,
                                  marpaESLIFValueResultInputp->u.a.p,
                                  marpaESLIFValueResultInputp->u.a.sizel,
                                  &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSON_negative_nanb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;
  marpaESLIFValueResult_t  marpaESLIFValueResult;
  marpaESLIFValueResult_t *marpaESLIFValueResultInputp;
  short                    rcb;

  /* Input is of type array by definition, UTF-8 encoded */
  marpaESLIFValueResultInputp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, arg0i);
  if (marpaESLIFValueResultInputp == NULL) {
    goto err;
  }

#ifdef MARPAESLIF_NAN
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_FLOAT;
  marpaESLIFValueResult.u.f             = MARPAESLIF_NAN;
#else
  marpaESLIFValueResult.contextp        = NULL;
  marpaESLIFValueResult.representationp = NULL;
  marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF;
#endif

  if (! _marpaESLIFJSON_proposalb(userDatavp,
                                  marpaESLIFValuep,
                                  marpaESLIFJSONContextp->marpaESLIFJSONDecodeOptionp->negativeNanActionp,
                                  marpaESLIFValueResultInputp->u.a.p,
                                  marpaESLIFValueResultInputp->u.a.sizel,
                                  &marpaESLIFValueResult)) {
    goto err;
  }

  rcb = _marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFJSONRepresentationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;

  /* Proxy to caller's representation */
  return marpaESLIFValueResultp->representationp(marpaESLIFValueOptionp->userDatavp, marpaESLIFValueResultp, inputcpp, inputlp, encodingasciisp);
}

/*****************************************************************************/
static short _marpaESLIFJSON_proposalb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFJSONProposalAction_t proposalp, char *strings, size_t stringl, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  marpaESLIFJSONContext_t *marpaESLIFJSONContextp;
  marpaESLIFValueOption_t *marpaESLIFValueOptionp;
  short                    rcb;

  if (proposalp != NULL) {
    marpaESLIFJSONContextp = (marpaESLIFJSONContext_t *) userDatavp;
    marpaESLIFValueOptionp = marpaESLIFJSONContextp->marpaESLIFValueOptionp;

    if (! proposalp(marpaESLIFValueOptionp->userDatavp, strings, stringl, marpaESLIFValueResultp)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s: Callback failure", strings);
      goto err;
    }
  } else if (marpaESLIFValueResultp->type == MARPAESLIF_VALUE_TYPE_UNDEF) {
    MARPAESLIF_WARNF(marpaESLIFValuep->marpaESLIFp, "%s: Parsing failure, using undefined value", strings);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}
