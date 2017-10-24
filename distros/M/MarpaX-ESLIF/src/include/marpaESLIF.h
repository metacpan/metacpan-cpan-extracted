#ifndef MARPAESLIF_H
#define MARPAESLIF_H

#include <stddef.h>                 /* For size_t */
#include <genericLogger.h>
#include <marpaESLIF/export.h>

typedef struct marpaESLIFOption {
  genericLogger_t *genericLoggerp;  /* Logger. Default: NULL */
} marpaESLIFOption_t;

typedef struct marpaESLIF            marpaESLIF_t;
typedef struct marpaESLIFGrammar     marpaESLIFGrammar_t;
typedef struct marpaESLIFRecognizer  marpaESLIFRecognizer_t;
typedef struct marpaESLIFValue       marpaESLIFValue_t;
typedef struct marpaESLIFSymbol      marpaESLIFSymbol_t;
typedef struct marpaESLIFValueResult marpaESLIFValueResult_t;

/* A string */
typedef struct marpaESLIFString {
  char   *bytep;            /* pointer bytes */
  size_t  bytel;            /* number of bytes */
  char   *encodingasciis;   /* Encoding of bytes, itself being writen in ASCII encoding, NUL byte terminated */
  char   *asciis;           /* ASCII (un-translatable bytes are changed to a replacement character) translation of previous bytes, NUL byte terminated - never NULL if bytep is not NULL */
  /*
   * Remark: the encodings and asciis pointers are not NULL only when ESLIF know that the buffer is associated to a "description". I.e.
   * this is happening ONLY when parsing the grammar. Raw data never have non-NULL asciis or encodings.
   */
} marpaESLIFString_t;

typedef struct marpaESLIFGrammarOption {
  void   *bytep;               /* Input */
  size_t  bytel;               /* Input length in byte unit */
  char   *encodings;           /* Input encoding. Default: NULL */
  size_t  encodingl;           /* Length of encoding itself. Default: 0 */
  char   *encodingOfEncodings; /* Encoding of encoding, in ASCII encoding. Default: NULL. */
} marpaESLIFGrammarOption_t;

/* The reader can return encoding information, giving eventual encoding of this information in encodingOfEncodingsp, starting at *encodingsp, spreaded over *encodinglp bytes */
typedef short (*marpaESLIFReader_t)(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingOfEncodingsp, char **encodingsp, size_t *encodinglp);
typedef struct marpaESLIFRecognizerOption {
  void                *userDatavp;                  /* User specific context */
  marpaESLIFReader_t   marpaESLIFReaderCallbackp;   /* Reader */
  short                disableThresholdb;           /* Default: 0 */
  short                exhaustedb;                  /* Exhaustion event. Default: 0 */
  short                newlineb;                    /* Count line/column numbers. Default: 0 */
  short                trackb;                      /* Track absolute position. Default: 0 */
  size_t               bufsizl;                     /* Minimum stream buffer size: Recommended: 0 (internally, a system default will apply) */
  unsigned int         buftriggerperci;             /* Excess number of bytes, in percentage of bufsizl, where stream buffer size is reduced. Recommended: 50 */
  unsigned int         bufaddperci;                 /* Policy of minimum of bytes for increase, in percentage of current allocated size, when stream buffer size need to augment. Recommended: 50 */
} marpaESLIFRecognizerOption_t;

typedef enum marpaESLIFEventType {
  MARPAESLIF_EVENTTYPE_NONE       = 0x00,
  MARPAESLIF_EVENTTYPE_COMPLETED  = 0x01, /* Grammar event */
  MARPAESLIF_EVENTTYPE_NULLED     = 0x02, /* Grammar event */
  MARPAESLIF_EVENTTYPE_PREDICTED  = 0x04, /* Grammar event */
  MARPAESLIF_EVENTTYPE_BEFORE     = 0x08, /* Just before lexeme is commited */
  MARPAESLIF_EVENTTYPE_AFTER      = 0x10, /* Just after lexeme is commited */
  MARPAESLIF_EVENTTYPE_EXHAUSTED  = 0x20, /* Exhaustion */
  MARPAESLIF_EVENTTYPE_DISCARD    = 0x40  /* Discard */
} marpaESLIFEventType_t;

