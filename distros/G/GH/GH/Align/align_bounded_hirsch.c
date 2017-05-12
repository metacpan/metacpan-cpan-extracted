#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <limits.h>
#include "Status/status.h"
#include "EditOp/editop.h"
#include "align_context.h"

static int solveAdjacents(alignContext *a, int ulI, int ulJ, int lrI, int lrJ);
static int solveMiddleRow(alignContext *a, int ulI, int ulJ, int lrI, int lrJ);
static int buildEditOpList(alignContext *a, EditOp **eList, int *cost);
static int pushIJ(int ulI, int ulJ, int lrI, int lrJ);
static int popIJ(int *ulI, int *ulJ, int *lrI, int *lrJ);
static int emptyIJ();

int
findHirschbergBoundedGlobalMinDiffs(char *str1, char *str2, int bound,
				    int *cost, EditOp **editList)
{
  int status = STAT_OK;
  alignContext *a = NULL;
  int ulI, ulJ, lrI, lrJ;	/* upper left, lower right */
      
  if (abs(strlen(str1) - strlen(str2)) > bound) {
    status = STAT_BOUND_TOO_TIGHT;
    goto bail;
  }

  a = setupAlignContext(str1, str2, bound);
  BailNull(a, status);

  /*
   * Here's where the real work happens.
   */
  pushIJ(0, 0, a->s1Len, a->s2Len);
  while (! emptyIJ()) {
    status = popIJ(&ulI, &ulJ, &lrI, &lrJ);
    BailError(status);

    while (ulI + 1 < lrI && ulJ < lrJ) {
      assert(ulI < lrI);
      assert(ulJ < lrJ);
      status = solveMiddleRow(a, ulI, ulJ, lrI, lrJ);
      BailError(status);
      if (a->midRow + 1 < lrI) {
	pushIJ(a->midRow, a->optCol[a->midRow], lrI, lrJ);
      }
      else {
	status = solveAdjacents(a, a->midRow, a->optCol[a->midRow], lrI, lrJ);
	BailError(status);
      }
      lrI = a->midRow;
      lrJ = a->optCol[a->midRow];
    }
    status = solveAdjacents(a, ulI, ulJ, lrI, lrJ);
    BailError(status);
  }

  status = buildEditOpList(a, editList, cost);
  BailError(status);

 bail:
  if (a) freeAlignContext(a);
  return(status);
}

static int
solveAdjacents(alignContext *a, int ulI, int ulJ, int lrI, int lrJ)
{
  int status = STAT_OK;
  int i;

  /* touch up any optCol entries that wouldn't otherwise be touched. */
  if (ulJ == lrJ) 
    for(i=ulI; i<=lrI;i++)
      a->optCol[i] = ulJ;
    
  return(status);
}

#define CELL(a,l) (a->currRowFor[l])
#define CELL_UP(a,l) (a->prevRowFor[l])

#define CELL_REV(a,l) (a->currRowRev[l])
#define CELL_DOWN(a,l) (a->prevRowRev[l])

#define MATCHCOST(a,i,l) (a->s1[i-1] == a->s2[i-a->bound+l-1] ? 0 : 1)
#define MATCHCOST_REV(a,i,l) (a->s1[i] == a->s2[i-a->bound+l] ? 0 : 1)

#define NORMAL_CELL_DP(a,l) \
   /* assume match/mismatch */ \
   CELL(a,l) = CELL_UP(a,l) + MATCHCOST(a,i,l); \
   /* use INSERT_S1 if it's better */ \
   if (CELL_UP(a,l+1) + 1 < CELL(a,l)) { \
       CELL(a,l) = CELL_UP(a,l+1) + 1; \
   } \
   /* use INSERT_S2 if it's better still */ \
   if (CELL(a,l-1) + 1 < CELL(a,l)) { \
       CELL(a,l) = CELL(a,l-1) + 1; \
   }
#define NORMAL_CELL_DP_REV(a,l) \
   /* assume match/mismatch */ \
   CELL_REV(a,l) = CELL_DOWN(a,l) + MATCHCOST_REV(a,i,l); \
   /* use INSERT_S1 if it's better */ \
   if (CELL_DOWN(a,l-1) + 1 < CELL_REV(a,l)) { \
       CELL_REV(a,l) = CELL_DOWN(a,l-1) + 1; \
   } \
   /* use INSERT_S2 if it's better still */ \
   if (CELL_REV(a,l+1) + 1 < CELL_REV(a,l)) { \
       CELL_REV(a,l) = CELL_REV(a,l+1) + 1; \
   }
