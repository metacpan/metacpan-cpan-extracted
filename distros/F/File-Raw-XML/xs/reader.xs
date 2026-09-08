
# File::Raw::XML::Reader: the pull reader. Bytes in through feed or from
# the file from_file opened, one event at a time out through next, the
# accessors over the current event.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML::Reader

SV *
new(class, ...)
        const char *class
    PREINIT:
        HV *opts;
        frx_reader_xs *x;
    CODE:
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "new");
        x = frx_reader_xs_new(aTHX_ opts, NULL);
        RETVAL = frx_reader_bless(aTHX_ x, class);
    OUTPUT:
        RETVAL

void
feed(self, bytes, ...)
        SV *self
        SV *bytes
    PREINIT:
        frx_reader_xs *x;
        STRLEN len;
        const char *in;
        int eof;
    PPCODE:
        x   = frx_reader_from_sv(aTHX_ self, "feed");
        in  = frx_input(aTHX_ bytes, &len);
        eof = items > 2 && SvTRUE(ST(2));
        if (!frx_reader_feed(&x->r, in, (size_t)len, eof)) frx_reader_croak(aTHX_ x);
        XSRETURN_EMPTY;

SV *
from_file(class, path, ...)
        const char *class
        const char *path
    PREINIT:
        HV *opts;
        frx_reader_xs *x;
        IV h;
    CODE:
        opts = frx_opts_hv(aTHX_ &ST(0), 2, items, "from_file");
        x = frx_reader_xs_new(aTHX_ opts, NULL);
        h = file_chunk_open(aTHX_ path, FRX_READER_CHUNK);
        if (h < 0) {
            int e = errno;
            frx_reader_xs_free(aTHX_ x);
            croak("File::Raw::XML::Reader: cannot open %s: %s", path, Strerror(e));
        }
        x->chunk = h;
        RETVAL = frx_reader_bless(aTHX_ x, class);
    OUTPUT:
        RETVAL

SV *
next(self)
        SV *self
    PREINIT:
        frx_reader_xs *x;
        frx_event ev;
        int rc;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "next");
        /* An event, or the end of the document, or "more bytes". A reader
         * with a file behind it answers the third itself: it pulls the
         * next chunk through File::Raw and feeds it, here, without going
         * back out to Perl. A reader fed by hand returns 0 and its caller
         * feeds. */
        for (;;) {
            const char *buf;
            IV n;

            rc = frx_reader_next(&x->r, &ev);
            if (x->r.failed) frx_reader_croak(aTHX_ x);
            if (rc == -2) croak("File::Raw::XML: next: a subtree is being captured; feed and call subtree again");
            if (rc != 0 || x->chunk < 0) break;

            n = file_chunk_read(aTHX_ x->chunk, &buf);
            if (n < 0) {
                int e = errno;
                file_chunk_close(aTHX_ x->chunk);
                x->chunk = -1;
                croak("File::Raw::XML::Reader: read failed: %s", Strerror(e));
            }
            if (!frx_reader_feed(&x->r, n ? buf : "", (size_t)n, n == 0))
                frx_reader_croak(aTHX_ x);
            if (n == 0) {                       /* the file is spent */
                file_chunk_close(aTHX_ x->chunk);
                x->chunk = -1;
            }
        }
        RETVAL = rc > 0 ? newSViv(ev.kind) : rc == 0 ? newSViv(0) : newSV(0);
    OUTPUT:
        RETVAL

SV *
kind(self)
        SV *self
    ALIAS:
        depth  = 1
        offset = 2
        empty  = 3
        done   = 4
    PREINIT:
        frx_reader_xs *x;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "kind");
        if (ix == 4) { RETVAL = newSViv(x->r.done ? 1 : 0); }
        else if (!x->r.have_cur) { RETVAL = newSV(0); }
        else if (ix == 0) RETVAL = newSViv(x->r.cur.kind);
        else if (ix == 1) RETVAL = newSViv(x->r.cur.kind == FRX_START ? x->r.cur.depth + 1 : x->r.cur.depth);
        else if (ix == 2) RETVAL = newSVuv((UV)x->r.cur.offset);
        else              RETVAL = newSViv(x->r.cur.empty ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
name(self)
        SV *self
    ALIAS:
        local  = 1
        ns     = 2
        prefix = 3
        value  = 4
        target = 5
        entity = 6
    PREINIT:
        frx_reader_xs *x;
        const frx_event *e;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "name");
        e = &x->r.cur;
        if (!x->r.have_cur) RETVAL = newSV(0);
        else switch (ix) {
        case 0:  RETVAL = frx_str_sv(aTHX_ &e->qname);  break;
        case 1:  RETVAL = frx_str_sv(aTHX_ &e->local);  break;
        case 2:  RETVAL = frx_str_sv(aTHX_ &e->ns);     break;
        case 3:  RETVAL = frx_str_sv(aTHX_ &e->prefix); break;
        case 4:  RETVAL = frx_str_sv(aTHX_ &e->value);  break;
        case 5:  RETVAL = e->kind == FRX_PI ? frx_str_sv(aTHX_ &e->local) : newSV(0); break;
        default: RETVAL = e->entity.len ? frx_str_sv(aTHX_ &e->entity) : newSV(0); break;
        }
    OUTPUT:
        RETVAL

