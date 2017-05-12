#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <limits.h>
#include "Status/status.h"
#include "EditOp/editop.h"


int
findGlobalMinDifferences(char *s1, char *s2, int *cost, EditOp **editList)
{
  int status = STAT_OK;
  int s1Len = 0;
  int s2Len = 0;
  int **rows = NULL;
  int *cells = NULL;
  int *traceback = NULL;
  int i, j;
  int traceLen;
  int tmp_int;
  int runLen;
  EditOp *eListHead;
  EditOp *eListTail;
  
  s1Len = strlen(s1);
  s2Len = strlen(s2);
  
  /*
   * Allocate a big array for the dynamic programming matrix and
   * for the traceback results.
   */

  cells = (int*) malloc((s1Len+1) * (s2Len+1) * sizeof(int));
  BailNull(cells, status);
  memset(cells, -1, ((s1Len+1) * (s2Len+1) * (sizeof(int))));

  rows = (int **) malloc((s1Len+1) * sizeof(int *));
  BailNull(rows, status);
  for(i=0; i < (s1Len+1); i++) {
    rows[i] = cells + (i * (s2Len+1));
  }
  traceback = (int *) malloc(((s1Len+1) + (s2Len+1)) * sizeof(int));
  BailNull(traceback, status);

  /*
   * Do the dynamic programming thing.
   */

  for(i=0; i < (s1Len+1); i++) {
    *(rows[i] + 0) = i;
  }
  for(j=0; j < (s2Len+1); j++) {
    *(rows[0] + j) = j;
  }
  for(i=1; i < (s1Len+1); i++) {
    for(j=1; j < (s2Len+1); j++) {
      *(rows[i] + j) = *(rows[i-1] + (j-1)) + (s1[i-1] == s2[j-1] ? 0 : 1);
      if ((*(rows[i-1] + j) + 1) < *(rows[i] + j))
	*(rows[i] + j) = *(rows[i-1] + j) + 1;
      if ((*(rows[i] + (j-1)) + 1) < *(rows[i] + j))
	*(rows[i] + j) = *(rows[i] + (j-1)) + 1;
    }
  }

  *cost = *(rows[s1Len] + (s2Len));

  /*
   * Traceback.  Walk from the bottom right corner back up to the upper
   * left, stuffing notes about the edit operations into an array as we
   * go.
   */

  i = s1Len;
  j = s2Len;
  traceLen = 0;

  /* trace back to one of the edges or the corner */
  while ((i != 0) && (j!= 0)) {
    if ((*(rows[i-1] + (j-1)) <= *(rows[i] + (j-1))) &&
	(*(rows[i-1] + (j-1)) <= *(rows[i-1] + (j)))) {
      if (s1[i-1] == s2[j-1]) {
	/* match */
	traceback[traceLen++] = MATCH;
      }
      else {
	/* mismatch */
	traceback[traceLen++] = MISMATCH;
      }
      i--; j--;
    }
    else {
      if (*(rows[i-1] + (j)) <= *(rows[i] + (j-1))) {
	/* insert into s1 */
	traceback[traceLen++] = INSERT_S1;
	i--;
      }
      else {
	/* insert into s2 */
	traceback[traceLen++] = INSERT_S2;
	j--;
      }
    }
  }
  
  /* if necessary, run along an edge to the corner */
  while (i != 0) {
    /* insert into s1 */
    traceback[traceLen++] = INSERT_S1;

    i--;
  }
  while (j != 0) {
    /* insert into s2 */
    traceback[traceLen++] = INSERT_S2;
    j--;
  }

  /* reverse the traceback array */
  i=0;
  j=traceLen-1;
  while (i < j) {
    tmp_int = traceback[i];
    traceback[i] = traceback[j];
    traceback[j] = tmp_int;
    i++;
    j--;
  }

    
  /*  compress the traceback array into a set of editops */
  eListHead = eListTail = NULL;
  i = 0;
  while (i<traceLen) {
    EditOp *e;

    runLen = 1;

    while (((i + runLen) < traceLen) &&
	   (traceback[i] == traceback[i+runLen])) {
      runLen++;
    }
    
    e = (EditOp *)malloc(sizeof(EditOp));
    BailNull(e, status);
    e->type = traceback[i];
    e->count = runLen;
    e->next = NULL;
    if (!eListHead) {
      eListHead = eListTail = e;
    }
    else {
      eListTail->next = e;
      eListTail = e;
    }
    i += runLen;
  }

  *editList = eListHead;

 bail:
  if (cells) free(cells);
  if (rows) free(rows);
  if (traceback) free(traceback);
  return(status);
}

