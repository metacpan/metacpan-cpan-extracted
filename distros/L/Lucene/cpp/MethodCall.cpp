
class PerlMethodCall
{
    private:
        struct list {
            SV* item;
            struct list *next;
        };
        struct list *args;
        struct list *args_tail;
        struct list *rets;
        struct list *rets_tail;
        I32 flags;
    public:
        PerlMethodCall()
        : args(NULL), args_tail(NULL), rets(NULL), rets_tail(NULL)
        {
        }
        ~PerlMethodCall()
        {
            finish();
        }
        void finish()
        {
            SV* sv;
            while ((sv = shiftReturn()))
                SvREFCNT_dec(sv);
            while ((sv = shiftArgument()))
                SvREFCNT_dec(sv);
        }
        void pushReturn(SV *ret)
        {
            struct list *n = new struct list;
            n->item = newRV(ret);
            n->next = NULL;
            if (rets_tail)
                rets_tail->next = n;
            else if (rets)
                rets->next = n;
            else
                rets = n;
            rets_tail = n;
        }
        SV* shiftReturn()
        {
            SV* ret;
            struct list *frst;
            if (!rets)
                return NULL;
            frst = rets->next;
            ret = SvRV(rets->item);
            delete rets;
            rets = frst;
            if (!rets)
                rets_tail = NULL;
            return ret;
        }
        void pushArgument(SV *arg)
        {
            struct list *n = new struct list;
            n->item = newRV(arg);
            n->next = NULL;
            if (args_tail)
                args_tail->next = n;
            else if (args)
                args->next = n;
            else
                args = n;
            args_tail = n;
        }
        SV* shiftArgument()
        {
            SV* arg;
            struct list *frst;
            if (!args)
                return NULL;
            frst = args->next;
            arg = SvRV(args->item);
            delete args;
            args = frst;
            if (!args)
                args_tail = NULL;
            return arg;
        }
        void call(SV* object, const char* method_name, I32 flgs = G_SCALAR)
        {
            int i = 0;
            int return_count;
            SV* arg;
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(SP);
            XPUSHs(object);
            while ((arg = shiftArgument()))
                XPUSHs(arg);
            PUTBACK;
            return_count = call_method(method_name, flgs);
            SPAGAIN;

            for (i = 0; i < return_count; ++i)
                pushReturn(POPs);

            PUTBACK;
            FREETMPS;
            LEAVE;
        }
};

