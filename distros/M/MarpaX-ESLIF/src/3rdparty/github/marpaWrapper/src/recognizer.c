#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "marpa.h"
#include "config.h"
#include "marpaWrapper/internal/_manageBuf.h"
#include "marpaWrapper/internal/_recognizer.h"
#include "marpaWrapper/internal/_grammar.h"
#include "marpaWrapper/internal/_logging.h"

static marpaWrapperRecognizerOption_t marpaWrapperRecognizerOptionDefault = {
  NULL,    /* genericLoggerp   */
  0,       /* disableThresholdb */
  0        /* exhaustionEventb */
};

/****************************************************************************/
marpaWrapperRecognizer_t *marpaWrapperRecognizer_newp(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_newp);
  marpaWrapperRecognizer_t *marpaWrapperRecognizerp = NULL;
  genericLogger_t          *genericLoggerp;
  int                       highestSymbolIdi;
  size_t                    nSymboll;

  if (marpaWrapperGrammarp == NULL) {
    errno = EINVAL;
    goto err;
  }

  if (marpaWrapperRecognizerOptionp == NULL) {
    marpaWrapperRecognizerOptionp = &marpaWrapperRecognizerOptionDefault;
  }
  genericLoggerp = marpaWrapperRecognizerOptionp->genericLoggerp;

  /* Create a recognizer instance */
  marpaWrapperRecognizerp = malloc(sizeof(marpaWrapperRecognizer_t));
  if (marpaWrapperRecognizerp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  /* See first instruction after this initialization block: marpaWrapperRecognizerp->marpaRecognizerp */
  marpaWrapperRecognizerp->marpaWrapperGrammarp         = marpaWrapperGrammarp;
  marpaWrapperRecognizerp->marpaWrapperRecognizerOption = *marpaWrapperRecognizerOptionp;
  marpaWrapperRecognizerp->sizeSymboll                  = 0;
  marpaWrapperRecognizerp->nSymboll                     = 0;
  marpaWrapperRecognizerp->symbolip                     = NULL;
  marpaWrapperRecognizerp->sizeProgressl                = 0;
  marpaWrapperRecognizerp->nProgressl                   = 0;
  marpaWrapperRecognizerp->progressp                    = NULL;
  marpaWrapperRecognizerp->treeModeb                    = MARPAWRAPPERRECOGNIZERTREEMODE_NA;
  marpaWrapperRecognizerp->haveVariableLengthTokenb     = 0;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_new(%p)", marpaWrapperGrammarp->marpaGrammarp);
  marpaWrapperRecognizerp->marpaRecognizerp = marpa_r_new(marpaWrapperGrammarp->marpaGrammarp);
  if (marpaWrapperRecognizerp->marpaRecognizerp == NULL) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Apply options */
  if (marpaWrapperRecognizerp->marpaWrapperRecognizerOption.disableThresholdb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_earley_item_warning_threshold_set(%p, -1)", marpaWrapperRecognizerp->marpaRecognizerp);
    /* Always succeed as per the doc */
    marpa_r_earley_item_warning_threshold_set(marpaWrapperRecognizerp->marpaRecognizerp, -1);
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_start_input(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  if (marpa_r_start_input(marpaWrapperRecognizerp->marpaRecognizerp) < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Allocate room for the terminals expected output */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_highest_symbol_id(%p)", marpaWrapperGrammarp->marpaGrammarp);
  highestSymbolIdi = marpa_g_highest_symbol_id(marpaWrapperGrammarp->marpaGrammarp);
  if (highestSymbolIdi < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  nSymboll = highestSymbolIdi + 1;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Pre-allocating room for %d symbols", nSymboll);
  if (manageBuf_createp(genericLoggerp,
			(void **) &(marpaWrapperRecognizerp->symbolip),
			&(marpaWrapperRecognizerp->sizeSymboll),
			nSymboll,
			sizeof(int)) == NULL) {
    goto err;
  }

  /* Events can happen */
  if (marpaWrapperGrammar_eventb(marpaWrapperGrammarp, NULL, NULL, marpaWrapperRecognizerOptionp->exhaustionEventb, 1) == 0) {
    goto err;
  }

  if (genericLoggerp != NULL) {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Cloning genericLogger");

    marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp = GENERICLOGGER_CLONE(genericLoggerp);
    if (marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Failed to clone genericLogger: %s", strerror(errno));
      goto err;
    }
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperRecognizerp);
  return marpaWrapperRecognizerp;

err:
  if (marpaWrapperRecognizerp != NULL) {
    int errnoi = errno;

    if ((genericLoggerp != NULL) &&
        (marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp != NULL) &&
        (marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp != genericLoggerp)) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned genericLogger");
      GENERICLOGGER_FREE(marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp);
    }
    marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp = NULL;
    marpaWrapperRecognizer_freev(marpaWrapperRecognizerp);

    errno = errnoi;
  }

  return NULL;
}

/****************************************************************************/
short marpaWrapperRecognizer_alternativeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, int valuei, int lengthi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_alternativeb);
  genericLogger_t *genericLoggerp = NULL;
  
  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  if (symboli < 0) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Invalid symbol number %d", symboli);
    errno = EINVAL;
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_alternative(%p, %d, %d, %d)", marpaWrapperRecognizerp->marpaRecognizerp, symboli, valuei, lengthi);
  if (marpa_r_alternative(marpaWrapperRecognizerp->marpaRecognizerp, (Marpa_Symbol_ID) symboli, valuei, lengthi) != MARPA_ERR_NONE) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  /* Remember that a token have a length > 1 */
  if (lengthi > 1) {
    if (marpaWrapperRecognizerp->haveVariableLengthTokenb == 0) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Remembering that at least one token have a length > 1");
      marpaWrapperRecognizerp->haveVariableLengthTokenb = 1;
    }
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_completeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_completeb);
  genericLogger_t *genericLoggerp = NULL;
  
  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_earleme_complete(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  if (marpa_r_earleme_complete(marpaWrapperRecognizerp->marpaRecognizerp) < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    /* As per the doc, events should be fetched even in case of failure */
    marpaWrapperGrammar_eventb(marpaWrapperRecognizerp->marpaWrapperGrammarp, NULL, NULL, marpaWrapperRecognizerp->marpaWrapperRecognizerOption.exhaustionEventb, 1);
    goto err;
  }

  /* Events can happen */
  if (marpaWrapperGrammar_eventb(marpaWrapperRecognizerp->marpaWrapperGrammarp, NULL, NULL, marpaWrapperRecognizerp->marpaWrapperRecognizerOption.exhaustionEventb, 1) == 0) {
    goto err;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_latestb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int *earleySetIdip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_latestb);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t     *genericLoggerp = NULL;
#endif
  Marpa_Earley_Set_ID  earleySetIdi;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;
#endif

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_latest_earley_set(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  /* This method always succeed as per the doc */
  earleySetIdi = marpa_r_latest_earley_set(marpaWrapperRecognizerp->marpaRecognizerp);

  if (earleySetIdip != NULL) {
    *earleySetIdip = (int) earleySetIdi;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_readb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, int valuei, int lengthi)
/****************************************************************************/
{
  if (marpaWrapperRecognizer_alternativeb(marpaWrapperRecognizerp, symboli, valuei, lengthi) == 0) {
    return 0;
  }
  
  return marpaWrapperRecognizer_completeb(marpaWrapperRecognizerp);
}

/****************************************************************************/
short marpaWrapperRecognizer_event_onoffb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, marpaWrapperGrammarEventType_t eventSeti, int onoffb)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_event_onoffb);
  genericLogger_t *genericLoggerp = NULL;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  if (onoffb != 0) {
    onoffb = 1;
  }

  if ((eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_COMPLETION) == MARPAWRAPPERGRAMMAR_EVENTTYPE_COMPLETION) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_completion_symbol_activate(%p, %d, %d)", marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb);
    if (marpa_r_completion_symbol_activate(marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb) != onoffb) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }
  if ((eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_NULLED) == MARPAWRAPPERGRAMMAR_EVENTTYPE_NULLED) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_nulled_symbol_activate(%p, %d, %d)", marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb);
    if (marpa_r_nulled_symbol_activate(marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb) != onoffb) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }
  if ((eventSeti & MARPAWRAPPERGRAMMAR_EVENTTYPE_PREDICTION) == MARPAWRAPPERGRAMMAR_EVENTTYPE_PREDICTION) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_prediction_symbol_activate(%p, %d, %d)", marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb);
    if (marpa_r_prediction_symbol_activate(marpaWrapperRecognizerp->marpaRecognizerp, symboli, onoffb) != onoffb) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_expectedb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, size_t *nSymbollp, int **symbolArraypp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_expectedb);
  genericLogger_t *genericLoggerp = NULL;
  int              nSymbolIdi;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_terminals_expected(%p, %p)", marpaWrapperRecognizerp->marpaRecognizerp, marpaWrapperRecognizerp->symbolip);
  nSymbolIdi = marpa_r_terminals_expected(marpaWrapperRecognizerp->marpaRecognizerp, marpaWrapperRecognizerp->symbolip);
  if (nSymbolIdi < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  marpaWrapperRecognizerp->nSymboll = (size_t) nSymbolIdi;

  if (nSymbollp != NULL) {
    *nSymbollp = (size_t) nSymbolIdi;
  }
  if (symbolArraypp != NULL) {
    *symbolArraypp = marpaWrapperRecognizerp->symbolip;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_exhaustedb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, short *exhaustedbp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_exhaustedb);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t *genericLoggerp = NULL;
#endif
  short            exhaustedb;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;
#endif

  /* This function always succeed as per doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_is_exhausted(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  exhaustedb = (marpa_r_is_exhausted(marpaWrapperRecognizerp->marpaRecognizerp) != 0) ? 1 : 0;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*exhaustedbp=%d)", (int) exhaustedb);
  if (exhaustedbp != NULL) {
    *exhaustedbp = exhaustedb;
  }
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_progressb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int starti, int endi, size_t *nProgresslp, marpaWrapperRecognizerProgress_t **progresspp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_progressb);
  genericLogger_t    *genericLoggerp = NULL;
  Marpa_Earley_Set_ID marpaLatestEarleySetIdi;
  Marpa_Earley_Set_ID marpaEarleySetIdStarti;
  Marpa_Earley_Set_ID earleySetIdi;
  Marpa_Earley_Set_ID marpaEarleySetIdEndi;
  Marpa_Earley_Set_ID earleySetOrigIdi;
  Marpa_Earleme       marpEarlemei;
  Marpa_Rule_ID       rulei;
  int                 realStarti = starti;
  int                 realEndi = endi;
  int                 positioni;
  size_t              nProgressl;
  int                 nbItemsi;
  int                itemi;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  /* This function always succeed as per doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_latest_earley_set(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  marpaLatestEarleySetIdi = marpa_r_latest_earley_set(marpaWrapperRecognizerp->marpaRecognizerp);
  if (realStarti < 0) {
    realStarti += (marpaLatestEarleySetIdi + 1);
  }
  if ((realStarti < 0) || (realStarti > marpaLatestEarleySetIdi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "starti must be in range [%d-%d]", (int) (-(marpaLatestEarleySetIdi+1)), (int) marpaLatestEarleySetIdi);
    errno = EINVAL;
    goto err;
  }
  if (realEndi < 0) {
    realEndi += (marpaLatestEarleySetIdi + 1);
  }
  if ((realEndi < 0) || (realEndi > marpaLatestEarleySetIdi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "endi must be in range [%d-%d]", (int) (-(marpaLatestEarleySetIdi+1)), (int) marpaLatestEarleySetIdi);
    errno = EINVAL;
    goto err;
  }
  if (realStarti > realEndi) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "[starti,endi] range [%d,%d] evaluated to [%d-%d]", starti, endi, realStarti, realEndi);
    errno = EINVAL;
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Asking for progress report in early set range [%d-%d]", realStarti, realEndi);
  marpaEarleySetIdStarti = (Marpa_Earley_Set_ID) realStarti;
  marpaEarleySetIdEndi   = (Marpa_Earley_Set_ID) realEndi;
  nProgressl = 0;
  for (earleySetIdi = marpaEarleySetIdStarti; earleySetIdi <= marpaEarleySetIdEndi; earleySetIdi++) {

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_earleme(%p, %d)", marpaWrapperRecognizerp->marpaRecognizerp, (int) earleySetIdi);
    marpEarlemei = marpa_r_earleme(marpaWrapperRecognizerp->marpaRecognizerp, earleySetIdi);
    if (marpEarlemei < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_progress_report_start(%p, %d)", marpaWrapperRecognizerp->marpaRecognizerp, (int) earleySetIdi);
    nbItemsi = marpa_r_progress_report_start(marpaWrapperRecognizerp->marpaRecognizerp, earleySetIdi);
    if (nbItemsi < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }

    for (itemi = 0; itemi < nbItemsi; itemi++) {

      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_progress_item(%p, %p, %p)", marpaWrapperRecognizerp->marpaRecognizerp, &positioni, &earleySetOrigIdi);
      rulei = marpa_r_progress_item(marpaWrapperRecognizerp->marpaRecognizerp, &positioni, &earleySetOrigIdi);
      if (rulei < 0) {
	MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
	goto err;
      }

      if (manageBuf_createp(genericLoggerp,
			    (void **) &(marpaWrapperRecognizerp->progressp),
			    &(marpaWrapperRecognizerp->sizeProgressl),
			    nProgressl + 1,
			    sizeof(marpaWrapperRecognizerProgress_t)) == NULL) {
	goto err;
      }

      marpaWrapperRecognizerp->progressp[nProgressl].earleySetIdi     = (int) earleySetIdi;
      marpaWrapperRecognizerp->progressp[nProgressl].earleySetOrigIdi = (int) earleySetOrigIdi;
      marpaWrapperRecognizerp->progressp[nProgressl].rulei            = rulei;
      marpaWrapperRecognizerp->progressp[nProgressl].positioni        = positioni;

      marpaWrapperRecognizerp->nProgressl = ++nProgressl;
    }

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_progress_report_finish(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
    if (marpa_r_progress_report_finish(marpaWrapperRecognizerp->marpaRecognizerp) < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }

  }

  if (nProgresslp != NULL) {
    *nProgresslp = marpaWrapperRecognizerp->nProgressl;
  }
  if (progresspp != NULL) {
    *progresspp = marpaWrapperRecognizerp->progressp;
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperRecognizer_progressLogb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int starti, int endi, genericLoggerLevel_t logleveli, void *userDatavp, symbolDescriptionCallback_t symbolDescriptionCallbackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_progressLogb);
  size_t            i;
  int               ix;
  genericLogger_t  *genericLoggerp = NULL;
  int               ruleLengthi;
  Marpa_Symbol_ID   lhsi, rhsi;
  Marpa_Earleme     earlemei, earlemeorigi;     
  char             *descriptionLHSs, *descriptionRHSs, *trailingDescriptionRHSs;
  size_t            lengthDescriptionLHSi;
  int               positioni, rulei;
  char             *lefts;
  char             *middles;
  char              rtypec;
  
  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

  if (marpaWrapperRecognizer_progressb(marpaWrapperRecognizerp, starti, endi, NULL, NULL) == 0) {
    goto err;
  }

  if (genericLoggerp != NULL) {
    if (marpaWrapperRecognizerp->nProgressl > 0) {
      for (i = 0; i < marpaWrapperRecognizerp->nProgressl; i++) {
	if (symbolDescriptionCallbackp == NULL) {
	  genericLogger_logv(genericLoggerp, logleveli, "# earleySetIdi %4d earleySetOrigIdi %4d rulei %4d positioni %4d",
			     marpaWrapperRecognizerp->progressp[i].earleySetIdi,
			     marpaWrapperRecognizerp->progressp[i].earleySetOrigIdi,
			     marpaWrapperRecognizerp->progressp[i].rulei,
			     marpaWrapperRecognizerp->progressp[i].positioni
			     );
	} else {
	  /* MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_earleme(%p, %d)", marpaWrapperRecognizerp->marpaRecognizerp, marpaWrapperRecognizerp->progressp[i].earleySetIdi); */
	  earlemei = marpa_r_earleme(marpaWrapperRecognizerp->marpaRecognizerp, (Marpa_Earley_Set_ID) marpaWrapperRecognizerp->progressp[i].earleySetIdi);
	  if (earlemei < 0) {
	    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
	    goto err;
	  }
	  earlemeorigi = marpa_r_earleme(marpaWrapperRecognizerp->marpaRecognizerp, (Marpa_Earley_Set_ID) marpaWrapperRecognizerp->progressp[i].earleySetOrigIdi);
	  if (earlemeorigi < 0) {
	    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
	    goto err;
	  }

	  /* MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_lhs(%p, %d)", marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, marpaWrapperRecognizerp->progressp[i].rulei); */
	  lhsi = marpa_g_rule_lhs(marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, (Marpa_Rule_ID) marpaWrapperRecognizerp->progressp[i].rulei);
	  if (lhsi < 0) {
	    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
	    goto err;
	  }
	  descriptionLHSs = symbolDescriptionCallbackp(userDatavp, lhsi);
	  if ((descriptionLHSs == NULL) || (strlen(descriptionLHSs) <= 0)) {
	    descriptionLHSs = "?";
	  }

	  /* MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_length(%p, %d)", marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, marpaWrapperRecognizerp->progressp[i].rulei); */
	  ruleLengthi = marpa_g_rule_length(marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, (Marpa_Rule_ID) marpaWrapperRecognizerp->progressp[i].rulei);
	  if (ruleLengthi < 0) {
	    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
	    goto err;
	  }

	  /* Description is split on multiple lines */
	  lengthDescriptionLHSi = strlen(descriptionLHSs);

	  positioni = marpaWrapperRecognizerp->progressp[i].positioni;
	  rulei     = marpaWrapperRecognizerp->progressp[i].rulei;

	  for (ix = 0; ix < ruleLengthi; ix++) {
	    lefts = (ix == 0) ? descriptionLHSs : " ";
	    middles = (ix == 0) ? "::=" : "   ";
	    rtypec = ((positioni < 0) || (positioni >= ruleLengthi)) ? 'F' : ((positioni > 0) ? 'R' : 'P');

	    if (ruleLengthi > 0) {
	      /* MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_rhs(%p, %d, %d)", marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, marpaWrapperRecognizerp->progressp[i].rulei, ix); */
	      rhsi = marpa_g_rule_rhs(marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp, (Marpa_Rule_ID) marpaWrapperRecognizerp->progressp[i].rulei, ix);
	      if (rhsi < 0) {
		MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
		goto err;
	      }
	      descriptionRHSs = symbolDescriptionCallbackp(userDatavp, rhsi);
	      if ((descriptionRHSs == NULL) || (strlen(descriptionRHSs) <= 0)) {
		descriptionRHSs = "?";
	      }
              /* Is it a sequence ? */
              if (ruleLengthi == 1) {
                if (((size_t) rulei) < marpaWrapperRecognizerp->marpaWrapperGrammarp->nRulel) {
                  if (marpaWrapperRecognizerp->marpaWrapperGrammarp->ruleArrayp[rulei].marpaWrapperGrammarRuleOption.sequenceb != 0) {
                    if (marpaWrapperRecognizerp->marpaWrapperGrammarp->ruleArrayp[rulei].marpaWrapperGrammarRuleOption.minimumi == 0) {
                      trailingDescriptionRHSs = "*";
                    } else {
                      trailingDescriptionRHSs = "+";
                    }
                  } else {
                    trailingDescriptionRHSs = "";
                  }
                } else {
                  MARPAWRAPPER_ERRORF(genericLoggerp, "Rule Symbol Id is %d >= %ld", rulei, (unsigned long) marpaWrapperRecognizerp->marpaWrapperGrammarp->nRulel);
                  trailingDescriptionRHSs = "*";
                }
              } else {
                trailingDescriptionRHSs = "";
              }
	    } else {
	      descriptionRHSs = "";
              trailingDescriptionRHSs = "";
	    }
	    if (positioni == ix) {
	      genericLogger_logv(genericLoggerp, logleveli, "[%c%d@%d..%d] %*s %s . %s%s", rtypec, rulei, earlemeorigi, earlemei, (int) lengthDescriptionLHSi, lefts, middles, descriptionRHSs, trailingDescriptionRHSs);
	    } else if (positioni < 0) {
	      if (ix == (ruleLengthi - 1)) {
		genericLogger_logv(genericLoggerp, logleveli, "[%c%d@%d..%d] %*s %s %s%s .", rtypec, rulei, earlemeorigi, earlemei, (int) lengthDescriptionLHSi, lefts, middles, descriptionRHSs, trailingDescriptionRHSs);
	      } else {
		genericLogger_logv(genericLoggerp, logleveli, "[%c%d@%d..%d] %*s %s %s%s", rtypec, rulei, earlemeorigi, earlemei, (int) lengthDescriptionLHSi, lefts, middles, descriptionRHSs, trailingDescriptionRHSs);
	      }
	    } else {
	      genericLogger_logv(genericLoggerp, logleveli, "[%c%d@%d..%d] %*s %s %s%s", rtypec, rulei, earlemeorigi, earlemei, (int) lengthDescriptionLHSi, lefts, middles, descriptionRHSs, trailingDescriptionRHSs);
	    }
	  }
	}
      }
    }
  }

  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
