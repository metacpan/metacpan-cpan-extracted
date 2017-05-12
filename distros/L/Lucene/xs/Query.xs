wchar_t*
toString(self)
       Query* self
    CODE:
       RETVAL = self->toString();
    OUTPUT:
       RETVAL

void
DESTROY(self)
        Query * self
    CODE:
        delete self;

