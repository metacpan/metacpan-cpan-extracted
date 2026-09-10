#ifndef FT_DNS_H
#define FT_DNS_H

/* ft_dns.h - resolving a name without stopping the loop.
 *
 * ft_h1_start used to call getaddrinfo() inline. Everything else in Fetch is
 * loop-driven, so that one call was the only thing in a request that could
 * stall every OTHER connection on the loop: a nameserver taking three seconds
 * froze a loop serving hundreds of sockets, and no amount of concurrency
 * above helped.
 *
 * ---- why a thread, and not a DNS client -----------------------------------
 *
 * Speaking DNS over UDP on the existing loop would need no thread and no new
 * link flag. It is rejected because getaddrinfo is not a DNS client, it is
 * the system's whole resolution policy: /etc/hosts, nsswitch (LDAP,
 * systemd-resolved, mDNS for .local), search domains, and RFC 6724 ordering.
 * A hand-written resolver that spoke only DNS would be asynchronous and would
 * also quietly stop resolving names that resolve today, which is a worse bug
 * than the one being fixed. Running the real call somewhere else keeps every
 * one of those semantics. It is what curl does by default too.
 *
 * ---- the shape ------------------------------------------------------------
 *
 * One detached thread per lookup, and a pipe. The thread calls getaddrinfo,
 * stores the answer in the shared struct, writes one byte and exits; the loop
 * watches the read end and picks the answer up. The byte is only the wakeup -
 * and the write is also what PUBLISHES the struct's fields to the loop
 * thread, since the read cannot complete before the write.
 *
 * THE THREAD TOUCHES NO PERL. No interpreter, no SVs, no Newx/Safefree (which
 * want an implicit context) - plain malloc and free, which is why the
 * allocations here look unlike the rest of the dist. The only calls it makes
 * are getaddrinfo, write, close and free.
 *
 * The read end belongs to the connection: it goes in c->fd while the state is
 * FT_RESOLVING, so the arming, the deadline timer and the teardown that
 * already exist all work on it unchanged, and a resolve that never answers
 * fails the request with the ordinary request timeout.
 *
 * Lifetime is a refcount of two, one per thread, taken under a mutex; whoever
 * drops the last one frees. That is what makes cancelling safe: a request torn
 * down mid-resolve drops its reference and returns immediately, and the thread
 * frees the struct when it eventually finishes and finds itself alone. Each
 * side closes only its own end of the pipe, so neither can close a descriptor
 * the other still holds - or, worse, one the kernel has since given to
 * something else.
 *
 * Without pthreads (FT_HAVE_PTHREAD unset) and on native Windows, ft_dns_start
 * returns 0 and the caller resolves inline, exactly as before. That is a
 * degradation in concurrency, never in correctness.
 */

#if defined(FT_HAVE_PTHREAD) && !defined(_WIN32)
#  define FT_DNS_ASYNC 1
#  include <pthread.h>
#  include <unistd.h>
#else
#  define FT_DNS_ASYNC 0
#endif

typedef struct ft_dns {
    char            *host;
    char            *port;
    struct addrinfo *ai;      /* the answer, freed with the struct   */
    int              gai;     /* getaddrinfo's return code           */
    int              fd_w;    /* the THREAD's end of the pipe, only  */
#if FT_DNS_ASYNC
    pthread_mutex_t  lock;
#endif
    int              refs;    /* guarded by lock                     */
} ft_dns;

/* strdup with plain malloc. Not Newx: the resolver thread frees these and has
 * no interpreter to hand a Safefree. Not strdup(3) either, which is POSIX
 * rather than C89 and is not declared everywhere this builds. */
static char *ft_strdup_plain(const char *s) {
    size_t n;
    char *p;
    if (!s) return NULL;
    n = strlen(s) + 1;
    p = (char *)malloc(n);
    if (p) memcpy(p, s, n);
    return p;
}

/* Drop one reference; the last one frees. Called from both threads, which is
 * the whole reason the count is guarded. */
