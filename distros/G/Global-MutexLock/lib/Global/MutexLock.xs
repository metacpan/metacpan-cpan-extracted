#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <sys/shm.h>
#include <pthread.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

MODULE = Global::MutexLock    PACKAGE = Global::MutexLock

PROTOTYPES: DISABLE

SV*
mutex_create()
PREINIT:
    pthread_mutex_t *m;
    pthread_mutexattr_t mat;
    int shmid;
CODE:
    shmid = shmget(IPC_PRIVATE, sizeof(pthread_mutex_t), 0666);
    if (shmid >= 0) {
        m = shmat(shmid, NULL, 0);
        pthread_mutexattr_init(&mat);
        pthread_mutexattr_setpshared(&mat, PTHREAD_PROCESS_SHARED);
        pthread_mutex_init(m, &mat);
    }
    RETVAL = newSViv(shmid);
OUTPUT:
    RETVAL

SV*
mutex_lock(sv_shmid)
    SV* sv_shmid;
PREINIT:
    pthread_mutex_t *m;
    int shmid;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        m = (pthread_mutex_t*)shmat(shmid, NULL, 0);
        if ((long)m != -1) {
            pthread_mutex_lock(m);
            RETVAL = newSViv(1);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
mutex_unlock(sv_shmid)
    SV* sv_shmid;
PREINIT:
    pthread_mutex_t *m;
    int shmid;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        m = (pthread_mutex_t*)shmat(shmid, NULL, 0);
        if ((long)m != -1) {
            pthread_mutex_unlock(m);
            RETVAL = newSViv(1);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
mutex_destory(sv_shmid)
    SV* sv_shmid;
PREINIT:
    int shmid;
CODE:
    if (SvOK(sv_shmid)) {
        shmid = SvIV(sv_shmid);
        if (shmctl(shmid, IPC_RMID, NULL) != 0) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSViv(1);
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL
