#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "marpa.h"
#include "config.h"
#include "marpaWrapper/internal/_value.h"
#include "marpaWrapper/internal/_recognizer.h"
#include "marpaWrapper/internal/_grammar.h"
#include "marpaWrapper/internal/_logging.h"

static marpaWrapperValueOption_t marpaWrapperValueOptionDefault = {
  NULL,                           /* genericLoggerp */
  1,                              /* highRankOnlyb */
  1,                              /* orderByRankb */
  0,                              /* ambiguousb */
  0,                              /* nullb */
  0                               /* maxParsesi */
};

/* Macro that return genericLoggerp from a marpaWrapperValuep */
#define GENERICLOGGERP(marpaWrapperValuep) ((marpaWrapperValuep != NULL) ? (marpaWrapperValuep)->marpaWrapperValueOption.genericLoggerp : NULL)

/****************************************************************************/
marpaWrapperValue_t *marpaWrapperValue_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperValueOption_t *marpaWrapperValueOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperValue_newp)
  marpaWrapperValue_t  *marpaWrapperValuep = NULL;
  genericLogger_t      *genericLoggerp;
  Marpa_Earley_Set_ID   marpaLatestEarleySetIdi;
  int                   highRankOnlyFlagi;
  int                   ambiguousi;
  int                   nulli;

#ifndef NDEBUG
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperRecognizerp == NULL)) {
    errno = EINVAL;
    goto err;
  }
#endif

  if (marpaWrapperValueOptionp == NULL) {
    marpaWrapperValueOptionp = &marpaWrapperValueOptionDefault;
  }
  genericLoggerp = marpaWrapperValueOptionp->genericLoggerp;

  /* Impossible if we are already valuating it */
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperRecognizerp->treeModeb != MARPAWRAPPERRECOGNIZERTREEMODE_NA)) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Already in valuation mode");
    goto err;
  }

  /* Create a value instance */
  marpaWrapperValuep = (marpaWrapperValue_t *) malloc(sizeof(marpaWrapperValue_t));
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep == NULL)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  /* See first instruction after this initialization block: marpaWrapperValuep->marpaValuep */
  marpaWrapperValuep->marpaWrapperRecognizerp = marpaWrapperRecognizerp;
  marpaWrapperValuep->marpaWrapperValueOption = *marpaWrapperValueOptionp;
  marpaWrapperValuep->marpaBocagep            = NULL;
  marpaWrapperValuep->marpaOrderp             = NULL;
  marpaWrapperValuep->marpaTreep              = NULL;
  marpaWrapperValuep->marpaValuep             = NULL; /* Is not NULL only during valueb lifetime */

  /* Always succeed as per the doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_latest_earley_set(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  marpaLatestEarleySetIdi = marpa_r_latest_earley_set(marpaWrapperRecognizerp->marpaRecognizerp);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_b_new(%p, %d)", marpaWrapperRecognizerp->marpaRecognizerp, (int) marpaLatestEarleySetIdi);
  marpaWrapperValuep->marpaBocagep = marpa_b_new(marpaWrapperRecognizerp->marpaRecognizerp, marpaLatestEarleySetIdi);
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaBocagep == NULL)) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_new(%p)", marpaWrapperValuep->marpaBocagep);
  marpaWrapperValuep->marpaOrderp = marpa_o_new(marpaWrapperValuep->marpaBocagep);
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaOrderp == NULL)) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  highRankOnlyFlagi = (marpaWrapperValueOptionp->highRankOnlyb != 0) ? 1 : 0;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_high_rank_only_set(%p, %d)", marpaWrapperValuep->marpaOrderp, highRankOnlyFlagi);
  if (MARPAWRAPPER_UNLIKELY(marpa_o_high_rank_only_set(marpaWrapperValuep->marpaOrderp, highRankOnlyFlagi) != highRankOnlyFlagi)) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  if (marpaWrapperValueOptionp->orderByRankb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_rank(%p)", marpaWrapperValuep->marpaOrderp);
    if (MARPAWRAPPER_UNLIKELY(marpa_o_rank(marpaWrapperValuep->marpaOrderp) < 0)) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if (marpaWrapperValueOptionp->ambiguousb == 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_ambiguity_metric(%p)", marpaWrapperValuep->marpaOrderp);
    ambiguousi = marpa_o_ambiguity_metric(marpaWrapperValuep->marpaOrderp);
    if (MARPAWRAPPER_UNLIKELY(ambiguousi < 0)) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    } else if (ambiguousi > 1) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Parse is ambiguous");
      goto err;
    }
  }
  
  if (marpaWrapperValueOptionp->nullb == 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_is_null(%p)", marpaWrapperValuep->marpaOrderp);
    nulli = marpa_o_is_null(marpaWrapperValuep->marpaOrderp);
    if (MARPAWRAPPER_UNLIKELY(nulli < 0)) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    } else if (nulli >= 1) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Parse is null");
      goto err;
    }
  }
  
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_t_new(%p)", marpaWrapperValuep->marpaOrderp);
  marpaWrapperValuep->marpaTreep = marpa_t_new(marpaWrapperValuep->marpaOrderp);
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaTreep == NULL)) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  if (genericLoggerp != NULL) {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Cloning genericLogger");

    marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp = GENERICLOGGER_CLONE(genericLoggerp);
    if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp == NULL)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Failed to clone genericLogger: %s", strerror(errno));
      goto err;
    }
  }

  /* Say we are in tree mode */
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Flagging tree mode to TREE");
  marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_TREE;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperValuep);
  return marpaWrapperValuep;

