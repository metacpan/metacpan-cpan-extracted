
# Private accessors for the test suite. Underscored, so pod-coverage
# ignores them; kept, because the tests need them for the life of the dist.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML

IV
_arena_selftest()
    PREINIT:
        frx_arena a;
        frx_buf   b;
        void     *first, *p;
        size_t    i;
        int       ok = 1;
    CODE:
        frx_arena_init(&a);
        frx_buf_init(&b);

        /* the first pointer is aligned and stays put across ten pages */
        first = frx_arena_alloc(&a, 24);
        if (!first || ((size_t)first & (FRX_ARENA_ALIGN - 1))) ok = 0;
        memset(first, 0xA5, 24);
        for (i = 0; ok && i < 10 * (FRX_ARENA_PAGE / 1024); i++) {
            p = frx_arena_alloc(&a, 1000);
            if (!p || ((size_t)p & (FRX_ARENA_ALIGN - 1))) ok = 0;
        }
        if (ok && a.pages < 10) ok = 0;
        if (ok && ((unsigned char *)first)[0] != 0xA5) ok = 0;
        if (ok && ((unsigned char *)first)[23] != 0xA5) ok = 0;

        /* an oversize allocation gets its own page */
        if (ok) {
            size_t before = a.pages;
            p = frx_arena_alloc(&a, FRX_ARENA_BIG + 1);
            if (!p || a.pages != before + 1) ok = 0;
            else memset(p, 0x5A, FRX_ARENA_BIG + 1);
        }

        /* a string comes back NUL-terminated with its length */
        if (ok) {
            frx_str s = frx_arena_strndup(&a, "abc\0def", 7);
            if (!s.p || s.len != 7 || s.p[7] != '\0' || memcmp(s.p, "abc\0def", 7)) ok = 0;
        }

        /* the buffer grows across its doubling boundaries and stays terminated */
        for (i = 0; ok && i < 100000; i++) frx_buf_append_ch(&b, (char)('a' + i % 26));
        frx_buf_append(&b, "!");
        if (ok && (b.failed || b.len != 100001 || b.p[b.len] != '\0'
                   || b.p[0] != 'a' || b.p[100000] != '!')) ok = 0;

        frx_buf_free(&b);
        frx_arena_free(&a);
        if (ok && (a.head || a.big || a.pages)) ok = 0;
        RETVAL = ok;
    OUTPUT:
        RETVAL

SV *
_lex(bytes, ...)
        SV *bytes
    PREINIT:
        STRLEN      len;
        const char *in;
        frx_opts    o;
        frx_arena   arena;
        frx_lex     l;
        frx_tok     t;
        AV         *rows;
        char        msg[512];
        size_t      n;
    CODE:
        /* _lex($bytes, $max_bytes = 0): every token as
         * [kind, offset, name, value-or-attrs], or a croak in the one
         * message shape. The arena is freed on both paths. */
        in = SvPVbyte(bytes, len);
        o.max_bytes  = items > 1 ? (size_t)SvUV(ST(1)) : 0;
        o.max_depth  = 0;
        o.id_attrs   = NULL;
        o.n_id_attrs = 0;
        frx_arena_init(&arena);
        rows = newAV();
        if (frx_lex_init(&l, (const unsigned char *)in, (size_t)len, &o, FRX_PROFILE_STRICT, &arena)) {
            while (frx_lex_next(&l, &t)) {
                AV *row = newAV();
                const char *kind = "?";
                switch (t.kind) {
                case FRX_TOK_START:   kind = "start";   break;
                case FRX_TOK_END:     kind = "end";     break;
                case FRX_TOK_EMPTY:   kind = "empty";   break;
                case FRX_TOK_TEXT:    kind = t.cdata ? "cdata" : "text"; break;
                case FRX_TOK_COMMENT: kind = "comment"; break;
                case FRX_TOK_PI:      kind = "pi";      break;
                }
                av_push(row, newSVpv(kind, 0));
                av_push(row, newSVuv((UV)t.offset));
                av_push(row, t.name.p ? newSVpvn(t.name.p, t.name.len) : newSV(0));
                if (t.kind == FRX_TOK_START || t.kind == FRX_TOK_EMPTY) {
                    AV *attrs = newAV();
                    int i;
                    for (i = 0; i < t.n_attrs; i++) {
                        AV *pair = newAV();
                        av_push(pair, newSVpvn(t.attrs[i].name.p, t.attrs[i].name.len));
                        av_push(pair, newSVpvn(t.attrs[i].value.p, t.attrs[i].value.len));
                        av_push(attrs, newRV_noinc((SV *)pair));
                    }
                    av_push(row, newRV_noinc((SV *)attrs));
                } else {
                    av_push(row, t.value.p ? newSVpvn(t.value.p, t.value.len) : newSV(0));
                }
                av_push(rows, newRV_noinc((SV *)row));
            }
        }
        if (l.failed) {
            n = frx_err_format(&l.err, in, (size_t)len, msg, sizeof msg);
            frx_lex_free(&l);
            frx_arena_free(&arena);
            SvREFCNT_dec((SV *)rows);
            croak("%.*s", (int)n, msg);
        }
        frx_lex_free(&l);
        frx_arena_free(&arena);
        RETVAL = newRV_noinc((SV *)rows);
    OUTPUT:
        RETVAL

