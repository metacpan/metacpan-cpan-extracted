#ifndef MARPAWRAPPER_GRAMMAR
#define MARPAWRAPPER_GRAMMAR

#include <stddef.h>
#include <stdarg.h>

#include <marpaWrapper/export.h>
#include <genericLogger.h>

/* ---------------- */
/* Opaque structure */
/* ---------------- */
typedef struct marpaWrapperGrammar marpaWrapperGrammar_t;

/* ------------------------------------------ */
/* For every symbol there can be three events */
/* ------------------------------------------ */
typedef enum marpaWrapperGrammarEventType {
  MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE       = 0x00,
  MARPAWRAPPERGRAMMAR_EVENTTYPE_COMPLETION = 0x01,
  MARPAWRAPPERGRAMMAR_EVENTTYPE_NULLED     = 0x02,
  MARPAWRAPPERGRAMMAR_EVENTTYPE_PREDICTION = 0x04
} marpaWrapperGrammarEventType_t;

/* Possile triggered events */
typedef struct marpaWrapperGrammarEvent {
  enum {
    MARPAWRAPPERGRAMMAR_EVENT_COMPLETED,
    MARPAWRAPPERGRAMMAR_EVENT_NULLED,
    MARPAWRAPPERGRAMMAR_EVENT_EXPECTED,
    MARPAWRAPPERGRAMMAR_EVENT_EXHAUSTED
  } eventType;
  int symboli; /* -1 in case of exhaustion, symbolId otherwise */
} marpaWrapperGrammarEvent_t;

/* ------------------ */
/* Options per symbol */
/* ------------------ */
typedef struct marpaWrapperGrammarSymbolOption {
  short  terminalb;             /* Default: 0. Eventually force symbol to be terminal         */
  short  startb;                /* Default: 0. Eventually force symbol to be the start symbol */
  int    eventSeti;             /* Default: MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE.               */
} marpaWrapperGrammarSymbolOption_t;

/* ---------------- */
/* Options per rule */
/* ---------------- */
typedef struct marpaWrapperGrammarRuleOption {
  int    ranki;          /* Default: 0. Rank                                        */
  short  nullRanksHighb; /* Default: 0. Null variant pattern                        */
  short  sequenceb;      /* Default: 0. Sequence ?                                  */
  int    separatorSymboli; /* Default: NULL. Eventual separator symbol              */
  short  properb;        /* Default: 0. Proper flag                                 */
  int    minimumi;       /* Default: 0. Mininimum - must be 0 or 1                  */
} marpaWrapperGrammarRuleOption_t;

/* --------------- */
/* General options */
/* --------------- */
typedef struct marpaWrapperGrammarOption {
  genericLogger_t *genericLoggerp;             /* Default: NULL.                                      */
  short            warningIsErrorb;            /* Default: 0. Have precedence over warningIsIgnoredb  */
  short            warningIsIgnoredb;          /* Default: 0.                                         */
  short            autorankb;                  /* Default: 0.                                         */
} marpaWrapperGrammarOption_t;

typedef enum marpaWrapperSymbolProperty {
  MARPAWRAPPER_SYMBOL_IS_ACCESSIBLE = 0x01,
  MARPAWRAPPER_SYMBOL_IS_NULLABLE   = 0x02,
  MARPAWRAPPER_SYMBOL_IS_NULLING    = 0x04,
  MARPAWRAPPER_SYMBOL_IS_PRODUCTIVE = 0x08,
  MARPAWRAPPER_SYMBOL_IS_START      = 0x10,
  MARPAWRAPPER_SYMBOL_IS_TERMINAL   = 0x20
} marpaWrapperSymbolProperty_t;

typedef enum marpaWrapperRuleProperty {
  MARPAWRAPPER_RULE_IS_ACCESSIBLE = 0x01,
  MARPAWRAPPER_RULE_IS_NULLABLE   = 0x02,
  MARPAWRAPPER_RULE_IS_NULLING    = 0x04,
  MARPAWRAPPER_RULE_IS_LOOP       = 0x08,
  MARPAWRAPPER_RULE_IS_PRODUCTIVE = 0x10
} marpaWrapperRuleProperty_t;

typedef short (*marpaWrapperGrammar_grammarOptionSetter_t)(void *userDatavp, marpaWrapperGrammarOption_t *marpaWrapperGrammarOptionp);
typedef short (*marpaWrapperGrammar_symbolOptionSetter_t)(void *userDatavp, int symboli, marpaWrapperGrammarSymbolOption_t *marpaWrapperGrammarSymbolOptionp);
typedef short (*marpaWrapperGrammar_ruleOptionSetter_t)(void *userDatavp, int rulei, marpaWrapperGrammarRuleOption_t *marpaWrapperGrammarRuleOptionp);

