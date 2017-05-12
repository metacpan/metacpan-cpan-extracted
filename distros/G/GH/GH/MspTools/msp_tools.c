#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <stdio.h>
#include "Msp/msp.h"
#include "MspTools/msp_tools.h"
#include "Status/status.h"

typedef struct _hashNode {
  int ecode;			/* encoding of word */
  int pos;			/* a position where this word occurs. */
  struct _hashNode *link;	/* pointer to next position w/ same hashval */
} hashNode;

typedef struct {
  hashNode **table;
  int tableSize;
  int wordSize;
  int mask;
#define ALPHABETSIZE 256
  int encodings[ALPHABETSIZE];
  int *nextPos;
  int nextPosSize;
} hashTable;

typedef struct {
  hashTable *hash;		/* used all over the place */
  int *allocated;		/* used for diag_lev */
  int *diag_lev;		/* shared btwn findMSPs and extend_hit */
  MSP *msp_list;		/* shared btwn findMSPs and extend_hit */
  /*  MSP **msp;			/* used by findMSPs */
  int numMSPs;			/* used by findMSPs */
  
  int tableSize;
  int wordSize;
  int K;
  int X;
  int match;
  int mismatch;
} mspSearchContext;

static int initTable(mspSearchContext *mspc);
static int fillTable(mspSearchContext *mspc, char *s, int sLen);
static int resetTable(mspSearchContext *mspc);
static int freeTable(mspSearchContext *mspc);
static int findMSPs(mspSearchContext *mspc, char *s1, int s1Len, char *s2, int s2Len);
static int dumpMSPs(mspSearchContext *mspc);
static int dumpMSPsVerbose(mspSearchContext *mspc,
			   char *s1, char *s2);
static int dumpBestPath(MSP *msp, int count);
static int add_word(hashTable *hash, int ecode, int pos);
static int extend_hit(mspSearchContext *mspc,
		      int pos1, int pos2, char *s1, char *s2,
		      int len1, int len2, int W);


int initMSPC(mspSearchContext **mspc, mspConfig *config)
{
  int status = STAT_OK;
  mspSearchContext *tmp;

  tmp = (mspSearchContext *)malloc(sizeof(mspSearchContext));
  BailNull(tmp, status);

  tmp->tableSize = config->tableSize;
  tmp->wordSize = config->wordSize;
  tmp->K = config->mspThresh;
  tmp->X = config->extensionThresh;
  tmp->match = config->matchScore;
  tmp->mismatch = config->mismatchScore;
  tmp->msp_list = NULL;
  tmp->numMSPs = 0;

  *mspc = tmp;
  return(status);
 bail:
  if(mspc)
    free(mspc);
  return(status);
}



int
getMSPs(char *s1, char *s2, mspConfig *config, MSP **msp, int *numMSPs)
{
  int status = 0;
  mspSearchContext *mspc;

  status = initMSPC(&mspc, config);
  BailError(status);
  status = initTable(mspc);
  BailError(status);
  status = fillTable(mspc, s1, strlen(s1));
  BailError(status);
  status = findMSPs(mspc, s1, strlen(s1), s2, strlen(s2));

  *numMSPs = mspc->numMSPs;
  *msp = mspc->msp_list;

  /* FREE EVERYTHING EXCEPT THE MSP JUST ALLOCATED OR LEAK!!! */
  /* Each of the msp's in the list started by *mspc->msp
   * will be freed by the caller (e.g. the perl routines
   * that destroy the GH::Msp object...
   */
  status = freeTable(mspc);
  BailError(status);
  free(mspc);

  return(status);
 bail:
  return(status);
}

int
getMSPsBulk(char *s1,
	    int seqCount, char **seqs,
	    mspConfig *config,
	    MSP ***msps)
{
  int status = STAT_OK;
  mspSearchContext *mspc;
  int i;
  int strLen1;
  MSP **msp_list;

  msp_list = (MSP **) malloc(seqCount * sizeof(MSP *));
  BailNull(msp_list, status);

  status = initMSPC(&mspc, config);
  status = initTable(mspc);
  status = fillTable(mspc, s1, strlen(s1));

  strLen1 = strlen(s1);

  for(i=0; i<seqCount; i++) {
    status = findMSPs(mspc, s1, strLen1, seqs[i], strlen(seqs[i]));
    
    msp_list[i] = mspc->msp_list; /* here's the head of the list. */
    mspc->msp_list = NULL;	/* keep resetTable from freeing msp's... */
   
    status = resetTable(mspc);	/* free memory used to search for msps */
  }

  *msps = msp_list;
  status = freeTable(mspc);
  free(mspc);

  return(status);
 bail:
  if (*msps) {
    MSP *tmp1, *tmp2;
    
    for(i=0; i<seqCount;i++) {
      tmp1 = *msps[i];	
      while (tmp1 != NULL) {
	tmp2 = tmp1->next_msp;
	free(tmp1);
	tmp1 = tmp2;
      }
      free(*msps);
    }
  }
  return(status);
}


