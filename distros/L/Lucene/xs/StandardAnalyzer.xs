StandardAnalyzer *
new(CLASS, stop_words = 0)
  CASE: items == 1
     const char* CLASS;
     CODE:
         RETVAL = new StandardAnalyzer();
     OUTPUT:
         RETVAL
  CASE: items == 2
     const char* CLASS;
     wchar_t** stop_words
     CODE:
         RETVAL = new StandardAnalyzer((const wchar_t**) stop_words);
     OUTPUT:
         RETVAL


void
DESTROY(self)
        StandardAnalyzer * self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
