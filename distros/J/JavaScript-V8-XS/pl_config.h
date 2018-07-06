#ifndef PL_CONFIG_H
#define PL_CONFIG_H

#ifdef __cplusplus
extern "C" {
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"
}
#endif

#ifdef New
#undef New
#endif
#ifdef Null
#undef Null
#endif
#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif
#ifdef IsSet
#undef IsSet
#endif

#endif