static int
initTable(mspSearchContext *mspc)
{
  int status = STAT_OK;
  int tableSize;
  int wordSize;
  hashTable *tmp;
  int i;
  
  tmp = (hashTable *)malloc(sizeof(hashTable));
  if (! tmp) {
    status = STAT_NO_MEM;
    goto bail;
  }

  tableSize = mspc->tableSize;
  wordSize = mspc->wordSize;

  /* bump the table size by 1 so that when we access the table
   * with a mode tableSize, we won't write off it's end...
   */
  tmp->table = (hashNode **)malloc(sizeof(hashNode *) * (tableSize+1));
  if (!tmp->table) {
    status = STAT_NO_MEM;
    goto bail;
  }
  memset(tmp->table, 0, sizeof(hashNode *) * (tableSize+1));

  tmp->tableSize = tableSize;
  tmp->wordSize = wordSize;
  tmp->mask = (1 << (wordSize + wordSize - 2)) - 1;
  for(i=0; i < ALPHABETSIZE; i++) {
    tmp->encodings[i] = -1;
  }
  tmp->encodings['A'] = tmp->encodings['a'] = 0;
  tmp->encodings['C'] = tmp->encodings['c'] = 1;
  tmp->encodings['G'] = tmp->encodings['g'] = 2;
  tmp->encodings['T'] = tmp->encodings['t'] = 3;

  mspc->hash = tmp;
  return(status);

 bail:
  if (tmp) {
    if (tmp->table) {
      free(tmp->table);
    }
    free(tmp);
  }
  return(status);
}

static int
resetTable(mspSearchContext *mspc)
{
  int status = STAT_OK;
  MSP *tmp1;
  MSP *tmp2;
  
  if (mspc->allocated) {
    free(mspc->allocated);
    mspc->allocated = NULL;
  }
  tmp1 = mspc->msp_list;
  while(tmp1) {
    tmp2 = tmp1->next_msp;
    free(tmp1);
    tmp1 = tmp2;
  }
  mspc->msp_list = (MSP *) 0;
  mspc->numMSPs = 0;  

  return(status);
}

static int
freeTable(mspSearchContext *mspc)
{
  int status = STAT_OK;
  hashNode *h, *tmp_h;
  int i;
  
  if (mspc->allocated) {
    free(mspc->allocated);
    mspc->allocated = NULL;
  }
  /* free the buckets in the hash table. */
  for(i=0; i <= mspc->hash->tableSize; i++) { /* handle alloc of tableSize+1 */
    h = mspc->hash->table[i];
    while (h) {
      tmp_h = h->link;
      free(h);
      h = tmp_h;
    }
  }
  free(mspc->hash->table);
  free(mspc->hash->nextPos);
  free(mspc->hash);

  return(status);
}


static int
dumpHashTable(hashTable *hash) {
  int i;
  hashNode *h;
  int pos;

  for(i=0; i < hash->tableSize; i++) {
    h = hash->table[i];
    while(h) {
      printf("i: %d, addr: %d, pos: %d, ecode: %d, hval: %d, link: %d\n",
	     i, (long) h, h->pos, h->ecode, h->ecode & hash->tableSize,
	     (long) h->link);
      pos = hash->nextPos[h->pos];
      while (pos >= 0) {
	printf("    and also at pos: %d\n", pos);
	pos = hash->nextPos[pos];
      }
      h = h->link;
    }
  }
  return(STAT_OK);
}

static int
dumpNextPos(hashTable *hash)
{
  int i;
  for(i=0; i < hash->nextPosSize; i++) {
    if (hash->nextPos[i] >= 0)
      printf("hashpos[%d]: %d\n", i, hash->nextPos[i]);
  }
  return(STAT_OK);
}

