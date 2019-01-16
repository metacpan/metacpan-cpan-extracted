#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define PROBE_TYPE_NONE      0
#define PROBE_TYPE_ONCE      1
#define PROBE_TYPE_PERMANENT 2

#define PROBE_ACTION_LOOKUP  0
#define PROBE_ACTION_CREATE  1
#define PROBE_ACTION_REMOVE  2

/*
 * Use preprocessor macros for time-sensitive operations.
 */
#define probe_is_enabled() !!probe_enabled

static Perl_ppaddr_t probe_nextstate_orig = 0;
static int probe_installed = 0;
static int probe_enabled = 0;
static HV* probe_hash = 0;
static SV* probe_trigger_cb = 0;

static void probe_enable(void);
static void probe_disable(void);
static int probe_is_installed(void);
static void probe_install(void);
static void probe_remove(void);

#define DEBUG 0

#define INFO(x) do { if (DEBUG > 0) dbg_printf x; } while (0)
#define TRACE(x) do { if (DEBUG > 1) dbg_printf x; } while (0)

void dbg_printf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
}

static inline void probe_invoke_callback(const char* file, int line, SV* callback)
{
    int count;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK (SP);
    EXTEND(SP, 2);
    XPUSHs(sv_2mortal(newSVpv(file, 0)));
    XPUSHs(sv_2mortal(newSViv(line)));
    PUTBACK;

    count = call_sv(callback, G_VOID|G_DISCARD);
    if (count != 0) {
        croak("probe trigger should have zero return values");
    }

    FREETMPS;
    LEAVE;
}

static int probe_lookup(const char* file, int line, int type, int action)
{
    U32 klen = strlen(file);
    char kstr[20];
    SV** rlines = 0;
    SV** rflag = 0;
    HV* lines = 0;
    SV* flag = 0;

    rlines = hv_fetch(probe_hash, file, klen, 0);
    if (rlines) {
        lines = (HV*) SvRV(*rlines);
        TRACE(("PROBE found entry for file [%s]: %p\n", file, lines));
    } else if (action == PROBE_ACTION_CREATE) {
        SV* slines = 0;
        lines = newHV();
        slines = (SV*) newRV((SV*) lines);
        hv_store(probe_hash, file, klen, slines, 0);
        INFO(("PROBE created entry for file [%s]: %p\n", file, lines));
    } else {
        return PROBE_TYPE_NONE;
    }

    klen = sprintf(kstr, "%d", line);
    rflag = hv_fetch(lines, kstr, klen, 0);
    if (rflag) {
        int ret = 0;
        flag = *rflag;
        ret = SvIV(flag);
        if (action == PROBE_ACTION_REMOVE) {
            /* TODO: remove file name when last line for file was removed? */
            hv_delete(lines, kstr, klen, G_DISCARD);
            INFO(("PROBE removed entry for line [%s] => %d\n", kstr, ret));
        }
        return ret;
    } else if (action == PROBE_ACTION_CREATE) {
        flag = newSViv(type);
        hv_store(lines, kstr, klen, flag, 0);
        INFO(("PROBE created entry for line [%s] => %d\n", kstr, type));
        return type;
    } else {
        return PROBE_TYPE_NONE;
    }

    /* catch any mistakes */
    return PROBE_TYPE_NONE;
}

/*
 * This function will run for every single line in your Perl code.
 * You would do well to make it as cheap as possible.
 */
static OP* probe_nextstate(pTHX)
{
    OP* ret = probe_nextstate_orig(aTHX);

    do {
        const char* file = 0;
        int line = 0;
        int type = PROBE_TYPE_NONE;

        if (!probe_is_enabled()) {
            break;
        }

        file = CopFILE(PL_curcop);
        line = CopLINE(PL_curcop);
        TRACE(("PROBE check [%s] [%d]\n", file, line));
        type = probe_lookup(file, line, PROBE_TYPE_NONE, PROBE_ACTION_LOOKUP);
        if (type == PROBE_TYPE_NONE) {
            break;
        }

        INFO(("PROBE triggered [%s] [%d] [%d]\n", file, line, type));
        if (probe_trigger_cb) {
            probe_invoke_callback(file, line, probe_trigger_cb);
        }

        if (type == PROBE_TYPE_ONCE) {
            probe_lookup(file, line, type, PROBE_ACTION_REMOVE);
        }
    } while (0);

    return ret;
}

