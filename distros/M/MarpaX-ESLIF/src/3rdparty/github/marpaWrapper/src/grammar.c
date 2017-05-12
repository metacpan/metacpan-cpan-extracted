#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "marpa.h"
#include "config.h"
#include "marpaWrapper/internal/_manageBuf.h"
#include "marpaWrapper/internal/_logging.h"
#include "marpaWrapper/internal/_grammar.h"

static marpaWrapperGrammarOption_t marpaWrapperGrammarOptionDefault = {
  NULL,    /* genericLoggerp             */
  0,       /* warningIsErrorb            */
  0,       /* warningIsIgnoredb          */
  0        /* autorankb                  */
};

static marpaWrapperGrammarSymbolOption_t marpaWrapperGrammarSymbolOptionDefault = {
  0,                                  /* terminalb */
  0,                                  /* startb */
  MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE  /* eventSeti */
};

static marpaWrapperGrammarRuleOption_t marpaWrapperGrammarRuleOptionDefault = {
   0,   /* ranki */
   0,   /* nullRanksHighb */
   0,   /* sequenceb */
  -1,   /* separatorSymboli */
   0,   /* properb */
   0    /* minimumi */
};

static marpaWrapperGrammarCloneOption_t marpaWrapperGrammarCloneOptionDefault = {
  NULL, /* userDatavp */
  NULL, /* genericLoggerSetterp */
  NULL, /* symbolOptionSetterp */
  NULL  /* ruleOptionSetterp */
};

#define MARPAWRAPPERGRAMMAREVENT_WEIGHT(eventType) ((eventType) == MARPAWRAPPERGRAMMAR_EVENT_COMPLETED) ? -1 : (((eventType) == MARPAWRAPPERGRAMMAR_EVENT_NULLED) ? 0 : 1)
static inline int   _marpaWrapperGrammar_cmpi(const void *event1p, const void *event2p);
static inline short _marpaWrapperGrammar_precomputeb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int *startip);

/****************************************************************************/
marpaWrapperGrammar_t *marpaWrapperGrammar_newp(marpaWrapperGrammarOption_t *marpaWrapperGrammarOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_newp);
  marpaWrapperGrammar_t *marpaWrapperGrammarp = NULL;
  genericLogger_t       *genericLoggerp = NULL;
#ifndef MARPAWRAPPER_NTRACE
  int                    marpaVersionip[3];
#endif

  if (marpaWrapperGrammarOptionp == NULL) {
    marpaWrapperGrammarOptionp = &marpaWrapperGrammarOptionDefault;
  }
  genericLoggerp = marpaWrapperGrammarOptionp->genericLoggerp;

#ifndef MARPAWRAPPER_NTRACE
  {
    /* Get marpa version */
    Marpa_Error_Code marpaErrorCodei = marpa_version(&(marpaVersionip[0]));
    if (marpaErrorCodei < 0) {
      MARPAWRAPPER_ERROR(genericLoggerp, "marpa_version failure");
      goto err;
    }
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_version: %d.%d.%d", marpaVersionip[0], marpaVersionip[1], marpaVersionip[2]);
  }
