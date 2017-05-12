#define NEED_newSVpvn_flags

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <iup.h>

#ifdef HAVELIB_IUPCD
#include <cd.h>
#include <wd.h>
#include <cdiup.h>
#endif

#ifdef HAVELIB_IUPIM
#include <iupim.h>
#include <im.h>
#include <im_image.h>
#endif

#ifdef HAVELIB_IUPCONTROLS
#include <iupcontrols.h>
#endif

#ifdef HAVELIB_IUP_PPLOT
#include <iup_pplot.h>
#endif

#ifdef HAVELIB_IUP_PLOT
#include <iup_plot.h>
#endif

#ifdef HAVELIB_IUP_MGLPLOT
#include <iup_mglplot.h>
#endif

#ifdef HAVELIB_IUPGL
#include <iupgl.h>
#endif

#ifdef HAVELIB_IUPOLE
#include <iupole.h>
#endif

#ifdef HAVELIB_IUPGLCONTROLS
#include <iupglcontrols.h>
#endif

#ifdef HAVELIB_IUP_SCINTILLA
#include <iup_scintilla.h>
#endif

#ifdef HAVELIB_CDCONTEXTPLUS
/* XXX */
#endif

/* Used only by the Perl binding not in iup.h */
int iupGetParamCount(const char *format, int *param_extra);
char iupGetParamType(const char* format, int *line_size);

/* macros for processing args in fuctions with variable arg list, e.g. 'func(...)' */
#define myST2IHN(a) ((items>(a)) && (SvIOK(ST(a))) ? INT2PTR(Ihandle*, SvIVX(ST(a))) : NULL)
#define myST2INT(a) ((items>(a)) && (SvOK(ST(a))) ? SvIV(ST(a)) : 0)
#define myST2FLT(a) ((items>(a)) && (SvOK(ST(a))) ? SvNV(ST(a)) : 0.0)
#define myST2STR(a) ((items>(a)) && (SvOK(ST(a))) ? SvPV_nolen(ST(a)) : NULL)

/* convert 'SV' to 'Ihandle*' + do undef->NULL conversion */
#define mySV2IHN(a) (SvIOK(a) ? INT2PTR(Ihandle *, SvIVX(a)) : NULL)
#define mySV2FLT(a) (SvOK(a) ? SvNV(a) : 0.0)
#define mySV2STR(a) (SvOK(a) ? SvPV_nolen(a) : NULL)

/* GetParam callback stuff */

typedef struct _getparam_data {
  int has_func;
  int obj_initialized;
  SV* func_ref;
  SV* obj_ref;
} getparam_data;

static int cb_param_action(Ihandle* dialog, int param_index, void* user_data) {
  int count, ret = 1;  
  getparam_data* gp = (getparam_data*)user_data;  
  if (gp->has_func && !gp->obj_initialized) {
    /* called for the first time; we need to set ihandle value to $obj_ref */
    dSP;
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(gp->obj_ref);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(dialog))));
    PUTBACK;

    call_method("ihandle",G_DISCARD);

    FREETMPS;
    LEAVE;

    gp->obj_initialized = 1;
  }
  if (gp->has_func) {
    dSP;
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(gp->obj_ref);
    XPUSHs(sv_2mortal(newSViv(param_index)));
    PUTBACK;

    count = call_sv(gp->func_ref,G_SCALAR);

    SPAGAIN;

    if (count != 1) croak("Error: GetParam's action has not returned single scalar value!\n");
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  return ret;
}

#define MY_CXT_KEY "IUP::Internal::LibraryIup::_guts" XS_VERSION

typedef struct {
    SV* idle_action;
    /* maybe more in the future */
} my_cxt_t;
START_MY_CXT;

int cb_ldestroy(Ihandle *ih) {
  fprintf(stderr, "destroying id=%p\n", ih);
}

static int cb_idle_action() {  
  dMY_CXT;
  dSP;
  int count, ret;
  
  ENTER;
  SAVETMPS;
    
  PUSHMARK(SP);  
  count = call_sv(MY_CXT.idle_action,G_SCALAR|G_NOARGS);

  SPAGAIN;

  if (count != 1) croak("Error: Idle's action has not returned single scalar value!\n");
  ret = POPi;

  PUTBACK;

  FREETMPS;
  LEAVE;

  return ret;
}


#include "Callback.c.inc"
#include "Canvas.c.inc"

MODULE = IUP        PACKAGE = IUP

#XXX-TODO move some functions from IUP.pm here

INCLUDE: Callback.xs.inc
INCLUDE: Canvas.xs.inc
INCLUDE: Canvas_Bitmap.xs.inc
INCLUDE: Canvas_Palette.xs.inc
INCLUDE: Canvas_Pattern.xs.inc
INCLUDE: Canvas_Stipple.xs.inc 
INCLUDE: Canvas_InternalServerImage.xs.inc

MODULE = IUP::Internal::LibraryIup        PACKAGE = IUP::Internal::LibraryIup

BOOT:
    {
        MY_CXT_INIT;
        MY_CXT.idle_action = newSVsv(&PL_sv_undef);
    }

void
CLONE(...)
    CODE:
    {
        MY_CXT_CLONE;
        MY_CXT.idle_action = newSVsv(&PL_sv_undef);
    }

################################################################################
void
_SetIdle(func)
                SV* func;
        PPCODE:
        {
                dMY_CXT;
                XPUSHs(sv_2mortal(newSVsv(MY_CXT.idle_action))); /* return the old value */
                SvSetSV(MY_CXT.idle_action, func);
                if (SvOK(func)) {
                  IupSetFunction("IDLE_ACTION", (Icallback)cb_idle_action);
                }
                else {
                  IupSetFunction("IDLE_ACTION", (Icallback)NULL);
                }
        }

################################################################################ iup.h

#### Original C function from <iup.h>
# void IupClose (void);
void
_IupClose()
        CODE:
                IupClose();

#### Original C function from <iup.h>
# IupOpen(NULL, NULL);
int
_IupOpen()
        CODE:
                RETVAL = IupOpen(NULL,NULL);
                IupSetGlobal("UTF8MODE", "YES");
                IupSetGlobal("UTF8MODE_FILE", "YES");
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupImageLibOpen (void);
void
_IupImageLibOpen()
        CODE:
#ifdef HAVELIB_IUPIMGLIB
                IupImageLibOpen();
#endif

#### Original C function from <iup.h>
# int IupMainLoop (void);
int
_IupMainLoop()
        CODE:
                RETVAL = IupMainLoop();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupLoopStep (void);
int
_IupLoopStep()
        CODE:
                RETVAL = IupLoopStep();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupLoopStepWait (void);
int
_IupLoopStepWait()
        CODE:
                RETVAL = IupLoopStepWait();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupMainLoopLevel (void);
int
_IupMainLoopLevel()
        CODE:
                RETVAL = IupMainLoopLevel();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupFlush (void);
void
_IupFlush()
        CODE:
                IupFlush();

#### Original C function from <iup.h>
# void IupExitLoop (void);
void
_IupExitLoop()
        CODE:
                IupExitLoop();

#### Original C function from <iup.h>
# void IupUpdate (Ihandle* ih);
void
_IupUpdate(ih)
                Ihandle* ih;
        CODE:
                IupUpdate(ih);

