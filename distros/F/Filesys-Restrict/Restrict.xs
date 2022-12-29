#define PERL_NO_GET_CONTEXT
#include "easyxs/easyxs.h"

// Cribbed from Socket.xs:
/* STRUCT_OFFSET should have come from from perl.h, but if not,
 * roll our own (not using offsetof() since that is C99). */
#ifndef STRUCT_OFFSET
#  define STRUCT_OFFSET(s,m)  (Size_t)(&(((s *)0)->m))
#endif

#define STRUCT_MEMBER_SIZE(s,m) sizeof(((s *)0)->m)

// Modern Win32 releases do support UNIX sockets via afunix.h,
// but that header file isn’t available on MinGW. Socket.xs defines
// the necessary structs and constants directly; if needed we could
// take that approach, but for now let’s just forgo UNIX socket support
// unless there’s sys/un.h.
#ifdef I_SYS_UN     // cf. perl5 Porting/Glossary

#define HAS_UNIX_SOCKETS 1
#include <sys/un.h>

#define SA_FAMILY_END_OFFSET ( \
    STRUCT_OFFSET(struct sockaddr, sa_family) \
    + STRUCT_MEMBER_SIZE(struct sockaddr, sa_family) \
)

#else
#define HAS_UNIX_SOCKETS 0
#endif

#include <sys/types.h>
#include <stdbool.h>

#include "ppport.h"

#define DEBUG 0

/* A duplicate of PL_ppaddr as we find it at BOOT time.
   We can thus overwrite PL_ppaddr with our own wrapper functions.
   This interacts better with wrap_op_checker(), which doesn’t provide
   a good way to call the op’s (now-overwritten) op_ppaddr callback.
*/
static Perl_ppaddr_t ORIG_PL_ppaddr[OP_max];

#define MYPKG "Filesys::Restrict"

/* An idempotent variant of dMARK that allows us to inspect the
   mark stack without changing it: */
#ifndef dMARK_TOPMARK
    #define dMARK_TOPMARK SV **mark = PL_stack_base + TOPMARK
#endif

static inline SV* _get_callback(pTHX) {
    SV* callback = get_sv(MYPKG "::_AUTHORIZE", 0);

    if (callback && !SvOK(callback)) {
        callback = NULL;
    }

    return callback;
}

#define _IS_FILEHANDLE(expr) (                          \
    (SvTYPE(expr) == SVt_PVGV) ||                       \
    (SvROK(expr) && SvTYPE(SvRV(expr)) == SVt_PVGV) ||  \
    (SvTYPE(expr) == SVt_PVIO) ||                       \
    (SvROK(expr) && SvTYPE(SvRV(expr)) == SVt_PVIO)     \
)

bool _is_pipe_open(pTHX_ const char* str, STRLEN len) {
    if (len >= 2) {
        if (memEQ("|-", str, 2)) return true;
        if (memEQ("-|", str, 2)) return true;
    }

    return false;
}

#define _IS_SCALAR_REF(sv) (SvROK(sv) && (SvTYPE(SvRV(sv)) < SVt_PVGV))

// Returns NULL to indicate no path.
static SV* _get_path_from_3arg_open(pTHX_ SV* mode, SV* expr) {

    // 3-arg open with undef 3rd arg opens an anonymous tempfile.
    if (!SvOK(expr)) return NULL;

    // Ignore scalar-reference paths, which indicate an “open”
    // of a Perl scalar.
    if (_IS_SCALAR_REF(expr)) return NULL;

    if (!SvPOK(mode)) croak("mode isn’t a string?!?");

    STRLEN modelen;
    const char* modestr = SvPVbyte(mode, modelen);

    if (_is_pipe_open(aTHX_ modestr, modelen)) return NULL;

    // If the last character of the mode is '=' then expr is a
    // file descriptor or filehandle, so we shouldn’t care.
    if (NULL != strchr(modestr, '&')) return NULL;

    return expr;
}

