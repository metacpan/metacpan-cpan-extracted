/* $Id: pack.h,v 1.1 2003/03/31 17:42:16 deschwen Exp $ */

#ifndef PACK_H
#define PACK_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/param.h>
#include <sys/pstat.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct pst_static    pst_static;
typedef struct pst_dynamic   pst_dynamic;
typedef struct pst_vminfo    pst_vminfo;
typedef struct pst_swapinfo  pst_swapinfo;
typedef struct pst_status    pst_status;
typedef struct pst_processor pst_processor;

typedef struct my_swapinfo {
    int size;
    pst_swapinfo *data;
} my_swapinfo;

typedef struct my_status {
    int size;
    pst_status *data;
} my_status;

typedef struct my_processor {
    int size;
    pst_processor *data;
} my_processor;


extern void XS_pack_pst_staticPtr(SV *, pst_static *);
extern void XS_pack_pst_dynamicPtr(SV *, pst_dynamic *);
extern void XS_pack_pst_vminfoPtr(SV *, pst_vminfo *);
extern void XS_pack_my_swapinfoPtr(SV *, my_swapinfo *);
extern void XS_pack_my_statusPtr(SV *, my_status *);
extern void XS_pack_my_processorPtr(SV *, my_processor *);

#ifdef __cplusplus
}
#endif

#endif /* PACK_H */
