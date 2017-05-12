PerlTokenizer *
new(CLASS, reader)
        const char* CLASS
        Reader* reader
    CODE:
        RETVAL = new PerlTokenizer(reader);
    OUTPUT:
        RETVAL
    CLEANUP:
        RETVAL->setObject(ST(0));
        // Memorize Reader in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Reader", 6, newRV(SvRV(ST(1))), 1);

void
close()
    CODE:

bool
next(token)
        Token *token
    CODE:
        croak("Virtual method Lucene::Tokenizer::next() not implemented");

void
DESTROY(self)
        PerlTokenizer *self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;

