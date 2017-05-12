
/* Base class for all the wrapper subclasses (multiple inhertance) */
class PerlWrapper
{
    protected:
        SV* obj_ref;
        mutable PerlMethodCall m;
    public:
        PerlWrapper() {}
        virtual ~PerlWrapper()
        {
            MarkObjCppOwned(SvRV(obj_ref));
        }
        void setObject(SV *o)
        {
            if (!sv_isobject(o))
                croak("Not an object specified to setObject");
            obj_ref = newRV_inc(o);
        }
};

