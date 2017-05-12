#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include "ppport.h"
#include "k.h"
#include "kparse.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

void croak_on_error(char *msg, K resp) {
    if (resp == NULL) {
        croak(msg);
    }

    if (resp->t == -128) {
        croak("%s with k error '%s'", msg, resp->s );
    }

    return;
}

MODULE = K   PACKAGE = K::Raw   PREFIX = k_
PROTOTYPES: DISABLE
BOOT:
    MATH_INT64_BOOT;

SV*
k_khpu(host, port, credentials)
    char *host
    int port
    char *credentials
    CODE:
        int i = khpu(host, port, credentials);
        if (i <= 0) {
            croak("Failed to connect to remote k instance '%s:%d'", host, port);
        }
        RETVAL = newSViv(i);
    OUTPUT:
        RETVAL

SV*
k_khpun(host, port, credentials, timeout)
    char *host
    int port
    char *credentials
    int timeout
    CODE:
        int i = khpun(host, port, credentials, timeout);
        if (i <= 0) {
            croak("Failed to connect to remote k instance '%s:%d'", host, port);
        }
        RETVAL = newSViv(i);
    OUTPUT:
        RETVAL

void
k_kclose(handle)
    int handle
    CODE:
        kclose(handle);

SV*
k_k(handle, kcmd=&PL_sv_undef)
    int handle
    SV *kcmd
    CODE:
        K resp;
        char *kcmd_str;

        if (handle == 0) {
            croak("Attempt to call k on an invalid handle");
        }

        // send
        if (SvOK(kcmd)) {
            kcmd_str = SvPV_nolen(kcmd);

            // synchronous
            if (handle > 0) {
                resp = k(handle, kcmd_str, (K)0);
                croak_on_error("Synchronous command failed", resp);
                RETVAL = sv_from_k(resp);
                r0(resp);
            }
            // asynchronous
            else {
                resp = k(handle, kcmd_str, (K)0);
                croak_on_error("Asynchronous command failed", resp);
                RETVAL = &PL_sv_undef;
            }
        }
        // receive
        else {
            resp = k(handle, (S)0);
            RETVAL = sv_from_k(resp);
            croak_on_error("Receive failed", resp);
            r0(resp);
        }

    OUTPUT:
        RETVAL
