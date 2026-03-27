/*
 * XS.xs - High-performance auditing via custom ops for Medusa::XS
 *
 * Named after Medusa, the Gorgon whose gaze turned onlookers to stone.
 * This XS module turns slow Perl auditing into lightning-fast C operations.
 *
 * Architecture:
 * - Custom ops injected into subroutine optrees at compile time
 * - Direct caller stack walking via cx_stack (no Perl caller() overhead)
 * - Loo library for pure-XS data serialisation with colour support
 * - Horus library for RFC 9562 UUID generation (v1-v8, NIL, MAX)
 *
 * Requires Perl 5.10+. XOP debug names require 5.14+ (gracefully degraded).
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../../ppport.h"

#include <sys/time.h>  /* For gettimeofday() */
#include <ctype.h>     /* For toupper() */

/* Horus UUID library - pure C, no Perl deps */
#define HORUS_FATAL(msg) croak("%s", (msg))
#include "horus_core.h"

/* Loo Data Dumper - pure XS with colour support */
#include "loo.h"

/* ------------------------------------------------------------------ */
/* Compatibility macros for older Perls                                */
/* ------------------------------------------------------------------ */

/* mg_findext was added in 5.13.2; ppport.h may not backport it */
#ifndef mg_findext
static MAGIC *
medusa_mg_findext(const SV *sv, int type, const MGVTBL *vtbl) {
    MAGIC *mg;
    if (sv) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl)
                return mg;
        }
    }
    return NULL;
}
#define mg_findext(sv, type, vtbl) medusa_mg_findext(sv, type, vtbl)
#endif

/* GvCV_set was added in 5.13.3 */
#ifndef GvCV_set
#  define GvCV_set(gv, cv)  (GvGP(gv)->gp_cv = (CV *)(cv))
#endif

/* CvGV_set was added in 5.13.3 */
#ifndef CvGV_set
#  define CvGV_set(cv, gv)  (CvGV(cv) = (GV *)(gv))
#endif

/* ------------------------------------------------------------------ */
/* Compatibility macros for op sibling handling (5.22+)               */
/* ------------------------------------------------------------------ */

#ifndef OpSIBLING
#  define OpSIBLING(o) ((o)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* ------------------------------------------------------------------ */
/* Constants                                                           */
/* ------------------------------------------------------------------ */

#define MEDUSA_CALLER_STACK_INITIAL_SIZE 256
#define MEDUSA_GUID_LEN 36  /* UUID hyphenated: xxxxxxxx-xxxx-Vxxx-yxxx-xxxxxxxxxxxx */
#define MEDUSA_TIME_BUF_SIZE 64
#define MEDUSA_LOG_BUF_SIZE 4096
#define MEDUSA_LOGGER_WRITE_BUF 8192

/* ------------------------------------------------------------------ */
/* Medusa::XS::Logger - Pure C file logger with flock                  */
/* ------------------------------------------------------------------ */

typedef struct {
    PerlIO *fh;           /* Open file handle */
    char   *filename;     /* Allocated copy of filename */
    STRLEN  filename_len;
} MedusaLogger;

/* Magic vtable for MedusaLogger destructor */
static int medusa_logger_mg_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL medusa_logger_vtbl = {0, 0, 0, 0, medusa_logger_mg_free, 0, 0, 0};

static int
medusa_logger_mg_free(pTHX_ SV *sv, MAGIC *mg) {
    MedusaLogger *logger = (MedusaLogger *)mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    if (logger) {
        if (logger->fh) {
            PerlIO_close(logger->fh);
            logger->fh = NULL;
        }
        if (logger->filename) {
            Safefree(logger->filename);
            logger->filename = NULL;
        }
        Safefree(logger);
    }
    return 0;
}

/* Get the C struct from a blessed SV */
static MedusaLogger *
medusa_logger_from_sv(pTHX_ SV *sv) {
    MAGIC *mg;
    if (!sv || !SvROK(sv)) return NULL;
    mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &medusa_logger_vtbl);
    if (mg && mg->mg_ptr) {
        return (MedusaLogger *)mg->mg_ptr;
    }
    return NULL;
}

/* Core log write - pure C, no Perl dispatch.
 * Does flock(LOCK_EX), write, flock(LOCK_UN) in one shot. */
static void
medusa_logger_write(pTHX_ MedusaLogger *logger, const char *line, STRLEN len) {
    int fd;
    if (!logger || !logger->fh) return;
    
    fd = PerlIO_fileno(logger->fh);
    
    /* LOCK_EX = 2 */
    flock(fd, 2);
    PerlIO_write(logger->fh, line, len);
    PerlIO_write(logger->fh, "\n", 1);
    PerlIO_flush(logger->fh);
    /* LOCK_UN = 8 */
    flock(fd, 8);
}

/* ------------------------------------------------------------------ */
/* Forward declarations                                                */
/* ------------------------------------------------------------------ */

static void medusa_generate_guid(pTHX_ char *buf, int version,
                                  const char *ns_str, STRLEN ns_len,
                                  const char *name_str, STRLEN name_len);
static SV * medusa_format_time(pTHX_ bool use_gmtime, const char *fmt);
static int medusa_resolve_colour(pTHX_ HV *options);
static const char * medusa_resolve_theme(pTHX_ HV *options);
static void medusa_loo_style_init(pTHX_ DDCStyle *style, int use_colour,
                                   const char *theme_name);
static SV * medusa_dump_param(pTHX_ SV *value, DDCStyle *style);
static void medusa_dump_param_into(pTHX_ SV *value, DDCStyle *style, SV *out);
static SV * medusa_collect_caller_stack(pTHX);
static SV * medusa_build_log_message(pTHX_ HV *log_config, const char *level,
                                     SV *guid, SV *caller_stack, SV *method_name,
                                     const char *msg_type, AV *params,
                                     const char *prefix, double elapsed);
static void medusa_collect_caller_stack_into(pTHX_ SV *result);

/* ------------------------------------------------------------------ */
/* Cached metadata structures                                          */
/* ------------------------------------------------------------------ */

/* AUDIT_CACHE - Cached metadata for fast wrapper execution */
typedef struct {
    CV *original_cv;      /* Original subroutine CV */
    const char *method;   /* Method name (points into CV's GV) */
    STRLEN method_len;
    const char *package;  /* Package name (points into stash) */
    STRLEN package_len;
    HV *log_config;       /* Cached pointer to %Medusa::XS::LOG */
    HV *options;          /* Cached pointer to $LOG{OPTIONS} hashref */
    bool opt_guid;        /* Cached option values */
    bool opt_caller;
    bool opt_elapsed;
    bool opt_date;
    bool opt_level;
    int  guid_version;    /* UUID version: 0=NIL, 1-8, -1=MAX (default 4) */
    char *guid_namespace; /* For v3/v5: namespace string (allocated copy) */
    STRLEN guid_namespace_len;
    char *guid_name;      /* For v3/v5: name string (allocated copy) */
    STRLEN guid_name_len;
    SV *format_message;   /* Cached FORMAT_MESSAGE coderef (or NULL for XS default) */
    bool use_xs_format;   /* TRUE if using XS FORMAT_MESSAGE */
    /* Pre-formatted message strings (saves snprintf per call) */
    SV *entry_msg;        /* "subroutine X called with args:" */
    SV *exit_msg;         /* "subroutine X returned:" */
    /* Cached logger info */
    const char *log_level;   /* Cached LOG_LEVEL string */
    const char *log_method;  /* Cached method name for logging */
    /* Cached format config (avoids per-call hash lookups in format_message) */
    const char *quote;       /* Cached QUOTE character */
    const char *time_type;   /* Cached TIME type ("gmtime"/"localtime") */
    const char *time_fmt;    /* Cached TIME_FORMAT string */
    bool time_use_gm;        /* Pre-computed: use gmtime? */
    const char *time_fmt_c;  /* Pre-computed: NULL if "default", else fmt string */
    /* Cached log level uppercase (avoids toupper loop per call) */
    char level_upper[32];
    /* Cached logger object (avoid hv_fetchs per call) */
    SV *log_obj;             /* Cached $LOG{LOG} logger object */
    bool log_obj_initialized; /* TRUE after first LOG_INIT call */
    /* Cached resolved method CV for logger dispatch (avoids call_method lookup) */
    CV *log_method_cv;       /* Resolved CV for $log_obj->$log_method */
    /* --- Per-call scratch buffers (avoid SV allocation per call) --- */
    SV *scratch_result;      /* Reusable SV for log message formatting */
    SV *scratch_guid;        /* Reusable SV for GUID string */
    SV *scratch_caller;      /* Reusable SV for caller stack */
    SV *scratch_dump;        /* Reusable SV for dump output */
    /* --- Loo dumper style (pre-configured, cached) --- */
    DDCStyle dump_style;     /* Pre-configured Loo style for param dumps */
    int dump_style_init;     /* TRUE after style has been initialised */
    /* --- Direct C logger write bypass --- */
    bool use_direct_write;   /* TRUE when logger is Medusa::XS::Logger */
    MedusaLogger *direct_logger; /* Cached C logger struct for direct write */
} AUDIT_CACHE;

/* ------------------------------------------------------------------ */
/* Custom op forward declarations                                      */
/* ------------------------------------------------------------------ */

static OP *pp_medusa_caller_stack(pTHX);
static OP *pp_medusa_format_log(pTHX);
static OP *pp_medusa_log_write(pTHX);

#if PERL_VERSION >= 14
static XOP medusa_xop_caller_stack;
static XOP medusa_xop_format_log;
static XOP medusa_xop_log_write;
#endif

/* ------------------------------------------------------------------ */
/* Optree injection: inject_audit_wrapper()                            */
/* ------------------------------------------------------------------ */

/* Forward declarations */
static CV * wrap_existing_cv(pTHX_ CV *orig_cv, const char *method, STRLEN method_len,
                              const char *pkg, STRLEN pkg_len);

/*
 * inject_audit_wrapper - Wrap a CV with audit enter/leave ops
 *
 * This creates a wrapper that:
 * 1. Logs entry (call args, GUID, caller stack, timestamp)
 * 2. Calls the original subroutine
 * 3. Logs exit (return values, elapsed time)
 */

/* Magic vtable to identify wrapped CVs */
static MGVTBL medusa_cv_vtbl = {0, 0, 0, 0, 0, 0, 0, 0};

/* Magic vtable for AUDIT_CACHE - with destructor */
static int medusa_cache_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL medusa_cache_vtbl = {0, 0, 0, 0, medusa_cache_free, 0, 0, 0};

static int
medusa_cache_free(pTHX_ SV *sv, MAGIC *mg) {
    AUDIT_CACHE *cache = (AUDIT_CACHE *)mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    if (cache) {
        /* Free pre-formatted message strings */
        if (cache->entry_msg) SvREFCNT_dec(cache->entry_msg);
        if (cache->exit_msg) SvREFCNT_dec(cache->exit_msg);
        /* Free scratch buffers */
        if (cache->scratch_result) SvREFCNT_dec(cache->scratch_result);
        if (cache->scratch_guid) SvREFCNT_dec(cache->scratch_guid);
        if (cache->scratch_caller) SvREFCNT_dec(cache->scratch_caller);
        if (cache->scratch_dump) SvREFCNT_dec(cache->scratch_dump);
        /* Free Loo dump style internals */
        if (cache->dump_style_init)
            ddc_style_destroy(aTHX_ &cache->dump_style);
        /* Free GUID config strings */
        if (cache->guid_namespace) Safefree(cache->guid_namespace);
        if (cache->guid_name) Safefree(cache->guid_name);
        /* Don't free method/package - they point into GV/stash */
        /* Don't free format_message - it's owned by %LOG */
        /* Don't free direct_logger - owned by logger object magic */
        Safefree(cache);
    }
    return 0;
}

