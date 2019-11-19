#ifndef MARPAESLIF_INTERNAL_STRUCTURES_H
#define MARPAESLIF_INTERNAL_STRUCTURES_H

#include <marpaESLIF.h>
/*
 * Prior to genericStack inclusion, we want to define a custom type for performance
 */

#define GENERICSTACK_CUSTOM marpaESLIFValueResult_t

#include <marpaWrapper.h>
#include <genericStack.h>
#include <genericHash.h>
#include <genericLogger.h>
#include <pcre2.h>
#include <tconv.h>
#include "marpaESLIF/internal/lua.h" /* For lua_State* */

#define INTERNAL_ANYCHAR_PATTERN "."                    /* This ASCII string is UTF-8 compatible */
#define INTERNAL_UTF8BOM_PATTERN "\\x{FEFF}"            /* FEFF Unicode code point i.e. EFBBBF in UTF-8 encoding */
#define INTERNAL_NEWLINE_PATTERN "(*BSR_UNICODE).*?\\R" /* newline as per unicode - we do .*? because our regexps are always anchored */
#define INTERNAL_STRINGMODIFIERS_PATTERN "i$"
#define INTERNAL_CHARACTERCLASSMODIFIERS_PATTERN "[eijmnsxDJUuaNubcA]+$"
#define INTERNAL_REGEXMODIFIERS_PATTERN "[eijmnsxDJUuaNubcA]*$"

typedef struct  marpaESLIF_regex           marpaESLIF_regex_t;
typedef         marpaESLIFString_t         marpaESLIF_string_t;
typedef enum    marpaESLIF_symbol_type     marpaESLIF_symbol_type_t;
typedef enum    marpaESLIF_terminal_type   marpaESLIF_terminal_type_t;
typedef struct  marpaESLIF_terminal        marpaESLIF_terminal_t;
typedef struct  marpaESLIF_meta            marpaESLIF_meta_t;
typedef         marpaESLIFSymbol_t         marpaESLIF_symbol_t;
typedef struct  marpaESLIF_rule            marpaESLIF_rule_t;
typedef struct  marpaESLIF_grammar         marpaESLIF_grammar_t;
typedef enum    marpaESLIF_matcher_value   marpaESLIF_matcher_value_t;
typedef enum    marpaESLIF_event_type      marpaESLIF_event_type_t;
typedef struct  marpaESLIF_readerContext   marpaESLIF_readerContext_t;
typedef struct  marpaESLIF_cloneContext    marpaESLIF_cloneContext_t;
typedef         marpaESLIFValueType_t      marpaESLIF_stack_type_t;
typedef struct  marpaESLIF_lexeme_data     marpaESLIF_lexeme_data_t;
typedef struct  marpaESLIF_alternative     marpaESLIF_alternative_t;
typedef         marpaESLIFAction_t         marpaESLIF_action_t;
typedef         marpaESLIFActionType_t     marpaESLIF_action_type_t;
typedef struct  marpaESLIF_stream          marpaESLIF_stream_t;

/* Symbol types */
enum marpaESLIF_symbol_type {
  MARPAESLIF_SYMBOL_TYPE_NA = 0,
  MARPAESLIF_SYMBOL_TYPE_TERMINAL,
  MARPAESLIF_SYMBOL_TYPE_META
};

/* Terminal types */
enum marpaESLIF_terminal_type {
  MARPAESLIF_TERMINAL_TYPE_NA = 0,
  MARPAESLIF_TERMINAL_TYPE_STRING,   /* String */
  MARPAESLIF_TERMINAL_TYPE_REGEX     /* Regular expression */
};

/* Regex modifiers - we take JPCRE2 matching semantics, c.f. https://neurobin.org/projects/softwares/libs/jpcre2/ */
struct marpaESLIF_regex_option_map {
  char                       modifierc;
  char                      *pcre2Options;
  marpaESLIF_uint32_t        pcre2Optioni;
  char                      *pcre2OptionNots;
  marpaESLIF_uint32_t        pcre2OptionNoti;
} marpaESLIF_regex_option_map[] = {
  { 'e', "PCRE2_MATCH_UNSET_BACKREF",                PCRE2_MATCH_UNSET_BACKREF,                NULL,              0 },
  { 'i', "PCRE2_CASELESS",                           PCRE2_CASELESS,                           NULL,              0 },
  { 'j', "PCRE2_ALT_BSUX|PCRE2_MATCH_UNSET_BACKREF", PCRE2_ALT_BSUX|PCRE2_MATCH_UNSET_BACKREF, NULL,              0 },
  { 'm', "PCRE2_MULTILINE",                          PCRE2_MULTILINE,                          NULL,              0 },
  { 'n', "PCRE2_UCP",                                PCRE2_UCP,                                NULL,              0 },
  { 's', "PCRE2_DOTALL",                             PCRE2_DOTALL,                             NULL,              0 },
  { 'x', "PCRE2_EXTENDED",                           PCRE2_EXTENDED,                           NULL,              0 },
  { 'D', "PCRE2_DOLLAR_ENDONLY",                     PCRE2_DOLLAR_ENDONLY,                     NULL,              0 },
  { 'J', "PCRE2_DUPNAMES",                           PCRE2_DUPNAMES,                           NULL,              0 },
  { 'U', "PCRE2_UNGREEDY",                           PCRE2_UNGREEDY,                           NULL,              0 },
  { 'a', NULL,                                       0,                                        "PCRE2_UTF",       PCRE2_UTF },
  { 'N', NULL,                                       0,                                        "PCRE2_UCP",       PCRE2_UCP },
  { 'u', "PCRE2_UTF",                                PCRE2_UTF,                                NULL,              0 },
  { 'b', "PCRE2_NEVER_UTF",                          PCRE2_NEVER_UTF,                          "PCRE2_UTF",       PCRE2_UTF },
  { 'c', "PCRE2_UTF",                                PCRE2_UTF,                                "PCRE2_NEVER_UTF", PCRE2_NEVER_UTF },
  { 'A', NULL,                                       0,                                        "PCRE2_ANCHORED",  PCRE2_ANCHORED }
};

struct marpaESLIF_regex {
  pcre2_code          *patternp;     /* Compiled pattern */
  pcre2_match_data    *match_datap;  /* Match data */
#ifdef PCRE2_CONFIG_JIT
  short                jitCompleteb; /* Eventual optimized JIT */
  short                jitPartialb;
#endif
  short                isAnchoredb;  /* Remember if pattern was allocated with PCRE2_ANCHORED (set automatically or not) */
  short                utfb;         /* Is UTF mode enabled in that pattern ? */
};

struct marpaESLIF_terminal {
  int                         idi;                 /* Terminal Id */
  marpaESLIF_string_t        *descp;               /* Terminal description */
  char                       *modifiers;           /* Modifiers */
  char                       *patterns;            /* This is what is sent to PCRE2 and what defines exactly the terminal */
  size_t                      patternl;
  marpaESLIF_uint32_t         patterni;            /* ... this includes pattern options */
  marpaESLIF_terminal_type_t  type;                /* Original type. Used for description. When origin is STRING we know that patterns if ASCII safe */
  marpaESLIF_regex_t          regex;               /* Regex version */
  short                       memcmpb;             /* Flag saying that memcmp is possible */
  char                       *bytes;               /* Original UTF-8 bytes, used for memcmp() when possible */
  size_t                      bytel;               /* i.e. when this is a string terminal without modifier */
};

/* Matcher return values */
enum marpaESLIF_matcher_value {
  MARPAESLIF_MATCH_AGAIN   = -1,
  MARPAESLIF_MATCH_FAILURE =  0,
  MARPAESLIF_MATCH_OK      =  1
};

/* Event types */
enum marpaESLIF_event_type {
  MARPAESLIF_EVENT_TYPE_NA        = 0x00,
  MARPAESLIF_EVENT_TYPE_COMPLETED = 0x01, /* Grammar event */
  MARPAESLIF_EVENT_TYPE_NULLED    = 0x02, /* Grammar event */
  MARPAESLIF_EVENT_TYPE_EXPECTED  = 0x04, /* Grammar event */
  MARPAESLIF_EVENT_TYPE_BEFORE    = 0x08, /* ESLIF lexeme event */
  MARPAESLIF_EVENT_TYPE_AFTER     = 0x10  /* ESLIF lexeme event */
};

/* A symbol */
struct marpaESLIFSymbol {
  marpaESLIF_symbol_type_t     type;  /* Symbol type */
  union {
    marpaESLIF_terminal_t     *terminalp; /* Symbol is a terminal */
    marpaESLIF_meta_t         *metap;     /* Symbol is a meta identifier, i.e. a rule */
  } u;
  short                        startb;                 /* Start symbol ? */
  short                        discardb;               /* Discard LHS symbol (i.e. :discard) ? */
  short                        discardRhsb;            /* Discard RHS symbol ? */
  short                        lhsb;                   /* Is an LHS somewhere in its grammar ? */
  short                        topb;                   /* Is a top-level symbol in its grammar - implies lhsb */
  int                          idi;                    /* Marpa ID */
  marpaESLIF_string_t         *descp;                  /* Symbol description */
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
  int                          lookupLevelDeltai;      /* Referenced grammar delta level */
  char                        *lookupMetas;            /* Referenced lookup meta name - shallow pointer */
  int                          lookupResolvedLeveli;   /* Resolved grammar level */
  int                          priorityi;              /* Symbol priority */
  genericStack_t               _nullableRuleStack;     /* Used during validation, to determine nullable semantics */
  genericStack_t              *nullableRuleStackp;     /* Pointer to _nullableRuleStack */
  marpaESLIFAction_t          *nullableActionp;        /* Nullable semantic, only for meta symbols that are not lexemes */
  int                          propertyBitSet;
  int                          eventBitSet;
  genericStack_t               _lhsRuleStack;          /* Stack of rules having this symbol as LHS */
  genericStack_t              *lhsRuleStackp;          /* Pointer to stack of rules having this symbol as LHS */
  marpaESLIF_symbol_t         *exceptionp;             /* Pointer to an exception itself, the one after the '-' character */
  marpaESLIFAction_t          *symbolActionp;          /* Custom symbol, only for terminals or lexemes */
  marpaESLIFAction_t          *ifActionp;              /* if semantic, only for meta symbols that are lexemes or terminals */
};

/* A rule */
struct marpaESLIF_rule {
  int                    idi;                          /* Rule Id */
  marpaESLIF_string_t   *descp;                        /* Rule alternative name */
  short                  descautob;                    /* True if alternative name was autogenerated */
  char                  *asciishows;                   /* Rule show (ASCII) */
  marpaESLIF_symbol_t   *lhsp;                         /* LHS symbol */
  marpaESLIF_symbol_t   *separatorp;                   /* Eventual separator symbol */
  genericStack_t         _rhsStack;                    /* Stack of RHS symbols */
  genericStack_t        *rhsStackp;                    /* Pointer to stack of RHS symbols */
  int                   *rhsip;                        /* Convenience array of RHS ids for rule introspection */
  short                 *skipbp;                       /* Convenience array of RHS ids for skip introspection */
  marpaESLIF_symbol_t   *exceptionp;                   /* Exception symbol */
  int                    exceptionIdi;                 /* Exception symbol Id */
  marpaESLIFAction_t    *actionp;                      /* Action */
  char                  *discardEvents;                /* Discard event name - shallowed to its RHS */
  short                  discardEventb;                /* Discard event initial state: 0: off, 1: on - copied to its RHS */
  int                    ranki;
  short                  nullRanksHighb;
  short                  sequenceb;
  short                  properb;
  int                    minimumi;
  short                  passthroughb;                 /* This rule is a passthrough */
  int                    propertyBitSet;
  short                  hideseparatorb;
};

