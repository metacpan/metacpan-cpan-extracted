/*!
    @header PJS_Types
    @abstract Definitions of types used throughout the library
*/

#ifndef __PJS_TYPES_H__
#define __PJS_TYPES_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PJS_Runtime PJS_Runtime;
typedef struct PJS_Context PJS_Context;

/*!
    @struct PJS_Runtime
    @abstract A structure that encapsulates a JSRuntime and supporting information.
    @field rt Pointer to the JSRuntime for this runtime.
    @field trap_handler an SV with the current JSPL::TrapHandler instaled in this runtime.
*/
struct PJS_Runtime {
    JSRuntime   *rt;
    SV		*trap_handler; /* Wrapps a PJS_TrapHandler */
};

PJS_GTYPEDEF(PJS_Runtime, RawRT);
PJS_TYPEDEF(Context);

#ifdef __cplusplus
}
#endif

#endif

