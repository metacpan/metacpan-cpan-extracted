#include "JavaScript.h"

void PJS_report_exception(PJS_Context *pcx) {
    jsval val;
    JSObject *object;

    /* If ERRSV is already set we can just return */
    if (SvTRUE(ERRSV)) {
        return;
    }
    
    /* No need to report exception if there isn't one */
    if (JS_IsExceptionPending(PJS_GetJSContext(pcx)) == JS_FALSE) {
        return;
    }

    JS_GetPendingException(PJS_GetJSContext(pcx), &val);
    if (JSVALToSV(PJS_GetJSContext(pcx), NULL, val, &ERRSV) == JS_FALSE) {
        croak("Failed to convert error object to perl object");
    }
    
    JS_ClearPendingException(PJS_GetJSContext(pcx));
    
    /* convert internal JS parser exceptions into JavaScript::Error objects. */
    if (JSVAL_IS_OBJECT(val)) {
        JS_ValueToObject(PJS_GetJSContext(pcx), val, &object);
        if (strcmp(OBJ_GET_CLASS(PJS_GetJSContext(pcx), object)->name, "Error") == 0) {
            sv_bless(ERRSV, gv_stashpvn(PJS_ERROR_PACKAGE, strlen(PJS_ERROR_PACKAGE), TRUE));
        }
    }
}