/* A grammar */
struct marpaESLIF_grammar {
  marpaESLIFGrammar_t   *marpaESLIFGrammarp;                 /* Shallow pointer to parent structure marpaESLIFGrammarp */
  int                    leveli;                             /* Grammar level */
  marpaESLIF_string_t   *descp;                              /* Grammar description */
  short                  descautob;                          /* True if alternative name was autogenerated */
  short                  latmb;                              /* Longest acceptable token match mode */
  marpaWrapperGrammar_t *marpaWrapperGrammarStartp;          /* Grammar implementation at :start */
  marpaWrapperGrammar_t *marpaWrapperGrammarStartNoEventp;   /* Grammar implementation at :start forcing no event */
  size_t                 nSymbolStartl;                      /* Number of lexemes at the very beginning of marpaWrapperGrammarStartp */
  int                   *symbolArrayStartp;                  /* Lexemes at the very beginning of marpaWrapperGrammarStartp */
  marpaWrapperGrammar_t *marpaWrapperGrammarDiscardp;        /* Grammar implementation at :discard */
  marpaWrapperGrammar_t *marpaWrapperGrammarDiscardNoEventp; /* Grammar implementation at :discard forcing no event */
  size_t                 nSymbolDiscardl;                    /* Number of lexemes at the very beginning of marpaWrapperGrammarDiscardp */
  int                   *symbolArrayDiscardp;                /* Lexemes at the very beginning of marpaWrapperGrammarStartp */
  marpaESLIF_symbol_t   *discardp;                           /* Discard symbol, used at grammar validation */
  genericStack_t         _symbolStack;                       /* Stack of symbols */
  genericStack_t        *symbolStackp;                       /* Pointer to stack of symbols */
  genericStack_t         _ruleStack;                         /* Stack of rules */
  genericStack_t        *ruleStackp;                         /* Pointer to stack of rules */
  marpaESLIFAction_t    *defaultSymbolActionp;               /* Default action for symbols - never NULL */
  marpaESLIFAction_t    *defaultRuleActionp;                 /* Default action for rules - never NULL */
  int                    starti;                             /* Default start symbol ID - filled during grammar validation */
  char                  *starts;                             /* Default start symbol name - filled during grammar validation - shallow pointer */
  int                   *ruleip;                             /* Array of rule IDs - filled by grammar validation */
  size_t                 nrulel;                             /* Size of the rule IDs array - filled by grammar validation */
  int                   *symbolip;                           /* Array of symbol IDs - filled by grammar validation */
  size_t                 nsymboll;                           /* Size of the symbol IDs array - filled by grammar validation */
  unsigned int           nbupdatei;                          /* Number of updates - used in grammar ESLIF actions */
  char                  *asciishows;                         /* Grammar show (ASCII) */
  int                    discardi;                           /* Discard symbol ID - filled during grammar validation */
};

/* ----------------------------------- */
/* Definition of the opaque structures */
/* ----------------------------------- */
struct marpaESLIF {
  marpaESLIFGrammar_t    *marpaESLIFGrammarp;          /* ESLIF has its own grammar -; */
  marpaESLIFOption_t      marpaESLIFOption;
  marpaESLIF_terminal_t  *anycharp;                    /* internal regex for match any character */
  marpaESLIF_terminal_t  *newlinep;                    /* Internal regex for match newline */
  marpaESLIF_terminal_t  *stringModifiersp;            /* Internal regex for match string modifiers */
  marpaESLIF_terminal_t  *characterClassModifiersp;    /* Internal regex for match character class modifiers */
  marpaESLIF_terminal_t  *regexModifiersp;             /* Internal regex for match regex modifiers */
  genericLogger_t        *traceLoggerp;                /* For cases where this is silent mode but compiled with TRACE */
  short                   NULLisZeroBytesb;            /* An internal boolean to help when we can safely do calloc() */
  char                   *versions;                    /* Version */
  int                     versionMajori;               /* Major version */
  int                     versionMinori;               /* Minor version */
  int                     versionPatchi;               /* Patch version */
  marpaESLIFValueResult_t marpaESLIFValueResultTrue;   /* Pre-filled ::true value result */
  marpaESLIFValueResult_t marpaESLIFValueResultFalse;  /* Pre-filled ::false value result */
  char                    float_fmts[128];            /* Pre-filled format string for floats */
  char                    double_fmts[128];           /* Pre-filled format string for double */
  char                    long_double_fmts[128];      /* Pre-filled format string for double */
};

