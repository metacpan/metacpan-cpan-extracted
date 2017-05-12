RAMDirectory *
new(CLASS)
const char* CLASS;
    CODE:
        RETVAL = new RAMDirectory();
//        printf("created ramdirectory\n");
    OUTPUT:
        RETVAL

void
close(self)
RAMDirectory* self
    CODE:
        self->close();
    OUTPUT:

void
DESTROY(self)
        RAMDirectory * self
    CODE:
        self->close();
        delete self;
//        printf("deleted ramdirectory\n");

