WhitespaceAnalyzer *
new(CLASS)
const char* CLASS;
    CODE:
        RETVAL = new WhitespaceAnalyzer();
    OUTPUT:
        RETVAL

void
DESTROY(self)
        WhitespaceAnalyzer * self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
