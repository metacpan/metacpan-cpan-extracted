MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzt_

SV *
fzt_tied(self, h = 0)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
    CODE:
        c = fz_self(aTHX_ self);
        if (!h) h = (UV)fz_rd_u32(c->base + FZ_H_ROOT);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        RETVAL = fz_tie_for(aTHX_ self, (uint32_t)h);
    OUTPUT:
        RETVAL

SV *
fzt_inflate(self, h = 0)
        SV *self
        UV h
    PREINIT:
        fz_container *c;
    CODE:
        c = fz_self(aTHX_ self);
        if (!h) h = (UV)fz_rd_u32(c->base + FZ_H_ROOT);
        fz_check_handle(aTHX_ c, (uint32_t)h);
        RETVAL = fz_slot_to_sv(aTHX_ c, (uint32_t)h);
    OUTPUT:
        RETVAL

MODULE = Frozen    PACKAGE = Frozen::Tie::Hash

SV *
FETCH(self, key)
        SV *self
        SV *key
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h, slot = 0;
        STRLEN klen;
        const char *k;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        k = SvPV(key, klen);
        switch (fz_probe(c->base, (uint32_t)c->len, h, k, (uint32_t)klen, &slot)) {
        case FZ_ABSENT:
            RETVAL = &PL_sv_undef;
            break;
        case FZ_BRANCH:
            RETVAL = fz_tie_for(aTHX_ csv, slot);
            break;
        default:
            RETVAL = fz_slot_to_sv(aTHX_ c, slot);
        }
    OUTPUT:
        RETVAL

IV
EXISTS(self, key)
        SV *self
        SV *key
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
        STRLEN klen;
        const char *k;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        k = SvPV(key, klen);
        RETVAL = fz_probe(c->base, (uint32_t)c->len, h, k, (uint32_t)klen, NULL)
                 != FZ_ABSENT;
    OUTPUT:
        RETVAL

SV *
FIRSTKEY(self)
        SV *self
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
        const char *k; uint32_t kl; int u = 0;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        av_store((AV *)SvRV(self), 2, newSViv(0));
        if (!fz_key_at(c->base, (uint32_t)c->len, h, 0, &k, &kl, &u))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(k, kl);
        if (u) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

SV *
NEXTKEY(self, last)
        SV *self
        SV *last
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
        const char *k; uint32_t kl; int u = 0;
        IV i;
        SV **slot;
    CODE:
        PERL_UNUSED_VAR(last);
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        slot = av_fetch((AV *)SvRV(self), 2, 0);
        i = (slot && *slot) ? SvIV(*slot) + 1 : 1;
        av_store((AV *)SvRV(self), 2, newSViv(i));
        if (!fz_key_at(c->base, (uint32_t)c->len, h, (uint32_t)i, &k, &kl, &u))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(k, kl);
        if (u) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

IV
SCALAR(self)
        SV *self
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        RETVAL = (IV)fz_count(c->base, (uint32_t)c->len, h);
    OUTPUT:
        RETVAL

void
STORE(self, key, value)
        SV *self
        SV *key
        SV *value
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(key); PERL_UNUSED_VAR(value);
        croak("Frozen: this hash is read-only. A write would either be lost "
              "or become one worker's private copy of a block every worker "
              "is sharing, which is the thing Frozen exists to prevent. "
              "Rebuild the block instead.");

void
DELETE(self, key)
        SV *self
        SV *key
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(key);
        croak("Frozen: this hash is read-only. Deleting would unshare the "
              "block for this worker alone. Rebuild the block instead.");

void
CLEAR(self)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        croak("Frozen: this hash is read-only. Clearing would unshare the "
              "block for this worker alone. Rebuild the block instead.");

MODULE = Frozen    PACKAGE = Frozen::Tie::Array

SV *
FETCH(self, i)
        SV *self
        UV i
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h, slot = 0;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        if (fz_at(c->base, (uint32_t)c->len, h, (uint32_t)i, &slot) == FZ_ABSENT)
            RETVAL = &PL_sv_undef;
        else if (fz_is_branch(slot))
            RETVAL = fz_tie_for(aTHX_ csv, slot);
        else
            RETVAL = fz_slot_to_sv(aTHX_ c, slot);
    OUTPUT:
        RETVAL

IV
FETCHSIZE(self)
        SV *self
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        RETVAL = (IV)fz_count(c->base, (uint32_t)c->len, h);
    OUTPUT:
        RETVAL

IV
EXISTS(self, i)
        SV *self
        UV i
    PREINIT:
        fz_container *c;
        SV *csv;
        uint32_t h;
    CODE:
        fz_tie_parts(aTHX_ self, &csv, &c, &h);
        RETVAL = (uint32_t)i < fz_count(c->base, (uint32_t)c->len, h);
    OUTPUT:
        RETVAL

void
STORE(self, i, value)
        SV *self
        UV i
        SV *value
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(i); PERL_UNUSED_VAR(value);
        croak("Frozen: this array is read-only. Rebuild the block instead.");

void
STORESIZE(self, n)
        SV *self
        UV n
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(n);
        croak("Frozen: this array is read-only. Rebuild the block instead.");

void
CLEAR(self)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        croak("Frozen: this array is read-only. Rebuild the block instead.");

void
PUSH(self, ...)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        croak("Frozen: this array is read-only. Rebuild the block instead.");

void
DELETE(self, i)
        SV *self
        UV i
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(i);
        croak("Frozen: this array is read-only. Rebuild the block instead.");

MODULE = Frozen    PACKAGE = Frozen
