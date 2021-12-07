#include <dyncall.h>
#include <dyncall_callback.h>
#include <dynload.h>

typedef struct
{
    DLLib *lib;
    DLSyms *syms;
    DCCallVM *cvm;
} Dyncall;

typedef struct
{
    const char *name;
    const char *sig;
    const char *ret;
    DCpointer *fptr;
    Dyncall *lib;
} DynXSub;

typedef struct _callback
{
    SV *cb;
    const char *signature;
    char ret_type;
    SV *userdata;
    DCCallVM *cvm;
} _callback;
