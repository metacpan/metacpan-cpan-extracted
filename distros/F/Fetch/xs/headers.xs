MODULE = Fetch		PACKAGE = Fetch::Headers

# Ordered, case-insensitive, multi-valued HTTP headers over a blessed
# [k, v, k, v, ...] arrayref (see include/fetch/ft_headers.h).

# new(%pairs) | new(\@pairs) | new(\%hash) | new($headers): a single arg is
# taken as pairs/arrayref/hashref/Fetch::Headers; any other list is the flat
# name => value list verbatim.
SV *
new(class, ...)
    SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        AV *av = newAV();
        if (items == 2) {
            ft_hdr_pairs_into(aTHX_ av, ST(1));
        } else {
            int i;
            for (i = 1; i < items; i++) av_push(av, newSVsv(ST(i)));
        }
        RETVAL = sv_bless(newRV_noinc((SV *)av), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# first value for $name, or undef
SV *
get(self, name)
    SV *self
    SV *name
    CODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        AV *av = (AV *)SvRV(self);
        SSize_t idx = ft_hdr_find(aTHX_ av, ns, nl);
        if (idx < 0) {
            RETVAL = newSV(0);
        } else {
            SV **v = av_fetch(av, idx + 1, 0);
            RETVAL = (v && *v) ? newSVsv(*v) : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# every value for $name, in order
void
get_all(self, name)
    SV *self
    SV *name
    PPCODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        AV *av = (AV *)SvRV(self);
        SSize_t n = av_len(av) + 1, i;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(av, i, 0);
            if (k && *k) {
                STRLEN kl;
                const char *ks = SvPV_const(*k, kl);
                if (ft_ci_eq(ks, kl, ns, nl)) {
                    SV **v = av_fetch(av, i + 1, 0);
                    mXPUSHs((v && *v) ? newSVsv(*v) : newSV(0));
                }
            }
        }
    }

# is $name present?
int
exists(self, name)
    SV *self
    SV *name
    CODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        RETVAL = ft_hdr_find(aTHX_ (AV *)SvRV(self), ns, nl) >= 0 ? 1 : 0;
    }
    OUTPUT:
        RETVAL

# append value(s) under $name, keeping any existing
SV *
add(self, name, ...)
    SV *self
    SV *name
    CODE:
    {
        AV *av = (AV *)SvRV(self);
        int i;
        for (i = 2; i < items; i++) {
            av_push(av, newSVsv(name));
            av_push(av, newSVsv(ST(i)));
        }
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# drop every value for $name
SV *
remove(self, name)
    SV *self
    SV *name
    CODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        AV *av = (AV *)SvRV(self);
        AV *keep = newAV();
        SSize_t n = av_len(av) + 1, i;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(av, i, 0);
            STRLEN kl;
            const char *ks = (k && *k) ? SvPV_const(*k, kl) : (kl = 0, "");
            if (!(k && *k) || !ft_ci_eq(ks, kl, ns, nl)) {
                SV **v = av_fetch(av, i + 1, 0);
                av_push(keep, (k && *k) ? newSVsv(*k) : newSV(0));
                av_push(keep, (v && *v) ? newSVsv(*v) : newSV(0));
            }
        }
        av_clear(av);
        n = av_len(keep) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(keep, i, 0);
            av_push(av, (e && *e) ? SvREFCNT_inc(*e) : newSV(0));
        }
        SvREFCNT_dec((SV *)keep);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# replace all values for $name with the given value(s)
SV *
set(self, name, ...)
    SV *self
    SV *name
    CODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        AV *av = (AV *)SvRV(self);
        AV *keep = newAV();
        SSize_t n = av_len(av) + 1, i;
        int j;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(av, i, 0);
            STRLEN kl;
            const char *ks = (k && *k) ? SvPV_const(*k, kl) : (kl = 0, "");
            if (!(k && *k) || !ft_ci_eq(ks, kl, ns, nl)) {
                SV **v = av_fetch(av, i + 1, 0);
                av_push(keep, (k && *k) ? newSVsv(*k) : newSV(0));
                av_push(keep, (v && *v) ? newSVsv(*v) : newSV(0));
            }
        }
        av_clear(av);
        n = av_len(keep) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(keep, i, 0);
            av_push(av, (e && *e) ? SvREFCNT_inc(*e) : newSV(0));
        }
        SvREFCNT_dec((SV *)keep);
        for (j = 2; j < items; j++) {
            av_push(av, newSVsv(name));
            av_push(av, newSVsv(ST(j)));
        }
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# distinct field names, in order of first appearance
void
names(self)
    SV *self
    PPCODE:
    {
        AV *av = (AV *)SvRV(self);
        AV *seen = newAV();
        SSize_t n = av_len(av) + 1, i;
        sv_2mortal((SV *)seen);
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(av, i, 0);
            if (k && *k) {
                STRLEN kl;
                const char *ks = SvPV_const(*k, kl);
                SSize_t m = av_len(seen) + 1, j;
                int dup = 0;
                for (j = 0; j < m; j++) {
                    SV **s = av_fetch(seen, j, 0);
                    STRLEN sl;
                    const char *ss = (s && *s) ? SvPV_const(*s, sl) : (sl = 0, "");
                    if (ft_ci_eq(ss, sl, ks, kl)) { dup = 1; break; }
                }
                if (!dup) {
                    av_push(seen, newSVsv(*k));
                    mXPUSHs(newSVsv(*k));
                }
            }
        }
    }

# the flat name => value list
void
pairs(self)
    SV *self
    PPCODE:
    {
        AV *av = (AV *)SvRV(self);
        SSize_t n = av_len(av) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            mXPUSHs((e && *e) ? newSVsv(*e) : newSV(0));
        }
    }

# a shallow copy
SV *
clone(self)
    SV *self
    CODE:
    {
        AV *av = (AV *)SvRV(self);
        AV *cp = newAV();
        SSize_t n = av_len(av) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            av_push(cp, (e && *e) ? newSVsv(*e) : newSV(0));
        }
        RETVAL = sv_bless(newRV_noinc((SV *)cp),
                          SvSTASH(SvRV(self)));
        SvREFCNT_inc(SvSTASH(SvRV(self)));
    }
    OUTPUT:
        RETVAL

# overlay $other: each field name it carries replaces all of this object's
# values for that name; names present only here are kept, in place.
SV *
merge(self, other)
    SV *self
    SV *other
    CODE:
        ft_hdr_merge(aTHX_ (AV *)SvRV(self), other);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL
