# The C ABI's Perl-visible ends: the table's address, its version, and the
# selftest that walks it.

MODULE = HAMT    PACKAGE = HAMT

# Unsigned, not IV: where the loader maps this object decides the sign bit, and
# a 32-bit perl above 0x7fffffff would hand back a negative from PTR2IV.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&HAMT_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = HAMT_ABI.abi_version;
    OUTPUT:
        RETVAL

# The number of the check that failed, or 0, and then a map, a set and a
# vector that were built in C through the table, for the Perl surface to
# read back. A negative number is a check that failed AND left something
# allocated behind it.
void
_abi_selftest()
    PREINIT:
        SV *map = NULL, *set = NULL, *vec = NULL;
        int step;
    PPCODE:
        step = hamt_abi_selftest(aTHX_ &map, &set, &vec);
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(map ? sv_2mortal(map) : &PL_sv_undef);
        PUSHs(set ? sv_2mortal(set) : &PL_sv_undef);
        PUSHs(vec ? sv_2mortal(vec) : &PL_sv_undef);