static SV* _get_path_from_2arg_open(pTHX_ SV* expr) {
    STRLEN len;
    const char* str = SvPVbyte(expr, len);

    if (_is_pipe_open(aTHX_ str, len)) return NULL;

    if (len < 1) return NULL;

    // Special cases:
    if (len == 2) {
        if (memEQ(str, ">-", 2)) return NULL;   // opens STDOUT
        if (memEQ(str, "<-", 2)) return NULL;   // opens STDIN
    }

    STRLEN idx = 0;

    if (str[idx] == '+') idx++;

    if (str[idx] == '<') {
        idx++;
    }
    else if (str[idx] == '>') {
        idx++;

        if (str[idx] == '>') idx++;
    }
    else {

        // For now ignore anything that isn’t +>, +>>, +<, >, >>, or <.
        return NULL;
    }

    // Duplicating a filehandle or file descriptor is always OK.
    if (str[idx] == '&') return NULL;

    return newSVpvn_flags(
        str + idx,
        len - idx,
        SVs_TEMP
    );
}

static inline void _prep_stack(pTHX_ SV** args, unsigned argscount) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, argscount);

    unsigned a;

    for (a=0; a < argscount; a++) PUSHs(args[a]);

    PUTBACK;
}

static inline void _authorize(pTHX_ int OPID, SV* path_sv, SV* callback_sv) {
    const char* opname = PL_op_desc[OPID];

    dSP;

    SV* args[] = {
        newSVpvn_flags(opname, strlen(opname), SVs_TEMP),
        path_sv,
    };

    _prep_stack(aTHX_ args, 2);

    I32 returns = call_sv( callback_sv, G_SCALAR );

    SPAGAIN;

    bool authorized;

    if (returns) {
        SV* got = POPs;
        authorized = SvTRUE(got);
    }
    else {
        authorized = false;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if (!authorized) {
        _prep_stack(aTHX_ args, 2);

        call_pv( MYPKG "::_CROAK", G_VOID | G_DISCARD );

        // We should never get here:
        assert(0);
    }
}

// open() is such a funny beast that it gets its own wrapper.
static OP* _wrapped_pp_OP_OPEN(pTHX) {
    SV* callback = _get_callback(aTHX);
    if (callback) {
        dSP;
        dMARK_TOPMARK;

        int numargs = SP - MARK;

        SV* path;

        switch (numargs) {
            case 1:
                path = NULL;
                break;

            case 2:
                path = _get_path_from_2arg_open(aTHX_ MARK[2]);
                break;

            case 3:
                path = _get_path_from_3arg_open(aTHX_ MARK[2], MARK[3]);

                break;

            default:

                // Shouldn’t happen, but just in case …
                croak("Bad # of args: %d", numargs);
        }

        if (path) {
            _authorize(aTHX_ OP_OPEN, path, callback);
        }
    }

    return ORIG_PL_ppaddr[OP_OPEN](aTHX);
}

# if 0
// require() also gets its own wrapper since it depends on @INC.
static OP* _wrapped_pp_OP_REQUIRE(pTHX) {
    SV* callback = _get_callback(aTHX);
    if (callback) {
        dSP;

        SV* required = *SP;

        STRLEN reqlen;
        const char* required_str = SvPVbyte(required, reqlen);

        if (reqlen && NULL != strchr("./", required_str[0])) {
            _authorize(aTHX_ OP_REQUIRE, required, callback);
        }
    }

    return ORIG_PL_ppaddr[OP_REQUIRE](aTHX);
}
#endif

#define MAKE_LAST_ARG_WRAPPER(OPID, CHECK_FH)  \
static OP* _wrapped_pp_##OPID(pTHX) {           \
    SV* callback = _get_callback(aTHX);              \
    if (callback) {                             \
        dSP;                                    \
        if (!CHECK_FH || !_IS_FILEHANDLE(*SP)) {              \
            _authorize(aTHX_ OPID, *SP, callback);   \
        }                                       \
    }                                           \
                                                \
    return ORIG_PL_ppaddr[OPID](aTHX);          \
}