#endif

  marpaWrapperGrammarp = malloc(sizeof(marpaWrapperGrammar_t));
  if (marpaWrapperGrammarp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  marpaWrapperGrammarp->precomputedb              = 0;
  marpaWrapperGrammarp->haveStartb                = 0;
  marpaWrapperGrammarp->marpaWrapperGrammarOption = *marpaWrapperGrammarOptionp;
  marpaWrapperGrammarp->marpaGrammarp             = NULL;
  /* See first instruction after this initialization block: marpaWrapperGrammarp->marpaConfig */
  marpaWrapperGrammarp->sizeSymboll               = 0;
  marpaWrapperGrammarp->nSymboll                  = 0;
  marpaWrapperGrammarp->symbolArrayp              = NULL;
  marpaWrapperGrammarp->sizeRulel                 = 0;
  marpaWrapperGrammarp->nRulel                    = 0;
  marpaWrapperGrammarp->ruleArrayp                = NULL;
  marpaWrapperGrammarp->sizeEventl                = 0;
  marpaWrapperGrammarp->nEventl                   = 0;
  marpaWrapperGrammarp->eventArrayp               = NULL;

  /* Initialize Marpa - always succeed as per the doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_c_init(%p)", &(marpaWrapperGrammarp->marpaConfig));
  marpa_c_init(&(marpaWrapperGrammarp->marpaConfig));

  /* Create a grammar instance */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_new(%p)", &(marpaWrapperGrammarp->marpaConfig));
  marpaWrapperGrammarp->marpaGrammarp = marpa_g_new(&(marpaWrapperGrammarp->marpaConfig));
  if (marpaWrapperGrammarp->marpaGrammarp == NULL) {
    MARPAWRAPPER_MARPA_C_ERROR(genericLoggerp, &(marpaWrapperGrammarp->marpaConfig));
    goto err;
  }

  /* Turn off obsolete features as per the doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_force_valued(%p)", marpaWrapperGrammarp->marpaGrammarp);
  if (marpa_g_force_valued(marpaWrapperGrammarp->marpaGrammarp) < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  if (genericLoggerp != NULL) {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Cloning genericLogger");

    marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp = GENERICLOGGER_CLONE(genericLoggerp);
    if (marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Failed to clone genericLogger: %s", strerror(errno));
      goto err;
    }
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperGrammarp);
  return marpaWrapperGrammarp;

 err:
  if (marpaWrapperGrammarp != NULL) {
    int errnoi = errno;

    if ((genericLoggerp != NULL) &&
        (marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp != NULL) &&
        (marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp != genericLoggerp)) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned genericLogger");
      GENERICLOGGER_FREE(marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp);
    }
    marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp = NULL;
    marpaWrapperGrammar_freev(marpaWrapperGrammarp);

    errno = errnoi;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
marpaWrapperGrammar_t *marpaWrapperGrammar_clonep(marpaWrapperGrammar_t *marpaWrapperGrammarOriginp, marpaWrapperGrammarCloneOption_t *marpaWrapperGrammarCloneOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_clonep);
  marpaWrapperGrammar_t            *marpaWrapperGrammarp = NULL;
  genericLogger_t                  *genericLoggerp       = NULL;
  int                              *rhsSymbolip          = NULL;
  size_t                            i;
  int                               marpaSymbolIdi;
  int                               marpaRuleIdi;
  int                               lhsSymboli;
  int                               ruleLengthi;
  int                               j;
  marpaWrapperGrammarOption_t       marpaWrapperGrammarOption;
  marpaWrapperGrammarSymbolOption_t marpaWrapperGrammarSymbolOption;
  marpaWrapperGrammarRuleOption_t   marpaWrapperGrammarRuleOption;

  if (marpaWrapperGrammarOriginp == NULL) {
    errno = EINVAL;
    return NULL;
  }

  if (marpaWrapperGrammarCloneOptionp == NULL) {
    marpaWrapperGrammarCloneOptionp = &marpaWrapperGrammarCloneOptionDefault;
  }

  genericLoggerp = marpaWrapperGrammarOriginp->marpaWrapperGrammarOption.genericLoggerp;

  /* Create the grammar */
  marpaWrapperGrammarOption = marpaWrapperGrammarOriginp->marpaWrapperGrammarOption;
  if (marpaWrapperGrammarCloneOptionp->grammarOptionSetterp != NULL) {
    if (! marpaWrapperGrammarCloneOptionp->grammarOptionSetterp(marpaWrapperGrammarCloneOptionp->userDatavp, &marpaWrapperGrammarOption)) {
      goto err;
    }
  }
  marpaWrapperGrammarp = marpaWrapperGrammar_newp(&marpaWrapperGrammarOption);
  if (marpaWrapperGrammarp == NULL) {
    goto err;
  }
  /* From now on, marpaWrapperGrammarp->marpaWrapperGrammarOption is a copy of marpaWrapperGrammarOriginp->marpaWrapperGrammarOption */

  /* Create the symbols - verifying IDs are identical - per def event set is similar */
  for (i = 0; i < marpaWrapperGrammarOriginp->nSymboll; i++) {
    marpaWrapperGrammarSymbolOption = marpaWrapperGrammarOriginp->symbolArrayp[i].marpaWrapperGrammarSymbolOption;
    if (marpaWrapperGrammarCloneOptionp->symbolOptionSetterp != NULL) {
      if (! marpaWrapperGrammarCloneOptionp->symbolOptionSetterp(marpaWrapperGrammarCloneOptionp->userDatavp,
                                                                 marpaWrapperGrammarOriginp->symbolArrayp[i].marpaSymbolIdi,
                                                                 &marpaWrapperGrammarSymbolOption)) {
        goto err;
      }
    }
    marpaSymbolIdi = marpaWrapperGrammar_newSymboli(marpaWrapperGrammarp, &marpaWrapperGrammarSymbolOption);
    if (marpaSymbolIdi < 0) {
      goto err;
    }
    if (marpaSymbolIdi != marpaWrapperGrammarOriginp->symbolArrayp[i].marpaSymbolIdi) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Cloned symbol ID is %d instead of %d", marpaSymbolIdi, marpaWrapperGrammarOriginp->symbolArrayp[i].marpaSymbolIdi);
      goto err;
    }
  }

  /* Create the rules - verifying IDs are identical */
  for (i = 0; i < marpaWrapperGrammarOriginp->nRulel; i++) {
    /* rule creation does not keep track of rule definition - we just have to ask for it */
    /* - LHS */
    lhsSymboli = marpa_g_rule_lhs(marpaWrapperGrammarOriginp->marpaGrammarp, marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi);
    if (lhsSymboli < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarOriginp->marpaGrammarp);
      goto err;
    }
    /* - Number of RHS */
    ruleLengthi = marpa_g_rule_length(marpaWrapperGrammarOriginp->marpaGrammarp, marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi);
    if (ruleLengthi < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarOriginp->marpaGrammarp);
      goto err;
    }
    if (ruleLengthi > 0) {
      rhsSymbolip = (int *) malloc(ruleLengthi * sizeof(int));
      if (rhsSymbolip == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	goto err;
      }
    }
    /* - RHS list */
    for (j = 0; j < ruleLengthi; j++) {
      rhsSymbolip[j] = marpa_g_rule_rhs(marpaWrapperGrammarOriginp->marpaGrammarp, marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi, j);
      if (rhsSymbolip[j] < 0) {
	MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarOriginp->marpaGrammarp);
	goto err;
      }
    }
    /* - Create the rule */
    marpaWrapperGrammarRuleOption = marpaWrapperGrammarOriginp->ruleArrayp[i].marpaWrapperGrammarRuleOption;
    if (marpaWrapperGrammarCloneOptionp->ruleOptionSetterp != NULL) {
      if (! marpaWrapperGrammarCloneOptionp->ruleOptionSetterp(marpaWrapperGrammarCloneOptionp->userDatavp,
                                                               marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi,
                                                               &marpaWrapperGrammarRuleOption)) {
        goto err;
      }
    }
    marpaRuleIdi = marpaWrapperGrammar_newRulei(marpaWrapperGrammarp,
						&marpaWrapperGrammarRuleOption,
						lhsSymboli,
						(size_t) ruleLengthi,
						rhsSymbolip);
    if (marpaRuleIdi < 0) {
      goto err;
    }
    if (marpaRuleIdi != marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Cloned rule ID is %d instead of %d", marpaRuleIdi, marpaWrapperGrammarOriginp->ruleArrayp[i].marpaRuleIdi);
      goto err;
    }
    /* - Free eventual RHS list */
    if (rhsSymbolip != NULL) {
      free(rhsSymbolip);
      rhsSymbolip = NULL;
    }
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperGrammarp);
  return marpaWrapperGrammarp;

 err:
  if (rhsSymbolip != NULL) {
    free(rhsSymbolip);
  }
  marpaWrapperGrammar_freev(marpaWrapperGrammarp);
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
void marpaWrapperGrammar_freev(marpaWrapperGrammar_t *marpaWrapperGrammarp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_freev);
  genericLogger_t  *genericLoggerp;

  if (marpaWrapperGrammarp != NULL) {
    /* Keep a copy of the generic logger. If original is not NULL, then we have a clone of it */
    genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

    if (marpaWrapperGrammarp->marpaGrammarp != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_unref(%p)", marpaWrapperGrammarp->marpaGrammarp);
      marpa_g_unref(marpaWrapperGrammarp->marpaGrammarp);
    }

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing symbol table");
    manageBuf_freev(genericLoggerp, (void **) &(marpaWrapperGrammarp->symbolArrayp));

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing rule table");
    manageBuf_freev(genericLoggerp, (void **) &(marpaWrapperGrammarp->ruleArrayp));

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing last list of events");
    manageBuf_freev(genericLoggerp, (void **) &(marpaWrapperGrammarp->eventArrayp));

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "free(%p)", marpaWrapperGrammarp);
    free(marpaWrapperGrammarp);

    if (genericLoggerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned generic logger");
      GENERICLOGGER_FREE(genericLoggerp);
    }
  }
}

