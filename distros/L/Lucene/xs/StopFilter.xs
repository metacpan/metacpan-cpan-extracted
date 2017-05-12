StopFilter*
new(CLASS, in, stop_words)
        const char* CLASS
        TokenStream* in
        wchar_t** stop_words
    CODE:
        MarkObjCppOwned(ST(1));
        RETVAL = new StopFilter(in, true, (const wchar_t**) stop_words);
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize TokenStream in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "TokenStream", 11, newRV(SvRV(ST(1))), 1);

bool
next(self, token)
        StopFilter* self
        Token *token
    CODE:
        RETVAL = self->next(token);
    OUTPUT:
        RETVAL


void
DESTROY(self)
        StopFilter* self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
