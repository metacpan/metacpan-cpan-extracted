#ifndef JSF_ERR_H
#define JSF_ERR_H

/* Validate-time context. `errors` is NULL on the is_valid() fast path (no
 * instance-location bookkeeping, no allocation); when non-NULL, validate()
 * collects error hashes and `iloc` is the reused JSON-Pointer buffer for the
 * current instanceLocation. Errors are the only thing that allocates
 * (principle 1). The full vocabulary + assembly live in jsf_interp.h. */

typedef struct jsf_ctx {
    AV  *errors;    /* sink (NULL => is_valid fast path) */
    SV  *iloc;      /* instanceLocation buffer (valid only when errors != NULL) */
    int  collect;   /* gather all errors vs fail-fast */
    int  depth;     /* recursion guard */
} jsf_ctx_t;

#endif /* JSF_ERR_H */
