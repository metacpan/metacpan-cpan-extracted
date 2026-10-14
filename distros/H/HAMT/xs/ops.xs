# The function forms of the reads, each in the class it reads. Called through
# a reference or with an ampersand they run as written here; a plain call is
# compiled into an op where perl allows it. The prototypes are what make the
# two agree.
#
# use HAMT::Map qw(hamt_map_get ...) or qw(:all): into the package the `use`
# was compiled in, which is the current statement's.

MODULE = HAMT    PACKAGE = HAMT::Map

void
hamt_map_get(self, key)
        SV *self
        SV *key
    PROTOTYPE: $$
    CODE:
        ST(0) = hamt_fn_map_get(aTHX_ self, key);
        XSRETURN(1);

void
hamt_map_exists(self, key)
        SV *self
        SV *key
    PROTOTYPE: $$
    CODE:
        ST(0) = hamt_fn_map_exists(aTHX_ self, key);
        XSRETURN(1);

void
hamt_map_count(self)
        SV *self
    PROTOTYPE: $
    CODE:
        ST(0) = sv_2mortal(newSVuv(hamt_fn_map_count(aTHX_ self)));
        XSRETURN(1);

void
import(class, ...)
    CODE:
        hamt_fn_import(aTHX_ HAMT_FN_MAP, &ST(1), items - 1);
        XSRETURN_EMPTY;

MODULE = HAMT    PACKAGE = HAMT::Set

void
hamt_set_has(self, member)
        SV *self
        SV *member
    PROTOTYPE: $$
    CODE:
        ST(0) = hamt_fn_set_has(aTHX_ self, member);
        XSRETURN(1);

void
hamt_set_count(self)
        SV *self
    PROTOTYPE: $
    CODE:
        ST(0) = sv_2mortal(newSVuv(hamt_fn_set_count(aTHX_ self)));
        XSRETURN(1);

void
import(class, ...)
    CODE:
        hamt_fn_import(aTHX_ HAMT_FN_SET, &ST(1), items - 1);
        XSRETURN_EMPTY;

MODULE = HAMT    PACKAGE = HAMT::Vector

void
hamt_vector_get(self, index)
        SV *self
        SV *index
    PROTOTYPE: $$
    CODE:
        ST(0) = hamt_fn_vector_get(aTHX_ self, index);
        XSRETURN(1);

void
hamt_vector_count(self)
        SV *self
    PROTOTYPE: $
    CODE:
        ST(0) = sv_2mortal(newSVuv(hamt_fn_vector_count(aTHX_ self)));
        XSRETURN(1);

void
import(class, ...)
    CODE:
        hamt_fn_import(aTHX_ HAMT_FN_VECTOR, &ST(1), items - 1);
        XSRETURN_EMPTY;

BOOT:
    hamt_ops_boot(aTHX);
