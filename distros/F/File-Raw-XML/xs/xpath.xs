
# File::Raw::XML::XPath: a compiled expression, and the two classes an
# attribute or a namespace node in a result comes back as. The compiled
# object holds no document; every result does, exactly as a Node does.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::XPath

SV *
new(class, expr, ...)
        const char *class
        SV         *expr
    PREINIT:
        HV        *opts;
        frx_xpath *x;
    CODE:
        opts = frx_opts_hv(aTHX_ &ST(0), 2, items, "new");
        x    = frx_xpath_from_opts(aTHX_ expr, opts, "new");
        RETVAL = frx_xpath_bless(aTHX_ x, class);
    OUTPUT:
        RETVAL

void
find(self, context)
        SV *self
        SV *context
    PREINIT:
        frx_xpath      *x;
        frx_doc        *d;
        const frx_node *ctx;
        SV             *doc_iv;
        frx_xp_val      v;
        const char     *err = NULL;
        AV             *av;
        I32             i, n;
    PPCODE:
        x   = frx_xpath_from_sv(aTHX_ self, "find");
        ctx = frx_xpath_context(aTHX_ context, "find", &d, &doc_iv);
        if (!frx_xpath_eval_at(x, d, ctx, &v, &err)) {
            frx_xp_val_free(&v);
            croak("File::Raw::XML: find: %s", err ? err : "the expression could not be evaluated");
        }
        av = frx_xp_result_av(aTHX_ &v, doc_iv, GIMME_V);
        frx_xp_val_free(&v);
        n = av_len(av) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            PUSHs(sv_2mortal(SvREFCNT_inc(e ? *e : &PL_sv_undef)));
        }

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Node

void
xpath(self, expr, ...)
        SV *self
        SV *expr
    PREINIT:
        HV             *opts;
        frx_xpath      *x;
        frx_doc        *d;
        const frx_node *ctx;
        SV             *doc_iv;
        frx_xp_val      v;
        const char     *err = NULL;
        AV             *av;
        I32             i, n;
        int             ok;
    PPCODE:
        ctx  = frx_xpath_context(aTHX_ self, "xpath", &d, &doc_iv);
        opts = frx_opts_hv(aTHX_ &ST(0), 2, items, "xpath");
        x    = frx_xpath_from_opts(aTHX_ expr, opts, "xpath");
        ok   = frx_xpath_eval_at(x, d, ctx, &v, &err);
        if (!ok) {
            char msg[512];
            my_snprintf(msg, sizeof msg, "File::Raw::XML: xpath: %s",
                        err ? err : "the expression could not be evaluated");
            frx_xp_val_free(&v);
            frx_xpath_free(x);
            croak("%s", msg);
        }
        av = frx_xp_result_av(aTHX_ &v, doc_iv, GIMME_V);
        frx_xp_val_free(&v);
        frx_xpath_free(x);
        n = av_len(av) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            PUSHs(sv_2mortal(SvREFCNT_inc(e ? *e : &PL_sv_undef)));
        }

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Document

void
xpath(self, expr, ...)
        SV *self
        SV *expr
    PREINIT:
        HV             *opts;
        frx_xpath      *x;
        frx_doc        *d;
        const frx_node *ctx;
        SV             *doc_iv;
        frx_xp_val      v;
        const char     *err = NULL;
        AV             *av;
        I32             i, n;
        int             ok;
    PPCODE:
        ctx  = frx_xpath_context(aTHX_ self, "xpath", &d, &doc_iv);
        opts = frx_opts_hv(aTHX_ &ST(0), 2, items, "xpath");
        x    = frx_xpath_from_opts(aTHX_ expr, opts, "xpath");
        ok   = frx_xpath_eval_at(x, d, ctx, &v, &err);
        if (!ok) {
            char msg[512];
            my_snprintf(msg, sizeof msg, "File::Raw::XML: xpath: %s",
                        err ? err : "the expression could not be evaluated");
            frx_xp_val_free(&v);
            frx_xpath_free(x);
            croak("%s", msg);
        }
        av = frx_xp_result_av(aTHX_ &v, doc_iv, GIMME_V);
        frx_xp_val_free(&v);
        frx_xpath_free(x);
        n = av_len(av) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            PUSHs(sv_2mortal(SvREFCNT_inc(e ? *e : &PL_sv_undef)));
        }

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Attr

SV *
name(self)
        SV *self
    ALIAS:
        local  = 1
        ns     = 2
        prefix = 3
        value  = 4
    PREINIT:
        const frx_node *owner;
        const frx_attr *a;
        int             ix_at;
        const char     *meth[] = { "name", "local", "ns", "prefix", "value" };
    CODE:
        owner = frx_entry_from_sv(aTHX_ self, meth[ix], 0, &ix_at, NULL);
        if (ix_at < 0 || ix_at >= owner->n_attrs)
            croak("File::Raw::XML: %s: the attribute is no longer in its element", meth[ix]);
        a = &owner->attrs[ix_at];
        switch (ix) {
        case 1:  RETVAL = frx_str_sv(aTHX_ &a->local);  break;
        case 2:  RETVAL = frx_str_sv(aTHX_ &a->ns);     break;
        case 3:  RETVAL = frx_str_sv(aTHX_ &a->prefix); break;
        case 4:  RETVAL = frx_str_sv(aTHX_ &a->value);  break;
        default: RETVAL = frx_str_sv(aTHX_ &a->qname);  break;
        }
    OUTPUT:
        RETVAL

SV *
owner(self)
        SV *self
    ALIAS:
        doc = 1
    PREINIT:
        const frx_node *o;
        SV             *doc_iv;
    CODE:
        o = frx_entry_from_sv(aTHX_ self, ix ? "doc" : "owner", 0, NULL, &doc_iv);
        RETVAL = ix ? frx_node_doc_rv(aTHX_ doc_iv) : frx_node_bless(aTHX_ doc_iv, o);
    OUTPUT:
        RETVAL

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Namespace

SV *
name(self)
        SV *self
    ALIAS:
        prefix = 1
        value  = 2
        uri    = 3
    PREINIT:
        const frx_node *owner;
        frx_str         p, u;
        int             ix_at;
        const char     *meth[] = { "name", "prefix", "value", "uri" };
    CODE:
        owner = frx_entry_from_sv(aTHX_ self, meth[ix], 1, &ix_at, NULL);
        if (!frx_xp_ns_at(owner, ix_at, &p, &u))
            croak("File::Raw::XML: %s: out of memory", meth[ix]);
        RETVAL = frx_str_sv(aTHX_ ix >= 2 ? &u : &p);
    OUTPUT:
        RETVAL

SV *
owner(self)
        SV *self
    ALIAS:
        doc = 1
    PREINIT:
        const frx_node *o;
        SV             *doc_iv;
    CODE:
        o = frx_entry_from_sv(aTHX_ self, ix ? "doc" : "owner", 1, NULL, &doc_iv);
        RETVAL = ix ? frx_node_doc_rv(aTHX_ doc_iv) : frx_node_bless(aTHX_ doc_iv, o);
    OUTPUT:
        RETVAL