#define FIRST_CELL_DP(a,l) \
   /* assume INSERT_S1 */ \
   CELL(a,l) = CELL_UP(a,l+1) + 1; \
   /* check match/mismatch if it's safe */ \
   if (CELL_UP(a,l) != -1) { \
   /* YIKES XXXX */ \
      if (CELL_UP(a,l) + MATCHCOST(a,i,l) <= CELL(a,l)) { \
         CELL(a,l) = CELL_UP(a,l) + MATCHCOST(a,i,l); \
      } \
   }
#define FIRST_CELL_DP_REV(a,l) \
   /* assume INSERT_S1 */ \
   CELL_REV(a,l) = CELL_DOWN(a,l-1) + 1; \
   /* check match/mismatch if it's safe */ \
   if (CELL_DOWN(a,l) != -1) { \
      if (CELL_DOWN(a,l) + MATCHCOST_REV(a,i,l) <= CELL_REV(a,l)) { \
         CELL_REV(a,l) = CELL_DOWN(a,l) + MATCHCOST_REV(a,i,l); \
      } \
   }
#define LAST_CELL_DP(a,l) \
   CELL(a,l) = CELL_UP(a,l) + MATCHCOST(a,i,l); \
   /* use INSERT_S2 if it's better */ \
   if (CELL(a,l-1) + 1 < CELL(a,l)) { \
       CELL(a,l) = CELL(a,l-1) + 1; \
   }
#define LAST_CELL_DP_REV(a,l) \
   CELL_REV(a,l) = CELL_DOWN(a,l) + MATCHCOST_REV(a,i,l); \
   /* use INSERT_S2 if it's better */ \
   if (CELL_REV(a,l+1) + 1 < CELL_REV(a,l)) { \
       CELL_REV(a,l) = CELL_REV(a,l+1) + 1; \
   }
#define ROTATE_ROWS_FORWARD(a) \
   { \
     a->tmpRow = a->currRowFor; \
     a->currRowFor = a->prevRowFor; \
     a->prevRowFor = a->tmpRow; \
   }
#define ROTATE_ROWS_REVERSE(a) \
   { \
     a->tmpRow = a->currRowRev; \
     a->currRowRev = a->prevRowRev; \
     a->prevRowRev = a->tmpRow; \
   }

#define DUMP_ROWS_FORWARD(a,p) \
   fprintf(stderr, "%s(prev): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", CELL_UP(a, l)); \
   } \
   fprintf(stderr, "\n"); \
   fprintf(stderr, "%s(curr): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", CELL(a, l)); \
   } \
   fprintf(stderr, "\n"); \
   fprintf(stderr, "%s(trace): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", TRACE(a, l)); \
   } \
   fprintf(stderr, "\n\n");

#define DUMP_ROWS_REVERSE(a,p) \
   fprintf(stderr, "%s(curr): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", CELL_REV(a, l)); \
   } \
   fprintf(stderr, "\n"); \
   fprintf(stderr, "%s(prev): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", CELL_DOWN(a, l)); \
   } \
   fprintf(stderr, "\n"); \
   fprintf(stderr, "%s(tracerev): ", p); \
   for(l=0;l<=a->rowMax;l++) { \
     fprintf(stderr, "%d ", TRACE_REV(a, l)); \
   } \
   fprintf(stderr, "\n\n");


