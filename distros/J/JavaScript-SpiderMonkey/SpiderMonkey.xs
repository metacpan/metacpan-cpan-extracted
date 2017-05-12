/* --------------------------------------------------------------------- */
/* SpiderMonkey.xs -- Perl Interface to the SpiderMonkey JavaScript      */
/*                    implementation.                                    */
/*                                                                       */
/* Revision:     $Revision: 1.7 $                                        */
/* Last Checkin: $Date: 2010/05/29 06:49:31 $                            */
/* By:           $Author: thomas_busch $                                     */
/*                                                                       */
/* Author: Mike Schilli mschilli1@aol.com, 2001                          */
/* --------------------------------------------------------------------- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "jsapi.h"
#include "SpiderMonkey.h"

#ifdef _MSC_VER
    /* As suggested in https://rt.cpan.org/Ticket/Display.html?id=6984 */
#define snprintf _snprintf 
#endif

/* JSRuntime needs this global class */
static
JSClass global_class = {
    "Global", 0,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub
};

static int Debug = 0;

static int max_branch_operations = 0;

/* It's kinda silly that we have to replicate this for getters and setters,
 * but there doesn't seem to be a way to distinguish between getters
 * and setters if we use the same function. (Somewhere I read in a 
 * usenet posting there's something like IS_ASSIGN, but this doesn't
 * seem to be in SpiderMonkey 1.5).
 */

/* --------------------------------------------------------------------- */
JSBool getsetter_dispatcher(
    JSContext *cx, 
    JSObject  *obj,
    jsval      id,
    jsval     *vp,
    char      *what
/* --------------------------------------------------------------------- */
) {
    dSP; 

    /* Call back into perl */
    ENTER ; 
    SAVETMPS ;
    PUSHMARK(SP);
        /* A somewhat nasty trick: Since JS_DefineObject() down below
         * returns a *JS_Object, which is typemapped as T_PTRREF,
         * and which is a reference (!) pointing to the real C pointer,
         * we need to brutally obtain the obj's address by casting
         * it to an int and forming a scalar out of it.
         * On the other hand, when Spidermonkey.pm stores the 
         * object's setters/getters, it will dereference
         * what it gets from JS_DefineObject() (therefore
         * obtain the object's address in memory) to index its
         * hash table.
         * I hope all reasonable machines can hold an address in
         * an int.
         */
    XPUSHs(sv_2mortal(newSViv((int)obj)));
    XPUSHs(sv_2mortal(newSVpv(JS_GetStringBytes(JSVAL_TO_STRING(id)), 0)));
    XPUSHs(sv_2mortal(newSVpv(what, 0)));
    XPUSHs(sv_2mortal(newSVpv(JS_GetStringBytes(JSVAL_TO_STRING(*vp)), 0)));
    PUTBACK;
    call_pv("JavaScript::SpiderMonkey::getsetter_dispatcher", G_DISCARD);
    FREETMPS;
    LEAVE;

    return JS_TRUE;
}

/* --------------------------------------------------------------------- */
JSBool getter_dispatcher(
    JSContext *cx, 
    JSObject  *obj,
    jsval      id,
    jsval     *vp
/* --------------------------------------------------------------------- */
) {
    return getsetter_dispatcher(cx, obj, id, vp, "getter");
}

/* --------------------------------------------------------------------- */
JSBool setter_dispatcher(
    JSContext *cx, 
    JSObject  *obj,
    jsval      id,
    jsval     *vp
/* --------------------------------------------------------------------- */
) {
    return getsetter_dispatcher(cx, obj, id, vp, "setter");
}

/* --------------------------------------------------------------------- */
int debug_enabled(
/* --------------------------------------------------------------------- */
) {
    dSP; 

    int enabled = 0;
    int count   = 0;

    /* Call back into perl */
    ENTER ; 
    SAVETMPS ;
    PUTBACK;
    count = call_pv("JavaScript::SpiderMonkey::debug_enabled", G_SCALAR);
    if(count == 1) {
        if(POPi == 1) {
            enabled = 1;
        }
    }
    FREETMPS;
    LEAVE;

    return enabled;
}

