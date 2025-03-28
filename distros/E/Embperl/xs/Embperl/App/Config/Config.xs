
/*
 * *********** WARNING **************
 * This file generated by Embperl::WrapXS/2.0.0
 * Any changes made here will be lost
 * ***********************************
 * 1. /usr/share/perl5/ExtUtils/XSBuilder/WrapXS.pm:52
 * 2. /usr/share/perl5/ExtUtils/XSBuilder/WrapXS.pm:2070
 * 3. xsbuilder/xs_generate.pl:6
 */


#include "ep.h"

#include "epmacro.h"

#include "epdat2.h"

#include "eppublic.h"

#include "eptypes.h"

#include "EXTERN.h"

#include "perl.h"

#include "XSUB.h"

#include "ep_xs_sv_convert.h"

#include "ep_xs_typedefs.h"



void Embperl__App__Config_destroy (pTHX_ Embperl__App__Config  obj) {
            if (obj -> pSessionArgs)
                SvREFCNT_dec(obj -> pSessionArgs);
            if (obj -> pSessionClasses)
                SvREFCNT_dec(obj -> pSessionClasses);
            if (obj -> pObjectAddpathAV)
                SvREFCNT_dec(obj -> pObjectAddpathAV);
            if (obj -> pObjectReqpathAV)
                SvREFCNT_dec(obj -> pObjectReqpathAV);

};



void Embperl__App__Config_new_init (pTHX_ Embperl__App__Config  obj, SV * item, int overwrite) {

    SV * * tmpsv ;

    if (SvTYPE(item) == SVt_PVMG) 
        memcpy (obj, (void *)SvIVX(item), sizeof (*obj)) ;
    else if (SvTYPE(item) == SVt_PVHV) {
        if ((tmpsv = hv_fetch((HV *)item, "app_name", sizeof("app_name") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sAppName = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sAppName = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "app_handler_class", sizeof("app_handler_class") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sAppHandlerClass = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sAppHandlerClass = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "session_handler_class", sizeof("session_handler_class") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sSessionHandlerClass = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sSessionHandlerClass = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "session_args", sizeof("session_args") - 1, 0)) || overwrite) {
            HV * tmpobj = ((HV *)epxs_sv2_HVREF((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> pSessionArgs = (HV *)SvREFCNT_inc(tmpobj);
            else
                obj -> pSessionArgs = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "session_classes", sizeof("session_classes") - 1, 0)) || overwrite) {
            AV * tmpobj = ((AV *)epxs_sv2_AVREF((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> pSessionClasses = (AV *)SvREFCNT_inc(tmpobj);
            else
                obj -> pSessionClasses = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "session_config", sizeof("session_config") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sSessionConfig = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sSessionConfig = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "cookie_name", sizeof("cookie_name") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sCookieName = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sCookieName = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "cookie_domain", sizeof("cookie_domain") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sCookieDomain = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sCookieDomain = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "cookie_path", sizeof("cookie_path") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sCookiePath = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sCookiePath = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "cookie_expires", sizeof("cookie_expires") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sCookieExpires = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sCookieExpires = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "cookie_secure", sizeof("cookie_secure") - 1, 0)) || overwrite) {
            obj -> bCookieSecure = (bool)epxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "log", sizeof("log") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sLog = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sLog = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "debug", sizeof("debug") - 1, 0)) || overwrite) {
            obj -> bDebug = (unsigned)epxs_sv2_UV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mailhost", sizeof("mailhost") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sMailhost = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sMailhost = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mailhelo", sizeof("mailhelo") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sMailhelo = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sMailhelo = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mailfrom", sizeof("mailfrom") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sMailfrom = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sMailfrom = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "maildebug", sizeof("maildebug") - 1, 0)) || overwrite) {
            obj -> bMaildebug = (bool)epxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mail_errors_to", sizeof("mail_errors_to") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sMailErrorsTo = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sMailErrorsTo = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mail_errors_limit", sizeof("mail_errors_limit") - 1, 0)) || overwrite) {
            obj -> nMailErrorsLimit = (int)epxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mail_errors_reset_time", sizeof("mail_errors_reset_time") - 1, 0)) || overwrite) {
            obj -> nMailErrorsResetTime = (int)epxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "mail_errors_resend_time", sizeof("mail_errors_resend_time") - 1, 0)) || overwrite) {
            obj -> nMailErrorsResendTime = (int)epxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_base", sizeof("object_base") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sObjectBase = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sObjectBase = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_app", sizeof("object_app") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sObjectApp = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sObjectApp = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_addpath", sizeof("object_addpath") - 1, 0)) || overwrite) {
            AV * tmpobj = ((AV *)epxs_sv2_AVREF((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> pObjectAddpathAV = (AV *)SvREFCNT_inc(tmpobj);
            else
                obj -> pObjectAddpathAV = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_reqpath", sizeof("object_reqpath") - 1, 0)) || overwrite) {
            AV * tmpobj = ((AV *)epxs_sv2_AVREF((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> pObjectReqpathAV = (AV *)SvREFCNT_inc(tmpobj);
            else
                obj -> pObjectReqpathAV = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_stopdir", sizeof("object_stopdir") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sObjectStopdir = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sObjectStopdir = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_fallback", sizeof("object_fallback") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sObjectFallback = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sObjectFallback = NULL ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "object_handler_class", sizeof("object_handler_class") - 1, 0)) || overwrite) {
            char * tmpobj = ((char *)epxs_sv2_PV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)));
            if (tmpobj)
                obj -> sObjectHandlerClass = (char *)ep_pstrdup(obj->pPool,tmpobj);
            else
                obj -> sObjectHandlerClass = NULL ;
        }
   ; }

    else
        croak ("initializer for Embperl::App::Config::new is not a hash or object reference") ;

} ;


MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
app_name(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sAppName;

    if (items > 1) {
        obj->sAppName = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
app_handler_class(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sAppHandlerClass;

    if (items > 1) {
        obj->sAppHandlerClass = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
session_handler_class(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sSessionHandlerClass;

    if (items > 1) {
        obj->sSessionHandlerClass = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

HV *
session_args(obj, val=NULL)
    Embperl::App::Config obj
    HV * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (HV *)  obj->pSessionArgs;

    if (items > 1) {
        obj->pSessionArgs = (HV *)SvREFCNT_inc(val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

AV *
session_classes(obj, val=NULL)
    Embperl::App::Config obj
    AV * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (AV *)  obj->pSessionClasses;

    if (items > 1) {
        obj->pSessionClasses = (AV *)SvREFCNT_inc(val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
session_config(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sSessionConfig;

    if (items > 1) {
        obj->sSessionConfig = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
cookie_name(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sCookieName;

    if (items > 1) {
        obj->sCookieName = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
cookie_domain(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sCookieDomain;

    if (items > 1) {
        obj->sCookieDomain = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
cookie_path(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sCookiePath;

    if (items > 1) {
        obj->sCookiePath = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
cookie_expires(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sCookieExpires;

    if (items > 1) {
        obj->sCookieExpires = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

bool
cookie_secure(obj, val=0)
    Embperl::App::Config obj
    bool val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (bool)  obj->bCookieSecure;

    if (items > 1) {
        obj->bCookieSecure = (bool) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
log(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sLog;

    if (items > 1) {
        obj->sLog = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

unsigned
debug(obj, val=0)
    Embperl::App::Config obj
    unsigned val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (unsigned)  obj->bDebug;

    if (items > 1) {
        obj->bDebug = (unsigned) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
mailhost(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sMailhost;

    if (items > 1) {
        obj->sMailhost = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
mailhelo(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sMailhelo;

    if (items > 1) {
        obj->sMailhelo = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
mailfrom(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sMailfrom;

    if (items > 1) {
        obj->sMailfrom = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

bool
maildebug(obj, val=0)
    Embperl::App::Config obj
    bool val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (bool)  obj->bMaildebug;

    if (items > 1) {
        obj->bMaildebug = (bool) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
mail_errors_to(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sMailErrorsTo;

    if (items > 1) {
        obj->sMailErrorsTo = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

int
mail_errors_limit(obj, val=0)
    Embperl::App::Config obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->nMailErrorsLimit;

    if (items > 1) {
        obj->nMailErrorsLimit = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

int
mail_errors_reset_time(obj, val=0)
    Embperl::App::Config obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->nMailErrorsResetTime;

    if (items > 1) {
        obj->nMailErrorsResetTime = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

int
mail_errors_resend_time(obj, val=0)
    Embperl::App::Config obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->nMailErrorsResendTime;

    if (items > 1) {
        obj->nMailErrorsResendTime = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
object_base(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sObjectBase;

    if (items > 1) {
        obj->sObjectBase = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
object_app(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sObjectApp;

    if (items > 1) {
        obj->sObjectApp = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

AV *
object_addpath(obj, val=NULL)
    Embperl::App::Config obj
    AV * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (AV *)  obj->pObjectAddpathAV;

    if (items > 1) {
        obj->pObjectAddpathAV = (AV *)SvREFCNT_inc(val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

AV *
object_reqpath(obj, val=NULL)
    Embperl::App::Config obj
    AV * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (AV *)  obj->pObjectReqpathAV;

    if (items > 1) {
        obj->pObjectReqpathAV = (AV *)SvREFCNT_inc(val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
object_stopdir(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sObjectStopdir;

    if (items > 1) {
        obj->sObjectStopdir = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
object_fallback(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sObjectFallback;

    if (items > 1) {
        obj->sObjectFallback = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 

char *
object_handler_class(obj, val=NULL)
    Embperl::App::Config obj
    char * val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (char *)  obj->sObjectHandlerClass;

    if (items > 1) {
        obj->sObjectHandlerClass = (char *)ep_pstrdup(obj->pPool,val);
    }
  OUTPUT:
    RETVAL

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 



SV *
new (class,initializer=NULL)
    char * class
    SV * initializer 
PREINIT:
    SV * svobj ;
    Embperl__App__Config  cobj ;
    SV * tmpsv ;
CODE:
    epxs_Embperl__App__Config_create_obj(cobj,svobj,RETVAL,malloc(sizeof(*cobj))) ;

    if (initializer) {
        if (!SvROK(initializer) || !(tmpsv = SvRV(initializer))) 
            croak ("initializer for Embperl::App::Config::new is not a reference") ;

        if (SvTYPE(tmpsv) == SVt_PVHV || SvTYPE(tmpsv) == SVt_PVMG)  
            Embperl__App__Config_new_init (aTHX_ cobj, tmpsv, 0) ;
        else if (SvTYPE(tmpsv) == SVt_PVAV) {
            int i ;
            SvGROW(svobj, sizeof (*cobj) * av_len((AV *)tmpsv)) ;     
            for (i = 0; i <= av_len((AV *)tmpsv); i++) {
                SV * * itemrv = av_fetch((AV *)tmpsv, i, 0) ;
                SV * item ;
                if (!itemrv || !*itemrv || !SvROK(*itemrv) || !(item = SvRV(*itemrv))) 
                    croak ("array element of initializer for Embperl::App::Config::new is not a reference") ;
                Embperl__App__Config_new_init (aTHX_ &cobj[i], item, 1) ;
            }
        }
        else {
             croak ("initializer for Embperl::App::Config::new is not a hash/array/object reference") ;
        }
    }
OUTPUT:
    RETVAL 

MODULE = Embperl::App::Config    PACKAGE = Embperl::App::Config 



void
DESTROY (obj)
    Embperl::App::Config  obj 
CODE:
    Embperl__App__Config_destroy (aTHX_ obj) ;

PROTOTYPES: disabled

BOOT:
    items = items; /* -Wall */

