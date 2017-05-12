#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "Status/status.h"
#include "align_context.h"



/***********************************************************************
 * Context for the ongoing the alignment.  Avoids globals...
 */

/* Allocate the alignment context structs */
alignContext *
newAlignContext()
{
  return((alignContext *)malloc(sizeof(alignContext)));
}

void
freeAlignContext(alignContext *a)
{
  if (a->currRowFor) free(a->currRowFor);
  if (a->prevRowFor) free(a->prevRowFor);
  if (a->currRowRev) free(a->currRowRev);
  if (a->prevRowRev) free(a->prevRowRev);
  if (a->cumRow) free(a->cumRow);
  if (a->optCol) free(a->optCol);

  if (a) free(a);
}

alignContext *
setupAlignContext(char *str1, char *str2, int bound)
{
  int status = STAT_OK;
  alignContext *a = NULL;
  
  a = newAlignContext();
  BailNull(a, status);

  a->s1 = str1;
  a->s1Len = strlen(str1);
  a->s2 = str2;
  a->s2Len = strlen(str2);
  a->bound = bound;
  a->rowMax = 2*bound;
  a->rowCount = a->rowMax + 1;
  a->rowSize = a->rowCount * sizeof(int);

  a->currRowFor = (int *)malloc(a->rowSize);
  BailNull(a->currRowFor, status);
  a->prevRowFor = (int *)malloc(a->rowSize);
  BailNull(a->prevRowFor, status);
  a->currRowRev = (int *)malloc(a->rowSize);
  BailNull(a->currRowRev, status);
  a->prevRowRev = (int *)malloc(a->rowSize);
  BailNull(a->prevRowRev, status);
  a->cumRow = (int *)malloc(a->rowSize);
  BailNull(a->cumRow, status);

  a->optCol = (int *)malloc((a->s1Len+1) * sizeof(int));
  BailNull(a->optCol, status);
  memset(a->optCol, -1, (a->s1Len+1) * sizeof(int));
  a->optCol[0] = 0;
  a->optCol[a->s1Len] = a->s2Len;

  return(a);
 bail:
  if (a) freeAlignContext(a);
  return(NULL);
}