static int
fillTable(mspSearchContext *mspc, char *s, int sLen)
{
  int status = STAT_OK;
  hashTable *hash;
  int i, j;
  char *t;
  int ecode;
  int tmp;

  hash = mspc->hash;
  hash->nextPosSize = sLen;
  hash->nextPos = (int *)malloc(sLen * sizeof(int));
  BailNull(hash->nextPos, status);

  memset(hash->nextPos, -1, (sLen * sizeof(int)));

  t = s;
  for (i=0; (i < sLen) && *t; ) {
  restart: 
    ecode = 0L;
    for (j = 0; (j < hash->wordSize - 1) && (i < sLen) && *t; j++) {
      tmp = hash->encodings[(int) *t];
      i++; t++;			/* inc these here in case of goto... */
      if (tmp < 0)
	goto restart;
      ecode = (ecode << 2) + tmp;
    }
 
    for (; (i < sLen) && *t;) {
      tmp = hash->encodings[(int) *t];
      i++, t++;			/* inc these here in case of goto... */
      if (tmp < 0)
	goto restart;
      ecode = ((ecode & hash->mask) << 2) + tmp;
      status = add_word(hash, ecode, i-1); /* -1 for the i++ above... */
      if (status != STAT_OK) 
	goto bail;
    }       
  }
  
  return(status);
 bail:
  if (hash->nextPos) {
    free(hash->nextPos);
  }
  return(status);
}


/* add_word - add a word to the table of critical words */
static int
add_word(hashTable *hash, int ecode, int pos)
{
  int status = STAT_OK;
  hashNode *h;
  int hval;

  hval = ecode & hash->tableSize;
  for (h = hash->table[hval]; h; h = h->link)
    if (h->ecode == ecode)
      break;

  if (!h) {
    h = (hashNode *) malloc (sizeof(hashNode));
    BailNull(h, status);
    h->link = hash->table[hval];
    hash->table[hval] = h;
    h->ecode = ecode;
    h->pos = -1;
  }
  hash->nextPos[pos] = h->pos;
  h->pos = pos;
  return(status);
bail:
  return(status);
}

static int
findMSPs(mspSearchContext *mspc, char *s1, int s1Len, char *s2, int s2Len)
{
  int status = STAT_OK;
  hashTable *hash;
  hashNode *h;
  char *t;
  int ecode, hval;
  int i, j, p;
  int tmp;

  hash = mspc->hash;
  mspc->allocated = (int *)malloc((s1Len+s2Len+1)*sizeof(int));
  BailNull(mspc->allocated, status);
  memset(mspc->allocated, 0, (s1Len+s2Len+1)*sizeof(int));
  mspc->diag_lev = mspc->allocated + s1Len;	/* point into the middle of the array. */

  t = s2;
  for (i=0; (i < s2Len) && *t; ) {
  restart:
    ecode = 0;
    for (j = 0; (j < hash->wordSize - 1) && (i < s2Len) && *t; j++) {
      tmp = hash->encodings[(int) *t];
      i++; t++;
      if (tmp < 0)
	goto restart;
      ecode = (ecode << 2) + tmp;
    }
    for (; (i < s2Len) && *t; ) {
      tmp = hash->encodings[(int) *t];
      i++; t++;
      if (tmp < 0)
	goto restart;
      ecode = ((ecode & hash->mask) << 2) + tmp;
      hval = ecode & hash->tableSize;
      for (h = hash->table[hval]; h; h = h->link)
	if (h->ecode == ecode) {
	  for (p = h->pos; p >= 0; p = hash->nextPos[p]) {
	    (void) extend_hit(mspc, p,(int)(t-s2-1),s1,s2,s1Len,s2Len,hash->wordSize);
	  }
	  break;
	}
    }
  }     

  return(status);
 bail:
  return(status);
}