err:
  if (marpaWrapperValuep != NULL) {
    int errnoi = errno;

    if ((genericLoggerp != NULL) &&
        (marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp != NULL) &&
        (marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp != genericLoggerp)) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned genericLogger");
      GENERICLOGGER_FREE(marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp);
    }
    marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp = NULL;
    marpaWrapperValue_freev(marpaWrapperValuep);

    errno = errnoi;
  }

  if (marpaWrapperRecognizerp != NULL) {
    marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_NA;
  }

  return NULL;
}

/****************************************************************************/
short marpaWrapperValue_valueb(marpaWrapperValue_t               *marpaWrapperValuep,
			       void                              *userDatavp,
			       marpaWrapperValueRuleCallback_t    ruleCallbackp,
			       marpaWrapperValueSymbolCallback_t  symbolCallbackp,
			       marpaWrapperValueNullingCallback_t nullingCallbackp)
/****************************************************************************/
{
  /* We take much care to set marpaWrapperValuep->marpaValuep only around the callbacks */
  MARPAWRAPPER_FUNCS(marpaWrapperValue_valueb)
  int               tnexti;
  Marpa_Value       marpaValuep = NULL;
  int               nexti;
  Marpa_Step_Type   stepi;
  Marpa_Rule_ID     marpaRuleIdi;
  Marpa_Symbol_ID   marpaSymbolIdi;
  int               argFirsti;
  int               argLasti;
  int               argResulti;
  int               tokenValuei;
  int               nParsesi;
  short             callbackb;

#ifndef NDEBUG
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep == NULL)) {
    errno = EINVAL;
    goto err;
  }
