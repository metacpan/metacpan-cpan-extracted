#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"

#include "glog.h"
#include "gmem.h"
#include "cover.h"

#define CHAR_LINE 2

/* How big will the initial bit set allocation be. */
#define COVER_INITIAL_SIZE 16   /* 16 * CHAR_BIT = 128 bits (lines) */

#define COVER_LIST_INITIAL_SIZE 8   /* 8 files in the hash */

/* Handle an array of unsigned char as an array of 4 bit values per line,
 * where bits 0-2 encode coverage and compiler phase (PL_phase has numeric
 * values from 0 to 6), and bit 3 is presence flag.
 */
#define LINE_SHIFT(line)                      ((line%CHAR_LINE)*4)
#define LINE_SET_COVERED(data, line, phase)     data[line/CHAR_LINE] |= ((phase+1) << LINE_SHIFT(line))
#define LINE_SET_PRESENT(data, line)            data[line/CHAR_LINE] |= (8 << LINE_SHIFT(line))
#define LINE_IS_COVERED(data, line)           ((data[line/CHAR_LINE] & ( 7 << LINE_SHIFT(line))) != 0)
#define LINE_IS_PRESENT_OR_COVERED(data, line) (data[line/CHAR_LINE] & (15 << LINE_SHIFT(line)))
#define LINE_GET_COMPILER_PHASE(data, line)  (((data[line/CHAR_LINE] >> LINE_SHIFT(line)) & 7) - 1)

/* Count of the hash collisions in the hash table */
#ifdef GLOG_SHOW
static unsigned int max_collisions = 0;
#endif

/* Helper macro to output the compiler phase */
#define OUTPUT_COMPILER_PHASE(name, op, id, more) \
    do { \
        fprintf(fp, "\"%s\":[", name); \
        lcount = 0; \
        for (j = 1; j <= node->bmax; ++j) { \
          if (LINE_IS_PRESENT_OR_COVERED(node->lines, j)) { \
            if (LINE_GET_COMPILER_PHASE(node->lines, j) op id ) { \
              if (lcount++) { \
                fprintf(fp, ","); \
              } \
              fprintf(fp, "%d", j); \
            } \
          } \
        } \
        fprintf(fp, "]%s", more ? "," : ""); \
    } while (0)

/* Grow CoverNode bit set if necessary. */
static void cover_node_ensure(CoverNode* node, int line);

/* Add a node to the list of files */
static CoverNode* add_get_node(CoverList* cover, const char* file, U32 file_hash);

/* Destroy list of covered subroutines */
static void cover_sub_destroy(SubCoverList* cover);

CoverList* cover_create(void) {
  CoverList* cover;
  GMEM_NEW(cover, CoverList*, sizeof(CoverList));

  cover->used = 0;
  cover->size = COVER_LIST_INITIAL_SIZE;
  GMEM_NEWARR(cover->list, CoverNode**, COVER_LIST_INITIAL_SIZE, sizeof(CoverNode*));

  return cover;
}

void cover_destroy(CoverList* cover) {
  int i;
  CoverNode* node = 0;

  assert(cover);

  for (i = 0; i < cover->size ; i++) {
    node = cover->list[i];
    if (!node) {
      continue;
    }

    CoverNode* tmp = node;
    /* GLOG(("Destroying set for [%s], %d/%d elements", node->file, node->bcnt, node->alen*CHAR_BIT)); */
    /* GLOG(("Destroying string [%s]", tmp->file)); */
    GMEM_DELSTR(tmp->file, -1);
    /* GLOG(("Destroying array [%p] with %d elements", tmp->lines, tmp->alen)); */
    GMEM_DELARR(tmp->lines , unsigned char*,   tmp->alen, sizeof(unsigned char));
    cover_sub_destroy(&tmp->subs);

    /* GLOG(("Destroying node [%p]", tmp)); */
    GMEM_DEL(tmp, CoverNode*, sizeof(CoverNode));
    cover->list[i] = 0;
  }

  GLOG(("Destroying cover [%p]. Max run %d. Used: %d", cover, max_collisions, cover->used));
  GMEM_DELARR(cover->list, CoverNode**, cover->size, sizeof(CoverNode*));
  GMEM_DEL(cover, CoverList*, sizeof(CoverList));
}

void cover_add_covered_line(CoverList* cover, const char* file, U32 file_hash, int line, int phase) {
  CoverNode* node = 0;

  if (file[0] == '(')
    return;

  assert(cover);
  node = add_get_node(cover, file, file_hash);

  assert(node);
  cover_node_ensure(node, line);

  /* if the line was not already registered, do so and keep track of how many */
  /* lines we have seen so far */
  if (! LINE_IS_COVERED(node->lines, line)) {
    /* GLOG(("Adding line %d for [%s]", line, node->file)); */
    ++node->bcnt;
    LINE_SET_COVERED(node->lines, line, phase);
  }
}

void cover_add_line(CoverList* cover, const char* file, U32 file_hash, int line) {
  CoverNode* node = 0;

  if (file[0] == '(')
    return;

  assert(cover);
  node = add_get_node(cover, file, file_hash);

  assert(node);
  cover_node_ensure(node, line);

  LINE_SET_PRESENT(node->lines, line);
}

