#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "tinyexpr.h"
#include "morpher_jit.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Predefined morpher functions */
static double morpher_sine(double t) {
    double s = sin(t * M_PI / 2.0);
    return s * s;
}

static double morpher_linear(double t) {
    return t;
}

static double morpher_smoothstep(double t) {
    return t * t * (3.0 - 2.0 * t);
}

static double morpher_smootherstep(double t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

static double morpher_cubic_in(double t) {
    return t * t * t;
}

static double morpher_cubic_out(double t) {
    double u = 1.0 - t;
    return 1.0 - u * u * u;
}

static double morpher_cubic_inout(double t) {
    if (t < 0.5) {
        return 4.0 * t * t * t;
    } else {
        double u = 2.0 * t - 2.0;
        return 0.5 * u * u * u + 1.0;
    }
}

static double morpher_exp_in(double t) {
    return t == 0.0 ? 0.0 : pow(2.0, 10.0 * (t - 1.0));
}

static double morpher_exp_out(double t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}

static double morpher_tanh(double t) {
    return tanh(2.0 * t) / tanh(2.0);
}

static double morpher_welch(double t) {
    return sin(t * M_PI / 2.0);
}

static double morpher_quad_in(double t) {
    return t * t;
}

static double morpher_quad_out(double t) {
    return t * (2.0 - t);
}

static double morpher_quad_inout(double t) {
    if (t < 0.5)
        return 2.0 * t * t;
    return -1.0 + (4.0 - 2.0 * t) * t;
}

static double morpher_circ_in(double t) {
    double d = 1.0 - t * t;
    return (d <= 0.0) ? 1.0 : 1.0 - sqrt(d);
}

static double morpher_circ_out(double t) {
    double u = t - 1.0;
    double d = 1.0 - u * u;
    return (d <= 0.0) ? 0.0 : sqrt(d);
}

static double morpher_circ_inout(double t) {
    if (t < 0.5) {
        double d = 1.0 - 4.0 * t * t;
        return (d <= 0.0) ? 0.5 : (1.0 - sqrt(d)) * 0.5;
    } else {
        double u = 2.0 * t - 2.0;
        double d = 1.0 - u * u;
        return (d <= 0.0) ? 0.5 : (sqrt(d) + 1.0) * 0.5;
    }
}

#define BACK_S 1.70158

static double morpher_back_in(double t) {
    return t * t * ((BACK_S + 1.0) * t - BACK_S);
}

static double morpher_back_out(double t) {
    double u = t - 1.0;
    return u * u * ((BACK_S + 1.0) * u + BACK_S) + 1.0;
}

static double morpher_back_inout(double t) {
    double s2 = BACK_S * 1.525;
    if (t < 0.5) {
        double u = 2.0 * t;
        return (u * u * ((s2 + 1.0) * u - s2)) * 0.5;
    } else {
        double u = 2.0 * t - 2.0;
        return (u * u * ((s2 + 1.0) * u + s2) + 2.0) * 0.5;
    }
}

static double morpher_elastic_in(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    return -pow(2.0, 10.0 * t - 10.0) * sin((t * 10.0 - 10.75) * (2.0 * M_PI / 3.0));
}

static double morpher_elastic_out(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * (2.0 * M_PI / 3.0)) + 1.0;
}

static double morpher_elastic_inout(double t) {
    double c = (2.0 * M_PI) / 4.5;
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    if (t < 0.5)
        return -(pow(2.0, 20.0 * t - 10.0) * sin((20.0 * t - 11.125) * c)) * 0.5;
    return (pow(2.0, -20.0 * t + 10.0) * sin((20.0 * t - 11.125) * c)) * 0.5 + 1.0;
}

static double bounce_out_raw(double t) {
    if (t < 1.0 / 2.75)
        return 7.5625 * t * t;
    if (t < 2.0 / 2.75) {
        t -= 1.5 / 2.75;
        return 7.5625 * t * t + 0.75;
    }
    if (t < 2.5 / 2.75) {
        t -= 2.25 / 2.75;
        return 7.5625 * t * t + 0.9375;
    }
    t -= 2.625 / 2.75;
    return 7.5625 * t * t + 0.984375;
}

static double morpher_bounce_in(double t) {
    return 1.0 - bounce_out_raw(1.0 - t);
}

static double morpher_bounce_out(double t) {
    return bounce_out_raw(t);
}

static double morpher_bounce_inout(double t) {
    if (t < 0.5)
        return (1.0 - bounce_out_raw(1.0 - 2.0 * t)) * 0.5;
    return (1.0 + bounce_out_raw(2.0 * t - 1.0)) * 0.5;
}

typedef double (*morpher_fn)(double);

typedef struct {
    const char *name;
    morpher_fn fn;
} morpher_entry;

static const morpher_entry predefined_morphers[] = {
    {"back_in",       morpher_back_in},
    {"back_inout",    morpher_back_inout},
    {"back_out",      morpher_back_out},
    {"bounce_in",     morpher_bounce_in},
    {"bounce_inout",  morpher_bounce_inout},
    {"bounce_out",    morpher_bounce_out},
    {"circ_in",       morpher_circ_in},
    {"circ_inout",    morpher_circ_inout},
    {"circ_out",      morpher_circ_out},
    {"cubic_in",      morpher_cubic_in},
    {"cubic_inout",   morpher_cubic_inout},
    {"cubic_out",     morpher_cubic_out},
    {"elastic_in",    morpher_elastic_in},
    {"elastic_inout", morpher_elastic_inout},
    {"elastic_out",   morpher_elastic_out},
    {"exp_in",        morpher_exp_in},
    {"exp_out",       morpher_exp_out},
    {"linear",        morpher_linear},
    {"quad_in",       morpher_quad_in},
    {"quad_inout",    morpher_quad_inout},
    {"quad_out",      morpher_quad_out},
    {"sine",          morpher_sine},
    {"smootherstep",  morpher_smootherstep},
    {"smoothstep",    morpher_smoothstep},
    {"tanh",          morpher_tanh},
    {"welch",         morpher_welch},
    {NULL, NULL}
};

static morpher_fn find_predefined_morpher(const char *name) {
    const morpher_entry *e;
    for (e = predefined_morphers; e->name; e++) {
        if (strcmp(e->name, name) == 0)
            return e->fn;
    }
    return NULL;
}

typedef struct {
    double *levels;      /* N+1 level values */
    double *durations;   /* N duration values */
    double *curves;      /* N curve values */
    int segments;        /* N (number of segments) */
    double total_duration;

    /* Flags */
    int is_morph;
    int is_hold;
    int is_fold_over;
    int is_wrap_neg;

    /* Custom morpher: Perl callback, formula expression, predefined fn, or default */
    SV *morpher_cv;
    te_expr *morpher_expr;
    double morpher_expr_t;
    char *morpher_formula;
    morpher_fn morpher_fn;
    jit_morpher *morpher_jit;

    /* Border levels for random generation */
    double border_start;
    double border_end;

    /* Cached state for sequential access optimization */
    int current_segment;
    int past_segment;
    double passed_duration;
    double level_diff;
    int is_neg;
    int is_asc;
} SegmentedEnvelope;

