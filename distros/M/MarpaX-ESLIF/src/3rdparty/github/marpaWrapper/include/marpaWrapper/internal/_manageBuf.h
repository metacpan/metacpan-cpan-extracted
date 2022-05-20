#ifndef MARPAWRAPPER_INTERNAL_MANAGEBUF_H
#define MARPAWRAPPER_INTERNAL_MANAGEBUF_H

#include "marpaWrapper/internal/_logging.h"

#define MARPAWRAPPER_MIN_CHUNK 1024

/*********************************************************************************/
static inline size_t _marpaWrapperGrammar_next_power_of_twob(genericLogger_t *genericLoggerp, size_t wantedl)
/*********************************************************************************/
/* https://www.geeksforgeeks.org/smallest-power-of-2-greater-than-or-equal-to-n/ */
/* Get the multiple of 2 that is >= sizel with one exception when sizel <= 1:    */
/* then the output will be MARPAWRAPPER_MIN_CHUNK (arbitrarily minimum).         */
/*********************************************************************************/
{
  size_t rcl;
  size_t previousl;

  if ((wantedl > 0) && !(wantedl & (wantedl - 1))) {
    rcl = (wantedl < MARPAWRAPPER_MIN_CHUNK) ? MARPAWRAPPER_MIN_CHUNK : wantedl;
  } else {
    previousl = rcl = MARPAWRAPPER_MIN_CHUNK;
    while (rcl < wantedl) {
      /* We count on compiler to optimize (<<= 1, + twice etc.) */
      rcl *= 2;
      if (rcl < previousl) {
        /* Turnaround */
        MARPAWRAPPER_ERRORF(genericLoggerp, "Failed to get power of 2 >= %d", (unsigned long) wantedl);
        rcl = 0;
        break;
      }
      previousl = rcl;
    }
  }

  return rcl;
}

#define MARPAWRAPPER_MANAGEBUF(genericLoggerp, p, currentNumberl, wantedNumberl, sizeOfElementl) do { \
    size_t  _wantedNumberl = wantedNumberl;                             \
    size_t  _nextNumberl;                                               \
    void   *_p;                                                         \
                                                                        \
    if (p == NULL) {                                                    \
      _nextNumberl = _marpaWrapperGrammar_next_power_of_twob(genericLoggerp, wantedNumberl); \
      if (_nextNumberl <= 0) {                                          \
        goto err;                                                       \
      }                                                                 \
      p = malloc(_nextNumberl * sizeOfElementl);                        \
      if (MARPAWRAPPER_UNLIKELY(p == NULL)) {                           \
        MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno)); \
        goto err;                                                       \
      }                                                                 \
      currentNumberl = _nextNumberl;                                    \
    } else if (currentNumberl < _wantedNumberl) {                       \
      _nextNumberl = _marpaWrapperGrammar_next_power_of_twob(genericLoggerp, wantedNumberl); \
      if (_nextNumberl <= 0) {                                          \
        goto err;                                                       \
      }                                                                 \
      _p = realloc(p, _nextNumberl * sizeOfElementl);                   \
      if (MARPAWRAPPER_UNLIKELY(_p == NULL)) {                          \
        MARPAWRAPPER_ERRORF(genericLoggerp, "realloc failure: %s", strerror(errno)); \
        goto err;                                                       \
      }                                                                 \
      p              = _p;                                              \
      currentNumberl = _nextNumberl;                                    \
    }                                                                   \
  } while (0)

#define MARPAWRAPPER_FREEBUF(p) do {            \
    void   *_p = p;                             \
    if (_p != NULL) {                           \
      free(_p);                                 \
      _p = NULL;                                \
    }                                           \
    p = _p;                                     \
  } while (0)

#endif /* MARPAWRAPPER_INTERNAL_MANAGEBUF_H */