/* extend_hit - extend a word-sized hit to a longer match */
static int
extend_hit(mspSearchContext *mspc, int pos1, int pos2, char *s1, char *s2,
	   int len1, int len2, int wordSize)
{
  int status = STAT_OK;
  const char *beg2, *beg1, *end1, *end2, *q, *s;
  int right_sum, left_sum, sum, diag, score;


  diag = pos2 - pos1;
  if (mspc->diag_lev[diag] > pos1) 
    return(STAT_OK);

  /* extend to the right */
  left_sum = sum = 0;
  q = s1+1+pos1;
  s = s2+1+pos2;
  end1 = q;
  end2 = s;
  while ((*s != '\0') && (*q != '\0') &&
	 (s<=s2+len2) && (q<=s1+len1) && sum >= left_sum - mspc->X) {
    sum += ((*s++ == *q++) ? mspc->match : mspc->mismatch);
    if (sum > left_sum) {
      left_sum = sum;
      end1 = q;
      end2 = s;
    }
  }

  /* extend to the left */
  right_sum = sum = 0;
  beg1 = q = (s1+pos1) - wordSize;/* char before the start of the match... */
  beg2 = s = (s2+pos2) - wordSize;
  while ((q>=s1) && (s>=s2) && sum >= right_sum - mspc->X) {
    sum += ((*(s) == *(q)) ? mspc->match : mspc->mismatch);
    q--;
    s--;
    if (sum > right_sum) {
      right_sum = sum;
      beg1 = q;
      beg2 = s;
    }
  }

  score = wordSize + left_sum + right_sum;
  if (score >= mspc->K) {
    MSP *mp = (MSP *)malloc(sizeof(MSP));
    if (!mp) {
      status = STAT_NO_MEM;
      goto bail;
    }

    mp->len = end1 - beg1 - 1;
    mp->score = score;
    mp->pos1 = (beg1 + 1) - s1;
    mp->pos2 = (beg2 + 1) - s2;
    mp->next_msp = mspc->msp_list;
    mspc->msp_list = mp;
    mspc->numMSPs++;
  }

  mspc->diag_lev[diag] = (end1 - s1) - 1 + wordSize;

 bail:
  return(status);
}

/*int 
//w_overlap(MSP *m1, MSP *m2, int maxCost)
//{
//  int gap1;                                  
//  int gap2;                                        
//  int cost = 0;
//  
//  gap1 = m2->pos1 - (m1->pos1 + m1->len - 1) - 1;  
//  gap2 = m2->pos2 - (m1->pos2 + m1->len - 1) - 1;  
//  
//  if (abs(gap1) > 30) {
//    cost = maxCost;
//  }
//  else {
//    if (abs(gap2) > 30) {
//      cost = maxCost;
//    }
//    else {
//      cost = abs(gap1) + abs(gap2);
//    }
//  }
//  return(cost);
//}
*/

/* for qsort below. */
int
compareMSPs(const void *a, const void *b)
{
  int retval;
  MSP *m1 = *(MSP **) a;
  MSP *m2 = *(MSP **) b;

  if (m1->pos2 < m2->pos2) {
    retval = -1;
  }
  else {
    if (m1->pos2 == m2->pos2) {
      retval = 0;
    }
    else {
      retval = 1;
    }
  }

  return(retval);
}

/* for qsort below. */
int
compareByS1Start(const void *a, const void *b)
{
  int retval;
  MSP *m1 = *(MSP **) a;
  MSP *m2 = *(MSP **) b;

  if (m1->pos1 < m2->pos1) {
    retval = -1;
  }
  else {
    if (m1->pos1 == m2->pos1) {
      retval = 0;
    }
    else {
      retval = 1;
    }
  }

  return(retval);
}

/* for qsort below. */
int
compareByS1End(const void *a, const void *b)
{
  int retval;
  MSP *m1 = *(MSP **) a;
  MSP *m2 = *(MSP **) b;

  if (m1->pos1 + m1->len < m2->pos1 + m2->len) {
    retval = -1;
  }
  else {
    if (m1->pos1 +m1->len == m2->pos1 + m2->len) {
      retval = 0;
    }
    else {
      retval = 1;
    }
  }

  return(retval);
}


int
findBestOverlapPath(char *s1, char *s2, MSP *msp, int numMSPs, mspConfig *c,
		    MSP **bestPath, int *numInPath, int *bestCost)
{
  int status = STAT_OK;
  MSP **msps;
  MSP *tmpMsp;
  int *l = NULL;		/* array of path lenths */
  int *prev = NULL;		/* keep track of prev. in best path at node */
  int i, j;			/* loop counters over array of MSPs */
  int s1Len;
  int s2Len;
  int maxCost;
  int bestIndex;
  int w;

  BailNull(msp, status);

  msps = (MSP **) malloc(sizeof(MSP *) * numMSPs);
  BailNull(msps, status);
  /* copy msps pointers into an array to avoid {heart,head}ache. */
  i = 0;
  tmpMsp = msp;
  while (tmpMsp != NULL) {
    msps[i] = tmpMsp;
    i++;
    tmpMsp = tmpMsp->next_msp;
  }
  qsort(msps, numMSPs, sizeof(MSP *), compareMSPs);

  l = (int *) malloc(sizeof(int) * numMSPs);
  BailNull(l, status);  
  prev = (int *) malloc(sizeof(int) *numMSPs);
  BailNull(prev, status);

  s1Len = strlen(s1);
  s2Len = strlen(s2);
  maxCost = s1Len + s2Len + 1;

  for(j=0; j<numMSPs; j++) {
    l[j] = msps[j]->pos2 - 0;
    prev[j] = -1;
    for(i=0; i<j; i++) {
      /* w = w_overlap(msps[i], msps[j], maxCost); */
      {
	int gap1;                                  
	int gap2;                                        
	
	gap1 = msps[j]->pos1 - (msps[i]->pos1 + msps[i]->len - 1) - 1;  
	gap2 = msps[j]->pos2 - (msps[i]->pos2 + msps[i]->len - 1) - 1;  
	
	if (abs(gap1) > c->ovFudge) {
	  w = maxCost;
	}
	else {
	  if (abs(gap2) > c->ovFudge) {
	    w = maxCost;
	  }
	  else {
	    w = abs(gap1) + abs(gap2);
	  }
	}
      }
      if (l[j] >= l[i] + w) {
	l[j] = l[i] + w;
	prev[j] = i;
      }
    }
  }

  bestIndex = 0;
  for(i=0; i<numMSPs; i++) {
    l[i] += s1Len - (msps[i]->pos1 + msps[i]->len - 1) - 1;
    if (l[i] < l[bestIndex]) 
      bestIndex = i;
  }
    
  i = bestIndex;
  *bestCost = l[bestIndex];

  j = 1;
  tmpMsp = (MSP *) malloc(sizeof(MSP));
  BailNull(tmpMsp, status);
  copyMSP(msps[i], tmpMsp);
  tmpMsp->next_msp = NULL;
  *bestPath = tmpMsp;

  while(prev[i] != -1) {
    i = prev[i];

    tmpMsp->next_msp = (MSP *) malloc(sizeof(MSP));
    BailNull(tmpMsp->next_msp, status);
    tmpMsp = tmpMsp->next_msp;
    copyMSP(msps[i], tmpMsp);

    tmpMsp->next_msp = NULL;	/* paranoia, copyMSP grabs the old next... */
    j++;
  }

  *numInPath = j;

 bail:
  if(msps)
    free(msps);
  if(l)
    free(l);
  if(prev)
    free(prev);
  return(status);
}

