
# File::Raw::XML::Node: every kind, distinguished by kind. Each method is
# a wrapper over a core tree function; the namespace argument is undef for
# any and '' for none, the ABI's NULL versus "".

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Node

IV
kind(self)
        SV *self
    CODE:
        RETVAL = frx_node_from_sv(aTHX_ self, "kind", NULL)->kind;
    OUTPUT:
        RETVAL

SV *
ns(self)
        SV *self
    ALIAS:
        prefix = 1
        local  = 2
        name   = 3
    PREINIT:
        const frx_node *n;
        const char *meth[] = { "ns", "prefix", "local", "name" };
    CODE:
        n = frx_node_from_sv(aTHX_ self, meth[ix], NULL);
        switch (ix) {
        case 1:  RETVAL = frx_str_sv(aTHX_ &n->prefix); break;
        case 2:  RETVAL = frx_str_sv(aTHX_ &n->local);  break;
        case 3:  RETVAL = frx_str_sv(aTHX_ &n->qname);  break;
        default: RETVAL = frx_str_sv(aTHX_ &n->ns);     break;
        }
    OUTPUT:
        RETVAL

SV *
attr(self, local)
        SV         *self
        const char *local
    PREINIT:
        const frx_node *n;
        const frx_str  *v;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "attr", NULL);
        v = frx_attr_value(n, NULL, local);
        RETVAL = v ? frx_str_sv(aTHX_ v) : newSV(0);
    OUTPUT:
        RETVAL

SV *
attr_ns(self, ns, local)
        SV         *self
        SV         *ns
        const char *local
    PREINIT:
        const frx_node *n;
        const frx_str  *v;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "attr_ns", NULL);
        v = frx_attr_value(n, frx_ns_arg(aTHX_ ns), local);
        RETVAL = v ? frx_str_sv(aTHX_ v) : newSV(0);
    OUTPUT:
        RETVAL

SV *
attrs(self)
        SV *self
    PREINIT:
        const frx_node *n;
        AV *out;
        int i;
    CODE:
        n   = frx_node_from_sv(aTHX_ self, "attrs", NULL);
        out = newAV();
        for (i = 0; i < n->n_attrs; i++) {
            AV *a = newAV();
            av_push(a, frx_str_sv(aTHX_ &n->attrs[i].ns));
            av_push(a, frx_str_sv(aTHX_ &n->attrs[i].prefix));
            av_push(a, frx_str_sv(aTHX_ &n->attrs[i].local));
            av_push(a, frx_str_sv(aTHX_ &n->attrs[i].value));
            av_push(out, newRV_noinc((SV *)a));
        }
        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

void
children(self)
        SV *self
    ALIAS:
        elements = 1
    PREINIT:
        const frx_node *n, *c;
        SV *doc_iv;
    PPCODE:
        n = frx_node_from_sv(aTHX_ self, ix ? "elements" : "children", &doc_iv);
        for (c = n->first_child; c; c = c->next) {
            if (ix && c->kind != FRX_ELEMENT) continue;
            XPUSHs(sv_2mortal(frx_node_bless(aTHX_ doc_iv, c)));
        }

void
find(self, ns, local)
        SV         *self
        SV         *ns
        const char *local
    PREINIT:
        const frx_node *n, *c;
        SV *doc_iv;
        const char *nsp;
    PPCODE:
        n   = frx_node_from_sv(aTHX_ self, "find", &doc_iv);
        nsp = frx_ns_arg(aTHX_ ns);
        for (c = frx_find(n, nsp, local, NULL); c; c = frx_find(n, nsp, local, c))
            XPUSHs(sv_2mortal(frx_node_bless(aTHX_ doc_iv, c)));

void
descendants(self, ns, local)
        SV         *self
        SV         *ns
        const char *local
    PREINIT:
        const frx_node *n, *c;
        SV *doc_iv;
        const char *nsp;
    PPCODE:
        n   = frx_node_from_sv(aTHX_ self, "descendants", &doc_iv);
        nsp = frx_ns_arg(aTHX_ ns);
        for (c = n->first_child; c; c = frx_walk_next(c, n))
            if (frx_node_matches(c, nsp, local))
                XPUSHs(sv_2mortal(frx_node_bless(aTHX_ doc_iv, c)));