/****************************************************************************/
int marpaWrapperGrammar_newSymboli(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperGrammarSymbolOption_t *marpaWrapperGrammarSymbolOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_newSymboli);
  Marpa_Symbol_ID                   marpaSymbolIdi;
  genericLogger_t                  *genericLoggerp = NULL;
  size_t                            nSymboll;
  marpaWrapperGrammarSymbol_t      *marpaWrapperSymbolp;
  marpaWrapperGrammarSymbolOption_t marpaWrapperGrammarSymbolOption;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

  /* Create symbol */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_new(%p)", marpaWrapperGrammarp->marpaGrammarp);
  marpaSymbolIdi = marpa_g_symbol_new(marpaWrapperGrammarp->marpaGrammarp);
  if (marpaSymbolIdi == -2) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Allocate room for the new symbol */
  nSymboll = marpaSymbolIdi + 1;
  if (manageBuf_createp(genericLoggerp,
			(void **) &(marpaWrapperGrammarp->symbolArrayp),
			&(marpaWrapperGrammarp->sizeSymboll),
			nSymboll,
			sizeof(marpaWrapperGrammarSymbol_t)) == NULL) {
    goto err;
  }

  marpaWrapperSymbolp = &(marpaWrapperGrammarp->symbolArrayp[marpaSymbolIdi]);
  marpaWrapperGrammarp->nSymboll = nSymboll;

  /* Fill the symbol structure */
  marpaWrapperSymbolp->marpaSymbolIdi = marpaSymbolIdi;
  if (marpaWrapperGrammarSymbolOptionp == NULL) {
    marpaWrapperGrammarSymbolOption = marpaWrapperGrammarSymbolOptionDefault;
  } else {
    marpaWrapperGrammarSymbolOption = *marpaWrapperGrammarSymbolOptionp;
  }

  /* Apply options */

  if (marpaWrapperGrammarSymbolOption.terminalb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_terminal_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi, (int) 1);
    if (marpa_g_symbol_is_terminal_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi, 1) != 1) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if (marpaWrapperGrammarSymbolOption.startb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_start_symbol_set(%p, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi);
    if (marpa_g_start_symbol_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi) < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
    marpaWrapperGrammarp->haveStartb = 1;
  }

  if ((marpaWrapperGrammarSymbolOption.eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_COMPLETION) == MARPAWRAPPERGRAMMAR_EVENTTYPE_COMPLETION) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_completion_event_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi, (int) 1);
    if (marpa_g_symbol_is_completion_event_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi, 1) != 1) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if ((marpaWrapperGrammarSymbolOption.eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_NULLED) == MARPAWRAPPERGRAMMAR_EVENTTYPE_NULLED) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_nulled_event_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi, (int) 1);
    if (marpa_g_symbol_is_nulled_event_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi, 1) != 1) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if ((marpaWrapperGrammarSymbolOption.eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_PREDICTION) == MARPAWRAPPERGRAMMAR_EVENTTYPE_PREDICTION) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_prediction_event_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi, (int) 1);
    if (marpa_g_symbol_is_prediction_event_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi, 1) != 1) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  marpaWrapperSymbolp->marpaWrapperGrammarSymbolOption = marpaWrapperGrammarSymbolOption;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", (int) marpaSymbolIdi);
  return (int) marpaSymbolIdi;
  
 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}