/* Call Perl morpher callback */
static double call_morpher(pTHX_ SV *morpher_cv, double t) {
    dSP;
    int count;
    double result;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVnv(t)));
    PUTBACK;

    count = call_sv(morpher_cv, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Morpher callback did not return a single value");

    result = POPn;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return result;
}

/* Apply morphing to a value */
/* Priority: morpher_cv > morpher_expr > morpher_fn (predefined or JIT) > default sine */
static double wrap_value(pTHX_ SegmentedEnvelope *env, double t) {
    if (!env->is_morph)
        return t;
    if (env->morpher_cv && SvOK(env->morpher_cv))
        return call_morpher(aTHX_ env->morpher_cv, t);
    if (env->morpher_expr) {
        env->morpher_expr_t = t;
        return te_eval(env->morpher_expr);
    }
    if (env->morpher_fn)
        return env->morpher_fn(t);
    return morpher_sine(t);
}

/* Wrap position based on hold/fold/wrap settings */
static double wrap_pos(SegmentedEnvelope *env, double t) {
    double total = env->total_duration;
    double at, ratio;
    int fold_check;

    if (total <= 0.0 || isnan(t))
        return 0.0;

    if (env->is_hold) {
        if (t > 0)
            return (t > total) ? total : t;
        return 0;
    }

    if (isinf(t))
        return 0.0;

    at = fabs(t);
    if (at > total) {
        ratio = at / total;
        fold_check = (int)fmod(floor(ratio), 2.0);
        if (t < 0 && env->is_wrap_neg)
            fold_check = !fold_check;

        if (env->is_fold_over && fold_check) {
            return (1.0 - (ratio - floor(ratio))) * total;
        } else {
            return (ratio - floor(ratio)) * total;
        }
    }
    return at;
}

/* Update cached segment data */
static void update_current_segment(SegmentedEnvelope *env, int i) {
    if (env->segments <= 0 || i < 0 || i >= env->segments) return;
    env->current_segment = i;
    env->level_diff = env->levels[i + 1] - env->levels[i];
    env->is_neg = (env->curves[i] < 0) ? 1 : 0;
    env->is_asc = (env->level_diff < 0 || env->is_neg) ? -1 : 1;
    env->past_segment = i;
}

/* Main evaluation function */
static double envelope_at(pTHX_ SegmentedEnvelope *env, double t) {
    double pd, d;
    int i;
    double val, curve_abs, ratio;

    if (env->segments <= 0)
        return (env->levels) ? env->levels[0] : 0.0;

    if (isnan(t))
        return t;
    if (isinf(t)) {
        if (env->is_hold)
            return (t > 0) ? env->levels[env->segments] : env->levels[0];
        return t - t;
    }

    t = wrap_pos(env, t);
    pd = env->passed_duration;
    i = env->current_segment;

    /* backward search */
    while (t < pd && i > 0) {
        pd -= env->durations[--i];
    }

    /* remove duration of passed segments */
    if (i == 0)
        pd = 0;
    else
        t -= pd;

    /* forward search - determine segment */
    while (i < env->segments) {
        d = env->durations[i];
        if (t > d && i != env->segments - 1) {
            t -= d;
            pd += d;
            i++;
        } else {
            if (t > d)
                t = d;
            if (i != env->past_segment)
                update_current_segment(env, i);
            break;
        }
    }

    /* cache state for next call */
    if (pd != env->passed_duration)
        env->passed_duration = pd;
    if (i != env->current_segment)
        env->current_segment = i;

    /* calculate result */
    d = env->durations[i];
    if (d <= 0.0)
        return env->levels[i];
    ratio = (env->is_neg ? (d - t) : t) / d;
    val = wrap_value(aTHX_ env, fabs(ratio));
    curve_abs = fabs(env->curves[i]);
    if (curve_abs != 1.0)
        val = (val < 0.0) ? -pow(-val, curve_abs) : pow(val, curve_abs);
    val = val * env->is_asc + env->is_neg;
    val = fabs(val) * env->level_diff + env->levels[i];

    return val;
}

/* Normalize array sum to 1.0 */
static void normalize_sum(double *arr, int len) {
    double sum = 0;
    int i;
    for (i = 0; i < len; i++)
        sum += arr[i];
    if (sum > 0) {
        for (i = 0; i < len; i++)
            arr[i] /= sum;
    }
}

/* Calculate total duration */
static double calc_total_duration(double *durations, int segments) {
    double total = 0;
    int i;
    for (i = 0; i < segments; i++)
        total += durations[i];
    return total;
}

/* Allocate a new zeroed envelope */
static SegmentedEnvelope *new_envelope(void) {
    SegmentedEnvelope *env;
    Newxz(env, 1, SegmentedEnvelope);
    env->past_segment = -1;
    return env;
}

/* Bless an envelope pointer into a Perl object */
static SV *bless_envelope(pTHX_ SegmentedEnvelope *env) {
    SV *sv = newSViv(PTR2IV(env));
    sv = newRV_noinc(sv);
    sv_bless(sv, gv_stashpv("Math::SegmentedEnvelope", GV_ADD));
    return sv;
}

/* Free envelope memory */
static void free_envelope(pTHX_ SegmentedEnvelope *env) {
    if (env) {
        if (env->levels) Safefree(env->levels);
        if (env->durations) Safefree(env->durations);
        if (env->curves) Safefree(env->curves);
        if (env->morpher_cv) SvREFCNT_dec(env->morpher_cv);
        te_free(env->morpher_expr);
        jit_morpher_free(env->morpher_jit);
        if (env->morpher_formula) Safefree(env->morpher_formula);
        Safefree(env);
    }
}

/* Safe array fetching helpers */
static double av_fetch_nv(AV *av, int idx, double default_val) {
    SV **svp = av_fetch(av, idx, 0);
    return (svp && *svp && SvOK(*svp)) ? SvNV(*svp) : default_val;
}

