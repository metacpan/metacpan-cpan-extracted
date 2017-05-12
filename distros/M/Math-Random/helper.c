/* NOTE: RETURN CODES HAVE BEEN CHANGED TO MATCH PERL, I.E.
   1 - NOW MEANS OK
   0 - NOW MEANS ERROR
   */

#include "randlib.h"
#include <stdio.h>
#include <stdlib.h>
#include "helper.h"

static long   *iwork = NULL; /* perl long array, alloc. in 'rspriw'  */
static double *fwork = NULL; /* perl float array, alloc. in 'rsprfw' */
static double *parm  = NULL; /* maintained by 'psetmn' for 'pgenmn'  */

/****************************************************************************
                Perl <-> C (Long) Integer Helper Functions
 (these pass single values back and forth, to load/read/manage working array)
 ****************************************************************************/

long gvpriw(long index) {
  /* Gets the Value at index of the PeRl (long) Integer Working array */
  extern long *iwork;
  
  return *(iwork + index);
}

int rspriw(long size) {
  /* Request Size for PeRl's (long) int Working array
   * returns:
   * 1 if successful
   * 0 if out of memory
   */
  extern long *iwork;
  static long siwork = 0L;

  if (size <= siwork) return 1;
  /* else reset array */
  if (iwork != NULL) free(iwork);
  iwork = (long *) malloc(sizeof(long) * size);
  if (iwork != NULL) {
    siwork = size;
    return 1;
  }
  fputs(" Unable to allocate randlib (long) int working array:\n",stderr);
  fprintf(stderr," Requested number of entries = %ld\n",size);
  fputs(" Out of memory in RSPRIW - ABORT\n",stderr);
  siwork = 0L;
  return 0;
}

/****************************************************************************
                Perl <-> C Float Helper Functions
 (these pass single values back and forth, to load/read/manage working array)
 ****************************************************************************/

double gvprfw(long index) {
  /* Gets the Value at index of the PeRl Float Working array */
  extern double *fwork;
  
  return *(fwork + index);
}

void svprfw(long index, double value) {
  /* Sets Value in PeRl's Float Working array */
  extern double *fwork;

  *(fwork + index) = value;
}
    
int rsprfw(long size) {
  /* Request Size for PeRl's Float Working array
   * returns:
   * 1 if successful
   * 0 if out of memory
   */
  extern double *fwork;
  static long sfwork = 0L;

  if (size <= sfwork) return 1;
  /* else reset array */
  if (fwork != NULL) free(fwork);
  fwork = (double*) malloc(sizeof(double) * size);
  if (fwork != NULL) {
    sfwork = size;
    return 1;
  }
  fputs(" Unable to allocate randlib float working array:\n",stderr);
  fprintf(stderr," Requested number of entries = %ld\n",size);
  fputs(" Out of memory in RSPRFW - ABORT\n",stderr);
  sfwork = 0L;
  return 0;
}

/*****************************************************************************
                           Randlib Helper Functions
      These routines call those randlib routines which depend on pointers
              (typically those with array input and/or output)
 *****************************************************************************/
void pgnprm(long n) {
  /* Perl's GeNerate PeRMutation
   * Fills perl's (long) integer working array with 0, ... ,n-1
   * and randomly permutes it.
   * Note: if n <= 0, it does what you'd expect:
   * N == 1: array of 0 of length 1
   * N <  1: array of length 0
   */

  /* NOTE: EITHER HERE OR IN PERL IWORK MUST HAVE SIZE CHECKED */

  extern long *iwork;
  long i;

  /* Fills working array ... */
  for (i=0L;i<n;i++)
    *(iwork + i) = i;

  /* ... and randomly permutes it */
  genprm(iwork,i);
}

void pgnmul (long n, long ncat) {
  /* Perl's GeNerate MULtinomial observation.
   * Method: uses void genmul(long n,double *p,long ncat,long *ix) in 'randlib.c'
   * Arguments:
   * n    - number of events to be classified.
   * ncat - number of categories into which the events are classified.
   * Notes:
   * *p - must be set up first in perl's double working array *fwork.
   *      must have at least ncat-1 categories and otherwise make sense.
   * *ix - (results) will be perl's (long) integer working array *iwork.
   */

  /* NOTE: FROM PERL, FWORK MUST HAVE SIZE CHECKED AND BE FILLED */
  /* ALSO, HERE OR IN PERL IWORK MUST HAVE SIZE CHECKED */

  extern long   *iwork;
  extern double *fwork;

  /* since all is OK so far, get the obs */
  genmul(n, fwork, ncat, iwork);
}

