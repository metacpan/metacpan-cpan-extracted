#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include "jsapi.h"
#include "jsdbgapi.h"

#if JS_VERSION < 180
#define JS_SetCStringsAreUTF8()	    /**/
#endif

#if JS_VERSION >= 185
#define JS_SetterPropStub   JS_StrictPropertyStub
#else
#define JS_SetterPropStub   JS_PropertyStub
#endif

static JSClass global_class = {
    "global", JSCLASS_GLOBAL_FLAGS,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_SetterPropStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

int main(int argc, char *argv[]) {
    JSRuntime *rt;
    JSContext *cx;
    int tt = 0;
    int HBJ = 0;
    int NOScript = 0;
    void *handle = dlopen(NULL, RTLD_NOW);
#ifndef JS_THREADSAFE
    if(dlsym(handle, "js_GetCurrentThread")) tt++;
#else
    tt++;
#endif
#if JS_VERSION < 180 || defined(JS_MAX_OPERATION_LIMIT)
    /* Don't use interim Operation Callback */
    HBJ++;
#endif
    JS_SetCStringsAreUTF8();
    rt = JS_NewRuntime(8L * 1024 * 1024);
    if(rt) cx = JS_NewContext(rt, 8192);
    else {
	fprintf(stderr, "Can't create runtime!");
	exit(1);
    }
    if(cx) {
	JSClass *jsclass;
	JSObject *gobj;
	// JS_SetContextThread(cx);
	// JS_SetGCParameterForThread(cx, JSGC_MAX_CODE_CACHE_BYTES, 16 * 1024 * 1024);
	JS_BeginRequest(cx);
#if JS_VERSION < 185
	gobj = JS_NewObject(cx, &global_class, NULL, NULL);
#else
	gobj = JS_NewCompartmentAndGlobalObject(cx, &global_class, NULL);
	fprintf(stderr, "Warning: support for this version of SM is a work in progress\n");
#endif
	if(!gobj || !JS_InitStandardClasses(cx, gobj)) 
	    goto fail;
	printf("#define JS_VERSION\t%d\n", JS_VERSION);
#ifndef JS_THREADSAFE
	if(tt) printf("#define JS_THREADSAFE\n", tt);
#endif
	if(HBJ) printf("#define JS_HAS_BRANCH_HANDLER\n");
	else printf("#undef JS_HAS_BRANCH_HANDLER\n");
	if(   !dlsym(handle, "JS_DestroyScript") 
	   && !dlsym(handle, "JS_AddNamedScriptRoot"))
	    printf("#define JSS_IS_OBJ\n");
	if(dlsym(handle, "JS_AddNamedScriptRoot"))
	    printf("#define JSS_IS_NEW\n");
	if(!dlsym(handle, "JS_HasArrayLength"))
	    printf("#define JS_NEED_ARRAYLENGTH\n");
	{ /* Test for bug #533450 */
	    const char *expr = "'\\xe9';";
	    jsval v1;
	    char *bytes;
	    JS_EvaluateScript(cx, gobj, expr, strlen(expr), __FILE__, __LINE__, &v1);
#if JS_VERSION < 185
	    bytes = JS_GetStringBytes(JSVAL_TO_STRING(v1));
#else
	    bytes = JS_EncodeString(cx, JSVAL_TO_STRING(v1));
#endif
	    if(strcmp(bytes, "\303\251") == 0)
		printf("#define JS_UTF8_NATIVE\n");
	    else printf("#undef JS_UTF8_NATIVE\n");
#if JS_VERSION >= 185
	    JS_free(cx, bytes);
#endif
	}
	exit(0);
    }
    fail:
    fprintf(stderr, "Not ABI compatible!\n");
    exit(1);
}