static AV *av_fetch_av(AV *av, int idx) {
    SV **svp = av_fetch(av, idx, 0);
    if (!svp || !*svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
        return NULL;
    return (AV*)SvRV(*svp);
}

/* Safe object unwrapping */
static SegmentedEnvelope *get_envelope(pTHX_ SV *sv, const char *name) {
    SegmentedEnvelope *env;
    if (!sv || !SvROK(sv) || !sv_isobject(sv) || !sv_derived_from(sv, "Math::SegmentedEnvelope"))
        croak("%s: not a Math::SegmentedEnvelope object", name);
    env = INT2PTR(SegmentedEnvelope*, SvIV(SvRV(sv)));
    if (!env)
        croak("%s: uninitialized or freed envelope object", name);
    return env;
}

static SegmentedEnvelope *get_static_envelope(pTHX_ SV *sv, const char *name) {
    SegmentedEnvelope *env;
    if (!sv || !SvROK(sv) || !sv_isobject(sv) || !sv_derived_from(sv, "Math::SegmentedEnvelope::Static"))
        croak("%s: not a Math::SegmentedEnvelope::Static object", name);
    env = INT2PTR(SegmentedEnvelope*, SvIV(SvRV(sv)));
    if (!env)
        croak("%s: uninitialized or freed static envelope object", name);
    return env;
}

/* Compile a morpher formula string, binding to the given t variable */
static te_expr *compile_morpher_formula(const char *formula, double *t_var) {
    int err;
    te_variable vars[] = {{"t", t_var, TE_VARIABLE, NULL}};
    te_expr *expr = te_compile(formula, vars, 1, &err);
    if (!expr)
        croak("morpher_formula: parse error at position %d in '%s'", err, formula);
    return expr;
}

/* Validate a morpher formula string (croaks on error, safe to call before allocation) */
static void validate_morpher_formula(const char *formula) {
    double dummy = 0;
    int err;
    te_variable vars[] = {{"t", &dummy, TE_VARIABLE, NULL}};
    te_expr *expr;

    if (find_predefined_morpher(formula))
        return;

    expr = te_compile(formula, vars, 1, &err);
    if (!expr)
        croak("morpher_formula: parse error at position %d in '%s'", err, formula);
    te_free(expr);
}

/* Set morpher formula on an envelope (shared logic for new/spline/accessor).
 * Caller must validate formula first if allocation has already occurred. */
static void set_morpher_formula(SegmentedEnvelope *env, const char *formula, STRLEN flen) {
    morpher_fn pfn;
    jit_morpher *jit;

    te_free(env->morpher_expr); env->morpher_expr = NULL;
    jit_morpher_free(env->morpher_jit); env->morpher_jit = NULL;
    if (env->morpher_formula) { Safefree(env->morpher_formula); env->morpher_formula = NULL; }
    env->morpher_fn = NULL;
    env->is_morph = 1;

    pfn = find_predefined_morpher(formula);
    if (pfn) {
        env->morpher_fn = pfn;
        return;
    }

    Newx(env->morpher_formula, flen + 1, char);
    Copy(formula, env->morpher_formula, flen + 1, char);
    jit = jit_morpher_compile(formula);
    if (jit) {
        env->morpher_fn = jit->fn;
        env->morpher_jit = jit;
    } else {
        /* compile_morpher_formula won't croak here because we pre-validated */
        env->morpher_expr = compile_morpher_formula(env->morpher_formula, &env->morpher_expr_t);
    }
}

/* Generate random envelope using Perl's RNG for srand() compatibility */
static void generate_random_envelope(pTHX_ SegmentedEnvelope *env) {
    int size = (int)(Drand01() * 5) + 3;
    int i;

    env->segments = size;

    Newx(env->levels, size + 1, double);
    Newx(env->durations, size, double);
    Newx(env->curves, size, double);

    env->levels[0] = env->border_start;
    for (i = 1; i < size; i++)
        env->levels[i] = Drand01();
    env->levels[size] = env->border_end;

    for (i = 0; i < size; i++)
        env->durations[i] = Drand01() + 0.2;
    normalize_sum(env->durations, size);

    for (i = 0; i < size; i++) {
        double c = Drand01() * 2 + 1;
        if (Drand01() > 0.5)
            c = -c;
        env->curves[i] = c;
    }

    env->total_duration = calc_total_duration(env->durations, env->segments);
}

/* Copy envelope boundary/wrapping flags */
static void copy_flags(SegmentedEnvelope *dst, const SegmentedEnvelope *src) {
    dst->is_hold = src->is_hold;
    dst->is_fold_over = src->is_fold_over;
    dst->is_wrap_neg = src->is_wrap_neg;
}

/* Initialize a SegmentedEnvelope as a deep copy of another (for static/table) */
static void copy_envelope(pTHX_ SegmentedEnvelope *dst, SegmentedEnvelope *src) {
    int i;
    STRLEN flen;

    Newx(dst->levels, src->segments + 1, double);
    Newx(dst->durations, src->segments, double);
    Newx(dst->curves, src->segments, double);

    for (i = 0; i <= src->segments; i++)
        dst->levels[i] = src->levels[i];
    for (i = 0; i < src->segments; i++) {
        dst->durations[i] = src->durations[i];
        dst->curves[i] = src->curves[i];
    }

    dst->segments = src->segments;
    dst->total_duration = src->total_duration;
    dst->is_morph = src->is_morph;
    dst->is_hold = src->is_hold;
    dst->is_fold_over = src->is_fold_over;
    dst->is_wrap_neg = src->is_wrap_neg;
    dst->border_start = 0;
    dst->border_end = 0;
    dst->current_segment = 0;
    dst->past_segment = -1;
    dst->passed_duration = 0;
    dst->level_diff = 0;
    dst->is_neg = 0;
    dst->is_asc = 0;

    if (src->morpher_cv && SvOK(src->morpher_cv))
        dst->morpher_cv = newSVsv(src->morpher_cv);
    else
        dst->morpher_cv = NULL;

    dst->morpher_expr_t = 0;
    dst->morpher_fn = src->morpher_fn;
    if (src->morpher_formula) {
        flen = strlen(src->morpher_formula);
        Newx(dst->morpher_formula, flen + 1, char);
        Copy(src->morpher_formula, dst->morpher_formula, flen + 1, char);
        /* Try JIT, fall back to tinyexpr */
        {
            jit_morpher *jit = jit_morpher_compile(src->morpher_formula);
            if (jit) {
                dst->morpher_fn = jit->fn;
                dst->morpher_jit = jit;
                dst->morpher_expr = NULL;
            } else {
                dst->morpher_fn = NULL;
                dst->morpher_jit = NULL;
                dst->morpher_expr = compile_morpher_formula(dst->morpher_formula, &dst->morpher_expr_t);
            }
        }
    } else {
        dst->morpher_jit = NULL;
        dst->morpher_formula = NULL;
        dst->morpher_expr = NULL;
    }
}

/* Initialize a stack-local SegmentedEnvelope borrowing arrays from parent (for table) */
static void borrow_envelope(pTHX_ SegmentedEnvelope *dst, SegmentedEnvelope *src) {
    dst->levels = src->levels;
    dst->durations = src->durations;
    dst->curves = src->curves;
    dst->segments = src->segments;
    dst->total_duration = src->total_duration;
    dst->is_morph = src->is_morph;
    dst->is_hold = src->is_hold;
    dst->is_fold_over = src->is_fold_over;
    dst->is_wrap_neg = src->is_wrap_neg;
    dst->border_start = 0;
    dst->border_end = 0;

    dst->morpher_cv = src->morpher_cv;
    dst->morpher_fn = src->morpher_fn;
    dst->morpher_jit = NULL;
    dst->morpher_formula = NULL;
    dst->morpher_expr_t = 0;
    if (src->morpher_formula && !src->morpher_jit) {
        dst->morpher_expr = compile_morpher_formula(src->morpher_formula, &dst->morpher_expr_t);
    } else {
        dst->morpher_expr = NULL;
    }

    dst->current_segment = 0;
    dst->past_segment = -1;
    dst->passed_duration = 0;
    dst->level_diff = 0;
    dst->is_neg = 0;
    dst->is_asc = 0;
}

MODULE = Math::SegmentedEnvelope    PACKAGE = Math::SegmentedEnvelope

PROTOTYPES: DISABLE

SV *
new(class, ...)
    SV *class
PREINIT:
    SegmentedEnvelope *env;
    SV *def_sv = NULL;
    AV *def_av;
    AV *levels_av = NULL, *durs_av = NULL, *curves_av = NULL;
    int i, num_levels = 0, num_durs = 0, num_curves = 0;
    int arg_start = 1;
    HV *stash;
    SV *self;
    const char *classname;
CODE:
    /* Parse arguments */
    if (items == 2) {
        def_sv = ST(1);
        arg_start = 2;
    } else if (items > 2) {
        if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
            def_sv = ST(1);
            arg_start = 2;
        } else if (SvPOK(ST(1))) {
            STRLEN len;
            const char *key = SvPV(ST(1), len);
            if (strEQ(key, "def") && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
                def_sv = ST(2);
                arg_start = 3;
            }
        }
    }

    /* Check def in options if not found yet */
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            STRLEN len;
            const char *key = SvPV(ST(i), len);
            if (strEQ(key, "def")) {
                def_sv = ST(i + 1);
            }
        }
    }

    /* Validate def_sv before allocating env */
    if (def_sv) {
        if (!SvROK(def_sv) || SvTYPE(SvRV(def_sv)) != SVt_PVAV)
            croak("def must be an array reference");
        def_av = (AV*)SvRV(def_sv);
        if (av_len(def_av) != 2)
            croak("def must have exactly 3 elements");

        levels_av = av_fetch_av(def_av, 0);
        durs_av   = av_fetch_av(def_av, 1);
        curves_av = av_fetch_av(def_av, 2);

        if (!levels_av || !durs_av || !curves_av)
            croak("def elements must be array references");

        num_levels = av_len(levels_av) + 1;
        num_durs   = av_len(durs_av) + 1;
        num_curves = av_len(curves_av) + 1;

        if (num_durs < 1)
            croak("envelope must have at least 1 segment");

        if (num_levels != num_durs + 1 || num_levels != num_curves + 1 || num_durs != num_curves)
            croak("size mismatch in envelope definition");
    }

    /* Pre-validate morpher_formula before allocating (croak-safe) */
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i)) && strEQ(SvPV_nolen(ST(i)), "morpher_formula")) {
            if (SvOK(ST(i + 1)))
                validate_morpher_formula(SvPV_nolen(ST(i + 1)));
        }
    }

    /* Allocate and zero-initialize */
    Newxz(env, 1, SegmentedEnvelope);
    env->border_start = Drand01();
    env->border_end = Drand01();
    env->past_segment = -1;

    /* Parse remaining key-value pairs */
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            STRLEN len;
            const char *key = SvPV(ST(i), len);
            SV *val = ST(i + 1);

            if (strEQ(key, "is_morph")) {
                env->is_morph = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "is_hold")) {
                env->is_hold = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "is_fold_over")) {
                env->is_fold_over = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "is_wrap_neg")) {
                env->is_wrap_neg = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "morpher")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
                    env->morpher_cv = newSVsv(val);
                }
            } else if (strEQ(key, "morpher_formula")) {
                if (SvOK(val)) {
                    STRLEN flen;
                    const char *formula = SvPV(val, flen);
                    set_morpher_formula(env, formula, flen);
                }
            } else if (strEQ(key, "border_level")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *bl = (AV*)SvRV(val);
                    if (av_len(bl) >= 0)
                        env->border_start = av_fetch_nv(bl, 0, 0.0);
                    if (av_len(bl) >= 1)
                        env->border_end = av_fetch_nv(bl, 1, env->border_start);
                    else
                        env->border_end = env->border_start;
                } else if (SvOK(val)) {
                    env->border_start = SvNV(val);
                    env->border_end = env->border_start;
                }
            }
        }
    }

    /* Initialize envelope data */
    if (def_sv) {
        env->segments = num_durs;
        Newx(env->levels, num_levels, double);
        Newx(env->durations, num_durs, double);
        Newx(env->curves, num_curves, double);

        for (i = 0; i < num_levels; i++)
            env->levels[i] = av_fetch_nv(levels_av, i, 0.0);
        for (i = 0; i < num_durs; i++)
            env->durations[i] = av_fetch_nv(durs_av, i, 0.0);
        for (i = 0; i < num_curves; i++)
            env->curves[i] = av_fetch_nv(curves_av, i, 1.0);

        env->total_duration = calc_total_duration(env->durations, env->segments);
    } else {
        /* Generate random envelope */
        generate_random_envelope(aTHX_ env);
    }

    /* Create blessed reference */
    classname = (sv_isobject(class)) ? HvNAME(SvSTASH(SvRV(class)))
              : (SvPOK(class) ? SvPV_nolen(class) : "Math::SegmentedEnvelope");
    self = newSViv(PTR2IV(env));
    self = newRV_noinc(self);
    stash = gv_stashpv(classname, GV_ADD);
    sv_bless(self, stash);

    RETVAL = self;
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    if (self && SvROK(self) && sv_isobject(self) && sv_derived_from(self, "Math::SegmentedEnvelope")) {
        env = INT2PTR(SegmentedEnvelope*, SvIV(SvRV(self)));
        free_envelope(aTHX_ env);
    }

