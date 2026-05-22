/* --- freelist for cb_queue entries + send_queue entries ---
 *
 * Both use a singly-linked-list-in-the-record-itself stash: the first
 * sizeof(void*) bytes of a released entry are repurposed as the "next
 * free" pointer. Reuse the same struct without rebuilding it from
 * scratch.
 *
 * Also lives here: the singleton sentinels (keepalive_noop_cb,
 * iter_timeout_cb) and the small helpers that munge per-query
 * settings into per-send fields.
 *
 * This file is #include'd from ClickHouse.xs as part of the single
 * translation unit; symbols stay file-local-to-the-TU.
 */

static ev_ch_cb_t *cbt_freelist = NULL;

static ev_ch_cb_t* alloc_cbt(void) {
    ev_ch_cb_t *cbt;
    if (cbt_freelist) {
        cbt = cbt_freelist;
        cbt_freelist = *(ev_ch_cb_t **)cbt;
    } else {
        Newx(cbt, 1, ev_ch_cb_t);
    }
    /* Reset all fields — freelist may have stale values. */
    cbt->cb = NULL;
    cbt->raw = 0;
    cbt->on_data = NULL;
    cbt->on_complete = NULL;
    cbt->query_timeout = 0;
    return cbt;
}

static void release_cbt(ev_ch_cb_t *cbt) {
    *(ev_ch_cb_t **)cbt = cbt_freelist;
    cbt_freelist = cbt;
}

static ev_ch_send_t *send_freelist = NULL;

/* Iterator timeout watcher cb: just break the loop the iterator drove. */
static void iter_timeout_cb(EV_P_ ev_timer *w, int revents) {
    (void)w; (void)revents;
    ev_break(EV_A, EVBREAK_ONE);
}

/* No-op CV reference used as the callback for HTTP keepalive pings;
 * initialised once at BOOT and shared by all connections. */
static SV *keepalive_noop_cb = NULL;

static ev_ch_send_t* alloc_send(void) {
    ev_ch_send_t *s;
    if (send_freelist) {
        s = send_freelist;
        send_freelist = *(ev_ch_send_t **)s;
    } else {
        Newx(s, 1, ev_ch_send_t);
    }
    s->data = NULL;
    s->data_len = 0;
    s->cb = NULL;
    s->insert_data = NULL;
    s->insert_data_len = 0;
    s->insert_av = NULL;
    s->raw = 0;
    s->on_data = NULL;
    s->on_complete = NULL;
    s->query_timeout = 0;
    s->query_id = NULL;
    return s;
}

static void release_send(ev_ch_send_t *s) {
    CLEAR_STR(s->query_id);
    *(ev_ch_send_t **)s = send_freelist;
    send_freelist = s;
}

/* Copy settings->{query_id} into s->query_id and apply query_timeout. */
static void send_apply_settings(ev_ch_send_t *s, HV *settings) {
    SV **svp = hv_fetch(settings, "query_id", 8, 0);
    if (svp && SvOK(*svp)) {
        STRLEN qlen;
        const char *qstr = SvPV(*svp, qlen);
        Newx(s->query_id, qlen + 1, char);
        Copy(qstr, s->query_id, qlen, char);
        s->query_id[qlen] = '\0';
    }
    svp = hv_fetch(settings, "query_timeout", 13, 0);
    if (svp && SvOK(*svp)) s->query_timeout = SvNV(*svp);
}

/* If settings has params => { x => 1 }, return a new HV* copy with the
 * param keys flattened to param_x => '1'. Caller owns the returned HV
 * (SvREFCNT_dec it). Returns NULL if no params key — caller continues
 * to use the original settings hashref. */
static HV* expand_params(pTHX_ HV *settings) {
    SV **svp = hv_fetch(settings, "params", 6, 0);
    if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV)
        return NULL;
    HV *phv = (HV *)SvRV(*svp);
    HV *copy = newHVhv(settings);
    HE *pe;
    hv_iterinit(phv);
    while ((pe = hv_iternext(phv))) {
        I32 pklen;
        char *pkey = hv_iterkey(pe, &pklen);
        SV *pval = hv_iterval(phv, pe);
        char *prefixed;
        Newx(prefixed, pklen + 7, char);
        Copy("param_", prefixed, 6, char);
        Copy(pkey, prefixed + 6, pklen, char);
        (void)hv_store(copy, prefixed, pklen + 6, newSVsv(pval), 0);
        Safefree(prefixed);
    }
    return copy;
}

/* Append send entry to queue and dispatch if idle. */
static void enqueue_send(ev_clickhouse_t *self, ev_ch_send_t *s) {
    ngx_queue_insert_tail(&self->send_queue, &s->queue);
    self->pending_count++;
    if (self->connected && self->callback_depth == 0)
        pipeline_advance(self);
}
