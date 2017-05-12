StopAnalyzer *
new(CLASS, stop_words = 0)
  CASE: items == 1
     const char* CLASS;
     CODE:
         RETVAL = new StopAnalyzer();
     OUTPUT:
         RETVAL
  CASE: items == 2
     const char* CLASS;
     wchar_t** stop_words
     CODE:
         RETVAL = new StopAnalyzer((const wchar_t**) stop_words);
     OUTPUT:
         RETVAL

void
DESTROY(self)
         StopAnalyzer* self
     CODE:
         if (!IsObjCppOwned(ST(0)))
             delete self;