static void ft_dns_unref(ft_dns *d) {
    int last;
    if (!d) return;
#if FT_DNS_ASYNC
    pthread_mutex_lock(&d->lock);
    last = (--d->refs == 0);
    pthread_mutex_unlock(&d->lock);
#else
    last = (--d->refs == 0);
#endif
    if (!last) return;
#if FT_DNS_ASYNC
    pthread_mutex_destroy(&d->lock);
#endif
    /* Reaching zero means the other side has already finished with the
     * struct, so nothing here can be racing a writer. */
    if (d->ai) freeaddrinfo(d->ai);
    free(d->host);
    free(d->port);
    free(d);
}

#if FT_DNS_ASYNC

static void *ft_dns_thread(void *arg) {
    ft_dns *d = (ft_dns *)arg;
    struct addrinfo hints, *ai = NULL;
    int gai;
    char b = 1;

    memset(&hints, 0, sizeof hints);
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    gai = getaddrinfo(d->host, d->port, &hints, &ai);
    d->gai = gai;
    d->ai  = (gai == 0) ? ai : NULL;
    if (gai != 0 && ai) freeaddrinfo(ai);   /* a failure can still allocate */

    /* The wakeup. A short write or an EPIPE - the request was cancelled and
     * the loop closed its end - is not an error worth reporting to anyone:
     * the close below wakes a watcher just as well as the byte does. */
    if (write(d->fd_w, &b, 1) < 0) { /* the close is the backstop */ }
    close(d->fd_w);
    ft_dns_unref(d);
    return NULL;
}

/* Start resolving host:port. Returns the read end of the pipe (>= 0) with
 * *out set, or -1 if a thread could not be started - in which case the caller
 * falls back to resolving inline and nothing is left allocated. */
static int ft_dns_start(const char *host, const char *port, ft_dns **out) {
    ft_dns *d;
    int fds[2];
    pthread_t tid;
    pthread_attr_t attr;
    int rc;

    *out = NULL;
    if (pipe(fds) != 0) return -1;

    d = (ft_dns *)calloc(1, sizeof *d);
    if (!d) { close(fds[0]); close(fds[1]); return -1; }
    d->host = ft_strdup_plain(host);
    d->port = ft_strdup_plain(port);
    d->fd_w = fds[1];
    d->refs = 2;                       /* this side, and the thread */
    if (!d->host || !d->port || pthread_mutex_init(&d->lock, NULL) != 0) {
        free(d->host); free(d->port); free(d);
        close(fds[0]); close(fds[1]);
        return -1;
    }

    /* Detached: nothing ever joins it, and an unjoined joinable thread leaks
     * its stack for the life of the process. */
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    rc = pthread_create(&tid, &attr, ft_dns_thread, d);
    pthread_attr_destroy(&attr);
    if (rc != 0) {
        d->refs = 1;                   /* no thread took the other one */
        close(fds[1]);
        ft_dns_unref(d);
        close(fds[0]);
        return -1;
    }
    /* fds[1] belongs to the thread from here; this side must not touch it. */
    *out = d;
    return fds[0];
}

#else  /* no threads: the caller resolves inline, as it always did */

static int ft_dns_start(const char *host, const char *port, ft_dns **out) {
    (void)host; (void)port;
    *out = NULL;
    return -1;
}

#endif /* FT_DNS_ASYNC */

/* Is this a literal address rather than a name? An IPv4 or IPv6 literal, or a
 * bracketed IPv6 the URL parser has already unwrapped, needs no resolution at
 * all - AI_NUMERICHOST makes getaddrinfo a parse with no network in it, so
 * those requests keep their old zero-latency path and start no thread. Every
 * test in this dist connects to 127.0.0.1, which is exactly this case. */
static int ft_dns_numeric(const char *host, const char *port,
                          struct addrinfo **ai) {
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags    = AI_NUMERICHOST;
    return getaddrinfo(host, port, &hints, ai) == 0;
}

#endif /* FT_DNS_H */