/****************************************************************************/
int marpaWrapperGrammar_newSymbolExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, short terminalb, short startb, int eventSeti)
/****************************************************************************/
{
  marpaWrapperGrammarSymbolOption_t marpaWrapperGrammarSymbolOption;

  marpaWrapperGrammarSymbolOption.terminalb           = terminalb;
  marpaWrapperGrammarSymbolOption.startb              = startb;
  marpaWrapperGrammarSymbolOption.eventSeti           = eventSeti;

  return marpaWrapperGrammar_newSymboli(marpaWrapperGrammarp, &marpaWrapperGrammarSymbolOption);
}

/****************************************************************************/
int marpaWrapperGrammar_newRulei(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperGrammarRuleOption_t *marpaWrapperGrammarRuleOptionp,
                                 int lhsSymboli,
                                 size_t rhsSymboll, int *rhsSymbolip
                                 )
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_newRulei);
  Marpa_Rule_ID                   marpaRuleIdi;
  genericLogger_t                *genericLoggerp = NULL;
  marpaWrapperGrammarRule_t      *marpaWrapperRulep;
  int                             sequenceFlagsi;
  size_t                          nRulel;
  size_t                          i;
  Marpa_Symbol_ID                 marpaLhsIdi;
  marpaWrapperGrammarRuleOption_t marpaWrapperGrammarRuleOption;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

  /* Check parameters - Some depend on marpaWrapperGrammarRuleOptionp */
  if (marpaWrapperGrammarRuleOptionp == NULL) {
    marpaWrapperGrammarRuleOption = marpaWrapperGrammarRuleOptionDefault;
  } else {
    marpaWrapperGrammarRuleOption = *marpaWrapperGrammarRuleOptionp;
  }

  if (lhsSymboli < 0) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Bad LHS symbol Id");
    goto err;
  }
  if (marpaWrapperGrammarRuleOption.sequenceb != 0) {
    if (rhsSymboll != 1) {
      MARPAWRAPPER_ERROR(genericLoggerp, "A sequence must have exactly one RHS");
      goto err;
    }
    if ((marpaWrapperGrammarRuleOption.minimumi != 0) && (marpaWrapperGrammarRuleOption.minimumi != 1)) {
      MARPAWRAPPER_ERROR(genericLoggerp, "A sequence must have a minimum of exactly 0 or 1");
      goto err;
    }
  }

  if (marpaWrapperGrammarp->marpaWrapperGrammarOption.autorankb != 0) {
    if (marpaWrapperGrammarRuleOption.ranki != 0) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Rule rank %d is ignored when autorank is on", marpaWrapperGrammarRuleOption.ranki);
    }
    /* We have to scan all the rules to find the latest, and the use the latest minus one as rank */
    if (marpaWrapperGrammarp->nRulel > 0) {
      for (i = 0; i < marpaWrapperGrammarp->nRulel; i++) {
	marpaRuleIdi = marpaWrapperGrammarp->ruleArrayp[i].marpaRuleIdi;
	marpaLhsIdi = marpa_g_rule_lhs(marpaWrapperGrammarp->marpaGrammarp, marpaRuleIdi);
	if (marpaLhsIdi < 0) {
	  MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
	  goto err;
	}
	if (marpaLhsIdi == (Marpa_Symbol_ID) lhsSymboli) {
	  /* Another rule with the same LHS already exist, and this is the rule No i */
	  marpaWrapperGrammarRuleOption.ranki = marpaWrapperGrammarp->ruleArrayp[i].marpaWrapperGrammarRuleOption.ranki;
	}
      }
    }
    marpaWrapperGrammarRuleOption.ranki--;
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Autosetted rule rank to %d", marpaWrapperGrammarRuleOption.ranki);
  }

    /* Create rule; it is either a sequence, either a list of RHS */
  if (marpaWrapperGrammarRuleOption.sequenceb != 0) {
    sequenceFlagsi = 0;
    if (marpaWrapperGrammarRuleOption.properb != 0) {
      sequenceFlagsi |= MARPA_PROPER_SEPARATION;
    }
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_sequence_new(%p, %d, %d, %d, %d, %s)", marpaWrapperGrammarp->marpaGrammarp, lhsSymboli, (int) rhsSymbolip[0], (int) marpaWrapperGrammarRuleOption.separatorSymboli, marpaWrapperGrammarRuleOption.minimumi, ((sequenceFlagsi & MARPA_PROPER_SEPARATION) == MARPA_PROPER_SEPARATION) ? "MARPA_PROPER_SEPARATION" : "0");
    marpaRuleIdi = marpa_g_sequence_new(marpaWrapperGrammarp->marpaGrammarp,
					lhsSymboli,
					(Marpa_Symbol_ID) rhsSymbolip[0],
					(Marpa_Symbol_ID) marpaWrapperGrammarRuleOption.separatorSymboli,
					marpaWrapperGrammarRuleOption.minimumi,
					sequenceFlagsi);
  } else {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_new(%p, %d, %p, %d)", marpaWrapperGrammarp->marpaGrammarp, lhsSymboli, rhsSymbolip, (int) rhsSymboll);
    marpaRuleIdi = marpa_g_rule_new(marpaWrapperGrammarp->marpaGrammarp,
				    lhsSymboli,
				    (Marpa_Symbol_ID *) rhsSymbolip,
				    rhsSymboll);
  }

  if (marpaRuleIdi == -2) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Apply options */
  if (marpaWrapperGrammarRuleOption.ranki != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_rank_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaRuleIdi, marpaWrapperGrammarRuleOption.ranki);
    marpa_g_rule_rank_set(marpaWrapperGrammarp->marpaGrammarp, marpaRuleIdi, marpaWrapperGrammarRuleOption.ranki);
    if (marpa_g_error(marpaWrapperGrammarp->marpaGrammarp, NULL) != MARPA_ERR_NONE) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if (marpaWrapperGrammarRuleOption.nullRanksHighb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_null_high_set(%p, %d, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaRuleIdi, 1);
    if (marpa_g_rule_null_high_set(marpaWrapperGrammarp->marpaGrammarp, marpaRuleIdi, 1) < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  /* Allocate room for the new rule */
  nRulel = marpaRuleIdi + 1;
  if (manageBuf_createp(genericLoggerp,
			(void **) &(marpaWrapperGrammarp->ruleArrayp),
			&(marpaWrapperGrammarp->sizeRulel),
			nRulel,
			sizeof(marpaWrapperGrammarRule_t)) == NULL) {
    goto err;
  }

  marpaWrapperRulep = &(marpaWrapperGrammarp->ruleArrayp[marpaRuleIdi]);
  marpaWrapperRulep->marpaRuleIdi                  = marpaRuleIdi;
  marpaWrapperRulep->marpaWrapperGrammarRuleOption = marpaWrapperGrammarRuleOption;

  marpaWrapperGrammarp->nRulel = nRulel;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", (int) marpaRuleIdi);
  return (int) marpaRuleIdi;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}

/****************************************************************************/
int marpaWrapperGrammar_newRuleExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, int ranki, short nullRanksHighb, int lhsSymboli, ...)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_newRuleExti);
  marpaWrapperGrammarRuleOption_t marpaWrapperGrammarRuleOption;
  genericLogger_t                *genericLoggerp = NULL;
  size_t                          sizeSymboll = 0;
  size_t                          nSymboll = 0;
  int                            *rhsSymbolip = NULL;
  int                             rhsSymboli;
  int                             rulei;
  va_list                         ap;
  
  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

  marpaWrapperGrammarRuleOption.ranki            = ranki;
  marpaWrapperGrammarRuleOption.nullRanksHighb   = nullRanksHighb;
  marpaWrapperGrammarRuleOption.sequenceb        = 0;
  marpaWrapperGrammarRuleOption.separatorSymboli = -1;
  marpaWrapperGrammarRuleOption.properb          = 0;
  marpaWrapperGrammarRuleOption.minimumi         = 0;

  va_start(ap, lhsSymboli);
  while ((rhsSymboli = va_arg(ap, int)) >= 0) {
    if (manageBuf_createp(genericLoggerp, (void **) &rhsSymbolip, &sizeSymboll, nSymboll + 1, sizeof(marpaWrapperGrammarSymbol_t)) == NULL) {
      goto err;
    }
    rhsSymbolip[nSymboll++] = rhsSymboli;
  }
  va_end(ap);

  rulei = marpaWrapperGrammar_newRulei(marpaWrapperGrammarp, &marpaWrapperGrammarRuleOption, lhsSymboli, nSymboll, rhsSymbolip);
  manageBuf_freev(genericLoggerp, (void **) &rhsSymbolip);

  return rulei;

 err:
  if (rhsSymbolip != NULL) {
    int errnoi = errno;
    manageBuf_freev(genericLoggerp, (void **) &rhsSymbolip);
    errno = errnoi;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}

