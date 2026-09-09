
# The C ABI's two Perl-visible ends: the table's address, and the selftest
# that walks a document through every entry.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&FRX_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        /* the table's own version, for a consumer's build-time guard to
         * assert against without resolving the table itself */
        RETVAL = FRX_ABI.abi_version;
    OUTPUT:
        RETVAL

void
_abi_selftest()
    PREINIT:
        SV *out;
    PPCODE:
        /* ($input, $exclusive_bytes), or an empty list on any mismatch */
        out = frx_abi_selftest(aTHX);
        if (!out) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal(newSVpvn(FRX_SELFTEST_INPUT, sizeof FRX_SELFTEST_INPUT - 1)));
        XPUSHs(sv_2mortal(out));

IV
_abi_selftest_full()
    CODE:
        /* 0 when every full-profile entry answered as it should, and the
         * number of the check that did not otherwise */
        RETVAL = frx_abi_selftest_full(aTHX);
    OUTPUT:
        RETVAL
