#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdlib.h> /* setenv/getenv */
#include <stdio.h>  /* sprintf */

/* configure-less detection of unsetenv for solaris */
#if defined(sun)
# if defined(__EXTENSIONS__) ||\
    (!defined(_STRICT_STDC) && !defined(__XOPEN_OR_POSIX)) || \
	    defined(_XPG6)
#  define HAVE_UNSETENV 1
#  define HAVE_SETENV 1
# endif
#endif

#ifndef HAVE_UNSETENV
# if !defined(sun) && !defined(_AIX)
#  define HAVE_UNSETENV 1
# endif
#endif
#ifndef HAVE_SETENV
# if !defined(WIN32) && !defined(sun)
#  define HAVE_SETENV 1
# endif
#endif

/* in order to work around system and perl implementation bugs/leaks, we need
 * to sometimes force PERL_USE_SAFE_PUTENV mode.
 */
#ifndef PERL_USE_SAFE_PUTENV
   /* Threaded perl with PERL_TRACK_MEMPOOL enabled causes
    * "panic: free from wrong pool at exit"
    * starting at 5.9.4 (confirmed through 5.20.1)
    * see: https://rt.cpan.org/Ticket/Display.html?id=99962
    */
# if PERL_BCDVERSION >= 0x5009004 && defined(USE_ITHREADS) && defined(PERL_TRACK_MEMPOOL)
#  define USE_SAFE_PUTENV 1
# elif PERL_BCDVERSION >= 0x5008000 && PERL_BCDVERSION < 0x5019006
   /* FreeBSD: SIGV at exit on perls prior to 5.19.6
    * see: https://rt.cpan.org/Ticket/Display.html?id=49872
    */
#  if defined(__FreeBSD__)
#   define USE_SAFE_PUTENV 1
#  endif
# endif
#endif

MODULE = Env::C        PACKAGE = Env::C  PREFIX = env_c_

char *
env_c_getenv(key)
    char *key

    CODE:
    RETVAL = getenv(key);

    OUTPUT:
    RETVAL

MODULE = Env::C        PACKAGE = Env::C  PREFIX = env_c_

int
env_c_setenv(key, val, override=1)
    char *key
    char *val
    int override;


    CODE:
#if !HAVE_SETENV
    if (override || getenv(key) == NULL) {
        char *old_env = getenv( key ); 
        char *buff = malloc(strlen(key) + strlen(val) + 2);
        if (buff != NULL) {
            sprintf(buff, "%s=%s", key, val);
#ifdef WIN32
            RETVAL = _putenv(buff);
            free(buff);
#else
            RETVAL = putenv(buff);
            if (old_env == NULL) {
                free(old_env);
            }
#endif
        }
        else {
            RETVAL = -1;
        }
    }
    else {
        RETVAL = -1;
    }
#else
# ifdef USE_SAFE_PUTENV
    PL_use_safe_putenv = 1;
# endif
    RETVAL = setenv(key, val, override);
#endif

    OUTPUT:
    RETVAL

MODULE = Env::C        PACKAGE = Env::C  PREFIX = env_c_

void
env_c_unsetenv(key)
    char *key

    PREINIT:
#ifdef WIN32
    char *buff;
#endif
#if defined( sun ) || defined( _AIX )
    int key_len;
    extern char **environ;
    char **envp;
#endif

    CODE:
#ifdef WIN32
    buff = malloc(strlen(key) + 2);
    sprintf(buff, "%s=", key);
    _putenv(buff);
    free(buff);
#else
#if HAVE_UNSETENV
    unsetenv(key);
#else
    key_len = strlen(key);
    for (envp = environ; *envp != NULL; envp++) {
        if (strncmp(key, *envp, key_len) == 0 &&
            (*envp)[key_len] == '=') {
            free(*envp);
            do {
                envp[0] = envp[1];
            } while (*envp++);
            break;
        }
    }
#endif
#endif

MODULE = Env::C        PACKAGE = Env::C  PREFIX = env_c_

AV*
env_c_getallenv()

    PREINIT:
    int i = 0;
    char *p;
    AV *av = Nullav;
#ifndef __BORLANDC__
    extern char **environ;
#endif

    CODE:
    RETVAL = newAV();

    while ((char*)environ[i] != '\0') {
        Perl_av_push(aTHX_ RETVAL, newSVpv((char*)environ[i++], 0));
    }

    OUTPUT:
    RETVAL

MODULE = Env::C        PACKAGE = Env::C  PREFIX = env_c_

# this is for leak.t, which  needs to know if PERL_USE_SAFE_PUTENV is in
# effect
int
env_c_using_safe_putenv()
    CODE:
#if defined(PERL_USE_SAFE_PUTENV) || defined(USE_SAFE_PUTENV)
    RETVAL = 1;
#else
    RETVAL = 0;
#endif

    OUTPUT:
    RETVAL
