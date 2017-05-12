
/* Analyzer wrapper for subclasses */
class PerlAnalyzer : public Analyzer, public PerlWrapper
{
    public:
        TokenStream* tokenStream(const TCHAR* fieldName, Reader* reader)
        {
            TokenStream* var;
            int count;
            SV* perl_reader;
            SV* perl_field_name;
            SV* obj = SvRV(obj_ref);

            perl_field_name = WCharToSv((wchar_t*)fieldName, sv_newmortal());
            perl_reader = PtrToSv("Lucene::Utils::Reader", (void*)reader, sv_newmortal());

            m.pushArgument(perl_field_name);
            m.pushArgument(perl_reader);
            m.call(obj, "tokenStream");
            SV* arg = m.shiftReturn();
            m.finish();

            var = SvToPtr<TokenStream*>(arg);
            if (!var)
                croak("tokenStream returned an invalid object");
            MarkObjCppOwned(arg); // The calling method deletes the object
            return var;
        }
};

