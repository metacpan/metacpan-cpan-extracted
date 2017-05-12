
class PerlTokenizer : public Tokenizer, public PerlWrapper
{
    public:
        PerlTokenizer(Reader* reader) : Tokenizer(reader), PerlWrapper() {}
        void close()
        {
            SV* obj = SvRV(obj_ref);
            Tokenizer::close();
            m.call(obj, "close");
            m.finish();
        }
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