double
at(self, t)
    SV *self
    double t
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "at");
    RETVAL = envelope_at(aTHX_ env, t);
OUTPUT:
    RETVAL

int
segment_at(self, t)
    SV *self
    double t
PREINIT:
    SegmentedEnvelope *env;
    double pd, d;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "segment_at");
    if (env->total_duration <= 0.0 || isnan(t)) {
        RETVAL = 0;
    } else if (isinf(t)) {
        RETVAL = (t > 0 && env->segments > 0) ? (env->segments - 1) : 0;
    } else {
        t = wrap_pos(env, t);
        pd = 0;
        for (i = 0; i < env->segments; i++) {
            d = env->durations[i];
            if (t <= pd + d || i == env->segments - 1) {
                RETVAL = i;
                break;
            }
            pd += d;
        }
    }
OUTPUT:
    RETVAL

SV *
static(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    SegmentedEnvelope *senv;
    SV *closure;
CODE:
    env = get_envelope(aTHX_ self, "static");

    Newxz(senv, 1, SegmentedEnvelope);
    copy_envelope(aTHX_ senv, env);

    closure = newSViv(PTR2IV(senv));
    RETVAL = sv_bless(newRV_noinc(closure),
                      gv_stashpv("Math::SegmentedEnvelope::Static", GV_ADD));
OUTPUT:
    RETVAL

void
table(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    SegmentedEnvelope senv;
    int size = 1024;
    int loop = 1;
    double from = 0;
    double to;
    int i;
    double range, lp, p;
CODE:
    env = get_envelope(aTHX_ self, "table");

    if (items > 1) size = SvIV(ST(1));
    if (items > 2) loop = SvIV(ST(2));
    if (items > 3) from = SvNV(ST(3));
    to = (items > 4) ? SvNV(ST(4)) : env->total_duration;

    if (size <= 0)
        croak("table size should be >= 1");

    memset(&senv, 0, sizeof(senv));
    borrow_envelope(aTHX_ &senv, env);

    range = to - from;
    lp = (double)loop / size;

    if (senv.morpher_cv && SvOK(senv.morpher_cv)) {
        /* Pre-compute to avoid stack corruption between PUSHs and call_sv */
        SV *buf_sv = sv_2mortal(newSVpvn("", 0));
        double *vals;
        SvGROW(buf_sv, size * sizeof(double));
        vals = (double*)SvPVX(buf_sv);
        for (i = 0; i < size; i++) {
            p = i * lp;
            p = p - floor(p);
            vals[i] = envelope_at(aTHX_ &senv, from + range * p);
        }
        SP -= items;
        EXTEND(SP, size);
        for (i = 0; i < size; i++)
            PUSHs(sv_2mortal(newSVnv(vals[i])));
    } else {
        SP -= items;
        EXTEND(SP, size);
        for (i = 0; i < size; i++) {
            p = i * lp;
            p = p - floor(p);
            PUSHs(sv_2mortal(newSVnv(envelope_at(aTHX_ &senv, from + range * p))));
        }
    }
    te_free(senv.morpher_expr);
    XSRETURN(size);

void
clean(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "clean");
    env->total_duration = calc_total_duration(env->durations, env->segments);
    env->current_segment = 0;
    env->past_segment = -1;
    env->passed_duration = 0;

double
duration(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "duration");
    RETVAL = env->total_duration;
OUTPUT:
    RETVAL

int
segments(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "segments");
    RETVAL = env->segments;
OUTPUT:
    RETVAL

SV *
level(self, idx, ...)
    SV *self
    int idx
PREINIT:
    SegmentedEnvelope *env;
    int real_idx;
CODE:
    env = get_envelope(aTHX_ self, "level");
    real_idx = (idx >= 0) ? idx : (env->segments + 1 + idx);

    if (real_idx < 0 || real_idx > env->segments)
        croak("no such index '%d' in definition part '0'", idx);

    if (items > 2) {
        env->levels[real_idx] = SvNV(ST(2));
        if (abs(env->current_segment - real_idx) <= 1)
            update_current_segment(env, env->current_segment);
    }

    RETVAL = newSVnv(env->levels[real_idx]);
OUTPUT:
    RETVAL

void
levels(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "levels");

    if (items > 1) {
        if (items - 1 != env->segments + 1)
            croak("size mismatch against initial definition");
        for (i = 0; i <= env->segments; i++)
            env->levels[i] = SvNV(ST(i + 1));
        update_current_segment(env, env->current_segment);
    }

    SP -= items;
    EXTEND(SP, env->segments + 1);
    for (i = 0; i <= env->segments; i++)
        PUSHs(sv_2mortal(newSVnv(env->levels[i])));
    XSRETURN(env->segments + 1);

SV *
dur(self, idx, ...)
    SV *self
    int idx
PREINIT:
    SegmentedEnvelope *env;
    int real_idx;
CODE:
    env = get_envelope(aTHX_ self, "dur");
    real_idx = (idx >= 0) ? idx : (env->segments + idx);

    if (real_idx < 0 || real_idx >= env->segments)
        croak("no such index '%d' in definition part '1'", idx);

    if (items > 2) {
        env->durations[real_idx] = SvNV(ST(2));
        env->total_duration = calc_total_duration(env->durations, env->segments);
        env->current_segment = 0;
        env->past_segment = -1;
        env->passed_duration = 0;
    }

    RETVAL = newSVnv(env->durations[real_idx]);
OUTPUT:
    RETVAL

void
durs(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "durs");

    if (items > 1) {
        if (items - 1 != env->segments)
            croak("size mismatch against initial definition");
        for (i = 0; i < env->segments; i++)
            env->durations[i] = SvNV(ST(i + 1));
        env->total_duration = calc_total_duration(env->durations, env->segments);
        env->current_segment = 0;
        env->past_segment = -1;
        env->passed_duration = 0;
    }

    SP -= items;
    EXTEND(SP, env->segments);
    for (i = 0; i < env->segments; i++)
        PUSHs(sv_2mortal(newSVnv(env->durations[i])));
    XSRETURN(env->segments);

SV *
curve(self, idx, ...)
    SV *self
    int idx
PREINIT:
    SegmentedEnvelope *env;
    int real_idx;
CODE:
    env = get_envelope(aTHX_ self, "curve");
    real_idx = (idx >= 0) ? idx : (env->segments + idx);

    if (real_idx < 0 || real_idx >= env->segments)
        croak("no such index '%d' in definition part '2'", idx);

    if (items > 2) {
        env->curves[real_idx] = SvNV(ST(2));
        if (env->current_segment == real_idx)
            update_current_segment(env, env->current_segment);
    }

    RETVAL = newSVnv(env->curves[real_idx]);
OUTPUT:
    RETVAL

void
curves(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "curves");

    if (items > 1) {
        if (items - 1 != env->segments)
            croak("size mismatch against initial definition");
        for (i = 0; i < env->segments; i++)
            env->curves[i] = SvNV(ST(i + 1));
        update_current_segment(env, env->current_segment);
    }

    SP -= items;
    EXTEND(SP, env->segments);
    for (i = 0; i < env->segments; i++)
        PUSHs(sv_2mortal(newSVnv(env->curves[i])));
    XSRETURN(env->segments);

SV *
is_morph(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "is_morph");
    if (items > 1)
        env->is_morph = SvTRUE(ST(1)) ? 1 : 0;
    RETVAL = env->is_morph ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
is_hold(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "is_hold");
    if (items > 1)
        env->is_hold = SvTRUE(ST(1)) ? 1 : 0;
    RETVAL = env->is_hold ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
is_fold_over(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "is_fold_over");
    if (items > 1)
        env->is_fold_over = SvTRUE(ST(1)) ? 1 : 0;
    RETVAL = env->is_fold_over ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
is_wrap_neg(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "is_wrap_neg");
    if (items > 1)
        env->is_wrap_neg = SvTRUE(ST(1)) ? 1 : 0;
    RETVAL = env->is_wrap_neg ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
morpher(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "morpher");
    if (items > 1) {
        if (env->morpher_cv) {
            SvREFCNT_dec(env->morpher_cv);
            env->morpher_cv = NULL;
        }
        if (SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
            env->morpher_cv = newSVsv(ST(1));
        }
    }
    if (env->morpher_cv && SvOK(env->morpher_cv))
        RETVAL = newSVsv(env->morpher_cv);
    else
        RETVAL = &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
morpher_formula(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "morpher_formula");
    if (items > 1) {
        if (!SvOK(ST(1))) {
            /* undef = reset to default */
            te_free(env->morpher_expr); env->morpher_expr = NULL;
            jit_morpher_free(env->morpher_jit); env->morpher_jit = NULL;
            if (env->morpher_formula) { Safefree(env->morpher_formula); env->morpher_formula = NULL; }
            env->morpher_fn = NULL;
        } else {
            STRLEN flen;
            const char *formula = SvPV(ST(1), flen);
            validate_morpher_formula(formula);
            set_morpher_formula(env, formula, flen);
        }
    }
    if (env->morpher_formula)
        RETVAL = newSVpv(env->morpher_formula, 0);
    else if (env->morpher_fn) {
        /* Find the name of the predefined morpher */
        const morpher_entry *e;
        RETVAL = &PL_sv_undef;
        for (e = predefined_morphers; e->name; e++) {
            if (e->fn == env->morpher_fn) {
                RETVAL = newSVpv(e->name, 0);
                break;
            }
        }
    }
    else
        RETVAL = &PL_sv_undef;
OUTPUT:
    RETVAL

void
morpher_formulas(...)
CODE:
{
    const morpher_entry *e;
    int count = 0;
    SP -= items;
    for (e = predefined_morphers; e->name; e++)
        count++;
    EXTEND(SP, count);
    for (e = predefined_morphers; e->name; e++)
        PUSHs(sv_2mortal(newSVpv(e->name, 0)));
    XSRETURN(count);
}

SV *
morpher_jit_backend(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "morpher_jit_backend");
    if (env->morpher_jit)
        RETVAL = newSVpv(jit_backend_name(env->morpher_jit), 0);
    else if (env->morpher_fn && !env->morpher_formula)
        RETVAL = newSVpv("builtin", 0);
    else
        RETVAL = newSVpv("none", 0);
OUTPUT:
    RETVAL

SV *
border_level(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    AV *result;
CODE:
    env = get_envelope(aTHX_ self, "border_level");
    if (items > 1) {
        SV *val = ST(1);
        if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
            AV *bl = (AV*)SvRV(val);
            if (av_len(bl) >= 0)
                env->border_start = av_fetch_nv(bl, 0, 0.0);
            if (av_len(bl) >= 1)
                env->border_end = av_fetch_nv(bl, 1, env->border_start);
            else
                env->border_end = env->border_start;
        } else if (SvOK(val)) {
            env->border_start = SvNV(val);
            env->border_end = env->border_start;
        }
    }
    result = newAV();
    av_push(result, newSVnv(env->border_start));
    av_push(result, newSVnv(env->border_end));
    RETVAL = newRV_noinc((SV*)result);
OUTPUT:
    RETVAL

SV *
normalize_duration(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "normalize_duration");
    normalize_sum(env->durations, env->segments);
    env->total_duration = calc_total_duration(env->durations, env->segments);
    env->current_segment = 0;
    env->past_segment = -1;
    env->passed_duration = 0;
    RETVAL = newSVsv(self);
OUTPUT:
    RETVAL

SV *
def(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    AV *result, *levels_av, *durs_av, *curves_av;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "def");

    levels_av = newAV();
    durs_av = newAV();
    curves_av = newAV();

    for (i = 0; i <= env->segments; i++)
        av_push(levels_av, newSVnv(env->levels[i]));
    for (i = 0; i < env->segments; i++) {
        av_push(durs_av, newSVnv(env->durations[i]));
        av_push(curves_av, newSVnv(env->curves[i]));
    }

    result = newAV();
    av_push(result, newRV_noinc((SV*)levels_av));
    av_push(result, newRV_noinc((SV*)durs_av));
    av_push(result, newRV_noinc((SV*)curves_av));

    RETVAL = newRV_noinc((SV*)result);
OUTPUT:
    RETVAL

SV *
spline(...)
PREINIT:
    AV *times_av, *values_av;
    int n, total_segs, res, span, i, idx, arg_start;
    double tension, tau;
    double *times, *vals;
    SegmentedEnvelope *env;
    SV *self;
    HV *stash;
    const char *classname;
    SV *times_ref, *values_ref;
CODE:
    /* Detect class method vs instance method vs function call */
    if (items >= 3 && (sv_isobject(ST(0)) || (SvPOK(ST(0)) && !SvROK(ST(0))))) {
        classname = sv_isobject(ST(0)) ? HvNAME(SvSTASH(SvRV(ST(0)))) : SvPV_nolen(ST(0));
        times_ref = ST(1);
        values_ref = ST(2);
        arg_start = 3;
    } else if (items >= 2 && !sv_isobject(ST(0))) {
        classname = "Math::SegmentedEnvelope";
        times_ref = ST(0);
        values_ref = ST(1);
        arg_start = 2;
    } else {
        croak("Usage: spline(\\@times, \\@values, %%opts)");
    }

    if (!SvROK(times_ref) || SvTYPE(SvRV(times_ref)) != SVt_PVAV)
        croak("spline: times must be an array reference");
    if (!SvROK(values_ref) || SvTYPE(SvRV(values_ref)) != SVt_PVAV)
        croak("spline: values must be an array reference");

    times_av = (AV*)SvRV(times_ref);
    values_av = (AV*)SvRV(values_ref);
    n = av_len(times_av) + 1;
    if (n < 2)
        croak("spline requires at least 2 points");
    if (n != av_len(values_av) + 1)
        croak("spline: times and values must have equal length");

    /* Pre-validate morpher_formula before allocating */
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i)) && strEQ(SvPV_nolen(ST(i)), "morpher_formula")) {
            if (SvOK(ST(i + 1)))
                validate_morpher_formula(SvPV_nolen(ST(i + 1)));
        }
    }

    /* Parse optional key-value args */
    res = 8;
    tension = 0.0;
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "resolution"))
                res = SvIV(ST(i + 1));
            else if (strEQ(key, "tension"))
                tension = SvNV(ST(i + 1));
        }
    }
    if (res < 1) res = 1;
    if (tension < 0.0) tension = 0.0;
    if (tension > 1.0) tension = 1.0;
    tau = (1.0 - tension) * 0.5;

    /* Read input arrays */
    Newx(times, n, double);
    Newx(vals, n, double);
    for (i = 0; i < n; i++) {
        times[i] = av_fetch_nv(times_av, i, 0.0);
        vals[i] = av_fetch_nv(values_av, i, 0.0);
    }

    /* Allocate envelope: (n-1)*res segments, (n-1)*res+1 levels */
    total_segs = (n - 1) * res;
    Newxz(env, 1, SegmentedEnvelope);
    env->past_segment = -1;
    env->segments = total_segs;
    Newx(env->levels, total_segs + 1, double);
    Newx(env->durations, total_segs, double);
    Newx(env->curves, total_segs, double);

    idx = 0;
    for (span = 0; span < n - 1; span++) {
        double dt = times[span + 1] - times[span];
        double seg_dur = (dt > 0.0) ? dt / res : 0.0;
        double p0 = vals[span > 0 ? span - 1 : span];
        double p1 = vals[span];
        double p2 = vals[span + 1];
        double p3 = vals[span + 2 < n ? span + 2 : span + 1];

        for (i = 0; i <= res; i++) {
            if (span > 0 && i == 0) continue;
            {
                double s = (double)i / res;
                double s2 = s * s;
                double s3 = s2 * s;
                double v = (-tau*s3 + 2*tau*s2 - tau*s) * p0
                         + ((2-tau)*s3 + (tau-3)*s2 + 1) * p1
                         + ((tau-2)*s3 + (3-2*tau)*s2 + tau*s) * p2
                         + (tau*s3 - tau*s2) * p3;

                env->levels[idx] = v;
                if (idx > 0) {
                    env->durations[idx - 1] = seg_dur;
                    env->curves[idx - 1] = 1.0;
                }
                idx++;
            }
        }
    }

    env->total_duration = calc_total_duration(env->durations, env->segments);

    Safefree(times);
    Safefree(vals);

    /* Parse remaining envelope options (is_morph, etc.) */
    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "is_morph"))
                env->is_morph = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "is_hold"))
                env->is_hold = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "is_fold_over"))
                env->is_fold_over = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "is_wrap_neg"))
                env->is_wrap_neg = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "morpher_formula")) {
                if (SvOK(val)) {
                    STRLEN flen;
                    const char *formula = SvPV(val, flen);
                    set_morpher_formula(env, formula, flen);
                }
            } else if (strEQ(key, "morpher")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV)
                    env->morpher_cv = newSVsv(val);
            }
        }
    }

    /* classname was set during arg parsing above */
    self = newSViv(PTR2IV(env));
    self = newRV_noinc(self);
    stash = gv_stashpv(classname, GV_ADD);
    sv_bless(self, stash);
    RETVAL = self;