static int
solveMiddleRow(alignContext *a, int ulI, int ulJ, int lrI, int lrJ)
{
  int status = STAT_OK;
  int i, l;
  int initL, endL;
  int val;
  
  a->midRow = ulI + ((lrI - ulI + 1) / 2); /* integer math rounds for us. */

  /* calculate the scores in the cells at row *bestI */
  /* they are the sum of the forward pass and reverse pass */

  /*
   * forward pass
   */

  memset(a->currRowFor, -1, a->rowSize);
  memset(a->prevRowFor, -1, a->rowSize);
  memset(a->cumRow, -1, a->rowSize);

  /* The first row gets special handling */
  initL = ulJ - ulI + a->bound;	/* map i,j to i,l */
  assert(initL >= 0);		/* should never happen... */
  /*endL  = (lrJ - ulI + initL ) > a->rowMax ? a->rowMax : lrJ - ulI + initL; */
  endL  = (lrJ - ulJ + initL ) > a->rowMax ? a->rowMax : lrJ - ulJ + initL;
  val = 0;
  for(l=initL; l<=endL; l++) {	
    CELL(a,l) = val++;		/* fill the first row with insertS2's */
  }
  ROTATE_ROWS_FORWARD(a);

  /* now do the rest of the rows. */
  for(i=ulI+1; i<=a->midRow ;i++) {
    initL = (ulJ - i + a->bound) < 0 ? 0 : (ulJ - i + a->bound);
    endL  = (lrJ - ulJ + initL ); /* figure out where to end */
    if (endL > lrJ - i + a->bound) /* keep the end in the box */
      endL = lrJ -i + a->bound;
    if (endL > a->rowMax)	/* keep the end in bounds */
      endL = a->rowMax;
    FIRST_CELL_DP(a,initL);
    for(l=initL+1; l<=endL-1; l++) {
      NORMAL_CELL_DP(a,l);
    }
    if (endL == a->rowMax) {	/* decide if it's safe to look staight up */
      LAST_CELL_DP(a,endL);
    }
    else {
      NORMAL_CELL_DP(a,l);
    }
    ROTATE_ROWS_FORWARD(a);
  }
  
  initL = (ulJ - a->midRow + a->bound) < 0 ? 0 : (ulJ - a->midRow + a->bound);
  endL  = (lrJ - ulJ + initL ) > a->rowMax ? a->rowMax : lrJ - ulJ + initL;
  for(l=initL; l<=endL; l++)
    if (a->prevRowFor[l] >= 0) 
      a->cumRow[l] = a->prevRowFor[l];
  
  /*
   * reverse phase
   */

  memset(a->currRowRev, -1, a->rowSize);
  memset(a->prevRowRev, -1, a->rowSize);

  initL = lrJ - lrI + a->bound;	/* map i,j to i,l */
  assert(initL <= a->rowMax);	/* should never happen... */
  endL  = (initL - lrJ - ulJ) > 0 ? initL - lrJ - ulJ : 0;

  val = 0;
  for(l=initL; l>=endL; l--) {
    CELL_REV(a,l) = val++;
  }
  ROTATE_ROWS_REVERSE(a);

  for(i=lrI-1;i>=a->midRow;i--) {
    initL = (lrJ - i + a->bound) < a->rowMax ? lrJ - i + a->bound : a->rowMax;
    endL  = (initL - lrJ - ulJ) < 0 ? 0 : initL - lrJ - ulJ;
    FIRST_CELL_DP_REV(a,initL);
    for(l=initL-1;l>=endL+1;l--) {
      /*NORMAL_CELL_DP_REV(a,l); */
      /* assume match/mismatch */ 
      CELL_REV(a,l) = CELL_DOWN(a,l) + MATCHCOST_REV(a,i,l); 
      /* use INSERT_S1 if it's better */ 
      if (CELL_DOWN(a,l-1) + 1 < CELL_REV(a,l)) { 
	CELL_REV(a,l) = CELL_DOWN(a,l-1) + 1; 
      } 
      /* use INSERT_S2 if it's better still */ 
      if (CELL_REV(a,l+1) + 1 < CELL_REV(a,l)) { 
	CELL_REV(a,l) = CELL_REV(a,l+1) + 1; 
      }
    }
    /*LAST_CELL_DP_REV(a,endL); */
    CELL_REV(a,endL) = CELL_DOWN(a,endL) + MATCHCOST_REV(a,i,endL);
    /* use INSERT_S2 if it's better */
    if (CELL_REV(a,endL+1) + 1 < CELL_REV(a,endL)) {
      CELL_REV(a,endL) = CELL_REV(a,endL+1) + 1;
    }
    ROTATE_ROWS_REVERSE(a);
  }
    
  {
    int bestVal = INT_MAX;
    int bestCol;

    /* sum results and choose optimal column */
    initL = (ulJ - a->midRow + a->bound) < 0 ? 0:(ulJ - a->midRow + a->bound);
    endL  = (lrJ - ulJ + initL ) > a->rowMax ? a->rowMax : lrJ - ulJ + initL;
    for(l=initL; l<=endL; l++) {
      if (a->prevRowRev[l] >= 0) 
	a->cumRow[l] += a->prevRowRev[l];
      if (a->cumRow[l] >= 0) 
	if (a->cumRow[l] < bestVal) {
	  bestVal = a->cumRow[l];
	  bestCol = l;
	}
    }
    assert(bestCol >= 0);
    assert(bestCol <= a->rowMax);
    a->optCol[a->midRow] = a->midRow + bestCol - a->bound;
  }

  return(status);
}
  