#### Original C function from <iup.h>
# void IupUpdateChildren(Ihandle* ih);
void
_IupUpdateChildren(ih)
                Ihandle* ih;
        CODE:
                IupUpdateChildren(ih);

#### Original C function from <iup.h>
# void IupRedraw (Ihandle* ih, int children);
void
_IupRedraw(ih,children)
                Ihandle* ih;
                int children;
        CODE:
                IupRedraw(ih,children);

#### Original C function from <iup.h>
# void IupRefresh (Ihandle* ih);
void
_IupRefresh(ih)
                Ihandle* ih;
        CODE:
                IupRefresh(ih);

#### Original C function from <iup.h>
# void IupRefreshChildren(Ihandle *ih);
void
_IupRefreshChildren(ih)
                Ihandle* ih;
        CODE:
                IupRefreshChildren(ih);

#### Original C function from <iup.h>
# int IupHelp (const char* url);
int
_IupHelp(url)
                char* url;
        CODE:
                RETVAL = IupHelp(url);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupLoad (const char *filename);
char*
_IupLoad(filename)
                const char* filename;
        CODE:
                RETVAL = IupLoad(filename);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupLoadBuffer (const char *buffer);
char*
_IupLoadBuffer(buffer)
                char* buffer;
        CODE:
                RETVAL = IupLoadBuffer(buffer);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupVersion (void);
char*
_IupVersion()
        CODE:
                RETVAL = IupVersion();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupVersionDate (void);
char*
_IupVersionDate()
        CODE:
                RETVAL = IupVersionDate();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupVersionNumber (void);
int
_IupVersionNumber()
        CODE:
                RETVAL = IupVersionNumber();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupSetLanguage (const char *lng);
void
_IupSetLanguage(lng)
                char* lng;
        CODE:
                IupSetLanguage(lng);

#### Original C function from <iup.h>
# char* IupGetLanguage (void);
char*
_IupGetLanguage()
        CODE:
                RETVAL = IupGetLanguage();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupDestroy (Ihandle* ih);
void
_IupDestroy(ih)
                Ihandle* ih;
        CODE:
                IupDestroy(ih);

#### Original C function from <iup.h>
# void IupDetach (Ihandle* child);
void
_IupDetach(child)
                Ihandle* child;
        CODE:
                IupDetach(child);

