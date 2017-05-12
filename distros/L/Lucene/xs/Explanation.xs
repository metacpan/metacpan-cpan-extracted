wchar_t*
toString(self)
       Explanation* self
    CODE:
       RETVAL = self->toString();
    OUTPUT:
       RETVAL

void
DESTROY(self)
        Explanation * self
    CODE:
        delete self;