#define ADD_OP_TO_LIST(op) \
   if (tail->type == op) \
      tail->count++; \
   else { \
      tail->next = (EditOp*)malloc(sizeof(EditOp)); \
      BailNull(tail->next, status); \
      tail = tail->next; \
      tail->type = op; \
      tail->count = 1; \
      tail->next = NULL; \
   }

static int
buildEditOpList(alignContext *a, EditOp **eList, int *cost)
{
  int status = STAT_OK;
  int curRow, prevCol, curCol;
  int i, j;			/* pos in s1, pos in s2 */
  EditOp *head = NULL;
  EditOp *tail = NULL;
  EditOp *tmpOp = NULL;
  
/*   { */
/*     int l; */
/*     for(l=0;l<=a->s1Len;l++) */
/*       printf("row: %d, optCol: %d\n", l, a->optCol[l]); */
/*   }   */

  head = (EditOp *)malloc(sizeof(EditOp)); /* set up a dummy to avoid test */
  BailNull(head, status);
  head->type = NOP;
  head->count = 0;
  head->next = NULL;
  tail = head;
  
  *cost = 0;
  prevCol = 0;
  i = 0;
  j = 0;
  for(curRow=1;curRow<=a->s1Len;curRow++) {
    curCol = a->optCol[curRow];

    if (curCol == prevCol) {	/* insert into S1 */
      ADD_OP_TO_LIST(INSERT_S1);
      (*cost)++;
    }
    else {
      if (curCol == prevCol + 1) { /* match or mismatch */
	if (a->s1[i] == a->s2[j]) {
	  ADD_OP_TO_LIST(MATCH);
	}
	else {
	  ADD_OP_TO_LIST(MISMATCH);
	  (*cost)++;
	}      
	j++;
      }
      else {
	/* scan forward for a place to put a match, the rest are insert*/
	while(j<curCol) {
	  if (a->s1[i] == a->s2[j]) {
	    ADD_OP_TO_LIST(MATCH);
	  }
	  else {
	    ADD_OP_TO_LIST(INSERT_S2);
	    (*cost)++;
	  }      
	  j++;
	}
      }
    }
    i++;
    prevCol = curCol;
  }

  tmpOp = head;			/* get rid of the dummy at the front */
  head = head->next;
  free(tmpOp);

  *eList = head;
  return(status);
 bail:
  if(head) {
    tmpOp = head;
    while (tmpOp) {
      head = tmpOp;
      tmpOp = head->next;
      free(head);
    }
  }
  *eList = NULL;
  return(status);
}

/*****************************************************************
 * A simple stack of coord. pairs, implemented as a list.
 * Better it later!
 */

typedef struct _IJlist {
  int ulI;
  int ulJ;
  int lrI;
  int lrJ;
  struct _IJlist *next;
} IJelement;

static IJelement *head = NULL;

static void
runIJ() {
  IJelement *el;
  int i;

  el = head;
  i = 1;
  while(el) {
    fprintf(stderr,
	    "poodle %*c el: %u --- (%d,%d), (%d, %d)\n",
	    i++, ' ',el, el->ulI, el->ulJ, el->lrI, el->lrJ);
    el = el->next;
  }
}

static int
pushIJ(int ulI, int ulJ, int lrI, int lrJ) {
  int status = STAT_OK;
  IJelement *el;
  
  el = (IJelement *)malloc(sizeof(IJelement));
  BailNull(el, status);
  memset(el, -1, sizeof(IJelement));

  el->ulI = ulI;
  el->ulJ = ulJ;
  el->lrI = lrI;
  el->lrJ = lrJ;
  el->next = head;
  head = el;

 bail:
  return(status);
}

static int
popIJ(int *ulI, int *ulJ, int *lrI, int *lrJ) {
  int status = STAT_OK;
  IJelement *el;
      
  BailNull(head, status);
  el = head;
  head = el->next;

  *ulI = el->ulI;
  *ulJ = el->ulJ;
  *lrI = el->lrI;
  *lrJ = el->lrJ;

  if (el) free(el);
 bail:
  return(status);
}

static int
emptyIJ() {
  if (head == NULL) {
    return(1);
  }
  else {
    return(0);
  }
}

