#ifndef MARPAESLIF_NAL_STRUCTURES_H
#define MARPAESLIF_INTERNAL_STRUCTURES_H

#include "marpaESLIF.h"
#include "config.h"
/*
 * Prior to genericStack inclusion, we want to define a custom type for performance
 * --------------------------------------------------------------------------------
 */
#define GENERICSTACK_CUSTOM marpaESLIFValueResult_t
#include <genericStack.h>

/*
 * Prior to genericHash inclusion, we define our hash size - a subject number
 * --------------------------------------------------------------------------
 */
#ifndef MARPAESLIF_HASH_SIZE
#define MARPAESLIF_HASH_SIZE 8 /* General default hash size */
#endif
#include <genericHash.h>

#include <marpaWrapper.h>                               /* Marpa engine */
#include <genericLogger.h>                              /* Generic logger */
#include <pcre2.h>                                      /* PCRE2 engine */
#include <tconv.h>                                      /* Generic character/translator engine */

/* Internal regex patterns */
/* ----------------------- */
#define INTERNAL_ANYCHAR_PATTERN "."                    /* This ASCII string is UTF-8 compatible */
#define INTERNAL_UTF8BOM_PATTERN "\\x{FEFF}"            /* FEFF Unicode code point i.e. EFBBBF in UTF-8 encoding */
#define INTERNAL_NEWLINE_PATTERN "(*BSR_UNICODE).*?\\R" /* newline as per unicode - we do .*? because our regexps are always anchored */
#define INTERNAL_STRINGMODIFIERS_PATTERN "i$"
#define INTERNAL_CHARACTERCLASSMODIFIERS_PATTERN "[eijmnsxDJUuaNubcA]+$"
#define INTERNAL_REGEXMODIFIERS_PATTERN "[eijmnsxDJUuaNubcA]*$"

/* Forward definitions */
/* ------------------- */
typedef struct  marpaESLIF_regex                 marpaESLIF_regex_t;
typedef         marpaESLIFString_t               marpaESLIF_string_t;
typedef enum    marpaESLIF_symbol_type           marpaESLIF_symbol_type_t;
typedef enum    marpaESLIF_terminal_type         marpaESLIF_terminal_type_t;
typedef struct  marpaESLIF_terminal              marpaESLIF_terminal_t;
typedef struct  marpaESLIF_meta                  marpaESLIF_meta_t;
typedef         marpaESLIFSymbol_t               marpaESLIF_symbol_t;
typedef struct  marpaESLIF_rule                  marpaESLIF_rule_t;
typedef struct  marpaESLIF_grammar               marpaESLIF_grammar_t;
typedef enum    marpaESLIF_matcher_value         marpaESLIF_matcher_value_t;
typedef enum    marpaESLIF_event_type            marpaESLIF_event_type_t;
typedef struct  marpaESLIF_readerContext         marpaESLIF_readerContext_t;
typedef struct  marpaESLIF_cloneContext          marpaESLIF_cloneContext_t;
typedef struct  marpaESLIF_symbol_data           marpaESLIF_symbol_data_t;
typedef struct  marpaESLIF_alternative           marpaESLIF_alternative_t;
typedef         marpaESLIFAction_t               marpaESLIF_action_t;
typedef         marpaESLIFActionType_t           marpaESLIF_action_type_t;
typedef struct  marpaESLIF_stream                marpaESLIF_stream_t;
typedef struct  marpaESLIF_stringGenerator       marpaESLIF_stringGenerator_t;
typedef struct  marpaESLIF_lua_functioncall      marpaESLIF_lua_functioncall_t;
typedef struct  marpaESLIF_lua_functiondecl      marpaESLIF_lua_functiondecl_t;
typedef enum    marpaESLIF_json_type             marpaESLIF_json_type_t;
typedef struct  marpaESLIF_pcre2_callout_context marpaESLIF_pcre2_callout_context_t;
typedef struct  marpaESLIFGrammar_Lshare         marpaESLIFGrammar_Lshare_t;
typedef struct  marpaESLIF_grammar_bootstrap     marpaESLIF_grammar_bootstrap_t;
typedef struct  marpaESLIFGrammar_bootstrap      marpaESLIFGrammar_bootstrap_t;

#include "marpaESLIF/internal/lua.h" /* For lua_State* */

/* Implementations */
/* --------------- */

/*
 * The general parent <-> child structure is:
 *
 * marpaESLIF
 * -> marpaESLIFGrammar
 *    -> marpaESLIF_grammar
 *       -> marpaESLIFRecognizer that contains a marpaESLIF_stream that can be shared with other recognizers
 *          -> marpaESLIFValue
 */

/* Internal event types that requires an action for faster lookup */
typedef enum marpaESLIF_internal_event_action {
  MARPAESLIF_INTERNAL_EVENT_ACTION_NA = 0,
  MARPAESLIF_INTERNAL_EVENT_ACTION__SYMBOL,
  MARPAESLIF_INTERNAL_EVENT_ACTION__DISCARD_ON,
  MARPAESLIF_INTERNAL_EVENT_ACTION__DISCARD_OFF,
  MARPAESLIF_INTERNAL_EVENT_ACTION__DISCARD_SWITCH
} marpaESLIF_internal_event_action_t;

