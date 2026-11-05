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

# The n-th allocation the library makes from now on fails, as if there were
# no memory, and the count is then off again; 0 turns it off. A test walks
# n up from one until an operation succeeds, so that every allocation the
# operation makes has failed once.
void
_alloc_fail_in(n)
        IV n
    CODE:
        hamt_alloc_fail_in = n < 0 ? 0 : n;

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

# The core's persistent delete, which the methods leave to set subtraction
# (they delete in place on a copy): 1 for a key that was there, 0 for one
# that was not, -1 for no memory. The trie that comes back is let go.
IV
_del_persistent(self, key)
        SV *self
        SV *key
    PREINIT:
        hamt_map *m;
        hamt_key k;
        hamt_node *r;
        int status;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::_del_persistent", "map");
        hamt_key_from_sv(aTHX_ key, &k);
        r = hamt_map_del(HAMT_CX, m->root, k.p, (size_t)k.len, k.utf8, k.hash, &status);
        if (r) hamt_node_release(HAMT_CX, r);
        RETVAL = status;
    OUTPUT:
        RETVAL

# For the checker's own tests: a trie built by hand and broken one way, by
# number, and what hamt_map_check says of it. The numbers are the rules of
# hamt_check.h; 21 and up are a rule met at another place. 0 is the trie
# as built. It is put right again before it is freed. Nothing here is
# checked for memory: these are run with memory.
IV
_map_broken(what)
        IV what
    PREINIT:
        hamt_node *root, *child, *bottom, *chain[13];
        hamt_entry *e0, *e0b, *e1, *e3, *e32;
        size_t count = 1;
        int d;
    CODE:
        e0  = hamt_entry_new(HAMT_CX, "a", 1, 0, 0, NULL);
        e0b = hamt_entry_new(HAMT_CX, "a", 1, 0, 0, NULL);
        e1  = hamt_entry_new(HAMT_CX, "b", 1, 0, 1, NULL);
        e3  = hamt_entry_new(HAMT_CX, "c", 1, 0, 3, NULL);
        e32 = hamt_entry_new(HAMT_CX, "d", 1, 0, 32, NULL);
        if (what == 4 || what == 10) {
            /* a root over one child at position 0 */
            child = hamt_node_new(HAMT_CX, 4);
            root  = hamt_node_new(HAMT_CX, 4);
            root->nodemap = 1;
            root->slot[0] = child;
            if (what == 4) {
                child->datamap = 1;
                child->slot[0] = hamt_entry_retain(e0);
            }
            else {
                child->datamap = 3;
                child->slot[0] = hamt_entry_retain(e3);
                child->slot[1] = hamt_entry_retain(e32);
                count = 2;
            }
            RETVAL = hamt_map_check(root, count);
        }
        else if (what == 6 || what == 7 || what == 8 || what == 9 || what == 22 || what == 24 || what == 26) {
            /* a chain of nodes down to depth twelve, each over one child at position 0 */
            bottom = hamt_node_new(HAMT_CX, 4);
            if (what == 9) {
                bottom->datamap = 1;
                bottom->slot[0] = hamt_entry_retain(e0);
            }
            else {
                bottom->ncoll = what == 7 ? 1 : 2;
                bottom->slot[0] = hamt_entry_retain(e0);
                if (what != 7) bottom->slot[1] = hamt_entry_retain(what == 26 ? e3 : e0b);
                count = bottom->ncoll;
            }
            chain[12] = bottom;
            for (d = 11; d >= 0; d--) {
                chain[d] = hamt_node_new(HAMT_CX, 4);
                chain[d]->nodemap = 1;
                chain[d]->slot[0] = chain[d + 1];
            }
            root = chain[0];
            if (what == 6)  bottom->datamap = 1;
            if (what == 22) e0b->refcnt = 0;
            if (what == 24) bottom->slot[1] = NULL;
            RETVAL = hamt_map_check(root, count);
            if (what == 6)  bottom->datamap = 0;
            if (what == 22) e0b->refcnt = 2;
            if (what == 24) bottom->slot[1] = e0b;
        }
        else {
            /* a root holding one entry at position 0 */
            root = hamt_node_new(HAMT_CX, 4);
            root->datamap = 1;
            root->slot[0] = hamt_entry_retain(e0);
            switch (what) {
            case 1:  root->refcnt = 0;  RETVAL = hamt_map_check(root, 1); root->refcnt = 1;  break;
            case 2:  root->nodemap = 1; RETVAL = hamt_map_check(root, 1); root->nodemap = 0; break;
            case 3:  root->datamap = 0; RETVAL = hamt_map_check(root, 0); root->datamap = 1; break;
            case 5:  root->ncoll = 2;   RETVAL = hamt_map_check(root, 2); root->ncoll = 0;   break;
            case 12: RETVAL = hamt_map_check(root, 2); break;
            case 13: root->slot[0] = e1;   RETVAL = hamt_map_check(root, 1); root->slot[0] = e0; break;
            case 21: e0->refcnt = 0;       RETVAL = hamt_map_check(root, 1); e0->refcnt = 2;     break;
            case 23: root->slot[0] = NULL; RETVAL = hamt_map_check(root, 1); root->slot[0] = e0; break;
            case 25:
                root->datamap = 0; root->nodemap = 1; root->slot[0] = NULL;
                RETVAL = hamt_map_check(root, 1);
                root->nodemap = 0; root->datamap = 1; root->slot[0] = e0;
                break;
            default: RETVAL = hamt_map_check(root, 1); break;
            }
        }
        hamt_node_release(HAMT_CX, root);
        hamt_entry_release(HAMT_CX, e0);
        hamt_entry_release(HAMT_CX, e0b);
        hamt_entry_release(HAMT_CX, e1);
        hamt_entry_release(HAMT_CX, e3);
        hamt_entry_release(HAMT_CX, e32);
    OUTPUT:
        RETVAL

