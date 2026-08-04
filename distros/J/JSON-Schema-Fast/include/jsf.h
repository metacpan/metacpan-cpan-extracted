#ifndef JSF_H
#define JSF_H

/* JSON::Schema::Fast C core - umbrella header.
 *
 * The .xs includes EXTERN.h / perl.h / XSUB.h BEFORE this file (so SV/HV/AV/
 * pTHX are defined); this header pulls in the C99 stdlib pieces the core needs
 * and then the split component headers. Everything is `static` in one
 * translation unit (Fast.c), so a future JSON::Schema::JIT can #include the
 * same core unchanged. */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if defined(__GNUC__) || defined(__clang__)
#  define JSF_LIKELY(x)   __builtin_expect(!!(x), 1)
#  define JSF_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#  define JSF_LIKELY(x)   (x)
#  define JSF_UNLIKELY(x) (x)
#endif

/* Offset 0 is the reserved "null" sentinel in every arena. */
#define JSF_NULL_OFF 0u

#include "jsf_arena.h"
#include "jsf_types.h"
#include "jsf_ir.h"
#include "jsf_err.h"
#include "jsf_compiled.h"
#include "jsf_parse.h"
#include "jsf_interp.h"

#endif /* JSF_H */