SV *
_dump(bytes, ...)
        SV *bytes
    PREINIT:
        STRLEN       len;
        const char  *in;
        frx_opts     o;
        frx_err      e;
        frx_doc     *d;
        const char **names = NULL;
        int          n_names = 0;
        char         msg[512];
        size_t       n;
        AV          *root_row;
        /* an explicit stack of (node, children AV): no recursion, rule 2 */
        frx_dump_frame *stack = NULL;
        int          sp = 0, cap = 0;
    CODE:
        /* _dump($bytes, $max_depth = 0, \@id_attrs = []): the tree as
         * nested arrayrefs, or a croak in the one message shape.
         *   element:  ['element', ns, prefix, local, [[ns,prefix,local,value]...],
         *                        [[prefix,uri]...], [children...], ns_ptr]
         *   text:     ['text', value]     comment: ['comment', value]
         *   pi:       ['pi', target, data]
         *   document: ['document', [children...]] */
        in = SvPVbyte(bytes, len);
        o.max_bytes = 0;
        o.max_depth = items > 1 ? (int)SvIV(ST(1)) : 0;
        o.id_attrs  = NULL;
        o.n_id_attrs = 0;
        if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
            AV *av = (AV *)SvRV(ST(2));
            int i;
            n_names = (int)(av_len(av) + 1);
            if (n_names) {
                Newx(names, n_names, const char *);
                SAVEFREEPV(names);
                for (i = 0; i < n_names; i++) {
                    SV **e = av_fetch(av, i, 0);
                    names[i] = e ? SvPV_nolen(*e) : "";
                }
                o.id_attrs   = names;
                o.n_id_attrs = n_names;
            }
        }
        d = frx_parse_doc(in, (size_t)len, &o, &e);
        if (!d) {
            n = frx_err_format(&e, in, (size_t)len, msg, sizeof msg);
            croak("%.*s", (int)n, msg);
        }
        {
            const frx_node *cur = d->document;
            AV *doc_children = newAV();
            root_row = newAV();
            av_push(root_row, newSVpvs("document"));
            av_push(root_row, newRV_noinc((SV *)doc_children));
            cap = 16;
            Newx(stack, cap, frx_dump_frame);
            stack[0].node = cur; stack[0].children = doc_children; sp = 1;
            cur = cur->first_child;
            while (cur) {
                AV *row = newAV();
                AV *kids = NULL;
                /* pop to the row's parent */
                while (sp > 0 && stack[sp - 1].node != cur->parent) sp--;
                switch (cur->kind) {
                case FRX_ELEMENT: {
                    AV *attrs = newAV(), *decls = newAV();
                    int i;
                    kids = newAV();
                    av_push(row, newSVpvs("element"));
                    av_push(row, newSVpvn(cur->ns.p, cur->ns.len));
                    av_push(row, newSVpvn(cur->prefix.p, cur->prefix.len));
                    av_push(row, newSVpvn(cur->local.p, cur->local.len));
                    for (i = 0; i < cur->n_attrs; i++) {
                        AV *a = newAV();
                        av_push(a, newSVpvn(cur->attrs[i].ns.p, cur->attrs[i].ns.len));
                        av_push(a, newSVpvn(cur->attrs[i].prefix.p, cur->attrs[i].prefix.len));
                        av_push(a, newSVpvn(cur->attrs[i].local.p, cur->attrs[i].local.len));
                        av_push(a, newSVpvn(cur->attrs[i].value.p, cur->attrs[i].value.len));
                        av_push(attrs, newRV_noinc((SV *)a));
                    }
                    for (i = 0; i < cur->n_decls; i++) {
                        AV *a = newAV();
                        av_push(a, newSVpvn(cur->decls[i].prefix.p, cur->decls[i].prefix.len));
                        av_push(a, newSVpvn(cur->decls[i].uri.p, cur->decls[i].uri.len));
                        av_push(decls, newRV_noinc((SV *)a));
                    }
                    av_push(row, newRV_noinc((SV *)attrs));
                    av_push(row, newRV_noinc((SV *)decls));
                    av_push(row, newRV_noinc((SV *)kids));
                    av_push(row, newSViv(PTR2IV(cur->ns.p)));
                    break;
                }
                case FRX_TEXT:
                    av_push(row, newSVpvs("text"));
                    av_push(row, newSVpvn(cur->value.p, cur->value.len));
                    break;
                case FRX_COMMENT:
                    av_push(row, newSVpvs("comment"));
                    av_push(row, newSVpvn(cur->value.p, cur->value.len));
                    break;
                case FRX_PI:
                    av_push(row, newSVpvs("pi"));
                    av_push(row, newSVpvn(cur->local.p, cur->local.len));
                    av_push(row, newSVpvn(cur->value.p, cur->value.len));
                    break;
                default:
                    av_push(row, newSVpvs("?"));
                    break;
                }
                av_push(stack[sp - 1].children, newRV_noinc((SV *)row));
                if (kids) {
                    if (sp == cap) { cap *= 2; Renew(stack, cap, frx_dump_frame); }
                    stack[sp].node = cur; stack[sp].children = kids; sp++;
                }
                cur = frx_walk_next(cur, d->document);
            }
            Safefree(stack);
        }
        frx_doc_free(d);
        RETVAL = newRV_noinc((SV *)root_row);
    OUTPUT:
        RETVAL

