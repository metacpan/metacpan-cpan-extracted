#ifndef FRX_PLUGIN_H
#define FRX_PLUGIN_H

/* The File::Raw plugin: file_slurp($path, plugin => 'xml', %opts) and
 * each_line($path, $cb, plugin => 'xml', record => [$ns, $local], %opts).
 *
 * READ parses the file's bytes under the per-call options and returns
 * the same blessed document the direct codec returns. STREAM feeds each
 * chunk File::Raw reads to a reader (frx_reader.h) and, for every element
 * whose namespace and local name match `record`, cuts that element out
 * as a Document of its own and calls the callback with it, so a file of
 * any size is read at the memory cost of one record. An element whose
 * end the chunk does not reach stays in capture across chunks. `record`
 * is required for the stream phase: without one there is nothing to
 * emit, and the refusal says so. WRITE serialises a Document with
 * frx_write.h under the same options to_string takes. RECORD is NULL.
 *
 * The FilePlugin is a file-scope static: File::Raw's registry stores the
 * pointer, not a copy (file_plugin.h). Its fields carry the _fn suffix
 * because plain read and write collide with Perl's host-IO macros on
 * Win32, which is why the struct is spelled that way upstream.
 *
 * Ownership, from file.c's dispatch: a plugin that replaces the bytes
 * returns a fresh SV at +1 and File::Raw mortalises it; NULL is "no
 * result" and becomes undef without being mortalised, which is why the
 * no-data case returns NULL rather than the immortal undef. The stream
 * state lives in ctx->call_state for the dispatch and is freed here at
 * the end or before any croak, since File::Raw does not free it.
 *
 * ctx->data is the file's bytes, raw; ctx->options is the per-call HV,
 * which File::Raw has built with `plugin` in it - frx_opts_from_hv knows
 * to skip that key, and `record` too when there is a path.
 *
 * Needs file_plugin.h, frx_obj.h. */

static SV *
frx_read(pTHX_ FilePluginContext *ctx)
{
    STRLEN      len;
    const char *in;
    if (!ctx->data) return NULL;
    in = SvPV(ctx->data, len);
    return frx_parse_to_sv(aTHX_ in, len, ctx->options, ctx->path);
}

typedef struct frx_stream_state {
    frx_reader_xs *x;
    char *rec_ns;               /* NULL: any namespace */
    char *rec_local;
} frx_stream_state;

static void
frx_stream_free(pTHX_ frx_stream_state *st)
{
    if (!st) return;
    frx_reader_xs_free(aTHX_ st->x);
    free(st->rec_ns);
    free(st->rec_local);
    free(st);
}

static frx_stream_state *
frx_stream_new(pTHX_ FilePluginContext *ctx)
{
    frx_stream_state *st;
    SV **rec = hv_fetchs(ctx->options, "record", 0);
    AV  *av;
    SV **e;
    if (!rec || !SvROK(*rec) || SvTYPE(SvRV(*rec)) != SVt_PVAV || av_len((AV *)SvRV(*rec)) != 1)
        croak("File::Raw::XML: the xml plugin streams records: pass record => [$ns, $local], "
              "with undef for any namespace and '' for none");
    av = (AV *)SvRV(*rec);
    st = (frx_stream_state *)malloc(sizeof *st);
    if (!st) croak("File::Raw::XML: out of memory");
    memset(st, 0, sizeof *st);
    e = av_fetch(av, 0, 0);
    if (e && SvOK(*e)) st->rec_ns = frx_strdup(SvPV_nolen(*e));
    e = av_fetch(av, 1, 0);
    if (!e || !SvOK(*e)) { free(st->rec_ns); free(st); croak("File::Raw::XML: record needs a local name"); }
    st->rec_local = frx_strdup(SvPV_nolen(*e));
    st->x = frx_reader_xs_new(aTHX_ ctx->options, ctx->path);
    return st;
}

static int
frx_stream_matches(const frx_stream_state *st, const frx_event *e)
{
    if (e->kind != FRX_START) return 0;
    if (!frx_str_eq(&e->local, st->rec_local, strlen(st->rec_local))) return 0;
    if (st->rec_ns && !frx_str_eq(&e->ns, st->rec_ns, strlen(st->rec_ns))) return 0;
    return 1;
}