int psetmn(long p) {
  /*
   * Perl's SET Multivariate Normal
   * p - dimension of multivariate normal deviate
   *
   * Input:
   * fwork must be loaded as follows prior to call:
   *    Origin = 0 indexing           Origin = 1 indexing
   *    (reverse odometer)
   *       fwork[0]                 <-> mean[1]
   *       fwork[1]                 <-> mean[2]
   *        ...                          ...
   *       fwork[p - 1]             <-> mean[p]
   *       fwork[0 + 0*p + p]       <-> covm[1,1]
   *       fwork[1 + 0*p + p]       <-> covm[2,1]
   *        ...                          ...
   *       fwork[i-1 + (j-1)*p + p] <-> covm[i,j]
   *        ...                          ...
   *       fwork[p-1 + (p-1)*p + p] <-> covm[p,p]
   * Tot:  p*p + p elements                  p*p + p elements
   * This should all be done by the Perl calling routine.
   * 
   * Side Effects:
   * parm[p*(p+3)/2 + 1] is a file static array which contains all the
   * information needed to generate the deviates.
   * fwork is essentially destroyed (but not reallocated).
   *
   * Returns:
   * 1 if initialization succeeded
   * 0 if out of memory
   *
   * Method:
   * Calls 'setgmn' in "randlib.c":
   * void setgmn(double *meanv,double *covm,long p,double *parm)
   */
  
  extern double *fwork, *parm;
  static long oldp = 0L; /* p from last reallocate of parm */

  if (p > oldp) { /* pmn_param is too small; reallocate */
    if (parm != NULL) free(parm);
    parm = (double *) malloc(sizeof(double)*(p*(p+3L)/2L + 1L));
    if (parm == NULL) {
      fputs("Out of memory in PSETMN - ABORT",stderr);
      fprintf(stderr,
	      "P = %ld; Requested # of doubles %ld\n",p,p*(p+3L)/2L + 1L);
      oldp = 0L;
      return 0;
    } else {
      oldp = p; /* keep track of last reallocation */
    }
  }
  /* initialize parm */
  setgmn(fwork, fwork + p, p, parm);
  return 1;
}

int pgenmn(void) {
  /* 
   * Perl's GENerate Multivariate Normal
   *
   * Input: (None)
   * 
   * p - dimension of multivariate normal deviate - gotten from parm[].
   * 'psetmn' must be called successfully before this routine is called.
   * If that be so, then fwork[] has enough space for the deviate
   * and scratch space used by the routine, and parm[] has the
   * parameters needed.
   *
   * Output:
   * 0 - generation failed
   * 1 - generation succeeded
   *
   * Side Effects:
   * fwork[0] ... fwork[p-1] will contain the deviate.
   *
   * Method:
   * Calls 'genmn' in "randlib.c":
   * void genmn(double *parm,double *x,double *work)
   */
  
  extern double *fwork, *parm;

  /* NOTE: CHECK OF PARM ONLY NEEDED IF PERL SET/GENERATE IS SPLIT */

  if (parm != NULL) { /* initialized OK */
    long p = (long) *(parm);
    genmn(parm,fwork,fwork+p); /* put deviate in fwork */
    return 1;

  } else { /* not initialized - ABORT */
    fputs("PGENMN called before PSETMN called successfully - ABORT\n",
	  stderr);
    fputs("parm not properly initialized in PGENMN - ABORT\n",stderr);
    return 0;
  }
}

void salfph(char* phrase)
{
/*
**********************************************************************
     void salfph(char* phrase)
               Set ALl From PHrase

                              Function

     Uses a phrase (character string) to generate two seeds for the RGN
     random number generator, then sets the initial seed of generator 1
     to the results.  The initial seeds of the other generators are set
     accordingly, and all generators' states are set to these seeds.

                              Arguments
     phrase --> Phrase to be used for random number generation

                              Method
     Calls 'setall' (from com.c) with the results of 'phrtsd' (here in
     randlib.c).  Please see those functions' comments for details.
**********************************************************************
*/
extern void phrtsd(char* phrase,long *seed1,long *seed2);
extern void setall(long iseed1,long iseed2);
static long iseed1, iseed2;

phrtsd(phrase,&iseed1,&iseed2);
setall(iseed1,iseed2);
}
