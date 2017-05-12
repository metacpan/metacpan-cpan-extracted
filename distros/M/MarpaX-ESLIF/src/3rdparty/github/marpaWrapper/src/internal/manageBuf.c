#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "config.h"
#include "marpaWrapper/internal/_manageBuf.h"
#include "marpaWrapper/internal/_logging.h"

/*********************/
/* manageBuf_createp */
/*********************/
void *manageBuf_createp(genericLogger_t *genericLoggerp, void **pp, size_t *sizelp, const size_t wantedNumberi, const size_t elementSizel) {
  size_t sizel     = *sizelp;
  void  *p         = *pp;
  size_t prevSizel;

  /*
   * Per def, this routine is managing an array of pointer
   */

  if (sizel < wantedNumberi) {

    prevSizel = sizel;
    while (sizel < wantedNumberi) {
      if (sizel <= 0) {
	/* Let's start at arbitrary number of elements of 100 */
	sizel = 100;
	p = malloc(sizel * elementSizel);
	if (p == NULL) {
	  MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	  return NULL;
	}
      } else {
	sizel *= 2;
	if (sizel < prevSizel) {
	  /* Turnaround */
	  errno = ERANGE;
	  MARPAWRAPPER_ERRORF(genericLoggerp, "Turnaround detection: %s", strerror(errno));
	  return NULL;
	}
	p = realloc(p, sizel * elementSizel);
	if (p == NULL) {
	  MARPAWRAPPER_ERRORF(genericLoggerp, "realloc failure: %s", strerror(errno));
	  return NULL;
	}
      }
      prevSizel = sizel;
    }
  }

  *pp = p;
  *sizelp = sizel;

  return p;
}

/*******************/
/* manageBuf_freev */
/*******************/
void manageBuf_freev(genericLogger_t *genericLoggerp, void **pp) {
  if (pp != NULL) {
    void *p = *pp;
    if (p != NULL) {
      free(p);
    }
    *pp = NULL;
  }
}

