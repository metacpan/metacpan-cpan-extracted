PerlTokenFilter *
new(CLASS, in)
        const char* CLASS
        TokenStream* in
    CODE:
        MarkObjCppOwned(ST(1));
        RETVAL = new PerlTokenFilter(in);
    OUTPUT:
        RETVAL
    CLEANUP:
        RETVAL->setObject(ST(0));
        // Memorize Reader in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "TokenStream", 11, newRV(SvRV(ST(1))), 1);

bool
next(token)
        Token *token
    CODE:
        croak("Virtual method Lucene::TokenFilter::next() not implemented");

void
DESTROY(self)
        PerlTokenFilter *self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;


