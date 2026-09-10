MODULE = Frozen    PACKAGE = Frozen

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&FZ_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = FZ_ABI.abi_version;
    OUTPUT:
        RETVAL

void
_abi_selftest()
    PREINIT:
        int step = 0;
        SV *data = NULL;
        SV *bytes;
    PPCODE:
        bytes = fz_abi_selftest(aTHX_ &step, &data);
        EXTEND(SP, 3);
        mPUSHi(step);
        PUSHs(bytes ? sv_2mortal(bytes) : &PL_sv_undef);
        PUSHs(data  ? sv_2mortal(data)  : &PL_sv_undef);
