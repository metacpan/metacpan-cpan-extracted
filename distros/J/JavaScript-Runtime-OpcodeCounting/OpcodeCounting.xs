#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <JavaScript.h>

#define PJS_ERROR_OPCODELILMIT_EXCEEDED "JavaScript::Error::OpcodeLimitExceeded"

struct PJS_Runtime_OpcodeCounting {
    U32 count;
    U32 limit;
};

typedef struct PJS_Runtime_OpcodeCounting PJS_Runtime_OpcodeCounting;

static JSTrapStatus opcodecounting_interrupt_handler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *data) {
    PJS_Runtime_OpcodeCounting *opcount = (PJS_Runtime_OpcodeCounting *) data;
    
    opcount->count++;
    
    if (opcount->limit > 0 && opcount->count > opcount->limit) {
        sv_setsv(ERRSV, newRV_inc(newSViv(opcount->limit)));
        sv_bless(ERRSV, gv_stashpvn(PJS_ERROR_OPCODELILMIT_EXCEEDED, strlen(PJS_ERROR_OPCODELILMIT_EXCEEDED), TRUE));
        return JSTRAP_ERROR;
    }
    
    return JSTRAP_CONTINUE;
}

MODULE = JavaScript::Runtime::OpcodeCounting        PACKAGE = JavaScript::Runtime::OpcodeCounting

PJS_TrapHandler *
jsr_init()
    PREINIT:
        PJS_TrapHandler            *handler;
        PJS_Runtime_OpcodeCounting *opcount;
    CODE:
        Newz(1, opcount, 1, PJS_Runtime_OpcodeCounting);
        if (opcount == NULL) {
            croak("Failed to allocate memory for PJS_Runtime_OpcodeCounting");
        }
        
        opcount->count = 0;
        opcount->limit = 0;
        
        Newz(1, handler, 1, PJS_TrapHandler);
        if (handler == NULL) {
            Safefree(opcount);
            croak("Failed to allocate memory for PJS_TrapHandler");
        }
        handler->handler = opcodecounting_interrupt_handler;
        handler->data = (void *) opcount;
        RETVAL = handler;
    OUTPUT:
        RETVAL
        
void
jsr_destroy(handler)
    PJS_TrapHandler *handler;
    CODE:
        Safefree(handler->data);
        Safefree(handler);
        
I32
jsr_get_opcount(handler)
    PJS_TrapHandler *handler;
    PREINIT:
        PJS_Runtime_OpcodeCounting *opcount;
    CODE:
        opcount = (PJS_Runtime_OpcodeCounting *) handler->data;
        RETVAL = opcount->count;
    OUTPUT:
        RETVAL
        
void
jsr_set_opcount(handler,count)
    PJS_TrapHandler *handler;
    I32         count;
    PREINIT:
        PJS_Runtime_OpcodeCounting *opcount;
    CODE:
        opcount = (PJS_Runtime_OpcodeCounting *) handler->data;
        opcount->count = count;
        
I32
jsr_get_opcount_limit(handler)
    PJS_TrapHandler *handler;
    PREINIT:
        PJS_Runtime_OpcodeCounting *opcount;
    CODE:
        opcount = (PJS_Runtime_OpcodeCounting *) handler->data;
        RETVAL = opcount->limit;
    OUTPUT:
        RETVAL
        
void
jsr_set_opcount_limit(handler,limit)
    PJS_TrapHandler *handler;
    I32         limit;
    PREINIT:
        PJS_Runtime_OpcodeCounting *opcount;
    CODE:
        opcount = (PJS_Runtime_OpcodeCounting *) handler->data;
        opcount->limit = limit;