int
findBoundedGlobalMinDifferences(char *s1, char *s2, int bound, int *cost, EditOp **editList)
{
  int status = STAT_OK;
  int s1Len = 0;
  int s2Len = 0;
  int maxL = 0;
  short int **rows = NULL;
  char **trace_rows = NULL;
  short int *cells = NULL;
  char *trace = NULL;
  char *traceback = NULL;
  int i, j, l;
  int traceLen;
  int tmp_int;
  int runLen;
  EditOp *eListHead;
  EditOp *eListTail;
  
  s1Len = strlen(s1);
  s2Len = strlen(s2);
  maxL = 2 * bound;		/* assumes 0 based array (2*bound+1 elements) */
  
  if (abs(s1Len - s2Len) > bound) {
    status = STAT_BOUND_TOO_TIGHT;
    goto bail;
  }

  /*
   * Allocate a big array for the dynamic programming matrix and
   * for the traceback results.
   */

  /*
   * The traceback code depends on the TRACE array being init'd to
   * a sentinel value (-1).
   */
  cells = (short int*) malloc((s1Len+1) * (maxL+1) * sizeof(short int));
  BailNull(cells, status);
  memset(cells, -1, ((s1Len+1) * (maxL+1) * (sizeof(short int))));

  trace = (char*) malloc((s1Len+1) * (maxL+1) * sizeof(char));
  BailNull(trace, status);
  memset(trace, -1, ((s1Len+1) * (maxL+1) * (sizeof(char))));

  rows = (short int **) malloc((s1Len+1) * sizeof(short int *));
  BailNull(rows, status);
  trace_rows = (char **) malloc((s1Len+1) * sizeof(char *));
  BailNull(trace_rows, status);

  traceback = (char *) malloc(((s1Len+1) + (s2Len+1)) * sizeof(char));
  BailNull(traceback, status);
  memset(traceback, -1, ((s1Len+1) + (s2Len+1) * (sizeof(char))));

  for(i=0; i < (s1Len+1); i++) {
    rows[i] = cells + (i * (maxL+1));
    trace_rows[i] = trace + (i * (maxL+1));
  }

#define CELL(i,l) (*(rows[i] + l))
#define TRACE(i,l) (*(trace_rows[i] + l))

#define FIRST_CELL_DP(i,l) \
  CELL(i,l) = CELL(i-1,l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  TRACE(i,l) = (s1[i-1] == s2[i-bound+l-1] ? MATCH : MISMATCH); \
  if ((CELL(i-1,l+1) + 1) < CELL(i,l)) { \
    CELL(i,l) = CELL(i-1,l+1) + 1; \
    TRACE(i,l) = INSERT_S1; \
  } \

#define NORMAL_CELL_DP(i,l) \
  CELL(i,l) = CELL(i-1,l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  TRACE(i,l) = (s1[i-1] == s2[i-bound+l-1] ? MATCH : MISMATCH); \
  if ((CELL(i-1,l+1) + 1) < CELL(i,l)) { \
    CELL(i,l) = CELL(i-1,l+1) + 1; \
    TRACE(i,l) = INSERT_S1; \
  } \
  if ((CELL(i,l-1) + 1) < CELL(i,l)) { \
    CELL(i,l) = CELL(i,l-1) + 1; \
    TRACE(i,l) = INSERT_S2; \
  }

#define LAST_CELL_DP(i,l) \
  CELL(i,l) = CELL(i-1,l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  TRACE(i,l) = (s1[i-1] == s2[i-bound+l-1] ? MATCH : MISMATCH); \
  if ((CELL(i,l-1) + 1) < CELL(i,l)) { \
    CELL(i,l) = CELL(i,l-1) + 1; \
    TRACE(i,l) = INSERT_S2; \
  }

  /*
   * Do the dynamic programming thing.
   */

  /* phase 1 */
  for(i=0; i <= bound; i++) {
    CELL(i,bound - i) = i;
    TRACE(i,bound - i) = INSERT_S1;
  }

  /* phase 2 */
  for(l=bound; l <= maxL; l++) {
    CELL(0,l) = l - bound;
    TRACE(0,l) = INSERT_S2;
  }

  /* phase 3. */
  for(i=1; i <= bound; i++) {
    for(l=bound-i+1; l < maxL; l++) {
      NORMAL_CELL_DP(i,l);	/* phase 3, regular cells */
    }
    LAST_CELL_DP(i,maxL);	/* phase 3, last cell */
  }

  /* phase 4. */
  for(i=bound+1; i <= s2Len - bound; i++) {
    FIRST_CELL_DP(i,0);		/* phase 4, first cell */

    for(l=1; l < maxL; l++) {
      NORMAL_CELL_DP(i,l);	/* phase 4, regular cells */
    }
 
    LAST_CELL_DP(i,maxL);	/* phase 4, last cell */
  }

  /* phase 5. */
  for(i=s2Len-bound+1; i <= s1Len; i++) {
    FIRST_CELL_DP(i,0);		/* phase 5, first cell */

    /*    for(l=1; l <= maxL - bound + s1Len - i; l++) { */
    for(l=1; i-bound+l < s2Len+1; l++) {
      NORMAL_CELL_DP(i,l);	/* phase 5, regular cells */
    }
  }

  /*
   * Traceback.  Walk from the bottom right corner back up to the upper
   * left, stuffing notes about the edit operations into an array as we
   * go.
   */

#if 0
  for (i=0; i <= s1Len; i++) {
    for(l=0; l < maxL; l++) {
      printf("%3d, ", CELL(i,l));
    }
    printf("%3d\n", CELL(i,maxL));
  }

  printf("-----------------------------------------\n");
  for (i=0; i <= s1Len; i++) {
    for(l=0; l < maxL; l++) {
      printf("%3d, ", TRACE(i,l));
    }
    printf("%3d\n", TRACE(i,maxL));
  }
#endif

  i = s1Len;
  l = maxL;
  traceLen = 0;

  /* finding where to start the traceback depends on the sentinel value
   * memset above.
   */
  while (TRACE(i,l) == -1) {
    l--;
  }
  
  *cost = CELL(s1Len, l);

  while (i != 0) {
    traceback[traceLen++] = TRACE(i,l);
    switch (TRACE(i,l)) {
    case MATCH:
      i--;
      break;
    case MISMATCH:
      i--;
      break;
    case INSERT_S1:
      i--;
      l++;
      break;
    case INSERT_S2:
      l--;
      break;      
    default:
      printf("YIKES: CELL(%d, %d) = %d\n", i, l, *(trace_rows[i] + l));
      i--;l--;
    }
  }
  
  /* if necessary, run along an edge to the corner */
  while (l != bound) {
    traceback[traceLen++] = TRACE(i,l);
    l--;
  }

  /* reverse the traceback array */
  i=0;
  l=traceLen-1;
  while (i < l) {
    tmp_int = traceback[i];
    traceback[i] = traceback[l];
    traceback[l] = tmp_int;
    i++;
    l--;
  }
  
  /*  compress the traceback array into a set of editops */
  eListHead = eListTail = NULL;
  i = 0;
  while (i<traceLen) {
    EditOp *e;

    runLen = 1;

    while (((i + runLen) < traceLen) &&
	   (traceback[i] == traceback[i+runLen])) {
      runLen++;
    }
    
    e = (EditOp *)malloc(sizeof(EditOp));
    BailNull(e, status);
    e->type = traceback[i];
    e->count = runLen;
    e->next = NULL;
    if (!eListHead) {
      eListHead = eListTail = e;
    }
    else {
      eListTail->next = e;
      eListTail = e;
    }
    i += runLen;
  }

  *editList = eListHead;

 bail:
  if (cells) free(cells);
  if (rows) free(rows);
  if (trace) free(trace);
  if (trace_rows) free(trace_rows);
  if (traceback) free(traceback);
  return(status);
}

#if 0

#undef CELL
#define CELL(l) (*(currRow + l))
#define CELLUP(l) (*(prevRow + l))
#define CELLDOWN(l) (*(prevRow + l))

#undef FIRST_CELL_DP
#define FIRST_CELL_DP(i,l) \
  CELL(l) = CELLUP(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELLUP(l+1) + 1) < CELL(l)) { \
    CELL(l) = CELLUP(l+1) + 1; \
  } \

#define FIRST_CELL_DP_REV \
  CELL(l) = CELLDOWN(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELL(l+1) + 1) < CELL(l)) { \
    CELL(l) = CELL(l+1) + 1; \
  }

#undef NORMAL_CELL_DP
#define NORMAL_CELL_DP(i,l) \
  CELL(l) = CELLUP(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELLUP(l+1) + 1) < CELL(l)) { \
    CELL(l) = CELLUP(l+1) + 1; \
  } \
  if ((CELL(l-1) + 1) < CELL(l)) { \
    CELL(l) = CELL(l-1) + 1; \
  }

