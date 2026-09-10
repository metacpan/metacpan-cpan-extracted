#ifndef FT_ALTSVC_H
#define FT_ALTSVC_H

/* ft_altsvc.h - how a client ever finds out HTTP/3 exists (RFC 7838).
 *
 * There is no h3:// scheme and no upgrade handshake. Every https:// URL
 * starts on TCP, and the ONLY thing that says the origin also answers over
 * QUIC is an Alt-Svc response header on a reply that has already come back
 * over HTTP/1.1 or HTTP/2:
 *
 *     Alt-Svc: h3=":443"; ma=86400
 *
 * So without this file the h3 client in ft_h3.h is unreachable from an
 * ordinary $ua->get - which is why the plan called it out as easy to leave
 * untested and why it is a header parser rather than anything to do with QUIC.
 *
 * The cache is per PROCESS rather than per UA, because it describes the
 * origin and not the client: two agents talking to the same server should not
 * each have to discover it. It is small, linear and bounded - a client talks
 * to a handful of origins, and an entry is 3 pointers and a time.
 *
 * NOT cached across processes. RFC 7838 permits persisting it; doing so would
 * mean a file somewhere, a format to version, and a stale entry surviving a
 * server that turned h3 off. A first connection per process paying one
 * round-trip to find out is the cheaper mistake.
 */

#include "ft_win.h"    /* ft_monotonic: Windows has no clock_gettime */

#define FT_ALTSVC_MAX 32

typedef struct ft_altsvc {
    char   *origin;      /* "host:port" as requested                */
    char   *host;        /* where h3 actually is (usually the same) */
    int     port;
    double  expires;     /* monotonic seconds; 0 = free slot        */
} ft_altsvc;

static ft_altsvc ft_altsvc_tab[FT_ALTSVC_MAX];

#define ft_altsvc_now() ft_monotonic()

static void ft_altsvc_clear_slot(ft_altsvc *e) {
    free(e->origin); free(e->host);
    e->origin = e->host = NULL;
    e->expires = 0;
}

/* The live entry for this origin, or NULL. An expired one is cleared as it is
 * found: nothing else sweeps the table, and a client that stops talking to an
 * origin should not keep its row for ever. */
static ft_altsvc *ft_altsvc_get(const char *origin) {
    double now = ft_altsvc_now();
    int i;
    for (i = 0; i < FT_ALTSVC_MAX; i++) {
        ft_altsvc *e = &ft_altsvc_tab[i];
        if (!e->origin || strcmp(e->origin, origin) != 0) continue;
        if (e->expires <= now) { ft_altsvc_clear_slot(e); return NULL; }
        return e;
    }
    return NULL;
}

static void ft_altsvc_put(const char *origin, const char *host, int port,
                          double ma) {
    int i, victim = -1;
    double oldest = 0;
    double now = ft_altsvc_now();
    for (i = 0; i < FT_ALTSVC_MAX; i++) {
        ft_altsvc *e = &ft_altsvc_tab[i];
        if (e->origin && strcmp(e->origin, origin) == 0) { victim = i; break; }
        if (!e->origin) { victim = i; break; }
        if (oldest == 0 || e->expires < oldest) { oldest = e->expires; victim = i; }
    }
    if (victim < 0) return;
    ft_altsvc_clear_slot(&ft_altsvc_tab[victim]);
    ft_altsvc_tab[victim].origin  = ft_strdup_plain(origin);
    ft_altsvc_tab[victim].host    = ft_strdup_plain(host);
    ft_altsvc_tab[victim].port    = port;
    ft_altsvc_tab[victim].expires = now + ma;
    if (!ft_altsvc_tab[victim].origin || !ft_altsvc_tab[victim].host)
        ft_altsvc_clear_slot(&ft_altsvc_tab[victim]);
}

static void ft_altsvc_forget(const char *origin) {
    int i;
    for (i = 0; i < FT_ALTSVC_MAX; i++)
        if (ft_altsvc_tab[i].origin
            && strcmp(ft_altsvc_tab[i].origin, origin) == 0)
            ft_altsvc_clear_slot(&ft_altsvc_tab[i]);
}