struct marpaESLIFGrammar {
  marpaESLIF_t              *marpaESLIFp;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;
  genericStack_t             _grammarStack;      /* Stack of grammars */
  genericStack_t            *grammarStackp;      /* Pointer to stack of grammars */
  marpaESLIF_grammar_t      *grammarp;           /* This is a SHALLOW copy of current grammar in grammarStackp, defaulting to the top grammar */
  short                      warningIsErrorb;    /* Current warningIsErrorb setting (used when parsing grammars ) */
  short                      warningIsIgnoredb;  /* Current warningIsErrorb setting (used when parsing grammars ) */
  short                      autorankb;          /* Current autorank setting */
  char                      *luabytep;           /* Lua script source */
  size_t                     luabytel;           /* Lua script source length in byte */
  char                      *luaprecompiledp;    /* Lua script source precompiled */
  size_t                     luaprecompiledl;    /* Lua script source precompiled length in byte */
  marpaESLIF_string_t       *luadescp;           /* Delayed until show is requested */
  int                        internalRuleCounti; /* Internal counter when creating internal rules (groups '(-...-)' and '(...)' */
};

struct marpaESLIF_meta {
  int                          idi;                             /* Non-terminal Id */
  char                        *asciinames;
  marpaESLIF_string_t         *descp;                           /* Non-terminal description */
  marpaWrapperGrammar_t       *marpaWrapperGrammarLexemeClonep; /* Cloned low-level grammar in lexeme search mode (no event) */
  int                          lexemeIdi;                       /* Lexeme Id in this cloned grammar */
  short                       *prioritizedb;                    /* Internal flag to prevent a prioritized symbol to appear more than once as an LHS */
  marpaESLIFGrammar_t         _marpaESLIFGrammarLexemeClone;    /* Cloned ESLIF grammar in lexeme search mode (no event): allocated when meta is allocated */
  marpaESLIF_grammar_t        _grammar;
  marpaESLIFGrammar_t         *marpaESLIFGrammarLexemeClonep;   /* Cloned ESLIF grammar in lexeme search mode (no event) */
  size_t                       nSymbolStartl;                   /* Number of lexemes at the very beginning of marpaWrapperGrammarStartp */
  int                         *symbolArrayStartp;               /* Lexemes at the very beginning of marpaWrapperGrammarStartp */
};

struct marpaESLIFValue {
  marpaESLIF_t                *marpaESLIFp;
  marpaESLIFRecognizer_t      *marpaESLIFRecognizerp;
  marpaESLIFValueOption_t      marpaESLIFValueOption;
  marpaWrapperValue_t         *marpaWrapperValuep;
  short                        previousPassWasPassthroughb;
  int                          previousArg0i;
  int                          previousArgni;
  genericStack_t              *valueResultStackp;
  short                        inValuationb;
  marpaESLIF_symbol_t         *symbolp;
  marpaESLIF_rule_t           *rulep;
  char                        *actions; /* True external name of best-effort ASCII in case of literal */
  marpaESLIF_string_t         *stringp; /* Not NULL only when is a literal - then callback is forced to be internal */
  lua_State                   *L;
  void                        *marpaESLIFLuaValueContextp;
  genericStack_t               _beforePtrStack;
  genericStack_t              *beforePtrStackp;
  genericHash_t                _beforePtrHash;
  genericHash_t               *beforePtrHashp;
  genericHash_t                _afterPtrHash;
  genericHash_t               *afterPtrHashp;
};