/* Get cached audit metadata from wrapper CV */
static AUDIT_CACHE *
get_audit_cache(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV*)cv, PERL_MAGIC_ext, &medusa_cache_vtbl);
    if (mg && mg->mg_ptr) {
        return (AUDIT_CACHE *)mg->mg_ptr;
    }
    return NULL;
}

/* Create and attach AUDIT_CACHE to wrapper CV */
static AUDIT_CACHE *
create_audit_cache(pTHX_ CV *wrapper_cv, CV *orig_cv, 
                   const char *method, STRLEN method_len,
                   const char *pkg, STRLEN pkg_len) {
    AUDIT_CACHE *cache;
    HV *log_config;
    SV **svp;
    char msg_buf[256];
    
    Newxz(cache, 1, AUDIT_CACHE);
    
    cache->original_cv = orig_cv;
    cache->method = method;
    cache->method_len = method_len;
    cache->package = pkg;
    cache->package_len = pkg_len;
    
    /* Pre-format message strings (saves snprintf per call) */
    snprintf(msg_buf, sizeof(msg_buf), "subroutine %s called with args:", method);
    cache->entry_msg = newSVpv(msg_buf, 0);
    SvREADONLY_on(cache->entry_msg);
    
    snprintf(msg_buf, sizeof(msg_buf), "subroutine %s returned:", method);
    cache->exit_msg = newSVpv(msg_buf, 0);
    SvREADONLY_on(cache->exit_msg);
    
    /* Cache %LOG reference */
    log_config = get_hv("Medusa::XS::LOG", 0);
    cache->log_config = log_config;
    
    /* Cache OPTIONS and individual flags */
    cache->opt_guid = cache->opt_caller = cache->opt_elapsed = TRUE;
    cache->opt_date = cache->opt_level = TRUE;
    cache->use_xs_format = TRUE;
    cache->log_level = "debug";
    cache->log_method = "debug";
    
    if (log_config) {
        svp = hv_fetchs(log_config, "OPTIONS", 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
            HV *options = (HV *)SvRV(*svp);
            SV **opt;
            
            cache->options = options;
            
            opt = hv_fetchs(options, "guid", 0);
            if (opt) cache->opt_guid = SvTRUE(*opt);
            
            opt = hv_fetchs(options, "caller", 0);
            if (opt) cache->opt_caller = SvTRUE(*opt);
            
            opt = hv_fetchs(options, "elapsed_call", 0);
            if (opt) cache->opt_elapsed = SvTRUE(*opt);
            
            opt = hv_fetchs(options, "date", 0);
            if (opt) cache->opt_date = SvTRUE(*opt);
            
            opt = hv_fetchs(options, "level", 0);
            if (opt) cache->opt_level = SvTRUE(*opt);

            /* GUID version config */
            cache->guid_version = 4;  /* default: UUID v4 */
            opt = hv_fetchs(options, "guid_version", 0);
            if (opt && SvOK(*opt)) cache->guid_version = SvIV(*opt);

            /* GUID namespace (for v3/v5) */
            opt = hv_fetchs(options, "guid_namespace", 0);
            if (opt && SvPOK(*opt)) {
                const char *ns = SvPV(*opt, cache->guid_namespace_len);
                Newx(cache->guid_namespace, cache->guid_namespace_len + 1, char);
                Copy(ns, cache->guid_namespace, cache->guid_namespace_len, char);
                cache->guid_namespace[cache->guid_namespace_len] = '\0';
            }

            /* GUID name (for v3/v5) */
            opt = hv_fetchs(options, "guid_name", 0);
            if (opt && SvPOK(*opt)) {
                const char *nm = SvPV(*opt, cache->guid_name_len);
                Newx(cache->guid_name, cache->guid_name_len + 1, char);
                Copy(nm, cache->guid_name, cache->guid_name_len, char);
                cache->guid_name[cache->guid_name_len] = '\0';
            }
        }
        
        /* Cache log level */
        svp = hv_fetchs(log_config, "LOG_LEVEL", 0);
        if (svp && SvPOK(*svp)) {
            cache->log_level = SvPV_nolen(*svp);
        }
        
        /* Pre-compute uppercase log level */
        {
            int i;
            for (i = 0; cache->log_level[i] && i < 31; i++) {
                cache->level_upper[i] = toupper((unsigned char)cache->log_level[i]);
            }
            cache->level_upper[i] = '\0';
        }
        
        /* Cache log method from LOG_FUNCTIONS */
        svp = hv_fetchs(log_config, "LOG_FUNCTIONS", 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
            HV *funcs = (HV *)SvRV(*svp);
            SV **meth = hv_fetch(funcs, cache->log_level, strlen(cache->log_level), 0);
            if (meth && SvPOK(*meth)) {
                cache->log_method = SvPV_nolen(*meth);
            }
        }
        
        /* Cache QUOTE character */
        cache->quote = "\xE2\x80\xA0"; /* default: † */
        svp = hv_fetchs(log_config, "QUOTE", 0);
        if (svp && SvPOK(*svp)) {
            cache->quote = SvPV_nolen(*svp);
        }
        
        /* Cache TIME settings */
        cache->time_type = "gmtime";
        svp = hv_fetchs(log_config, "TIME", 0);
        if (svp && SvPOK(*svp)) {
            cache->time_type = SvPV_nolen(*svp);
        }
        cache->time_use_gm = (strcmp(cache->time_type, "gmtime") == 0);
        
        cache->time_fmt = "default";
        svp = hv_fetchs(log_config, "TIME_FORMAT", 0);
        if (svp && SvPOK(*svp)) {
            cache->time_fmt = SvPV_nolen(*svp);
        }
        cache->time_fmt_c = (strcmp(cache->time_fmt, "default") == 0) ? NULL : cache->time_fmt;
        
        /* Don't cache LOG object at compile time — it may change at runtime.
         * The lazy init in medusa_xs_log_cached will pick up the correct
         * logger on the first call. */
        cache->log_obj = NULL;
        cache->log_obj_initialized = FALSE;
        cache->log_method_cv = NULL;
        cache->use_direct_write = FALSE;
        cache->direct_logger = NULL;
        
        /* Check if FORMAT_MESSAGE is the default XS wrapper */
        svp = hv_fetchs(log_config, "FORMAT_MESSAGE", 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
            CV *fm_cv = (CV *)SvRV(*svp);
            /* Detect our own xs_format_message XSUB — still use fast path */
            GV *xs_fmt_gv = gv_fetchpvs("Medusa::XS::xs_format_message",
                                         GV_NOADD_NOINIT, SVt_PVCV);
            if (xs_fmt_gv && GvCV(xs_fmt_gv) && fm_cv == GvCV(xs_fmt_gv)) {
                /* It's our default — keep use_xs_format = TRUE */
            } else {
                cache->format_message = *svp;
                cache->use_xs_format = FALSE;
            }
        }
    }
    
    /* Allocate scratch buffers (reused across calls) */
    cache->scratch_result = newSV(MEDUSA_LOG_BUF_SIZE);
    SvPOK_on(cache->scratch_result);
    SvCUR_set(cache->scratch_result, 0);
    *SvPVX(cache->scratch_result) = '\0';
    
    cache->scratch_guid = newSV(MEDUSA_GUID_LEN + 1);
    SvPOK_on(cache->scratch_guid);
    SvCUR_set(cache->scratch_guid, 0);
    
    cache->scratch_caller = newSV(MEDUSA_CALLER_STACK_INITIAL_SIZE);
    SvPOK_on(cache->scratch_caller);
    SvCUR_set(cache->scratch_caller, 0);
    
    cache->scratch_dump = newSV(256);
    SvPOK_on(cache->scratch_dump);
    SvCUR_set(cache->scratch_dump, 0);

    /* Initialise Loo dump style with colour from OPTIONS */
    {
        int use_colour = medusa_resolve_colour(aTHX_ cache->options);
        const char *theme = medusa_resolve_theme(aTHX_ cache->options);
        medusa_loo_style_init(aTHX_ &cache->dump_style, use_colour, theme);
        cache->dump_style_init = 1;
    }
    
    /* Attach cache to wrapper CV */
    sv_magicext((SV*)wrapper_cv, NULL, PERL_MAGIC_ext, &medusa_cache_vtbl,
                (const char *)cache, 0);
    
    return cache;
}

/* Check if a CV is already wrapped */
#define CV_IS_AUDITED(cv) (SvMAGICAL((SV*)cv) && mg_findext((SV*)cv, PERL_MAGIC_ext, &medusa_cv_vtbl))

/* Store original CV in magic for later retrieval */
static void
mark_cv_audited(pTHX_ CV *cv, const char *method, STRLEN method_len) {
    MAGIC *mg;
    if (!CV_IS_AUDITED(cv)) {
        mg = sv_magicext((SV*)cv, NULL, PERL_MAGIC_ext, &medusa_cv_vtbl, method, method_len);
        mg->mg_flags |= MGf_DUP;
    }
}

/* Get method name from audited CV magic */
static const char *
get_audited_method(pTHX_ CV *cv, STRLEN *len) {
    MAGIC *mg = mg_findext((SV*)cv, PERL_MAGIC_ext, &medusa_cv_vtbl);
    if (mg && mg->mg_ptr) {
        *len = mg->mg_len;
        return mg->mg_ptr;
    }
    *len = 0;
    return NULL;
}

/*
 * Deferred wrapping for older Perls (5.10-5.12).
 *
 * On 5.10, MODIFY_CODE_ATTRIBUTES fires inside newATTRSUB before the CV
 * is installed into the glob.  CvGV(cv) is NULL at that point.
 *
 * Strategy: queue (original_cv, pkg_name) pairs.  In CHECK phase,
 * scan the package stash to find which GV now points to each CV,
 * then create the wrapper and replace the GV's CV.
 */
static AV *medusa_pending_wraps = NULL;

/* Queue an original CV + package name for deferred wrapping */
static void
medusa_queue_deferred_wrap(pTHX_ CV *cv, const char *pkg, STRLEN pkg_len)
{
    if (!medusa_pending_wraps) {
        medusa_pending_wraps = newAV();
    }
    av_push(medusa_pending_wraps, newRV_inc((SV *)cv));
    av_push(medusa_pending_wraps, newSVpvn(pkg, pkg_len));
}

