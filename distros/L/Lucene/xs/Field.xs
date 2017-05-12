Field *
Keyword(CLASS, name, value)
const char* CLASS;
const wchar_t* name
const wchar_t* value
    CODE:
        RETVAL = Field::Keyword(name, value);
    OUTPUT:
        RETVAL

Field *
UnIndexed(CLASS, name, value)
const char* CLASS;
const wchar_t* name
const wchar_t* value
    CODE:
        RETVAL = Field::UnIndexed(name, value);
    OUTPUT:
        RETVAL

Field *
Text(CLASS, name, value)
const char* CLASS;
const wchar_t* name
const wchar_t* value
    CODE:
        RETVAL = Field::Text(name, value);
    OUTPUT:
        RETVAL

Field *
UnStored(CLASS, name, value)
const char* CLASS;
const wchar_t* name
const wchar_t* value
    CODE:
        RETVAL = Field::UnStored(name, value);
    OUTPUT:
        RETVAL

void
setBoost(self, boost)
        Field *self
        float boost
    CODE:
        self->setBoost(boost);

float
getBoost(self)
        Field *self
    CODE:
        RETVAL = self->getBoost();
    OUTPUT:
        RETVAL