SV *
_by_id(bytes, id_attrs, attr, value)
        SV         *bytes
        SV         *id_attrs
        const char *attr
        SV         *value
    PREINIT:
        STRLEN       len, vlen;
        const char  *in, *v;
        frx_opts     o;
        frx_err      e;
        frx_doc     *d;
        const char **names = NULL;
        int          n_names = 0, i;
        const frx_node *hit;
        char         msg[512];
        size_t       n;
    CODE:
        /* _by_id($bytes, \@id_attrs, $attr, $value): [qname, offset] or undef */
        in = SvPVbyte(bytes, len);
        v  = SvPVbyte(value, vlen);
        o.max_bytes = 0; o.max_depth = 0; o.id_attrs = NULL; o.n_id_attrs = 0;
        if (SvROK(id_attrs) && SvTYPE(SvRV(id_attrs)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(id_attrs);
            n_names = (int)(av_len(av) + 1);
            if (n_names) {
                Newx(names, n_names, const char *);
                SAVEFREEPV(names);
                for (i = 0; i < n_names; i++) {
                    SV **el = av_fetch(av, i, 0);
                    names[i] = el ? SvPV_nolen(*el) : "";
                }
                o.id_attrs = names; o.n_id_attrs = n_names;
            }
        }
        d = frx_parse_doc(in, (size_t)len, &o, &e);
        if (!d) {
            n = frx_err_format(&e, in, (size_t)len, msg, sizeof msg);
            croak("%.*s", (int)n, msg);
        }
        hit = frx_by_id(d, attr, v, (size_t)vlen);
        if (hit) {
            AV *row = newAV();
            av_push(row, newSVpvn(hit->qname.p, hit->qname.len));
            av_push(row, newSVuv((UV)hit->offset));
            RETVAL = newRV_noinc((SV *)row);
        } else {
            RETVAL = newSV(0);
        }
        frx_doc_free(d);
    OUTPUT:
        RETVAL

SV *
_walk(bytes, ns, local)
        SV *bytes
        SV *ns
        const char *local
    PREINIT:
        STRLEN       len;
        const char  *in, *nsp;
        frx_err      e;
        frx_doc     *d;
        const frx_node *c;
        HV          *out;
        AV          *found, *desc;
        frx_buf      text;
        char         msg[512];
        size_t       n;
    CODE:
        /* _walk($bytes, $ns, $local): { find => [qnames of the root's direct
         * children matching], descendants => [every descendant element's
         * qname in document order], text => the root's text }. ns undef is
         * any namespace, '' is none: the ABI's NULL versus "". */
        in  = SvPVbyte(bytes, len);
        nsp = SvOK(ns) ? SvPV_nolen(ns) : NULL;
        d = frx_parse_doc(in, (size_t)len, NULL, &e);
        if (!d) {
            n = frx_err_format(&e, in, (size_t)len, msg, sizeof msg);
            croak("%.*s", (int)n, msg);
        }
        out   = newHV();
        found = newAV();
        desc  = newAV();
        for (c = frx_find(d->root, nsp, local, NULL); c; c = frx_find(d->root, nsp, local, c))
            av_push(found, newSVpvn(c->qname.p, c->qname.len));
        for (c = d->root->first_child; c; c = frx_walk_next(c, d->root))
            if (c->kind == FRX_ELEMENT) av_push(desc, newSVpvn(c->qname.p, c->qname.len));
        frx_buf_init(&text);
        frx_text(d->root, &text);
        {
            /* attr => the root's attribute value for (ns, local), or undef */
            const frx_str *v = frx_attr_value(d->root, nsp, local);
            (void)hv_stores(out, "attr", v ? newSVpvn(v->p, v->len) : newSV(0));
        }
        (void)hv_stores(out, "find", newRV_noinc((SV *)found));
        (void)hv_stores(out, "descendants", newRV_noinc((SV *)desc));
        (void)hv_stores(out, "text", newSVpvn(text.p ? text.p : "", text.len));
        (void)hv_stores(out, "n_ids", newSViv(d->n_ids));
        frx_buf_free(&text);
        frx_doc_free(d);
        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

SV *
_join_base(base, ref)
        SV *base
        SV *ref
    PREINIT:
        STRLEN blen, rlen;
        const char *b, *r;
        frx_buf out;
    CODE:
        /* join-URI-References(base, ref), Canonical XML 1.1 section 2.4 */
        b = SvPVbyte(base, blen);
        r = SvPVbyte(ref, rlen);
        frx_buf_init(&out);
        if (!frx_join_base(&out, b, (size_t)blen, r, (size_t)rlen)) {
            frx_buf_free(&out);
            croak("File::Raw::XML: _join_base: out of memory");
        }
        RETVAL = newSVpvn(out.p ? out.p : "", out.len);
        frx_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_err_format(what, offset, bytes)
        const char *what
        UV          offset
        SV         *bytes
    PREINIT:
        STRLEN      len;
        const char *in;
        char        out[512];
        frx_err     e;
        size_t      n;
    CODE:
        in = SvPVbyte(bytes, len);
        frx_err_set(&e, FRX_E_SYNTAX, (size_t)offset, what);
        n = frx_err_format(&e, in, (size_t)len, out, sizeof out);
        RETVAL = newSVpvn(out, n);
    OUTPUT:
        RETVAL