#define NORMAL_CELL_DP_REV(i,l) \
  CELL(l) = CELLDOWN(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELLDOWN(l-1) + 1) < CELL(l)) { \
    CELL(l) = CELLDOWN(l-1) + 1; \
  } \
  if ((CELL(l+1) + 1) < CELL(l)) { \
    CELL(l) = CELL(l+1) + 1; \
  }

#undef LAST_CELL_DP
#define LAST_CELL_DP(i,l) \
  CELL(l) = CELLUP(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELL(l-1) + 1) < CELL(l)) { \
    CELL(l) = CELL(l-1) + 1; \
  }

#define LAST_CELL_DP_REV(i,l) \
  CELL(l) = CELLDOWN(l) + (s1[i-1] == s2[i-bound+l-1] ? 0 : 1); \
  if ((CELLDOWN(l-1) + 1) < CELL(l)) { \
    CELL(l) = CELLDOWN(l-1) + 1; \
  } \
  
#define PUSHROW(curr,prev) \
  tmpRow = prevRow; \
  prevRow = currRow; \
  currRow = tmpRow; \
  memset(currRow, -1, ((2 * bound + 1) * sizeof(int)));

#define DUMPCURR(prefix) \
  printf(prefix); \
  for(l=0;l<=maxL;l++) \
    printf("%d ", CELL(l)); \
  printf("\n");