OUTPUT:
    RETVAL

SV *
quantize(self, steps)
    SV *self
    int steps
PREINIT:
    SegmentedEnvelope *env, *nenv;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "quantize");
    if (steps < 2) steps = 2;

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = env->segments;

    Newx(nenv->levels, env->segments + 1, double);
    Newx(nenv->durations, env->segments, double);
    Newx(nenv->curves, env->segments, double);

    for (i = 0; i <= env->segments; i++)
        nenv->levels[i] = floor(env->levels[i] * steps + 0.5) / steps;
    for (i = 0; i < env->segments; i++) {
        nenv->durations[i] = env->durations[i];
        nenv->curves[i] = env->curves[i];
    }
    nenv->total_duration = env->total_duration;

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
trim(self, from_t, to_t, ...)
    SV *self
    double from_t
    double to_t
PREINIT:
    SegmentedEnvelope *env, *nenv;
    SegmentedEnvelope senv;
    int i, segments;
    double dur, seg_dur;
CODE:
    env = get_envelope(aTHX_ self, "trim");

    dur = to_t - from_t;
    if (dur <= 0.0)
        croak("trim: to_t must be greater than from_t");

    segments = 32;
    for (i = 3; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i)) && strEQ(SvPV_nolen(ST(i)), "segments"))
            segments = SvIV(ST(i + 1));
    }
    if (segments < 1) segments = 1;

    seg_dur = dur / segments;

    /* Borrow parent for evaluation */
    memset(&senv, 0, sizeof(senv));
    borrow_envelope(aTHX_ &senv, env);

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = segments;
    Newx(nenv->levels, segments + 1, double);
    Newx(nenv->durations, segments, double);
    Newx(nenv->curves, segments, double);

    for (i = 0; i <= segments; i++)
        nenv->levels[i] = envelope_at(aTHX_ &senv, from_t + i * seg_dur);
    for (i = 0; i < segments; i++) {
        nenv->durations[i] = seg_dur;
        nenv->curves[i] = 1.0;
    }
    nenv->total_duration = dur;

    te_free(senv.morpher_expr);

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
lerp(self, other_sv, mix)
    SV *self
    SV *other_sv
    double mix
PREINIT:
    SegmentedEnvelope *a, *b, *nenv;
    int i;
    double imix;
CODE:
    a = get_envelope(aTHX_ self, "lerp");
    b = get_envelope(aTHX_ other_sv, "lerp");

    if (a->segments != b->segments)
        croak("lerp: envelopes must have the same number of segments (use blend for different sizes)");

    imix = 1.0 - mix;

    nenv = new_envelope();
    copy_flags(nenv, a);
    nenv->segments = a->segments;

    Newx(nenv->levels, a->segments + 1, double);
    Newx(nenv->durations, a->segments, double);
    Newx(nenv->curves, a->segments, double);

    for (i = 0; i <= a->segments; i++)
        nenv->levels[i] = a->levels[i] * imix + b->levels[i] * mix;
    for (i = 0; i < a->segments; i++) {
        nenv->durations[i] = a->durations[i] * imix + b->durations[i] * mix;
        nenv->curves[i] = a->curves[i] * imix + b->curves[i] * mix;
    }
    nenv->total_duration = calc_total_duration(nenv->durations, nenv->segments);

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
resample(self, num_segments)
    SV *self
    int num_segments
PREINIT:
    SegmentedEnvelope *env, *nenv;
    SegmentedEnvelope senv;
    int i;
    double seg_dur;