void cover_dump(CoverList* cover, FILE* fp) {
  CoverNode* node = 0;
  SubCoverNode* sub_node = 0;
  int ncount = 0, i = 0, scount = 0;

  assert(cover);

  /*
   * We output the cover data as elements in a JSON hash
   * that must be opened / closed OUTSIDE this routine.
   */
  fprintf(fp, "\"files\":\n{");
  for (i = 0 ; i < cover->size; i++) {
    int j = 0;
    int lcount;
    node = cover->list[i];
    if (!node || !node->bcnt) {
      continue;
    }

    if (ncount++) {
      fprintf(fp, ",\n");
    }
    fprintf(fp, "\"%s\":{\"covered\":[",
            node->file);
    lcount = 0;
    for (j = 1; j <= node->bmax; ++j) {
      if (LINE_IS_COVERED(node->lines, j)) {
        if (lcount++) {
          fprintf(fp, ",");
        }
        fprintf(fp, "%d", j);
      }
    }
    fprintf(fp, "],\"present\":["); /* close the `covered` object */
    lcount = 0;
    for (j = 1; j <= node->bmax; ++j) {
      if (LINE_IS_PRESENT_OR_COVERED(node->lines, j)) {
        if (lcount++) {
          fprintf(fp, ",");
        }
        fprintf(fp, "%d", j);
      }
    }

    fprintf(fp, "],\"phases\":{"); /* close the `present` object */

    OUTPUT_COMPILER_PHASE("BEGIN"   , <=, PERL_PHASE_START   , 1);
    OUTPUT_COMPILER_PHASE("CHECK"   , ==, PERL_PHASE_CHECK   , 1);
    OUTPUT_COMPILER_PHASE("INIT"    , ==, PERL_PHASE_INIT    , 1);
    OUTPUT_COMPILER_PHASE("RUN"     , ==, PERL_PHASE_RUN     , 1);
    OUTPUT_COMPILER_PHASE("END"     , ==, PERL_PHASE_END     , 1);
    OUTPUT_COMPILER_PHASE("DESTRUCT", ==, PERL_PHASE_DESTRUCT, 0);

    fprintf(fp, "},\"subs\":{"); /* close the `phases` object */

    for (j = 0, scount = 0; j < node->subs.size; j++) {
      const char* phase;
      sub_node = node->subs.list[j];
      if (!sub_node) {
        continue;
      }

      if (scount++) {
        fprintf(fp, ",\n");
      }
      phase = sub_node->phase == PERL_PHASE_CONSTRUCT ? "" :
              sub_node->phase == PERL_PHASE_START ? "BEGIN" :
                                 PL_phase_names[sub_node->phase];
      fprintf(fp, "\"%s,%d\":\"%s\"",
              sub_node->sub, sub_node->line, phase);
    }

    fprintf(fp, "}"); /* close the `subs' object */
    fprintf(fp, "}"); /* close the `list of files` object */
  }
  fprintf(fp, "}"); /* close the `files` object */
}

static void cover_node_ensure(CoverNode* node, int line) {
  /* keep track of largest line seen so far */
  if (node->bmax < line) {
    node->bmax = line;
  }

  /* maybe we need to grow the bit set? */
  int needed = line / CHAR_LINE + 1;
  if (node->alen < needed) {
    /* start at COVER_INITIAL_SIZE, then duplicate the size, until we have */
    /* enough room */
    int size = node->alen ? node->alen : COVER_INITIAL_SIZE;
    while (size < needed) {
      size *= 2;
    }

    /* GLOG(("Growing map for [%s] from %d to %d - %p", node->file, node->alen, size, node->lines)); */

    /* realloc will grow the data and keep all current values... */
    GMEM_REALLOC(node->lines,  unsigned char*,   node->alen * sizeof(unsigned char),   size * sizeof(unsigned char));

    /* ... but it will not initialise the new space to 0. */
    memset(node->lines + node->alen, 0, size - node->alen);

    /* we are bigger now */
    node->alen = size;
  }
}

static U32 find_pos(CoverNode** where, U32 hash, const char* file, int size) {
  U32 pos = hash % size;

#ifdef GLOG_SHOW
  unsigned int run = 0;
#endif

  while (where[pos] &&
         (hash != where[pos]->hash ||
          strcmp(file, where[pos]->file) != 0)) {
    pos = (pos + 1) % size;

#ifdef GLOG_SHOW
    ++run;
#endif
  }

#ifdef GLOG_SHOW
  if (run > max_collisions) {
    max_collisions = run;
  }
#endif

  return pos;
}

