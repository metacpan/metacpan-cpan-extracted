Token*
new(CLASS, text = 0, start = 0, end = 0, typ = 0)
    CASE: items == 5
            const char* CLASS
            wchar_t* text
            int32_t start
            int32_t end
            wchar_t* typ
        CODE:
            RETVAL = new Token(text, start, end, typ);
        OUTPUT:
            RETVAL
    CASE:
            const char* CLASS
        CODE:
            RETVAL = new Token();
        OUTPUT:
            RETVAL

void
set(self, text, start, end, typ)
        Token* self
        wchar_t* text
        int32_t start
        int32_t end
        wchar_t* typ
    CODE:
        self->set(text, start, end, typ);

size_t
bufferLength(self)
        Token* self
    CODE:
        RETVAL = self->bufferLength();
    OUTPUT:
        RETVAL

void
growBuffer(self, size)
        Token *self
        size_t size
    CODE:
        self->growBuffer(size);

void
setPositionIncrement(self, pos_inc)
        Token* self
        int32_t pos_inc
    CODE:
        self->setPositionIncrement(pos_inc);

int32_t
getPositionIncrement(self)
        Token* self
    CODE:
        RETVAL = self->getPositionIncrement();
    OUTPUT:
        RETVAL

const wchar_t*
termText(self)
        Token* self
    CODE:
        RETVAL = self->termText();
    OUTPUT:
        RETVAL

size_t
termTextLength(self)
        Token* self
    CODE:
        RETVAL = self->termTextLength();
    OUTPUT:
        RETVAL

void
resetTermTextLen(self)
        Token* self
    CODE:
        self->resetTermTextLen();

void
setText(self, txt)
        Token* self
        const wchar_t* txt
    CODE:
        self->setText(txt);

int32_t
startOffset(self)
        Token* self
    CODE:
        RETVAL = self->startOffset();
    OUTPUT:
        RETVAL

void
setStartOffset(self, val)
        Token* self
        int32_t val
    CODE:
        self->setStartOffset(val);

int32_t
endOffset(self)
        Token* self
    CODE:
        RETVAL = self->endOffset();
    OUTPUT:
        RETVAL

void
setEndOffset(self, val)
        Token* self
        int32_t val
    CODE:
        self->setEndOffset(val);

const wchar_t*
type(self)
        Token* self
    CODE:
        RETVAL = self->type();
    OUTPUT:
        RETVAL

void
setType(self, typ)
        Token* self
        const wchar_t* typ
    CODE:
        self->setType(typ);

