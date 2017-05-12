
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <Msp/msp.h>
#include <MspTools/msp_tools.h>
#include <MspTools/msp_helpers.h>
#include "Status/status.h"

static void freeMSPList(MSP *m);
static SV *buildOutputBulk(int count, MSP **paths, int *costs);
static AV * buildSegmentReturnValue(int cost, int leftStart, int leftEnd,
				    int rightStart, int rightEnd);
static SV *buildBulkMSPs(int count, MSP **msps);

/*
 * A helper function for the XS routine getMSPs.
 *  o pickup config info
 *  o get the set of msp's
 *  o Then run down the list, and create a new perl MSP object
 *    for each msps on the list.
 *
 */

SV *
getMSPs_helper(char *s1, char *s2)
{
  int status = STAT_OK;
  mspConfig *mspC = NULL;
  MSP *msp = NULL;
  int numMSPs = 0;
  AV *av = NULL;
  SV *sv = NULL;
  SV *rv = NULL;

  status = getMSPConfig(&mspC);
  BailError(status);

  status = getMSPs(s1, s2, mspC, &msp, &numMSPs);
  BailError(status);
  
  if (numMSPs > 0) {
    av = newAV();
    while (msp) {
      sv = sv_newmortal();
      sv_setref_pv(sv, "GH::Msp", (void*) msp);
      (void) SvREFCNT_inc(sv);
      av_push(av, sv);
      msp = msp->next_msp;
    }
    rv = newRV_inc((SV *)av);
  }
  else {
  }

 bail:
  if (mspC) free(mspC);		/* allocated by getMSPConfig */
  return(rv);
}

SV *
MSPMismatches_helper(MSP *msp, char *s1, char *s2)
{
  int i;
  int mismatches = 0;
  int s1pos;
  int s2pos;

  s1pos = msp->pos1;
  s2pos = msp->pos2;
  for(i=0; i < msp->len; i++) {
    if (s1[s1pos] != s2[s2pos]) {
      mismatches++;
    }
    s1pos++;
    s2pos++;
  }

  return(newSViv(mismatches));
}

SV *
getMSPsBulk_helper(char *s1, SV *arrayRef)
{
  int status = STAT_OK;

  AV *av;
  int count = 0;
  char **seqs = NULL;
  int i;
  mspConfig *mspC;
  AV *av2;
  SV **sv;
  int s2Len;
  MSP **msps = NULL;
  int *counts = NULL;
  SV *outRV = NULL;
  
  if ((!SvROK(arrayRef)) || (SvTYPE(SvRV(arrayRef)) != SVt_PVAV)) {
    status = STAT_BAD_ARGS;
    goto bail;
  }
  av = (AV *) SvRV(arrayRef);	/* get the array from the ref */
  count = av_len(av) + 1;	/* remember that av_len is max. index. */

  seqs = (char **) malloc(count * sizeof (char *));
  BailNull(seqs, status);

  for(i=0; i<count;i++) {
    sv = av_fetch(av, i, 0); 
    seqs[i] = SvPV(*sv, s2Len); /* pull the string from it */
  }
  
  status = getMSPConfig(&mspC);
  BailError(status);
  status = getMSPsBulk(s1, count, seqs, mspC, &msps);
  BailError(status);
  
  outRV = buildBulkMSPs(count, msps); 
  
 bail:  
  if (msps) 
    free(msps);
  if (seqs) free(seqs);
  if (counts) free(counts);
  return(outRV);
}

/*
 * A helper function for the XS routine findBestOverlap.
 *  o pickup config info
 *  o get a set of msp's
 *  o find a "best" overlap path
 *  o get the bounds of the segments that make up the path.
 *  o build up the perl data structure to return
 *  o pass it on back.
 *
 */

