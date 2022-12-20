#// clang-format off

MODULE = Dyn::Call PACKAGE = Dyn::Call

DCpointer
malloc(size_t size)
CODE:
// clang-format on
{
    RETVAL = safemalloc(size);
    if (RETVAL == NULL) XSRETURN_EMPTY;
}
// clang-format off
OUTPUT:
RETVAL

DCpointer
calloc(size_t num, size_t size)
CODE:
// clang-format off
    {RETVAL = safecalloc(num, size);
    if (RETVAL == NULL) XSRETURN_EMPTY;}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
realloc(IN_OUT DCpointer ptr, size_t size)
CODE:
    ptr = saferealloc(ptr, size);
OUTPUT:
    RETVAL

void
free(DCpointer ptr)
PPCODE:
// clang-format on
{
    if (ptr != NULL) dcFreeMem(ptr);
    ptr = NULL;
    sv_set_undef(ST(0));
} // Let Dyn::Call::Pointer::DESTROY take care of the rest
  // clang-format off

DCpointer
memchr(DCpointer ptr, char ch, size_t count)

int
memcmp(lhs, rhs, size_t count)
INIT:
    DCpointer lhs, rhs;
CODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else
        croak("ptr is not of type Dyn::Call::Pointer");
    if (sv_derived_from(ST(1), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { rhs = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    RETVAL = memcmp(lhs, rhs, count);
}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
memset(DCpointer dest, char ch, size_t count)

void
memcpy(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    if (sv_derived_from(ST(1), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    CopyD(src, dest, nitems, char);
}
// clang-format off

void
memmove(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    if (sv_derived_from(ST(1), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    Move(src, dest, nitems, char);
}
// clang-format off

BOOT :
// clang-format on
{
    export_function("Dyn::Call", "malloc", "memory");
    export_function("Dyn::Call", "calloc", "memory");
    export_function("Dyn::Call", "realloc", "memory");
    export_function("Dyn::Call", "free", "memory");
    export_function("Dyn::Call", "memchr", "memory");
    export_function("Dyn::Call", "memcmp", "memory");
    export_function("Dyn::Call", "memset", "memory");
    export_function("Dyn::Call", "memcpy", "memory");
    export_function("Dyn::Call", "memmove", "memory");
}
// clang-format off

MODULE = Dyn::Call PACKAGE = Dyn::Call::Pointer

FALLBACK : TRUE

IV
plus(DCpointer ptr, IV other, IV swap)
OVERLOAD: +
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) + other;
// clang-format off
OUTPUT:
    RETVAL

IV
minus(DCpointer ptr, IV other, IV swap)
OVERLOAD: -
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) - other;
// clang-format off
OUTPUT:
    RETVAL

char *
as_string(DCpointer ptr, ...)
OVERLOAD: \"\"
CODE:
    // clang-format on
    RETVAL = (char *)ptr;
// clang-format off
OUTPUT:
    RETVAL

SV *
raw(ptr, size_t size, bool utf8 = false)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
    RETVAL = newSVpvn_utf8((const char *)ptr, size, utf8 ? 1 : 0);
}
// clang-format off
OUTPUT:
    RETVAL

void
dump(ptr, size_t size)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Dyn::Call::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Dyn::Call::Pointer");
}
// clang-format off
