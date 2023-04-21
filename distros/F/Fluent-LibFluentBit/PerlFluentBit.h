#include <fluent-bit-minimal.h>

extern MGVTBL PerlFluentBit_ctx_mg_vtbl;
extern void* PerlFluentBit_get_mg(SV *obj, MGVTBL *tbl);
extern SV* PerlFluentBit_set_mg(SV *obj, MGVTBL *tbl, void *ptr);

#define PerlFluentBit_set_ctx_mg(obj, ptr)     PerlFluentBit_set_mg(obj, &PerlFluentBit_ctx_mg_vtbl, (void*) ptr)
#define PerlFluentBit_get_ctx_mg(obj)          ((flb_ctx_t*) PerlFluentBit_get_mg(obj, &PerlFluentBit_ctx_mg_vtbl))
extern SV * PerlFluentBit_wrap_ctx(flb_ctx_t *ctx);
