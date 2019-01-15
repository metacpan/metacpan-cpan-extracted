#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static Perl_ppaddr_t probe_nextstate_orig = 0;
static int probe_installed = 0;
static int probe_enabled = 0;
static HV* probe_hash = 0;
static SV* probe_trigger_cb = 0;

static int probe_is_enabled(void);
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

static int probe_lookup(const char* file, int line, int create)
{
    U32 klen = strlen(file);
    SV** rlines = hv_fetch(probe_hash, file, klen, 0);
    HV* lines = 0;
    char kstr[20];

    if (rlines) {
        lines = (HV*) SvRV(*rlines);
        TRACE(("PROBE found entry for file [%s]: %p\n", file, lines));
    } else if (!create) {
        return 0;
    } else {
        SV* slines = 0;
        lines = newHV();
        slines = (SV*) newRV((SV*) lines);
        hv_store(probe_hash, file, klen, slines, 0);
        TRACE(("PROBE created entry for file [%s]: %p\n", file, lines));
    }

    klen = sprintf(kstr, "%d", line);
    if (!create) {
        SV** rflag = hv_fetch(lines, kstr, klen, 0);
        return rflag && SvTRUE(*rflag);
    } else {
        SV* flag = &PL_sv_yes;
        hv_store(lines, kstr, klen, flag, 0);
        TRACE(("PROBE created entry for line [%s]\n", kstr));
    }

    return 1;
}

static OP* probe_nextstate(pTHX)
{
    OP* ret = probe_nextstate_orig(aTHX);

    do {
        const char* file = 0;
        int line = 0;

        if (!probe_is_enabled()) {
            break;
        }

        file = CopFILE(PL_curcop);
        line = CopLINE(PL_curcop);
        // it isn't always obvious what file path is being used (e.g., what you should put in the cfg file)
        TRACE(("PROBE check [%s] [%d]\n", file, line));
        if (!probe_lookup(file, line, 0)) {
            break;
        }

        INFO(("PROBE triggered [%s] [%d]\n", file, line));
        if (!probe_trigger_cb) {
            break;
        }

        probe_invoke_callback(file, line, probe_trigger_cb);
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

static int probe_is_enabled(void)
{
    return probe_enabled;
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
    probe_clear();

void
dump()
CODE:
    probe_dump();

void
add_probe(const char* file, int line)
CODE:
    probe_lookup(file, line, 1);

void
trigger(SV* callback)
CODE:
    if (probe_trigger_cb == (SV*)NULL) {
        probe_trigger_cb = newSVsv(callback);
    } else {
        SvSetSV(probe_trigger_cb, callback);
    }
