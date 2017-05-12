#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Status/status.h"
#include "EditOp/editop.h"

/* common function, used below */
static SV *packageAlignmentResults(int status, int cost, EditOp *eList);

/*
 * A helper function for the XS routine globalMinDifferences.
 *  o ...
 *  o 
 *
 */

SV *
globalMinDifferences_helper(char *s1, char *s2)
{
  int status = STAT_OK;
  int cost = 0;
  EditOp *eList = NULL;
  SV *rv = NULL;

  status = findGlobalMinDifferences(s1, s2, &cost, &eList);
  /*  BailError(status); */
  
  rv = packageAlignmentResults(status, cost, eList);

 bail:
  return(rv);
}

/*
 * A helper function for the XS routine globalMinDifferences.
 *  o ...
 *  o 
 *
 */

SV *
boundedGlobalMinDifferences_helper(char *s1, char *s2, int bound)
{
  int status = STAT_OK;
  int cost = 0;
  EditOp *eList = NULL;
  SV *rv = NULL;

  status = findBoundedGlobalMinDifferences(s1, s2, bound, &cost, &eList);
  /*  BailError(status); */
  
  rv = packageAlignmentResults(status, cost, eList);

 bail:
  return(rv);
}

/*
 * A helper function for the XS routine globalHirschbergMinDiffs.
 *  o ...
 *  o 
 *
 */

SV *
boundedHirschbergGlobalMinDiffs_helper(char *s1, char *s2, int bound)
{
  int status = STAT_OK;
  int cost = 0;
  EditOp *eList = NULL;
  SV *rv = NULL;

  status = findHirschbergBoundedGlobalMinDiffs(s1, s2, bound, &cost, &eList);
  /*  BailError(status); */
  
  rv = packageAlignmentResults(status, cost, eList);

 bail:
  return(rv);
}


static SV *
packageAlignmentResults(int status, int cost, EditOp *eList)
{
  EditOp *eTmp = NULL;
  int eCount = 0;
  int i = 0;
  AV *av1 = NULL;
  AV *av2 = NULL;
  SV *sv = NULL;
  SV *rv = NULL;

  av1 = newAV();
  sv = newSViv(status);
  av_push(av1, sv);

  if (eList) {
    eTmp = eList;
    while (eTmp) {
      eCount++;
      eTmp = eTmp->next;
    }
    
    sv = newSViv(cost);
    av_push(av1, sv);

    av2 = newAV();
    av_unshift(av2, eCount);
    i = 0;
    while (eList) {
      sv = sv_newmortal();
      sv_setref_pv(sv, "GH::EditOp", (void*) eList);
      (void) SvREFCNT_inc(sv);
      /* XXX memory leak using av_store? _inc AGAIN? */
      av_store(av2, i, sv);
      eList = eList->next;
      i++;
    }
    rv = newRV_inc((SV *)av2);
    av_push(av1, rv);

  }

  rv = newRV_inc((SV *)av1);
  return(rv);
}
