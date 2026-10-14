# Doors for the tests and for nobody else. Each name starts with an
# underscore, none is documented, and any may change in any release.

MODULE = HAMT    PACKAGE = HAMT

# Pin the seed, so a test can ask for the same layout twice.
void
_seed(n)
        UV n
    CODE:
        hamt_seed = (uint64_t)n;

# Keep only the low `bits` bits of every hash from here on: 0 makes every key
# collide, 5 fills one level and then collides. 64 puts the whole hash back.
# A container built under one setting must not be read under another.
void
_hash_bits(bits)
        UV bits
    CODE:
        hamt_hash_set_bits(bits > 64 ? 64 : (unsigned)bits);

# The hash of a key that has already been through the key rule, as sixteen
# hex digits: a 64-bit number does not fit an IV on every perl.
SV *
_hash_of(bytes, utf8 = 0)
        SV *bytes
        int utf8
    PREINIT:
        STRLEN len;
        const char *p;
        uint64_t h;
    CODE:
        p = SvPVbyte(bytes, len);
        h = hamt_hash(p, (size_t)len, utf8);
        RETVAL = newSVpvf("%08lx%08lx",
                          (unsigned long)(h >> 32),
                          (unsigned long)(h & 0xffffffffUL));
    OUTPUT:
        RETVAL

# An entry made and released in C, reporting what it held on the way: the
# key's length, its flag, and whether the key compares equal to itself and
# unequal to the same bytes under the other flag. The value's reference count
# is the caller's to check before and after.
void
_entry_probe(bytes, utf8, value)
        SV *bytes
        int utf8
        SV *value
    PREINIT:
        STRLEN len;
        const char *p;
        uint64_t h;
        hamt_entry *e;
        IV held, self_eq, flag_eq;
    PPCODE:
        p = SvPVbyte(bytes, len);
        h = hamt_hash(p, (size_t)len, utf8);
        e = hamt_entry_new(HAMT_CX, p, (size_t)len, utf8, h, (void *)value);
        if (!e) croak("HAMT::_entry_probe: out of memory");
        hamt_entry_retain(e);
        hamt_entry_release(HAMT_CX, e);
        held    = (IV)SvREFCNT(value);
        self_eq = hamt_entry_key_eq(e, p, (size_t)len, utf8, h);
        flag_eq = hamt_entry_key_eq(e, p, (size_t)len, !utf8,
                                    hamt_hash(p, (size_t)len, !utf8));
        hamt_entry_release(HAMT_CX, e);
        EXTEND(SP, 3);
        mPUSHi(held);
        mPUSHi(self_eq);
        mPUSHi(flag_eq);

# An object blessed into `klass` that carries ext magic, but not this
# library's: what a handle from some other extension looks like. Every
# method has to refuse it, since its magic points at somebody else's struct.
void
_foreign_handle(klass)
        SV *klass
    PREINIT:
        static MGVTBL other = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
        static char payload[64];
        SV *inner, *rv;
    CODE:
        inner = newSV(0);
        sv_magicext(inner, NULL, PERL_MAGIC_ext, &other, payload, 0);
        rv = sv_2mortal(newRV_noinc(inner));
        sv_bless(rv, gv_stashsv(klass, GV_ADD));
        ST(0) = rv;
        XSRETURN(1);

# How many temporaries perl is holding right now. A walk that calls a sub
# for every entry must not let this grow with the walk.
void
_tmps_ix()
    CODE:
        ST(0) = sv_2mortal(newSViv((IV)PL_tmps_ix));
        XSRETURN(1);

# How many blocks the library holds: every node, every entry, every handle's
# struct. Back to where it started means nothing was leaked.
void
_live_blocks()
    CODE:
        ST(0) = sv_2mortal(newSViv((IV)hamt_live_blocks));
        XSRETURN(1);

# How many freed blocks the allocator is holding for reuse. -1 in a build
# that has no pool, and -2 in one that has but where it is not open, which
# is a fault and must not read as the first.
void
_pool_held()
    CODE:
#ifndef HAMT_NO_POOL
        ST(0) = sv_2mortal(newSViv(hamt_pool_one.open
                                   ? (IV)hamt_pool_held(&hamt_pool_one) : -2));
#else
        ST(0) = sv_2mortal(newSViv(-1));
#endif
        XSRETURN(1);
