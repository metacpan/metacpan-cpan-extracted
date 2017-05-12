#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "glog.h"
#include "gmem.h"
#include "header.h"
#include "plist.h"
#include "hlist.h"

static void hlist_del_pos(HList* hlist, int pos, int clear);
static void hlist_grow(HList* hlist);
static int hlist_cmp(const void* v1, const void* v2);
static HNode* hlist_lookup(HList* hlist, const char* name, int type, int add, int del);


HList* hlist_create(void) {
  HList* p = 0;
  GMEM_NEW(p, HList*, sizeof(HList));
  if (!p) {
    return 0;
  }

  hlist_init(p);
  return p;
}

void hlist_destroy(HList* hlist) {
  if (!hlist) {
    return;
  }

  hlist_clear(hlist);
  GMEM_DEL(hlist, HList*, sizeof(HList));
}

HList* hlist_clone(HList* hlist) {
  if (!hlist) {
    return 0;
  }

  GLOG(("=C= Cloning hlist %p", hlist));
  /* hlist_dump(hlist, stderr); */
  HList* p = hlist_create();
  p->flags = hlist->flags;
  int j;
  for (j = 0; j < hlist->ulen; ++j) {
    hlist_grow(p);
    p->data[j].header = header_clone(hlist->data[j].header);
    p->data[j].values = plist_clone(hlist->data[j].values);
    ++p->ulen;
  }
  return p;
}

void hlist_init(HList* hlist) {
  if (!hlist) {
    return;
  }

  hlist->data = 0;
  hlist->alen = hlist->ulen = 0;
  hlist->flags = 0;
}

/* TODO: perhaps we should leave hlist as empty but not delete the chunks we */
/* already allocated for it... */
void hlist_clear(HList* hlist) {
  if (!hlist) {
    return;
  }

  int j;
  for (j = 0; j < hlist->ulen; ++j) {
    HNode* n = &hlist->data[j];
    header_destroy(n->header);
    plist_destroy(n->values);
  }
  GMEM_DELARR(hlist->data, HNode*, hlist->alen, sizeof(HNode));
  hlist_init(hlist);
}

int hlist_size(const HList* hlist)
{
  return hlist ? hlist->ulen : 0;
}

HNode* hlist_get(HList* hlist, const char* name) {
  if (!hlist) {
    return 0;
  }

  GLOG(("=C= Getting [%s]", name));
  return hlist_lookup(hlist, name, HEADER_TYPE_NONE, 0, 0);
}

HNode* hlist_add(HList* hlist, const char* name, const void* obj) {
  if (!hlist) {
    return 0;
  }

  HNode* n = hlist_lookup(hlist, name, HEADER_TYPE_NONE, 0, 0);
  if (!n) {
    Header* h = header_lookup_standard(HEADER_TYPE_NONE, name);
    if (!h) {
      h = header_create(name);
    }
    hlist_grow(hlist);
    n = &hlist->data[hlist->ulen++];
    n->header = h;
    n->values = plist_create();
    HLIST_FLAG_CLR(hlist, HLIST_FLAGS_SORTED);
  }

  plist_add(n->values, obj);
  GLOG(("=C= Added [%s] => %p (%d)", name, obj, n->header->order));
  return n;
}

void hlist_del(HList* hlist, const char* name) {
  if (!hlist) {
    return;
  }

  GLOG(("=C= Deleting [%s]", name));
  hlist_lookup(hlist, name, HEADER_TYPE_NONE, 0, 1);
}

void hlist_sort(HList* hlist) {
  if (!hlist) {
    return;
  }

  if (HLIST_FLAG_GET(hlist, HLIST_FLAGS_SORTED)) {
    GLOG(("=C= Already sorted hlist"));
  } else {
    GLOG(("=C= Sorting hlist"));
    qsort(hlist->data, hlist->ulen, sizeof(HNode), hlist_cmp);
    GLOG(("=C= Sorted hlist"));
    HLIST_FLAG_SET(hlist, HLIST_FLAGS_SORTED);
  }
}

void hlist_dump(const HList* hlist, FILE* fp) {
  if (!hlist) {
    return;
  }

  int j;
  for (j = 0; j < hlist->ulen; ++j) {
    HNode* n = &hlist->data[j];
    header_dump(n->header, fp);
    plist_dump(n->values, fp);
  }
  fflush(fp);
}

void hlist_transfer_header(HList* from, int pos, HList* to)
{
  if (!from || !to) {
    return;
  }
  if (pos >= hlist_size(from)) {
    return;
  }
  hlist_grow(to);
  to->data[to->ulen++] = from->data[pos];
  hlist_del_pos(from, pos, 0);
}


static void hlist_del_pos(HList* hlist, int pos, int clear) {
  HNode* n = &hlist->data[pos];
  --hlist->ulen;
  if (clear) {
    header_destroy(n->header);
    plist_destroy(n->values);
  }
  int j;
  for (j = pos; j < hlist->ulen; ++j) {
    hlist->data[j] = hlist->data[j+1];
  }
}

static void hlist_grow(HList* hlist) {
  if (!hlist) {
    return;
  }
  if (hlist->ulen < hlist->alen) {
    return;
  }

  int count = hlist->alen == 0 ? HLIST_INITIAL_SIZE : 2*hlist->alen;
  GLOG(("=C= Growing HList from %d to %d", hlist->alen, count));
  GMEM_REALLOC(hlist->data, HNode*, sizeof(HNode) * hlist->alen, sizeof(HNode) * count);
  hlist->alen = count;
}

static int hlist_cmp(const void* v1, const void* v2) {
  const HNode* n1 = (const HNode*) v1;
  const HNode* n2 = (const HNode*) v2;
  const Header* h1 = n1->header;
  const Header* h2 = n2->header;

  int delta = h1->order - h2->order;
  return delta ? delta : header_compare(h1->name, h2->name);
}

/*
 * TODO: leave this as pure lookup, move insert and delete to the caller functions?
 */
static HNode* hlist_lookup(HList* hlist, const char* name, int type, int add, int del) {
  if (!hlist) {
    return 0;
  }

  int j = 0;
  HNode* n = 0;
  for (j = 0; j < hlist->ulen; ++j) {
    n = &hlist->data[j];
    if (header_matches_type_or_name(n->header, type, name)) {
      break;
    }
  }
  if (j >= hlist->ulen) {
    n = 0;
  }

  do {
    if (add) {
      if (n) {
        break;
      }
      hlist_grow(hlist);
      n = &hlist->data[hlist->ulen++];
      Header* h = header_create(name);
      n->header = h;
      n->values = plist_create();
      HLIST_FLAG_CLR(hlist, HLIST_FLAGS_SORTED);
      break;
    }

    if (del) {
      if (!n) {
        break;
      }
      hlist_del_pos(hlist, j, 1);
      n = 0;
      break;
    }
  } while (0);

  return n;
}
