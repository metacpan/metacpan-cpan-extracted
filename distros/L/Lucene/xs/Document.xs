Document *
new(CLASS)
const char* CLASS;
    CODE:
        RETVAL = new Document();
    OUTPUT:
        RETVAL

void
add(self, field)
       Document* self
       Field* field
    CODE:
       self->add(*field);

const wchar_t*
get(self, field)
       Document* self
       wchar_t* field
    CODE:
       RETVAL = self->get(field);
    OUTPUT:
       RETVAL

void 
removeField(self, field)
       Document* self
       wchar_t* field
    CODE:
       self->removeField(field);

const wchar_t*
toString(self)
       Document* self
    CODE:
       RETVAL = self->toString();
    OUTPUT:
       RETVAL

void
DESTROY(self)
       Document* self
    CODE:
       if (!IsObjCppOwned(ST(0)))
            delete self;