/* CHECK-phase callback: apply all deferred wraps */
static void
medusa_check_apply_wraps(pTHX_ void *data)
{
    I32 i, len;
    PERL_UNUSED_VAR(data);

    if (!medusa_pending_wraps) return;
    len = av_len(medusa_pending_wraps);

    /* Each entry is a pair: [cv_rv, pkg_sv] stored as consecutive elements */
    for (i = 0; i <= len; i += 2) {
        SV **cv_rvp  = av_fetch(medusa_pending_wraps, i, 0);
        SV **pkg_svp = av_fetch(medusa_pending_wraps, i + 1, 0);
        if (cv_rvp && SvROK(*cv_rvp) && pkg_svp && SvPOK(*pkg_svp)) {
            CV *orig_cv = (CV *)SvRV(*cv_rvp);
            const char *pkg;
            STRLEN pkg_len;
            HV *stash;
            HE *he;
            GV *found_gv = NULL;
            const char *method_name = NULL;
            STRLEN method_len = 0;

            pkg = SvPV(*pkg_svp, pkg_len);
            stash = gv_stashpvn(pkg, pkg_len, 0);
            if (!stash) continue;

            /* Scan the stash to find which GV holds this CV */
            hv_iterinit(stash);
            while ((he = hv_iternext(stash))) {
                GV *gv = (GV *)HeVAL(he);
                if (isGV(gv) && GvCV(gv) == orig_cv) {
                    found_gv = gv;
                    method_name = GvNAME(gv);
                    method_len = GvNAMELEN(gv);
                    break;
                }
            }

            if (found_gv && method_name) {
                CV *wrapper_cv;

                /* Update the audited mark with the real method name */
                mark_cv_audited(aTHX_ orig_cv, method_name, method_len);

                /* Create wrapper CV */
                wrapper_cv = wrap_existing_cv(aTHX_ orig_cv, method_name,
                                              method_len, pkg, pkg_len);
                if (wrapper_cv) {
                    GvCV_set(found_gv, wrapper_cv);
                    CvGV_set(wrapper_cv, found_gv);
                }
            }
        }
    }
    av_clear(medusa_pending_wraps);
}

/*
 * inject_audit_wrapper - Main entry point for wrapping a subroutine
 *
 * Called when :Audit attribute is applied to a subroutine.
 * Replaces the CV's body with the audit wrapper XSUB.
 */
static void
inject_audit_wrapper(pTHX_ CV *cv, const char *method, STRLEN method_len,
                     const char *pkg, STRLEN pkg_len) {
    GV *gv;
    CV *wrapper_cv;

    if (!cv) return;

    /* Don't wrap if already audited */
    if (CV_IS_AUDITED(cv)) {
        return;
    }

    /* Get the GV for this CV so we can replace it in the stash */
    gv = CvGV(cv);

    if (!gv) {
        /* On 5.10, CvGV is NULL inside MODIFY_CODE_ATTRIBUTES because
         * newATTRSUB hasn't installed the CV into the glob yet.
         * Queue for deferred wrapping in CHECK phase. */
        medusa_queue_deferred_wrap(aTHX_ cv, pkg, pkg_len);
        return;
    }

    /* Mark the original CV as audited */
    mark_cv_audited(aTHX_ cv, method, method_len);

    /* Create wrapper CV */
    wrapper_cv = wrap_existing_cv(aTHX_ cv, method, method_len, pkg, pkg_len);
    if (!wrapper_cv) {
        return;
    }

    /* Replace the CV in the glob */
    GvCV_set(gv, wrapper_cv);
    CvGV_set(wrapper_cv, gv);
}

/* Forward declaration of wrapper XSUB */
XS(XS_Medusa__XS_audit_wrapper);

/*
 * wrap_existing_cv - Wrap an existing CV with audit functionality
 *
 * Creates XSUB wrapper + AUDIT_CACHE with all config pre-computed.
 */
static CV *
wrap_existing_cv(pTHX_ CV *orig_cv, const char *method, STRLEN method_len,
                 const char *pkg, STRLEN pkg_len) {
    CV *wrapper_cv;
    AUDIT_CACHE *cache;
    
    if (!orig_cv) return NULL;
    
    /* Create a new wrapper CV */
    wrapper_cv = newXS(NULL, XS_Medusa__XS_audit_wrapper, __FILE__);
    
    /* Store original CV ref in wrapper for later retrieval */
    CvXSUBANY(wrapper_cv).any_ptr = (void *)orig_cv;
    SvREFCNT_inc((SV *)orig_cv);
    
    /* Mark the wrapper as audited */
    mark_cv_audited(aTHX_ wrapper_cv, method, method_len);
    
    /* Create cached metadata for fast wrapper execution */
    cache = create_audit_cache(aTHX_ wrapper_cv, orig_cv, 
                               method, method_len, pkg, pkg_len);
    
    return wrapper_cv;
}

/* ------------------------------------------------------------------ */
/* XS integrated logging - calls Perl FORMAT_MESSAGE and logger       */
/* ------------------------------------------------------------------ */

/* Forward declaration */
static void medusa_xs_log_message(pTHX_ HV *params);

/* ------------------------------------------------------------------ */
/* Colour resolution helpers                                           */
/* ------------------------------------------------------------------ */

/* Resolve colour setting from OPTIONS hash: 0=off, 1=on, 'auto'=detect */
static int
medusa_resolve_colour(pTHX_ HV *options)
{
    SV **svp;

    if (!options) return 1;  /* default: enabled */

    svp = hv_fetchs(options, "colour", 0);
    if (!svp || !SvOK(*svp)) return 1;  /* default: enabled */

    /* Check for 'auto' string */
    if (SvPOK(*svp)) {
        const char *val = SvPV_nolen(*svp);
        if (strEQ(val, "auto"))
            return loo_detect_colour(aTHX);
        /* "0" or "1" as string */
        return SvTRUE(*svp) ? 1 : 0;
    }

    return SvIV(*svp) ? 1 : 0;
}

/* Resolve theme name from OPTIONS hash */
static const char *
medusa_resolve_theme(pTHX_ HV *options)
{
    SV **svp;

    if (!options) return "default";

    svp = hv_fetchs(options, "colour_theme", 0);
    if (svp && SvPOK(*svp))
        return SvPV_nolen(*svp);

    return "default";
}

/* ------------------------------------------------------------------ */
/* Loo-based SV serializer (replaces custom dump and Data::Dumper)     */
/* ------------------------------------------------------------------ */

/* Initialise a DDCStyle for Medusa's compact log output */
static void
medusa_loo_style_init(pTHX_ DDCStyle *style, int use_colour,
                  const char *theme_name)
{
    ddc_style_init(style);

    /* Compact output for log lines */
    style->terse      = 1;    /* no $VARn = */
    style->indent     = 0;    /* single-line output */
    style->sortkeys   = 1;    /* deterministic key order */
    style->maxdepth   = 8;    /* same limit as before */
    style->quotekeys  = 0;    /* cleaner output */
    style->useqq      = 1;    /* escape non-printable chars */

    /* Colour */
    style->use_colour = use_colour;
    if (use_colour && theme_name) {
        const LooTheme *theme = loo_find_theme(theme_name);
        if (theme) {
            style->c_string_fg   = theme->string_fg   ? ddc_resolve_colour_named(theme->string_fg, 0)   : NULL;
            style->c_number_fg   = theme->number_fg   ? ddc_resolve_colour_named(theme->number_fg, 0)   : NULL;
            style->c_key_fg      = theme->key_fg      ? ddc_resolve_colour_named(theme->key_fg, 0)      : NULL;
            style->c_brace_fg    = theme->brace_fg    ? ddc_resolve_colour_named(theme->brace_fg, 0)    : NULL;
            style->c_bracket_fg  = theme->bracket_fg  ? ddc_resolve_colour_named(theme->bracket_fg, 0)  : NULL;
            style->c_paren_fg    = theme->paren_fg    ? ddc_resolve_colour_named(theme->paren_fg, 0)    : NULL;
            style->c_arrow_fg    = theme->arrow_fg    ? ddc_resolve_colour_named(theme->arrow_fg, 0)    : NULL;
            style->c_comma_fg    = theme->comma_fg    ? ddc_resolve_colour_named(theme->comma_fg, 0)    : NULL;
            style->c_undef_fg    = theme->undef_fg    ? ddc_resolve_colour_named(theme->undef_fg, 0)    : NULL;
            style->c_blessed_fg  = theme->blessed_fg  ? ddc_resolve_colour_named(theme->blessed_fg, 0)  : NULL;
            style->c_regex_fg    = theme->regex_fg    ? ddc_resolve_colour_named(theme->regex_fg, 0)    : NULL;
            style->c_code_fg     = theme->code_fg     ? ddc_resolve_colour_named(theme->code_fg, 0)     : NULL;
            style->c_variable_fg = theme->variable_fg ? ddc_resolve_colour_named(theme->variable_fg, 0) : NULL;
            style->c_quote_fg    = theme->quote_fg    ? ddc_resolve_colour_named(theme->quote_fg, 0)    : NULL;
            style->c_reset       = "\033[0m";
        }
    }
}

/* Dump a single SV to a compact string via Loo */
static SV *
medusa_dump_param(pTHX_ SV *value, DDCStyle *style)
{
    SV *out;

    /* Reset per-dump state */
    style->level = 0;
    if (style->seen) hv_clear(style->seen);
    else style->seen = newHV();
    if (style->post) av_clear(style->post);
    else style->post = newAV();

    out = newSVpvn("", 0);
    SvGROW(out, 256);
    style->out = out;

    ddc_dump_ref(aTHX_ value, style, 0);

    return out;
}

/* Dump a single SV into a pre-allocated buffer (hot-path, no alloc) */
static void
medusa_dump_param_into(pTHX_ SV *value, DDCStyle *style, SV *out)
{
    /* Reset per-dump state */
    style->level = 0;
    if (style->seen) hv_clear(style->seen);
    else style->seen = newHV();
    if (style->post) av_clear(style->post);
    else style->post = newAV();

    SvCUR_set(out, 0);
    *SvPVX(out) = '\0';
    style->out = out;

    ddc_dump_ref(aTHX_ value, style, 0);
}




/*
 * XS implementation of FORMAT_MESSAGE
 * Matches the Perl implementation in original Medusa
 */