SV *
findBestOverlap_helper(char *s1, char *s2)
{
  int status = STAT_OK;
  mspConfig *mspC = NULL;
  MSP *msp = NULL;
  int numMSPs;
  MSP *bestPath = NULL;
  int numInPath;
  int bestCost;
  int leftStart;
  int rightStart;
  int leftEnd;
  int rightEnd;
  AV *av = NULL;
  SV *rv = NULL;
  
  status = getMSPConfig(&mspC);
  BailError(status);

  status = getMSPs(s1, s2, mspC, &msp, &numMSPs);
  BailError(status);
  
  if (numMSPs > 0) {
    status = findBestOverlapPath(s1, s2, msp, numMSPs, mspC,
				 &bestPath, &numInPath, &bestCost);
    BailError(status);
    
    /* the last msp in the path is the first msp in the bestPath list */
    leftEnd = bestPath->pos1 + bestPath->len - 1;
    rightEnd = bestPath->pos2 + bestPath->len - 1;
    
    while(bestPath->next_msp != NULL) {
      bestPath = bestPath->next_msp;
    }
    leftStart = bestPath->pos1;
    rightStart = bestPath->pos2;
    
    if (numInPath > 0) {
      av = buildSegmentReturnValue(bestCost,
				   leftStart, leftEnd,
				   rightStart, rightEnd);
      rv = newRV_inc((SV *)av);
    }
    else {
      rv = &PL_sv_undef;
    }
  }
  else {
    rv = &PL_sv_undef;
  }

 bail:
  if (mspC) free(mspC);
  if (msp) freeMSPList(msp);
  return(rv);
}

/*
 * A helper function for the XS routine tmpPlace
 *  o pickup config info
 *  o get a set of msp's
 *  o ...
 *
 */

SV *
tmpPlace_helper(char *s1, char *s2)
{
  int status = STAT_OK;
  mspConfig *mspC;
  MSP *msp;
  int numMSPs;
  MSP *bestPath = NULL;
  int numInPath = 0;
  int bestCost;
  AV *av;
  SV *rv = NULL;
  int leftStart;
  int rightStart;
  int leftEnd;
  int rightEnd;
  
  status = getMSPConfig(&mspC);
  BailError(status);
  status = getMSPs(s1, s2, mspC, &msp, &numMSPs);
  BailError(status);
  
  status = tmpPlace(s1, s2, msp, numMSPs, mspC,
		    &bestPath, &numInPath, &bestCost);
  BailError(status);

  /* the last msp in the path is the first msp in the list... */
  leftEnd = bestPath->pos1 + bestPath->len - 1;
  rightEnd = bestPath->pos2 + bestPath->len - 1;
  
  printf("S1start: %d S1end: %d.\n", bestPath->pos1, bestPath->pos1 + bestPath->len);
  while(bestPath->next_msp != NULL) {
    bestPath = bestPath->next_msp;
    printf("S1start: %d S1end: %d.\n", bestPath->pos1, bestPath->pos1 + bestPath->len);
  }
  leftStart = bestPath->pos1;
  rightStart = bestPath->pos2;
  
  if (numInPath > 0) {
    av =  buildSegmentReturnValue(bestCost,
				  leftStart, leftEnd,
				  rightStart, rightEnd);
    rv = newRV_inc((SV *)av);
  }
  
 bail:
  if (mspC) free(mspC);
  if (msp) freeMSPList(msp);
  return(rv);
}

/*
 * A helper function for the XS routine findBestInclusion
 *  o pickup config info
 *  o get a set of msp's
 *  o find a "best" inclusion path
 *  o get the bounds of the segments that make up the path.
 *  o build up the perl data structure to return
 *  o pass it on back.
 *
 */

