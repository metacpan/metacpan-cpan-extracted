PerlAnalyzer *
new(CLASS)
        const char* CLASS
    CODE:
        RETVAL = new PerlAnalyzer();
    OUTPUT:
        RETVAL
    CLEANUP:
        RETVAL->setObject(ST(0));

TokenStream*
tokenStream(self, field, reader)
        PerlAnalyzer *self
        char *field
        Reader *reader
    CODE:
        croak("Virtual method tokenStream not implemented");

void
DESTROY(self)
        PerlAnalyzer *self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