typedef struct marpaWrapperGrammarCloneOption {
  void                                      *userDatavp;           /* Default: NULL. User context */
  marpaWrapperGrammar_grammarOptionSetter_t  grammarOptionSetterp; /* Default: NULL. Overwrite grammar option */
  marpaWrapperGrammar_symbolOptionSetter_t   symbolOptionSetterp;  /* Default: NULL. Overwrite event symbol option */
  marpaWrapperGrammar_ruleOptionSetter_t     ruleOptionSetterp;    /* Default: NULL. Overwrite event rule option */
} marpaWrapperGrammarCloneOption_t;

#ifdef __cplusplus
extern "C" {
#endif
  marpaWrapper_EXPORT marpaWrapperGrammar_t *marpaWrapperGrammar_newp(marpaWrapperGrammarOption_t *marpaWrapperGrammarOptionp);
  marpaWrapper_EXPORT marpaWrapperGrammar_t *marpaWrapperGrammar_clonep(marpaWrapperGrammar_t *marpaWrapperGrammarOriginp, marpaWrapperGrammarCloneOption_t *marpaWrapperGrammarCloneOptionp);
  marpaWrapper_EXPORT void                   marpaWrapperGrammar_freev(marpaWrapperGrammar_t *marpaWrapperGrammarp);

  marpaWrapper_EXPORT int                    marpaWrapperGrammar_newSymboli(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperGrammarSymbolOption_t *marpaWrapperGrammarSymbolOptionp);
  marpaWrapper_EXPORT short                  marpaWrapperGrammar_symbolPropertyb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int symboli, int *marpaWrapperSymbolPropertyBitSetp);
  marpaWrapper_EXPORT int                    marpaWrapperGrammar_newRulei(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperGrammarRuleOption_t *marpaWrapperGrammarRuleOptionp,
										int lhsSymboli,
										size_t rhsSymboll, int *rhsSymbolip
										);
  marpaWrapper_EXPORT short                  marpaWrapperGrammar_rulePropertyb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int rulei, int *marpaWrapperRulePropertyBitSetp);
  /* Handy methods to create symbols and rules that I find more user-friendly */
  marpaWrapper_EXPORT int                    marpaWrapperGrammar_newSymbolExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, short terminalb, short startb, int eventSeti);
  marpaWrapper_EXPORT int                    marpaWrapperGrammar_newRuleExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, int ranki, short nullRanksHighb, int lhsSymboli, ...);
  marpaWrapper_EXPORT int                    marpaWrapperGrammar_newSequenceExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, int ranki, short nullRanksHighb,
										       int lhsSymboli,
										       int rhsSymboli, int minimumi, int separatorSymboli, short properb);
  
  marpaWrapper_EXPORT short                  marpaWrapperGrammar_precomputeb(marpaWrapperGrammar_t *marpaWrapperGrammarp);
  marpaWrapper_EXPORT short                  marpaWrapperGrammar_precompute_startb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int starti);
  marpaWrapper_EXPORT short                  marpaWrapperGrammar_eventb(marpaWrapperGrammar_t *marpaWrapperGrammarp, size_t *eventlp, marpaWrapperGrammarEvent_t **eventpp, short exhaustionEventb, short forceReloadb);
#ifdef __cplusplus
}
#endif

/* Very often, symbols and rules are created with no particular attribute */
/* These macros are just short-hands to make life easier.                 */
#define MARPAWRAPPERGRAMMAR_NEWSYMBOL(marpaWrapperGrammarp) marpaWrapperGrammar_newSymboli((marpaWrapperGrammarp), NULL)
#define MARPAWRAPPERGRAMMAR_NEWRULE(marpaWrapperGrammarp, lhsSymboli, ...) marpaWrapperGrammar_newRuleExti((marpaWrapperGrammarp), 0, 0, (lhsSymboli), __VA_ARGS__)
#define MARPAWRAPPERGRAMMAR_NEWSEQUENCE(marpaWrapperGrammarp, lhsSymboli, rhsSymboli, minimumi) marpaWrapperGrammar_newSequenceExti((marpaWrapperGrammarp), 0, 0, (lhsSymboli), (rhsSymboli), (minimumi), -1, 0)

#endif /* MARPAWRAPPER_GRAMMAR */