SV *
findBestInclusion_helper(char *s1, char *s2)
{
  int status = STAT_OK;
  mspConfig *mspC;
  MSP *msp;
  int numMSPs;
  MSP *bestPath = NULL;
  int numInPath = 0;
  int bestCost;
  AV *av;
  SV *rv = NULL;
  int leftStart;
  int rightStart;
  int leftEnd;
  int rightEnd;
  
  status = getMSPConfig(&mspC);
  BailError(status)
  status = getMSPs(s1, s2, mspC, &msp, &numMSPs);
  BailError(status);
  
  status = findBestInclusionPath(s1, s2, msp, numMSPs, mspC,
                                       &bestPath, &numInPath, &bestCost);
  BailError(status);

  /* the last msp in the path is the first msp in the list... */
  leftEnd = bestPath->pos1 + bestPath->len - 1;
  rightEnd = bestPath->pos2 + bestPath->len - 1;
  
  while(bestPath->next_msp != NULL) {
    bestPath = bestPath->next_msp;
  }
  leftStart = bestPath->pos1;
  rightStart = bestPath->pos2;
  
  if (numInPath > 0) {
    av =  buildSegmentReturnValue(bestCost,
				  leftStart, leftEnd,
				  rightStart, rightEnd);
    rv = newRV_inc((SV *)av);
  }
  
 bail:
  if (mspC) free(mspC);
  if (msp) freeMSPList(msp);
  return(rv);
}


/*
 * A helper function for the XS routine findBestInclusionBulk.
 *  o unpack the arguments (names, seqs) from the perl data structure
 *    and store them in simple C arrays.
 *  o get the MSP config info.
 *  o dive into the C layer and find a whole bunch of inclusion paths
 *  o build up the perl data structures for the return values.
 *  o pass it on back.
 *
 */

SV *
findBestInclusionBulk_helper(char *s1, SV *arrayRef)
{
  int status = STAT_OK;

  AV *av;
  int count = 0;
  char **names = NULL;
  char **seqs = NULL;
  int i;
  mspConfig *mspC;
  SV **rv;
  AV *av2;
  SV **sv;
  char *s2Name;
  char *s2Seq;
  int s2Len;
  MSP **paths = NULL;
  int *costs = NULL;
  SV *outRV = NULL;
  
  if ((!SvROK(arrayRef)) || (SvTYPE(SvRV(arrayRef)) != SVt_PVAV)) {
    status = STAT_BAD_ARGS;
    goto bail;
  }
  av = (AV *) SvRV(arrayRef);	/* get the array from the ref */
  count = av_len(av) + 1;	/* remember that av_len is max. index. */
  names = (char **) malloc(count * sizeof (char *));
  BailNull(names, status);
  seqs = (char **) malloc(count * sizeof (char *));
  BailNull(seqs, status);

  for(i=0; i<count;i++) {
    /* get the ref to the name, seq array */
    rv = av_fetch(av, i, 0); 
    /* make sure that the correct structure was passed in. */
    if ((!SvROK(*rv)) || (SvTYPE(SvRV(*rv)) != SVt_PVAV)) {
      status = STAT_BAD_ARGS;
      goto bail;
    }
    /* convert it to an array. */
    av2 = (AV *) SvRV(*rv);
    
    if (av_len(av2) != 1) {	/* remember that av_len is max. index */
      status = STAT_BAD_ARGS;
      goto bail;
    }
    sv = av_fetch(av2, 0, 0);
    s2Name = SvPV_nolen(*sv); /* pull the string from it */
    
    sv = av_fetch(av2, 1, 0);
    s2Seq = SvPV(*sv, s2Len); /* pull the string from it */
    
    names[i] = s2Name;
    seqs[i] = s2Seq;
  }
  
  status = getMSPConfig(&mspC);
  BailError(status);
  status = findInclusionsBulk(s1, count, names, seqs, mspC, &paths, &costs);
  BailError(status);
  
  outRV = buildOutputBulk(count, paths, costs); 
  
 bail:  
  if (paths) 
    for(i=0; i<count;i++) 
      freeMSPList(paths[i]);
  if (names) free(names);
  if (seqs) free(seqs);
  if (costs) free(costs);
  return(outRV);
}

/****************************************************************************
 * End of the "public" _helper functions.
 ****************************************************************************/

