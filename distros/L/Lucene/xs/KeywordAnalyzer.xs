KeywordAnalyzer *
new(CLASS)
const char* CLASS;
    CODE:
        RETVAL = new KeywordAnalyzer();
    OUTPUT:
        RETVAL

void
DESTROY(self)
        KeywordAnalyzer * self
    CODE:
        if (!IsObjCppOwned(ST(0))) {
            delete self;
        }
