PerFieldAnalyzerWrapper *
new(CLASS, default_analyzer)
        const char* CLASS
        Analyzer* default_analyzer
    CODE:
        MarkObjCppOwned(ST(1));
        RETVAL = new PerFieldAnalyzerWrapper(default_analyzer);
    OUTPUT:
        RETVAL

void
addAnalyzer(self, field_name, analyzer)
        PerFieldAnalyzerWrapper* self
        const wchar_t* field_name
        Analyzer* analyzer
    CODE:
        MarkObjCppOwned(ST(2));
        self->addAnalyzer(field_name, analyzer);
    CLEANUP:
        // Memorize Analyzer in returned blessed hash reference.
        // We don't want them to be destroyed by perl before the C++ object they
        // contain gets destroyed by C++. Otherwise this would cause a seg fault.
        HV *ohv = (HV *) SvRV(ST(0));
        SV **analyzers = hv_fetch(ohv, "Analyzers", 8, 0);
        if (analyzers) {
            AV *av = (AV *) SvRV(*analyzers);
            av_push(av, newRV_inc(ST(2)));
        }
        else {
            AV *av = newAV();
            av_push(av, newRV_inc(ST(2)));
            hv_store(ohv, "Analyzers", 8, newRV_inc((SV*)av), 0);
        }

void
DESTROY(self)
        PerFieldAnalyzerWrapper * self
    CODE:
        if (!IsObjCppOwned(ST(0)))
            delete self;