/* Internal rule action types for faster lookup */
typedef enum marpaESLIF_internal_rule_action {
  MARPAESLIF_INTERNAL_RULE_ACTION_NA = 0,
  MARPAESLIF_INTERNAL_RULE_ACTION___SHIFT,
  MARPAESLIF_INTERNAL_RULE_ACTION___UNDEF,
  MARPAESLIF_INTERNAL_RULE_ACTION___ASCII,
  MARPAESLIF_INTERNAL_RULE_ACTION___CONVERT,
  MARPAESLIF_INTERNAL_RULE_ACTION___CONCAT,
  MARPAESLIF_INTERNAL_RULE_ACTION___COPY,
  MARPAESLIF_INTERNAL_RULE_ACTION___TRUE,
  MARPAESLIF_INTERNAL_RULE_ACTION___FALSE,
  MARPAESLIF_INTERNAL_RULE_ACTION___JSON,
  MARPAESLIF_INTERNAL_RULE_ACTION___JSONF,
  MARPAESLIF_INTERNAL_RULE_ACTION___ROW,
  MARPAESLIF_INTERNAL_RULE_ACTION___TABLE,
  MARPAESLIF_INTERNAL_RULE_ACTION___AST
} marpaESLIF_internal_rule_action_t;

/* Internal symbol action types for faster lookup */
typedef enum marpaESLIF_internal_symbol_action {
  MARPAESLIF_INTERNAL_SYMBOL_ACTION_NA = 0,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___TRANSFER,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___UNDEF,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___ASCII,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___CONVERT,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___CONCAT,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___TRUE,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___FALSE,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___JSON,
  MARPAESLIF_INTERNAL_SYMBOL_ACTION___JSONF
} marpaESLIF_internal_symbol_action_t;

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
  MARPAESLIF_TERMINAL_TYPE_REGEX,    /* Regular expression */
  MARPAESLIF_TERMINAL_TYPE__EOF,     /* :eof */
  MARPAESLIF_TERMINAL_TYPE__EOL,     /* :eol */
  MARPAESLIF_TERMINAL_TYPE__SOL,     /* :sol */
  MARPAESLIF_TERMINAL_TYPE__EMPTY    /* :empty */
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

struct marpaESLIF_pcre2_callout_context {
  marpaESLIFRecognizer_t *marpaESLIFRecognizerp;
  marpaESLIF_terminal_t  *terminalp;
};

struct marpaESLIF_regex {
  pcre2_code            *patternp;     /* Compiled pattern */
  pcre2_match_data      *match_datap;  /* Match data */
#ifdef PCRE2_CONFIG_JIT
  short                  jitb;         /* Eventual optimized JIT */
#endif
  short                  isAnchoredb;  /* Remember if pattern was allocated with PCRE2_ANCHORED (set automatically or not) */
  short                  utfb;         /* Is UTF mode enabled in that pattern ? */
  pcre2_compile_context *compile_contextp;    /* Output of pcre2_compile_context */
  short                  calloutb;     /* Do this regex have any callout ? */
  pcre2_match_context   *match_contextp;    /* Match context */
  marpaESLIF_pcre2_callout_context_t callout_context; /* Callout match */
  short                  characterClassb; /* Origin is a character class */
};

struct marpaESLIF_terminal {
  char                          *utf8s;               /* Original UTF-8 input to _marpaESLIF_terminal_new() */
  size_t                         utf8l;               /* Original UTF-8 input length to _marpaESLIF_terminal_new() */
  int                            idi;                 /* Terminal Id */
  marpaESLIF_string_t           *descp;               /* Terminal description */
  char                          *modifiers;           /* Modifiers */
  char                          *patterns;            /* This is what is sent to PCRE2 and what defines exactly the terminal */
  size_t                         patternl;
  marpaESLIF_uint32_t            patterni;            /* ... this includes pattern options */
  marpaESLIF_terminal_type_t     type;                /* Original type. Used for description. When origin is STRING we know that patterns if ASCII safe */
  marpaESLIF_regex_t             regex;               /* Regex version */
  short                          memcmpb;             /* Flag saying that memcmp is possible */
  char                          *bytes;               /* Original UTF-8 bytes, used for memcmp() when possible */
  size_t                         bytel;               /* i.e. when this is a string terminal without modifier */
  short                          pseudob;             /* Pseudo terminal */
  int                            eventSeti;           /* Remember eventSeti */
  short                          byte2failureb;       /* True if the willfailb array is filled */
  short                          willfailb[256];      /* For string and character class terminals, pre-computation of expected failure for the 256 ASCII bytes */
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
  /* For faster lookup we put these elements at the beginning of the structure - these are all shallow pointers */
  marpaESLIFAction_t                  *effectiveNullableActionp;
  marpaESLIF_internal_rule_action_t    effectiveNullableActione;
  marpaESLIFAction_t                  *effectiveSymbolActionp;
  marpaESLIF_internal_symbol_action_t  effectiveSymbolActione;