static CoverNode* add_get_node(CoverList* cover, const char* file, U32 file_hash) {
  U32 pos, i;
  CoverNode* node = NULL;
  CoverNode** new_list = NULL;

  /* TODO: comment these magic numbers */
  /* TODO: move this enlargement code to a separate function */
  if (3 * cover->used > 2 * cover->size) {
    GMEM_NEWARR(new_list, CoverNode**, cover->size * 2, sizeof(CoverNode*));
    for (i = 0; i < cover->size; i++) {
      if (!cover->list[i]) {
        continue;
      }
      pos = find_pos(new_list, cover->list[i]->hash, cover->list[i]->file, cover->size * 2);
      new_list[pos] = cover->list[i];
    }

    GMEM_DELARR(cover->list, CoverNode**, cover->size, sizeof(CoverNode*));
    cover->list = new_list;
    cover->size *= 2;
  }

  pos = find_pos(cover->list, file_hash, file, cover->size);
  if (cover->list[pos]) {
    return cover->list[pos];
  }

  GMEM_NEW(node, CoverNode*, sizeof(CoverNode));
  /* TODO: normalise name first? ./foo.pl, foo.pl, ../bar/foo.pl, etc. */
  int l = 0;
  GMEM_NEWSTR(node->file, file, -1, l);
  node->lines  = NULL;
  node->hash   = file_hash;
  node->alen   = node->bcnt = node->bmax = 0;
  node->subs.list = NULL;
  node->subs.used = 0;
  node->subs.size = 0;

  ++cover->used;
  cover->list[pos] = node;

  /* GLOG(("Adding set for [%s]", node->file)); */
  return node;
}

/* Add a node to the list of subs */
static SubCoverNode* sub_add_get_node(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line);

static void cover_sub_destroy(SubCoverList* cover) {
  int i;
  SubCoverNode* node = 0;

  assert(cover);

  for (i = 0; i < cover->size ; i++) {
    node = cover->list[i];
    if (!node) {
      continue;
    }

    SubCoverNode* tmp = node;
    GMEM_DELSTR(tmp->sub, -1);
    GMEM_DEL(tmp, SubCoverNode*, sizeof(SubCoverNode));
    cover->list[i] = 0;
  }

  GLOG(("Destroying cover [%p]. Max run %d. Used: %d", cover, max_collisions, cover->used));
  GMEM_DELARR(cover->list, SubCoverNode**, cover->size, sizeof(SubCoverNode*));
}

void cover_sub_add_covered_sub(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line, int phase) {
  SubCoverNode* node = 0;

  assert(cover);
  node = sub_add_get_node(cover, file, file_hash, name, name_hash, line);

  assert(node);

  if (node->phase == PERL_PHASE_CONSTRUCT)
    node->phase = phase;
}

void cover_sub_add_sub(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line) {
  SubCoverNode* node = 0;

  assert(cover);
  node = sub_add_get_node(cover, file, file_hash, name, name_hash, line);

  assert(node);
}

static U32 sub_find_pos(SubCoverNode** where, U32 hash, const char* name, int size) {
  U32 pos = hash % size;

#ifdef GLOG_SHOW
  unsigned int run = 0;
#endif

  while (where[pos] &&
         (hash != where[pos]->hash ||
          strcmp(name, where[pos]->sub) != 0)) {
    pos = (pos + 1) % size;

#ifdef GLOG_SHOW
    ++run;
#endif
  }

#ifdef GLOG_SHOW
  if (run > max_collisions) {
    max_collisions = run;
  }
#endif

  return pos;
}

static SubCoverNode* sub_add_get_node(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line) {
  CoverNode* parent = add_get_node(cover, file, file_hash);
  SubCoverList* sub_cover = &parent->subs;
  U32 pos, i;
  SubCoverNode* node = NULL;
  SubCoverNode** new_list = NULL;

  /* TODO: comment these magic numbers */
  /* TODO: move this enlargement code to a separate function */
  if (sub_cover->size == 0) {
    sub_cover->size = COVER_LIST_INITIAL_SIZE;
    GMEM_NEWARR(sub_cover->list, SubCoverNode**, COVER_LIST_INITIAL_SIZE, sizeof(SubCoverNode*));
  }
  if (3 * sub_cover->used > 2 * sub_cover->size) {
    GMEM_NEWARR(new_list, SubCoverNode**, sub_cover->size * 2, sizeof(SubCoverNode*));
    for (i = 0; i < sub_cover->size; i++) {
      if (!sub_cover->list[i]) {
        continue;
      }
      pos = sub_find_pos(new_list, sub_cover->list[i]->hash, sub_cover->list[i]->sub, sub_cover->size * 2);
      new_list[pos] = sub_cover->list[i];
    }

    GMEM_DELARR(sub_cover->list, SubCoverNode**, sub_cover->size, sizeof(SubCoverNode*));
    sub_cover->list = new_list;
    sub_cover->size *= 2;
  }

  name_hash += line * 6449;

  pos = sub_find_pos(sub_cover->list, name_hash, name, sub_cover->size);
  if (sub_cover->list[pos]) {
    return sub_cover->list[pos];
  }

  GMEM_NEW(node, SubCoverNode*, sizeof(CoverNode));
  int l = 0;
  GMEM_NEWSTR(node->sub, name, -1, l);
  node->line   = line;
  node->hash   = name_hash;
  node->phase  = PERL_PHASE_CONSTRUCT;

  ++sub_cover->used;
  sub_cover->list[pos] = node;

  /* GLOG(("Adding set for [%s]", node->file)); */
  return node;
}
