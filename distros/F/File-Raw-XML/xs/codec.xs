
# The direct codec and the importer.

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML

void
import(...)
    PREINIT:
        HV  *caller;
        const char *pkg;
        I32  i;
        int  want_codec = 0, want_const = 0, want_events = 0;
    PPCODE:
        /* `use File::Raw::XML qw(file_xml_decode file_xml_events)`,
         * `:codec`, `:all`, `:const`. Anything else warns and is skipped,
         * as File::Raw::JSON does; a bare `use` exports nothing. */
        caller = CopSTASH(PL_curcop);
        pkg    = HvNAME(caller);
        for (i = 1; i < items; i++) {
            STRLEN n;
            const char *a = SvPV(ST(i), n);
            if ((n == 6 && memcmp(a, ":codec", 6) == 0) || (n == 4 && memcmp(a, ":all", 4) == 0)) {
                want_codec = want_events = 1;
                if (n == 4) want_const = 1;
            } else if (n == 6 && memcmp(a, ":const", 6) == 0) {
                want_const = 1;
            } else if (n == 15 && memcmp(a, "file_xml_decode", 15) == 0) {
                want_codec = 1;
            } else if (n == 15 && memcmp(a, "file_xml_events", 15) == 0) {
                want_events = 1;
            } else {
                warn("File::Raw::XML: %.*s is not exported", (int)n, a);
            }
        }
        if (want_codec) {
            CV *src = get_cv("File::Raw::XML::file_xml_decode", 0);
            SV *dst = sv_2mortal(newSVpvf("%s::file_xml_decode", pkg));
            if (!src) croak("File::Raw::XML: file_xml_decode is not loaded");
            /* newXS overwrites an existing destination CV */
            newXS(SvPV_nolen(dst), CvXSUB(src), __FILE__);
        }
        if (want_events) {
            CV *src = get_cv("File::Raw::XML::file_xml_events", 0);
            SV *dst = sv_2mortal(newSVpvf("%s::file_xml_events", pkg));
            if (!src) croak("File::Raw::XML: file_xml_events is not loaded");
            newXS(SvPV_nolen(dst), CvXSUB(src), __FILE__);
        }
        if (want_const) {
            newCONSTSUB(caller, "FRX_ELEMENT",  newSViv(FRX_ELEMENT));
            newCONSTSUB(caller, "FRX_TEXT",     newSViv(FRX_TEXT));
            newCONSTSUB(caller, "FRX_COMMENT",  newSViv(FRX_COMMENT));
            newCONSTSUB(caller, "FRX_PI",       newSViv(FRX_PI));
            newCONSTSUB(caller, "FRX_DOCUMENT", newSViv(FRX_DOCUMENT));
            newCONSTSUB(caller, "FRX_START",    newSViv(FRX_START));
            newCONSTSUB(caller, "FRX_END",      newSViv(FRX_END));
            newCONSTSUB(caller, "FRX_DOCTYPE",  newSViv(FRX_DOCTYPE));
        }
        XSRETURN_EMPTY;

SV *
file_xml_decode(bytes, ...)
        SV *bytes
    PREINIT:
        STRLEN      len;
        const char *in;
        HV         *opts;
    CODE:
        in   = frx_input(aTHX_ bytes, &len);
        opts = frx_opts_hv(aTHX_ &ST(0), 1, items, "file_xml_decode");
        RETVAL = frx_parse_to_sv(aTHX_ in, len, opts, NULL);
    OUTPUT:
        RETVAL

# The push form over the same reader: the option tail is split into the
# callbacks, indexed by the event kind they answer to, and the rest,
# which are the reader's options. The dispatch is an array index and a
# call_sv - no method call and no hash lookup per event.
void
file_xml_events(bytes, ...)
        SV *bytes
    PREINIT:
        STRLEN         len;
        const char    *in;
        HV            *opts;
        SV            *cb[FRX_EVENT_KINDS];
        frx_reader_xs *x;
        SV            *rsv;
        frx_event      ev;
        int            rc, k;
        I32            i;
    CODE:
        for (k = 0; k < FRX_EVENT_KINDS; k++) cb[k] = NULL;

        if (((items - 1) & 1) != 0)
            croak("File::Raw::XML: file_xml_events: options must be key/value pairs");

        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i < items; i += 2) {
            STRLEN      klen;
            const char *key = SvPV(ST(i), klen);
            int         kind = frx_event_kind_named(key, klen);

            if (kind < 0) {
                (void)hv_store(opts, key, (I32)klen, newSVsv(ST(i + 1)), 0);
                continue;
            }
            if (!SvROK(ST(i + 1)) || SvTYPE(SvRV(ST(i + 1))) != SVt_PVCV)
                croak("File::Raw::XML: file_xml_events: the %.*s callback is not a code reference",
                      (int)klen, key);
            cb[kind] = ST(i + 1);
        }

        in  = frx_input(aTHX_ bytes, &len);
        x   = frx_reader_xs_new(aTHX_ opts, NULL);
        rsv = sv_2mortal(frx_reader_bless(aTHX_ x, FRX_READER_CLASS));

        if (!frx_reader_feed(&x->r, in, len, 1)) frx_reader_croak(aTHX_ x);

        for (;;) {
            rc = frx_reader_next(&x->r, &ev);
            if (x->r.failed) frx_reader_croak(aTHX_ x);
            if (rc <= 0) break;     /* the document ended; every byte was fed */
            if (ev.kind < 0 || ev.kind >= FRX_EVENT_KINDS || !cb[ev.kind]) continue;

            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(rsv);
            PUTBACK;
            call_sv(cb[ev.kind], G_VOID | G_DISCARD);
            SPAGAIN;
            FREETMPS;
            LEAVE;
        }
