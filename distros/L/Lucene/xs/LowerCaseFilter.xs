LowerCaseFilter*
new(CLASS, in)
        const char* CLASS
        TokenStream* in
    CODE:
        MarkObjCppOwned(ST(1));
        RETVAL = new LowerCaseFilter(in, true);
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize TokenStream in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "TokenStream", 11, newRV(SvRV(ST(1))), 1);

bool
next(self, token)
        LowerCaseFilter* self
        Token *token
    CODE:
        RETVAL = self->next(token);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        LowerCaseFilter* self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
