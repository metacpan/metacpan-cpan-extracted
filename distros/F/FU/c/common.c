/* Because I don't know how to use sv_setref_pv() correctly. */

static SV *fu_selfobj_(pTHX_ SV **self, void *obj, const char *klass) {
    *self = newSViv(PTR2IV(obj));
    return sv_bless(sv_2mortal(newRV_noinc(*self)), gv_stashpv(klass, GV_ADD));
}
/* Write a blessed SV to obj->self and returns a mortal ref to it */
#define fu_selfobj(obj, klass) fu_selfobj_(aTHX_ &((obj)->self), obj, klass)



/* Return an SV to use for croak_sv() with a HV object.
 * Adds a "full_message" field including stack trace. */

__attribute__((format (printf, 3, 4)))
static SV *fu_croak_hv(HV *hv, const char *klass, const char *message, ...) {
    va_list args;
    SV *sv;
    dTHX;
    dSP;

    va_start(args, message);
    sv = vnewSVpvf(message, &args);
    va_end(args);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(sv);
    PUTBACK;
    call_pv("Carp::longmess", G_SCALAR);
    hv_stores(hv, "full_message", SvREFCNT_inc(POPs));
    FREETMPS;
    LEAVE;

    return sv_bless(sv_2mortal(newRV_noinc((SV *)hv)), gv_stashpv(klass, GV_ADD));
}

__attribute__((noreturn, format (printf, 1, 2)))
static void fu_confess(const char *message, ...) {
    va_list args;
    SV *sv;
    dTHX;
    dSP;

    va_start(args, message);
    sv = vnewSVpvf(message, &args);
    va_end(args);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(sv);
    PUTBACK;
    call_pv("Carp::confess", G_DISCARD);
    /* Won't happen, but a safe fallback */
    croak("%s", SvPV_nolen(sv));
}



/* Custom string builder, should be slightly faster than using Sv* macros directly. */

typedef struct {
    SV *sv;
    SV *mortal;
    char *cur;
    char *end;
    size_t maxlen;
    int setutf8;
    char sbuf[4096];
} fustr;

static void fustr_init_(pTHX_ fustr *s, SV *mortal, size_t maxlen) {
    s->sv = NULL;
    s->cur = s->sbuf;
    s->end = s->sbuf + (maxlen > sizeof s->sbuf ? sizeof s->sbuf : maxlen);
    s->maxlen = maxlen;
    s->mortal = mortal;
    s->setutf8 = 0;
}

#define fustr_start(s) (((s)->sv ? SvPVX((s)->sv) : (s)->sbuf))
#define fustr_len(s) ((s)->cur - fustr_start(s))

static void fustr_grow(pTHX_ fustr *s, size_t add) {
    size_t off = fustr_len(s);
    size_t newlen = sizeof s->sbuf;
    char *buf;
    add += off;
    if (add > s->maxlen) croak("maximum string length exceeded");
    /* Increment to next power of two; SvGROW's default strategy is slow */
    while (newlen < add) newlen <<= 1;
    if (newlen > s->maxlen) newlen = s->maxlen;
    if (s->sv) {
        buf = SvGROW(s->sv, newlen);
    } else {
        if (s->mortal) {
            s->sv = s->mortal;
            sv_setpv_bufsize(s->sv, off, newlen);
        } else {
            s->sv = newSV(newlen);
        }
        SvPOK_only(s->sv);
        buf = SvPVX(s->sv);
        memcpy(buf, s->sbuf, off);
    }
    s->cur = buf + off;
    s->end = buf + (SvLEN(s->sv) > s->maxlen ? s->maxlen : SvLEN(s->sv));
}

static inline void fustr_reserve_(pTHX_ fustr *s, size_t add) {
    if (UNLIKELY(s->end < s->cur + add)) fustr_grow(aTHX_ s, add);
}

static inline void fustr_write_(pTHX_ fustr *s, const char *str, size_t n) {
    fustr_reserve_(aTHX_ s, n);
    memcpy(s->cur, str, n);
    s->cur += n;
}

static inline void fustr_write_ch_(pTHX_ fustr *s, char x) {
    fustr_reserve_(aTHX_ s, 1);
    *(s->cur++) = x;
}

/* Adds n uninitialized bytes to the string and returns a buffer to write the data to */
static inline char *fustr_write_buf_(pTHX_ fustr *s, size_t n) {
    fustr_reserve_(aTHX_ s, n);
    char *buf = s->cur;
    s->cur += n;
    return buf;
}