struct marpaESLIF_stream {
  char                  *buffers;              /* Pointer to allocated buffer containing input */
  size_t                 bufferl;              /* Number of valid bytes in this buffer (!= allocated size) */
  size_t                 bufferallocl;         /* Number of allocated bytes in this buffer (!= valid bytes) */
  char                  *globalOffsetp;        /* The offset between the original start of input, and current buffer */
  short                  eofb;                 /* EOF flag */
  short                  utfb;                 /* A flag to say if input is UTF-8 correct. Automatically true if charconvb is true. Can be set by regex engine as well. */
  short                  charconvb;            /* A flag to say if latest stream chunk was converted to UTF-8 */
  char                  *lastFroms;            /* Last from encoding as per user, in user's encoding */
  size_t                 lastFroml;            /* Last from encoding length as per user, in user's encoding */
  char                  *bytelefts;            /* Buffer when character conversion needs to reread leftover bytes */
  size_t                 byteleftl;            /* Usable length of this buffer */
  size_t                 byteleftallocl;       /* Allocated length of this buffer */
  char                  *inputs;               /* Current pointer in buffers */
  size_t                 inputl;               /* Current remaining bytes */
  size_t                 bufsizl;              /* Buffer bufsizl policy */
  size_t                 buftriggerl;          /* Minimum number of bytes to trigger crunch of data */
  short                  nextReadIsFirstReadb; /* Flag to say if next read is first read */
  short                  noAnchorIsOkb;        /* Flag to say if the "A" flag in regexp modifiers is allowed: removing PCRE2_ANCHOR is allowed ONLY is the whole stream was read once */
  char                  *encodings;            /* Current encoding. Always != NULL when charconvb is true. Always NULL when charconvb is false. */
  marpaESLIF_terminal_t *encodingp;            /* Terminal case-insensitive version of current encoding. Always != NULL when charconvb is true. Always NULL when charconvb is false. */
  tconv_t                tconvp;               /* current converter. Always != NULL when charconvb is true. Always NULL when charconvb is false. */
  size_t                 linel;                /* Line number */
  size_t                 columnl;              /* Column number */
  short                  bomdoneb;             /* In char mode, flag indicating if BOM was processed successfully (BOM existence or not) */
};

struct marpaESLIFRecognizer {
  /* The variables starting with "_" are not supposed to ever be accessed  */
  /* except in very precise situations (typically the new()/free() or when */
  /* faking a new() method). */
  marpaESLIF_t                *marpaESLIFp;

  /* Because recognizers can be cached we cannot afford marpaESLIFGrammarp to point to something on the stack when we free: Grammarp and grammarp */
  /* We guarantee that pointers below grammarp are correct (these are shallow pointers) */
  marpaESLIFGrammar_t          _marpaESLIFGrammar;
  marpaESLIF_grammar_t         _grammar;
  marpaESLIFGrammar_t         *marpaESLIFGrammarp;
  
  marpaESLIFRecognizerOption_t marpaESLIFRecognizerOption;
  marpaWrapperRecognizer_t    *marpaWrapperRecognizerp; /* Current recognizer */
  marpaWrapperGrammar_t       *marpaWrapperGrammarp; /* Shallow copy of cached grammar in use */
  genericStack_t               _lexemeInputStack;  /* Internal input stack of lexemes */
  genericStack_t              *lexemeInputStackp;  /* Pointer to internal input stack of lexemes */
  marpaESLIFEvent_t           *eventArrayp;        /* For the events */
  size_t                       eventArrayl;        /* Current number of events */
  size_t                       eventArraySizel;    /* Real allocated size (to avoid constant free/deletes) */
  marpaESLIFRecognizer_t      *parentRecognizerp;
  char                        *lastCompletionEvents; /* A trick to avoid having to fetch the array event when a discard subgrammar succeed */
  marpaESLIF_symbol_t         *lastCompletionSymbolp; /* Ditto */
  char                        *discardEvents;     /* Set by a child discard recognizer that reaches a completion event */
  marpaESLIF_symbol_t         *discardSymbolp;    /* Ditto */
  int                          resumeCounteri;    /* Internal counter for tracing - no functional impact */
  int                          callstackCounteri; /* Internal counter for tracing - no functional impact */