#endif

  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_t_next(%p)", marpaWrapperValuep->marpaTreep);
  tnexti = marpa_t_next(marpaWrapperValuep->marpaTreep);
  if (MARPAWRAPPER_UNLIKELY(tnexti < -1)) {
    MARPAWRAPPER_MARPA_G_ERROR(GENERICLOGGERP(marpaWrapperValuep), marpaWrapperValuep->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  } else if (tnexti == -1) {
    MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "Tree iterator exhausted");
    goto done;
  }

  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_t_parse_count(%p)", marpaWrapperValuep->marpaTreep);
  nParsesi = marpa_t_parse_count(marpaWrapperValuep->marpaTreep);
  if ((marpaWrapperValuep->marpaWrapperValueOption.maxParsesi > 0) && (nParsesi > marpaWrapperValuep->marpaWrapperValueOption.maxParsesi)) {
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "Maximum number of parse trees is reached: %d", marpaWrapperValuep->marpaWrapperValueOption.maxParsesi);
    goto done;
  }
  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "Number of parse trees: %d, max=%d", nParsesi, marpaWrapperValuep->marpaWrapperValueOption.maxParsesi);

  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_new(%p)", marpaWrapperValuep->marpaTreep);
  marpaValuep = marpa_v_new(marpaWrapperValuep->marpaTreep);
  if (MARPAWRAPPER_UNLIKELY(marpaValuep == NULL)) {
    MARPAWRAPPER_MARPA_G_ERROR(GENERICLOGGERP(marpaWrapperValuep), marpaWrapperValuep->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_valued_force(%p)", marpaValuep);
  if (MARPAWRAPPER_UNLIKELY(marpa_v_valued_force(marpaValuep) < 0)) {
    MARPAWRAPPER_MARPA_G_ERROR(GENERICLOGGERP(marpaWrapperValuep), marpaWrapperValuep->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  nexti = 1;
  while (nexti != 0) {
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_step(%p)", marpaValuep);
    stepi = marpa_v_step(marpaValuep);
    if (MARPAWRAPPER_UNLIKELY(stepi < 0)) {
      MARPAWRAPPER_MARPA_G_ERROR(GENERICLOGGERP(marpaWrapperValuep), marpaWrapperValuep->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }

    MARPAWRAPPER_MARPA_STEP_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, stepi);

    switch (stepi) {
    case MARPA_STEP_RULE:

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_rule(%p)", marpaValuep);
      marpaRuleIdi = marpa_v_rule(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_arg_0(%p)", marpaValuep);
      argFirsti = marpa_v_arg_0(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_arg_n(%p)", marpaValuep);
      argLasti = marpa_v_arg_n(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_result(%p)", marpaValuep);
      argResulti = marpa_v_result(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "Rule %d: Stack [%d..%d] -> Stack %d", (int) marpaRuleIdi, argFirsti, argLasti, argResulti);

      if (ruleCallbackp != NULL) {
        marpaWrapperValuep->marpaValuep = marpaValuep;
	callbackb = ruleCallbackp(userDatavp, (int) marpaRuleIdi, argFirsti, argLasti, argResulti);
        marpaWrapperValuep->marpaValuep = NULL;
        if (callbackb == 0) {
	  MARPAWRAPPER_ERRORF(GENERICLOGGERP(marpaWrapperValuep), "Rule No %d value callback failure", (int) marpaRuleIdi);
	  goto err;
	}
      }

      break;
    case MARPA_STEP_TOKEN:

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_token(%p)", marpaValuep);
      marpaSymbolIdi = marpa_v_token(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_token_value(%p)", marpaValuep);
      tokenValuei = marpa_v_token_value(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_result(%p)", marpaValuep);
      argResulti = marpa_v_result(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "Symbol %d: Stack %d -> Stack %d", (int) marpaSymbolIdi, tokenValuei, argResulti);

      if (symbolCallbackp != NULL) {
        marpaWrapperValuep->marpaValuep = marpaValuep;
	callbackb = symbolCallbackp(userDatavp, (int) marpaSymbolIdi, tokenValuei, argResulti);
        marpaWrapperValuep->marpaValuep = NULL;
        if (callbackb == 0) {
	  MARPAWRAPPER_ERRORF(GENERICLOGGERP(marpaWrapperValuep), "Symbol No %d value callback failure", (int) marpaSymbolIdi);
	  goto err;
	}
      }

      break;
    case MARPA_STEP_NULLING_SYMBOL:

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_symbol(%p)", marpaValuep);
      marpaSymbolIdi = marpa_v_symbol(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_result(%p)", marpaValuep);
      argResulti = marpa_v_result(marpaValuep);

      MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "Nulling symbol %d-> Stack %d", (int) marpaSymbolIdi, argResulti);

      if (nullingCallbackp != NULL) {
        marpaWrapperValuep->marpaValuep = marpaValuep;
	callbackb = nullingCallbackp(userDatavp, (int) marpaSymbolIdi, argResulti);
        marpaWrapperValuep->marpaValuep = NULL;
        if (callbackb == 0) {
	  MARPAWRAPPER_ERRORF(GENERICLOGGERP(marpaWrapperValuep), "Nulling symbol No %d value callback failure", (int) marpaSymbolIdi);
	  goto err;
	}
      }

      break;
    case MARPA_STEP_INACTIVE:
      nexti = 0;
      break;
    case MARPA_STEP_INITIAL:
      break;
    default:
      break;
    }
  }
  
  MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_unref(%p)", marpaValuep);
  marpa_v_unref(marpaValuep);

  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 1");
  return 1;
  
 done:
  if (marpaValuep != NULL) {
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_unref(%p)", marpaValuep);
    marpa_v_unref(marpaValuep);
  }

  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 0");
  return 0;
  
 err:
  if (marpaValuep != NULL) {
    int errnoi = errno;
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_unref(%p)", marpaValuep);
    marpa_v_unref(marpaValuep);
    errno = errnoi;
  }
  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return -1");
  return -1;
}

/****************************************************************************/
short marpaWrapperValue_value_startb(marpaWrapperValue_t *marpaWrapperValuep, int *startip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperValue_value_startb)
  Marpa_Step_Type     step_type;
  Marpa_Earley_Set_ID start_earley_set;

#ifndef NDEBUG
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep == NULL)) {
    errno = EINVAL;
    goto err;
  }
#endif

  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaValuep == NULL)) {
    MARPAWRAPPER_ERROR(GENERICLOGGERP(marpaWrapperValuep), "marpaWrapperValue_value_startb() called outside of marpaWrapperValue_valueb()");
    goto err;
  }

  step_type = marpa_v_step_type(marpaWrapperValuep->marpaValuep);
  switch (step_type) {
  case MARPA_STEP_RULE:
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_rule_start_es_id(%p)", marpaWrapperValuep->marpaValuep);
    start_earley_set = marpa_v_rule_start_es_id(marpaWrapperValuep->marpaValuep);
    break;
  case MARPA_STEP_TOKEN:
  case MARPA_STEP_NULLING_SYMBOL:
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_token_start_es_id(%p)", marpaWrapperValuep->marpaValuep);
    start_earley_set = marpa_v_token_start_es_id(marpaWrapperValuep->marpaValuep);
    break;
  default:
    MARPAWRAPPER_WARNF(GENERICLOGGERP(marpaWrapperValuep), "Unsupported step type %d", (int) step_type);
    goto err;
  }

  if (startip != NULL) {
    *startip = (int) start_earley_set;
  }
  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperValue_value_lengthb(marpaWrapperValue_t *marpaWrapperValuep, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperValue_value_lengthb)
  Marpa_Step_Type     step_type;
  Marpa_Earley_Set_ID start_earley_set;
  Marpa_Earley_Set_ID end_earley_set;
  int                 lengthi;

#ifndef NDEBUG
  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep == NULL)) {
    errno = EINVAL;
    goto err;
  }
#endif

  if (MARPAWRAPPER_UNLIKELY(marpaWrapperValuep->marpaValuep == NULL)) {
    MARPAWRAPPER_ERROR(GENERICLOGGERP(marpaWrapperValuep), "marpaWrapperValue_value_lengthb() called outside of marpaWrapperValue_valueb()");
    goto err;
  }

  step_type = marpa_v_step_type(marpaWrapperValuep->marpaValuep);
  switch (step_type) {
  case MARPA_STEP_RULE:
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_rule_start_es_id(%p)", marpaWrapperValuep->marpaValuep);
    start_earley_set = marpa_v_rule_start_es_id(marpaWrapperValuep->marpaValuep);
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_es_id(%p)", marpaWrapperValuep->marpaValuep);
    end_earley_set = marpa_v_es_id(marpaWrapperValuep->marpaValuep);
    lengthi = end_earley_set - start_earley_set + 1;
    break;
  case MARPA_STEP_NULLING_SYMBOL:
    lengthi = 0;
    break;
  case MARPA_STEP_TOKEN:
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_token_start_es_id(%p)", marpaWrapperValuep->marpaValuep);
    start_earley_set = marpa_v_token_start_es_id(marpaWrapperValuep->marpaValuep);
    MARPAWRAPPER_TRACEF(GENERICLOGGERP(marpaWrapperValuep), funcs, "marpa_v_es_id(%p)", marpaWrapperValuep->marpaValuep);
    end_earley_set = marpa_v_es_id(marpaWrapperValuep->marpaValuep);
    lengthi = end_earley_set - start_earley_set + 1;
    break;
  default:
    MARPAWRAPPER_WARNF(GENERICLOGGERP(marpaWrapperValuep), "Unsupported step type %d", (int) step_type);
    goto err;
  }

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }
  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(GENERICLOGGERP(marpaWrapperValuep), funcs, "return 0");
  return 0;
}

