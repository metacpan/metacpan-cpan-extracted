#ifndef MARPAWRAPPER_INTERNAL_MANAGEBUF_H
#define MARPAWRAPPER_INTERNAL_MANAGEBUF_H

#include <stddef.h> /* size_t definition */
#include "config.h"
#include "marpaWrapper/export.h"
#include "genericLogger.h"

#ifdef __cpluscplus
extern "C" {
#endif
  MARPAWRAPPER_NO_EXPORT void *manageBuf_createp(genericLogger_t *genericLoggerp, void **pp, size_t *sizelp, const size_t wantedNumberi, const size_t elementSizel);
  MARPAWRAPPER_NO_EXPORT void  manageBuf_freev  (genericLogger_t *genericLoggerp, void **pp);
#ifdef __cpluscplus
}
#endif

#endif /* MARPAWRAPPER_INTERNAL_MANAGEBUF_H */