/* a finished record to the callback; a die inside it ends the stream */
static void
frx_stream_emit(pTHX_ FilePluginContext *ctx, frx_stream_state *st, frx_doc *d)
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(frx_doc_bless(aTHX_ d)));
    PUTBACK;
    call_sv(ctx->callback, G_VOID | G_DISCARD | G_EVAL);
    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (SvTRUE(ERRSV)) {
        SV *err = sv_2mortal(newSVsv(ERRSV));
        ctx->call_state = NULL;
        frx_stream_free(aTHX_ st);
        croak_sv(err);
    }
}

static int
frx_stream(pTHX_ FilePluginContext *ctx, const char *chunk, size_t len, int eof)
{
    frx_stream_state *st = (frx_stream_state *)ctx->call_state;
    frx_reader *r;
    if (!st) {
        st = frx_stream_new(aTHX_ ctx);
        ctx->call_state = st;
    }
    r = &st->x->r;
    if (!frx_reader_feed(r, chunk ? chunk : "", len, eof)) {
        ctx->call_state = NULL;
        frx_stream_free(aTHX_ st);
        frx_reader_croak(aTHX_ st->x);
    }
    for (;;) {
        frx_event ev;
        int rc;
        if (r->capturing) {
            frx_doc *d = NULL;
            rc = frx_reader_subtree(r, &d);
            if (r->failed) { ctx->call_state = NULL; frx_stream_free(aTHX_ st); frx_reader_croak(aTHX_ st->x); }
            if (!rc) return 0;                      /* more bytes wanted */
            frx_stream_emit(aTHX_ ctx, st, d);
            if (ctx->cancel) break;
            continue;
        }
        rc = frx_reader_next(r, &ev);
        if (r->failed) { ctx->call_state = NULL; frx_stream_free(aTHX_ st); frx_reader_croak(aTHX_ st->x); }
        if (rc == 0) return 0;                      /* more bytes wanted */
        if (rc < 0) break;                          /* the document ended */
        if (frx_stream_matches(st, &ev)) {
            frx_doc *d = NULL;
            rc = frx_reader_subtree(r, &d);
            if (r->failed) { ctx->call_state = NULL; frx_stream_free(aTHX_ st); frx_reader_croak(aTHX_ st->x); }
            if (!rc) return 0;
            frx_stream_emit(aTHX_ ctx, st, d);
            if (ctx->cancel) break;
        }
    }
    ctx->call_state = NULL;
    frx_stream_free(aTHX_ st);
    return 0;
}

/* WRITE: file_spew($path, $doc, plugin => 'xml', %opts): the document's
 * markup under the writer's options; File::Raw writes the bytes to a
 * temporary file beside the path and renames it into place */
static SV *
frx_write_hook(pTHX_ FilePluginContext *ctx)
{
    frx_doc        *d;
    frx_write_opts  o;
    int             perl_chars = 0;
    if (!ctx->data || !SvROK(ctx->data))
        croak("File::Raw::XML: file_spew with the xml plugin takes a File::Raw::XML::Document");
    d = frx_doc_from_sv(aTHX_ ctx->data, "file_spew");
    frx_write_opts_from_hv(aTHX_ ctx->options, &o, &perl_chars, "file_spew", 1);
    if (perl_chars)
        croak("File::Raw::XML: file_spew: encoding => 'perl' is for to_string; a file takes bytes");
    return frx_write_sv(aTHX_ d->document, d, &o, 0, "file_spew");
}

static FilePlugin frx_plugin;     /* filled at BOOT; the registry keeps the pointer */

static void
frx_plugin_register(pTHX)
{
    frx_plugin.name      = "xml";
    frx_plugin.read_fn   = frx_read;
    frx_plugin.write_fn  = frx_write_hook;
    frx_plugin.record_fn = NULL;
    frx_plugin.stream_fn = frx_stream;
    frx_plugin.state     = NULL;
    if (file_register_plugin(aTHX_ &frx_plugin) != 1)
        warn("File::Raw::XML: failed to register the 'xml' plugin with File::Raw");
}

#endif /* FRX_PLUGIN_H */