#define MAKE_LAST_ARG_WRAPPER_CHECK_FH(OPID)  \
    MAKE_LAST_ARG_WRAPPER(OPID, 1)

#define MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OPID)  \
    MAKE_LAST_ARG_WRAPPER(OPID, 0)

#define MAKE_2ARG_WRAPPER(OPID)  \
static OP* _wrapped_pp_##OPID(pTHX) {           \
    SV* callback = _get_callback(aTHX);              \
    if (callback) {                             \
        dSP;                                    \
        _authorize(aTHX_ OPID, *SP, callback);   \
        _authorize(aTHX_ OPID, *(SP - 1), callback);   \
    }                                           \
                                                \
    return ORIG_PL_ppaddr[OPID](aTHX);          \
}

// ----------------------------------------------------------------------

#define _MY_SET_SP_AND_MARK(OP_MAXARG) \
    dSP;                                            \
    dMARK_TOPMARK;                                  \
                                                    \
    /* The compiler will optimize this away         \
        for MAKE_FIRST_ARG_OPEN_LIST_WRAPPER:        \
    */                                              \
    if (OP_MAXARG)                                  \
        if (SP < MARK || (SP - MARK) > OP_MAXARG) { \
            unsigned numargs = MAXARG;              \
            MARK = SP;                              \
            while (numargs--) MARK--;               \
        }

/* For ops that take an indefinite number of args. */
#define MAKE_FIRST_ARG_OPEN_LIST_WRAPPER(OPID) \
    MAKE_SINGLE_ARG_LIST_WRAPPER(OPID, 0, 0)

/* For ops whose number of string args is a fixed range.

   NB: In some perls, some list opts don’t set MARK. In those cases we
   fall back to MAXARG. As of now mkdir is the known “offender”, and
   only on Alpine Linux 3.11 & 3.12 (not 3.13).
*/
#define MAKE_SINGLE_ARG_LIST_WRAPPER(OPID, ARG_INDEX, OP_MAXARG)       \
static OP* _wrapped_pp_##OPID(pTHX) {                   \
    SV* callback = _get_callback(aTHX); \
    if (callback) {                              \
        _MY_SET_SP_AND_MARK(OP_MAXARG)                  \
                                                        \
        _authorize(aTHX_ OPID, MARK[1 + ARG_INDEX], callback); \
    }                                                   \
                                                        \
    return ORIG_PL_ppaddr[OPID](aTHX);                  \
}

static OP* _wrapped_pp_OP_TRUNCATE(pTHX) {
    SV* callback = _get_callback(aTHX);
    if (callback) {
        dSP;
        SV* first_arg = *(SP - 1);

        if (!_IS_FILEHANDLE(first_arg)) {
            _authorize(aTHX_ OP_TRUNCATE, first_arg, callback);
        }
    }

    return ORIG_PL_ppaddr[OP_TRUNCATE](aTHX);
}

#define MAKE_ALL_ARGS_LIST_WRAPPER_CHECK_FH(OPID, ARG_INDEX)       \
static OP* _wrapped_pp_##OPID(pTHX) {                   \
    SV* callback = _get_callback(aTHX); \
    if (callback) {                              \
        _MY_SET_SP_AND_MARK(0)                  \
                                                        \
        MARK += ARG_INDEX; \
        while (++MARK <= SP) { \
            if (!_IS_FILEHANDLE(*MARK)) { \
                _authorize(aTHX_ OPID, *MARK, callback); \
            } \
        } \
    }                                                   \
                                                        \
    return ORIG_PL_ppaddr[OPID](aTHX);                  \
}

/* For ops where only the last arg is a string. */
#define MAKE_SOCKET_OP_WRAPPER(OPID)           \
static OP* _wrapped_pp_##OPID(pTHX) {   \
    SV* callback = _get_callback(aTHX); \
    if (callback) {                             \
        dSP;                            \
        STRLEN pathlen;                 \
        const char* path = _get_local_socket_path(aTHX_ SP[0], &pathlen); \
        if (path) { \
            SV* path_sv = newSVpvn_flags(path, pathlen, SVs_TEMP); \
            _authorize(aTHX_ OPID, path_sv, callback); \
        } \
    }                                   \
                                        \
    return ORIG_PL_ppaddr[OPID](aTHX);  \
}

