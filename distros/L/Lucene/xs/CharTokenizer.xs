PerlCharTokenizer *
new(CLASS, reader)
        const char* CLASS
        Reader* reader
    CODE:
        RETVAL = new PerlCharTokenizer(reader);
    OUTPUT:
        RETVAL
    CLEANUP:
        RETVAL->setObject(ST(0));

void
close()
    CODE:

bool
isTokenChar(self, c)
        PerlCharTokenizer* self
        wchar_t c
    CODE:
        croak("Virtual method Lucene::Tokenizer::isTokenChar() not implemented");

void
DESTROY(self)
        PerlCharTokenizer *self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;


