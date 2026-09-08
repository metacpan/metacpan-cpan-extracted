
# File::Raw::XML::Document: what a parse returns.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Document

SV *
root(self)
        SV *self
    PREINIT:
        frx_doc *d;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, "root");
        RETVAL = frx_node_bless(aTHX_ SvRV(self), d->root);
    OUTPUT:
        RETVAL

SV *
document(self)
        SV *self
    PREINIT:
        frx_doc *d;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, "document");
        RETVAL = frx_node_bless(aTHX_ SvRV(self), d->document);
    OUTPUT:
        RETVAL

SV *
by_id(self, attr, value)
        SV         *self
        const char *attr
        SV         *value
    PREINIT:
        frx_doc        *d;
        const frx_node *n;
        STRLEN          vlen;
        const char     *v;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, "by_id");
        v = frx_input(aTHX_ value, &vlen);
        n = frx_by_id(d, attr, v, (size_t)vlen);
        RETVAL = n ? frx_node_bless(aTHX_ SvRV(self), n) : newSV(0);
    OUTPUT:
        RETVAL

SV *
version(self)
        SV *self
    PREINIT:
        frx_doc *d;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, "version");
        RETVAL = newSVpvn(d->version.p, d->version.len);
    OUTPUT:
        RETVAL

IV
standalone(self)
        SV *self
    PREINIT:
        frx_doc *d;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, "standalone");
        RETVAL = d->standalone ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
doctype(self)
        SV *self
    PREINIT:
        frx_doc *d;
        HV      *hv;
    CODE:
        /* { name, public_id, system_id, internal_subset }, the ids and the
         * subset undef when the declaration had none; undef with no DOCTYPE */
        d = frx_doc_from_sv(aTHX_ self, "doctype");
        PERL_UNUSED_VAR(hv);
        RETVAL = frx_doctype_sv(aTHX_ d->doctype);
    OUTPUT:
        RETVAL

SV *
to_string(self, ...)
        SV *self
    PREINIT:
        frx_doc        *d;
        HV             *opts;
        frx_write_opts  o;
        int             perl_chars;
    CODE:
        d    = frx_doc_from_sv(aTHX_ self, "to_string");
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "to_string");
        frx_write_opts_from_hv(aTHX_ opts, &o, &perl_chars, "to_string", 1);
        RETVAL = frx_write_sv(aTHX_ d->document, d, &o, perl_chars, "to_string");
    OUTPUT:
        RETVAL

IV
equals(self, other)
        SV *self
        SV *other
    PREINIT:
        frx_doc *a, *b;
    CODE:
        a = frx_doc_from_sv(aTHX_ self, "equals");
        b = frx_doc_from_sv(aTHX_ other, "equals");
        RETVAL = frx_tree_equal(a->document, b->document) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
c14n(self, ...)
        SV *self
    PREINIT:
        frx_doc  *d;
        HV       *opts;
        frx_c14n  c;
    CODE:
        d    = frx_doc_from_sv(aTHX_ self, "c14n");
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "c14n");
        frx_c14n_opts(aTHX_ opts, SvRV(self), &c, "c14n");
        RETVAL = frx_c14n_sv(aTHX_ d->document, &c, "c14n");
    OUTPUT:
        RETVAL

# ---- building and editing -------------------------------------------------

SV *
new_element(self, ns, name)
        SV *self
        SV *ns
        SV *name
    PREINIT:
        frx_doc *d;
        frx_node *n;
        frx_err  e;
        STRLEN nslen, nlen, plen, llen;
        const char *nsp, *namep, *prefix, *local;
    CODE:
        d     = frx_doc_from_sv(aTHX_ self, "new_element");
        nsp   = frx_arg_bytes(aTHX_ ns, &nslen);
        namep = frx_arg_bytes(aTHX_ name, &nlen);
        frx_split_arg(namep, nlen, &prefix, &plen, &local, &llen);
        n = frx_new_element(d, nsp, nslen, prefix, plen, local, llen, &e);
        if (!n) frx_edit_croak(aTHX_ "new_element", &e);
        RETVAL = frx_node_bless(aTHX_ SvRV(self), n);
    OUTPUT:
        RETVAL

