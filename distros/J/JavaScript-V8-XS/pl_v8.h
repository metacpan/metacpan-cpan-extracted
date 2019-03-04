#ifndef PL_V8_H
#define PL_V8_H

#include <v8.h>
#include "pl_config.h"
#include "ppport.h"

using namespace v8;
class V8Context;

#if 0
#define PL_NAME_ROOT              "_perl_"

#define PL_NAME_GENERIC_CALLBACK  "generic_callback"

#define PL_SLOT_CREATE(name)      (PL_NAME_ROOT "." #name)

#define PL_SLOT_GENERIC_CALLBACK  PL_SLOT_CREATE(PL_NAME_GENERIC_CALLBACK)
#endif

/*
 * We use these two functions to convert back and forth between the Perl
 * representation of an object and the JS one.
 *
 * Because data in Perl and JS can be nested (array of hashes of arrays of...),
 * the functions are recursive.
 *
 * pl_v8_to_perl: takes a JS value from a given position in the V8 stack,
 * and creates the equivalent Perl value.
 *
 * pl_perl_to_v8: takes a Perl value and leaves the equivalent JS value at the
 * top of the V8 stack.
 */
SV* pl_v8_to_perl(pTHX_ V8Context* ctx, const Local<Object>& object);
const Local<Object> pl_perl_to_v8(pTHX_ SV* value, V8Context* ctx);

/*
 * Get the JS value of a global / nested property as Perl data.
 */
SV* pl_get_global_or_property(pTHX_ V8Context* ctx, const char* name);

/*
 * Return true if a given global / nested property exists.
 */
SV* pl_exists_global_or_property(pTHX_ V8Context* ctx, const char* name);

/*
 * Get the JS type of a global / nested property as a Perl string.
 */
SV* pl_typeof_global_or_property(pTHX_ V8Context* ctx, const char* name);

/*
 * Return a true value if an object is of a given class
 */
SV* pl_instanceof_global_or_property(pTHX_ V8Context* ctx, const char* oname, const char* cname);

/*
 * Set the JS value of a global / nested property from Perl data.
 */
int pl_set_global_or_property(pTHX_ V8Context* ctx, const char* name, SV* value);

/*
 * Delete a global / nested property.
 */
int pl_del_global_or_property(pTHX_ V8Context* ctx, const char* name);

/*
 * Run the V8 GC
 */
int pl_run_gc(V8Context* ctx);

SV* pl_global_objects(pTHX_ V8Context* ctx);

bool find_parent(V8Context* ctx, const char* name, Local<Context>& context, Local<Object>& object, Local<Value>& slot, int create = 0);
bool find_object(V8Context* ctx, const char* name, Local<Context>& context, Local<Object>& object);

#endif