static SV *
medusa_xs_format_message(pTHX_ HV *params, HV *log_config) {
    SV *result;
    SV **svp;
    HV *options = NULL;
    bool opt_date, opt_guid, opt_level, opt_caller, opt_elapsed;
    const char *quote = "†";
    const char *time_type = "gmtime";
    const char *time_fmt = "default";
    const char *log_level = "debug";
    SV *timestamp = NULL;
    
    /* Get quote character */
    svp = hv_fetchs(log_config, "QUOTE", 0);
    if (svp && SvPOK(*svp)) {
        quote = SvPV_nolen(*svp);
    }
    
    /* Get TIME setting */
    svp = hv_fetchs(log_config, "TIME", 0);
    if (svp && SvPOK(*svp)) {
        time_type = SvPV_nolen(*svp);
    }
    
    /* Get TIME_FORMAT */
    svp = hv_fetchs(log_config, "TIME_FORMAT", 0);
    if (svp && SvPOK(*svp)) {
        time_fmt = SvPV_nolen(*svp);
    }
    
    /* Get options hash */
    opt_date = opt_guid = opt_level = opt_caller = opt_elapsed = TRUE;
    svp = hv_fetchs(log_config, "OPTIONS", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
        options = (HV *)SvRV(*svp);
        SV **opt;
        
        opt = hv_fetchs(options, "date", 0);
        if (opt) opt_date = SvTRUE(*opt);
        
        opt = hv_fetchs(options, "guid", 0);
        if (opt) opt_guid = SvTRUE(*opt);
        
        opt = hv_fetchs(options, "level", 0);
        if (opt) opt_level = SvTRUE(*opt);
        
        opt = hv_fetchs(options, "caller", 0);
        if (opt) opt_caller = SvTRUE(*opt);
        
        opt = hv_fetchs(options, "elapsed_call", 0);
        if (opt) opt_elapsed = SvTRUE(*opt);
    }
    
    /* Get level from params */
    svp = hv_fetchs(params, "level", 0);
    if (svp && SvPOK(*svp)) {
        log_level = SvPV_nolen(*svp);
    }
    
    result = newSVpvn("", 0);
    SvGROW(result, MEDUSA_LOG_BUF_SIZE);
    
    /* Add timestamp */
    if (opt_date) {
        bool use_gm = (strcmp(time_type, "gmtime") == 0);
        const char *fmt = (strcmp(time_fmt, "default") == 0) ? NULL : time_fmt;
        timestamp = medusa_format_time(aTHX_ use_gm, fmt);
        sv_catpvf(result, "%s ", SvPV_nolen(timestamp));
        SvREFCNT_dec(timestamp);
    }
    
    /* Add GUID */
    if (opt_guid) {
        svp = hv_fetchs(params, "guid", 0);
        if (svp && SvOK(*svp)) {
            sv_catpvf(result, "%s ", SvPV_nolen(*svp));
        }
    }
    
    /* Add log level (uppercase) */
    if (opt_level) {
        char level_upper[32];
        int i;
        for (i = 0; log_level[i] && i < 31; i++) {
            level_upper[i] = toupper((unsigned char)log_level[i]);
        }
        level_upper[i] = '\0';
        sv_catpv(result, level_upper);
    }
    
    /* Add caller stack */
    if (opt_caller) {
        svp = hv_fetchs(params, "caller", 0);
        if (svp && SvOK(*svp) && SvCUR(*svp) > 0) {
            sv_catpvf(result, " caller=%s%s%s", quote, SvPV_nolen(*svp), quote);
        }
    }
    
    /* Add message */
    svp = hv_fetchs(params, "message", 0);
    if (svp && SvOK(*svp)) {
        sv_catpvf(result, " message=%s%s%s", quote, SvPV_nolen(*svp), quote);
    }
    
    /* Add elapsed if present (check both 'elapsed' and 'elapsed_call' keys) */
    if (opt_elapsed) {
        svp = hv_fetchs(params, "elapsed_call", 0);
        if (svp && SvOK(*svp)) {
            sv_catpvf(result, " elapsed_call=%s%s%s", quote, SvPV_nolen(*svp), quote);
        } else {
            svp = hv_fetchs(params, "elapsed", 0);
            if (svp && SvOK(*svp)) {
                sv_catpvf(result, " elapsed=%s%s%s", quote, SvPV_nolen(*svp), quote);
            }
        }
    }
    
    /* Add params array (arg0, arg1, ... or return0, return1, ...) */
    svp = hv_fetchs(params, "params", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
        AV *params_av = (AV *)SvRV(*svp);
        I32 len = av_len(params_av);
        I32 i;
        SV **prefix_sv = hv_fetchs(params, "prefix", 0);
        const char *prefix = (prefix_sv && SvPOK(*prefix_sv)) ? SvPV_nolen(*prefix_sv) : "arg";

        {
            DDCStyle style;
            int use_colour = medusa_resolve_colour(aTHX_ options);
            const char *theme = medusa_resolve_theme(aTHX_ options);
            medusa_loo_style_init(aTHX_ &style, use_colour, theme);
            for (i = 0; i <= len; i++) {
                SV **elem = av_fetch(params_av, i, 0);
                if (elem && *elem) {
                    SV *cleaned = medusa_dump_param(aTHX_ *elem, &style);
                    sv_catpvf(result, " %s%d=%s%s%s", prefix, (int)i, quote, SvPV_nolen(cleaned), quote);
                    SvREFCNT_dec(cleaned);
                }
            }
            ddc_style_destroy(aTHX_ &style);
        }
    }

    return result;
}

/*
 * Fast-path format+log that uses AUDIT_CACHE directly.
 * Eliminates ALL hash lookups from the log pipeline.
 * Uses scratch SVs to avoid per-call SV allocation.
 * Uses direct C write bypass for Medusa::XS::Logger.
 * Only used when use_xs_format is TRUE (no custom Perl FORMAT_MESSAGE).
 */
