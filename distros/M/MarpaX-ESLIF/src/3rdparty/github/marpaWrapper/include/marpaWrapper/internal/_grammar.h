#ifndef MARPAWRAPPER_INTERNAL_GRAMMAR_H
#define MARPAWRAPPER_INTERNAL_GRAMMAR_H

#include <stddef.h>
#include "marpaWrapper/grammar.h"
#include "marpa.h"

typedef struct marpaWrapperGrammarSymbol {
  Marpa_Symbol_ID                   marpaSymbolIdi;
  marpaWrapperGrammarSymbolOption_t marpaWrapperGrammarSymbolOption;
} marpaWrapperGrammarSymbol_t;

typedef struct marpaWrapperGrammarRule {
  Marpa_Rule_ID                   marpaRuleIdi;
  marpaWrapperGrammarRuleOption_t marpaWrapperGrammarRuleOption;
} marpaWrapperGrammarRule_t;

struct marpaWrapperGrammar {
  short                         precomputedb; /* Flag saying it is has be precomputed */
  short                         haveStartb;   /* Flag saying it a start symbol was explicitely declare */

  marpaWrapperGrammarOption_t   marpaWrapperGrammarOption;
  Marpa_Grammar                 marpaGrammarp;
  Marpa_Config                  marpaConfig;

  /* Storage of symbols */
  size_t                        sizeSymboll;           /* Allocated size */
  size_t                        nSymboll;              /* Used size      */
  marpaWrapperGrammarSymbol_t  *symbolArrayp;

  /* Storage of rules */
  size_t                        sizeRulel;           /* Allocated size */
  size_t                        nRulel;              /* Used size      */
  marpaWrapperGrammarRule_t    *ruleArrayp;

  /* Last events list */
  size_t                        sizeEventl;           /* Allocated size */
  size_t                        nEventl;              /* Used size      */
  marpaWrapperGrammarEvent_t   *eventArrayp;
};

#endif /* MARPAWRAPPER_INTERNAL_GRAMMAR_H */