CODE:
    env = get_envelope(aTHX_ self, "resample");
    if (num_segments < 1) num_segments = 1;

    memset(&senv, 0, sizeof(senv));
    borrow_envelope(aTHX_ &senv, env);

    seg_dur = env->total_duration / num_segments;

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = num_segments;
    Newx(nenv->levels, num_segments + 1, double);
    Newx(nenv->durations, num_segments, double);
    Newx(nenv->curves, num_segments, double);

    for (i = 0; i <= num_segments; i++)
        nenv->levels[i] = envelope_at(aTHX_ &senv, i * seg_dur);
    for (i = 0; i < num_segments; i++) {
        nenv->durations[i] = seg_dur;
        nenv->curves[i] = 1.0;
    }
    nenv->total_duration = env->total_duration;

    te_free(senv.morpher_expr);

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
clamp(self, lo, hi)
    SV *self
    double lo
    double hi
PREINIT:
    SegmentedEnvelope *env, *nenv;
    int i;
    double v;
CODE:
    env = get_envelope(aTHX_ self, "clamp");
    if (lo > hi) {
        double tmp = lo;
        lo = hi;
        hi = tmp;
    }

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = env->segments;
    Newx(nenv->levels, env->segments + 1, double);
    Newx(nenv->durations, env->segments, double);
    Newx(nenv->curves, env->segments, double);

    for (i = 0; i <= env->segments; i++) {
        v = env->levels[i];
        if (v < lo) v = lo;
        if (v > hi) v = hi;
        nenv->levels[i] = v;
    }
    for (i = 0; i < env->segments; i++) {
        nenv->durations[i] = env->durations[i];
        nenv->curves[i] = env->curves[i];
    }
    nenv->total_duration = env->total_duration;

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
smooth(self, ...)
    SV *self
PREINIT:
    SegmentedEnvelope *env, *nenv;
    int i, passes, p;
    double *buf;