int
getMSPConfig(mspConfig **mspC)
{
  int status = STAT_OK;
  mspConfig *tmp;
  SV *sv;

  tmp = (mspConfig *)malloc(sizeof(mspConfig));
  BailNull(tmp, status);

  sv = get_sv("GH::MspTools::tableSize", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->tableSize = SvIV(sv);
  }
  else {
    tmp->tableSize = 32767;
  }
  
  sv = get_sv("GH::MspTools::wordSize", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->wordSize = SvIV(sv);
  }
  else {
    tmp->wordSize = 12;
  }
  
  sv = get_sv("GH::MspTools::extensionThreshold", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->extensionThresh= SvIV(sv);
  }
  else {
    tmp->extensionThresh = 12;
  }
  
  sv = get_sv("GH::MspTools::mspThreshold", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->mspThresh = SvIV(sv);
  }
  else {
    tmp->mspThresh = 12;
  }
  
  sv = get_sv("GH::MspTools::matchScore", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->matchScore = SvIV(sv);
  }
  else {
    tmp->matchScore = 1;
  }
  
  sv = get_sv("GH::MspTools::mismatchScore", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->mismatchScore = SvIV(sv);
  }
  else {
    tmp->mismatchScore = -5;
  }
  
  sv = get_sv("GH::MspTools::ovFudge", FALSE);
  if((sv) && (SvIOK(sv))) {
    tmp->ovFudge = SvIV(sv);
  }
  else {
    tmp->ovFudge = 30;
  }
  
  *mspC = tmp;
  return(status);
 bail:
  *mspC = NULL;
  return(status);
}


void
freeMSPList(MSP *msp)
{
  MSP *tmp;
  
  tmp = msp;	
  while (msp != NULL) {
    tmp = msp->next_msp;
    free(msp);
    msp = tmp;
  }
}

SV *
buildOutputBulk(int count, MSP **paths, int *costs)
{
  int i;
  MSP *tmp;
  int leftEnd, rightEnd, leftStart, rightStart;
  AV *outAV;
  AV *resultAV;

  outAV = newAV();

  for(i=0; i<count;i++) {

    tmp = paths[i];

    if (tmp) {
      leftEnd = tmp->pos1 + tmp->len - 1;
      rightEnd = tmp->pos2 + tmp->len - 1;
		
      while(tmp->next_msp != NULL) {
	tmp = tmp->next_msp;
      }	
      leftStart = tmp->pos1;
      rightStart = tmp->pos2;
		
      resultAV = buildSegmentReturnValue(costs[i],
					 leftStart, leftEnd,
					 rightStart, rightEnd);
      av_push(outAV, newRV_noinc((SV *)resultAV));
    }
    else {
      av_push(outAV, &PL_sv_undef);
    }
  }	
  
  return(newRV_noinc((SV *)outAV));
}

AV *
buildSegmentReturnValue(int cost, int leftStart, int leftEnd,
			int rightStart, int rightEnd)
{
  AV *av;
  SV *sv;

  av = newAV();
  sv = newSViv(cost);		/* cost */
  av_push(av, sv);
  sv = newSViv(leftStart);	/* left start */
  av_push(av, sv);
  sv = newSViv(leftEnd);	/* left end */
  av_push(av, sv);
  sv = newSViv(rightStart);	/* right start */
  av_push(av, sv);
  sv = newSViv(rightEnd);	/* right end */
  av_push(av, sv);

  return(av);
}

static SV *
buildBulkMSPs(int count, MSP **msps)
{
  int i;
  MSP *tmp;
  AV *outAV;
  AV *av;
  SV *sv;

  outAV = newAV();

  for(i=0; i<count;i++) {

    if (msps[i] != NULL) {
      av = newAV();
      tmp = msps[i];
      while (tmp) {
	sv = sv_newmortal();
	sv_setref_pv(sv, "GH::Msp", (void*) tmp);
	(void) SvREFCNT_inc(sv);
	av_push(av, sv);
	tmp = tmp->next_msp;
      }
      /*av_push(outAV, newRV_noinc((SV *)av)); */
      av_push(outAV, newRV_inc((SV *)av));
    }
    else {
      av_push(outAV, &PL_sv_undef);
    }
  }	
  
  /*return(newRV_noinc((SV *)outAV)); */
  return(newRV_inc((SV *)outAV));
}