  int                          leveli;         /* Recognizer level (!= grammar level) */
  size_t                       parentDeltal;   /* Parent original delta - used to recovert parent current pointer at our free */
  /* Current recognizer states */
  short                        scanb;          /* Prevent resume before a call to scan */
  short                        noEventb;       /* No event mode */
  short                        discardb;       /* Discard mode */
  short                        silentb;        /* Silent mode */
  short                        haveLexemeb;    /* Remember if this recognizer have at least one lexeme */
  short                        completedb;     /* Ditto for completion (used in case od discard events) */
  short                        cannotcontinueb; /* Internal flag that forces CanContinueb() to return false */
  genericStack_t               _alternativeStackSymbol;          /* Current alternative stack containing symbol information and the matched size */
  genericStack_t              *alternativeStackSymbolp;          /* Pointer to current alternative stack containing symbol information and the matched size */
  genericStack_t               _commitedAlternativeStackSymbol;  /* Commited alternative stack */
  genericStack_t              *commitedAlternativeStackSymbolp;  /* Pointer to commited alternative stack */
  genericStack_t               _set2InputStack;                  /* Mapping latest Earley Set to absolute input offset and length */
  genericStack_t              *set2InputStackp;                  /* Pointer to mapping latest Earley Set to absolute input offset and length */
  char                       **lexemesArrayp;      /* Persistent buffer of last call to marpaESLIFRecognizer_lexeme_expectedb */
  size_t                       lexemesArrayAllocl; /* Current allocated size -; */
  short                       *discardEventStatebp; /* Discard current event states for the CURRENT grammar (marpaESLIFRecognizerp->marpaESLIFGrammarp->grammarp) */
  short                       *beforeEventStatebp;  /* Lexeme before current event states for the CURRENT grammar */
  short                       *afterEventStatebp;   /* Lexeme after current event states for the CURRENT grammar */
  marpaESLIF_lexeme_data_t   **lastPausepp;         /* Lexeme last pause for the CURRENT grammar */
  marpaESLIF_lexeme_data_t   **lastTrypp;           /* Lexeme or :discard last try for the CURRENT grammar */
  short                        discardOnOffb;       /* Discard is on or off ? */
  short                        pristineb;           /* 1: pristine, i.e. can be reused, 0: have at least one thing that happened at the raw grammar level, modulo the eventual initial events */
  genericHash_t                _marpaESLIFRecognizerHash; /* Cache of recognizers ready for re-use - shared with all children (lexeme mode) */
  genericHash_t               *marpaESLIFRecognizerHashp;
  genericStack_t               _marpaESLIFRecognizerStack; /* Cache of recognizers already malloced - not ready for reuse, just already allocated */
  genericStack_t              *marpaESLIFRecognizerStackp; /* Cache of recognizers already malloced - not ready for reuse, just already allocated */
  marpaESLIF_stream_t          _marpaESLIF_stream;  /* A stream is always owned by one recognizer */
  marpaESLIF_stream_t         *marpaESLIF_streamp;  /* ... But the stream pointer can be shared with others */
  size_t                       previousMaxMatchedl;       /* Always computed */
  size_t                       lastSizel;                 /* Always computed */
  int                          maxStartCompletionsi;
  int                          numberOfStartCompletionsi; /* Computed only if maxStartCompletionsi != 0 */
  size_t                       lastSizeBeforeCompletionl; /* Computed only if maxStartCompletionsi is != 0 */

  /* When a recognizer needs to discard, we prepare storage for marpaESLIFGrammarp, marpaESLIFRecognizerOptionp and marpaESLIFValueOptionp. */
  /* This a lazy initialization, driven by the grammarDiscardInitializedb flag. */
  short                        grammarDiscardInitializedb;
  marpaESLIFGrammar_t          marpaESLIFGrammarDiscard;
  marpaESLIF_grammar_t         grammarDiscard;
  marpaESLIFRecognizerOption_t marpaESLIFRecognizerOptionDiscard;
  marpaESLIFValueOption_t      marpaESLIFValueOptionDiscard;

  /* Embedded lua - c.f. src/bindings/src/marpaESLIFLua.c */
  void                        *marpaESLIFLuaRecognizerContextp;

  /* Lexeme input stack is a marpaESLIFValueResult stack */
  genericStack_t               _beforePtrStack;
  genericStack_t              *beforePtrStackp;
  genericHash_t                _beforePtrHash;
  genericHash_t               *beforePtrHashp;
  genericHash_t                _afterPtrHash;
  genericHash_t               *afterPtrHashp;

