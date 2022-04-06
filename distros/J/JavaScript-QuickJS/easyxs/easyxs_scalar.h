#ifndef EASYXS_SCALAR_H
#define EASYXS_SCALAR_H 1

#include "init.h"

/* EXPERIMENTAL! */

enum exs_sv_type_e {
    EXS_SVTYPE_UNKNOWN,
    EXS_SVTYPE_UNDEF,
    EXS_SVTYPE_REFERENCE,
    EXS_SVTYPE_BOOLEAN,
    EXS_SVTYPE_STRING,
    EXS_SVTYPE_UV,
    EXS_SVTYPE_IV,
    EXS_SVTYPE_NV,
};

typedef enum exs_sv_type_e exs_sv_type_e;

#ifndef SvIsBOOL
#define SvIsBOOL(sv) FALSE
#endif

#define exs_sv_type(sv) (           \
    !SvOK(sv) ? EXS_SVTYPE_UNDEF        \
    : SvROK(sv) ? EXS_SVTYPE_REFERENCE  \
    : SvIsBOOL(sv) ? EXS_SVTYPE_BOOLEAN \
    : SvPOK(sv) ? EXS_SVTYPE_STRING     \
    : SvUOK(sv) ? EXS_SVTYPE_UV         \
    : SvIOK(sv) ? EXS_SVTYPE_IV         \
    : SvNOK(sv) ? EXS_SVTYPE_NV         \
    : EXS_SVTYPE_UNKNOWN                \
)

#endif
