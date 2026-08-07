MODULE = Hyperman		PACKAGE = Hyperman

# Public C ABI entry point (hm_abi.h / hm_abi_impl.h): a DBI-style versioned
# function-pointer table for XS consumers (DBIx::Loop, ...). Resolved at
# runtime - call_pv("Hyperman::_abi_ptr"), INT2PTR, check abi_version.

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&hm_abi_table);
    OUTPUT:
        RETVAL

# Resolve and exercise the whole table from C: future lifecycle (done, fail,
# on_ready, double-settle no-op), a C io watcher on a pipe, a cancelled timer,
# and a live timer, all pumped with run_until. 1 = every check passed.
IV
_abi_selftest()
    CODE:
        RETVAL = hm_abi_selftest(aTHX);
    OUTPUT:
        RETVAL

# The table's version, for tests and for a consumer that would rather ask
# than dereference the pointer itself.
IV
_abi_version()
    CODE:
        RETVAL = hm_abi_table.abi_version;
    OUTPUT:
        RETVAL