typedef struct marpaESLIFEvent {
  marpaESLIFEventType_t type;
  char                 *symbols; /* Symbol name, always NULL if exhausted event, always ':discard' if discard event */
  char                 *events;  /* Event name, always NULL if exhaustion eent */
} marpaESLIFEvent_t;

typedef short (*marpaESLIFValueRuleCallback_t)(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
typedef short (*marpaESLIFValueSymbolCallback_t)(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *bytep, size_t bytel, int resulti);
typedef void  (*marpaESLIFValueFreeCallback_t)(void *userDatavp, int contexti, void *p, size_t sizel);

typedef marpaESLIFValueRuleCallback_t   (*marpaESLIFValueRuleActionResolver_t)(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
typedef marpaESLIFValueSymbolCallback_t (*marpaESLIFValueSymbolActionResolver_t)(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
typedef marpaESLIFValueFreeCallback_t   (*marpaESLIFValueFreeActionResolver_t)(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);

/* Value types */
typedef enum marpaESLIFValueType {
  MARPAESLIF_VALUE_TYPE_UNDEF = 0,
  MARPAESLIF_VALUE_TYPE_CHAR,
  MARPAESLIF_VALUE_TYPE_SHORT,
  MARPAESLIF_VALUE_TYPE_INT,
  MARPAESLIF_VALUE_TYPE_LONG,
  MARPAESLIF_VALUE_TYPE_FLOAT,
  MARPAESLIF_VALUE_TYPE_DOUBLE,
  MARPAESLIF_VALUE_TYPE_PTR,
  MARPAESLIF_VALUE_TYPE_ARRAY
} marpaESLIFValueType_t;

/* Valuation result */
/* The representation returns a sequence of bytes and is appended AS-IS */
/* It is legal to return NULL in *inputcpp or 0 in *inputlp: representation will be ignored */
typedef short (*marpaESLIFRepresentation_t)(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp);
struct marpaESLIFValueResult {
  int                        contexti;          /* Free value meaningful only to the user */
  size_t                     sizel;             /* Length of data in case value is an ARRAY - always 0 otherwise */
  marpaESLIFRepresentation_t representationp;   /* How a user-land alternative is represented if it was in the input */
  short                      shallowb;          /* In case of PTR or ARRAY, indicate if this is a shallow pointer */
  marpaESLIFValueType_t      type;              /* Type for tagging the following union */
  union {
    char    c;                                  /* Value is a char */
    short   b;                                  /* Value is a short */
    int     i;                                  /* Value is an int */
    long    l;                                  /* Value is a long */
    float   f;                                  /* Value is a float */
    double  d;                                  /* Value is a double */
    void   *p;                                  /* Value is a pointer */
  } u;
};

/* An alternative from external lexer point of view */
typedef struct marpaESLIFAlternative {
  char                      *lexemes;     /* Lexeme name */
  marpaESLIFValueResult_t    value;       /* Value */
  size_t                     grammarLengthl; /* Length within the grammar (1 in the token-stream model) */
} marpaESLIFAlternative_t;

typedef struct marpaESLIFValueOption {
  void                                 *userDatavp;            /* User specific context */
  marpaESLIFValueRuleActionResolver_t   ruleActionResolverp;   /* Will return the function doing the wanted rule action */
  marpaESLIFValueSymbolActionResolver_t symbolActionResolverp; /* Will return the function doing the wanted symbol action */
  marpaESLIFValueFreeActionResolver_t   freeActionResolverp;   /* Will return the function doing the free */
  short                                 highRankOnlyb;         /* Default: 1 */
  short                                 orderByRankb;          /* Default: 1 */
  short                                 ambiguousb;            /* Default: 0 */
  short                                 nullb;                 /* Default: 0 */
  int                                   maxParsesi;            /* Default: 0 */
} marpaESLIFValueOption_t;

typedef struct marpaESLIFRecognizerProgress {
  int earleySetIdi;
  int earleySetOrigIdi;
  int rulei;
  int positioni;
} marpaESLIFRecognizerProgress_t;

typedef enum marpaESLIFActionType {
  MARPAESLIF_ACTION_TYPE_NAME = 0,
  MARPAESLIF_ACTION_TYPE_STRING
} marpaESLIFActionType_t;

typedef struct marpaESLIFAction {
  marpaESLIFActionType_t type;
  union {
    char               *names;
    marpaESLIFString_t *stringp;
  } u;
} marpaESLIFAction_t;

typedef struct marpaESLIFGrammarDefaults {
  marpaESLIFAction_t *defaultRuleActionp;   /* Default action for rules */
  marpaESLIFAction_t *defaultSymbolActionp; /* Default action for symbols */
  marpaESLIFAction_t *defaultFreeActionp;   /* Default action for free - if not NULL, type can never be MARPAESLIF_ACION_TYPE_STRING */
} marpaESLIFGrammarDefaults_t;

/* Rule property */

typedef enum marpaESLIFRulePropertyBit {
  MARPAESLIF_RULE_IS_ACCESSIBLE = 0x01,
  MARPAESLIF_RULE_IS_NULLABLE   = 0x02,
  MARPAESLIF_RULE_IS_NULLING    = 0x04,
  MARPAESLIF_RULE_IS_LOOP       = 0x08,
  MARPAESLIF_RULE_IS_PRODUCTIVE = 0x10
} marpaESLIFRulePropertyBit_t;

/* Symbol Property */
typedef enum marpaESLIFSymbolPropertyBit {
  MARPAESLIF_SYMBOL_IS_ACCESSIBLE = 0x01,
  MARPAESLIF_SYMBOL_IS_NULLABLE   = 0x02,
  MARPAESLIF_SYMBOL_IS_NULLING    = 0x04,
  MARPAESLIF_SYMBOL_IS_PRODUCTIVE = 0x08,
  MARPAESLIF_SYMBOL_IS_START      = 0x10,
  MARPAESLIF_SYMBOL_IS_TERMINAL   = 0x20
} marpaESLIFSymbolPropertyBit_t;

typedef struct marpaESLIFGrammarProperty {
  int                    leveli;                       /* Grammar level */
  int                    maxLeveli;                    /* Maximum grammar level */
  marpaESLIFString_t    *descp;                        /* Grammar description (auto-generated if none) */
  short                  latmb;                        /* LATM ? */
  marpaESLIFAction_t    *defaultSymbolActionp;         /* Default action for symbols - never NULL */
  marpaESLIFAction_t    *defaultRuleActionp;           /* Default action for rules - never NULL */
  marpaESLIFAction_t    *defaultFreeActionp;           /* Default action for free - can be NULL */
  int                    starti;                       /* Start symbol Id - always >= 0 */
  int                    discardi;                     /* Discard symbol Id (-1 if none) */
  size_t                 nsymboll;                     /* Number of symbols - always > 0*/
  int                   *symbolip;                     /* Array of symbols Ids - never NULL */
  size_t                 nrulel;                       /* Number of rules - always > 0*/
  int                   *ruleip;                       /* Array of rule Ids - never NULL */
} marpaESLIFGrammarProperty_t;

typedef struct marpaESLIFRuleProperty {
  int                    idi;                          /* Rule Id */
  marpaESLIFString_t    *descp;                        /* Rule alternative name (auto-generated if none) */
  char                  *asciishows;                   /* Rule show (ASCII) */
  int                    lhsi;                         /* LHS symbol Id */
  int                    separatori;                   /* Eventual separator symbol Id (-1 if none) */
  size_t                 nrhsl;                        /* Number of RHS, 0 in case of a nullable */
  int                   *rhsip;                        /* Array of RHS Ids, NULL in case of a nullable */
  int                    exceptioni;                   /* Exception symbol Id (-1 if none) */
  marpaESLIFAction_t    *actionp;                      /* Action */
  char                  *discardEvents;                /* Discard event name - shallowed with its RHS */
  short                  discardEventb;                /* Discard event initial state: 0: off, 1: on */
  int                    ranki;                        /* Rank */
  short                  nullRanksHighb;               /* Null ranks high ? */
  short                  sequenceb;                    /* Sequence ? */
  short                  properb;                      /* Proper ? */
  int                    minimumi;                     /* minimum in case of sequence ? */
  short                  internalb;                    /* This rule is internal */
  int                    propertyBitSet;               /* C.f. marpaESLIFRulePropertyBit_t */
  short                  hideseparatorb;               /* Separator hiden from arguments ? */
} marpaESLIFRuleProperty_t;

typedef enum marpaESLIFSymbolType {
  MARPAESLIF_SYMBOLTYPE_TERMINAL = 0,
  MARPAESLIF_SYMBOLTYPE_META
} marpaESLIFSymbolType_t;

typedef struct marpaESLIFSymbolProperty {
  marpaESLIFSymbolType_t       type;                   /* Symbol type */
  short                        startb;                 /* Start symbol ? */
  short                        discardb;               /* Discard LHS symbol (i.e. :discard) ? */
  short                        discardRhsb;            /* Discard RHS symbol ? */
  short                        lhsb;                   /* Is an LHS somewhere in its grammar ? */
  short                        topb;                   /* Is a top-level symbol in its grammar - implies lhsb */
  int                          idi;                    /* Marpa ID */
  marpaESLIFString_t          *descp;                  /* Symbol description */
  char                        *eventBefores;           /* Pause before */
  short                        eventBeforeb;           /* Pause before initial state: 0: off, 1: on */
  char                        *eventAfters;            /* Pause after */
  short                        eventAfterb;            /* Pause after initial state: 0: off, 1: on */
  char                        *eventPredicteds;        /* Event name for prediction */
  short                        eventPredictedb;        /* Prediction initial state: 0: off, 1: on */
  char                        *eventNulleds;           /* Event name for nulled */
  short                        eventNulledb;           /* Nulled initial state: 0: off, 1: on */
  char                        *eventCompleteds;        /* Event name for completion */
  short                        eventCompletedb;        /* Completion initial state: 0: off, 1: on */
  char                        *discardEvents;          /* Discard event name - shallow pointer to a :discard rule's discardEvents */
  short                        discardEventb;          /* Discard event initial state: 0: off, 1: on - copy of :discard's rule value */
  int                          lookupResolvedLeveli;   /* Resolved grammar level */
  int                          priorityi;              /* Symbol priority */
  marpaESLIFAction_t          *nullableActionp;        /* Nullable semantic */
  int                          propertyBitSet;
} marpaESLIFSymbolProperty_t;

#ifdef __cplusplus
extern "C" {
#endif
  marpaESLIF_EXPORT const char                   *marpaESLIF_versions(void);
  marpaESLIF_EXPORT marpaESLIF_t                 *marpaESLIF_newp(marpaESLIFOption_t *marpaESLIFOptionp);
  marpaESLIF_EXPORT short                         marpaESLIF_extend_builtin_actionb(marpaESLIF_t *marpaESLIFp, char **actionsArrayp, size_t actionsArrayl);
  marpaESLIF_EXPORT marpaESLIFOption_t           *marpaESLIF_optionp(marpaESLIF_t *marpaESLIFp);
  marpaESLIF_EXPORT marpaESLIFGrammar_t          *marpaESLIF_grammarp(marpaESLIF_t *marpaESLIFp);

  marpaESLIF_EXPORT marpaESLIFGrammar_t          *marpaESLIFGrammar_newp(marpaESLIF_t *marpaESLIFp, marpaESLIFGrammarOption_t *marpaESLIFGrammarOptionp);
  marpaESLIF_EXPORT marpaESLIFGrammar_t          *marpaESLIFGrammar_unsafe_newp(marpaESLIF_t *marpaESLIFp, marpaESLIFGrammarOption_t *marpaESLIFGrammarOptionp);
  marpaESLIF_EXPORT marpaESLIF_t                 *marpaESLIFGrammar_eslifp(marpaESLIFGrammar_t *marpaESLIFGrammarp);
  marpaESLIF_EXPORT marpaESLIFGrammarOption_t    *marpaESLIFGrammar_optionp(marpaESLIFGrammar_t *marpaESLIFGrammarp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ngrammarib(marpaESLIFGrammar_t *marpaESLIFGrammarp, int *ngrammarip);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_defaultsb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarDefaults_t *marpaESLIFGrammarDefaultsp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_defaults_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarDefaults_t *marpaESLIFGrammarDefaultsp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_defaults_setb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarDefaults_t *marpaESLIFGrammarDefaultsp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_defaults_by_level_setb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarDefaults_t *marpaESLIFGrammarDefaultsp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammar_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int *levelip, marpaESLIFString_t **descpp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammar_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int leveli, marpaESLIFString_t *descp, int *levelip, marpaESLIFString_t **descpp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammarproperty_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarProperty_t *grammarPropertyp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammarproperty_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFGrammarProperty_t *grammarPropertyp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_rulearray_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int **ruleipp, size_t *rulelp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_rulearray_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int **ruleipp, size_t *rulelp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruleproperty_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, marpaESLIFRuleProperty_t *rulePropertyp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruleproperty_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, marpaESLIFRuleProperty_t *rulePropertyp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruledisplayform_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, char **ruledisplaysp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruledisplayform_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, char **ruledisplaysp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symbolarray_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int **symbolipp, size_t *symbollp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symbolarray_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int **symbolipp, size_t *symbollp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symbolproperty_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int symboli, marpaESLIFSymbolProperty_t *marpaESLIFSymbolPropertyp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symbolproperty_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int symboli, marpaESLIFSymbolProperty_t *marpaESLIFSymbolPropertyp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symboldisplayform_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int symboli, char **symboldisplaysp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_symboldisplayform_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int symboli, char **symboldisplaysp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruleshowform_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, char **ruleshowsp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_ruleshowform_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, int rulei, char **ruleshowsp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammarshowform_currentb(marpaESLIFGrammar_t *marpaESLIFGrammarp, char **grammarshowsp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_grammarshowform_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, char **grammarshowsp, int leveli, marpaESLIFString_t *descp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_parseb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp, marpaESLIFValueOption_t *marpaESLIFValueOptionp, short *exhaustedbp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
  marpaESLIF_EXPORT short                         marpaESLIFGrammar_parse_by_levelb(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp, marpaESLIFValueOption_t *marpaESLIFValueOptionp, short *exhaustedbp, int leveli, marpaESLIFString_t *descp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
  marpaESLIF_EXPORT void                          marpaESLIFGrammar_freev(marpaESLIFGrammar_t *marpaESLIFGrammarp);

  marpaESLIF_EXPORT marpaESLIFRecognizer_t       *marpaESLIFRecognizer_newp(marpaESLIFGrammar_t *marpaESLIFGrammarp, marpaESLIFRecognizerOption_t *marpaESLIFRecognizerOptionp);
  marpaESLIF_EXPORT marpaESLIFGrammar_t          *marpaESLIFRecognizer_grammarp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
  marpaESLIF_EXPORT marpaESLIFRecognizerOption_t *marpaESLIFRecognizer_optionp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_scanb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, short initialEventsb, short *continuebp, short *exhaustedbp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_resumeb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, size_t deltaLengthl, short *continuebp, short *exhaustedbp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_alternativeb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFAlternative_t *marpaESLIFAlternativep);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_completeb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, size_t lengthl);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_readb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFAlternative_t *marpaESLIFAlternativep, size_t lengthl);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_tryb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *lexemes, short *matchbp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_discard_tryb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, short *matchbp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_expectedb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, size_t *nLexemelp, char ***lexemesArraypp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_last_pauseb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *lexemes, char **pausesp, size_t *pauselp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_lexeme_last_tryb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *lexemes, char **trysp, size_t *trylp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_discard_last_tryb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char **trysp, size_t *trylp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_isEofb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, short *eofbp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_event_onoffb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *symbols, marpaESLIFEventType_t eventSeti, short onoffb);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_eventb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, size_t *eventArraylp, marpaESLIFEvent_t **eventArraypp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_progressLogb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, int starti, int endi, genericLoggerLevel_t logleveli);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_inputb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char **inputsp, size_t *inputlp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_locationb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, size_t *linelp, size_t *columnlp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_readb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char **inputsp, size_t *inputlp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_last_completedb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *names, char **offsetpp, size_t *lengthlp);
  marpaESLIF_EXPORT short                         marpaESLIFRecognizer_hook_discardb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, short discardOnOffb);
  marpaESLIF_EXPORT void                          marpaESLIFRecognizer_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);

  marpaESLIF_EXPORT marpaESLIFValue_t            *marpaESLIFValue_newp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueOption_t *marpaESLIFValueOptionp);
  marpaESLIF_EXPORT marpaESLIFRecognizer_t       *marpaESLIFValue_recognizerp(marpaESLIFValue_t *marpaESLIFValuep);
  marpaESLIF_EXPORT marpaESLIFValueOption_t      *marpaESLIFValue_optionp(marpaESLIFValue_t *marpaESLIFValuep);
  marpaESLIF_EXPORT short                         marpaESLIFValue_valueb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp);
  marpaESLIF_EXPORT short                         marpaESLIFValue_value_startb(marpaESLIFValue_t *marpaESLIFValuep, int *startip);
  marpaESLIF_EXPORT short                         marpaESLIFValue_value_lengthb(marpaESLIFValue_t *marpaESLIFValuep, int *lengthip);
  marpaESLIF_EXPORT short                         marpaESLIFValue_contextb(marpaESLIFValue_t *marpaESLIFValuep, char **symbolsp, int *symbolip, char **rulesp, int *ruleip);
  marpaESLIF_EXPORT void                          marpaESLIFValue_freev(marpaESLIFValue_t *marpaESLIFValuep);

  /* Stack management when doing valuation */
  marpaESLIF_EXPORT short                         marpaESLIFValue_stack_setb(marpaESLIFValue_t *marpaESLIFValuep, int indicei, marpaESLIFValueResult_t *marpaESLIFValueResultp);
  /* forget is like setting a value of type MARPAESLIFVALUE_TYPE_UNDEF except that memory management is switched off */
  marpaESLIF_EXPORT short                         marpaESLIFValue_stack_forgetb(marpaESLIFValue_t *marpaESLIFValuep, int indicei);
  marpaESLIF_EXPORT short                         marpaESLIFValue_stack_getb(marpaESLIFValue_t *marpaESLIFValuep, int indicei, marpaESLIFValueResult_t *marpaESLIFValueResultp);
  marpaESLIF_EXPORT marpaESLIFValueResult_t       *marpaESLIFValue_stack_getp(marpaESLIFValue_t *marpaESLIFValuep, int indicei);

  /* getAndForgetb transfers the memory management from the stack to the end-user in one call */
  marpaESLIF_EXPORT short                         marpaESLIFValue_stack_getAndForgetb(marpaESLIFValue_t *marpaESLIFValuep, int indicei, marpaESLIFValueResult_t *marpaESLIFValueResultp);

  marpaESLIF_EXPORT void                          marpaESLIF_freev(marpaESLIF_t *marpaESLIFp);
#ifdef __cplusplus
}
#endif

#endif /* MARPAESLIF_H*/
