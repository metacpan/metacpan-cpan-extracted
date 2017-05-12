
typedef struct _aligncontext {
  char *s1;
  char *s2;
  int s1Len;
  int s2Len;
  int bound;
  int rowMax;
  int rowCount;
  int rowSize;
  int midRow;
  int *rowMem;			/* this gets allocated */
  int *currRowFor;		/* these just get carved out of rowMem */
  int *prevRowFor;
  int *currRowRev;
  int *prevRowRev;
  int *cumRow;
  int *tmpRow;
  int *optCol;			/* the number of INSERT_S2's in this row */
} alignContext;

alignContext *newAlignContext();
alignContext *setupAlignContext(char *str1, char *str2, int bound);
void freeAlignContext(alignContext *a);