static void
medusa_xs_log_cached(pTHX_ AUDIT_CACHE *cache, SV *guid_sv, SV *caller_sv,
                     SV *message_sv, AV *params_av, const char *prefix,
                     const char *elapsed_str) {
    dSP;
    SV *result;
    SV *log_obj;
    
    /* Get/initialize logger object (lazy — only on first call) */
    if (!cache->log_obj_initialized) {
        HV *log_config = cache->log_config;
        SV **svp;
        
        if (!log_config) return;
        
        svp = hv_fetchs(log_config, "LOG", 0);
        if (!svp || !SvROK(*svp)) {
            /* Call LOG_INIT */
            SV **init_cb = hv_fetchs(log_config, "LOG_INIT", 0);
            if (init_cb && SvROK(*init_cb)) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                PUTBACK;
                call_sv(*init_cb, G_SCALAR);
                SPAGAIN;
                log_obj = POPs;
                if (SvROK(log_obj)) {
                    hv_stores(log_config, "LOG", SvREFCNT_inc(log_obj));
                    cache->log_obj = log_obj;
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            svp = hv_fetchs(log_config, "LOG", 0);
        }
        
        if (!svp || !SvROK(*svp)) return;
        cache->log_obj = *svp;
        cache->log_obj_initialized = TRUE;
        /* Resolve method CV for direct dispatch */
        {
            GV *method_gv = gv_fetchmethod_autoload(
                SvSTASH(SvRV(*svp)), cache->log_method, FALSE);
            if (method_gv && isGV(method_gv) && GvCV(method_gv)) {
                cache->log_method_cv = GvCV(method_gv);
            }
        }
        /* Detect Medusa::XS::Logger for direct C write bypass */
        {
            HV *stash = SvSTASH(SvRV(*svp));
            if (stash) {
                const char *name = HvNAME(stash);
                if (name && strcmp(name, "Medusa::XS::Logger") == 0) {
                    MedusaLogger *lg = medusa_logger_from_sv(aTHX_ *svp);
                    if (lg) {
                        cache->use_direct_write = TRUE;
                        cache->direct_logger = lg;
                    }
                }
            }
        }
    }
    
    log_obj = cache->log_obj;
    if (!log_obj || !SvROK(log_obj)) return;

    /* Runtime colour toggle: re-read colour setting from OPTIONS and
     * reinit the dump style if it changed (Option A: ~50ns hash fetch) */
    if (cache->options) {
        int current_colour = medusa_resolve_colour(aTHX_ cache->options);
        if (cache->dump_style.use_colour != current_colour) {
            const char *theme = medusa_resolve_theme(aTHX_ cache->options);
            if (cache->dump_style_init)
                ddc_style_destroy(aTHX_ &cache->dump_style);
            medusa_loo_style_init(aTHX_ &cache->dump_style, current_colour, theme);
            cache->dump_style_init = 1;
        }
    }
    
    /* Reuse scratch result SV (avoid newSV + SvGROW per call) */
    result = cache->scratch_result;
    SvCUR_set(result, 0);
    *SvPVX(result) = '\0';
    
    /* Timestamp — write directly into a stack buffer */
    if (cache->opt_date) {
        struct timeval tv;
        struct tm *tm_info;
        char tbuf[MEDUSA_TIME_BUF_SIZE];
        
        gettimeofday(&tv, NULL);
        tm_info = cache->time_use_gm ? gmtime(&tv.tv_sec) : localtime(&tv.tv_sec);
        
        if (!cache->time_fmt_c) {
            strftime(tbuf, sizeof(tbuf), "%a %b %e %H:%M:%S %Y", tm_info);
        } else {
            char *ms_pos;
            char fmt_copy[128];
            strncpy(fmt_copy, cache->time_fmt_c, sizeof(fmt_copy) - 1);
            fmt_copy[sizeof(fmt_copy) - 1] = '\0';
            ms_pos = strstr(fmt_copy, "%ms");
            if (ms_pos) {
                char ms_buf[16];
                STRLEN len;
                snprintf(ms_buf, sizeof(ms_buf), "%03ld", tv.tv_usec / 1000);
                *ms_pos = '\0';
                strftime(tbuf, sizeof(tbuf), fmt_copy, tm_info);
                len = strlen(tbuf);
                snprintf(tbuf + len, sizeof(tbuf) - len, "%s%s", ms_buf, ms_pos + 3);
            } else {
                strftime(tbuf, sizeof(tbuf), fmt_copy, tm_info);
            }
        }
        sv_catpv(result, tbuf);
        sv_catpvn(result, " ", 1);
    }
    
    /* GUID — use sv_catpvn instead of sv_catpvf */
    if (cache->opt_guid && guid_sv) {
        sv_catsv(result, guid_sv);
        sv_catpvn(result, " ", 1);
    }
    
    /* Level (pre-computed uppercase) */
    if (cache->opt_level) {
        sv_catpv(result, cache->level_upper);
    }
    
    /* Caller stack — decompose sv_catpvf into sv_catpvn calls */
    if (cache->opt_caller && caller_sv && SvCUR(caller_sv) > 0) {
        sv_catpvn(result, " caller=", 8);
        sv_catpv(result, cache->quote);
        sv_catsv(result, caller_sv);
        sv_catpv(result, cache->quote);
    }
    
    /* Message */
    if (message_sv && SvOK(message_sv)) {
        sv_catpvn(result, " message=", 9);
        sv_catpv(result, cache->quote);
        sv_catsv(result, message_sv);
        sv_catpv(result, cache->quote);
    }
    
    /* Elapsed */
    if (cache->opt_elapsed && elapsed_str) {
        sv_catpvn(result, " elapsed_call=", 14);
        sv_catpv(result, cache->quote);
        sv_catpv(result, elapsed_str);
        sv_catpv(result, cache->quote);
    }
    
    /* Params — use Loo dump style with scratch_dump buffer */
    if (params_av) {
        I32 len = av_len(params_av);
        I32 i;
        char idx_buf[16];
        for (i = 0; i <= len; i++) {
            SV **elem = av_fetch(params_av, i, 0);
            if (elem && *elem) {
                int idx_len;
                /* Dump into scratch SV via Loo */
                medusa_dump_param_into(aTHX_ *elem, &cache->dump_style, cache->scratch_dump);
                /* Build " prefix0=†value†" without sv_catpvf */
                sv_catpvn(result, " ", 1);
                sv_catpv(result, prefix);
                idx_len = snprintf(idx_buf, sizeof(idx_buf), "%d=", (int)i);
                sv_catpvn(result, idx_buf, idx_len);
                sv_catpv(result, cache->quote);
                sv_catsv(result, cache->scratch_dump);
                sv_catpv(result, cache->quote);
            }
        }
    }
    
    /* Dispatch to logger */
    if (cache->use_direct_write && cache->direct_logger) {
        /* FASTEST: direct C write — no Perl call overhead at all */
        medusa_logger_write(aTHX_ cache->direct_logger,
                            SvPVX(result), SvCUR(result));
    } else {
        /* Perl dispatch path — push a mortal copy so logger can safely
         * store the string without aliasing our scratch SV */
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(log_obj);
        XPUSHs(sv_2mortal(newSVpvn(SvPVX(result), SvCUR(result))));
        PUTBACK;
        if (cache->log_method_cv) {
            call_sv((SV *)cache->log_method_cv, G_DISCARD);
        } else {
            call_method(cache->log_method, G_DISCARD);
        }
        FREETMPS;
        LEAVE;
    }
}

/*
 * XS implementation of log_message
 * Can call Perl FORMAT_MESSAGE callback or use XS default
 */
static void
medusa_xs_log_message(pTHX_ HV *params) {
    dSP;
    HV *log_config;
    SV **svp;
    SV *log_obj;
    SV *format_message_cb;
    SV *formatted_msg;
    const char *log_level = "debug";
    const char *log_method;
    
    /* Get %Medusa::XS::LOG */
    log_config = get_hv("Medusa::XS::LOG", 0);
    if (!log_config) {
        return;
    }
    
    /* Initialize logger if needed */
    svp = hv_fetchs(log_config, "LOG", 0);
    if (!svp || !SvROK(*svp)) {
        /* Call LOG_INIT */
        SV **init_cb = hv_fetchs(log_config, "LOG_INIT", 0);
        if (init_cb && SvROK(*init_cb)) {
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(*init_cb, G_SCALAR);
            SPAGAIN;
            log_obj = POPs;
            if (SvROK(log_obj)) {
                hv_stores(log_config, "LOG", SvREFCNT_inc(log_obj));
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        svp = hv_fetchs(log_config, "LOG", 0);
    }
    
    if (!svp || !SvROK(*svp)) {
        return; /* Still no logger */
    }
    log_obj = *svp;
    
    /* Get log level */
    svp = hv_fetchs(params, "level", 0);
    if (svp && SvPOK(*svp)) {
        log_level = SvPV_nolen(*svp);
    } else {
        svp = hv_fetchs(log_config, "LOG_LEVEL", 0);
        if (svp && SvPOK(*svp)) {
            log_level = SvPV_nolen(*svp);
        }
    }
    
    /* Store level in params for FORMAT_MESSAGE */
    hv_stores(params, "level", newSVpv(log_level, 0));
    
    /* Get log method name from LOG_FUNCTIONS */
    log_method = log_level;
    svp = hv_fetchs(log_config, "LOG_FUNCTIONS", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
        HV *funcs = (HV *)SvRV(*svp);
        SV **meth = hv_fetch(funcs, log_level, strlen(log_level), 0);
        if (meth && SvPOK(*meth)) {
            log_method = SvPV_nolen(*meth);
        }
    }
    
    /* Get FORMAT_MESSAGE callback or use XS default */
    svp = hv_fetchs(log_config, "FORMAT_MESSAGE", 0);
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        /* Call Perl FORMAT_MESSAGE callback */
        I32 count;
        HE *he;
        
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        
        /* Push params hash as list */
        hv_iterinit(params);
        while ((he = hv_iternext(params))) {
            XPUSHs(hv_iterkeysv(he));
            XPUSHs(hv_iterval(params, he));
        }
        PUTBACK;
        
        count = call_sv(*svp, G_SCALAR);
        SPAGAIN;
        
        if (count >= 1) {
            formatted_msg = SvREFCNT_inc(POPs);
        } else {
            formatted_msg = newSVpvn("", 0);
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    } else {
        /* Use XS FORMAT_MESSAGE implementation */
        formatted_msg = medusa_xs_format_message(aTHX_ params, log_config);
    }
    
    /* Call $LOG{LOG}->$log_method($formatted_msg) */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(log_obj);  /* Push the blessed reference, not SvRV */
    XPUSHs(sv_2mortal(formatted_msg));
    PUTBACK;
    call_method(log_method, G_DISCARD);
    FREETMPS;
    LEAVE;
}

/* XSUB wrapper that performs actual audit logging - full Medusa-compatible
 * Uses AUDIT_CACHE for fast config access (no hash lookups per call) */
XS(XS_Medusa__XS_audit_wrapper) {
    dXSARGS;
    AUDIT_CACHE *cache;
    CV *orig_cv;
    I32 count;
    const char *method_name;
    char guid[MEDUSA_GUID_LEN + 1];
    struct timeval start_time, end_time;
    double elapsed;
    HV *log_config;
    I32 gimme;
    AV *args_copy;
    bool opt_guid, opt_caller, opt_elapsed;
    SV *guid_sv = NULL;
    SV *caller_sv = NULL;
    I32 i;
    bool use_fast_path;
    
    /* Get cached metadata - this is the key optimization */
    cache = get_audit_cache(aTHX_ cv);
    use_fast_path = (cache && cache->use_xs_format);
    
    if (cache) {
        /* Fast path: use cached values */
        orig_cv = cache->original_cv;
        method_name = cache->method;
        log_config = cache->log_config;
        opt_guid = cache->opt_guid;
        opt_caller = cache->opt_caller;
        opt_elapsed = cache->opt_elapsed;
    } else {
        /* Fallback: get from CV (shouldn't happen) */
        GV *gv;
        HV *stash;
        SV **svp;
        
        orig_cv = (CV *)CvXSUBANY(cv).any_ptr;
        if (!orig_cv) {
            croak("Medusa::XS: wrapper CV has no original CV reference");
        }
        
        method_name = "unknown";
        gv = CvGV(orig_cv);
        if (gv) {
            method_name = GvNAME(gv);
        }
        
        log_config = get_hv("Medusa::XS::LOG", 0);
        opt_guid = opt_caller = opt_elapsed = TRUE;
        
        if (log_config) {
            svp = hv_fetchs(log_config, "OPTIONS", 0);
            if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
                HV *options = (HV *)SvRV(*svp);
                SV **opt;
                
                opt = hv_fetchs(options, "guid", 0);
                if (opt) opt_guid = SvTRUE(*opt);
                
                opt = hv_fetchs(options, "caller", 0);
                if (opt) opt_caller = SvTRUE(*opt);
                
                opt = hv_fetchs(options, "elapsed_call", 0);
                if (opt) opt_elapsed = SvTRUE(*opt);
            }
        }
    }
    
    if (!log_config) {
        /* No config, just forward without logging */
        PUSHMARK(SP - items);
        count = call_sv((SV *)orig_cv, GIMME_V);
        SPAGAIN;
        XSRETURN(count);
    }
    
    /* Generate GUID via Horus (version from cache or default v4) */
    if (opt_guid) {
        int gv = cache ? cache->guid_version : 4;
        const char *gns = cache ? cache->guid_namespace : NULL;
        STRLEN gns_len  = cache ? cache->guid_namespace_len : 0;
        const char *gnm = cache ? cache->guid_name : NULL;
        STRLEN gnm_len  = cache ? cache->guid_name_len : 0;
        medusa_generate_guid(aTHX_ guid, gv, gns, gns_len, gnm, gnm_len);
        if (use_fast_path) {
            /* Reuse scratch SV — no allocation */
            guid_sv = cache->scratch_guid;
            sv_setpvn(guid_sv, guid, MEDUSA_GUID_LEN);
        } else {
            guid_sv = newSVpvn(guid, MEDUSA_GUID_LEN);
        }
    }
    
    /* Collect caller stack */
    if (opt_caller) {
        if (use_fast_path) {
            /* Reuse scratch SV — no allocation */
            caller_sv = cache->scratch_caller;
            medusa_collect_caller_stack_into(aTHX_ caller_sv);
        } else {
            caller_sv = medusa_collect_caller_stack(aTHX);
        }
    }
    
    /* Copy arguments for logging (before they might be modified) */
    args_copy = newAV();
    for (i = 0; i < items; i++) {
        av_push(args_copy, SvREFCNT_inc(ST(i)));
    }
    
    /* Capture start time */
    gettimeofday(&start_time, NULL);
    
    /* Log entry */
    if (use_fast_path) {
        /* FAST PATH: no HV allocation, no hash lookups, direct format+log */
        medusa_xs_log_cached(aTHX_ cache, guid_sv, caller_sv,
                             cache->entry_msg, args_copy, "arg", NULL);
    } else {
        /* Slow path: build params hash for medusa_xs_log_message */
        HV *params = newHV();
        
        if (caller_sv && SvCUR(caller_sv) > 0) {
            hv_stores(params, "caller", SvREFCNT_inc(caller_sv));
        }
        if (guid_sv) {
            hv_stores(params, "guid", SvREFCNT_inc(guid_sv));
        }
        if (cache && cache->entry_msg) {
            hv_stores(params, "message", SvREFCNT_inc(cache->entry_msg));
        } else {
            char msg_buf[256];
            snprintf(msg_buf, sizeof(msg_buf), "subroutine %s called with args:", method_name);
            hv_stores(params, "message", newSVpv(msg_buf, 0));
        }
        hv_stores(params, "params", newRV_noinc((SV *)args_copy));
        args_copy = NULL; /* ownership transferred */
        hv_stores(params, "prefix", newSVpvs("arg"));
        
        medusa_xs_log_message(aTHX_ params);
        SvREFCNT_dec((SV *)params);
    }
    
    /* Call the original function - always in LIST context to capture all values */
    gimme = GIMME_V;
    PUSHMARK(SP - items);
    count = call_sv((SV *)orig_cv, G_ARRAY | G_EVAL);
    SPAGAIN;
    
    /* Capture end time */
    gettimeofday(&end_time, NULL);
    elapsed = (end_time.tv_sec - start_time.tv_sec) + 
              (end_time.tv_usec - start_time.tv_usec) / 1000000.0;
    
    /* Copy return values for logging */
    {
        AV *return_copy = newAV();
        char elapsed_buf[32];
        
        for (i = 0; i < count; i++) {
            av_push(return_copy, SvREFCNT_inc(SP[-count+1+i]));
        }
        
        if (opt_elapsed) {
            snprintf(elapsed_buf, sizeof(elapsed_buf), "%.6f", elapsed);
        }
        
        if (use_fast_path) {
            /* FAST PATH: direct format+log */
            medusa_xs_log_cached(aTHX_ cache, guid_sv, caller_sv,
                                 cache->exit_msg, return_copy, "return",
                                 opt_elapsed ? elapsed_buf : NULL);
        } else {
            /* Slow path */
            HV *params = newHV();
            
            if (caller_sv && SvCUR(caller_sv) > 0) {
                hv_stores(params, "caller", SvREFCNT_inc(caller_sv));
            }
            if (guid_sv) {
                hv_stores(params, "guid", SvREFCNT_inc(guid_sv));
            }
            if (cache && cache->exit_msg) {
                hv_stores(params, "message", SvREFCNT_inc(cache->exit_msg));
            } else {
                char msg_buf[256];
                snprintf(msg_buf, sizeof(msg_buf), "subroutine %s returned:", method_name);
                hv_stores(params, "message", newSVpv(msg_buf, 0));
            }
            hv_stores(params, "params", newRV_noinc((SV *)return_copy));
            return_copy = NULL; /* ownership transferred */
            hv_stores(params, "prefix", newSVpvs("return"));
            
            if (opt_elapsed) {
                hv_stores(params, "elapsed_call", newSVpv(elapsed_buf, 0));
            }
            
            medusa_xs_log_message(aTHX_ params);
            SvREFCNT_dec((SV *)params);
        }
        
        /* Free return_copy if not transferred */
        if (return_copy) SvREFCNT_dec((SV *)return_copy);
    }
    
    /* Clean up — only free non-scratch SVs (slow path allocated them) */
    if (!use_fast_path) {
        if (guid_sv) SvREFCNT_dec(guid_sv);
        if (caller_sv) SvREFCNT_dec(caller_sv);
    }
    
    /* Check for exceptions */
    if (SvTRUE(ERRSV)) {
        croak_sv(ERRSV);
    }
    
    /* Handle context: in scalar context, return only first element (like Perl shift) */
    if (gimme == G_SCALAR && count > 1) {
        /* Return only the first value - shift other items off */
        SV *first = SP[-count+1];  /* First return value */
        SP -= count;  /* Remove all items */
        SP++;
        if (first) {
            *SP = first;
        }
        XSRETURN(1);
    }
    
    XSRETURN(count);
}

/* ------------------------------------------------------------------ */
/* Utility: Generate UUID via Horus (RFC 9562, all versions)           */
/* ------------------------------------------------------------------ */

/* Persistent state for time-based UUID versions */
static horus_v1_state_t medusa_v1_state = {{{0}}, 0, 0, 0};
static horus_v6_state_t medusa_v6_state = {{{0}}, 0};
static horus_v7_state_t medusa_v7_state = {0, {{0}}};

/* Resolve a namespace string to a 16-byte UUID.
 * Accepts well-known names (dns, url, oid, x500) or a UUID string. */
static void
medusa_resolve_namespace(const char *ns_str, STRLEN ns_len,
                         unsigned char *ns_uuid)
{
    if (ns_len == 3 && strncmp(ns_str, "dns", 3) == 0)
        memcpy(ns_uuid, HORUS_NS_DNS, 16);
    else if (ns_len == 3 && strncmp(ns_str, "url", 3) == 0)
        memcpy(ns_uuid, HORUS_NS_URL, 16);
    else if (ns_len == 3 && strncmp(ns_str, "oid", 3) == 0)
        memcpy(ns_uuid, HORUS_NS_OID, 16);
    else if (ns_len == 4 && strncmp(ns_str, "x500", 4) == 0)
        memcpy(ns_uuid, HORUS_NS_X500, 16);
    else {
        /* Try parsing as UUID string */
        if (!horus_parse_uuid(ns_uuid, ns_str, ns_len))
            memcpy(ns_uuid, HORUS_NS_DNS, 16);  /* fallback */
    }
}

static void
medusa_generate_guid(pTHX_ char *buf, int version,
                     const char *ns_str, STRLEN ns_len,
                     const char *name_str, STRLEN name_len)
{
    unsigned char uuid[16];

    switch (version) {
        case 1:
            if (!medusa_v1_state.initialized)
                horus_v1_init_state(&medusa_v1_state);
            horus_uuid_v1(uuid, &medusa_v1_state);
            break;
        case 3: {
            unsigned char ns_uuid[16];
            if (ns_str && ns_len > 0)
                medusa_resolve_namespace(ns_str, ns_len, ns_uuid);
            else
                memcpy(ns_uuid, HORUS_NS_DNS, 16);
            horus_uuid_v3(uuid, ns_uuid,
                          (const unsigned char *)name_str,
                          name_len);
            break;
        }
        case 4:
            horus_uuid_v4(uuid);
            break;
        case 5: {
            unsigned char ns_uuid[16];
            if (ns_str && ns_len > 0)
                medusa_resolve_namespace(ns_str, ns_len, ns_uuid);
            else
                memcpy(ns_uuid, HORUS_NS_DNS, 16);
            horus_uuid_v5(uuid, ns_uuid,
                          (const unsigned char *)name_str,
                          name_len);
            break;
        }
        case 6:
            if (!medusa_v1_state.initialized)
                horus_v1_init_state(&medusa_v1_state);
            horus_uuid_v6(uuid, &medusa_v1_state, &medusa_v6_state);
            break;
        case 7:
            horus_uuid_v7(uuid, &medusa_v7_state);
            break;
        case 8: {
            unsigned char custom[16];
            horus_random_bytes(custom, 16);
            horus_uuid_v8(uuid, custom);
            break;
        }
        case 0:  /* NIL */
            horus_uuid_nil(uuid);
            break;
        case -1: /* MAX */
            horus_uuid_max(uuid);
            break;
        default:
            horus_uuid_v4(uuid);
            break;
    }

    horus_format_uuid(buf, uuid, HORUS_FMT_STR);
    buf[HORUS_FMT_STR_LEN] = '\0';
}

/* ------------------------------------------------------------------ */
/* Utility: Format timestamp with optional milliseconds                */
/* ------------------------------------------------------------------ */

static SV *
medusa_format_time(pTHX_ bool use_gmtime, const char *fmt) {
    struct timeval tv;
    struct tm *tm_info;
    char buf[MEDUSA_TIME_BUF_SIZE];
    char ms_buf[16];
    STRLEN len;
    
    gettimeofday(&tv, NULL);
    
    if (use_gmtime) {
        tm_info = gmtime(&tv.tv_sec);
    } else {
        tm_info = localtime(&tv.tv_sec);
    }
    
    if (fmt == NULL || strcmp(fmt, "default") == 0) {
        /* Default format: asctime style */
        strftime(buf, sizeof(buf), "%a %b %e %H:%M:%S %Y", tm_info);
    } else {
        /* Custom format with %ms placeholder for milliseconds */
        char *ms_pos;
        char fmt_copy[128];
        
        strncpy(fmt_copy, fmt, sizeof(fmt_copy) - 1);
        fmt_copy[sizeof(fmt_copy) - 1] = '\0';
        
        ms_pos = strstr(fmt_copy, "%ms");
        if (ms_pos) {
            /* Replace %ms with actual milliseconds */
            snprintf(ms_buf, sizeof(ms_buf), "%03ld", tv.tv_usec / 1000);
            *ms_pos = '\0';
            strftime(buf, sizeof(buf), fmt_copy, tm_info);
            len = strlen(buf);
            snprintf(buf + len, sizeof(buf) - len, "%s%s", ms_buf, ms_pos + 3);
        } else {
            strftime(buf, sizeof(buf), fmt_copy, tm_info);
        }
    }
    
    return newSVpv(buf, 0);
}

/* ------------------------------------------------------------------ */
/* Utility: Collect caller stack (replaces Perl caller() loop)        */
/* ------------------------------------------------------------------ */

static SV *
medusa_collect_caller_stack(pTHX) {
    SV *result;
    const PERL_CONTEXT *cx;
    I32 cxix;
    char buf[MEDUSA_CALLER_STACK_INITIAL_SIZE];
    STRLEN pos = 0;
    bool first = TRUE;
    
    result = newSVpvn("", 0);
    SvGROW(result, MEDUSA_CALLER_STACK_INITIAL_SIZE);
    
    /* Walk the context stack */
    for (cxix = cxstack_ix; cxix >= 0; cxix--) {
        cx = &cxstack[cxix];
        
        /* Only process subroutine contexts */
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_EVAL) {
            const char *pkg;
            I32 line;
            
            /* Get package name and line number */
            if (cx->blk_oldcop) {
                pkg = CopSTASHPV(cx->blk_oldcop);
                line = CopLINE(cx->blk_oldcop);
            } else {
                continue;
            }
            
            if (!first) {
                sv_catpvn(result, "->", 2);
            }
            first = FALSE;
            
            sv_catpvf(result, "%s:%d", pkg ? pkg : "(unknown)", (int)line);
        }
    }
    
    return result;
}

/* Collect caller stack into a pre-allocated SV (avoids per-call newSV) */
static void
medusa_collect_caller_stack_into(pTHX_ SV *result) {
    const PERL_CONTEXT *cx;
    I32 cxix;
    bool first = TRUE;
    
    SvCUR_set(result, 0);
    *SvPVX(result) = '\0';
    
    for (cxix = cxstack_ix; cxix >= 0; cxix--) {
        cx = &cxstack[cxix];
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_EVAL) {
            const char *pkg;
            I32 line;
            if (cx->blk_oldcop) {
                pkg = CopSTASHPV(cx->blk_oldcop);
                line = CopLINE(cx->blk_oldcop);
            } else {
                continue;
            }
            if (!first) sv_catpvn(result, "->", 2);
            first = FALSE;
            sv_catpvf(result, "%s:%d", pkg ? pkg : "(unknown)", (int)line);
        }
    }
}