  marpaESLIF_symbol_type_t       type;  /* Symbol type */
  union {
    marpaESLIF_terminal_t       *terminalp; /* Symbol is a terminal */
    marpaESLIF_meta_t           *metap;     /* Symbol is a meta identifier, i.e. a rule */
  } u;
  marpaESLIF_t                  *marpaESLIFp;
  short                          startb;                 /* Start symbol ? */
  short                          discardb;               /* Discard LHS symbol (i.e. :discard) ? */
  short                          discardRhsb;            /* Discard RHS symbol ? */
  short                          lhsb;                   /* Is an LHS somewhere in its grammar ? */
  short                          topb;                   /* Is a top-level symbol in its grammar - implies lhsb */
  int                            idi;                    /* Marpa ID */
  marpaESLIF_string_t           *descp;                  /* Symbol description */
  char                          *eventBefores;           /* Pause before */
  short                          eventBeforeb;           /* Pause before initial state: 0: off, 1: on */
  marpaESLIF_internal_event_action_t eventBeforee;       /* For faster lookup if it requires an action */
  char                          *eventAfters;            /* Pause after */
  short                          eventAfterb;            /* Pause after initial state: 0: off, 1: on */
  marpaESLIF_internal_event_action_t eventAftere;        /* For faster lookup if it requires an action */
  char                          *eventPredicteds;        /* Event name for prediction */
  short                          eventPredictedb;        /* Prediction initial state: 0: off, 1: on */
  marpaESLIF_internal_event_action_t eventPredictede;    /* For faster lookup if it requires an action */
  char                          *eventNulleds;           /* Event name for nulled */
  short                          eventNulledb;           /* Nulled initial state: 0: off, 1: on */
  marpaESLIF_internal_event_action_t eventNullede;       /* For faster lookup if it requires an action */
  char                          *eventCompleteds;        /* Event name for completion */
  short                          eventCompletedb;        /* Completion initial state: 0: off, 1: on */
  marpaESLIF_internal_event_action_t eventCompletede;    /* For faster lookup if it requires an action */
  marpaESLIF_lua_functiondecl_t *eventDeclp;             /* Specific to event declaration on parameterized LHSs */
  char                          *discardEvents;          /* Discard event name - shallow pointer to a :discard rule's discardEvents */
  short                          discardEventb;          /* Discard event initial state: 0: off, 1: on - copy of :discard's rule value */
  marpaESLIF_internal_event_action_t discardEvente;      /* Discard event internal action type */
  int                            lookupLevelDeltai;      /* Referenced grammar delta level */
  marpaESLIF_symbol_t           *lookupSymbolp;          /* Forced referenced lookup symbol */
  int                            lookupResolvedLeveli;   /* Resolved grammar level */
  int                            priorityi;              /* Symbol priority */
  genericStack_t                 _nullableRuleStack;     /* Used during validation, to determine nullable semantics */
  genericStack_t                *nullableRuleStackp;     /* Pointer to _nullableRuleStack */
  marpaESLIFAction_t            *nullableActionp;        /* Nullable semantic, only for meta symbols that are not lexemes */
  marpaESLIF_internal_rule_action_t nullableActione;     /* For faster lookup */
  int                            propertyBitSet;
  int                            eventBitSet;
  genericStack_t                 _lhsRuleStack;          /* Stack of rules having this symbol as LHS */
  genericStack_t                *lhsRuleStackp;          /* Pointer to stack of rules having this symbol as LHS */
  marpaESLIF_symbol_t           *exceptionp;             /* Pointer to an exception itself, the one after the '-' character */
  marpaESLIFAction_t            *symbolActionp;          /* symbol-action, only for terminals or lexemes */
  marpaESLIF_internal_symbol_action_t symbolActione;     /* For faster lookup */
  marpaESLIFAction_t            *ifActionp;              /* if-action, only for terminals or lexemes */
  marpaESLIFAction_t            *generatorActionp;       /* generator-action */
  marpaESLIFSymbolOption_t       marpaESLIFSymbolOption;
  /* When an external meta symbol is created, it duplicates a symbol content */
  short                          contentIsShallowb;
  marpaESLIFGrammar_t           *marpaESLIFGrammarp;     /* Shallow pointer, set by marpaESLIFSymbol_meta_newp() only */
  short                          verboseb;               /* Symbol is verbose */
  int                            parami;                 /* -1 when none */
  short                          parameterizedRhsb;
  marpaESLIF_lua_functiondecl_t *declp;                  /* For parameterized symbols, shallow pointer to declp */
  marpaESLIF_lua_functioncall_t *callp;                  /* For parameterized symbols, shallow pointer to callp */
  marpaESLIFAction_t            *pushContextActionp;     /* For parameterized symbols, context push action */
  short                          lookaheadb;             /* Lookahead symbol ? */
  short                          lookaheadIsTerminalb;   /* Lookahead is a single terminal ? */
  marpaESLIF_symbol_t           *lookaheadSymbolp;       /* Lookahead symbol */
};

/* A rule */
struct marpaESLIF_rule {
  /* For faster lookup we put these elements at the beginning of the structure - these are all shallow pointers */
  marpaESLIFAction_t                *effectiveRuleActionp;
  marpaESLIF_internal_rule_action_t  effectiveRuleActione;

  int                             idi;                          /* Rule Id */
  marpaESLIF_string_t            *descp;                        /* Rule alternative name */
  short                           descautob;                    /* True if alternative name was autogenerated */
  char                           *asciishows;                   /* Rule show (ASCII) */
  marpaESLIF_symbol_t            *lhsp;                         /* LHS symbol */
  marpaESLIF_symbol_t            *separatorp;                   /* Eventual separator symbol */
  size_t                          nrhsl;                        /* Number of rhs */
  marpaESLIF_symbol_t           **rhspp;                        /* RHS symbols */
  int                            *rhsip;                        /* Convenient array for rule property */
  short                          *skipbp;                       /* Skip booleans */
  marpaESLIF_symbol_t            *exceptionp;                   /* Exception symbol */
  int                             exceptionIdi;                 /* Exception symbol Id */
  marpaESLIFAction_t             *actionp;                      /* Action */
  marpaESLIF_internal_rule_action_t actione;                    /* For faster lookup */
  char                           *discardEvents;                /* Discard event name - shallowed to its RHS */
  short                           discardEventb;                /* Discard event initial state: 0: off, 1: on - copied to its RHS */
  marpaESLIF_internal_event_action_t discardEvente;             /* Discard event internal action type */
  int                             ranki;
  short                           nullRanksHighb;
  short                           sequenceb;
  short                           properb;
  int                             minimumi;
  int                             propertyBitSet;
  short                           hideseparatorb;
  marpaESLIF_lua_functiondecl_t  *declp;
  marpaESLIF_lua_functioncall_t **callpp;
  marpaESLIF_lua_functioncall_t  *separatorcallp;
  short                           internalb;                   /* Internal rule (:discard and :start cases) */
  marpaESLIFAction_t             *contextActionp;              /* Get current rule context */
};

