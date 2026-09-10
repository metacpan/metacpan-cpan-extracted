MODULE = Frozen    PACKAGE = Frozen

SV *
freeze(class, data, ...)
        SV *class
        SV *data
    PREINIT:
        int lossy = 0;
        const char *flat = NULL;
        I32 i;
    CODE:
        PERL_UNUSED_VAR(class);
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "lossy_nv")) lossy = SvTRUE(ST(i + 1));
            else if (strEQ(o, "flat"))     flat  = SvOK(ST(i + 1))
                                                 ? SvPV_nolen(ST(i + 1)) : NULL;
        }
        RETVAL = SvREFCNT_inc(fz_freeze_sv(aTHX_ data, lossy, flat));
    OUTPUT:
        RETVAL

void
freeze_to(class, path, data, ...)
        SV *class
        SV *path
        SV *data
    PREINIT:
        int lossy = 0;
        const char *flat = NULL;
        I32 i;
        SV *blk;
        SV *tmp;
        PerlIO *fh;
        STRLEN len;
        const char *bytes;
        const char *p;
        const char *t;
    CODE:
        PERL_UNUSED_VAR(class);
        for (i = 3; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "lossy_nv")) lossy = SvTRUE(ST(i + 1));
            else if (strEQ(o, "flat"))     flat  = SvOK(ST(i + 1))
                                                 ? SvPV_nolen(ST(i + 1)) : NULL;
        }
        blk = fz_freeze_sv(aTHX_ data, lossy, flat);
        bytes = SvPV(blk, len);
        p = SvPV_nolen(path);
        tmp = sv_2mortal(newSVpvf("%s.tmp%ld", p, (long)PerlProc_getpid()));
        t = SvPV_nolen(tmp);
        fh = PerlIO_open(t, "wb");
        if (!fh) croak("Frozen: cannot open %s: %s", t, Strerror(errno));
        if ((STRLEN)PerlIO_write(fh, bytes, len) != len) {
            PerlIO_close(fh);
            (void)PerlLIO_unlink(t);
            croak("Frozen: cannot write %s: %s", t, Strerror(errno));
        }
        if (PerlIO_close(fh) != 0) {
            (void)PerlLIO_unlink(t);
            croak("Frozen: cannot close %s: %s", t, Strerror(errno));
        }
        if (PerlLIO_rename(t, p) != 0) {
            (void)PerlLIO_unlink(t);
            croak("Frozen: cannot rename %s to %s: %s", t, p, Strerror(errno));
        }

void
_header(class, blk)
        SV *class
        SV *blk
    PREINIT:
        STRLEN len;
        const unsigned char *h;
    PPCODE:
        PERL_UNUSED_VAR(class);
        h = (const unsigned char *)SvPV(blk, len);
        if (len < FZ_HEADER_SIZE) croak("Frozen: shorter than a header");
        EXTEND(SP, 11);
        mPUSHs(newSVpvn((const char *)h, 4));
        mPUSHu(h[FZ_H_VERSION] | (h[FZ_H_VERSION + 1] << 8));
        mPUSHu(h[FZ_H_HEADER_SIZE] | (h[FZ_H_HEADER_SIZE + 1] << 8));
        mPUSHu(fz_rd_u32(h + FZ_H_FLAGS));
        mPUSHu(fz_rd_u32(h + FZ_H_ENDIAN));
        mPUSHu(h[FZ_H_OFFWIDTH]);
        mPUSHu(fz_rd_u32(h + FZ_H_TOTAL));
        mPUSHu(fz_rd_u32(h + FZ_H_ROOT));
        mPUSHu(fz_rd_u32(h + FZ_H_SEED));
        mPUSHu(fz_rd_u32(h + FZ_H_NODES));
        mPUSHu(fz_rd_u32(h + FZ_H_STRINGS));

IV
_walk_ok(class, blk)
        SV *class
        SV *blk
    PREINIT:
        STRLEN len;
        const unsigned char *b;
        IV count = 0;
    CODE:
        PERL_UNUSED_VAR(class);
        b = (const unsigned char *)SvPV(blk, len);
        if (len < FZ_HEADER_SIZE) croak("Frozen: shorter than a header");
        if (fz_rd_u32(b + FZ_H_TOTAL) != (uint32_t)len)
            croak("Frozen: total_size %u disagrees with the length %u",
                  (unsigned)fz_rd_u32(b + FZ_H_TOTAL), (unsigned)len);
        count = (IV)fz_walk_check(b, (uint32_t)len,
                                  fz_rd_u32(b + FZ_H_ROOT), 0);
        if (count < 0) {
            const char *why =
                count == FZ_E_BOUNDS ? "an offset outside the block"
              : count == FZ_E_ALIGN  ? "a node that is not 8-aligned"
              : count == FZ_E_TAG    ? "a tag that is not a live kind"
              : count == FZ_E_COUNT  ? "a count larger than the bytes that remain"
              : count == FZ_E_DEPTH  ? "a structure deeper than FZ_MAX_DEPTH"
              :                        "something unaccounted for";
            croak("Frozen: the block holds %s", why);
        }
        RETVAL = count;
    OUTPUT:
        RETVAL

IV
_string_count(class, blk)
        SV *class
        SV *blk
    PREINIT:
        STRLEN len;
        const unsigned char *b;
    CODE:
        PERL_UNUSED_VAR(class);
        b = (const unsigned char *)SvPV(blk, len);
        RETVAL = (IV)fz_rd_u32(b + FZ_H_STRINGS);
    OUTPUT:
        RETVAL

SV *
_find(class, blk, key)
        SV *class
        SV *blk
        SV *key
    PREINIT:
        STRLEN len, klen;
        const unsigned char *b;
        const char *k;
        uint32_t root, slot;
    CODE:
        PERL_UNUSED_VAR(class);
        b = (const unsigned char *)SvPV(blk, len);
        k = SvPV(key, klen);
        if (len < FZ_HEADER_SIZE) croak("Frozen: shorter than a header");
        root = fz_rd_u32(b + FZ_H_ROOT);
        if (FZ_SLOT_TAG(root) != FZ_T_HASH) croak("Frozen: the root is not a hash");
        slot = fz_hash_find(b, (uint32_t)len, FZ_SLOT_OFF(root), k, (uint32_t)klen);
        RETVAL = (slot == FZ_NOTFOUND) ? &PL_sv_undef : newSVuv(slot);
    OUTPUT:
        RETVAL

IV
_has_mphf(class, blk)
        SV *class
        SV *blk
    PREINIT:
        STRLEN len;
        const unsigned char *b;
        uint32_t root;
    CODE:
        PERL_UNUSED_VAR(class);
        b = (const unsigned char *)SvPV(blk, len);
        root = fz_rd_u32(b + FZ_H_ROOT);
        if (FZ_SLOT_TAG(root) != FZ_T_HASH) croak("Frozen: the root is not a hash");
        RETVAL = fz_rd_u32(b + FZ_SLOT_OFF(root) + 4) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_at(class, blk, slot)
        SV *class
        SV *blk
        UV slot
    PREINIT:
        STRLEN len;
        const unsigned char *b;
        uint32_t off;
    CODE:
        PERL_UNUSED_VAR(class);
        b = (const unsigned char *)SvPV(blk, len);
        off = FZ_SLOT_OFF((uint32_t)slot);
        RETVAL = (off < len) ? newSVuv(FZ_SLOT_TAG((uint32_t)slot))
                             : &PL_sv_undef;
    OUTPUT:
        RETVAL
