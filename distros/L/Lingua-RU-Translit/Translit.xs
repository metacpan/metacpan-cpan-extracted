#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include "tables.h"

int Rcmp(const void *, const void *);

typedef struct {
  double p;
  uchar *str;
  int prev;
  int skip;
  int pos;
} Rslot;

SV* decode(SV *string)
{
  uchar *from;
  int i, j, nrus, rslots, flen;
  uchar Rstrstr[NSLOTS*1024];
  Rslot R[NSLOTS], E, *result=&E;
  SV *to;

  if (! SvOK(string))
    return(&PL_sv_undef);

  from=SvPV(string, flen);
  /* !!! WARNING !!!
     arbitrary limit here. I'm too lazy to remove it right now,
     may be later...
  */
  if (flen>1023) flen=1023;

  for (i=0; i<NSLOTS; i++)
    R[i].str=Rstrstr+i*1024;

  nrus=rslots=1;
  R[0].p=E.p=1;
  R[0].prev=E.prev=0;
  R[0].skip=1;
  R[0].pos=0;
  E.str=from;
  E.pos=flen;

  for (i=0; i<flen; i++, from++)
  {
    int cur;

    if (*from >127) goto done;
    cur=ord[*from];
    E.p*=Etrans[E.prev][cur];
    E.prev=cur;
    for (j=0; j<nrus; j++)
    {
      uchar **trs, *s;

      if (--R[j].skip)
        continue;

      for (trs=E2R[E.prev]; s=*trs; trs++)
      {
        int x, slot;
        for (x=1;s[x] && from[x] && ord[from[x]]==ord[s[x]];x++);
        if (s[x])
          continue;

        if (trs[1])
          memcpy(R[slot=rslots++].str, R[j].str, i);
        else
          slot=j;

        cur=ord[*s];
        R[slot].str[R[j].pos]= (cur ? (*from>'Z' ? *s-32 : *s) : *from);
        R[slot].pos=R[j].pos+1;
        R[slot].p=R[j].p*Rtrans[R[j].prev][cur];
        R[slot].prev=cur;
        R[slot].skip=x;
      }
    }
    if (rslots > CLEANUP_THRESHOLD)
    {
      qsort(R, rslots, sizeof(Rslot), Rcmp);
      rslots=CLEANUP_THRESHOLD;
    }
    nrus=rslots;
  }
  qsort(R, rslots, sizeof(Rslot), Rcmp);

  if (R[0].p > 0 && R[0].p > E.p)
    result=R;
done:
  to = newSVpv(result->str, result->pos);
}

// sort with decreasing probability
int Rcmp(const void *a, const void *b)
{
  return ((Rslot*)a)->p < ((Rslot*)b)->p ?  1 :
         ((Rslot*)a)->p > ((Rslot*)b)->p ? -1 : 0;
}

MODULE = Lingua::RU::Translit		PACKAGE = Lingua::RU::Translit		

SV*
translit2koi(input)
        SV *input
        CODE:
        RETVAL=decode(input);
        OUTPUT:
        RETVAL