SV *
attrs(self)
        SV *self
    PREINIT:
        frx_reader_xs *x;
        AV *out;
        int i;
    CODE:
        x   = frx_reader_from_sv(aTHX_ self, "attrs");
        out = newAV();
        if (x->r.have_cur) {
            for (i = 0; i < x->r.cur.n_attrs; i++) {
                const frx_attr *a = &x->r.cur.attrs[i];
                AV *row = newAV();
                av_push(row, frx_str_sv(aTHX_ &a->ns));
                av_push(row, frx_str_sv(aTHX_ &a->prefix));
                av_push(row, frx_str_sv(aTHX_ &a->local));
                av_push(row, frx_str_sv(aTHX_ &a->value));
                av_push(out, newRV_noinc((SV *)row));
            }
        }
        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

SV *
attr(self, local)
        SV *self
        const char *local
    PREINIT:
        frx_reader_xs *x;
        int i;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "attr");
        RETVAL = newSV(0);
        if (x->r.have_cur) {
            for (i = 0; i < x->r.cur.n_attrs; i++) {
                const frx_attr *a = &x->r.cur.attrs[i];
                if (frx_str_eq(&a->local, local, strlen(local))) { RETVAL = frx_str_sv(aTHX_ &a->value); break; }
            }
        }
    OUTPUT:
        RETVAL

SV *
attr_ns(self, ns, local)
        SV *self
        SV *ns
        const char *local
    PREINIT:
        frx_reader_xs *x;
        const char *nsp;
        int i;
    CODE:
        x   = frx_reader_from_sv(aTHX_ self, "attr_ns");
        nsp = frx_ns_arg(aTHX_ ns);
        RETVAL = newSV(0);
        if (x->r.have_cur) {
            for (i = 0; i < x->r.cur.n_attrs; i++) {
                const frx_attr *a = &x->r.cur.attrs[i];
                if (!frx_str_eq(&a->local, local, strlen(local))) continue;
                if (nsp && !frx_str_eq(&a->ns, nsp, strlen(nsp))) continue;
                RETVAL = frx_str_sv(aTHX_ &a->value);
                break;
            }
        }
    OUTPUT:
        RETVAL

SV *
doctype(self)
        SV *self
    PREINIT:
        frx_reader_xs *x;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "doctype");
        RETVAL = frx_doctype_sv(aTHX_ x->r.have_cur && x->r.cur.kind == FRX_DOCTYPE ? x->r.cur.doctype : x->r.p.doctype);
    OUTPUT:
        RETVAL

SV *
subtree(self)
        SV *self
    PREINIT:
        frx_reader_xs *x;
        frx_doc *d = NULL;
        int rc;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "subtree");
        /* The same pull loop next has, for the same reason. A reader with
         * a file behind it answers "more bytes" itself: its caller has no
         * feed to call, and next refuses while a capture is open, so
         * without this an element that straddles a chunk boundary could
         * never complete - subtree would answer undef for ever. */
        for (;;) {
            const char *buf;
            IV n;

            rc = frx_reader_subtree(&x->r, &d);
            if (x->r.failed) frx_reader_croak(aTHX_ x);
            if (rc == -2) croak("File::Raw::XML: subtree needs a start event");
            if (rc != 0 || x->chunk < 0) break;

            n = file_chunk_read(aTHX_ x->chunk, &buf);
            if (n < 0) {
                int e = errno;
                file_chunk_close(aTHX_ x->chunk);
                x->chunk = -1;
                croak("File::Raw::XML::Reader: read failed: %s", Strerror(e));
            }
            if (!frx_reader_feed(&x->r, n ? buf : "", (size_t)n, n == 0))
                frx_reader_croak(aTHX_ x);
            if (n == 0) {                       /* the file is spent */
                file_chunk_close(aTHX_ x->chunk);
                x->chunk = -1;
            }
        }
        RETVAL = rc > 0 && d ? frx_doc_bless(aTHX_ d) : newSV(0);
    OUTPUT:
        RETVAL

IV
capturing(self)
        SV *self
    PREINIT:
        frx_reader_xs *x;
    CODE:
        x = frx_reader_from_sv(aTHX_ self, "capturing");
        RETVAL = x->r.capturing ? 1 : 0;
    OUTPUT:
        RETVAL