/* ------------------------------------------------------------------ */
/* Utility: Get option from %LOG hash                                  */
/* ------------------------------------------------------------------ */

static bool
get_log_option(pTHX_ HV *log_config, const char *key) {
    SV **svp;
    HV *options;
    
    if (!log_config) return TRUE;  /* Default to enabled */
    
    svp = hv_fetchs(log_config, "OPTIONS", 0);
    if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV) {
        return TRUE;
    }
    
    options = (HV *)SvRV(*svp);
    svp = hv_fetch(options, key, strlen(key), 0);
    if (!svp) return TRUE;
    
    return SvTRUE(*svp);
}

static SV *
get_log_value(pTHX_ HV *log_config, const char *key) {
    SV **svp;
    
    if (!log_config) return NULL;
    
    svp = hv_fetch(log_config, key, strlen(key), 0);
    return svp ? *svp : NULL;
}

/* ------------------------------------------------------------------ */
/* Utility: Format log message (Phase 3 implementation)                */
/* ------------------------------------------------------------------ */

/*
 * Build a formatted log message string:
 * [timestamp] [guid] LEVEL message key=†value† ...
 */
static SV *
medusa_build_log_message(pTHX_ HV *log_config, const char *level,
                          SV *guid, SV *caller_stack, SV *method_name,
                          const char *msg_type, AV *params, 
                          const char *prefix, double elapsed) {
    SV *result;
    SV *timestamp = NULL;
    SV *quote_sv;
    const char *quote = "†";
    bool opt_date, opt_guid, opt_level, opt_caller, opt_elapsed;
    char buf[MEDUSA_LOG_BUF_SIZE];
    STRLEN pos = 0;
    
    /* Get options */
    opt_date = get_log_option(aTHX_ log_config, "date");
    opt_guid = get_log_option(aTHX_ log_config, "guid");
    opt_level = get_log_option(aTHX_ log_config, "level");
    opt_caller = get_log_option(aTHX_ log_config, "caller");
    opt_elapsed = get_log_option(aTHX_ log_config, "elapsed_call");
    
    /* Get quote character */
    quote_sv = get_log_value(aTHX_ log_config, "QUOTE");
    if (quote_sv && SvPOK(quote_sv)) {
        quote = SvPV_nolen(quote_sv);
    }
    
    result = newSVpvn("", 0);
    SvGROW(result, MEDUSA_LOG_BUF_SIZE);
    
    /* Add timestamp */
    if (opt_date) {
        SV *time_type = get_log_value(aTHX_ log_config, "TIME");
        bool use_gmtime = TRUE;
        if (time_type && SvPOK(time_type)) {
            const char *tt = SvPV_nolen(time_type);
            use_gmtime = (strcmp(tt, "gmtime") == 0);
        }
        
        SV *time_fmt = get_log_value(aTHX_ log_config, "TIME_FORMAT");
        const char *fmt = NULL;
        if (time_fmt && SvPOK(time_fmt)) {
            fmt = SvPV_nolen(time_fmt);
            if (strcmp(fmt, "default") == 0) fmt = NULL;
        }
        
        timestamp = medusa_format_time(aTHX_ use_gmtime, fmt);
        sv_catpvf(result, "%s ", SvPV_nolen(timestamp));
        SvREFCNT_dec(timestamp);
    }
    
    /* Add GUID */
    if (opt_guid && guid && SvOK(guid)) {
        sv_catpvf(result, "%s ", SvPV_nolen(guid));
    }
    
    /* Add log level */
    if (opt_level && level) {
        /* Uppercase the level */
        char level_upper[32];
        int i;
        for (i = 0; level[i] && i < 31; i++) {
            level_upper[i] = toupper(level[i]);
        }
        level_upper[i] = '\0';
        sv_catpv(result, level_upper);
    }
    
    /* Add caller stack */
    if (opt_caller && caller_stack && SvOK(caller_stack) && SvCUR(caller_stack) > 0) {
        sv_catpvf(result, " caller=%s%s%s", quote, SvPV_nolen(caller_stack), quote);
    }
    
    /* Add message */
    if (method_name && SvOK(method_name)) {
        sv_catpvf(result, " message=%ssubroutine %s %s:%s", 
                  quote, SvPV_nolen(method_name), msg_type, quote);
    }
    
    /* Add elapsed time (only for leave) */
    if (opt_elapsed && elapsed > 0) {
        sv_catpvf(result, " elapsed_call=%s%.6f%s", quote, elapsed, quote);
    }
    
    /* Add parameters */
    if (params && prefix) {
        I32 len = av_len(params);
        I32 i;
        
        {
            DDCStyle style;
            medusa_loo_style_init(aTHX_ &style, 0, NULL);
            for (i = 0; i <= len; i++) {
                SV **elem = av_fetch(params, i, 0);
                if (elem && *elem) {
                    SV *dumped = medusa_dump_param(aTHX_ *elem, &style);
                    sv_catpvf(result, " %s%d=%s%s%s",
                              prefix, (int)i, quote, SvPV_nolen(dumped), quote);
                    SvREFCNT_dec(dumped);
                }
            }
            ddc_style_destroy(aTHX_ &style);
        }
    }
    
    return result;
}