int
findBestInclusionPath(char *s1, char *s2, MSP *msp, int numMSPs, mspConfig *c,
		      MSP **bestPath, int *numInPath, int *bestCost)
{
  int status = STAT_OK;
  MSP **msps = NULL;
  MSP *tmpMsp = NULL;
  int *l = NULL;		/* array of path lenths */
  int *prev = NULL;		/* keep track of prev. in best path at node */
  int i, j;			/* loop counters over array of MSPs */
  int s1Len;
  int s2Len;
  int maxCost;
  int bestIndex;
  int w;

  if (numMSPs > 3000) {
    status = STAT_BAD_ARGS;
    goto bail;
  }

  /* copy msps pointers into an array to avoid {heart,head}ache. */
  msps = (MSP **) malloc(sizeof(MSP *) * numMSPs);
  BailNull(msps, status);
  i = 0;
  tmpMsp = msp;
  while (tmpMsp != NULL) {
    msps[i] = tmpMsp;
    i++;
    tmpMsp = tmpMsp->next_msp;
  }
  qsort(msps, numMSPs, sizeof(MSP *), compareMSPs);

  l = (int *) malloc(sizeof(int) * numMSPs);
  BailNull(l, status);  
  prev = (int *) malloc(sizeof(int) *numMSPs);
  BailNull(prev, status);

  s1Len = strlen(s1);
  s2Len = strlen(s2);
  maxCost = s1Len + s2Len + 1;

  for(j=0; j<numMSPs; j++) {
    l[j] = msps[j]->pos2 - 0;
    prev[j] = -1;
    for(i=0; i<j; i++) {
      /* w = w_overlap(msps[i], msps[j], maxCost); */
      {
	int gap1;                                  
	int gap2;                                        
	
	gap1 = msps[j]->pos1 - (msps[i]->pos1 + msps[i]->len - 1) - 1;  
	gap2 = msps[j]->pos2 - (msps[i]->pos2 + msps[i]->len - 1) - 1;  
	
	if (abs(gap1) > c->ovFudge) {
	  w = maxCost;
	}
	else {
	  if (abs(gap2) > c->ovFudge) {
	    w = maxCost;
	  }
	  else {
	    w = abs(gap1) + abs(gap2);
	  }
	}
      }
      if (l[j] >= l[i] + w) {
	l[j] = l[i] + w;
	prev[j] = i;
      }
    }
  }

  bestIndex = 0;
  for(i=0; i<numMSPs; i++) {
    l[i] += s2Len - (msps[i]->pos2 + msps[i]->len - 1) - 1;
    if (l[i] < l[bestIndex]) 
      bestIndex = i;
  }
    
  i = bestIndex;
  *bestCost = l[bestIndex];

  j = 1;
  tmpMsp = (MSP *) malloc(sizeof(MSP));
  BailNull(tmpMsp, status);
  copyMSP(msps[i], tmpMsp);
  tmpMsp->next_msp = NULL;
  *bestPath = tmpMsp;

  while(prev[i] != -1) {
    i = prev[i];

    tmpMsp->next_msp = (MSP *) malloc(sizeof(MSP));
    BailNull(tmpMsp->next_msp, status);
    tmpMsp = tmpMsp->next_msp;
    copyMSP(msps[i], tmpMsp);

    tmpMsp->next_msp = NULL;	/* paranoia, copyMSP grabs the old next... */
    j++;
  }

  *numInPath = j;

 bail:
  if(msps)
    free(msps);
  if(l)
    free(l);
  if(prev)
    free(prev);
  return(status);
}

int
tmpPlace(char *s1, char *s2, MSP *msp, int numMSPs, mspConfig *c,
	 MSP **bestPath, int *numInPath, int *bestCost)
{
  int status = STAT_OK;
  MSP **msps = NULL;
  MSP *tmpMsp = NULL;
  int *l = NULL;		/* array of path lenths */
  int *prev = NULL;		/* keep track of prev. in best path at node */
  int i, j;			/* loop counters over array of MSPs */
  int s1Len;
  int s2Len;
  int maxCost;
  int bestIndex;
  int w;

  if (numMSPs > 3000) {
    status = STAT_BAD_ARGS;
    goto bail;
  }

  /* copy msps pointers into an array to avoid {heart,head}ache. */
  msps = (MSP **) malloc(sizeof(MSP *) * numMSPs);
  BailNull(msps, status);
  i = 0;
  tmpMsp = msp;
  while (tmpMsp != NULL) {
    msps[i] = tmpMsp;
    i++;
    tmpMsp = tmpMsp->next_msp;
  }
  qsort(msps, numMSPs, sizeof(MSP *), compareByS1Start);

  l = (int *) malloc(sizeof(int) * numMSPs);
  BailNull(l, status);  
  prev = (int *) malloc(sizeof(int) *numMSPs);
  BailNull(prev, status);

  s1Len = strlen(s1);
  s2Len = strlen(s2);
  maxCost = s1Len + s2Len + 1;

  for(j=0; j<numMSPs; j++) {
    l[j] = msps[j]->pos1 == 0 ? 0 : INT_MAX;
    prev[j] = -1;
    for(i=0; i<j; i++) {
      {
	int gap1;                                  
	int gap2;                                        
	
	gap1 = msps[j]->pos1 - (msps[i]->pos1 + msps[i]->len - 1) - 1;  
	gap2 = msps[j]->pos2 - (msps[i]->pos2 + msps[i]->len - 1) - 1;  
	
	w = abs(gap1) + abs(gap2);
      }
      if (l[j] >= l[i] + w) {
	l[j] = l[i] + w;
	prev[j] = i;
      }
    }
  }
  
  bestIndex = 0;
  for(i=0; i<numMSPs; i++) {
    l[i] += s2Len - (msps[i]->pos2 + msps[i]->len - 1) - 1;
    if (l[i] < l[bestIndex]) 
      bestIndex = i;
  }
    
  i = bestIndex;
  *bestCost = l[bestIndex];

  j = 1;
  tmpMsp = (MSP *) malloc(sizeof(MSP));
  BailNull(tmpMsp, status);
  copyMSP(msps[i], tmpMsp);
  tmpMsp->next_msp = NULL;
  *bestPath = tmpMsp;

  while(prev[i] != -1) {
    i = prev[i];

    tmpMsp->next_msp = (MSP *) malloc(sizeof(MSP));
    BailNull(tmpMsp->next_msp, status);
    tmpMsp = tmpMsp->next_msp;
    copyMSP(msps[i], tmpMsp);

    tmpMsp->next_msp = NULL;	/* paranoia, copyMSP grabs the old next... */
    j++;
  }

  *numInPath = j;

 bail:
  if(msps)
    free(msps);
  if(l)
    free(l);
  if(prev)
    free(prev);
  return(status);
}