SV *
text(self)
        SV *self
    PREINIT:
        const frx_node *n;
        frx_buf b;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "text", NULL);
        frx_buf_init(&b);
        frx_text(n, &b);
        if (b.failed) { frx_buf_free(&b); croak("File::Raw::XML: text: out of memory"); }
        RETVAL = newSVpvn(b.p ? b.p : "", b.len);
        SvUTF8_on(RETVAL);
        frx_buf_free(&b);
    OUTPUT:
        RETVAL

SV *
parent(self)
        SV *self
    PREINIT:
        const frx_node *n;
        SV *doc_iv;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "parent", &doc_iv);
        RETVAL = n->parent ? frx_node_bless(aTHX_ doc_iv, n->parent) : newSV(0);
    OUTPUT:
        RETVAL

SV *
doc(self)
        SV *self
    PREINIT:
        SV *doc_iv;
    CODE:
        (void)frx_node_from_sv(aTHX_ self, "doc", &doc_iv);
        RETVAL = frx_node_doc_rv(aTHX_ doc_iv);
    OUTPUT:
        RETVAL

SV *
to_string(self, ...)
        SV *self
    PREINIT:
        const frx_node *n;
        SV             *doc_iv;
        HV             *opts;
        frx_write_opts  o;
        int             perl_chars;
    CODE:
        n    = frx_node_from_sv(aTHX_ self, "to_string", &doc_iv);
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "to_string");
        frx_write_opts_from_hv(aTHX_ opts, &o, &perl_chars, "to_string", 0);
        RETVAL = frx_write_sv(aTHX_ n, frx_doc_from_iv(aTHX_ doc_iv), &o, perl_chars, "to_string");
    OUTPUT:
        RETVAL

SV *
c14n(self, ...)
        SV *self
    PREINIT:
        const frx_node *n;
        SV       *doc_iv;
        HV       *opts;
        frx_c14n  c;
    CODE:
        n    = frx_node_from_sv(aTHX_ self, "c14n", &doc_iv);
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "c14n");
        frx_c14n_opts(aTHX_ opts, doc_iv, &c, "c14n");
        RETVAL = frx_c14n_sv(aTHX_ n, &c, "c14n");
    OUTPUT:
        RETVAL

# ---- editing: every method returns the node it acted on or made

SV *
append(self, child)
        SV *self
        SV *child
    ALIAS:
        insert_before = 1
    PREINIT:
        frx_node *n, *c;
        SV *doc_iv;
        frx_doc *d;
        frx_err e;
        int ok;
    CODE:
        n = (frx_node *)frx_node_from_sv(aTHX_ self, ix ? "insert_before" : "append", &doc_iv);
        d = frx_doc_from_iv(aTHX_ doc_iv);
        c = frx_node_arg(aTHX_ child, doc_iv, ix ? "insert_before" : "append");
        ok = ix ? frx_insert_before(d, n, c, &e) : frx_append_child(d, n, c, &e);
        if (!ok) frx_edit_croak(aTHX_ ix ? "insert_before" : "append", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, c);
    OUTPUT:
        RETVAL