/* A grammar */
struct marpaESLIF_grammar {
  marpaESLIFGrammar_t   *marpaESLIFGrammarp;                 /* Shallow pointer to parent structure marpaESLIFGrammarp */
  marpaESLIFGrammar_Lshare_t *Lsharep;                       /* Shallow pointer to parent structure's Lsharep - can never be NULL */
  int                    leveli;                             /* Grammar level */
  marpaESLIF_string_t   *descp;                              /* Grammar description */
  short                  descautob;                          /* True if alternative name was autogenerated */
  short                  latmb;                              /* Longest acceptable token match mode */
  short                  discardIsFallbackb;                 /* discard is fallback mode */
  marpaWrapperGrammar_t *marpaWrapperGrammarStartp;          /* Grammar implementation at :start */
  marpaWrapperGrammar_t *marpaWrapperGrammarStartNoEventp;   /* Grammar implementation at :start forcing no event */
  size_t                 nTerminall;                         /* Total number of accessible terminals */
  marpaESLIF_symbol_t  **symbolArraypp;                      /* Total accessible grammar terminal (Symbols sorted by priority) */
  marpaESLIF_symbol_t  **willFailsymbolArraypp;              /* Workarea for total accessible grammar terminals predicted to fail */
  size_t                 nTerminalPristinel;                 /* Number of terminals at the very beginning of marpaWrapperGrammarStartp */
  int                   *terminalIdArrayPristinep;           /* Terminals at the very beginning of marpaWrapperGrammarStartp (Ids sorted by priority) */
  marpaESLIF_symbol_t  **terminalArrayPristinepp;            /* Terminals at the very beginning of marpaWrapperGrammarStartp (Symbols sorted by priority) */
  marpaWrapperGrammar_t *marpaWrapperGrammarDiscardp;        /* Grammar implementation at :discard */
  marpaWrapperGrammar_t *marpaWrapperGrammarDiscardNoEventp; /* Grammar implementation at :discard forcing no event */
  size_t                 nTerminalDiscardPristinel;          /* Number of lexemes at the very beginning of marpaWrapperGrammarDiscardp */
  int                   *terminalIdArrayDiscardPristinep;    /* Terminals at the very beginning of marpaWrapperGrammarStartp (Ids) */
  marpaESLIF_symbol_t  **terminalArrayDiscardPristinepp;     /* Terminals at the very beginning of marpaWrapperGrammarStartp (Symbols ordered by priority) */
  marpaESLIF_symbol_t   *discardp;                           /* Discard symbol, used at grammar validation */
  genericStack_t         _symbolStack;                       /* Stack of symbols */
  genericStack_t        *symbolStackp;                       /* Pointer to stack of symbols */
  genericStack_t         _ruleStack;                         /* Stack of rules */
  genericStack_t        *ruleStackp;                         /* Pointer to stack of rules */
  marpaESLIFAction_t    *defaultSymbolActionp;               /* Default action for symbols - never NULL */
  marpaESLIF_internal_symbol_action_t defaultSymbolActione;  /* For faster lookup */
  marpaESLIFAction_t    *defaultRuleActionp;                 /* Default action for rules - never NULL */
  marpaESLIF_internal_rule_action_t defaultRuleActione;      /* For faster lookup */
  marpaESLIFAction_t    *defaultEventActionp;                /* Default action for events - can be NULL */
  marpaESLIFAction_t    *defaultRegexActionp;                /* Default regex action, applies to all regexes of a grammar - can be NULL */
  int                    starti;                             /* Default start symbol ID - filled during grammar validation */
  char                  *starts;                             /* Default start symbol name - filled during grammar validation - shallow pointer */
  int                   *ruleip;                             /* Array of rule IDs - filled by grammar validation */
  size_t                 nrulel;                             /* Size of the rule IDs array - filled by grammar validation */
  int                   *symbolip;                           /* Array of symbol IDs - filled by grammar validation */
  size_t                 nsymboll;                           /* Size of the symbol IDs array - filled by grammar validation */
  unsigned int           nbupdatei;                          /* Number of updates - used in grammar ESLIF actions */
  char                  *asciishows;                         /* Grammar show (ASCII) */
  int                    discardi;                           /* Discard symbol ID - filled during grammar validation */
  char                  *defaultEncodings;                   /* Default encoding is reader returns NULL */
  char                  *fallbackEncodings;                  /* Fallback encoding is reader returns NULL and tconv fails to detect encoding */
  short                  fastDiscardb;                       /* True when :discard can be done in the context of the current recognizer */
  marpaESLIF_symbol_t  **allSymbolsArraypp;                  /* For fast access to symbols, they are all flatened here */
  marpaESLIF_rule_t    **allRulesArraypp;                    /* For fast access to rules, they are all flatened here */
  int                   *expectedTerminalIdArrayp;           /* Total list of expected symbol ids sorted by priority */
  marpaESLIF_symbol_t  **expectedTerminalArraypp;            /* Total list of expected terminals sorted by priority */
};

enum marpaESLIF_json_type {
  MARPAESLIF_JSON_TYPE_STRICT = 0,
  MARPAESLIF_JSON_TYPE_EXTENDED,
  _MARPAESLIF_JSON_TYPE_LAST
};

struct marpaESLIFGrammar_Lshare {
  lua_State                 *L;                                 /* A Lua instance */
  marpaESLIFRecognizer_t    *marpaESLIFRecognizerUnsharedTopp;  /* The unshared top-level recognizer that is running on this grammar */
  marpaESLIFRecognizer_t    *marpaESLIFRecognizerLastInjectedp; /* The last marpaESLIFRecognizer injected */
  marpaESLIFValue_t         *marpaESLIFValueLastInjectedp;      /* The last marpaESLIFValuep injected */
};

