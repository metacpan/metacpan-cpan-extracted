FuzzyQuery *
new(CLASS, term)
const char* CLASS;
Term* term
    CODE:
        RETVAL = new FuzzyQuery(term);
//        printf("created FuzzyQuery\n");
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Term in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Term", 4, newRV(SvRV(ST(1))), 1);

void
DESTROY(self)
        FuzzyQuery * self
    CODE:
        delete self;
//        printf("deleted FuzzyQuery\n");

