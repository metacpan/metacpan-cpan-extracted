SimpleAnalyzer *
new(CLASS)
const char* CLASS;
    CODE:
        RETVAL = new SimpleAnalyzer();
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SimpleAnalyzer * self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
