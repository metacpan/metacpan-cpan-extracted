
class PerlTokenFilter : public TokenFilter, public PerlWrapper
{
    public:
        PerlTokenFilter(TokenStream* in) : TokenFilter(in, true), PerlWrapper() {}
        bool next(Token* token)
        {
            SV* obj = SvRV(obj_ref);
            SV* perl_token = PtrToSv("Lucene::Analysis::Token", (void*)token, sv_newmortal());
            m.pushArgument(perl_token);
            m.call(obj, "next");
            SV* ret = m.shiftReturn();
            m.finish();
            if (SvTRUE(ret))
                return true;
            return false;
        }
};