#define MARPAESLIFGRAMMARLUA_FOR_PARLIST 0
#define MARPAESLIFGRAMMARLUA_FOR_EXPLIST 1
struct marpaESLIF {
  marpaESLIFGrammar_t        *marpaESLIFGrammarLuap;
  marpaESLIFGrammar_t        *marpaESLIFGrammarLuapp[2];   /* C.f. MARPAESLIFGRAMMARLUA_FOR_PARLIST and MARPAESLIFGRAMMARLUA_FOR_EXPLIST */
  marpaESLIFGrammar_t        *marpaESLIFGrammarp;          /* ESLIF has its own grammar -; */
  marpaESLIFOption_t          marpaESLIFOption;
  marpaESLIF_terminal_t      *anycharp;                    /* internal regex for match any character */
  marpaESLIF_terminal_t      *newlinep;                    /* Internal regex for match newline */
  marpaESLIFSymbol_t         *newlineSymbolp;              /* Internal symbol for match newline */
  marpaESLIF_terminal_t      *stringModifiersp;            /* Internal regex for match string modifiers */
  marpaESLIF_terminal_t      *characterClassModifiersp;    /* Internal regex for match character class modifiers */
  marpaESLIF_terminal_t      *regexModifiersp;             /* Internal regex for match regex modifiers */
  genericLogger_t            *traceLoggerp;                /* For cases where this is silent mode but compiled with TRACE */
  short                       NULLisZeroBytesb;            /* An internal boolean to help when we can safely do calloc() */
  short                       ZeroIntegerisZeroBytesb;     /* An internal boolean to help when we can safely do calloc() */
  char                       *versions;                    /* Version */
  int                         versionMajori;               /* Major version */
  int                         versionMinori;               /* Minor version */
  int                         versionPatchi;               /* Patch version */
  marpaESLIFValueResult_t     marpaESLIFValueResultTrue;   /* Pre-filled ::true value result */
  marpaESLIFValueResult_t     marpaESLIFValueResultFalse;  /* Pre-filled ::false value result */
#ifdef HAVE_LOCALE_H
  struct lconv               *lconvp;
#endif
  char                        decimalPointc;
  const uint8_t              *tablesp;                     /* Output of pcre2_maketables */
#ifdef MARPAESLIF_HAVE_LONG_LONG
  size_t                      llongmincharsl;              /* Number of digits of LLONG_MIN */
  size_t                      llongmaxcharsl;              /* Number of digits of LLONG_MAX */
#else
  size_t                      longmincharsl;               /* Number of digits of LONG_MIN */
  size_t                      longmaxcharsl;               /* Number of digits of LONG_MAX */
#endif
#ifdef MARPAESLIF_INFINITY
  float                       positiveinfinityf;           /* +Inf */
  float                       negativeinfinityf;           /* -Inf */
#endif
#ifdef MARPAESLIF_NAN
  float                       positivenanf;                /* +NaN */
  float                       negativenanf;                /* -NaN */
  short                       nanconfidenceb;              /* 1 when ESLIF think that NaN representation is correct */
#endif
  /* For JSON grammars : the symbols that depend on strictness */
  marpaESLIF_symbol_t        *jsonStringpp[_MARPAESLIF_JSON_TYPE_LAST];
  marpaESLIF_symbol_t        *jsonConstantOrNumberpp[_MARPAESLIF_JSON_TYPE_LAST];
  marpaESLIFGrammar_Lshare_t  Lshare;                  /* A Lua instance, used by all sub-grammars of ESLIF */
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
  short                      hasPseudoTerminalb; /* Any pseudo terminal in the grammar ? */
  short                      hasEofPseudoTerminalb; /* Any :eof terminal in the grammar ? */
  short                      hasEolPseudoTerminalb; /* Any :eol terminal in the grammar ? */
  short                      hasSolPseudoTerminalb; /* Any :sol terminal in the grammar ? */
  short                      hasEmptyPseudoTerminalb; /* Any :empty terminal in the grammar ? */
  genericHash_t              _lexemeGrammarHash; /* Cache of string <=> lexeme grammars */
  genericHash_t             *lexemeGrammarHashp;
  short                      hasLookaheadMetab;  /* Any lookahead meta in the grammar ? */
  /* For JSON grammars : the symbols that depend on strictness */
  marpaESLIF_symbol_t       *jsonStringp; /* Shallow pointer */
  marpaESLIF_symbol_t       *jsonConstantOrNumberp; /* Shallow pointer */

  /* Lua singleton. There is a difficulty with generated grammars: we do not want to attach them  */
  /* to the original grammar, because they are volatile. This is why the L singleton and          */
  /* associated singleton constants are all in a specific structure, and they are accessible      */
  /* only via a pointer.                                                                          */
  /* By definition a grammar is the owner of the singleton if *Lsharep == &_Lshare.               */
  marpaESLIFGrammar_Lshare_t _Lshare;
  marpaESLIFGrammar_Lshare_t *Lsharep;

  marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammar_bootstrapp;
};

struct marpaESLIF_meta {
  int                            idi;                             /* Non-terminal Id */
  char                          *asciinames;
  marpaESLIF_string_t           *descp;                           /* Meta description */
  marpaWrapperGrammar_t         *marpaWrapperGrammarStartp;       /* Cloned low-level grammar starting at idi */
  marpaWrapperGrammar_t         *marpaWrapperGrammarStartNoEventp; /* Cloned low-level grammar starting at idi (no event) */
  int                            lexemeIdi;                       /* Lexeme Id in this cloned grammar */
  short                         *prioritizedb;                    /* Internal flag to prevent a prioritized symbol to appear more than once as an LHS */
  marpaESLIFGrammar_t           _marpaESLIFGrammarLexemeClone;    /* Cloned ESLIF grammar in lexeme search mode (no event): allocated when meta is allocated */
  marpaESLIF_grammar_t          _grammar;
  marpaESLIFGrammar_t           *marpaESLIFGrammarLexemeClonep;   /* Cloned ESLIF grammar in lexeme search mode (no event) */
  size_t                         nTerminalPristinel;              /* Number of terminals at the very beginning of marpaWrapperGrammarStartp */
  int                           *terminalIdArrayPristinep;        /* Grammar terminals at the very beginning of marpaWrapperGrammarStartp (Ids sorted by priority) */
  marpaESLIF_symbol_t          **terminalArrayPristinepp;         /* Grammar terminals at the very beginning of marpaWrapperGrammarStartp (Symbols sorted by priority) */
  size_t                         nTerminall;                      /* Number of grammar terminals of marpaWrapperGrammarp */
  marpaESLIF_symbol_t          **symbolArraypp;                   /* Grammar terminals of marpaWrapperGrammarp (Symbols sorted by priority) */
  marpaESLIF_symbol_t          **willFailsymbolArraypp;           /* Workarea for total accessible grammar terminals predicted to fail */
  short                          lazyb;                           /* Meta symbol is lazy - for internal usage only at bootstrap */
  int                            eventSeti;                       /* Remember eventSeti */
};

