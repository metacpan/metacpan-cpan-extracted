Highlighter *
new(CLASS, obj, obj2 = 0)
 CASE: items == 2
    const char* CLASS;
    Scorer* obj
    CODE:
        RETVAL = new Highlighter(obj);
    OUTPUT:
        RETVAL
 CASE: items == 3
    const char* CLASS;
    Formatter* obj
    Scorer* obj2
    CODE:
        RETVAL = new Highlighter(obj, obj2);
    OUTPUT:
        RETVAL

const wchar_t*
getBestFragment(self, analyzer, fieldname, text)
        Highlighter* self
        Analyzer* analyzer
        wchar_t* fieldname
        wchar_t* text
     CODE:
        RETVAL = self->getBestFragment(analyzer, fieldname, text);
     OUTPUT:
        RETVAL

const wchar_t*
getBestFragments(self, analyzer, fieldname, text, max_num_fragments, separator)
        Highlighter* self
        Analyzer* analyzer
        wchar_t* fieldname
        wchar_t* text
        int max_num_fragments
        wchar_t* separator
     CODE:
        TokenStream* tokenStream = analyzer->tokenStream(fieldname, _CLNEW StringReader(text));
        RETVAL = self->getBestFragments(tokenStream, text, max_num_fragments, separator);
        tokenStream->close();
        delete tokenStream;
     OUTPUT:
        RETVAL

void
DESTROY(self)
        Highlighter * self
    CODE:
        delete self;

