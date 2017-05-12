#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <sys/shm.h>
#include <string.h>
#include <pthread.h>

#define MAX_VARSIZE 536870912 // 512MB

typedef struct {
    pthread_mutex_t m;
    char str[MAX_VARSIZE];
    int len;
} SharedObject;

void clear_sharedobject(SharedObject *o) {
    memset(o->str, '\0', MAX_VARSIZE);
    o->len = 0;
}

void init_sharedobject(SharedObject *o) {
    pthread_mutexattr_t mat;
    pthread_mutexattr_init(&mat);
    pthread_mutexattr_setpshared(&mat, PTHREAD_PROCESS_SHARED);
    pthread_mutex_init(&(o->m), &mat);
    clear_sharedobject(o);
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

MODULE = Global::IPC::StaticVariable    PACKAGE = Global::IPC::StaticVariable

PROTOTYPES: DISABLE


SV*
var_create()
PREINIT:
    SharedObject *o;
    int shmid = -1;
CODE:
    if ((shmid = shmget(IPC_PRIVATE, sizeof(SharedObject), 0666))!=-1) {
        o = (SharedObject*)shmat(shmid, NULL, 0);
        init_sharedobject(o);
        RETVAL = newSViv(shmid);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
var_destory(sv_shmid)
    SV* sv_shmid;
PREINIT:
    int shmid = -1;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
    }
    if (shmid == -1 || shmctl(shmid, IPC_RMID, NULL) != 0) {
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = newSViv(1);
    }
OUTPUT:
    RETVAL

SV*
var_update(sv_shmid, sv_str)
    SV* sv_shmid;
    SV* sv_str;
PREINIT:
    SharedObject *o = NULL;
    int shmid = -1;
    STRLEN sv_str_len = 0;
    char *ptr_sv_str = NULL;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        if (shmid != -1) o = (SharedObject*)shmat(shmid, NULL, 0);
    }
    if (o != NULL && (long)o != -1) {
        if (SvOK(sv_str)) ptr_sv_str = SvPV(sv_str, sv_str_len);
        pthread_mutex_lock(&(o->m));
        if (sv_str_len == 0) {
            clear_sharedobject(o);
        } else {
            if (o->len) memset(o->str, '\0', o->len);
            strncpy(o->str, ptr_sv_str, sv_str_len);
            o->len = sv_str_len;
        }
        pthread_mutex_unlock(&(o->m));
        RETVAL = newSViv(1);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
var_read(sv_shmid)
    SV* sv_shmid;
PREINIT:
    SharedObject *o = NULL;
    int shmid = -1;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        if (shmid != -1) o = (SharedObject*)shmat(shmid, NULL, 0);
    }
    if (o != NULL && (long)o != -1) {
        RETVAL = newSVpvn(o->str, o->len);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
var_append(sv_shmid, sv_str)
    SV* sv_shmid;
    SV* sv_str;
PREINIT:
    SharedObject *o = NULL;
    int shmid = -1;
    STRLEN sv_str_len = 0;
    char *ptr_sv_str = NULL, *tmp_ptr = NULL;
CODE:
    if (SvOK(sv_shmid) && SvOK(sv_str)) {
        ptr_sv_str = SvPV(sv_str, sv_str_len);
        if (ptr_sv_str && sv_str_len > 0) {
            shmid = SvIV(sv_shmid);
            if (shmid != -1) o = (SharedObject*)shmat(shmid, NULL, 0);
            if (o != NULL && (long)o != -1) {
                pthread_mutex_lock(&(o->m));
                tmp_ptr = o->str + o->len;
                strncpy(tmp_ptr, ptr_sv_str, sv_str_len);
                o->len += sv_str_len;
                pthread_mutex_unlock(&(o->m));
                RETVAL = newSViv(1);
            } else {
                RETVAL = &PL_sv_undef;
            }
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
var_getreset(sv_shmid)
    SV* sv_shmid;
PREINIT:
    SharedObject *o = NULL;
    int shmid = -1;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        if (shmid != -1) o = (SharedObject*)shmat(shmid, NULL, 0);
    }
    if (o != NULL && (long)o != -1) {
        pthread_mutex_lock(&(o->m));
        RETVAL = newSVpvn(o->str, o->len);
        clear_sharedobject(o);
        pthread_mutex_unlock(&(o->m));
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
var_length(sv_shmid)
    SV* sv_shmid;
PREINIT:
    SharedObject *o = NULL;
    int shmid = -1;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        if (shmid != -1) o = (SharedObject*)shmat(shmid, NULL, 0);
    }
    if (o != NULL && (long)o != -1) {
        RETVAL = newSViv(o->len);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL
