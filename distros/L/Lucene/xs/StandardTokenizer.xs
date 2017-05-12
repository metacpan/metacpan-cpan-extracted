StandardTokenizer*
new(CLASS, reader)
        const char* CLASS
        Reader* reader
    CODE:
        RETVAL = new StandardTokenizer(reader);
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Reader in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Reader", 6, newRV(SvRV(ST(1))), 1);

void
DESTROY(self)
        StandardTokenizer* self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