SV *
new_text(self, text)
        SV *self
        SV *text
    ALIAS:
        new_comment = 1
    PREINIT:
        frx_doc *d;
        frx_node *n;
        frx_err  e;
        STRLEN len;
        const char *s;
    CODE:
        d = frx_doc_from_sv(aTHX_ self, ix ? "new_comment" : "new_text");
        s = frx_arg_bytes(aTHX_ text, &len);
        n = ix ? frx_new_comment(d, s, len, &e) : frx_new_text(d, s, len, &e);
        if (!n) frx_edit_croak(aTHX_ ix ? "new_comment" : "new_text", &e);
        RETVAL = frx_node_bless(aTHX_ SvRV(self), n);
    OUTPUT:
        RETVAL

SV *
new_pi(self, target, ...)
        SV *self
        SV *target
    PREINIT:
        frx_doc *d;
        frx_node *n;
        frx_err  e;
        STRLEN tlen, dlen;
        const char *t, *data;
    CODE:
        d    = frx_doc_from_sv(aTHX_ self, "new_pi");
        t    = frx_arg_bytes(aTHX_ target, &tlen);
        data = frx_arg_bytes(aTHX_ items > 2 ? ST(2) : NULL, &dlen);
        n = frx_new_pi(d, t, tlen, data, dlen, &e);
        if (!n) frx_edit_croak(aTHX_ "new_pi", &e);
        RETVAL = frx_node_bless(aTHX_ SvRV(self), n);
    OUTPUT:
        RETVAL

void
import_node(self, ...)
        SV *self
    ALIAS:
        import = 1
    PREINIT:
        frx_doc *d;
        const frx_node *src;
        frx_node *copy;
        frx_err  e;
    PPCODE:
        /* `import` is the name the family reads, and perl's own: it calls
         * __PACKAGE__->import for every `use` of this class, with the
         * class name and whatever import list follows. Neither is a
         * document, so that call is answered with nothing and only a real
         * invocant with a node does the work. The alias cannot live in
         * Document.pm: the class comes from this bundle, and the .pm is
         * loaded only if someone uses it by name. */
        PERL_UNUSED_VAR(ix);
        if (items < 2 || !SvROK(self)) XSRETURN_EMPTY;
        d    = frx_doc_from_sv(aTHX_ self, "import");
        src  = frx_node_from_sv(aTHX_ ST(1), "import", NULL);
        copy = frx_import(d, src, &e);
        if (!copy) frx_edit_croak(aTHX_ "import", &e);
        XPUSHs(sv_2mortal(frx_node_bless(aTHX_ SvRV(self), copy)));

void
errors(self)
        SV *self
    PREINIT:
        frx_doc        *d;
        const frx_verr *e;
        char            msg[512];
    PPCODE:
        /* validate => 'collect': every violation, in document order */
        d = frx_doc_from_sv(aTHX_ self, "errors");
        for (e = d->errors; e; e = e->next) {
            size_t n = frx_verr_format(e, msg, sizeof msg);
            XPUSHs(sv_2mortal(newSVpvn(msg, n)));
        }

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML

SV *
new_document(class, ...)
        const char *class
    PREINIT:
        HV *opts;
        SV **v;
        int v11 = 0;
        frx_doc *d;
    CODE:
        PERL_UNUSED_VAR(class);
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "new_document");
        if (opts && (v = hv_fetchs(opts, "version", 0))) {
            STRLEN n;
            const char *s = SvPV(*v, n);
            if (n == 3 && memcmp(s, "1.1", 3) == 0) v11 = 1;
            else if (!(n == 3 && memcmp(s, "1.0", 3) == 0))
                croak("File::Raw::XML: new_document: version must be 1.0 or 1.1");
            if (hv_iterinit(opts) > 1) croak("File::Raw::XML: new_document: the one option is version");
        } else if (opts && hv_iterinit(opts)) {
            croak("File::Raw::XML: new_document: the one option is version");
        }
        d = frx_doc_new_empty(v11);
        if (!d) croak("File::Raw::XML: new_document: out of memory");
        RETVAL = frx_doc_bless(aTHX_ d);
    OUTPUT:
        RETVAL
