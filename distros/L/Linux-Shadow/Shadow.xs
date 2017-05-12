#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <shadow.h>

#include "const-c.inc"

MODULE = Linux::Shadow        PACKAGE = Linux::Shadow    

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

void
getspnam (name)
        const char * name
    INIT:
        struct spwd *shadow;
    PPCODE:
        shadow = getspnam(name);
        if (shadow) {
            XPUSHs(sv_2mortal(newSVpvf("%s", shadow->sp_namp)));
            XPUSHs(sv_2mortal(newSVpvf("%s", shadow->sp_pwdp)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_lstchg)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_min)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_max)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_warn)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_inact)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_expire)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_flag)));
        }

void
getspent ()
    INIT:
        struct spwd *shadow;
    PPCODE:
        shadow = getspent();
        if (shadow) {
            XPUSHs(sv_2mortal(newSVpvf("%s", shadow->sp_namp)));
            XPUSHs(sv_2mortal(newSVpvf("%s", shadow->sp_pwdp)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_lstchg)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_min)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_max)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_warn)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_inact)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_expire)));
            XPUSHs(sv_2mortal(newSViv(shadow->sp_flag)));
        }

void
setspent ()

void
endspent ()