/****************************************************************************/
int marpaWrapperGrammar_newSequenceExti(marpaWrapperGrammar_t *marpaWrapperGrammarp, int ranki, short nullRanksHighb,
                                        int lhsSymboli,
                                        int rhsSymboli, int minimumi, int separatorSymboli, short properb)
/****************************************************************************/
{
  marpaWrapperGrammarRuleOption_t marpaWrapperGrammarRuleOption;
  int                             rhsSymbolip[1] = { rhsSymboli };

  switch (minimumi) {
  case '*':
    minimumi = 0;
    break;
  case '+':
    minimumi = 1;
    break;
  default:
    break;
  }
  
  marpaWrapperGrammarRuleOption.ranki            = ranki;
  marpaWrapperGrammarRuleOption.nullRanksHighb   = nullRanksHighb;
  marpaWrapperGrammarRuleOption.sequenceb        = 1;
  marpaWrapperGrammarRuleOption.separatorSymboli = separatorSymboli;
  marpaWrapperGrammarRuleOption.properb          = properb;
  marpaWrapperGrammarRuleOption.minimumi         = minimumi;

  return marpaWrapperGrammar_newRulei(marpaWrapperGrammarp, &marpaWrapperGrammarRuleOption, lhsSymboli, 1, rhsSymbolip);
}

