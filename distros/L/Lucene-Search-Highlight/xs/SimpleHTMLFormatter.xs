SimpleHTMLFormatter *
new(CLASS, pre_tag = 0, post_tag = 0)
 CASE: items == 1
    const char* CLASS;
    CODE:
        RETVAL = new SimpleHTMLFormatter();
    OUTPUT:
        RETVAL
 CASE: items == 3
    const char* CLASS;
    const wchar_t* pre_tag
    const wchar_t* post_tag
    CODE:
        RETVAL = new SimpleHTMLFormatter(pre_tag, post_tag);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SimpleHTMLFormatter * self
    CODE:
        delete self;