# The same for a vector and hamt_vec_check, by a number of this file's own:
# 1 to 9 break the tail or the root, 10 and up the tree. 19 asks the checker
# to allow no spare children at all, and 20 gives a table that lies. 0 is
# the vector as built.
IV
_vec_broken(what)
        IV what
    PREINIT:
        hamt_vec v;
        hamt_vnode *leaf, *leaf2, *node, *kids[2], *keep;
        void *vals[32];
        static size_t dummy[32];
        SV *one;
        int i;
    CODE:
        one = sv_2mortal(newSViv(1));
        for (i = 0; i < 32; i++) vals[i] = one;
        hamt_vec_init(&v);
        v.tail  = hamt_vnode_leaf(HAMT_CX, vals, 1);
        v.count = 1;
        if (what < 10) {
            switch (what) {
            case 1: keep = v.tail; v.tail = NULL; RETVAL = hamt_vec_check(&v); v.tail = keep;      break;
            case 2: v.tail->leaf = 0;             RETVAL = hamt_vec_check(&v); v.tail->leaf = 1;   break;
            case 3: v.tail->len = 0;              RETVAL = hamt_vec_check(&v); v.tail->len = 1;    break;
            case 4: v.tail->len = 2;              RETVAL = hamt_vec_check(&v); v.tail->len = 1;    break;
            case 5: v.tail->sizes = dummy;        RETVAL = hamt_vec_check(&v); v.tail->sizes = NULL; break;
            case 6: v.tail->refcnt = 0;           RETVAL = hamt_vec_check(&v); v.tail->refcnt = 1; break;
            case 7: v.tail->slot[0] = NULL;       RETVAL = hamt_vec_check(&v); v.tail->slot[0] = one; break;
            case 8: v.root = v.tail;              RETVAL = hamt_vec_check(&v); v.root = NULL;      break;
            case 9: v.count = 2;                  RETVAL = hamt_vec_check(&v); v.count = 1;        break;
            default: RETVAL = hamt_vec_check(&v); break;
            }
        }
        else if (what < 18) {
            /* a root over one full leaf */
            leaf = hamt_vnode_leaf(HAMT_CX, vals, 32);
            node = hamt_vnode_make(HAMT_CX, &leaf, 1, HAMT_VEC_BITS);
            v.root  = node;
            v.count = 33;
            switch (what) {
            case 10: v.shift = 7;            RETVAL = hamt_vec_check(&v); v.shift = HAMT_VEC_BITS; break;
            case 11: v.shift = 10;           RETVAL = hamt_vec_check(&v); v.shift = HAMT_VEC_BITS; break;
            case 12: node->slot[0] = NULL;   RETVAL = hamt_vec_check(&v); node->slot[0] = leaf;    break;
            case 13: node->refcnt = 0;       RETVAL = hamt_vec_check(&v); node->refcnt = 1;        break;
            case 14: node->len = 0;          RETVAL = hamt_vec_check(&v); node->len = 1;           break;
            case 15: node->leaf = 1;         RETVAL = hamt_vec_check(&v); node->leaf = 0;          break;
            case 16: leaf->sizes = dummy;    RETVAL = hamt_vec_check(&v); leaf->sizes = NULL;      break;
            default: leaf->slot[0] = NULL;   RETVAL = hamt_vec_check(&v); leaf->slot[0] = one;     break;
            }
        }
        else {
            /* a root over two leaves: full ones, or ones holding one value each */
            leaf  = hamt_vnode_leaf(HAMT_CX, vals, what == 18 ? 32 : 1);
            leaf2 = hamt_vnode_leaf(HAMT_CX, vals, what == 18 ? 32 : 1);
            kids[0] = leaf;
            kids[1] = leaf2;
            node = hamt_vnode_make(HAMT_CX, kids, 2, HAMT_VEC_BITS);
            v.root  = node;
            v.count = (size_t)leaf->len + leaf2->len + 1;
            if (what == 18)      { leaf->len = 31;    RETVAL = hamt_vec_check(&v); leaf->len = 32; }
            else if (what == 20) { node->sizes[0] = 5; RETVAL = hamt_vec_check(&v); node->sizes[0] = 1; }
            else RETVAL = hamt_vec_check_spare(&v, 0);
        }
        if (v.root) hamt_vnode_release(HAMT_CX, v.root);
        hamt_vnode_release(HAMT_CX, v.tail);
    OUTPUT:
        RETVAL

# The core's persistent put, which the methods leave to the harness (they
# put in place on a copy): 1 for a key that was new, 0 for one replaced.
# The trie that comes back is let go.
IV
_put_persistent(self, key, value)
        SV *self
        SV *key
        SV *value
    PREINIT:
        hamt_map *m;
        hamt_key k;
        hamt_entry *e;
        hamt_node *r;
        int added;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::_put_persistent", "map");
        hamt_key_from_sv(aTHX_ key, &k);
        e = hamt_entry_new(HAMT_CX, k.p, (size_t)k.len, k.utf8, k.hash, (void *)value);
        if (!e) croak("HAMT::_put_persistent: out of memory");
        r = hamt_map_put(HAMT_CX, m->root, e, &added);
        hamt_entry_release(HAMT_CX, e);
        if (!r) croak("HAMT::_put_persistent: out of memory");
        hamt_node_release(HAMT_CX, r);
        RETVAL = added;
    OUTPUT:
        RETVAL

# How many levels of nodes a vector has over its leaves.
IV
_vec_height(self)
        SV *self
    PREINIT:
        hamt_vec *v;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::_vec_height");
        RETVAL = (IV)hamt_vec_height(v);
    OUTPUT:
        RETVAL