const char* _get_local_socket_path(pTHX_ SV* sockname_sv, STRLEN *pathlen) {
    char* path = NULL;

#if HAS_UNIX_SOCKETS
    STRLEN sockname_len;
    const char* sockname_str = SvPVbyte(sockname_sv, sockname_len);

    // Let Perl handle the failure state:
    if (sockname_len >= SA_FAMILY_END_OFFSET) {
        sa_family_t family = ( (struct sockaddr*) sockname_str )->sa_family;

        if (family == AF_UNIX) {
            path = ( (struct sockaddr_un*) sockname_str )->sun_path;
            *pathlen = sockname_len - STRUCT_OFFSET(struct sockaddr_un, sun_path);
        }
    }
#endif

    return path;
}

MAKE_SOCKET_OP_WRAPPER(OP_BIND);
MAKE_SOCKET_OP_WRAPPER(OP_CONNECT);

MAKE_SINGLE_ARG_LIST_WRAPPER(OP_SYSOPEN, 1, 4);

MAKE_FIRST_ARG_OPEN_LIST_WRAPPER(OP_EXEC);
MAKE_FIRST_ARG_OPEN_LIST_WRAPPER(OP_SYSTEM);

MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_LSTAT);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_STAT);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTRREAD);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTRWRITE);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTREXEC);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTEREAD);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTEWRITE);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTEEXEC);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTIS);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTSIZE);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTMTIME);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTATIME);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTCTIME);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTROWNED);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTEOWNED);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTZERO);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTSOCK);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTCHR);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTBLK);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTFILE);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTDIR);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTPIPE);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTSUID);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTSGID);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTSVTX);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTLINK);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTTEXT);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_FTBINARY);
MAKE_LAST_ARG_WRAPPER_CHECK_FH(OP_CHDIR);
MAKE_ALL_ARGS_LIST_WRAPPER_CHECK_FH(OP_CHOWN, 2);
MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_CHROOT);
MAKE_ALL_ARGS_LIST_WRAPPER_CHECK_FH(OP_UNLINK, 0);
MAKE_ALL_ARGS_LIST_WRAPPER_CHECK_FH(OP_CHMOD, 1);
MAKE_ALL_ARGS_LIST_WRAPPER_CHECK_FH(OP_UTIME, 2);
MAKE_2ARG_WRAPPER(OP_RENAME);
MAKE_2ARG_WRAPPER(OP_LINK);

// symlink() is special: its “target” (the first arg) and doesn’t
// need to refer to a valid filesystem node.
MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_SYMLINK);

MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_READLINK);
MAKE_SINGLE_ARG_LIST_WRAPPER(OP_MKDIR, 0, 2);
MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_RMDIR);
MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_OPEN_DIR);

// MAKE_LAST_ARG_WRAPPER_NO_CHECK_FH(OP_DOFILE);

/* ---------------------------------------------------------------------- */

#define MAKE_BOOT_WRAPPER(OPID)         \
ORIG_PL_ppaddr[OPID] = PL_ppaddr[OPID]; \
PL_ppaddr[OPID] = _wrapped_pp_##OPID;

//----------------------------------------------------------------------

bool initialized = false;

MODULE = Filesys::Restrict   PACKAGE = Filesys::Restrict

PROTOTYPES: DISABLE

BOOT:
    /* In theory this is for PL_check rather than PL_ppaddr, but per
       Paul Evans in practice this mutex gets used for other stuff, too.
       Paul says a race here should be exceptionally rare, so for pre-5.16
       perls (which lack this mutex) let’s just skip it.
    */
#ifdef OP_CHECK_MUTEX_LOCK
    OP_CHECK_MUTEX_LOCK;
