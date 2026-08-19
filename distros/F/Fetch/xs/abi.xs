MODULE = Fetch		PACKAGE = Fetch

# Address of Fetch's C ABI table (fetch_abi.h). A consumer XS module fetches
# this once at boot, INT2PTRs it to a `const fetch_abi *`, and checks
# ->abi_version before using it. Not part of the public Perl API.
IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&FETCH_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = FETCH_ABI.abi_version;
    OUTPUT:
        RETVAL

# Fetch->on_request(\&start, \&done): the same observer registry the C ABI's
# on_request writes to, reached from Perl - for a consumer that is not an XS
# module. Same contract (process-global, per hop, no deregistration), one
# Perl call per hop as the price. Public.
IV
on_request(class, start, done = &PL_sv_undef)
        SV *class
        SV *start
        SV *done
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = ft_obs_add_perl(aTHX_ start, done);
    OUTPUT:
        RETVAL

# v2 on_request, for t/23-observer.t. Registering a C callback is not
# something Perl can do, so the test drives these two instead: install, make
# requests, then read back what the observer saw.
IV
_abi_observer_install()
    CODE:
        RETVAL = ft_obs_selftest_install(aTHX);
    OUTPUT:
        RETVAL

# (starts, dones, resolved, failed) since load.
void
_abi_observer_state()
    PPCODE:
        EXTEND(SP, 4);
        mPUSHi(FT_OBS_ST_STARTS);
        mPUSHi(FT_OBS_ST_DONES);
        mPUSHi(FT_OBS_ST_OK);
        mPUSHi(FT_OBS_ST_ERR);
