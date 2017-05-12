#include <stdio.h>
#include <stdlib.h>
#include "glog.h"
#include "gmem.h"
#include "plist.h"

static void plist_grow(PList* plist);

PList* plist_create(void) {
  PList* p = 0;
  GMEM_NEW(p, PList*, sizeof(PList));
  if (!p) {
    return 0;
  }

  plist_init(p);
  return p;
}

void plist_destroy(PList* plist) {
  if (!plist) {
    return;
  }

  plist_clear(plist);
  GMEM_DEL(plist, PList*, sizeof(PList));
}

PList* plist_clone(PList* plist) {
  if (!plist) {
    return 0;
  }

  PList* p = plist_create();
  int j;
  for (j = 0; j < plist->ulen; ++j) {
    plist_grow(p);
    p->data[j].ptr = plist->data[j].ptr;
    ++p->ulen;
  }
  return p;
}

void plist_init(PList* plist) {
  if (!plist) {
    return;
  }

  plist->data = 0;
  plist->alen = plist->ulen = 0;
}

void plist_clear(PList* plist) {
  if (!plist) {
    return;
  }

  GMEM_DELARR(plist->data, PNode*, plist->alen, sizeof(PNode));
  plist_init(plist);
}

int plist_size(const PList* plist)
{
  return plist ? plist->ulen : 0;
}

PNode* plist_add(PList* plist, const void* obj)
{
  if (!plist) {
    return 0;
  }
  if (!obj) {
    return 0;
  }

  PNode* n = 0;
  plist_grow(plist);
  n = &plist->data[plist->ulen++];
  n->ptr = obj;
  return n;
}

void plist_dump(const PList* plist, FILE* fp)
{
  if (!plist) {
    return;
  }

  int j;
  for (j = 0; j < plist->ulen; ++j) {
    fprintf(fp, "%4d: %p\n", j, plist->data[j].ptr);
  }
  fflush(fp);
}


static void plist_grow(PList* plist) {
  if (!plist) {
    return;
  }
  if (plist->ulen < plist->alen) {
    return;
  }

  int count = plist->alen == 0 ? PLIST_INITIAL_SIZE : 2*plist->alen;
  GLOG(("=C= Growing PList from %d to %d", plist->alen, count));
  GMEM_REALLOC(plist->data, PNode*, sizeof(PNode) * plist->alen, sizeof(PNode) * count);
  plist->alen = count;
}