int
findHirschbergBoundedGlobalMinDiffs(char *s1, char *s2, int bound,
				    int *cost, EditOp **editList)
{
  int status = STAT_OK;
  int s1Len = 0;
  int s2Len = 0;
  int maxL = 0;
  int minJ = -1;
  int minL = -1;
  int minLval = INT_MAX;
  int urI, urJ;			/* upper right */
  int llI, llJ;			/* lower left */
  int funnyRowCount;		/* how many rows are "short" */
  int i, j, l;
  int midpoint;
  int *currRow = NULL;
  int *prevRow = NULL;
  int *midRow = NULL;
  int *tmpRow= NULL;
  
  maxL = 2 * bound;
  s1Len = strlen(s1);
  s2Len = strlen(s2);

  if (abs(s1Len - s2Len) > bound) {
    status = STAT_BOUND_TOO_TIGHT;
    goto bail;
  }

  currRow = (int *)malloc((2 * bound + 1) * sizeof(int));
  BailNull(currRow, status);
  memset(currRow, -1, ((2 * bound + 1) * sizeof(int)));

  prevRow = (int *)malloc((2 * bound + 1) * sizeof(int));  
  BailNull(prevRow, status);
  memset(prevRow, -1, ((2 * bound + 1) * sizeof(int)));

  midRow = (int *)malloc((2 * bound + 1) * sizeof(int));  
  BailNull(midRow, status);
  memset(midRow, 0, ((2 * bound + 1) * sizeof(int)));

  urI = 0;
  urJ = 0;
  llI = s1Len;
  llJ = s1Len;			/* XXXX LIAR! */

  while (urI + 1 < llI) {
    midpoint = (llI-urI)/2;  

    /*****************************************************************
     * Do the dynamic programming thing.
     */
    /*
     * FORWARD phase
     */

    /* do the first couple nasty rows */
    
    funnyRowCount = bound + urI - urJ;

    for(l=funnyRowCount; l<=maxL;l++) /* the row at urI is just insert_s2's */
      CELL(l) = l - funnyRowCount;

    /* now run any remaining funny rows (watch first cell) */
    for(i=urI+1; i<=urI+funnyRowCount; i++) { 
      PUSHROW(currRow, prevRow);
      CELL(funnyRowCount-i) = i;		/* insert_s1's */
      for(l=funnyRowCount-i+1; l < maxL; l++) {
	NORMAL_CELL_DP(i,l);
      }
      LAST_CELL_DP(i,maxL);	
    }

    /* main loop. */
    for(i=urI+funnyRowCount+1; i <= midpoint; i++) {
      PUSHROW(currRow, prevRow);
      FIRST_CELL_DP(i,0);
      for(l=1; l < maxL; l++) {
	NORMAL_CELL_DP(i,l);
      }
      LAST_CELL_DP(i,maxL);
    }

    tmpRow = midRow;
    midRow = currRow;
    currRow = tmpRow;

    /*
     * REVERSE
     */

#if 0
    /* do the dirty work in the bottom corner... */
    for(l=0; l<=bound;l++)
      CELL(l) = bound-l;		/* insert_s2's */

    for(i=ll-1; i>=ll-bound; i--) {
      PUSHROW(currRow, prevRow);
      CELL(bound+ll-i) = (ll - i); /* insert_s1's */
      for(l=bound+ll-i-1; l > 0; l--) {
	NORMAL_CELL_DP_REV(i,l);
      }
      FIRST_CELL_DP_REV(i,0);	
    }

    /* main reverse loop */
    for(i=ll-bound-1; i>= midpoint; i--) {
      PUSHROW(currRow, prevRow);
      LAST_CELL_DP_REV(i,maxL);
      for(l=maxL-1; l > 0; l--) {
	NORMAL_CELL_DP_REV(i,l);
      }
      FIRST_CELL_DP_REV(i,0);
    }


    /* add together the forward and reverse scores */
    for(l=0; l<=maxL; l++)
      midRow[l] += currRow[l];

    /* and choose a minimal column */
    for(l=0; l<=maxL;l++) {
      if (midRow[l] < minLval) {
	minLval = midRow[l];
	minL = l;
      }
    }
    minJ = midpoint + minL - bound;

    printf("min col at %d, val %d\n", minJ, minLval);
    ll = minJ;
#endif
  }
 bail:
  if (currRow) free(currRow);
  if (prevRow) free(prevRow);
  if (midRow) free(midRow);
  return(status);
}

#endif
