TermQuery *
new(CLASS, term)
const char* CLASS;
Term* term
    CODE:
        RETVAL = new TermQuery(term);
    OUTPUT:
        RETVAL
    CLEANUP:
        // Memorize Term in returned blessed hash reference.
        // We don't want it to be destroyed by perl before the C++ object it
        // contains gets destroyed by C++. Otherwise this would cause a seg fault.
        hv_store((HV *) SvRV(ST(0)), "Term", 4, newRV(SvRV(ST(1))), 1);

void
DESTROY(self)
        TermQuery * self
    CODE:
        delete self;