#endif
    if (!initialized) {
        initialized = true;

        MAKE_BOOT_WRAPPER(OP_OPEN);
        MAKE_BOOT_WRAPPER(OP_SYSOPEN);
        MAKE_BOOT_WRAPPER(OP_TRUNCATE);
        MAKE_BOOT_WRAPPER(OP_EXEC);
        MAKE_BOOT_WRAPPER(OP_SYSTEM);

        if (HAS_UNIX_SOCKETS) {
            MAKE_BOOT_WRAPPER(OP_BIND);
            MAKE_BOOT_WRAPPER(OP_CONNECT);
        }

        HV *stash = gv_stashpv(MYPKG, FALSE);
        newCONSTSUB(stash, "_HAS_UNIX_SOCKETS", boolSV(HAS_UNIX_SOCKETS));

        MAKE_BOOT_WRAPPER(OP_LSTAT);
        MAKE_BOOT_WRAPPER(OP_STAT);
        MAKE_BOOT_WRAPPER(OP_FTRREAD);
        MAKE_BOOT_WRAPPER(OP_FTRWRITE);
        MAKE_BOOT_WRAPPER(OP_FTREXEC);
        MAKE_BOOT_WRAPPER(OP_FTEREAD);
        MAKE_BOOT_WRAPPER(OP_FTEWRITE);
        MAKE_BOOT_WRAPPER(OP_FTEEXEC);
        MAKE_BOOT_WRAPPER(OP_FTIS);
        MAKE_BOOT_WRAPPER(OP_FTSIZE);
        MAKE_BOOT_WRAPPER(OP_FTMTIME);
        MAKE_BOOT_WRAPPER(OP_FTATIME);
        MAKE_BOOT_WRAPPER(OP_FTCTIME);
        MAKE_BOOT_WRAPPER(OP_FTROWNED);
        MAKE_BOOT_WRAPPER(OP_FTEOWNED);
        MAKE_BOOT_WRAPPER(OP_FTZERO);
        MAKE_BOOT_WRAPPER(OP_FTSOCK);
        MAKE_BOOT_WRAPPER(OP_FTCHR);
        MAKE_BOOT_WRAPPER(OP_FTBLK);
        MAKE_BOOT_WRAPPER(OP_FTFILE);
        MAKE_BOOT_WRAPPER(OP_FTDIR);
        MAKE_BOOT_WRAPPER(OP_FTPIPE);
        MAKE_BOOT_WRAPPER(OP_FTSUID);
        MAKE_BOOT_WRAPPER(OP_FTSGID);
        MAKE_BOOT_WRAPPER(OP_FTSVTX);
        MAKE_BOOT_WRAPPER(OP_FTLINK);
        MAKE_BOOT_WRAPPER(OP_FTTEXT);
        MAKE_BOOT_WRAPPER(OP_FTBINARY);
        MAKE_BOOT_WRAPPER(OP_CHDIR);
        MAKE_BOOT_WRAPPER(OP_CHOWN);
        MAKE_BOOT_WRAPPER(OP_CHROOT);
        MAKE_BOOT_WRAPPER(OP_UNLINK);
        MAKE_BOOT_WRAPPER(OP_CHMOD);
        MAKE_BOOT_WRAPPER(OP_UTIME);
        MAKE_BOOT_WRAPPER(OP_RENAME);
        MAKE_BOOT_WRAPPER(OP_LINK);
        MAKE_BOOT_WRAPPER(OP_SYMLINK);
        MAKE_BOOT_WRAPPER(OP_READLINK);
        MAKE_BOOT_WRAPPER(OP_MKDIR);
        MAKE_BOOT_WRAPPER(OP_RMDIR);
        MAKE_BOOT_WRAPPER(OP_OPEN_DIR);

        // MAKE_BOOT_WRAPPER(OP_REQUIRE);
        // MAKE_BOOT_WRAPPER(OP_DOFILE);
    }
#ifdef OP_CHECK_MUTEX_UNLOCK
    OP_CHECK_MUTEX_UNLOCK;
#endif