/* --------------------------------------------------------------------- */
static JSBool
FunctionDispatcher(JSContext *cx, JSObject *obj, uintN argc, 
    jsval *argv, jsval *rval) {
/* --------------------------------------------------------------------- */
    dSP; 
    SV          *sv;
    char        *n_jstr;
    int         n_jnum;
    double      n_jdbl;
    unsigned    i;
    int         count;
    JSFunction  *fun;
    fun = JS_ValueToFunction(cx, argv[-2]);

    /* printf("Function %s received %d arguments\n", 
           (char *) JS_GetFunctionName(fun),
           (int) argc); */

    /* Call back into perl */
    ENTER ; 
    SAVETMPS ;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((int)obj)));
    XPUSHs(sv_2mortal(newSVpv(
        JS_GetFunctionName(fun), 0)));
    for(i=0; i<argc; i++) {
        XPUSHs(sv_2mortal(newSVpv(
            JS_GetStringBytes(JS_ValueToString(cx, argv[i])), 0)));
    }
    PUTBACK;
    count = call_pv("JavaScript::SpiderMonkey::function_dispatcher", G_SCALAR);
    SPAGAIN;

    if(Debug)
        fprintf(stderr, "DEBUG: Count is %d\n", count);

    if( count > 0) {
        sv = POPs;        
        if(SvROK(sv)) {
            /* Im getting a perl reference here, the user
             * seems to want to send a perl object to jscript
             * ok, we will do it, although it seems like a painful
             * thing to me.
             */

            if(Debug)
                fprintf(stderr, "DEBUG: %lx is a ref!\n", (long) sv);
            *rval = OBJECT_TO_JSVAL(SvIV(SvRV(sv)));
        }
        else if(SvIOK(sv)) {
            /* It appears that we have been sent an int return
             * value.  Thats fine we can give javascript an int
             */
            n_jnum=SvIV(sv);
            if(Debug)
                fprintf(stderr, "DEBUG: %lx is an int (%d)\n", (long) sv,n_jnum);
            *rval = INT_TO_JSVAL(n_jnum);
        } else if(SvNOK(sv)) {
            /* It appears that we have been sent an double return
             * value.  Thats fine we can give javascript an double
             */
            n_jdbl=SvNV(sv);

            if(Debug) 
                fprintf(stderr, "DEBUG: %lx is a double(%f)\n", (long) sv,n_jdbl);
            *rval = DOUBLE_TO_JSVAL(JS_NewDouble(cx, n_jdbl));
        } else if(SvPOK(sv)) {
            n_jstr = SvPV(sv, PL_na);
            //warn("DEBUG: %s (%d)\n", n_jstr);
            *rval = STRING_TO_JSVAL(JS_NewStringCopyZ(cx, n_jstr));
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return JS_TRUE;
}

/* --------------------------------------------------------------------- */
static void
ErrorReporter(JSContext *cx, const char *message, JSErrorReport *report) {
/* --------------------------------------------------------------------- */
     char msg[400];
     if (report->linebuf) {
         int i = 0;
         int printed = 
             snprintf (msg, sizeof(msg), 
                       "Error: %s at line %d: ", message, report->lineno
                       );
         /* Don't print the \n at the end of report->linebuf. */
         while (printed < sizeof (msg) - 1) {
             if (report->linebuf[i] == '\n')
                 break;
             msg[printed] = report->linebuf[i];
             printed++;
             i++;
         }
         msg[printed] = '\0';
     } else {
         /*
           Fix for following bug (report->linebuf is null at runtime):
           https://rt.cpan.org/Public/Bug/Display.html?id=57617
           BKB 2010-05-24 10:12:45
          */
         snprintf(msg, sizeof(msg), 
                  "Error: %s at line %d", message, report->lineno);
     }
     sv_setpv(get_sv("@", TRUE), msg);
}

/* --------------------------------------------------------------------- */
static JSBool
BranchHandler(JSContext *cx, JSScript *script) {
/* --------------------------------------------------------------------- */
  PJS_Context* pcx = (PJS_Context*) JS_GetContextPrivate(cx);

  pcx->branch_count++;
  if (pcx->branch_count > pcx->branch_max) {
    return JS_FALSE;
  } else {
    return JS_TRUE;
  }
}



MODULE = JavaScript::SpiderMonkey	PACKAGE = JavaScript::SpiderMonkey
PROTOTYPES: DISABLE

######################################################################
char *
JS_GetImplementationVersion()
######################################################################
    CODE:
    {
        RETVAL = (char *) JS_GetImplementationVersion();
    }
    OUTPUT:
    RETVAL

######################################################################
JSRuntime *
JS_NewRuntime(maxbytes)
        int maxbytes
######################################################################
    PREINIT:
    JSRuntime *rt;
    CODE:
    {
        rt = JS_NewRuntime(maxbytes);
        if(!rt) {
            XSRETURN_UNDEF;
        }
        RETVAL = rt;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_DestroyRuntime(rt)
        JSRuntime *rt
######################################################################
    CODE:
    {
        JS_DestroyRuntime(rt);
        RETVAL = 0;
    }
    OUTPUT:
    RETVAL

######################################################################
JSRuntime *
JS_Init(maxbytes)
        int maxbytes
######################################################################
    PREINIT:
    JSRuntime *rt;
    CODE:
    {
        rt = JS_Init(maxbytes);
        if(!rt) {
            XSRETURN_UNDEF;
        }
            /* Replace this by Debug = debug_enabled(); once 
             * Log::Log4perl 0.47 is out */
        Debug = 0;
        RETVAL = rt;
    }
    OUTPUT:
    RETVAL

######################################################################
JSContext *
JS_NewContext(rt, stack_chunk_size)
        JSRuntime *rt
        int stack_chunk_size
######################################################################
    PREINIT:
    JSContext *cx;
    CODE:
    {
        PJS_Context* pcx;
        cx = JS_NewContext(rt, stack_chunk_size);
        if(!cx) {
            XSRETURN_UNDEF;
        }
#ifdef E4X
        JS_SetOptions(cx,JSOPTION_XML);
#endif

        Newz(1, pcx, 1, PJS_Context);
        JS_SetContextPrivate(cx, (void *)pcx);

        RETVAL = cx;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_DestroyContext(cx)
    JSContext *cx;
######################################################################
    CODE:
    {
        JS_DestroyContext(cx);
        Safefree(JS_GetContextPrivate(cx));
        RETVAL = 0;
    }
    OUTPUT:
    RETVAL

######################################################################
JSObject *
JS_NewObject(cx, class, proto, parent)
    JSContext * cx
    JSClass   * class
    JSObject  * proto
    JSObject  * parent
######################################################################
    PREINIT:
    JSObject *obj;
    CODE:
    {
        obj = JS_NewObject(cx, class, NULL, NULL);
        if(!obj) {
            XSRETURN_UNDEF;
        }
        RETVAL = obj;
    }
    OUTPUT:
    RETVAL

######################################################################
JSObject *
JS_InitClass(cx, iobj, parent_proto, clasp, constructor, nargs, ps, fs, static_ps, static_fs)
    JSContext * cx
    JSObject *iobj
    JSObject *parent_proto
    JSClass *clasp
    JSNative constructor
    int nargs
    JSPropertySpec *ps
    JSFunctionSpec *fs
    JSPropertySpec *static_ps
    JSFunctionSpec *static_fs
######################################################################
    PREINIT:
    JSObject *obj;
    uintN     na;
    INIT:
    na = (uintN) nargs;
    CODE:
    {
        obj = JS_InitClass(cx, iobj, parent_proto, clasp,
                           constructor, nargs, ps, fs, static_ps,
                           static_fs);
        if(!obj) {
            XSRETURN_UNDEF;
        }
        RETVAL = obj;
    }
    OUTPUT:
    RETVAL

######################################################################
JSClass *
JS_GlobalClass()
######################################################################
    PREINIT:
    JSClass *gc;
    CODE:
    {
        gc = &global_class;
        RETVAL = gc;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_EvaluateScript(cx, gobj, script, length, filename, lineno)
    JSContext  * cx
    JSObject   * gobj
    char       * script 
    int          length
    char       * filename
    int          lineno
######################################################################
    PREINIT:
    uintN len;
    uintN ln;
    int    rc;
    jsval  jsval;
    INIT:
    len = (uintN) length;
    ln  = (uintN) lineno;
    CODE:
    {
        rc = JS_EvaluateScript(cx, gobj, script, len, filename,
                               ln, &jsval);
        if(!rc) {
            XSRETURN_UNDEF;
        }
        RETVAL = rc;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_InitStandardClasses(cx, gobj)
    JSContext  * cx
    JSObject   * gobj
######################################################################
    PREINIT:
    JSBool rc;
    CODE:
    {
        rc = JS_InitStandardClasses(cx, gobj);
        if(!rc) {
            XSRETURN_UNDEF;
        }
        RETVAL = (int) rc;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_DefineFunction(cx, obj, name, nargs, flags)
    JSContext  * cx
    JSObject   * obj
    char       * name
    int          nargs
    int          flags
######################################################################
    PREINIT:
    JSFunction *rc;
    CODE:
    {
        rc = JS_DefineFunction(cx, obj,
             (const char *) name, FunctionDispatcher,
             (uintN) nargs, (uintN) flags);
        if(!rc) {
            XSRETURN_UNDEF;
        }
        RETVAL = (int) rc;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_SetErrorReporter(cx)
    JSContext  * cx
######################################################################
    CODE:
    {
        JS_SetErrorReporter(cx, ErrorReporter);
        RETVAL = 0;
    }
    OUTPUT:
    RETVAL

######################################################################
JSObject *
JS_DefineObject(cx, obj, name, class, proto)
    JSContext  * cx
    JSObject   * obj
    char       * name
    JSClass    * class
    JSObject   * proto
######################################################################
    PREINIT:
    SV       *sv = sv_newmortal();
    CODE:
    {
        RETVAL = JS_DefineObject(cx, obj, name, class, proto, 0);
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_DefineProperty(cx, obj, name, value)
    JSContext   * cx
    JSObject    * obj
    char        * name 
    char        * value
    #JSPropertyOp  getter
    #JSPropertyOp  setter
    #uintN         flags
######################################################################
    PREINIT:
    JSBool rc;
    JSString *str;
    CODE:
    {
        str = JS_NewStringCopyZ(cx, value); 

        /* This implementation is somewhat sub-optimal, since it
         * calls back into perl even if no getters/setters have
         * been defined. The necessity for a callback is determined
         * at the perl level, where there's a data structure mapping
         * out each object's properties and their getter/setter settings.
         */
        rc = JS_DefineProperty(cx, obj, name, STRING_TO_JSVAL(str), 
                               getter_dispatcher, setter_dispatcher, 0);
        RETVAL = (int) rc;
    }
    OUTPUT:
    RETVAL

######################################################################
void
JS_GetProperty(cx, obj, name)
    JSContext   * cx
    JSObject    * obj
    char        * name 
######################################################################
    PREINIT:
    JSBool rc;
    jsval  vp;
    JSString *str;
    SV       *sv = sv_newmortal();
    PPCODE:
    {
        rc = JS_TRUE;
        rc = JS_GetProperty(cx, obj, name, &vp);
        if(rc) {
            str = JS_ValueToString(cx, vp);
            if(strcmp(JS_GetStringBytes(str), "undefined") == 0) {
                sv = &PL_sv_undef;
            } else {
                sv_setpv(sv, JS_GetStringBytes(str));
            }
        } else {
            sv = &PL_sv_undef;
        }
        XPUSHs(sv);
    }

######################################################################
JSObject *
JS_NewArrayObject(cx)
    JSContext  * cx
######################################################################
    PREINIT:
    JSObject *rc;
    CODE:
    {
        rc = JS_NewArrayObject(cx, 0, NULL);
        RETVAL = rc;
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_SetElement(cx, obj, idx, valptr)
    JSContext  *cx
    JSObject   *obj
    int         idx
    char       *valptr
######################################################################
    PREINIT:
    JSBool rc;
    JSString  *str;
    jsval val;
    CODE:
    {
        str = JS_NewStringCopyZ(cx, valptr);
        val = STRING_TO_JSVAL(str); 
        rc = JS_SetElement(cx, obj, idx, &val);
        if(rc) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    }
    OUTPUT:
    RETVAL

######################################################################
int
JS_SetElementAsObject(cx, obj, idx, elobj)
    JSContext  *cx
    JSObject   *obj
    int         idx
    JSObject   *elobj
######################################################################
    PREINIT:
    JSBool rc;
    jsval val;
    CODE:
    {
        val = OBJECT_TO_JSVAL(elobj); 
        rc = JS_SetElement(cx, obj, idx, &val);
        if(rc) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    }
    OUTPUT:
    RETVAL

######################################################################
void
JS_GetElement(cx, obj, idx)
    JSContext  *cx
    JSObject   *obj
    int         idx
######################################################################
    PREINIT:
    JSBool rc;
    jsval  vp;
    JSString *str;
    SV       *sv = sv_newmortal();
    PPCODE:
    {
        rc = JS_GetElement(cx, obj, idx, &vp);
        if(rc) {
            str = JS_ValueToString(cx, vp);
            if(strcmp(JS_GetStringBytes(str), "undefined") == 0) {
                sv = &PL_sv_undef;
            } else {
                sv_setpv(sv, JS_GetStringBytes(str));
            }
        } else {
            sv = &PL_sv_undef;
        }
        XPUSHs(sv);
    }

######################################################################
JSClass *
JS_GetClass(cx, obj)
    JSContext  * cx
    JSObject  * obj
######################################################################
    PREINIT:
    JSClass *rc;
    CODE:
    {
#ifdef JS_THREADSAFE
        rc = JS_GetClass(cx, obj);
#else
        rc = JS_GetClass(obj);
#endif
        RETVAL = rc;
    }
    OUTPUT:
    RETVAL


######################################################################
void
JS_SetMaxBranchOperations(cx, max_branch_operations)
    JSContext  *cx
    int         max_branch_operations
######################################################################
    CODE:
    {
        PJS_Context* pcx = (PJS_Context *) JS_GetContextPrivate(cx);
        pcx->branch_count = 0;
        pcx->branch_max = max_branch_operations;
        JS_SetBranchCallback(cx, BranchHandler);
    }
    OUTPUT:


######################################################################