/****************************************************************************/
short marpaWrapperGrammar_precomputeb(marpaWrapperGrammar_t *marpaWrapperGrammarp)
/****************************************************************************/
{
  return _marpaWrapperGrammar_precomputeb(marpaWrapperGrammarp, NULL);
}

/****************************************************************************/
short marpaWrapperGrammar_precompute_startb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int starti)
/****************************************************************************/
{
  return _marpaWrapperGrammar_precomputeb(marpaWrapperGrammarp, &starti);
}

/****************************************************************************/
static inline short _marpaWrapperGrammar_precomputeb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int *startip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_precomputeb);
  genericLogger_t            *genericLoggerp = NULL;
  int                         starti;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

  if (startip != NULL) {
    /* Start symbol out of bounds ? */
    starti = *startip;
    if ((starti < 0) || (((size_t) starti) >= marpaWrapperGrammarp->nSymboll)) {
      if (marpaWrapperGrammarp->nSymboll > 0) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "Start symbol is out of range: %d but should be in [0..%d]", starti, marpaWrapperGrammarp->nSymboll - 1);
      } else {
	MARPAWRAPPER_ERRORF(genericLoggerp, "Start symbol is out of range: %d but there is no symbol", starti);
      }
      goto err;
    }
  } else {
    /* Use arbitrarily first symbol as start symbol */
    starti = 0;
  }

  if (((marpaWrapperGrammarp->haveStartb == 0) || (startip != NULL)) && (marpaWrapperGrammarp->nSymboll > 0)) {
    marpaWrapperGrammarSymbol_t *marpaWrapperSymbolp = &(marpaWrapperGrammarp->symbolArrayp[starti]);

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_start_symbol_set(%p, %d)", marpaWrapperGrammarp->marpaGrammarp, (int) marpaWrapperSymbolp->marpaSymbolIdi);
    if (marpa_g_start_symbol_set(marpaWrapperGrammarp->marpaGrammarp, marpaWrapperSymbolp->marpaSymbolIdi) < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
    marpaWrapperGrammarp->haveStartb = 1;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_precompute(%p)", marpaWrapperGrammarp->marpaGrammarp);
  if (marpa_g_precompute(marpaWrapperGrammarp->marpaGrammarp) < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Prefetch events */
  if (marpaWrapperGrammar_eventb(marpaWrapperGrammarp, NULL, NULL, 0 /* exhaustionEventb */, 1) == 0) {
    goto err;
  }
  
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperGrammar_eventb(marpaWrapperGrammar_t *marpaWrapperGrammarp, size_t *eventlp, marpaWrapperGrammarEvent_t **eventpp, short exhaustionEventb, short forceReloadb)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_eventb);
  genericLogger_t                  *genericLoggerp = NULL;
  marpaWrapperGrammarEvent_t       *eventp         = NULL;
  int                               nbEventi;
  int                               i;
  int                               subscribedEventi;
  const char                       *msgs;
  const char                       *warningMsgs;
  const char                       *fatalMsgs;
  const char                       *infoMsgs;
  Marpa_Event_Type                  eventType;
  Marpa_Event                       event;
  int                               eventValuei;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;

  /* Events are always fetched when necessary internally. External API can nevertheless */
  /* force the refresh on demand.                                                       */
  if (forceReloadb != 0) {

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Updating cached event list");
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_event_count(%p)", marpaWrapperGrammarp->marpaGrammarp);
    nbEventi = marpa_g_event_count(marpaWrapperGrammarp->marpaGrammarp);
    if (nbEventi < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Number of events: %d", nbEventi);

    /* This variable is the number of subscribed events */
    marpaWrapperGrammarp->nEventl = 0;

    if (nbEventi > 0) {
      /* Get all events, with a distinction between warnings, and the subscriptions */
      for (i = 0, subscribedEventi = 0; i < nbEventi; i++) {
    
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_event(%p, %p, %d)", marpaWrapperGrammarp->marpaGrammarp, &event, i);
        eventType = marpa_g_event(marpaWrapperGrammarp->marpaGrammarp, &event, i);
        if (eventType < 0) {
          MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
          goto err;
        }

        msgs = (eventType < MARPA_EVENT_COUNT) ? marpa_event_description[eventType].suggested : NULL;
        if (msgs == NULL) {
          MARPAWRAPPER_ERRORF(genericLoggerp, "Unknown event type %d", (int) eventType);
          goto err;
        }
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Event %d: %s", (int) eventType, msgs);

        warningMsgs = NULL;
        fatalMsgs   = NULL;
        infoMsgs    = NULL;

        switch (eventType) {
        case MARPA_EVENT_NONE:
          break;
        case MARPA_EVENT_COUNTED_NULLABLE:
          fatalMsgs = msgs;
          break;
        case MARPA_EVENT_EARLEY_ITEM_THRESHOLD:
          warningMsgs = msgs;
          break;
        case MARPA_EVENT_EXHAUSTED:
          if (exhaustionEventb) {
            /* Generate an event */
            if (manageBuf_createp(genericLoggerp, (void **) &(marpaWrapperGrammarp->eventArrayp), &(marpaWrapperGrammarp->sizeEventl), subscribedEventi + 1, sizeof(marpaWrapperGrammarEvent_t)) == NULL) {
              goto err;
            }
            eventp = &(marpaWrapperGrammarp->eventArrayp[subscribedEventi]);

            eventp->eventType = MARPAWRAPPERGRAMMAR_EVENT_EXHAUSTED;
            eventp->symboli   = -1; /* No symbol associated to such event */

            marpaWrapperGrammarp->nEventl = ++subscribedEventi;
          }
          break;
        case MARPA_EVENT_LOOP_RULES:
          warningMsgs = msgs;
          break;
        case MARPA_EVENT_NULLING_TERMINAL:
          fatalMsgs = msgs;
          break;
        case MARPA_EVENT_SYMBOL_COMPLETED:
        case MARPA_EVENT_SYMBOL_NULLED:
        case MARPA_EVENT_SYMBOL_EXPECTED: /* Only if marpa_r_expected_symbol_event_set */
        case MARPA_EVENT_SYMBOL_PREDICTED:
          /* Event value is the id of the symbol */
          eventValuei = marpa_g_event_value(&event);
          MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_event_value(%p) returns %d", &event, eventValuei);
          if (manageBuf_createp(genericLoggerp, (void **) &(marpaWrapperGrammarp->eventArrayp), &(marpaWrapperGrammarp->sizeEventl), subscribedEventi + 1, sizeof(marpaWrapperGrammarEvent_t)) == NULL) {
            goto err;
          }
          eventp = &(marpaWrapperGrammarp->eventArrayp[subscribedEventi]);

          eventp->eventType = (eventType == MARPA_EVENT_SYMBOL_COMPLETED) ? MARPAWRAPPERGRAMMAR_EVENT_COMPLETED : ((eventType == MARPA_EVENT_SYMBOL_NULLED) ? MARPAWRAPPERGRAMMAR_EVENT_NULLED : MARPAWRAPPERGRAMMAR_EVENT_EXPECTED);
          eventp->symboli   = marpaWrapperGrammarp->symbolArrayp[eventValuei].marpaSymbolIdi;

          marpaWrapperGrammarp->nEventl = ++subscribedEventi;
          break;
        default:
          /* These are all the events as per this version of marpa */
          MARPAWRAPPER_NOTICEF(genericLoggerp, "Unsupported event type %d", (int) eventType);
          break;
        }
        if (warningMsgs != NULL) {
          if (marpaWrapperGrammarp->marpaWrapperGrammarOption.warningIsErrorb != 0) {
            MARPAWRAPPER_ERROR(genericLoggerp, warningMsgs);
            goto err;
          } else {
            MARPAWRAPPER_WARN(genericLoggerp, warningMsgs);
          }
        } else if (fatalMsgs != NULL) {
          MARPAWRAPPER_ERROR(genericLoggerp, fatalMsgs);
          goto err;
        } else if (infoMsgs != NULL) {
          MARPAWRAPPER_INFO(genericLoggerp, infoMsgs);
        }
      }

      if (subscribedEventi > 1) {
        /* Sort the events */
        qsort(marpaWrapperGrammarp->eventArrayp, subscribedEventi, sizeof(marpaWrapperGrammarEvent_t), &_marpaWrapperGrammar_cmpi);
      }

    }
  } else {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Using cached event list");
  }

  if (eventlp != NULL) {
    *eventlp = marpaWrapperGrammarp->nEventl;
  }
  if (eventpp != NULL) {
    *eventpp = (marpaWrapperGrammarp->nEventl > 0) ? marpaWrapperGrammarp->eventArrayp : NULL;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  if (eventp != NULL) {
    int errnoi = errno;
    free(eventp);
    errno = errnoi;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline int _marpaWrapperGrammar_cmpi(const void *event1p, const void *event2p)
/****************************************************************************/
{
  int w1i = MARPAWRAPPERGRAMMAREVENT_WEIGHT(((marpaWrapperGrammarEvent_t *) event1p)->eventType);
  int w2i = MARPAWRAPPERGRAMMAREVENT_WEIGHT(((marpaWrapperGrammarEvent_t *) event2p)->eventType);

  return (w1i < w2i) ? -1 : ((w1i > w2i) ? 1 : 0);
}

/****************************************************************************/
short marpaWrapperGrammar_symbolPropertyb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int symboli, int *marpaWrapperSymbolPropertyBitSetp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_symbolPropertyb);
  genericLogger_t                  *genericLoggerp = NULL;
  Marpa_Grammar                     marpaGrammarp;
  int                               accessiblei;
  int                               nullablei;
  int                               nullingi;
  int                               productivei;
  int                               starti;
  int                               terminali;
  int                               marpaWrapperSymbolPropertyBitSet;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;
  marpaGrammarp  = marpaWrapperGrammarp->marpaGrammarp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_accessible(%p)", marpaGrammarp);
  accessiblei = marpa_g_symbol_is_accessible(marpaGrammarp, symboli);
  if (accessiblei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_nullable(%p)", marpaGrammarp);
  nullablei = marpa_g_symbol_is_nullable(marpaGrammarp, symboli);
  if (nullablei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_nulling(%p)", marpaGrammarp);
  nullingi = marpa_g_symbol_is_nulling(marpaGrammarp, symboli);
  if (nullingi < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_productive(%p)", marpaGrammarp);
  productivei = marpa_g_symbol_is_productive(marpaGrammarp, symboli);
  if (productivei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_start(%p)", marpaGrammarp);
  starti = marpa_g_symbol_is_start(marpaGrammarp, symboli);
  if (starti < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_symbol_is_terminal(%p)", marpaGrammarp);
  terminali = marpa_g_symbol_is_terminal(marpaGrammarp, symboli);
  if (terminali < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  if (marpaWrapperSymbolPropertyBitSetp != NULL) {
    marpaWrapperSymbolPropertyBitSet = 0;
    if (accessiblei != 0) { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_ACCESSIBLE; }
    if (nullablei != 0)   { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_NULLABLE;   }
    if (nullingi != 0)    { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_NULLING;    }
    if (productivei != 0) { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_PRODUCTIVE; }
    if (starti != 0)      { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_START;      }
    if (terminali != 0)   { marpaWrapperSymbolPropertyBitSet |= MARPAWRAPPER_SYMBOL_IS_TERMINAL;   }
    *marpaWrapperSymbolPropertyBitSetp = marpaWrapperSymbolPropertyBitSet;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperGrammar_rulePropertyb(marpaWrapperGrammar_t *marpaWrapperGrammarp, int rulei, int *marpaWrapperRulePropertyBitSetp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperGrammar_rulePropertyb);
  genericLogger_t                  *genericLoggerp = NULL;
  Marpa_Grammar                     marpaGrammarp;
  int                               accessiblei;
  int                               nullablei;
  int                               nullingi;
  int                               loopi;
  int                               productivei;
  int                               marpaWrapperRulePropertyBitSet;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperGrammarp->marpaWrapperGrammarOption.genericLoggerp;
  marpaGrammarp  = marpaWrapperGrammarp->marpaGrammarp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_is_accessible(%p)", marpaGrammarp);
  accessiblei = marpa_g_rule_is_accessible(marpaGrammarp, rulei);
  if (accessiblei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_is_nullable(%p)", marpaGrammarp);
  nullablei = marpa_g_rule_is_nullable(marpaGrammarp, rulei);
  if (nullablei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_is_nulling(%p)", marpaGrammarp);
  nullingi = marpa_g_rule_is_nulling(marpaGrammarp, rulei);
  if (nullingi < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_is_loop(%p)", marpaGrammarp);
  loopi = marpa_g_rule_is_loop(marpaGrammarp, rulei);
  if (loopi < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_is_productive(%p)", marpaGrammarp);
  productivei = marpa_g_rule_is_productive(marpaGrammarp, rulei);
  if (productivei < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp);
    goto err;
  }

  if (marpaWrapperRulePropertyBitSetp != NULL) {
    marpaWrapperRulePropertyBitSet = 0;
    if (accessiblei != 0) { marpaWrapperRulePropertyBitSet |= MARPAWRAPPER_RULE_IS_ACCESSIBLE; }
    if (nullablei != 0)   { marpaWrapperRulePropertyBitSet |= MARPAWRAPPER_RULE_IS_NULLABLE;   }
    if (nullingi != 0)    { marpaWrapperRulePropertyBitSet |= MARPAWRAPPER_RULE_IS_NULLING;    }
    if (loopi != 0)       { marpaWrapperRulePropertyBitSet |= MARPAWRAPPER_RULE_IS_LOOP;       }
    if (productivei != 0) { marpaWrapperRulePropertyBitSet |= MARPAWRAPPER_RULE_IS_PRODUCTIVE; }
    *marpaWrapperRulePropertyBitSetp = marpaWrapperRulePropertyBitSet;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