/* ------------------------------------------------------------------ */
/* Custom op pp functions                                              */
/* ------------------------------------------------------------------ */

static OP *
pp_medusa_caller_stack(pTHX) {
    dSP;
    SV *stack = medusa_collect_caller_stack(aTHX);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(stack));
    PUTBACK;
    return NORMAL;
}

/*
 * pp_medusa_format_log - Format a log message
 *
 * Stack: method_name, msg_type, guid, caller_stack, params_av
 * Returns: formatted log message SV
 */
static OP *
pp_medusa_format_log(pTHX) {
    dSP;
    SV *params_sv, *caller_sv, *guid_sv, *msg_type_sv, *method_sv;
    AV *params_av = NULL;
    SV *result;
    HV *log_config = NULL;
    GV *gv;
    
    /* Pop args from stack */
    params_sv = POPs;
    caller_sv = POPs;
    guid_sv = POPs;
    msg_type_sv = POPs;
    method_sv = POPs;
    
    /* Get params array */
    if (SvROK(params_sv) && SvTYPE(SvRV(params_sv)) == SVt_PVAV) {
        params_av = (AV *)SvRV(params_sv);
    }
    
    /* Get log config */
    gv = gv_fetchpvn_flags("Medusa::XS::LOG", 15, 0, SVt_PVHV);
    if (gv) log_config = GvHV(gv);
    
    /* Build message */
    result = medusa_build_log_message(aTHX_ log_config, "debug",
                                       guid_sv, caller_sv, method_sv,
                                       SvPV_nolen(msg_type_sv), 
                                       params_av, "arg", 0);
    
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(result));
    PUTBACK;
    return NORMAL;
}

/*
 * pp_medusa_log_write - Custom op for direct file logging
 *
 * Stack: logger_sv (blessed Medusa::XS::Logger), message_sv
 * Performs flock + write + flush in pure C, zero Perl dispatch.
 */
static OP *
pp_medusa_log_write(pTHX) {
    dSP;
    SV *message_sv;
    SV *logger_sv;
    MedusaLogger *logger;
    const char *line;
    STRLEN len;
    
    message_sv = POPs;
    logger_sv = POPs;
    
    logger = medusa_logger_from_sv(aTHX_ logger_sv);
    if (logger) {
        line = SvPV(message_sv, len);
        medusa_logger_write(aTHX_ logger, line, len);
    }
    
    PUTBACK;
    return NORMAL;
}

/* ------------------------------------------------------------------ */
/* XS Module                                                           */
/* ------------------------------------------------------------------ */

MODULE = Medusa::XS  PACKAGE = Medusa::XS

BOOT:
#if PERL_VERSION >= 14
    /* Register custom ops */
    XopENTRY_set(&medusa_xop_caller_stack, xop_name, "medusa_caller_stack");
    XopENTRY_set(&medusa_xop_caller_stack, xop_desc, "Medusa caller stack collection");
    XopENTRY_set(&medusa_xop_caller_stack, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_medusa_caller_stack, &medusa_xop_caller_stack);
    
    XopENTRY_set(&medusa_xop_format_log, xop_name, "medusa_format_log");
    XopENTRY_set(&medusa_xop_format_log, xop_desc, "Medusa log message formatting");
    XopENTRY_set(&medusa_xop_format_log, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_medusa_format_log, &medusa_xop_format_log);
    
    XopENTRY_set(&medusa_xop_log_write, xop_name, "medusa_log_write");
    XopENTRY_set(&medusa_xop_log_write, xop_desc, "Medusa direct file log write");
    XopENTRY_set(&medusa_xop_log_write, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_medusa_log_write, &medusa_xop_log_write);
#endif

# ------------------------------------------------------------------ #
# XSUB: Generate UUID (all RFC 9562 versions via Horus)                #
# ------------------------------------------------------------------ #

SV *
generate_guid(...)
    PREINIT:
        char buf[HORUS_FMT_STR_LEN + 1];
        int version = 4;
        const char *ns_str = NULL;
        STRLEN ns_len = 0;
        const char *name_str = NULL;
        STRLEN name_len = 0;
    CODE:
        if (items >= 1) version = SvIV(ST(0));
        if (items >= 2 && SvOK(ST(1))) ns_str = SvPV(ST(1), ns_len);
        if (items >= 3 && SvOK(ST(2))) name_str = SvPV(ST(2), name_len);
        medusa_generate_guid(aTHX_ buf, version,
                             ns_str, ns_len, name_str, name_len);
        RETVAL = newSVpvn(buf, HORUS_FMT_STR_LEN);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: Format timestamp                                              #
# ------------------------------------------------------------------ #

SV *
format_time(use_gmtime = TRUE, fmt = NULL)
        bool use_gmtime
        const char *fmt
    CODE:
        RETVAL = medusa_format_time(aTHX_ use_gmtime, fmt);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: Collect caller stack                                          #
# ------------------------------------------------------------------ #

SV *
collect_caller_stack()
    CODE:
        RETVAL = medusa_collect_caller_stack(aTHX);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: Clean dumper output (legacy compat - passes through to Loo)    #
# ------------------------------------------------------------------ #

SV *
clean_dumper(input)
        SV *input
    CODE:
        /* Legacy: with Loo, dump output is already clean.
         * This just returns the input for backward compatibility. */
        RETVAL = newSVsv(input);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: SV serializer via Loo                                         #
# ------------------------------------------------------------------ #

SV *
dump_sv(value)
        SV *value
    PREINIT:
        DDCStyle style;
        HV *log_config;
        HV *options = NULL;
        int use_colour = 0;
        const char *theme = NULL;
    CODE:
        /* Read colour settings from %LOG{OPTIONS} */
        log_config = get_hv("Medusa::XS::LOG", 0);
        if (log_config) {
            SV **svp = hv_fetchs(log_config, "OPTIONS", 0);
            if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
                options = (HV *)SvRV(*svp);
                use_colour = medusa_resolve_colour(aTHX_ options);
                theme = medusa_resolve_theme(aTHX_ options);
            }
        }
        medusa_loo_style_init(aTHX_ &style, use_colour, theme);
        RETVAL = medusa_dump_param(aTHX_ value, &style);
        ddc_style_destroy(aTHX_ &style);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: Wrap a subroutine with auditing                                #
# ------------------------------------------------------------------ #

void
wrap_sub(coderef, method_name = NULL)
        SV *coderef
        SV *method_name
    PREINIT:
        CV *cv;
        CV *wrapper;
        const char *method;
        STRLEN method_len;
        const char *pkg;
        STRLEN pkg_len;
        GV *gv;
    PPCODE:
        /* Get the CV from the coderef */
        if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
            croak("wrap_sub: argument must be a code reference");
        }
        cv = (CV *)SvRV(coderef);
        
        /* Get method name from CV or argument */
        if (method_name && SvOK(method_name)) {
            method = SvPV(method_name, method_len);
        } else {
            gv = CvGV(cv);
            if (gv) {
                method = GvNAME(gv);
                method_len = GvNAMELEN(gv);
            } else {
                method = "__ANON__";
                method_len = 8;
            }
        }
        
        /* Get package name from CV */
        gv = CvGV(cv);
        if (gv && GvSTASH(gv)) {
            pkg = HvNAME(GvSTASH(gv));
            pkg_len = pkg ? strlen(pkg) : 0;
        } else {
            pkg = "main";
            pkg_len = 4;
        }
        
        /* Inject the audit wrapper */
        inject_audit_wrapper(aTHX_ cv, method, method_len, pkg, pkg_len);
        
        /* Return the wrapped CV */
        XPUSHs(coderef);
        XSRETURN(1);

bool
is_audited(coderef)
        SV *coderef
    PREINIT:
        CV *cv;
    CODE:
        if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
            RETVAL = FALSE;
        } else {
            cv = (CV *)SvRV(coderef);
            RETVAL = CV_IS_AUDITED(cv) ? TRUE : FALSE;
        }
    OUTPUT:
        RETVAL

SV *
_make_test_audit_op(method, package)
        const char *method
        const char *package
    CODE:
        /* Legacy test hook — AUDITOP struct removed, return confirmation */
        RETVAL = newSVpvf("AUDIT_CACHE@%s::%s", package, method);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: _apply_deferred_wraps - Re-install wrappers queued on 5.10    #
# ------------------------------------------------------------------ #

void
_apply_deferred_wraps()
    PPCODE:
        medusa_check_apply_wraps(aTHX_ NULL);
        XSRETURN(0);

# ------------------------------------------------------------------ #
# XSUB: log_message - Full XS logging implementation                  #
# ------------------------------------------------------------------ #

void
log_message(...)
    PREINIT:
        HV *params;
        int i;
    PPCODE:
        /* Build params hash from @_ */
        if (items % 2 != 0) {
            croak("log_message: odd number of arguments");
        }
        params = newHV();
        for (i = 0; i < items; i += 2) {
            SV *key = ST(i);
            SV *val = ST(i+1);
            STRLEN len;
            const char *k = SvPV(key, len);
            hv_store(params, k, len, SvREFCNT_inc(val), 0);
        }
        medusa_xs_log_message(aTHX_ params);
        SvREFCNT_dec((SV *)params);
        XSRETURN(0);