static void probe_dump(void)
{
    hv_iterinit(probe_hash);
    while (1) {
        SV* key = 0;
        SV* value = 0;
        char* kstr = 0;
        STRLEN klen = 0;
        HV* lines = 0;
        HE* entry = hv_iternext(probe_hash);
        if (!entry) {
            break; /* no more hash keys */
        }
        key = hv_iterkeysv(entry);
        if (!key) {
            continue; /* invalid key */
        }
        kstr = SvPV(key, klen);
        if (!kstr) {
            continue; /* invalid key */
        }
        fprintf(stderr, "PROBE dump file [%s]\n", kstr);

        value = hv_iterval(probe_hash, entry);
        if (!value) {
            continue; /* invalid value */
        }
        lines = (HV*) SvRV(value);
        hv_iterinit(lines);
        while (1) {
            SV* key = 0;
            SV* value = 0;
            char* kstr = 0;
            STRLEN klen = 0;
            HE* entry = hv_iternext(lines);
            if (!entry) {
                break; /* no more hash keys */
            }
            key = hv_iterkeysv(entry);
            if (!key) {
                continue; /* invalid key */
            }
            kstr = SvPV(key, klen);
            if (!kstr) {
                continue; /* invalid key */
            }
            value = hv_iterval(lines, entry);
            if (!value || !SvTRUE(value)) {
                continue;
            }
            fprintf(stderr, "PROBE dump line [%s]\n", kstr);
        }
    }
}

static void probe_enable(void)
{
    if (probe_is_enabled()) {
        return;
    }
    INFO(("PROBE enabling\n"));
    probe_enabled = 1;
}

static void probe_reset(int installed)
{
    probe_installed = installed;
    probe_enabled = 0;
    probe_hash = 0;
    probe_trigger_cb = 0;
}

static void probe_clear(void)
{
    probe_hash = newHV();
    INFO(("PROBE cleared\n"));
}

static void probe_disable(void)
{
    if (!probe_is_enabled()) {
        return;
    }
    probe_enabled = 0;
    INFO(("PROBE disabled\n"));
}

static int probe_is_installed(void)
{
    return probe_installed;
}

static void probe_install(void)
{
    if (probe_is_installed()) {
        return;
    }

    INFO(("PROBE installed, [%p] => [%p]\n", PL_ppaddr[OP_NEXTSTATE], probe_nextstate));

    if (!probe_nextstate_orig) {
        probe_nextstate_orig = PL_ppaddr[OP_NEXTSTATE];
    }
    PL_ppaddr[OP_NEXTSTATE] = probe_nextstate;
    probe_reset(1);
    probe_clear();
}

static void probe_remove(void)
{
    if (!probe_is_installed()) {
        return;
    }
    INFO(("PROBE removed, [%p] => [%p]\n", PL_ppaddr[OP_NEXTSTATE], probe_nextstate_orig));
    if (probe_nextstate_orig) {
        PL_ppaddr[OP_NEXTSTATE] = probe_nextstate_orig;
    }
    probe_reset(0);
}

MODULE = Devel::Probe        PACKAGE = Devel::Probe
PROTOTYPES: DISABLE

#################################################################

void
install()
CODE:
    probe_install();

void
remove()
CODE:
    probe_remove();

int
is_installed()
CODE:
    RETVAL = probe_is_installed();
OUTPUT: RETVAL

void
enable()
CODE:
    probe_enable();

void
disable()
CODE:
    probe_disable();

int
is_enabled()
CODE:
    RETVAL = probe_is_enabled();
OUTPUT: RETVAL

void
clear()
CODE:
    probe_disable();
    probe_clear();

void
dump()
CODE:
    probe_dump();

void
add_probe(const char* file, int line, int type)
CODE:
    probe_lookup(file, line, type, PROBE_ACTION_CREATE);

void
trigger(SV* callback)
CODE:
    if (probe_trigger_cb == (SV*)NULL) {
        probe_trigger_cb = newSVsv(callback);
    } else {
        SvSetSV(probe_trigger_cb, callback);
    }