void marpaWrapperRecognizer_freev(marpaWrapperRecognizer_t *marpaWrapperRecognizerp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_freev);
  genericLogger_t  *genericLoggerp;

  if (marpaWrapperRecognizerp != NULL) {
    /* Keep a copy of the generic logger. If original is not NULL, then we have a clone of it */
    genericLoggerp = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;

    if (marpaWrapperRecognizerp->marpaRecognizerp != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_unref(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
      marpa_r_unref(marpaWrapperRecognizerp->marpaRecognizerp);
    }

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing symbol table");
    manageBuf_freev(genericLoggerp, (void **) &(marpaWrapperRecognizerp->symbolip));

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing progress table");
    manageBuf_freev(genericLoggerp, (void **) &(marpaWrapperRecognizerp->progressp));

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "free(%p)", marpaWrapperRecognizerp);
    free(marpaWrapperRecognizerp);

    if (genericLoggerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned generic logger");
      GENERICLOGGER_FREE(genericLoggerp);
    }
  }
}

/****************************************************************************/
marpaWrapperGrammar_t *marpaWrapperRecognizer_grammarp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperRecognizer_grammarp);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t       *genericLoggerp;
#endif
  marpaWrapperGrammar_t *marpaWrapperGrammarp;

  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    return NULL;
  }

#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp       = marpaWrapperRecognizerp->marpaWrapperRecognizerOption.genericLoggerp;
#endif
  marpaWrapperGrammarp = marpaWrapperRecognizerp->marpaWrapperGrammarp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperGrammarp);
  return marpaWrapperGrammarp;
}
