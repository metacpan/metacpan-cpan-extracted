RangeFilter *
new(CLASS, field, lower_term, upper_term, include_lower, include_upper)
const char* CLASS;
wchar_t* field;
wchar_t* lower_term;
wchar_t* upper_term;
bool include_lower;
bool include_upper;
    CODE:
        RETVAL = new RangeFilter(field, lower_term, upper_term, include_lower, include_upper);
    OUTPUT:
        RETVAL


RangeFilter *
Less(CLASS, field, upper_term)
const char* CLASS;
wchar_t* field;
wchar_t* upper_term;
    CODE:
        RETVAL = RangeFilter::Less(field, upper_term);
    OUTPUT:
        RETVAL


RangeFilter *
More(CLASS, field, lower_term)
const char* CLASS;
wchar_t* field;
wchar_t* lower_term;
    CODE:
        RETVAL = RangeFilter::More(field, lower_term);
    OUTPUT:
        RETVAL

wchar_t*
toString(self)
       RangeFilter* self
    CODE:
       RETVAL = self->toString();
    OUTPUT:
       RETVAL

void
DESTROY(self)
        RangeFilter * self
    CODE:
        delete self;

