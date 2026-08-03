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
