/*!
    @header PJS_Runtime.h
    @abstract Types and functions related to runtime handling
*/

#ifndef __PJS_RUNTIME_H__
#define __PJS_RUNTIME_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

struct PJS_TrapHandler {
    JSTrapHandler               handler;
    void                        *data;
    
    /* Private field, don't mess with it */
    struct PJS_TrapHandler *_next;
};

/*!
    @struct PJS_Runtime
    @abstract A structure that encapsulates a JSRuntime and supporting information.
    @field rt Pointer to the JSRuntime for this runtime.
    @field list Pointer to a linked list of PJS_Context that are defined in this runtime.
    @field trap_handlers Pointer to a linked list of PJS_TrapHandler structures that are defined for this runtime.
*/
struct PJS_Runtime {
    JSRuntime                       *rt;
    struct PJS_Context              *list;
    struct PJS_TrapHandler          *trap_handlers;
};

/*!
    @function PJS_CreateRuntime
    @abstract Creates and initializes a new runtime.
    @param maxbytes The maximum number of bytes that this runtime may use before throwing an error.
    @result A pointer to an PJS_Runtime.
*/
PJS_EXTERN PJS_Runtime *
PJS_CreateRuntime(int maxbytes);

/*!
    @function PJS_DestroyRuntime
    @abstract Frees the runtime and any memory allocated by it.
    @param runtime The runtime to free.
*/
PJS_EXTERN void
PJS_DestroyRuntime(PJS_Runtime *runtime);

/*!
    @function PJS_AddTrapHandler
    @abstract Registers a traphandler in the runtime.
    @param inRuntime The runtime to install a trap hander in.
    @param trapHandler The trap handler to install
*/
PJS_EXTERN void
PJS_AddTrapHandler(PJS_Runtime *inRuntime, PJS_TrapHandler *trapHandler);
    
/*!
    @function PJS_RemoteTrapHandler
    @abstract Removes a traphandler from the runtime.
    @param fromRuntime The runtime to remove the handler from.
    @param trapHandler The trap handler to remove.
*/
PJS_EXTERN void
PJS_RemoveTrapHandler(PJS_Runtime *fromRuntime, PJS_TrapHandler *trapHandler);

PJS_EXTERN JSTrapStatus
PJS_trap_handler(JSContext *, JSScript *, jsbytecode *, jsval *, void *);

PJS_EXTERN JSTrapStatus
PJS_perl_trap_handler(JSContext *, JSScript *, jsbytecode *, jsval *, void *);

#ifdef __cplusplus
}
#endif

#endif
