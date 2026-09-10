MODULE = Frozen    PACKAGE = Frozen

SV *
open(class, path, ...)
        SV *class
        SV *path
    PREINIT:
        fz_container *c;
        int rc, want_copy = 0, want_verify = 0;
        I32 i;
        SV *obj;
    CODE:
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "copy")) want_copy = SvTRUE(ST(i + 1));
        }
        c = (fz_container *)malloc(sizeof(fz_container));
        if (!c) croak("Frozen: out of memory");
        rc = fz_container_open(aTHX_ c, SvPV_nolen(path), want_copy);
        if (rc == FZ_OPEN_OK) rc = fz_check_header(c->base, c->len);
        if (rc != FZ_OPEN_OK) {
            fz_container_release(c);
            free(c);

            if (rc == FZ_OPEN_ENOENT) XSRETURN_UNDEF;
            croak("Frozen: %s %s", SvPV_nolen(path), fz_open_error(rc));
        }
        obj = newSV(0);
        sv_setref_pv(obj, SvPV_nolen(class), (void *)c);
        if (want_verify) {
            uint32_t want = fz_rd_u32(c->base + FZ_H_CHECKSUM);
            if (want != fz_checksum(c->base, (uint32_t)c->len)) {
                SvREFCNT_dec(obj);
                croak("Frozen: %s fails its checksum", SvPV_nolen(path));
            }
        }
        RETVAL = obj;
    OUTPUT:
        RETVAL

SV *
attach(class, bytes, ...)
        SV *class
        SV *bytes
    PREINIT:
        fz_container *c;
        int rc;
        I32 i;
        SV *obj;
    CODE:
        c = (fz_container *)malloc(sizeof(fz_container));
        if (!c) croak("Frozen: out of memory");
        rc = fz_container_attach(aTHX_ c, bytes);
        if (rc == FZ_OPEN_OK) rc = fz_check_header(c->base, c->len);
        if (rc != FZ_OPEN_OK) {
            if (c->holder) SvREFCNT_dec(c->holder);
            fz_container_release(c);
            free(c);
            croak("Frozen: the scalar %s", fz_open_error(rc));
        }
        obj = newSV(0);
        sv_setref_pv(obj, SvPV_nolen(class), (void *)c);
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzc_

void
fzc_close(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (c && c->base) {
            if (c->holder) { SvREFCNT_dec(c->holder); c->holder = NULL; }
            fz_container_release(c);
        }

UV
fzc_size(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) croak("Frozen: this container is closed");
        RETVAL = (UV)c->len;
    OUTPUT:
        RETVAL

IV
fzc_is_mapped(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) croak("Frozen: this container is closed");
        RETVAL = (c->src == FZ_SRC_MMAP) ? 1 : 0;
    OUTPUT:
        RETVAL

IV
fzc_is_open(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        RETVAL = (c && c->base) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
fzc_find(self, key)
        SV *self
        SV *key
    PREINIT:
        fz_container *c;
        STRLEN klen;
        const char *k;
        uint32_t root, slot;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) croak("Frozen: this container is closed");
        k = SvPV(key, klen);
        root = fz_rd_u32(c->base + FZ_H_ROOT);
        if (FZ_SLOT_TAG(root) != FZ_T_HASH) croak("Frozen: the root is not a hash");
        slot = fz_hash_find(c->base, (uint32_t)c->len, FZ_SLOT_OFF(root),
                            k, (uint32_t)klen);
        RETVAL = (slot == FZ_NOTFOUND) ? &PL_sv_undef : newSVuv(slot);
    OUTPUT:
        RETVAL

SV *
fzc_string_at(self, slot)
        SV *self
        UV slot
    PREINIT:
        fz_container *c;
        uint32_t len = 0;
        const char *p;
        int utf8 = 0;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) croak("Frozen: this container is closed");
        if (FZ_SLOT_TAG((uint32_t)slot) != FZ_T_STR)
            croak("Frozen: that slot is not a string");

        p = fz_str_at(c->base, (uint32_t)c->len, (uint32_t)slot, &len, &utf8);
        if (!p) croak("Frozen: that string runs past the block");
        RETVAL = newSVpvn(p, len);
        if (utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

MODULE = Frozen    PACKAGE = Frozen

void
DESTROY(self)
        SV *self
    PREINIT:
        fz_container *c;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (c) {
            if (c->holder) SvREFCNT_dec(c->holder);
            fz_container_release(c);
            free(c);
            sv_setiv(SvRV(self), 0);
        }

MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzc_

IV
fzc_verify(self)
        SV *self
    PREINIT:
        fz_container *c;
        uint32_t want, got;
        long n;
    CODE:
        c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) croak("Frozen: this container is closed");
        want = fz_rd_u32(c->base + FZ_H_CHECKSUM);
        got  = fz_checksum(c->base, (uint32_t)c->len);
        if (want != got)
            croak("Frozen: the checksum disagrees (header says %08lx, the "
                  "bytes give %08lx) - the block has been altered or was "
                  "written by a different build",
                  (unsigned long)want, (unsigned long)got);
        n = fz_walk_check(c->base, (uint32_t)c->len,
                          fz_rd_u32(c->base + FZ_H_ROOT), 0);
        if (n < 0) {
            const char *why =
                n == FZ_E_BOUNDS ? "an offset outside the block"
              : n == FZ_E_ALIGN  ? "a node that is not 8-aligned"
              : n == FZ_E_TAG    ? "a tag that is not a live kind"
              : n == FZ_E_COUNT  ? "a count larger than the bytes that remain"
              : n == FZ_E_DEPTH  ? "a structure deeper than FZ_MAX_DEPTH"
              :                    "something unaccounted for";
            croak("Frozen: the block holds %s", why);
        }
        RETVAL = 1;
    OUTPUT:
        RETVAL