struct marpaESLIF_stringGenerator {
  marpaESLIF_t *marpaESLIFp;
  char         *s;      /* Pointer */
  size_t        l;      /* Used size */
  short         okb;    /* Status */
  size_t        allocl; /* Allocated size */
};

struct marpaESLIFValue {
  marpaESLIF_t                *marpaESLIFp;
  marpaESLIFGrammar_Lshare_t  *Lsharep;                       /* Shallow pointer to parent structure's Lsharep - can never be NULL */
  marpaESLIFRecognizer_t      *marpaESLIFRecognizerp;
  marpaESLIFValueOption_t      marpaESLIFValueOption;
  marpaWrapperValue_t         *marpaWrapperValuep;
  genericStack_t              _valueResultStack;
  genericStack_t              *valueResultStackp;
  short                        inValuationb;
  marpaESLIF_symbol_t         *symbolp;
  marpaESLIF_rule_t           *rulep;
  char                        *actions; /* Shallow pointer to action "name", depends on action type */
  marpaESLIF_action_t         *actionp; /* Shallow pointer to action */
  marpaESLIF_string_t         *stringp; /* Not NULL only when is a literal - then callback is forced to be internal */
  void                        *marpaESLIFLuaValueContextp;
  marpaESLIFRepresentation_t   proxyRepresentationp; /* Proxy representation callback, c.f. json.c for an example */
  marpaESLIF_stringGenerator_t stringGenerator; /* Internal string generator, put here to avoid unnecessary malloc()/free() calls */
  genericLogger_t             *stringGeneratorLoggerp; /* Internal string generator logger, put here to avoid unnecessary genericLogger_newp()/genericLogger_freev() calls */
  char                        *luaprecompiledp;    /* Lua script source precompiled */
  size_t                       luaprecompiledl;    /* Lua script source precompiled length in byte */
  short                        hideSeparatorb;     /* Hook for internal ::row and ::table actions to process more efficiently hide-separator adverb */
  short                        isLexemeb;          /* Special mode for true lexemes: caller did not mind about valuation, just the number of bytes consumed up to completion */
};

struct marpaESLIF_stream {
  char                  *buffers;              /* Pointer to allocated buffer containing input */
  size_t                 bufferl;              /* Number of valid bytes in this buffer (!= allocated size) */
  size_t                 bufferallocl;         /* Number of allocated bytes in this buffer (!= valid bytes) */
  char                  *globalOffsetp;        /* The offset between the original start of input, and current buffer */
  short                  eofb;                 /* EOF flag */
  short                  utfb;                 /* A flag to say if input is UTF-8 correct. Automatically true if charconvb is true. Can be set by regex engine as well. */
  short                  charconvb;            /* A flag to say if latest stream chunk was converted to UTF-8 */
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
  tconv_t                tconvp;               /* current converter. Always != NULL when charconvb is true. Always NULL when charconvb is false. */
  short                  bomdoneb;             /* In char mode, flag indicating if BOM was processed successfully (BOM existence or not) */
  unsigned int           peeki;                /* Number of peeked sharing */
  size_t                 linel;                /* Line number */
  size_t                 columnl;              /* Column number */
};

struct marpaESLIFRecognizer {
  /* The variables starting with "_" are not supposed to ever be accessed  */
  /* except in very precise situations (typically the new()/free() or when */
  /* faking a new() method). */
  marpaESLIF_t                *marpaESLIFp;
  marpaESLIF_grammar_t        *grammarp;
  marpaESLIFGrammar_Lshare_t *Lsharep;                       /* Shallow pointer to parent structure's Lsharep - TAKE CARE - can be NULL because sometimes grammarp can be NULL */
  marpaESLIFGrammar_t        *marpaESLIFGrammarp;            /* Shallow pointer to parent structure's marpaESLIFGrammarp - TAKE CARE - can be NULL because sometimes grammarp can be NULL */
  short                       isLexemeb;                     /* Lexeme mode: the position of terminal matches may change, only size is trustable */
  
  marpaESLIFRecognizerOption_t marpaESLIFRecognizerOption;
  marpaWrapperRecognizer_t    *marpaWrapperRecognizerp; /* Current recognizer */
  marpaWrapperGrammar_t       *marpaWrapperGrammarp; /* Shallow copy of cached grammar in use */
  genericStack_t               _lexemeStack;       /* Internal input stack of lexemes */
  genericStack_t              *lexemeStackp;       /* Pointer to internal input stack of lexemes */
  marpaESLIFEvent_t           *eventArrayp;        /* For the events */
  size_t                       eventArrayl;        /* Current number of events */
  size_t                       eventArraySizel;    /* Real allocated size (to avoid constant free/deletes) */
  marpaESLIFRecognizer_t      *marpaESLIFRecognizerParentp;
  char                        *lastCompletionEvents; /* A trick to avoid having to fetch the array event when a discard subgrammar succeed */
  marpaESLIF_symbol_t         *lastCompletionSymbolp; /* Ditto */
  marpaESLIF_internal_event_action_t lastCompletionEvente;  /* Ditto */
  char                        *discardEvents;     /* Set by a child discard recognizer that reaches a completion event */
  marpaESLIF_internal_event_action_t discardEvente;     /* Discard event internal action type */
  marpaESLIF_symbol_t         *discardSymbolp;    /* Ditto */
  int                          resumeCounteri;    /* Internal counter for tracing - no functional impact */
  int                          callstackCounteri; /* Internal counter for tracing - no functional impact */
  int                          callstackCounterGlobali; /* Internal counter for tracing - no functional impact */