# ------------------------------------------------------------------ #
# XSUB: xs_format_message - XS default FORMAT_MESSAGE                 #
# ------------------------------------------------------------------ #

SV *
xs_format_message(...)
    PREINIT:
        HV *params;
        HV *log_config;
        int i;
    CODE:
        /* Build params hash from @_ */
        if (items % 2 != 0) {
            croak("xs_format_message: odd number of arguments");
        }
        params = newHV();
        for (i = 0; i < items; i += 2) {
            SV *key = ST(i);
            SV *val = ST(i+1);
            STRLEN len;
            const char *k = SvPV(key, len);
            hv_store(params, k, len, SvREFCNT_inc(val), 0);
        }
        log_config = get_hv("Medusa::XS::LOG", 0);
        if (!log_config) {
            log_config = newHV();
        }
        RETVAL = medusa_xs_format_message(aTHX_ params, log_config);
        SvREFCNT_dec((SV *)params);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------ #
# XSUB: init_logger - Initialize the logger from LOG_INIT             #
# ------------------------------------------------------------------ #

void
init_logger()
    PREINIT:
        HV *log_config;
        SV **svp;
    PPCODE:
        log_config = get_hv("Medusa::XS::LOG", 0);
        if (!log_config) {
            XSRETURN(0);
        }
        
        /* Check if LOG already initialized */
        svp = hv_fetchs(log_config, "LOG", 0);
        if (svp && SvROK(*svp)) {
            XSRETURN(0);
        }
        
        /* Call LOG_INIT */
        svp = hv_fetchs(log_config, "LOG_INIT", 0);
        if (svp && SvROK(*svp)) {
            dSP;
            SV *log_obj;
            int count;
            
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = call_sv(*svp, G_SCALAR);
            SPAGAIN;
            
            if (count >= 1) {
                log_obj = POPs;
                if (SvROK(log_obj)) {
                    hv_stores(log_config, "LOG", SvREFCNT_inc(log_obj));
                }
            }
            
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        XSRETURN(0);

# ------------------------------------------------------------------ #
# XSUB: import - Set up calling package to use Medusa::XS             #
# ------------------------------------------------------------------ #

void
import(...)
    PREINIT:
        HV *log_config;
        const char *caller_pkg;
        HV *caller_stash;
        AV *isa;
        GV *isa_gv;
        int i;
    PPCODE:
        /* Check for odd number of args (after class name) */
        if ((items - 1) % 2 != 0) {
            croak("odd number of params passed in import");
        }
        
        /* Get caller package */
        caller_pkg = CopSTASHPV(PL_curcop);
        if (!caller_pkg) caller_pkg = "main";
        
        /* Push Medusa::XS onto caller's @ISA */
        caller_stash = gv_stashpv(caller_pkg, GV_ADD);
        isa_gv = gv_fetchpvn_flags("ISA", 3, GV_ADD, SVt_PVAV);
        if (caller_stash) {
            GV *pkg_isa = gv_fetchmethod_autoload(caller_stash, "ISA", FALSE);
            SV *isa_name = newSVpvf("%s::ISA", caller_pkg);
            AV *isa_av = get_av(SvPV_nolen(isa_name), GV_ADD);
            SvREFCNT_dec(isa_name);
            av_push(isa_av, newSVpvs("Medusa::XS"));
        }
        
        /* Process key=value pairs into %LOG (make copies of values) */
        log_config = get_hv("Medusa::XS::LOG", GV_ADD);
        for (i = 1; i < items; i += 2) {
            SV *key = ST(i);
            SV *val = ST(i + 1);
            STRLEN klen;
            const char *kstr = SvPV(key, klen);
            /* Use newSVsv to copy - stack values may be read-only */
            hv_store(log_config, kstr, klen, newSVsv(val), 0);
        }
        
        XSRETURN(0);

# ------------------------------------------------------------------ #
# XSUB: MODIFY_CODE_ATTRIBUTES - Handle :Audit attribute              #
# ------------------------------------------------------------------ #

void
MODIFY_CODE_ATTRIBUTES(pkg, coderef, ...)
        SV *pkg
        SV *coderef
    PREINIT:
        CV *cv;
        GV *gv;
        const char *method_name = "__ANON__";
        STRLEN method_len = 8;
        const char *pkg_name;
        STRLEN pkg_len;
        HV *audited;
        int i;
        bool found_audit = FALSE;
    PPCODE:
        /* Check if any attribute is "Audit" */
        for (i = 2; i < items; i++) {
            STRLEN len;
            const char *attr = SvPV(ST(i), len);
            if (len >= 5 && strncmp(attr, "Audit", 5) == 0) {
                found_audit = TRUE;
                break;
            }
        }
        
        if (!found_audit) {
            /* Return remaining attributes (none handled) */
            for (i = 2; i < items; i++) {
                XPUSHs(ST(i));
            }
            XSRETURN(items - 2);
        }
        
        /* Get the CV */
        if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
            croak("MODIFY_CODE_ATTRIBUTES: not a code reference");
        }
        cv = (CV *)SvRV(coderef);
        
        /* Initialize logger */
        {
            dSP;
            PUSHMARK(SP);
            PUTBACK;
            call_pv("Medusa::XS::init_logger", G_DISCARD);
        }
        
        /* Get method name from CV's GV */
        gv = CvGV(cv);
        if (gv) {
            method_name = GvNAME(gv);
            method_len = GvNAMELEN(gv);
        }
        
        /* Get package name */
        pkg_name = SvPV(pkg, pkg_len);
        
        /* Track in %AUDITED */
        audited = get_hv("Medusa::XS::AUDITED", GV_ADD);
        {
            char addr_key[32];
            int addr_len = snprintf(addr_key, sizeof(addr_key), "%lu", 
                                    (unsigned long)PTR2UV(cv));
            hv_store(audited, addr_key, addr_len, newSViv(1), 0);
        }
        
        /* Wrap the sub with XS auditing */
        inject_audit_wrapper(aTHX_ cv, method_name, method_len, 
                             pkg_name, pkg_len);
        
        /* Return empty list (we handled Audit, no unhandled attrs) */
        XSRETURN(0);

# ------------------------------------------------------------------ #
# XSUB: FETCH_CODE_ATTRIBUTES - Report attributes on a coderef       #
# ------------------------------------------------------------------ #

void
FETCH_CODE_ATTRIBUTES(pkg, coderef)
        SV *pkg
        SV *coderef
    PREINIT:
        CV *cv;
        HV *audited;
        bool is_audited_cv = FALSE;
    PPCODE:
        PERL_UNUSED_VAR(pkg);
        
        if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
            XSRETURN(0);
        }
        cv = (CV *)SvRV(coderef);
        
        /* Check %AUDITED hash */
        audited = get_hv("Medusa::XS::AUDITED", 0);
        if (audited) {
            char addr_key[32];
            int addr_len = snprintf(addr_key, sizeof(addr_key), "%lu",
                                    (unsigned long)PTR2UV(cv));
            if (hv_exists(audited, addr_key, addr_len)) {
                is_audited_cv = TRUE;
            }
        }
        
        /* Check XS magic */
        if (!is_audited_cv && CV_IS_AUDITED(cv)) {
            is_audited_cv = TRUE;
        }
        
        if (is_audited_cv) {
            XPUSHs(sv_2mortal(newSVpvs("Audit")));
            XSRETURN(1);
        }
        
        XSRETURN(0);

# ================================================================== #
# Medusa::XS::Logger — Pure XS file logger with flock                 #
# ================================================================== #

MODULE = Medusa::XS  PACKAGE = Medusa::XS::Logger

SV *
new(pkg, ...)
        const char *pkg
    PREINIT:
        MedusaLogger *logger;
        SV *self_rv;
        SV *self_sv;
        const char *filename = "audit.log";
        STRLEN filename_len;
        HV *args;
        SV **svp;
        I32 i;
    CODE:
        /* Parse args: new(file => 'x') or new({file => 'x'}) */
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            args = (HV *)SvRV(ST(1));
        } else if (items > 1 && (items - 1) % 2 == 0) {
            args = newHV();
            sv_2mortal((SV *)args);
            for (i = 1; i < items; i += 2) {
                const char *key;
                STRLEN klen;
                key = SvPV(ST(i), klen);
                (void)hv_store(args, key, klen, SvREFCNT_inc(ST(i+1)), 0);
            }
        } else {
            args = newHV();
            sv_2mortal((SV *)args);
        }
        
        svp = hv_fetchs(args, "file", 0);
        if (svp && SvPOK(*svp)) {
            filename = SvPV(*svp, filename_len);
        } else {
            filename_len = 9; /* strlen("audit.log") */
        }
        
        Newxz(logger, 1, MedusaLogger);
        Newx(logger->filename, filename_len + 1, char);
        Copy(filename, logger->filename, filename_len, char);
        logger->filename[filename_len] = '\0';
        logger->filename_len = filename_len;
        
        logger->fh = PerlIO_open(filename, "a");
        if (!logger->fh) {
            Safefree(logger->filename);
            Safefree(logger);
            croak("Medusa::XS::Logger: cannot open '%s': %s", filename, strerror(errno));
        }
        
        /* Bless a ref to an SV, attach C struct via magic */
        self_sv = newSV(0);
        sv_magicext(self_sv, NULL, PERL_MAGIC_ext, &medusa_logger_vtbl,
                    (const char *)logger, 0);
        self_rv = newRV_noinc(self_sv);
        sv_bless(self_rv, gv_stashpv(pkg, GV_ADD));
        
        RETVAL = self_rv;
    OUTPUT:
        RETVAL

void
debug(self, line)
        SV *self
        SV *line
    PREINIT:
        MedusaLogger *logger;
        const char *msg;
        STRLEN len;
    CODE:
        logger = medusa_logger_from_sv(aTHX_ self);
        if (!logger) croak("Medusa::XS::Logger: invalid logger object");
        msg = SvPV(line, len);
        medusa_logger_write(aTHX_ logger, msg, len);

void
info(self, line)
        SV *self
        SV *line
    PREINIT:
        MedusaLogger *logger;
        const char *msg;
        STRLEN len;
    CODE:
        logger = medusa_logger_from_sv(aTHX_ self);
        if (!logger) croak("Medusa::XS::Logger: invalid logger object");
        msg = SvPV(line, len);
        medusa_logger_write(aTHX_ logger, msg, len);

void
error(self, line)
        SV *self
        SV *line
    PREINIT:
        MedusaLogger *logger;
        const char *msg;
        STRLEN len;
    CODE:
        logger = medusa_logger_from_sv(aTHX_ self);
        if (!logger) croak("Medusa::XS::Logger: invalid logger object");
        msg = SvPV(line, len);
        medusa_logger_write(aTHX_ logger, msg, len);

void
log(self, line)
        SV *self
        SV *line
    PREINIT:
        MedusaLogger *logger;
        const char *msg;
        STRLEN len;
    CODE:
        logger = medusa_logger_from_sv(aTHX_ self);
        if (!logger) croak("Medusa::XS::Logger: invalid logger object");
        msg = SvPV(line, len);
        medusa_logger_write(aTHX_ logger, msg, len);

void
DESTROY(self)
        SV *self
    CODE:
        /* Magic destructor handles cleanup automatically */
        PERL_UNUSED_VAR(self);
