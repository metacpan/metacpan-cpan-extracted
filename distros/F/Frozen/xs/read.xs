MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzr_

UV
fzr_root(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = fz_self(aTHX_ self);
        RETVAL = (UV)fz_rd_u32(c->base + FZ_H_ROOT);
    OUTPUT:
        RETVAL

SV *
fzr_kind(self, h)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
        const char *k;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        switch (FZ_SLOT_TAG((uint32_t)h)) {
        case FZ_T_UNDEF: k = "undef";  break;
        case FZ_T_TRUE:  case FZ_T_FALSE: k = "bool"; break;
        case FZ_T_INT:   case FZ_T_UINT:  k = "int";  break;
        case FZ_T_NUM:   k = "num";    break;
        case FZ_T_STR:   k = "string"; break;
        case FZ_T_HASH:  k = "hash";   break;
        case FZ_T_ARRAY: k = "array";  break;
        default:         k = "unknown";
        }
        RETVAL = newSVpv(k, 0);
    OUTPUT:
        RETVAL

UV
fzr_count(self, h)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        RETVAL = (UV)fz_count(c->base, (uint32_t)c->len, (uint32_t)h);
    OUTPUT:
        RETVAL

void
fzr_fetch(self, h, key)
        SV *self
        UV h
        SV *key
    PREINIT:
        fz_container *c;
        STRLEN klen;
        const char *k;
        uint32_t slot = 0;
        int r;
    PPCODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        k = SvPV(key, klen);
        r = fz_probe(c->base, (uint32_t)c->len, (uint32_t)h, k,
                     (uint32_t)klen, &slot);
        if (r == FZ_ABSENT) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal(fz_slot_to_sv(aTHX_ c, slot)));

SV *
fzr_child(self, h, key)
        SV *self
        UV h
        SV *key
    PREINIT:
        fz_container *c;
        STRLEN klen;
        const char *k;
        uint32_t slot = 0;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        k = SvPV(key, klen);
        RETVAL = (fz_probe(c->base, (uint32_t)c->len, (uint32_t)h, k,
                           (uint32_t)klen, &slot) == FZ_ABSENT)
               ? &PL_sv_undef : newSVuv(slot);
    OUTPUT:
        RETVAL

SV *
fzr_probe(self, h, key)
        SV *self
        UV h
        SV *key
    PREINIT:
        fz_container *c;
        STRLEN klen;
        const char *k;
        uint32_t slot = 0;
        int r;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        k = SvPV(key, klen);
        r = fz_probe(c->base, (uint32_t)c->len, (uint32_t)h, k,
                     (uint32_t)klen, &slot);
        RETVAL = newSVpv(r == FZ_LEAF ? "leaf"
                       : r == FZ_BRANCH ? "branch" : "absent", 0);
    OUTPUT:
        RETVAL

IV
fzr_exists(self, h, key)
        SV *self
        UV h
        SV *key
    PREINIT:
        fz_container *c;
        STRLEN klen;
        const char *k;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        k = SvPV(key, klen);
        RETVAL = (fz_probe(c->base, (uint32_t)c->len, (uint32_t)h, k,
                           (uint32_t)klen, NULL) != FZ_ABSENT) ? 1 : 0;
    OUTPUT:
        RETVAL

void
fzr_at(self, h, i)
        SV *self
        UV h
        UV i
    PREINIT:
        fz_container *c;
        uint32_t slot = 0;
    PPCODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        if (fz_at(c->base, (uint32_t)c->len, (uint32_t)h, (uint32_t)i, &slot)
                == FZ_ABSENT)
            XSRETURN_EMPTY;
        XPUSHs(sv_2mortal(fz_slot_to_sv(aTHX_ c, slot)));

void
fzr_keys(self, h)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
        uint32_t n, i;
    PPCODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        if (FZ_SLOT_TAG((uint32_t)h) != FZ_T_HASH) XSRETURN_EMPTY;
        n = fz_count(c->base, (uint32_t)c->len, (uint32_t)h);
        EXTEND(SP, (SSize_t)n);
        for (i = 0; i < n; i++) {
            const char *k; uint32_t kl; int u = 0;
            if (!fz_key_at(c->base, (uint32_t)c->len, (uint32_t)h, i, &k, &kl, &u))
                continue;
            {
                SV *sv = newSVpvn(k, kl);
                if (u) SvUTF8_on(sv);
                mPUSHs(sv);
            }
        }

SV *
fzr_value(self, h)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
    CODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        RETVAL = fz_slot_to_sv(aTHX_ c, (uint32_t)h);
    OUTPUT:
        RETVAL

void
fzr_path(self, h, path, ...)
        SV *self
        UV h
        SV *path
    PREINIT:
        fz_container *c;
        STRLEN plen;
        const char *p;
        char sep = '.';
        uint32_t cur;
    PPCODE:
        c = fz_self(aTHX_ self);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        if (items > 3) {
            STRLEN sl;
            const char *s = SvPV(ST(3), sl);
            if (sl) sep = s[0];
        }
        p   = SvPV(path, plen);

        cur = fz_path_find(c->base, (uint32_t)c->len, (uint32_t)h,
                           p, (uint32_t)plen, sep);
        if (cur == FZ_NOTFOUND) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal(newSVuv(cur)));

MODULE = Frozen    PACKAGE = Frozen

MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzr_

IV
fzr_each_leaf(self, cb, ...)
        SV *self
        SV *cb
    PREINIT:
        fz_container *c;
        fz_walk_perl w;
        const char *segs[FZ_MAX_DEPTH];
        uint32_t lens[FZ_MAX_DEPTH];
        char *idxbuf;
    CODE:
        c = fz_self(aTHX_ self);
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
            croak("Frozen: each_leaf wants a code reference");
        w.cb = cb; w.self = self; w.sep = '.'; w.count = 0;
        if (items > 2) {
            STRLEN sl; const char *s = SvPV(ST(2), sl);
            if (sl) w.sep = s[0];
        }
        idxbuf = (char *)malloc((size_t)FZ_MAX_DEPTH * 12);
        if (!idxbuf) croak("Frozen: out of memory");
        {
            uint32_t budget = (uint32_t)(c->len / 4) + 16;
            fz_walk_rec(c->base, (uint32_t)c->len,
                        fz_rd_u32(c->base + FZ_H_ROOT),
                        segs, lens, idxbuf, 0, fz_walk_perl_cb, &w, &budget);
        }
        free(idxbuf);
        RETVAL = w.count;
    OUTPUT:
        RETVAL

MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzr_

void
fzr_get(self, path)
        SV *self
        SV *path
    PREINIT:
        fz_container *c;
        STRLEN plen;
        const char *p;
        uint32_t cur;
    PPCODE:
        c = fz_self(aTHX_ self);
        p = SvPV(path, plen);
        cur = fz_path_find(c->base, (uint32_t)c->len,
                           fz_rd_u32(c->base + FZ_H_ROOT),
                           p, (uint32_t)plen, '.');
        if (cur == FZ_NOTFOUND) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal(fz_slot_to_sv(aTHX_ c, cur)));