  int                          leveli;         /* Recognizer level (!= grammar level) */
  size_t                       parentDeltal;   /* Parent original delta - used to recover parent current pointer at our free */
  size_t                       parentLinel;    /* Parent original linel - used to recover parent line number our free */
  size_t                       parentColumnl;  /* Parent original columnl - used to recover parent column number our free */
  /* Current recognizer states */
  short                        scanb;          /* Prevent resume before a call to scan */
  short                        noEventb;       /* No event mode */
  short                        discardb;       /* Discard mode */
  short                        silentb;        /* Silent mode */
  short                        haveLexemeb;    /* Remember if this recognizer have at least one lexeme */
  short                        completedb;     /* Ditto for completion (used in case of discard events) */
  short                        forceExhaustedb; /* If recognizer interface has the exhaustedb flag set and this value is true, forces an exhaustion event if grammar do not have one */
  short                        cannotcontinueb; /* Internal flag that forces CanContinueb() to return false */
  genericStack_t               _alternativeStackSymbol;          /* Current alternative stack containing symbol information and the matched size */
  genericStack_t              *alternativeStackSymbolp;          /* Pointer to current alternative stack containing symbol information and the matched size */
  genericStack_t               _commitedAlternativeStackSymbol;  /* Commited alternative stack */
  genericStack_t              *commitedAlternativeStackSymbolp;  /* Pointer to commited alternative stack */
  genericStack_t               _set2InputStack;                  /* Mapping latest Earley Set to absolute input offset and length */
  genericStack_t              *set2InputStackp;                  /* Pointer to mapping latest Earley Set to absolute input offset and length */
  char                       **namesArrayp;         /* Persistent buffer of last call to marpaESLIFRecognizer_name_expectedb */
  size_t                       namesArrayAllocl;    /* Current allocated size -; */
  short                       *discardEventStatebp; /* Discard current event states for the CURRENT grammar (marpaESLIFRecognizerp->marpaESLIFGrammarp->grammarp) */
  short                       *beforeEventStatebp;  /* Lexeme before current event states for the CURRENT grammar */
  short                       *afterEventStatebp;   /* Lexeme after current event states for the CURRENT grammar */
  marpaESLIF_symbol_data_t   **lastPausepp;         /* Lexeme last pause for the CURRENT grammar */
  marpaESLIF_symbol_data_t   **lastTrypp;           /* Lexeme or :discard last try for the CURRENT grammar */
  short                        discardOnOffb;       /* Discard is on or off ? */
  short                        pristineb;           /* 1: pristine, i.e. can be reused, 0: have at least one thing that happened at the raw grammar level, modulo the eventual initial events */
  genericHash_t                _marpaESLIFRecognizerHash; /* Cache of recognizers ready for re-use - shared with all children (lexeme mode) */
  genericHash_t               *marpaESLIFRecognizerHashp;
  marpaESLIF_stream_t          _marpaESLIF_stream;  /* A stream is always owned by one recognizer */
  marpaESLIF_stream_t         *marpaESLIF_streamp;  /* ... But the stream pointer can be shared with others */
  size_t                       previousMaxMatchedl;       /* Always computed */
  size_t                       lastSizel;                 /* Always computed */
  int                          maxStartCompletionsi;
  size_t                       lastSizeBeforeCompletionl; /* Computed only if maxStartCompletionsi is != 0 */
  short                        atStartCompletionb;
  size_t                       startCompletionl;  /* Number of bytes at the last start completion */
  size_t                       cumulCompletionl;  /* Number of bytes since the last start completion (or at the very beginning) */
  int                          numberOfStartCompletionsi; /* Total number of start completions */

  marpaESLIFRecognizerOption_t marpaESLIFRecognizerOptionDiscard;
  marpaESLIFValueOption_t      marpaESLIFValueOptionDiscard;

  /* Embedded lua - c.f. src/bindings/src/marpaESLIFLua.c */
  void                        *marpaESLIFLuaRecognizerContextp;

  /* For pristine recognizers, expected terminals are always known in advance */
  size_t                       nTerminalPristinel;
  int                         *terminalIdArrayPristinep; /* This is a shallow pointer! */
  marpaESLIF_symbol_t        **terminalArrayPristinepp; /* This is a shallow pointer! */

  /* Accessible terminals */
  size_t                       nTerminall;
  int                         *symbolIdArrayp; /* This is a shallow pointer! */

  /* Last discard information is NOT available via last_complete because it is not */
  /* associated with any particular grammar. So, when trackb is on */
  /* the only way to get last discard value is to have an explicit area for it. */
  size_t                       lastDiscardl;    /* Number of bytes */
  char                        *lastDiscards;    /* Bytes */

  /* For lua action callbacks */
  char                        *actions;        /* Shallow pointer to action "name", depends on action type */
  marpaESLIF_action_t         *actionp;        /* Shallow pointer to action */

  /* For _marpaESLIFRecognizer_set_internalp_deepb */
  genericStack_t               _marpaESLIFValueResultWorkStack;
  genericStack_t              *marpaESLIFValueResultWorkStackp;
  genericStack_t               _marpaESLIFValueResultStackOrig;
  genericStack_t              *marpaESLIFValueResultStackOrigp;
  genericStack_t               _marpaESLIFValueResultStackNew;
  genericStack_t              *marpaESLIFValueResultStackNewp;

  /* When doing regex callback, only the "offset_vector" part is variable, all other */
  /* members of the regex's TABLE argument can be created once and modified in-place */
  size_t                       _offset_vector_allocl;
  marpaESLIFValueResultPair_t  _marpaESLIFCalloutBlockPairs[_MARPAESLIFCALLOUTBLOCK_SIZE];
  marpaESLIFValueResult_t      _marpaESLIFCalloutBlock;
  marpaESLIFValueResult_t     *marpaESLIFCalloutBlockp;

  /* We always maintain a shallow pointer to the top-level recognizer, to ease access to lua state */
  /* This variable should be used ONLY IN src/lua.c (modulo initialization and propagation that are in src/marpaESLIF.c) */
  marpaESLIFRecognizer_t      *marpaESLIFRecognizerTopp;

  /* Storage for latest call to marpaWrapperRecognizer_progressb */
  size_t                          progressallocl;
  marpaESLIFRecognizerProgress_t *progressp;

  char                           *luaprecompiledp;    /* Lua script source precompiled */
  size_t                          luaprecompiledl;    /* Lua script source precompiled length in byte */
  marpaESLIFAction_t             *getContextActionp;  /* Getting the context is a common function that is stored at recognizer level */
  marpaESLIFAction_t             *setContextActionp;  /* Setting the context is a common function that is stored at recognizer level */
  marpaESLIFAction_t             *popContextActionp;  /* Getting the context is a common function that is stored at recognizer level */

  marpaESLIFRecognizer_t         *marpaESLIFRecognizerSharedp;

  /* A flag to remember if we are in the last_discard_loop mode */
  short                           last_discard_loopb;

  /* Proxy generic logger */
  genericLogger_t                *genericLoggerp;
};

struct marpaESLIF_symbol_data {
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
  marpaESLIF_symbol_t     *symbolp;               /* Associated symbol - shallow pointer */
  marpaESLIFValueResult_t  marpaESLIFValueResult; /* Associated value */
  int                      grammarLengthi;        /* Length within the grammar (1 in the token-stream model) */
  short                    usedb;                 /* Is this structure in use ? */
  size_t                   matchedLengthl;        /* Number of bytes that matched */
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
  NULL,              /* ifActionResolverp */
  NULL,              /* eventActionResolverp */
  NULL,              /* regexActionResolverp */
  NULL,              /* generatorActionResolverp */
  NULL               /* importerp */
};

marpaESLIFSymbolOption_t marpaESLIFSymbolOption_default_template = {
  NULL,              /* userDatavp */
  NULL               /* importerp */
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

struct marpaESLIF_lua_functioncall {
  char   *luaexplists;
  short   luaexplistcb;
  int     sizei;   /* Number of top expressions */
};

struct marpaESLIF_lua_functiondecl {
  char   *luaparlists;
  short   luaparlistcb;
  int     sizei;   /* Number of parameters */
};

struct marpaESLIF_grammar_bootstrap {
  marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp;
  marpaWrapperGrammar_t         *marpaWrapperGrammarStartp;          /* Grammar implementation at :start */
  unsigned int                   nbupdatei;                          /* Number of updates - used in grammar ESLIF actions */
  int                            leveli;                             /* Grammar level */
  short                          latmb;                              /* Longest acceptable token match mode */
  marpaESLIF_string_t           *descp;                              /* Grammar description */
  short                          descautob;                          /* True if alternative name was autogenerated */
  short                          discardIsFallbackb;                 /* discard is fallback mode */
  marpaESLIFAction_t            *defaultRuleActionp;                 /* Default action for rules */
  marpaESLIFAction_t            *defaultSymbolActionp;               /* Default action for symbols */
  marpaESLIFAction_t            *defaultEventActionp;                /* Default action for events */
  marpaESLIFAction_t            *defaultRegexActionp;                /* Default regex action, applies to all regexes of a grammar */
  char                          *defaultEncodings;                   /* Default encoding is reader returns NULL */
  char                          *fallbackEncodings;                  /* Fallback encoding is reader returns NULL and tconv fails to detect encoding */
  genericStack_t                 _symbolStack;                       /* Stack of symbols */
  genericStack_t                *symbolStackp;                       /* Pointer to stack of symbols */
  genericStack_t                 _ruleStack;                         /* Stack of rules */
  genericStack_t                *ruleStackp;                         /* Pointer to stack of rules */
};

struct marpaESLIFGrammar_bootstrap {
  genericStack_t             _grammarBootstrapStack; /* Stack of marpaESLIF_grammar_bootstrap_t */
  genericStack_t            *grammarBootstrapStackp; /* Pointer to stack of marpaESLIF_grammar_bootstrap_t */
  short                      warningIsErrorb;        /* Current warningIsErrorb setting (used when parsing grammars ) */
  short                      warningIsIgnoredb;      /* Current warningIsErrorb setting (used when parsing grammars ) */
  short                      autorankb;              /* Current autorank setting */
  char                      *luabytep;               /* Lua script source */
  size_t                     luabytel;               /* Lua script source length in byte */
  int                        internalRuleCounti;     /* Internal counter when creating internal rules (groups '(-...-)' and '(...)' */
  short                      hasPseudoTerminalb;     /* Any pseudo terminal in the grammar ? */
  short                      hasEofPseudoTerminalb;  /* Any :eof terminal in the grammar ? */
  short                      hasEolPseudoTerminalb;  /* Any :eol terminal in the grammar ? */
  short                      hasSolPseudoTerminalb;  /* Any :sol terminal in the grammar ? */
  short                      hasEmptyPseudoTerminalb; /* Any :empty terminal in the grammar ? */
  short                      hasLookaheadMetab;      /* Any lookahead meta in the grammar ? */
};

#include "marpaESLIF/internal/eslif.h"

#endif /* MARPAESLIF_INTERNAL_STRUCTURES_H */
