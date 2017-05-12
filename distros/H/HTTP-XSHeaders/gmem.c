#include <stdio.h>
#include <stdlib.h>
#include "gmem.h"

int gmem_unused = 0;

#if defined(GMEM_CHECK) && GMEM_CHECK >= 1

long gmem_new = 0;
long gmem_del = 0;

static int gmem_inited = 0;

static void gmem_init(void);
static void gmem_fini(void);

static void gmem_init(void) {
  if (gmem_inited) {
    return;
  }

  gmem_inited = 1;
  gmem_new = gmem_del = 0;

#if defined(GMEM_CHECK) && GMEM_CHECK >= 1
  fprintf(stderr, "=== MEM BEG %ld %ld ===\n", gmem_new, gmem_del);
#endif
  atexit(gmem_fini);
}

static void gmem_fini(void) {
  if (!gmem_inited) {
    return ;
  }

#if defined(GMEM_CHECK) && GMEM_CHECK >= 1
  fprintf(stderr, "=== MEM END %ld %ld ===\n", gmem_new, gmem_del);
  if (gmem_new == gmem_del) {
    fprintf(stderr, "=== MEM OK ===\n");
  } else {
    fprintf(stderr, "=== MEM ERR %ld BYTES ===\n", gmem_new - gmem_del);
  }
#endif
  gmem_inited = 0;
}

int gmem_new_called(const char* file,
                    int line,
                    void* var,
                    int count,
                    long size) {
  gmem_init();

  if (!var) {
    return 0;
  }

  if (size <= 0 || count <= 0) {
    return 0;
  }

  long total = size * count;
#if defined(GMEM_CHECK) && GMEM_CHECK >= 2
  fprintf(stderr, "=== MEM NEW %s %d %p %d %ld %ld ===\n",
          file, line, var, count, size, total);
#endif
  gmem_new += total;
  return total;
}

int gmem_del_called(const char* file,
                    int line,
                    void* var,
                    int count,
                    long size) {
  gmem_init();

  if (!var) {
    return 0;
  }

  if (size < 0 && var) {
    size = strlen((char*) var) + 1;
  }
  if (size <= 0 || count <= 0) {
    return 0;
  }

  long total = size * count;
#if defined(GMEM_CHECK) && GMEM_CHECK >= 2
  fprintf(stderr, "=== MEM DEL %s %d %p %d %ld %ld ===\n",
          file, line, var, count, size, total);
#endif
  gmem_del += total;
  return total;
}

int gmem_strnew(const char* file,
                int line,
                char** tgt,
                const char* src,
                int len) {
  if (!tgt) {
    return 0;
  }
  *tgt = 0;
  if (!src) {
    return 0;
  }
  if (len <= 0) {
    len = strlen(src) + 1;
  }
  _GMEM_NEW(*tgt, char*, len);
  memcpy(*tgt, src, len);
  gmem_new_called(file, line, *tgt, len, 1);
  return len;
}

int gmem_strdel(const char* file,
                int line,
                char** str,
                int len) {
  if (!str || !*str) {
    return 0;
  }
  if (len <= 0) {
    len = strlen(*str) + 1;
  }
  gmem_del_called(file, line, *str, len, 1);
  _GMEM_DEL(*str, char*, len);
  *str = 0;
  return len;
}

#endif /* #if defined(GMEM_CHECK) && GMEM_CHECK >= 1 */