/* Parse one Alt-Svc field value and record what it advertises.
 *
 *     Alt-Svc: h3=":443"; ma=86400, h3-29=":443"; ma=3600
 *     Alt-Svc: clear
 *
 * Only "h3" is taken. The drafts (h3-29 and friends) name wire formats this
 * client does not implement, and treating them as h3 would mean handshaking
 * with a server that speaks something else - the failure would look like a
 * network fault rather than a version mismatch.
 *
 * An empty authority ("h3=\":443\"") means the same host on that port, which
 * is what a server almost always sends; a full one ("h3=\"other:443\"")
 * points elsewhere and is honoured as written. `ma` defaults to 24 hours per
 * RFC 7838; `clear` drops what is known. */
static void ft_altsvc_parse(const char *origin, const char *host,
                            const char *val, STRLEN len) {
    STRLEN i = 0;
    while (i < len) {
        STRLEN start, eq;
        char althost[256];
        int  altport = 0;
        double ma = 86400.0;
        int is_h3 = 0;

        while (i < len && (val[i] == ' ' || val[i] == '\t' || val[i] == ','))
            i++;
        if (i >= len) break;
        start = i;
        while (i < len && val[i] != '=' && val[i] != ',' && val[i] != ';') i++;

        if (i - start == 5 && strncasecmp(val + start, "clear", 5) == 0) {
            ft_altsvc_forget(origin);
            return;
        }
        is_h3 = (i - start == 2 && strncasecmp(val + start, "h3", 2) == 0);
        if (i >= len || val[i] != '=') {          /* no value: skip the entry */
            while (i < len && val[i] != ',') i++;
            continue;
        }
        eq = ++i;
        /* the quoted alt-authority: [host]:port */
        {
            STRLEN a = eq, aend;
            if (a < len && val[a] == '"') a++;
            aend = a;
            while (aend < len && val[aend] != '"') aend++;
            {
                STRLEN colon = aend;
                STRLEN k;
                for (k = a; k < aend; k++) if (val[k] == ':') colon = k;
                if (colon > a && colon - a < sizeof althost) {
                    memcpy(althost, val + a, colon - a);
                    althost[colon - a] = '\0';
                } else {
                    /* ":443" - the same host, a different port */
                    size_t hl = strlen(host);
                    if (hl >= sizeof althost) hl = sizeof althost - 1;
                    memcpy(althost, host, hl);
                    althost[hl] = '\0';
                }
                if (colon < aend) altport = (int)strtol(val + colon + 1, NULL, 10);
            }
            i = aend < len ? aend + 1 : len;
        }
        /* the parameters, of which only ma is read */
        while (i < len && val[i] != ',') {
            if (val[i] == ';') {
                STRLEN p = ++i;
                while (p < len && (val[p] == ' ' || val[p] == '\t')) p++;
                if (p + 3 <= len && strncasecmp(val + p, "ma=", 3) == 0)
                    ma = strtod(val + p + 3, NULL);
                i = p;
            }
            i++;
        }
        if (is_h3 && altport > 0) {
            /* ma=0 is an explicit "stop using it" and not a fresh entry */
            if (ma <= 0) ft_altsvc_forget(origin);
            else         ft_altsvc_put(origin, althost, altport, ma);
            return;
        }
    }
}

/* Look for Alt-Svc in a response header list and record what it says. Called
 * for every response that came back over TCP, which is where the header can
 * appear - a server has no reason to advertise QUIC on a QUIC connection. */
static void ft_altsvc_note(pTHX_ const char *host, int port, AV *headers) {
    char origin[300];
    SSize_t i, n;
    if (!headers) return;
    n = av_len(headers) + 1;
    snprintf(origin, sizeof origin, "%s:%d", host, port);
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(headers, i, 0);
        SV **v = av_fetch(headers, i + 1, 0);
        STRLEN kl, vl;
        const char *ks, *vs;
        if (!(k && *k && v && *v)) continue;
        ks = SvPV_const(*k, kl);
        if (kl != 7 || strncasecmp(ks, "alt-svc", 7) != 0) continue;
        vs = SvPV_const(*v, vl);
        ft_altsvc_parse(origin, host, vs, vl);
        return;
    }
}

#endif /* FT_ALTSVC_H */