  /* For pristine recognizers, expected terminals are always known in advance */
  size_t                       nSymbolPristinel;
  int                          *symbolArrayPristinep; /* This is shallow pointer! */

  /* Last discard information is NOT available via last_complete because formally there is */
  /* no token injected in the grammar: discard is a transversal thing. So, we trackb is on */
  /* the only way to get last discard value is to have an explicit area for it. */
  size_t                       lastDiscardl;    /* Number of bytes */
  char                        *lastDiscards;    /* Bytes */

  /* For lua if-action callback */
  lua_State                   *L;
  char                        *ifactions;
};

struct marpaESLIF_lexeme_data {
  char   *bytes;        /* Data */
  size_t  bytel;        /* Length */
  size_t  byteSizel;    /* Allocated size */
};

/* Alternative work in two mode: when there is parent recognizer and when this is a top-level recognizer:
   - when there is a parent recognizer, we are by definition in computing a lexeme. Then we have the full
     control. And we guarantee that the input will never crunch. At most it can move. Therefore in this
     mode we can work with offsets.
   - when this is a top-level recognizer, everything is allocated on the heap.
*/
struct marpaESLIF_alternative {
  marpaESLIF_symbol_t *symbolp;                  /* Associated symbol - shallow pointer */
  marpaESLIFValueResult_t marpaESLIFValueResult; /* Associated value */
  int                     grammarLengthi;        /* Length within the grammar (1 in the token-stream model) */
  short                   usedb;                 /* Is this structure in use ? */
};

marpaESLIF_alternative_t marpaESLIF_alternative_default = {
  NULL, /* symbolp */
  NULL, /* valuep */
  0,    /* valuel */
  0,    /* grammarLengthi */
  0     /* usedb */
};

/* ------------------------------- */
/* Definition of internal contexts */
/* ------------------------------- */

/* Internal reader context when parsing a grammar. Everything is in utf8s so the reader can say ok to any stream callback */
struct marpaESLIF_readerContext {
  marpaESLIF_t              *marpaESLIFp;
  marpaESLIFGrammarOption_t *marpaESLIFGrammarOptionp;
};

/* Internal structure to have clone context information */
struct marpaESLIF_cloneContext {
  marpaESLIF_t         *marpaESLIFp;
  marpaESLIF_grammar_t *grammarp;
};

/* ------------------------------------------- */
/* Definition of the default option structures */
/* ------------------------------------------- */
marpaESLIFOption_t marpaESLIFOption_default_template = {
  NULL               /* genericLoggerp */
};

marpaESLIFGrammarOption_t marpaESLIFGrammarOption_default_template = {
  NULL, /* bytep */
  0,    /* bytel */
  NULL, /* encodings */
  0     /* encodingl */
};

marpaESLIFRecognizerOption_t marpaESLIFRecognizerOption_default_template = {
  NULL,              /* userDatavp */
  NULL,              /* readerCallbackp */
  0,                 /* disableThresholdb */
  0,                 /* exhaustedb */
  0,                 /* newlineb */
  0,                 /* trackb */
  MARPAESLIF_BUFSIZ, /* bufsizl */
  50,                /* buftriggerperci */
  50,                /* bufaddperci */
  NULL               /* ifActionResolverp */
};

marpaESLIFValueOption_t marpaESLIFValueOption_default_template = {
  NULL, /* userDatavp - filled at run-time */
  NULL, /* ruleActionResolverp */
  NULL, /* symbolActionResolverp */
  NULL, /* importerp */
  1,    /* highRankOnlyb */
  1,    /* orderByRankb */
  0,    /* ambiguousb */
  0,    /* nullb */
  0     /* maxParsesi */
};

/* String helper */
struct marpaESLIFStringHelper {
  marpaESLIF_t       *marpaESLIFp;
  marpaESLIFString_t *marpaESLIFStringp;
};

#include "marpaESLIF/internal/eslif.h"

#endif /* MARPAESLIF_INTERNAL_STRUCTURES_H */