CODE:
    env = get_envelope(aTHX_ self, "smooth");
    passes = (items > 1) ? SvIV(ST(1)) : 1;
    if (passes < 1) passes = 1;

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = env->segments;
    Newx(nenv->levels, env->segments + 1, double);
    Newx(nenv->durations, env->segments, double);
    Newx(nenv->curves, env->segments, double);

    for (i = 0; i <= env->segments; i++)
        nenv->levels[i] = env->levels[i];
    for (i = 0; i < env->segments; i++) {
        nenv->durations[i] = env->durations[i];
        nenv->curves[i] = env->curves[i];
    }
    nenv->total_duration = env->total_duration;

    /* Moving average smoothing: keep endpoints fixed */
    Newx(buf, env->segments + 1, double);
    for (p = 0; p < passes; p++) {
        Copy(nenv->levels, buf, env->segments + 1, double);
        for (i = 1; i < env->segments; i++)
            nenv->levels[i] = (buf[i-1] + buf[i] + buf[i+1]) / 3.0;
    }
    Safefree(buf);

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
derivative(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env, *nenv;
    int i;
CODE:
    env = get_envelope(aTHX_ self, "derivative");

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = env->segments;
    Newx(nenv->levels, env->segments + 1, double);
    Newx(nenv->durations, env->segments, double);
    Newx(nenv->curves, env->segments, double);

    /* Rate of change at each breakpoint (forward difference) */
    for (i = 0; i < env->segments; i++) {
        double dl = env->levels[i+1] - env->levels[i];
        double dt = env->durations[i];
        nenv->levels[i] = (dt > 0) ? dl / dt : 0;
    }
    /* Last level: same as previous (no forward segment) */
    nenv->levels[env->segments] = (env->segments > 0)
        ? nenv->levels[env->segments - 1] : 0;

    for (i = 0; i < env->segments; i++) {
        nenv->durations[i] = env->durations[i];
        nenv->curves[i] = 1.0;
    }
    nenv->total_duration = env->total_duration;

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
integrate(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env, *nenv;
    int i;
    double accum;
CODE:
    env = get_envelope(aTHX_ self, "integrate");

    nenv = new_envelope();
    copy_flags(nenv, env);
    nenv->segments = env->segments;
    Newx(nenv->levels, env->segments + 1, double);
    Newx(nenv->durations, env->segments, double);
    Newx(nenv->curves, env->segments, double);

    /* Cumulative trapezoidal integration */
    accum = 0;
    nenv->levels[0] = 0;
    for (i = 0; i < env->segments; i++) {
        accum += (env->levels[i] + env->levels[i+1]) * 0.5 * env->durations[i];
        nenv->levels[i+1] = accum;
        nenv->durations[i] = env->durations[i];
        nenv->curves[i] = 1.0;
    }
    nenv->total_duration = env->total_duration;

    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

SV *
from_samples(...)
PREINIT:
    AV *samples_av;
    SegmentedEnvelope *env;
    int n, i;
    double seg_dur, dur;
    SV *samples_ref;
    int arg_start = 2;
CODE:
    /* Detect class method vs instance method vs function call */
    if (items >= 3 && (sv_isobject(ST(0)) || (SvPOK(ST(0)) && !SvROK(ST(0))))) {
        samples_ref = ST(1);
        dur = SvNV(ST(2));
        arg_start = 3;
    } else if (items >= 2 && !sv_isobject(ST(0))) {
        samples_ref = ST(0);
        dur = SvNV(ST(1));
        arg_start = 2;
    } else {
        croak("Usage: from_samples(\\@values, $duration)");
    }

    if (!SvROK(samples_ref) || SvTYPE(SvRV(samples_ref)) != SVt_PVAV)
        croak("from_samples: samples must be an array reference");

    samples_av = (AV*)SvRV(samples_ref);
    n = av_len(samples_av) + 1;
    if (n < 2)
        croak("from_samples requires at least 2 samples");
    if (dur <= 0)
        croak("from_samples: duration must be positive");

    seg_dur = dur / (n - 1);

    env = new_envelope();
    env->segments = n - 1;
    Newx(env->levels, n, double);
    Newx(env->durations, n - 1, double);
    Newx(env->curves, n - 1, double);

    for (i = 0; i < n; i++)
        env->levels[i] = av_fetch_nv(samples_av, i, 0.0);
    for (i = 0; i < n - 1; i++) {
        env->durations[i] = seg_dur;
        env->curves[i] = 1.0;
    }
    env->total_duration = dur;

    for (i = arg_start; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "is_hold"))
                env->is_hold = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "is_fold_over"))
                env->is_fold_over = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "is_wrap_neg"))
                env->is_wrap_neg = SvTRUE(val) ? 1 : 0;
        }
    }

    RETVAL = bless_envelope(aTHX_ env);
OUTPUT:
    RETVAL

SV *
_raw_levels(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
CODE:
    env = get_envelope(aTHX_ self, "_raw_levels");
    if (!env->levels || env->segments < 1)
        RETVAL = newSVpvn("", 0);
    else
        RETVAL = newSVpvn((const char *)env->levels, (env->segments + 1) * sizeof(double));
OUTPUT:
    RETVAL

SV *
_raw_table(self, size)
    SV *self
    int size
PREINIT:
    SegmentedEnvelope *env;
    SegmentedEnvelope senv;
    double *buf;
    int i;
    double lp, p;
CODE:
    env = get_envelope(aTHX_ self, "_raw_table");
    if (size < 1) size = 1;

    memset(&senv, 0, sizeof(senv));
    borrow_envelope(aTHX_ &senv, env);

    Newx(buf, size, double);
    lp = 1.0 / size;
    for (i = 0; i < size; i++) {
        p = i * lp;
        buf[i] = envelope_at(aTHX_ &senv, p * env->total_duration);
    }
    te_free(senv.morpher_expr);

    RETVAL = newSVpvn((const char *)buf, size * sizeof(double));
    Safefree(buf);
OUTPUT:
    RETVAL

SV *
clone(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env, *nenv;
CODE:
    env = get_envelope(aTHX_ self, "clone");
    nenv = new_envelope();
    copy_envelope(aTHX_ nenv, env);
    RETVAL = bless_envelope(aTHX_ nenv);
OUTPUT:
    RETVAL

double
area(self)
    SV *self
PREINIT:
    SegmentedEnvelope *env;
    int i;
    double total = 0.0;
CODE:
    env = get_envelope(aTHX_ self, "area");
    for (i = 0; i < env->segments; i++)
        total += (env->levels[i] + env->levels[i+1]) * 0.5 * env->durations[i];
    RETVAL = total;
OUTPUT:
    RETVAL

MODULE = Math::SegmentedEnvelope    PACKAGE = Math::SegmentedEnvelope::Static

void
DESTROY(self)
    SV *self
PREINIT:
    SegmentedEnvelope *senv;
CODE:
    if (self && SvROK(self) && sv_isobject(self) && sv_derived_from(self, "Math::SegmentedEnvelope::Static")) {
        senv = INT2PTR(SegmentedEnvelope*, SvIV(SvRV(self)));
        free_envelope(aTHX_ senv);
    }

double
call(self, t)
    SV *self
    double t
PREINIT:
    SegmentedEnvelope *senv;
CODE:
    senv = get_static_envelope(aTHX_ self, "call");
    RETVAL = envelope_at(aTHX_ senv, t);
OUTPUT:
    RETVAL