/****************************************************************************/
void marpaWrapperValue_freev(marpaWrapperValue_t *marpaWrapperValuep)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperValue_freev)
  genericLogger_t  *genericLoggerp;

  if (marpaWrapperValuep != NULL) {
    /* Keep a copy of the generic logger. If original is not NULL, then we have a clone of it */
    genericLoggerp = marpaWrapperValuep->marpaWrapperValueOption.genericLoggerp;

    if (marpaWrapperValuep->marpaTreep != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_t_unref(%p)", marpaWrapperValuep->marpaTreep);
      marpa_t_unref(marpaWrapperValuep->marpaTreep);
    }

    if (marpaWrapperValuep->marpaOrderp != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_unref(%p)", marpaWrapperValuep->marpaOrderp);
      marpa_o_unref(marpaWrapperValuep->marpaOrderp);
    }

    if (marpaWrapperValuep->marpaBocagep != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_b_unref(%p)", marpaWrapperValuep->marpaBocagep);
      marpa_b_unref(marpaWrapperValuep->marpaBocagep);
    }

    if (marpaWrapperValuep->marpaWrapperRecognizerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Flagging tree mode to NA");
      marpaWrapperValuep->marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_NA;
    }

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "free(%p)", marpaWrapperValuep);
    free(marpaWrapperValuep);

    if (genericLoggerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned generic logger");
      GENERICLOGGER_FREE(genericLoggerp);
    }
  }
}