#### Original C function from <iup.h>
# Ihandle* IupAppend (Ihandle* ih, Ihandle* child);
Ihandle*
_IupAppend(ih,child)
                Ihandle* ih;
                Ihandle* child;
        CODE:
                RETVAL = IupAppend(ih,child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupInsert (Ihandle* ih, Ihandle* ref_child, Ihandle* child);
Ihandle*
_IupInsert(ih,ref_child,child)
                Ihandle* ih;
                Ihandle* ref_child;
                Ihandle* child;
        CODE:
                RETVAL = IupInsert(ih,ref_child,child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetChild (Ihandle* ih, int pos);
Ihandle*
_IupGetChild(ih,pos)
                Ihandle* ih;
                int pos;
        CODE:
                RETVAL = IupGetChild(ih,pos);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupGetChildPos (Ihandle* ih, Ihandle* child);
int
_IupGetChildPos(ih,child)
                Ihandle* ih;
                Ihandle* child;
        CODE:
                RETVAL = IupGetChildPos(ih,child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupGetChildCount(Ihandle* ih);
int
_IupGetChildCount(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetChildCount(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetNextChild (Ihandle* ih, Ihandle* child);
Ihandle*
_IupGetNextChild(ih,child)
                Ihandle* ih;
                Ihandle* child;
        CODE:                
                RETVAL = IupGetNextChild(ih,child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetBrother (Ihandle* ih);
Ihandle*
_IupGetBrother(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetBrother(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetParent (Ihandle* ih);
Ihandle*
_IupGetParent(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetParent(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetDialog (Ihandle* ih);
Ihandle*
_IupGetDialog(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetDialog(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetDialogChild(Ihandle* ih, const char* name);
Ihandle*
_IupGetDialogChild(ih,name)
                Ihandle* ih;
                const char* name;
        CODE:
                RETVAL = IupGetDialogChild(ih,name);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
#NOTE: changed between iup3.2 and iup 3.3
# int IupReparent(Ihandle* child, Ihandle* new_parent, Ihandle* ref_child);
int
_IupReparent(ih,new_parent,ref_child)
                Ihandle* ih;
                Ihandle* new_parent;
                Ihandle* ref_child;
        CODE:
                RETVAL = IupReparent(ih,new_parent,ref_child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupPopup (Ihandle* ih, int x, int y);
int
_IupPopup(ih,x,y)
                Ihandle* ih;
                int x;
                int y;
        CODE:
                RETVAL = IupPopup(ih,x,y);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupShow (Ihandle* ih);
int
_IupShow(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupShow(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupShowXY (Ihandle* ih, int x, int y);
int
_IupShowXY(ih,x,y)
                Ihandle* ih;
                int x;
                int y;
        CODE:
                RETVAL = IupShowXY(ih,x,y);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupHide (Ihandle* ih);
int
_IupHide(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupHide(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupMap (Ihandle* ih);
int
_IupMap(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupMap(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupUnmap (Ihandle *ih);
void
_IupUnmap(ih)
                Ihandle* ih;
        CODE:
                IupUnmap(ih);

#### Original C function from <iup.h>
# void IupStoreAttribute(Ihandle* ih, const char* name, const char* value);
void
_IupStoreAttribute(ih,name,value)
                Ihandle* ih;
                const char* name;
                const char* value;
        CODE:
                IupStoreAttribute(ih,name,value); /* XXX-HANDLE-UTF8 */

#### Original C function from <iup.h>
# void IupStoreAttributeId(Ihandle *ih, const char *name, int id, const char *value);
void
_IupStoreAttributeId(ih,name,id,value)
                Ihandle* ih;
                const char* name;
                int id;
                const char* value;
        CODE:
                IupStoreAttributeId(ih,name,id,value); /* XXX-HANDLE-UTF8 */

#### Original C function from <iup.h>
# void  IupStoreAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
void
_IupStoreAttributeId2(ih,name,lin,col,value)
                Ihandle* ih;
                const char* name;
                int lin;
                int col;
                const char* value;
        CODE:
                IupStoreAttributeId2(ih,name,lin,col,value); /* XXX-HANDLE-UTF8 */

#### Original C function from <iup.h>
# char* IupGetAttribute (Ihandle* ih, const char* name);
SV*
_IupGetAttribute(ih,name)
                Ihandle* ih;
                const char* name;
        CODE:
                char *v = IupGetAttribute(ih,name);
                RETVAL = (v==NULL) ? newSVpvn(NULL, 0) : newSVpvn_utf8(v, strlen(v), 1);
        OUTPUT:
                RETVAL

Ihandle*
_IupGetAttributeIH(ih,name)
                Ihandle* ih;
                const char* name;
        CODE:
                RETVAL = (Ihandle*)IupGetAttribute(ih,name);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char *IupGetAttributeId(Ihandle *ih, const char *name, int id);
SV*
_IupGetAttributeId(ih,name,id)
                Ihandle* ih;
                const char* name;
                int id;
        CODE:
                char *v = IupGetAttributeId(ih,name,id);
                RETVAL = (v==NULL) ? newSVpvn(NULL, 0) : newSVpvn_utf8(v, strlen(v), 1);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupGetAttributeId2(Ihandle* ih, const char* name, int lin, int col);
SV*
_IupGetAttributeId2(ih,name,lin,col)
                Ihandle* ih;
                const char* name;
                int lin;
                int col;
        CODE:
                char *v = IupGetAttributeId2(ih,name,lin,col);
                RETVAL = (v==NULL) ? newSVpvn(NULL, 0) : newSVpvn_utf8(v, strlen(v), 1);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupResetAttribute(Ihandle *ih, const char* name);
void
_IupResetAttribute(ih,name)
                Ihandle* ih;
                const char* name;
        CODE:
                IupResetAttribute(ih,name);

#### Original C function from <iup.h>
# void IupStoreGlobal (const char* name, const char* value);
void
_IupStoreGlobal(name,value)
                char* name;
                char* value;
        CODE:
                IupStoreGlobal(name,value);

#### Original C function from <iup.h>
# char* IupGetGlobal (const char* name);
char*
_IupGetGlobal(name)
                char* name;
        CODE:
                RETVAL = IupGetGlobal(name);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSetFocus (Ihandle* ih);
Ihandle*
_IupSetFocus(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupSetFocus(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetFocus (void);
Ihandle*
_IupGetFocus()
        CODE:
                RETVAL = IupGetFocus();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupPreviousField (Ihandle* ih); 
Ihandle*
_IupPreviousField(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupPreviousField(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupNextField (Ihandle* ih);
Ihandle*
_IupNextField(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupNextField(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGetHandle (const char *name);
Ihandle*
_IupGetHandle(name)
                char* name;
        CODE:
                RETVAL = IupGetHandle(name);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSetHandle (const char *name, Ihandle* ih);
Ihandle*
_IupSetHandle(name,ih)
                const char* name;
                Ihandle* ih;
        CODE:
                RETVAL = IupSetHandle(name,ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupGetName (Ihandle* ih);
char*
_IupGetName(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetName(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupSetAttributeHandle(Ihandle* ih, const char* name, Ihandle* ih_named);
void
_IupSetAttributeHandle(ih,name,ih_named)
                Ihandle* ih;
                const char* name;
                Ihandle* ih_named;
        CODE:
                //xxx warn("#XS# ih='%p' name='%s' ih_named='%p'", ih, name, ih_named);
                IupSetAttributeHandle(ih,name,ih_named);

#### Original C function from <iup.h>
# Ihandle* IupGetAttributeHandle(Ihandle* ih, const char* name);
Ihandle*
_IupGetAttributeHandle(ih,name)
                Ihandle* ih;
                const char* name;
        CODE:
                RETVAL = IupGetAttributeHandle(ih,name);                
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupGetClassName(Ihandle* ih);
char*
_IupGetClassName(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetClassName(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# char* IupGetClassType(Ihandle* ih);
char*
_IupGetClassType(ih)
                Ihandle* ih;
        CODE:
                RETVAL = IupGetClassType(ih);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupCopyClassAttributes(Ihandle* src_ih, Ihandle* dst_ih);
void
_IupCopyClassAttributes(src_ih,dst_ih)
                Ihandle* src_ih;
                Ihandle* dst_ih;
        CODE:
                IupCopyClassAttributes(src_ih,dst_ih);

#### Original C function from <iup.h>
# int IupGetAllClasses(char** names, int max_n);
void
_IupGetAllClasses(...)
        INIT:
                int i, rv, count, max_n;
                char** list = NULL;                  
        PPCODE:
                max_n = myST2INT(1);
                count = IupGetAllClasses(NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetAllClasses(list,count);
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<count; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# void IupSaveClassAttributes(Ihandle* ih);
void
_IupSaveClassAttributes(ih)
                Ihandle* ih;
        CODE:
                IupSaveClassAttributes(ih);

#### Original C function from <iup.h>
# void IupSetClassDefaultAttribute(const char* classname, const char *name, const char* value);
void
_IupSetClassDefaultAttribute(classname,name,value)
                char* classname;
                char* name;
                char* value;
        CODE:
                IupSetClassDefaultAttribute(classname,name,value);

#### Original C function from <iup.h>
# Ihandle* IupFill (void);
Ihandle*
_IupFill()
        CODE:
                RETVAL = IupFill();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupRadio (Ihandle* child);
Ihandle*
_IupRadio(child)
                Ihandle* child;
        CODE:
                RETVAL = IupRadio(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupNormalizer (Ihandle* ih_first, ...);
Ihandle*
_IupNormalizer(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupNormalizerv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupNormalizer(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupNormalizer(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupVbox (Ihandle* child, ...);
Ihandle*
_IupVbox(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupVboxv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupVbox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupVbox(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupZbox (Ihandle* child, ...);
Ihandle*
_IupZbox(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupZboxv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupZbox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupZbox(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupHbox (Ihandle* child,...);
Ihandle*
_IupHbox(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupHboxv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupHbox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupHbox(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupCbox (Ihandle* child, ...);
Ihandle*
_IupCbox(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupCboxv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupCbox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupCbox(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSbox (Ihandle *child);
Ihandle*
_IupSbox(child)
                Ihandle* child;
        CODE:
                RETVAL = IupSbox(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSplit (Ihandle* child1, Ihandle* child2);
Ihandle*
_IupSplit(child1,child2)
                Ihandle* child1;
                Ihandle* child2;
        CODE:
                RETVAL = IupSplit(child1,child2);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupFrame (Ihandle* child);
Ihandle*
_IupFrame(child)
                Ihandle* child;
        CODE:
                RETVAL = IupFrame(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupImage (int width, int height, const unsigned char *pixmap);
Ihandle*
_IupImage(width,height,pixmap)
                int width;
                int height;
                SV * pixmap;
        CODE:
                RETVAL = IupImage(width,height,(unsigned char *)SvPVbyte_nolen(pixmap));
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupImageRGB (int width, int height, const unsigned char *pixmap);
Ihandle*
_IupImageRGB(width,height,pixmap)
                int width;
                int height;
                SV * pixmap;
        CODE:
                RETVAL = IupImageRGB(width,height,(unsigned char *)SvPVbyte_nolen(pixmap));
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupImageRGBA (int width, int height, const unsigned char *pixmap);
Ihandle*
_IupImageRGBA(width,height,pixmap)
                int width;
                int height;
                SV * pixmap;
        CODE:
                RETVAL = IupImageRGBA(width,height,(unsigned char *)SvPVbyte_nolen(pixmap));
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupItem (const char* title, const char* action);
Ihandle*
_IupItem(title,action)
                const char* title;
                const char* action;
        CODE:
                RETVAL = IupItem(title,action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSubmenu (const char* title, Ihandle* child);
Ihandle*
_IupSubmenu(title,child)
                const char* title;
                Ihandle* child;
        CODE:
                RETVAL = IupSubmenu(title,child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSeparator (void);
Ihandle*
_IupSeparator()
        CODE:
                RETVAL = IupSeparator();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupMenu (Ihandle* child,...);
Ihandle*
_IupMenu(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupMenuv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupMenu(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupMenu(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupButton (const char* title, const char* action);
Ihandle*
_IupButton(title,action)
                const char* title;
                const char* action;
        CODE:
                RETVAL = IupButton(title,action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupFlatButton(const char *title);
Ihandle*
_IupFlatButton(title)
                const char* title;
        CODE:
                RETVAL = IupFlatButton(title);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupCanvas (const char* action);
Ihandle*
_IupCanvas(action)
                const char* action;
        CODE:
                RETVAL = IupCanvas(action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupDialog (Ihandle* child);
Ihandle*
_IupDialog(child)
                Ihandle* child;
        CODE:
                RETVAL = IupDialog(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupUser (void);
Ihandle*
_IupUser()
        CODE:
                RETVAL = IupUser();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupAnimatedLabel (Ihandle* animation);
Ihandle*
_IupAnimatedLabel(animation)
                Ihandle* animation;
        CODE:
                RETVAL = IupAnimatedLabel(animation);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupLabel (const char* title);
Ihandle*
_IupLabel(title)
                const char* title;
        CODE:
                RETVAL = IupLabel(title);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupList (const char* action);
Ihandle*
_IupList(action)
                const char* action;
        CODE:
                RETVAL = IupList(action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupText (const char* action);
Ihandle*
_IupText(action)
                const char* action;
        CODE:
                RETVAL = IupText(action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupToggle (const char* title, const char* action);
Ihandle*
_IupToggle(title,action)
                const char* title;
                const char* action;
        CODE:
                RETVAL = IupToggle(title,action);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupLink(const char *url, const char * title);
Ihandle*
_IupLink(url,title)
                const char* url;
                const char* title;
        CODE:
                RETVAL = IupLink(url,title);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupExpander(Ihandle* child);
Ihandle*
_IupExpander(child)
                Ihandle* child;
        CODE:
                RETVAL = IupExpander(child);
        OUTPUT:
                RETVAL


#### Original C function from <iup.h>
# Ihandle* IupDetachBox(Ihandle* child);
Ihandle*
_IupDetachBox(child)
                Ihandle* child;
        CODE:
                RETVAL = IupDetachBox(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupBackgroundBox(Ihandle* child);
Ihandle*
_IupBackgroundBox(child)
                Ihandle* child;
        CODE:
                RETVAL = IupBackgroundBox(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupScrollBox(Ihandle* child);
Ihandle*
_IupScrollBox(child)
                Ihandle* child;
        CODE:
                RETVAL = IupScrollBox(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupGridBoxv(Ihandle **children);
Ihandle*
_IupGridBox(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupGridBoxv(pointers);
                  free(pointers);
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupGridBox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupGridBox(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupTimer (void);
Ihandle*
_IupTimer()
        CODE:
                RETVAL = IupTimer();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupClipboard (void);
Ihandle*
_IupClipboard()
        CODE:
                RETVAL = IupClipboard();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupProgressBar(void);
Ihandle*
_IupProgressBar()
        CODE:
                RETVAL = IupProgressBar();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupDatePick();
Ihandle*
_IupDatePick()
        CODE:
                RETVAL = IupDatePick();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupCalendar(void);
Ihandle*
_IupCalendar()
        CODE:
                RETVAL = IupCalendar();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupVal (const char *type);
Ihandle*
_IupVal(type)
                char* type;
        CODE:
                RETVAL = IupVal(type);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupTabs (Ihandle* child, ...);
Ihandle*
_IupTabs(...)
        PREINIT:
                int i;
        CODE:
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupTabsv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupTabs(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupTabs(NULL);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupTree (void);
Ihandle*
_IupTree()
        CODE:
                RETVAL = IupTree();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSpin (void);
Ihandle*
_IupSpin()
        CODE:
                RETVAL = IupSpin();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupSpinbox (Ihandle* child);
Ihandle*
_IupSpinbox(child)
                Ihandle* child;
        CODE:
                RETVAL = IupSpinbox(child);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupSaveImageAsText(Ihandle* ih, const char* file_name, const char* format, const char* name);
int
_IupSaveImageAsText(ih,file_name,format,name)
                Ihandle* ih;
                const char* file_name;
                const char* format;
                const char* name;
        CODE:
                RETVAL = IupSaveImageAsText(ih,file_name,format,name);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void IupTextConvertLinColToPos(Ihandle* ih, int lin, int col, int *pos);
void
_IupTextConvertLinColToPos(ih,lin,col,pos)
                Ihandle* ih;
                int lin;
                int col;
        INIT:
                int pos;
        PPCODE:
                IupTextConvertLinColToPos(ih,lin,col,&pos);
                XPUSHs(sv_2mortal(newSViv(pos)));

#### Original C function from <iup.h>
# void IupTextConvertPosToLinCol(Ihandle* ih, int pos, int *lin, int *col);
void
_IupTextConvertPosToLinCol(ih,pos)
                Ihandle* ih;
                int pos;
        INIT:
                int lin;
                int col;
        PPCODE:
                IupTextConvertPosToLinCol(ih,pos,&lin,&col);
                XPUSHs(sv_2mortal(newSViv(lin)));
                XPUSHs(sv_2mortal(newSViv(col)));


#### Original C function from <iup.h>
# int IupConvertXYToPos(Ihandle* ih, int x, int y);
int
_IupConvertXYToPos(ih,x,y)
                Ihandle* ih;
                int x;
                int y;
        CODE:
                RETVAL = IupConvertXYToPos(ih,x,y);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupTreeSetUserId(Ihandle* ih, int id, void* userid);
int
_IupTreeSetUserId(ih,id,userid)
                Ihandle* ih;
                int id;
                SV* userid;
        CODE:
                RETVAL = IupTreeSetUserId(ih,id,INT2PTR(void*, SvIVX(userid)));
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# void* IupTreeGetUserId(Ihandle* ih, int id);
void
_IupTreeGetUserId(ih,id)
                Ihandle* ih;
                int id;
        INIT:
                void* ptr;
        PPCODE:
                ptr = IupTreeGetUserId(ih,id);
                if (ptr==NULL) XPUSHs(sv_2mortal(newSVpv(NULL,0))); /* undef xxxcheckthis */ 
                else XPUSHs(sv_2mortal(newSViv(PTR2IV(ptr))));

#### Original C function from <iup.h>
# int IupTreeGetId(Ihandle* ih, void *userid);
int
_IupTreeGetId(ih,userid)
                Ihandle* ih;
                SV* userid;
        CODE:
                RETVAL = IupTreeGetId(ih,INT2PTR(void*, SvIVX(userid)));
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupLayoutDialog(Ihandle* dialog);
Ihandle*
_IupLayoutDialog(dialog)
                Ihandle* dialog;
        CODE:
                RETVAL = IupLayoutDialog(dialog);
        OUTPUT:
                RETVAL


#### Original C function from <iup.h>
# Ihandle* IupFileDlg(void);
Ihandle*
_IupFileDlg()
        CODE:
                RETVAL = IupFileDlg();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupMessageDlg(void);
Ihandle*
_IupMessageDlg()
        CODE:
                RETVAL = IupMessageDlg();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupColorDlg(void);
Ihandle*
_IupColorDlg()
        CODE:
                RETVAL = IupColorDlg();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupFontDlg(void);
Ihandle*
_IupFontDlg()
        CODE:
                RETVAL = IupFontDlg();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# Ihandle* IupProgressDlg(void);
Ihandle*
_IupProgressDlg()
        CODE:
                RETVAL = IupProgressDlg();
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupGetFile(char *arq);
void
_IupGetFile(arq)
                char* arq;
        INIT:
                int rv;
                char tmp[MAXPATHLEN];
                /* somehow handle the situation when arq is longer then MAXPATHLEN-1 */
                tmp[MAXPATHLEN-1] = 0;
                if (arq) strncpy(tmp,arq,MAXPATHLEN-1);
        PPCODE:
                rv = IupGetFile(tmp);
                /*warn("rv=%d a=%s", rv, tmp);*/
                /* gonna return array: (retval, filename) */
                XPUSHs(sv_2mortal(newSViv(rv)));
                if (rv == -1)
                  XPUSHs(sv_2mortal(newSVpv(NULL,0))); /* undef */
                else
                  XPUSHs(sv_2mortal(newSVpvn_utf8(tmp, strlen(tmp), 1)));  /* XPUSHs(sv_2mortal(newSVpv(tmp,0))); */

#### Original C function from <iup.h>
# void IupMessage(const char *title, const char *msg);
void
_IupMessage(title,msg)
                const char* title;
                const char* msg;
        CODE:
                IupMessage(title,msg);

#### Original C function from <iup.h>
# int IupAlarm(const char *title, const char *msg, const char *b1, const char *b2, const char *b3);
int
_IupAlarm(title,msg,b1,b2,b3)
                const char* title;
                const char* msg;
                const char* b1;
                const char* b2;
                const char* b3;
        CODE:
                RETVAL = IupAlarm(title,msg,b1,b2,b3);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupGetText(const char* title, char* text);
void
_IupGetText(title,text)
                char* title;
                char* text;
        INIT:
                int rv;
                char newtext[10001]; /* xxx hardcoded length */ 
        PPCODE:
                strncpy(newtext, text, 10000);
                newtext[10000] = 0;
                rv = IupGetText(title,newtext,10000);
                /* gonna return text or undef */
                XPUSHs(sv_2mortal(newSVpvn_utf8(newtext, strlen(newtext), 1))); /* XPUSHs(sv_2mortal(newSVpv(newtext,0))); */

#### Original C function from <iup.h>
# int IupGetColor(int x, int y, unsigned char* r, unsigned char* g, unsigned char* b);
void
_IupGetColor(x,y,r,g,b)
                int x;
                int y;
                unsigned char r;
                unsigned char g;
                unsigned char b;
        INIT:
                int rv;
                unsigned char newr = r; /* xxx check this assignment newr=r or newr=*r ? */
                unsigned char newg = g;
                unsigned char newb = b;
        PPCODE:
                rv = IupGetColor(x,y,&newr,&newg,&newb);
                if (rv == 1) {
                  /* gonna return array: (newr, newg, newb) */
                  XPUSHs(sv_2mortal(newSViv(newr)));
                  XPUSHs(sv_2mortal(newSViv(newg)));
                  XPUSHs(sv_2mortal(newSViv(newb)));
                }
                else {
                  /* gonna return array: (undef, undef, undef) */
                  /* xxxcheckthis is 3x udef necessary? */
                  XPUSHs(&PL_sv_undef);
                  XPUSHs(&PL_sv_undef);
                  XPUSHs(&PL_sv_undef);
                }

#### Original C function from <iup.h>
# int IupGetParam(const char* title, Iparamcb action, void* user_data, const char* format,...);
void
_IupGetParam(title,action,action_data,format,...)
                char* title;
                SV* action;
                SV* action_data;
                char* format;
        INIT:
                getparam_data gp;
                void* gp_user_data = (void*)&gp;
                int rv, i, size, line_size = 0;
                int param_extra, param_count;                 
                void* param_data[50]; /* xxx why 50? */
                char param_type[50];
                const char* f = format;
                const char* s;
                int varparam = 4; /* position in variable param list */
                
                param_count = iupGetParamCount(format, &param_extra);
                memset(param_data, 0, sizeof(void*)*50);
                memset(param_type, 0, sizeof(char)*50);
                
                /* warn param count mismatch; however no warning if absolutely no defaults given */
                if(param_count != items-4 && items > 4 && param_count > 0) warn("Warning: GetParam() param count mismatch (got %d, expected %d)",items-4,param_count);                  
                
                for (i = 0; i < param_count; i++) {
                  char t = iupGetParamType(f, &line_size);
                  if (t == 't') { /* if separator */
                    f += line_size;
                    i--; /* compensate next increment */
                    continue;
                  }
                  
                  switch(t) {
                    case 'b':
                    case 'i':
                    case 'l':
                      param_data[i] = malloc(sizeof(int));
                      if (varparam > items-1) {
                        // xxx warn("FATAL.i!!! cur=%d items=%d", varparam, items);
                        *(int*)(param_data[i]) = 0;
                      }
                      else *(int*)(param_data[i]) = SvIV(ST(varparam));
                      varparam++;
                      break;
                    case 'a':
                    case 'r':
                      param_data[i] = malloc(sizeof(float));
                      if (varparam > items-1) {
                        // xxx warn("FATAL.f!!! cur=%d items=%d", varparam, items);
                        *(float*)(param_data[i]) = 0.0;
                      }
                      else *(float*)(param_data[i]) = SvNV(ST(varparam));
                      varparam++;
                      break;
                    case 'f':
                    case 'c':
                    case 's':
                    case 'm':
                      if (varparam > items-1)
                        s = "";
                      else
                        s = SvPV_nolen(ST(varparam));
                      varparam++;
                      size = strlen(s);
                      param_data[i] = malloc(10240); /* XXX hardcoded in iup - not nice */
                      if (size > 10240) {
                        warn("Warning: initial string size %d too big, truncating", size);
                        size = 1024-1;
                      }
                      memcpy(param_data[i], s, size+1);
                      break;
                  }

                  param_type[i] = t;
                  f += line_size;
                }
                
        PPCODE:
                gp.has_func = 0;
                if (SvOK(action)) {
                  gp.has_func = 1;
                  gp.obj_initialized = 0;
                  gp.func_ref = action;
                  gp.obj_ref = action_data;
                }
                
                rv = IupGetParamv(title, cb_param_action, gp_user_data, format, param_count, param_extra, param_data);

                /* gonna return array: (retval, newval1, newval2, ...) */
                XPUSHs(sv_2mortal(newSViv(rv)));
                for (i = 0; i < param_count; i++) {
                  switch(param_type[i]) {
                    case 'b':
                    case 'i':
                    case 'l':
                      XPUSHs(sv_2mortal(newSViv( *(int*)(param_data[i]) )));
                      break;
                    case 'a':
                    case 'r':
                      XPUSHs(sv_2mortal(newSVnv( *(float*)(param_data[i]) )));
                      break;
                    case 'f':
                    case 'c':
                    case 's':
                    case 'm':
                      XPUSHs(sv_2mortal(newSVpvn_utf8(param_data[i], strlen(param_data[i]), 1)));  /* XPUSHs(sv_2mortal(newSVpv( param_data[i], 0 ))); */
                      break;
                  }
                }
                for (i = 0; i < param_count; i++) free(param_data[i]);

#### Original C function from <iup.h>
# int IupListDialog(int type, const char *title, int size, const char** list, int op, int max_col, int max_lin, int* marks);
void
_IupListDialog_single(title,list,SV_op,SV_max_lin,SV_max_col)
                char *title;
                SV* list;
                SV* SV_op;
                SV* SV_max_lin;
                SV* SV_max_col;
        INIT:
                int i, rv, op, max_col, max_lin;
                int items = -1;
                const char** i_list = NULL;                  
                STRLEN l;
        PPCODE:
                /* convert undef to 0 */
                op = (SvIOK(SV_op)) ? SvIVX(SV_op) : 0;
                /* convert undef to -1 */
                max_col = (SvIOK(SV_max_col)) ? SvIVX(SV_max_col) : -1;
                max_lin = (SvIOK(SV_max_lin)) ? SvIVX(SV_max_lin) : -1;
                
                if ((!SvROK(list)) || (SvTYPE(SvRV(list)) != SVt_PVAV) || ((items = av_len((AV *)SvRV(list))) < 0)) {
                  warn("Warning: invalid 'list' argument of ListDialog()");
                  XSRETURN_UNDEF;
                }                
                items++;
                i_list = malloc( (items) * sizeof(void*) );                  
                
                /* create i_list array */
                for(i=0; i<items; i++) i_list[i] = SvPV(*av_fetch((AV *)SvRV(list), i, 0), l);
                
                /* xxx hack: converting perl's 0-based index to iup's 1-based index*/
                if (op>=0) op++;

                /* call IUP function */
                rv = IupListDialog(1,title,items,i_list,op,max_col,max_lin,NULL);
                
                /* arrange return values */
                XPUSHs(sv_2mortal(newSViv(rv)));
                if (i_list != NULL) free(i_list);

#### Original C function from <iup.h>
# int IupListDialog(int type, const char *title, int size, const char** list, int op, int max_col, int max_lin, int* marks);
void
_IupListDialog_multi(title,list,marks,SV_max_lin,SV_max_col)
                char *title;
                SV* list;
                SV* marks;
                SV* SV_max_lin;
                SV* SV_max_col;
        INIT:
                int i, rv, max_col, max_lin;
                int items1 = -1, items2 = -1, items = -1;
                const char** i_list = NULL;                  
                int* i_marks = NULL;
                STRLEN l;
                AV* retmarks;
        PPCODE:
                /* convert undef to -1 */
                max_col = (SvIOK(SV_max_col)) ? SvIVX(SV_max_col) : -1;
                max_lin = (SvIOK(SV_max_lin)) ? SvIVX(SV_max_lin) : -1;

                if ((!SvROK(list)) || (SvTYPE(SvRV(list)) != SVt_PVAV) || ((items1 = av_len((AV *)SvRV(list))) < 0)) {
                  warn("Warning: invalid 'list' argument of ListDialog()");
                  XSRETURN_UNDEF;
                }

                if (SvOK(marks) && ((!SvROK(marks)) || (SvTYPE(SvRV(marks)) != SVt_PVAV) || ((items2 = av_len((AV *)SvRV(marks))) < 0))) {
                  warn("Warning: invalid 'marks' argument of ListDialog()");
                  XSRETURN_UNDEF;
                }
                
                items = items1+1;
                i_marks = malloc( (items) * sizeof(int) );
                i_list = malloc( (items) * sizeof(void*) );                  
                
                /* create i_marks array */
                if (items2 >= 0) {
                  if (items1 != items2)
                    warn("Warning: 'list' and 'marks' arrays have different size(%d vs. %d) in ListDialog()",items1+1, items2+1);
                  if (items2 > items1)
                    items2 = items1;
                  for(i=0; i<=items2; i++) i_marks[i]= SvIV(*av_fetch((AV *)SvRV(marks), i, 0));
                  for(   ; i<=items1; i++) i_marks[i]= 0;
                }

                /* create i_list array */
                for(i=0; i<items; i++) i_list[i] = SvPV(*av_fetch((AV *)SvRV(list), i, 0), l);
                
                /* call IUP function */
                rv = IupListDialog(2,title,items,i_list,-1,max_col,max_lin,i_marks);                
                
                //xxx /* return error code */
                //xxx XPUSHs(sv_2mortal(newSViv(rv)));
        
                /* arrange return values - returning array */
                if (rv < 0) { /* cancel */
                  for(i=0; i<items; i++) XPUSHs(sv_2mortal(newSViv(rv)));
                }
                else {
                  for(i=0; i<items; i++) XPUSHs(sv_2mortal(newSViv(i_marks[i])));
                }
                
                /* arrange return values - returning array ref*/
                //xxx retmarks = newAV();
                //xxx for(i=0; i<items; i++) av_store(retmarks, i, newSViv(i_marks[i]));                  
                //xxx XPUSHs(sv_2mortal(retmarks);
                
                if (i_list != NULL) free(i_list);
                if (i_marks != NULL) free(i_marks);

#### Original C function from <iup.h>
#int IUP::GetClassCallbacks(const char* classname, char** names, int max_n);
void
_IupGetClassCallbacks(...)
        INIT:
                int i, rv, count, max_n;
                int items = -1;
                char* classname;
                char** list = NULL;                  
        PPCODE:
                classname = myST2STR(0);
                max_n = myST2INT(1);
                count = IupGetClassCallbacks(classname,NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetClassCallbacks(classname,list,count);
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<count; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# int IupGetAllNames(char** names, int max_n);
void
_IupGetAllNames(...)
        INIT:
                int i, rv, count, max_n;
                int items = -1;
                char** list = NULL;                  
        PPCODE:
                max_n = myST2INT(0);
                count = IupGetAllNames(NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetAllNames(list,count);
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<count; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# int IupGetAllDialogs(char** names, int max_n);
void
_IupGetAllDialogs(...)
        INIT:
                int i, rv, count, max_n;
                char** list = NULL;                  
        PPCODE:
                max_n = myST2INT(0);
                count = IupGetAllDialogs(NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetAllDialogs(list,count);
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<count; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# int IupGetClassAttributes(const char* classname, char** names, int max_n);
void
_IupGetClassAttributes(classname,...)
                const char* classname;
        INIT:
                int i, rv, count, max_n;
                char** list = NULL;                  
        PPCODE:
                max_n = myST2INT(1);
                count = IupGetClassAttributes(classname,NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetClassAttributes(classname,list,count);
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<count; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# int IupGetAllAttributes(Ihandle* ih, char** names, int max_n);
void
_IupGetAllAttributes(ih,...)
                Ihandle* ih;
        INIT:
                int i, rv, count, max_n;
                char** list = NULL;                  
        PPCODE:
                max_n = myST2INT(1);
                count = IupGetAllAttributes(ih,NULL,0);
                if (max_n > 0) count = max_n;
                list = malloc( count * sizeof(void*) );
                rv = IupGetAllAttributes(ih,list,count);
                #warn("[DEBUG.XS] rv=%d count=%d\n", rv, count); /* xxx why are these values different? */
                if(GIMME_V == G_ARRAY) {
                  for(i=0; i<rv; i++) XPUSHs(sv_2mortal(newSVpv(list[i],0)));
                }
                else {
                  XPUSHs(sv_2mortal(newSViv(rv)));
                }
                if (list != NULL) free(list);

#### Original C function from <iup.h>
# int IupRecordInput(const char* filename, int mode);
int
_IupRecordInput(filename,mode)
                const char* filename;
                int mode;
        CODE:
                RETVAL = IupRecordInput(filename,mode);
        OUTPUT:
                RETVAL

#### Original C function from <iup.h>
# int IupPlayInput(const char* filename);
int
_IupPlayInput(filename)
                const char* filename;
        CODE:
                RETVAL = IupPlayInput(filename);
        OUTPUT:
                RETVAL
                
################################################################################ iup_scintilla.h

# void IupScintillaOpen(void);
void
_IupScintillaOpen()
        CODE:
#ifdef HAVELIB_IUP_SCINTILLA
                IupScintillaOpen();
#endif


# Ihandle *IupScintilla(void);
Ihandle*
_IupScintilla()
        CODE:
#ifdef HAVELIB_IUP_SCINTILLA
                RETVAL = IupScintilla();
#else
                RETVAL = 0;
#endif
        OUTPUT:
                RETVAL

################################################################################ iupcontrols.h

#### Original C function from <iupcontrols.h>
# Ihandle* IupColorBrowser(void);
Ihandle*
_IupColorBrowser()
        CODE:
#ifdef HAVELIB_IUPCONTROLS        
                RETVAL = IupColorBrowser();
#else
                warn("Error: IUP was built without IupOleControl() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupDial(const char* type);
Ihandle*
_IupDial(type)
                char* type;
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupDial(type);
#else
                warn("Error: IUP was built without IupOleControl() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# int IupControlsOpen(void);
int
_IupControlsOpen()
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupControlsOpen();
#else
                RETVAL = 0;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupColorbar(void);
Ihandle*
_IupColorbar()
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupColorbar();
#else
                warn("Error: IUP was built without IupColorbar() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupCells(void);
Ihandle*
_IupCells()
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupCells();
#else
                warn("Error: IUP was built without IupCells() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupGauge(void);
Ihandle*
_IupGauge()
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupGauge();
#else
                warn("Error: IUP was built without IupGauge() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupMatrixList(void);
Ihandle*
_IupMatrixList()
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupMatrixList();
#else
                warn("Error: IUP was built without IupMatrixList() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function from <iupcontrols.h>
# Ihandle* IupMatrix(const char *action);
Ihandle*
_IupMatrix(action)
                char* action;
        CODE:
#ifdef HAVELIB_IUPCONTROLS
                RETVAL = IupMatrix(action);
#else
                warn("Error: IUP was built without IupMatrix() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

################################################################################ iupglcontrols.h

#### Original C function
# int IupGLControlsOpen(void);
void
_IupGLControlsOpen()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                IupGLControlsOpen();
#endif

#### Original C function
# Ihandle* IupGLCanvasBox(Ihandle* child, ...);
# Ihandle* IupGLCanvasBoxv(Ihandle** children);
Ihandle*
_IupGLCanvasBox(...)
        PREINIT:
                int i;
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                if (items>1) {
                  Ihandle** pointers = malloc( (items+1) * sizeof(void*) );                  
                  for(i=0; i<items; i++) pointers[i] = mySV2IHN(ST(i));
                  pointers[i] = NULL;
                  RETVAL = IupGLCanvasBoxv(pointers);
                  free(pointers);                  
                }
                else if (items==1) RETVAL = SvOK(ST(0)) ? IupGLCanvasBox(mySV2IHN(ST(0)), NULL) : NULL;
                else RETVAL = IupGLCanvasBox(NULL);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLSubCanvas(void);
Ihandle*
_IupGLSubCanvas()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLSubCanvas();
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLLabel(const char* title);
Ihandle*
_IupGLLabel(const char* title)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLLabel(title);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLSeparator(void);
Ihandle*
_IupGLSeparator()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLSeparator();
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLButton(const char* title);
Ihandle*
_IupGLButton(const char* title)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLButton(title);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLToggle(const char* title);
Ihandle*
_IupGLToggle(const char* title)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLToggle(title);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLLink(const char *url, const char * title);
Ihandle*
_IupGLLink(const char *url, const char * title)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLLink(url, title);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLProgressBar(void);
Ihandle*
_IupGLProgressBar()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLProgressBar();
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLVal(void);
Ihandle*
_IupGLVal()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLVal();
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLFrame(Ihandle* child);
Ihandle*
_IupGLFrame(Ihandle* child)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLFrame(child);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLExpander(Ihandle* child);
Ihandle*
_IupGLExpander(Ihandle* child)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLExpander(child);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLScrollBox(Ihandle* child);
Ihandle*
_IupGLScrollBox(Ihandle* child)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLScrollBox(child);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLSizeBox(Ihandle* child);
Ihandle*
_IupGLSizeBox(Ihandle* child)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLSizeBox(child);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLBackgroundBox(Ihandle* child);
Ihandle*
_IupGLBackgroundBox(Ihandle* child)
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLBackgroundBox(child);
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# Ihandle* IupGLText(void);
Ihandle*
_IupGLText()
        CODE:
#ifdef HAVELIB_IUPGLCONTROLS
                RETVAL = IupGLText();
#else
                warn("Error: IUP was built without IupGLControls support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

################################################################################ plots
INCLUDE: MglPlot.xs.inc
INCLUDE: PPlot.xs.inc
INCLUDE: Plot.xs.inc

################################################################################ iupole.h 

#### Original C function
# Ihandle *IupOleControl(const char* progid);
Ihandle*
_IupOleControl(progid)
                const char* progid;
        CODE:
#ifdef HAVELIB_IUPOLE
                RETVAL = IupOleControl(progid);
#else
                warn("Error: IUP was built without IupOleControl() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# int IupOleControlOpen(void);
int
_IupOleControlOpen()
        CODE:
#ifdef HAVELIB_IUPOLE
                RETVAL = IupOleControlOpen();
#else
                RETVAL = 0;
#endif
        OUTPUT:
                RETVAL

################################################################################ iupgl.h

#### Original C function from <.../iup/include/iupgl.h>
# void IupGLCanvasOpen(void);
void
_IupGLCanvasOpen()
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLCanvasOpen();
#endif

#### Original C function from <.../iup/include/iupgl.h>
# Ihandle *IupGLCanvas(const char *action);
Ihandle*
_IupGLCanvas(action)
                const char* action;
        CODE:
#ifdef HAVELIB_IUPGL
                RETVAL = IupGLCanvas(action);
#else
                warn("Error: IUP was built without IupGLCavnas() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# void IupGLMakeCurrent(Ihandle* ih);
void
_IupGLMakeCurrent(ih)
                Ihandle* ih;
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLMakeCurrent(ih);
#endif

#### Original C function
# int IupGLIsCurrent(Ihandle* ih);
int
_IupGLIsCurrent(ih)
                Ihandle* ih;
        CODE:
#ifdef HAVELIB_IUPGL
                RETVAL = IupGLIsCurrent(ih);
#else
                RETVAL = 0;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# void IupGLSwapBuffers(Ihandle* ih);
void
_IupGLSwapBuffers(ih)
                Ihandle* ih;
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLSwapBuffers(ih);
#endif

#### Original C function
# void IupGLPalette(Ihandle* ih, int index, float r, float g, float b);
void
_IupGLPalette(ih,index,r,g,b)
                Ihandle* ih;
                int index;
                float r;
                float g;
                float b;
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLPalette(ih,index,r,g,b);
#endif

#### Original C function
# void IupGLUseFont(Ihandle* ih, int first, int count, int list_base);
void
_IupGLUseFont(ih,first,count,list_base)
                Ihandle* ih;
                int first;
                int count;
                int list_base;
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLUseFont(ih,first,count,list_base);
#endif

#### Original C function
# void IupGLWait(int gl);
void
_IupGLWait(gl)
                int gl;
        CODE:
#ifdef HAVELIB_IUPGL
                IupGLWait(gl);
#endif

################################################################################ iupim.h

#### Original C function
# Ihandle* IupLoadImage(const char* file_name);
Ihandle*
_IupLoadImage(file_name)
                const char* file_name;
        CODE:
#ifdef HAVELIB_IUPIM
                RETVAL = IupLoadImage(file_name);
#else
                warn("Error: IUP was built without IupLoadImage() support");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

#### Original C function
# int IupSaveImage(Ihandle* ih, const char* file_name, const char* format);
int
_IupSaveImage(ih,file_name,format)
                Ihandle* ih;
                const char* file_name;
                const char* format;
        CODE:
#ifdef HAVELIB_IUPIM
                RETVAL = IupSaveImage(ih,file_name,format);
#else
                warn("Error: IUP was built without IupSaveImage() support");
                RETVAL = 0;
#endif
        OUTPUT:
                RETVAL

################################################################################

#### keyboard related macros
int
_isXkey(c)
                int c;
        CODE:
                RETVAL = iup_isXkey(c);
        OUTPUT:
                RETVAL

int
_isShiftXkey(c)
                int c;
        CODE:
                RETVAL = iup_isShiftXkey(c);
        OUTPUT:
                RETVAL

int
_isCtrlXkey(c)
                int c;
        CODE:
                RETVAL = iup_isCtrlXkey(c);
        OUTPUT:
                RETVAL

int
_isAltXkey(c)
                int c;
        CODE:
                RETVAL = iup_isAltXkey(c);
        OUTPUT:
                RETVAL

int
_isSysXkey(c)
                int c;
        CODE:
                RETVAL = iup_isSysXkey(c);
        OUTPUT:
                RETVAL

int
_isPrintable(c)
                int c;
        CODE:
                RETVAL = iup_isprint(c);
        OUTPUT:
                RETVAL

#### mouse related macros
int
_isShift(s)
                char* s;
        CODE:
                RETVAL = iup_isshift(s);
        OUTPUT:
                RETVAL

int
_isControl(s)
                char* s;
        CODE:
                RETVAL = iup_iscontrol(s);
        OUTPUT:
                RETVAL

int
_isButton1(s)
                char* s;
        CODE:
                RETVAL = iup_isbutton1(s);
        OUTPUT:
                RETVAL

int
_isButton2(s)
                char* s;
        CODE:
                RETVAL = iup_isbutton2(s);
        OUTPUT:
                RETVAL

int
_isButton3(s)
                char* s;
        CODE:
                RETVAL = iup_isbutton3(s);
        OUTPUT:
                RETVAL

int
_isButton4(s)
                char* s;
        CODE:
                RETVAL = iup_isbutton4(s);
        OUTPUT:
                RETVAL

int
_isButton5(s)
                char* s;
        CODE:
                RETVAL = iup_isbutton5(s);
        OUTPUT:
                RETVAL

int
_isDouble(s)
                char* s;
        CODE:
                RETVAL = iup_isdouble(s);
        OUTPUT:
                RETVAL

int
_isAlt(s)
                char* s;
        CODE:
                RETVAL = iup_isalt(s);
        OUTPUT:
                RETVAL

int
_isSys(s)
                char* s;
        CODE:
                RETVAL = iup_issys(s);
        OUTPUT:
                RETVAL
                
##char*
##_Testing(p)
##                SV* p;
##        CODE:
##                if SvOK(p) {
##                  printf("SvOK - yes");
##                }
##                else {
##                  printf("SvOK - no\n");
##                }
##                RETVAL = NULL;
##        OUTPUT:
##                RETVAL

#### Original C function from <iupcontrols.h>
# void IupControlsClose(void); 
# int IupMatGetInt (Ihandle* ih, const char* name, int lin, int col);
# void IupMatSetAttribute (Ihandle* ih, const char* name, int lin, int col, char* value);
# float IupMatGetFloat (Ihandle* ih, const char* name, int lin, int col);
# void IupMatSetfAttribute (Ihandle* ih, const char* name, int lin, int col, char* format, ...);

#### Original C function from <iup.h>
# void IupSetAttribute (Ihandle* ih, const char* name, const char* value);
# Ihandle* IupSetAttributes (Ihandle* ih, const char *str);
# Icallback IupSetCallback(Ihandle* ih, const char *name, Icallback func);
# Ihandle* IupSetCallbacks(Ihandle* ih, const char *name, Icallback func, ...);
# Icallback IupGetFunction (const char *name);
# Icallback IupSetFunction (const char *name, Icallback func);
# Ihandle* IupCreate (const char *classname);
# Ihandle* IupCreatep(const char *classname, void *first, ...);
# char* IupGetAttributes (Ihandle* ih);
# Icallback IupGetCallback(Ihandle* ih, const char *name);
# int IupGetInt (Ihandle* ih, const char* name);
# int IupGetInt2 (Ihandle* ih, const char* name);
# int IupGetIntInt (Ihandle *ih, const char* name, int *i1, int *i2);
# float IupGetFloat (Ihandle* ih, const char* name);
# void IupSetfAttribute (Ihandle* ih, const char* name, const char* format, ...);
# Ihandle* IupSetAtt(const char* handle_name, Ihandle* ih, const char* name, ...);
# void IupSetGlobal (const char* name, const char* value);
# char* IupMapFont (const char *iupfont);
# char* IupUnMapFont (const char *driverfont);
# void IupMessagef(const char *title, const char *format, ...);
# int IupScanf(const char *format, ...);
# Ihandle* IupMultiLine (const char* action);
# void IupTreeSetAttribute (Ihandle* ih, const char* name, int id, const char* value);
# void IupTreeStoreAttribute(Ihandle* ih, const char* name, int id, const char* value);
# char* IupTreeGetAttribute (Ihandle* ih, const char* name, int id);
# int IupTreeGetInt (Ihandle* ih, const char* name, int id);
# float IupTreeGetFloat (Ihandle* ih, const char* name, int id);
# void IupTreeSetfAttribute (Ihandle* ih, const char* name, int id, const char* format, ...);
# void IupTreeSetAttributeHandle(Ihandle* ih, const char* a, int id, Ihandle* ih_named);