SV *
detach(self)
        SV *self
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
    CODE:
        n = (frx_node *)frx_node_from_sv(aTHX_ self, "detach", &doc_iv);
        if (!frx_remove(frx_doc_from_iv(aTHX_ doc_iv), n, &e)) frx_edit_croak(aTHX_ "detach", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

SV *
set_attr(self, ns, name, value)
        SV *self
        SV *ns
        SV *name
        SV *value
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
        STRLEN nslen, nlen, plen, llen, vlen;
        const char *nsp, *namep, *prefix, *local, *v;
    CODE:
        n     = (frx_node *)frx_node_from_sv(aTHX_ self, "set_attr", &doc_iv);
        nsp   = frx_arg_bytes(aTHX_ ns, &nslen);
        namep = frx_arg_bytes(aTHX_ name, &nlen);
        v     = frx_arg_bytes(aTHX_ value, &vlen);
        frx_split_arg(namep, nlen, &prefix, &plen, &local, &llen);
        if (!frx_set_attr(frx_doc_from_iv(aTHX_ doc_iv), n, nsp, nslen, prefix, plen, local, llen, v, vlen, &e))
            frx_edit_croak(aTHX_ "set_attr", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

SV *
remove_attr(self, ns, local)
        SV *self
        SV *ns
        SV *local
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
        STRLEN nslen, llen;
        const char *nsp, *l;
    CODE:
        n   = (frx_node *)frx_node_from_sv(aTHX_ self, "remove_attr", &doc_iv);
        nsp = frx_arg_bytes(aTHX_ ns, &nslen);
        l   = frx_arg_bytes(aTHX_ local, &llen);
        if (!frx_remove_attr(frx_doc_from_iv(aTHX_ doc_iv), n, nsp, nslen, l, llen, &e))
            frx_edit_croak(aTHX_ "remove_attr", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

SV *
set_text(self, text)
        SV *self
        SV *text
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
        STRLEN len;
        const char *s;
    CODE:
        n = (frx_node *)frx_node_from_sv(aTHX_ self, "set_text", &doc_iv);
        s = frx_arg_bytes(aTHX_ text, &len);
        if (!frx_set_text(frx_doc_from_iv(aTHX_ doc_iv), n, s, len, &e)) frx_edit_croak(aTHX_ "set_text", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

SV *
declare_ns(self, prefix, uri)
        SV *self
        SV *prefix
        SV *uri
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
        STRLEN plen, ulen;
        const char *p, *u;
    CODE:
        n = (frx_node *)frx_node_from_sv(aTHX_ self, "declare_ns", &doc_iv);
        p = frx_arg_bytes(aTHX_ prefix, &plen);
        u = frx_arg_bytes(aTHX_ uri, &ulen);
        if (!frx_declare_ns(frx_doc_from_iv(aTHX_ doc_iv), n, p, plen, u, ulen, &e)) frx_edit_croak(aTHX_ "declare_ns", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

SV *
set_name(self, ns, name)
        SV *self
        SV *ns
        SV *name
    PREINIT:
        frx_node *n;
        SV *doc_iv;
        frx_err e;
        STRLEN nslen, nlen, plen, llen;
        const char *nsp, *namep, *prefix, *local;
    CODE:
        n     = (frx_node *)frx_node_from_sv(aTHX_ self, "set_name", &doc_iv);
        nsp   = frx_arg_bytes(aTHX_ ns, &nslen);
        namep = frx_arg_bytes(aTHX_ name, &nlen);
        frx_split_arg(namep, nlen, &prefix, &plen, &local, &llen);
        if (!frx_set_name(frx_doc_from_iv(aTHX_ doc_iv), n, nsp, nslen, prefix, plen, local, llen, &e))
            frx_edit_croak(aTHX_ "set_name", &e);
        RETVAL = frx_node_bless(aTHX_ doc_iv, n);
    OUTPUT:
        RETVAL

# ---- the xml: attributes ---------------------------------------------------

SV *
base_uri(self)
        SV *self
    PREINIT:
        const frx_node *n;
        SV      *doc_iv;
        frx_buf  b;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "base_uri", &doc_iv);
        frx_buf_init(&b);
        if (!frx_node_base_uri(n, frx_doc_from_iv(aTHX_ doc_iv), &b)) {
            frx_buf_free(&b);
            croak("File::Raw::XML: base_uri: out of memory");
        }
        RETVAL = newSVpvn(b.p ? b.p : "", b.len);
        SvUTF8_on(RETVAL);
        frx_buf_free(&b);
    OUTPUT:
        RETVAL

SV *
lang(self)
        SV *self
    PREINIT:
        const frx_node *n;
        frx_str v;
    CODE:
        n = frx_node_from_sv(aTHX_ self, "lang", NULL);
        v = frx_node_lang(n);
        RETVAL = v.len ? frx_str_sv(aTHX_ &v) : newSV(0);
    OUTPUT:
        RETVAL

SV *
space(self)
        SV *self
    CODE:
        RETVAL = newSVpv(frx_node_space(frx_node_from_sv(aTHX_ self, "space", NULL)), 0);
    OUTPUT:
        RETVAL