int findInclusionsBulk(char *s1,
		       int count, char **names, char **seqs,
		       mspConfig *config,
		       MSP ***paths,
		       int **costs)
{
  int status = STAT_OK;
  mspSearchContext *mspc;
  int i;
  int strLen1;
  int numMSPs = 0;
  MSP *msp;
  MSP *bestPath;
  int bestNum;
  int bestCost;

  *paths = (MSP **) malloc(count * sizeof(MSP *));
  BailNull(*paths, status);

  *costs = (int *) malloc(count * sizeof(int));
  BailNull(*costs, status);

  status = initMSPC(&mspc, config);
  status = initTable(mspc);
  status = fillTable(mspc, s1, strlen(s1));

  strLen1 = strlen(s1);

  for(i=0; i<count; i++) {
    status = findMSPs(mspc, s1, strLen1, seqs[i], strlen(seqs[i]));

    numMSPs = mspc->numMSPs;	/* there are this many msps */
    msp = mspc->msp_list;	/* here's the head of the list. */
   
    (*paths)[i] = NULL;
    if (numMSPs > 0) {
      status = findBestInclusionPath(s1, seqs[i], msp, numMSPs, config,
				     &bestPath, &bestNum, &bestCost);
      if (status == STAT_OK) {
	(*paths)[i] = bestPath;
	(*costs)[i] = bestCost;
      }
    }
    status = resetTable(mspc);	/* free memory used to search for msps */
  }

  status = freeTable(mspc);
  free(mspc);

  return(status);
 bail:
  if (*paths) {
    free(*paths);
    *paths = NULL;
  }
  if (*costs) {
    free(*costs);
    *costs = NULL;
  }
  return(status);
}

int dumpBestPath(MSP *msp, int count)
{
  int status = STAT_OK;
  MSP *m;
  int i, j;

  i = 0;
  j = 0;
  m = msp;
  while (m) {
    for(j=0; j<i; j++) printf(" ");
    printf("%d: (%d) %d--%d\n", i, m->len, m->pos1, m->pos2);
    m = m->next_msp;
    i++;
  }
  printf("\n");
  return(status);
}

int dumpMSPs(mspSearchContext *mspc)
{
  int status = STAT_OK;
  MSP *tmp;
  int i = 0;

  printf("num: %d\n", mspc->numMSPs);
  tmp = mspc->msp_list;
  while(tmp) {
    (void)printf("%5d: pos1: %7d pos2: %7d len: %d\n",
		 i++,
		 tmp->pos1,
		 tmp->pos2,
		 tmp->len);
    tmp = tmp->next_msp;
  }
  return(status);
}

int dumpMSPsVerbose(mspSearchContext *mspc,
	     char *s1,
	     char *s2)
{
  int status = STAT_OK;
  MSP *tmp;
  int i = 0;

  printf("num: %d\n", mspc->numMSPs);
  tmp = mspc->msp_list;
  while(tmp) {
    (void)printf("%5d: pos1: %7d pos2: %7d len: %d seq: %.15s --- %.15s\n",
		 i++,
		 tmp->pos1,
		 tmp->pos2,
		 tmp->len,
		 s1+tmp->pos1,
		 s2+tmp->pos2
		 );
    tmp = tmp->next_msp;
  }
  return(status);
}