static SV *fustr_done_(pTHX_ fustr *s) {
    fustr_reserve_(aTHX_ s, 1);
    *s->cur = 0;
    if (s->sv) {
        SvCUR_set(s->sv, s->cur - SvPVX(s->sv));
        // TODO: SvPV_shrink_to_cur?
    } else {
        s->sv = newSVpvn_flags(s->sbuf, s->cur - s->sbuf, s->mortal ? SVs_TEMP : 0);
    }
    if (s->setutf8) SvUTF8_on(s->sv);
    return s->sv;
}

#define fustr_init(a,b,c) fustr_init_(aTHX_ a,b,c)
#define fustr_reserve(a,b) fustr_reserve_(aTHX_ a,b)
#define fustr_write(a,b,c) fustr_write_(aTHX_ a,b,c)
#define fustr_write_ch(a,b) fustr_write_ch_(aTHX_ a,b)
#define fustr_write_buf(a,b) fustr_write_buf_(aTHX_ a,b)
#define fustr_done(a) fustr_done_(aTHX_ a)


#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define fu_bswap(bits, out, in) ({ U##bits tmpswap; memcpy(&tmpswap, in, bits>>3); tmpswap = __builtin_bswap##bits(tmpswap); memcpy(out, &tmpswap, bits>>3); })
#else
#define fu_bswap(bits, out, in) memcpy(out, in, bits>>3)
#endif

#define fu_frombeT(T, bits, buf) ({ T tmpval; fu_bswap(bits, &tmpval, buf); tmpval; })
#define fu_frombeI(bits, buf) fu_frombeT(I##bits, bits, buf)
#define fu_frombeU(bits, buf) fu_frombeT(U##bits, bits, buf)

#define fu_tobeT(T, bits, out, in) ({ T tmpval = in; fu_bswap(bits, out, &tmpval); })
#define fu_tobeI(bits, out, in) fu_tobeT(I##bits, bits, out, in)
#define fu_tobeU(bits, out, in) fu_tobeT(U##bits, bits, out, in)

#define fustr_writebeT(T, bits, s, in) fu_tobeT(T, bits, fustr_write_buf(s, bits>>3), in)
#define fustr_writebeI(bits, s, in) fustr_writebeT(I##bits, bits, s, in)
#define fustr_writebeU(bits, s, in) fustr_writebeT(U##bits, bits, s, in)


/* Return the difference between two struct timespecs as fractional seconds. */
static double fu_timediff(const struct timespec *a, const struct timespec *b) {
    return ((double)(a->tv_sec - b->tv_sec)) + (double)(a->tv_nsec - b->tv_nsec) / 1000000000.0;
}


static int fu_hexdig(char x) {
    return x >= '0' && x <= '9' ? x-'0' : x >= 'A' && x <= 'F' ? x-'A'+10 : x >= 'a' && x <= 'f' ? x-'a'+10 : 0x10000;
}



/* -1 if arg is not a bool, 0 on false, 1 on true */
static int fu_2bool(pTHX_ SV *val) {
    if (SvIsBOOL(val)) return BOOL_INTERNALS_sv_isbool_true(val) ? 1 : 0;
    if (!SvROK(val)) return -1;
    SV *rv = SvRV(val);

    if (SvOBJECT(rv)) {
        HV *stash = SvSTASH(rv);
        /* Historical: "JSON::XS::Boolean", not used by JSON::XS since 3.0 in 2013 */
        if (stash == gv_stashpvs("JSON::PP::Boolean", 0) /* Also covers Types::Serialiser::Boolean and used by a bunch of other modules */
                || stash == gv_stashpvs("boolean", 0)
                || stash == gv_stashpvs("Mojo::JSON::_Bool", 0)
                || stash == gv_stashpvs("JSON::Tiny::_Bool", 0))
            return !!SvIV(rv);
        return -1;
    }

    /* \0 or \1 */
    if (SvTYPE(rv) < SVt_PVAV) {
        if (SvIOK(rv)) {
            IV iv = SvIV(rv);
            return iv == 0 ? 0 : iv == 1 ? 1 : -1;
        } else if (SvOK(rv)) {
            STRLEN len;
            char *str = SvPV_nomg(rv, len);
            return len != 1 ? -1 : *str == '0' ? 0 : *str == '1' ? 1 : -1;
        }
    }
    return -1;
}
