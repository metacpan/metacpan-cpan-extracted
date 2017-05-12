class PerlCharTokenizer : public CharTokenizer, public PerlWrapper
{
    public:
        bool isTokenChar(wchar_t c) const
        {
            SV* obj = SvRV(obj_ref);
            wchar_t ch[2];
            ch[0] = c;
            ch[1] = 0;
            SV* pch = WCharToSv((wchar_t*)ch, sv_newmortal());
            m.pushArgument(pch);
            m.call(obj, "isTokenChar");
            SV* ret = m.shiftReturn();
            m.finish();
            if (SvTRUE(ret))
                return true;
            return false;
        }
        wchar_t normalize(const wchar_t c) const
        {
            SV* obj = SvRV(obj_ref);
            m.pushArgument(newSVpv("next", 4));
            m.call(obj, "can");
            SV* ret = m.shiftReturn();
            m.finish();
            if (SvTRUE(ret)) {
                wchar_t *ret1, ret2;
                wchar_t ch[2];
                ch[0] = c;
                ch[1] = 0;
                SV* pch = WCharToSv((wchar_t*)ch, sv_newmortal());
                m.pushArgument(pch);
                m.call(obj, "normalize");
                SV* ret = m.shiftReturn();
                m.finish();
                ret1 = SvToWChar(ret);
                ret2 = ret1[0];
                Safefree(ret1);
                return ret2;
            }
            else
                return CharTokenizer::normalize(c);
        }

        PerlCharTokenizer(Reader* reader) : CharTokenizer(reader), PerlWrapper() {}
        void close()
        {
            SV* obj = SvRV(obj_ref);
            CharTokenizer::close();
            m.call(obj, "close");
            m.finish();
        }
        bool next(Token* token)
        {
            SV* obj = SvRV(obj_ref);
            m.pushArgument(newSVpv("next", 4));
            m.call(obj, "can");
            SV* ret = m.shiftReturn();
            m.finish();
            if (SvTRUE(ret)) {
                SV* perl_token = PtrToSv("Lucene::Analysis::Token", (void*)token, sv_newmortal());
                m.pushArgument(perl_token);
                m.call(obj, "next");
                SV* ret = m.shiftReturn();
                m.finish();
                if (SvTRUE(ret))
                    return true;
                return false;
            }
            else
                return CharTokenizer::next(token);
        }
};


