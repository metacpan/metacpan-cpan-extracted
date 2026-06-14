#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include <unistd.h>
#include <sys/epoll.h>

typedef struct {
  SV  **slots;
  UV    cap;
  UV    count;
} le_registry_t;

static le_registry_t *
le_registry_from_sv(SV *obj) {
  if (!sv_isobject(obj)) {
    croak("registry is not an object");
  }

  SV *rv = SvRV(obj);
  if (!SvIOK(rv)) {
    croak("invalid registry object");
  }

  return INT2PTR(le_registry_t *, SvIV(rv));
}

static void
le_registry_grow(le_registry_t *r, UV fd) {
  UV old_cap = r->cap;
  UV new_cap = old_cap ? old_cap : 64;

  while (fd >= new_cap) {
    if (new_cap > (UV_MAX / 2)) {
      croak("fd registry too large");
    }
    new_cap *= 2;
  }

  Renew(r->slots, new_cap, SV *);
  Zero(r->slots + old_cap, new_cap - old_cap, SV *);
  r->cap = new_cap;
}





typedef struct {
  int epfd;
  struct epoll_event *events;
  int max_events;
} le_epoll_t;

static le_epoll_t *
le_epoll_from_sv(SV *obj) {
  if (!sv_isobject(obj)) {
    croak("epoll buffer is not an object");
  }
  SV *rv = SvRV(obj);
  if (!SvIOK(rv)) {
    croak("invalid epoll buffer object");
  }
  return INT2PTR(le_epoll_t *, SvIV(rv));
}

static uint32_t
le_mask_to_epoll_events(IV mask) {
  uint32_t ev = 0;
  if (mask & 0x01) ev |= EPOLLIN;
  if (mask & 0x02) ev |= EPOLLOUT;
#ifdef EPOLLPRI
  if (mask & 0x04) ev |= EPOLLPRI;
#endif
#ifdef EPOLLRDHUP
  if (mask & 0x08) ev |= EPOLLRDHUP;
#endif
#ifdef EPOLLET
  if (mask & 0x10) ev |= EPOLLET;
#endif
#ifdef EPOLLONESHOT
  if (mask & 0x20) ev |= EPOLLONESHOT;
#endif
  return ev;
}

static IV
le_epoll_events_to_mask(uint32_t ev) {
  IV mask = 0;
  if (ev & EPOLLIN)  mask |= 0x01;
  if (ev & EPOLLOUT) mask |= 0x02;
#ifdef EPOLLPRI
  if (ev & EPOLLPRI) mask |= 0x04;
#endif
#ifdef EPOLLRDHUP
  if (ev & EPOLLRDHUP) mask |= 0x08;
#endif
#ifdef EPOLLET
  if (ev & EPOLLET) mask |= 0x10;
#endif
#ifdef EPOLLONESHOT
  if (ev & EPOLLONESHOT) mask |= 0x20;
#endif
  if (ev & EPOLLERR) mask |= 0x40;
  if (ev & EPOLLHUP) mask |= 0x80;
  return mask;
}

static int
le_timeout_ms(SV *timeout_s) {
  if (!SvOK(timeout_s)) {
    return -1;
  }
  double sec = SvNV(timeout_s);
  if (sec <= 0.0) {
    return 0;
  }
  double ms = sec * 1000.0;
  if (ms > 2147483647.0) {
    return 2147483647;
  }
  int out = (int)ms;
  if ((double)out < ms) {
    out++;
  }
  return out < 0 ? 0 : out;
}

typedef struct {
  IV fd;
  IV mask;
  SV *fh;
  SV *cb;
  SV *loop;
  SV *tag;
  SV *watcher; /* optional direct Loop watcher; avoids a Perl dispatch closure */
} le_backend_watch_t;

static le_backend_watch_t *
le_backend_watch_from_sv(SV *obj) {
  if (!sv_isobject(obj)) {
    croak("backend watch is not an object");
  }

  SV *rv = SvRV(obj);
  if (!SvIOK(rv)) {
    croak("invalid backend watch object");
  }

  return INT2PTR(le_backend_watch_t *, SvIV(rv));
}





static SV *
le_backend_watch_make_sv(const char *class, IV fd, SV *fh, SV *watcher, IV mask, SV *loop, SV *tag) {
  le_backend_watch_t *w;
  Newxz(w, 1, le_backend_watch_t);
  w->fd      = fd;
  w->mask    = mask;
  w->fh      = newSVsv(fh);
  w->cb      = newSV(0);
  w->loop    = newSVsv(loop);
  w->tag     = newSVsv(tag);
  w->watcher = newSVsv(watcher);
  SV *inner = newSViv(PTR2IV(w));
  SV *ref = newRV_noinc(inner);
  sv_bless(ref, gv_stashpv(class, GV_ADD));
  return ref;
}

static SV *
le_hv_fetch_required(HV *hv, const char *key, I32 klen) {
  SV **svp = hv_fetch(hv, key, klen, 0);
  if (!svp) {
    croak("missing required hash key '%.*s'", (int)klen, key);
  }
  return *svp;
}

static void
le_registry_delete_slot(le_registry_t *r, UV fd) {
  if (fd < r->cap && r->slots[fd]) {
    SvREFCNT_dec(r->slots[fd]);
    r->slots[fd] = NULL;
    if (r->count) r->count--;
  }
}

static void
le_hv_store_sv(HV *hv, const char *key, I32 klen, SV *value) {
  (void)hv_store(hv, key, klen, value, 0);
}

static SV *
le_bool_sv(int v) {
  return newSViv(v ? 1 : 0);
}

static int
le_hv_bool(HV *hv, const char *key, I32 len) {
  SV **svp = hv_fetch(hv, key, len, 0);
  return (svp && SvTRUE(*svp)) ? 1 : 0;
}

static IV
le_events_to_mask(SV *ev) {
  if (!SvROK(ev) || SvTYPE(SvRV(ev)) != SVt_PVHV) {
    croak("epoll event must be a hash reference");
  }

  HV *hv = (HV *)SvRV(ev);
  IV m = 0;

  if (le_hv_bool(hv, "in", 2))      m |= 0x01;
  if (le_hv_bool(hv, "out", 3))     m |= 0x02;
  if (le_hv_bool(hv, "prio", 4))    m |= 0x04;
  if (le_hv_bool(hv, "rdhup", 5))   m |= 0x08;
  if (le_hv_bool(hv, "et", 2))      m |= 0x10;
  if (le_hv_bool(hv, "oneshot", 7)) m |= 0x20;
  if (le_hv_bool(hv, "err", 3))     m |= 0x40;
  if (le_hv_bool(hv, "hup", 3))     m |= 0x80;

  return m;
}



typedef struct {
  IV deadline_ns;
  UV id;
  SV *cb;
} le_timer_entry_t;

typedef struct {
  le_timer_entry_t *heap;
  UV size;
  UV cap;
  char *live;
  UV live_cap;
  UV next_id;
  UV cancelled;
} le_timer_heap_t;

static le_timer_heap_t *
le_timer_heap_from_sv(SV *obj) {
  if (!sv_isobject(obj)) {
    croak("timer heap is not an object");
  }
  SV *rv = SvRV(obj);
  if (!SvIOK(rv)) {
    croak("invalid timer heap object");
  }
  return INT2PTR(le_timer_heap_t *, SvIV(rv));
}

static void
le_timer_heap_grow(le_timer_heap_t *h, UV need) {
  UV old_cap = h->cap;
  UV new_cap = old_cap ? old_cap : 64;
  while (need >= new_cap) {
    if (new_cap > (UV_MAX / 2)) croak("timer heap too large");
    new_cap *= 2;
  }
  Renew(h->heap, new_cap, le_timer_entry_t);
  if (new_cap > old_cap) {
    Zero(h->heap + old_cap, new_cap - old_cap, le_timer_entry_t);
  }
  h->cap = new_cap;
}

static void
le_timer_live_grow(le_timer_heap_t *h, UV id) {
  UV old_cap = h->live_cap;
  UV new_cap = old_cap ? old_cap : 64;
  while (id >= new_cap) {
    if (new_cap > (UV_MAX / 2)) croak("timer id table too large");
    new_cap *= 2;
  }
  Renew(h->live, new_cap, char);
  Zero(h->live + old_cap, new_cap - old_cap, char);
  h->live_cap = new_cap;
}

static int
le_timer_is_live(le_timer_heap_t *h, UV id) {
  return (id < h->live_cap && h->live[id]) ? 1 : 0;
}

static void
le_timer_swap(le_timer_entry_t *a, le_timer_entry_t *b) {
  le_timer_entry_t tmp = *a;
  *a = *b;
  *b = tmp;
}

static void
le_timer_sift_up(le_timer_heap_t *h, UV i) {
  while (i > 0) {
    UV p = (i - 1) / 2;
    if (h->heap[p].deadline_ns <= h->heap[i].deadline_ns) break;
    le_timer_swap(&h->heap[p], &h->heap[i]);
    i = p;
  }
}

static void
le_timer_sift_down(le_timer_heap_t *h, UV i) {
  while (1) {
    UV l = i * 2 + 1;
    if (l >= h->size) break;
    UV r = l + 1;
    UV m = l;
    if (r < h->size && h->heap[r].deadline_ns < h->heap[l].deadline_ns) m = r;
    if (h->heap[i].deadline_ns <= h->heap[m].deadline_ns) break;
    le_timer_swap(&h->heap[i], &h->heap[m]);
    i = m;
  }
}

static void
le_timer_pop_root(le_timer_heap_t *h) {
  if (h->size == 0) return;
  SvREFCNT_dec(h->heap[0].cb);
  h->size--;
  if (h->size > 0) {
    h->heap[0] = h->heap[h->size];
    Zero(&h->heap[h->size], 1, le_timer_entry_t);
    le_timer_sift_down(h, 0);
  }
  else {
    Zero(&h->heap[0], 1, le_timer_entry_t);
  }
}

static void
le_timer_drop_cancelled_roots(le_timer_heap_t *h) {
  while (h->size && !le_timer_is_live(h, h->heap[0].id)) {
    le_timer_pop_root(h);
    if (h->cancelled) h->cancelled--;
  }
}

static int
le_hv_true_key(HV *hv, const char *key, I32 klen) {
  SV **svp = hv_fetch(hv, key, klen, 0);
  return (svp && SvTRUE(*svp)) ? 1 : 0;
}

static SV *
le_hv_get_key(HV *hv, const char *key, I32 klen) {
  SV **svp = hv_fetch(hv, key, klen, 0);
  return svp ? *svp : &PL_sv_undef;
}

static void
le_call_watcher_cb(SV *cb, SV *loop, SV *fh, SV *watcher) {
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(loop)));
  XPUSHs(sv_2mortal(newSVsv(fh)));
  XPUSHs(sv_2mortal(newSVsv(watcher)));
  PUTBACK;
  call_sv(cb, G_DISCARD);
  FREETMPS;
  LEAVE;
}

static void
le_backend_watch_dispatch_direct(le_backend_watch_t *w, IV mask) {
  if (!w->watcher || !SvOK(w->watcher) || !SvROK(w->watcher) || SvTYPE(SvRV(w->watcher)) != SVt_PVHV) {
    return;
  }

  HV *whv = (HV *)SvRV(w->watcher);
  if (!le_hv_true_key(whv, "active", 6)) {
    return;
  }

  SV *fh = le_hv_get_key(whv, "fh", 2);
  if (!SvOK(fh)) {
    return;
  }

  int read_trig  = (mask & 0x01) ? 1 : 0;
  int write_trig = (mask & 0x02) ? 1 : 0;

  if (mask & 0x40) {
    SV *ecb = le_hv_get_key(whv, "error_cb", 8);
    if (SvOK(ecb) && le_hv_true_key(whv, "error_enabled", 13)) {
      le_call_watcher_cb(ecb, w->loop, fh, w->watcher);
      return;
    }
    read_trig = 1;
    write_trig = 1;
  }

  if (mask & 0x80) {
    read_trig = 1;
  }

  if (read_trig && le_hv_true_key(whv, "read_enabled", 12)) {
    SV *rcb = le_hv_get_key(whv, "read_cb", 7);
    if (SvOK(rcb)) {
      le_call_watcher_cb(rcb, w->loop, fh, w->watcher);
    }
  }

  if (!le_hv_true_key(whv, "active", 6)) {
    return;
  }

  if (write_trig && le_hv_true_key(whv, "write_enabled", 13)) {
    SV *wcb = le_hv_get_key(whv, "write_cb", 8);
    if (SvOK(wcb)) {
      le_call_watcher_cb(wcb, w->loop, fh, w->watcher);
    }
  }
}


MODULE = Linux::Event    PACKAGE = Linux::Event::XS
PROTOTYPES: DISABLE

SV *
registry_new(class = "Linux::Event::XS::Registry")
    const char *class
  CODE:
    le_registry_t *r;
    Newxz(r, 1, le_registry_t);
    SV *inner = newSViv(PTR2IV(r));
    SV *ref = newRV_noinc(inner);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
registry_get(reg, fd)
    SV *reg
    UV fd
  CODE:
    le_registry_t *r = le_registry_from_sv(reg);
    if (fd >= r->cap || !r->slots[fd]) {
      RETVAL = &PL_sv_undef;
    }
    else {
      RETVAL = newSVsv(r->slots[fd]);
    }
  OUTPUT:
    RETVAL

void
registry_set(reg, fd, value)
    SV *reg
    UV fd
    SV *value
  CODE:
    le_registry_t *r = le_registry_from_sv(reg);
    if (fd >= r->cap) {
      le_registry_grow(r, fd);
    }
    if (r->slots[fd]) {
      SvREFCNT_dec(r->slots[fd]);
    }
    else {
      r->count++;
    }
    r->slots[fd] = newSVsv(value);

SV *
registry_delete(reg, fd)
    SV *reg
    UV fd
  CODE:
    le_registry_t *r = le_registry_from_sv(reg);
    if (fd >= r->cap || !r->slots[fd]) {
      RETVAL = &PL_sv_undef;
    }
    else {
      RETVAL = r->slots[fd];
      r->slots[fd] = NULL;
      r->count--;
    }
  OUTPUT:
    RETVAL

UV
registry_count(reg)
    SV *reg
  CODE:
    le_registry_t *r = le_registry_from_sv(reg);
    RETVAL = r->count;
  OUTPUT:
    RETVAL





IV
loop_cancel_watcher(loop, watcher)
    SV *loop
    SV *watcher
  CODE:
    if (!SvROK(loop) || SvTYPE(SvRV(loop)) != SVt_PVHV) {
      croak("loop must be a hash-based object");
    }
    if (!SvROK(watcher) || SvTYPE(SvRV(watcher)) != SVt_PVHV) {
      croak("watcher must be a hash-based object");
    }

    HV *lhv = (HV *)SvRV(loop);
    HV *whv = (HV *)SvRV(watcher);

    SV *active = le_hv_fetch_required(whv, "active", 6);
    if (!SvTRUE(active)) {
      RETVAL = 0;
    }
    else {
      SV *fdsv = le_hv_fetch_required(whv, "fd", 2);
      UV fd = (UV)SvIV(fdsv);

      SV *watchers_sv = le_hv_fetch_required(lhv, "_watchers", 9);
      le_registry_t *watchers = le_registry_from_sv(watchers_sv);
      le_registry_delete_slot(watchers, fd);

      SV *backend_sv = le_hv_fetch_required(lhv, "backend", 7);
      if (!SvROK(backend_sv) || SvTYPE(SvRV(backend_sv)) != SVt_PVHV) {
        croak("backend must be a hash-based object");
      }
      HV *bhv = (HV *)SvRV(backend_sv);

      SV *ep_sv = le_hv_fetch_required(bhv, "ep", 2);
      le_epoll_t *ep = le_epoll_from_sv(ep_sv);
      int ret = epoll_ctl(ep->epfd, EPOLL_CTL_DEL, (int)fd, NULL);
      if (ret < 0 && errno != ENOENT && errno != EBADF) {
        croak("epoll_ctl delete failed for fd %ld: %s", (long)fd, strerror(errno));
      }

      SV *breg_sv = le_hv_fetch_required(bhv, "watch", 5);
      le_registry_t *breg = le_registry_from_sv(breg_sv);
      le_registry_delete_slot(breg, fd);

      hv_store(whv, "active", 6, newSViv(0), 0);
      hv_store(whv, "fh", 2, newSV(0), 0);
      RETVAL = 1;
    }
  OUTPUT:
    RETVAL

SV *
watcher_new(class, loop, fh, fd, read_cb=&PL_sv_undef, write_cb=&PL_sv_undef, error_cb=&PL_sv_undef, data=&PL_sv_undef, edge_triggered=0, oneshot=0)
    const char *class
    SV *loop
    SV *fh
    IV fd
    SV *read_cb
    SV *write_cb
    SV *error_cb
    SV *data
    IV edge_triggered
    IV oneshot
  CODE:
    if (SvOK(read_cb) && (!SvROK(read_cb) || SvTYPE(SvRV(read_cb)) != SVt_PVCV)) {
      croak("read must be a coderef or undef");
    }
    if (SvOK(write_cb) && (!SvROK(write_cb) || SvTYPE(SvRV(write_cb)) != SVt_PVCV)) {
      croak("write must be a coderef or undef");
    }
    if (SvOK(error_cb) && (!SvROK(error_cb) || SvTYPE(SvRV(error_cb)) != SVt_PVCV)) {
      croak("error must be a coderef or undef");
    }

    HV *hv = newHV();
    SV *fh_slot = newSVsv(fh);
    if (SvROK(fh_slot)) {
      sv_rvweaken(fh_slot);
    }

    int read_enabled  = SvOK(read_cb)  ? 1 : 0;
    int write_enabled = SvOK(write_cb) ? 1 : 0;
    int error_enabled = SvOK(error_cb) ? 1 : 0;

    le_hv_store_sv(hv, "loop", 4, newSVsv(loop));
    le_hv_store_sv(hv, "fh", 2, fh_slot);
    le_hv_store_sv(hv, "fd", 2, newSViv(fd));
    le_hv_store_sv(hv, "data", 4, newSVsv(data));
    le_hv_store_sv(hv, "read_cb", 7, newSVsv(read_cb));
    le_hv_store_sv(hv, "write_cb", 8, newSVsv(write_cb));
    le_hv_store_sv(hv, "error_cb", 8, newSVsv(error_cb));
    le_hv_store_sv(hv, "read_enabled", 12, le_bool_sv(read_enabled));
    le_hv_store_sv(hv, "write_enabled", 13, le_bool_sv(write_enabled));
    le_hv_store_sv(hv, "error_enabled", 13, le_bool_sv(error_enabled));
    le_hv_store_sv(hv, "edge_triggered", 14, le_bool_sv(edge_triggered));
    le_hv_store_sv(hv, "oneshot", 7, le_bool_sv(oneshot));
    le_hv_store_sv(hv, "active", 6, newSViv(1));

    SV *ref = newRV_noinc((SV *)hv);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
backend_watch_new(class, fd, fh, cb, mask, loop, tag=&PL_sv_undef)
    const char *class
    IV fd
    SV *fh
    SV *cb
    IV mask
    SV *loop
    SV *tag
  CODE:
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
      croak("cb must be a coderef");
    }
    le_backend_watch_t *w;
    Newxz(w, 1, le_backend_watch_t);
    w->fd   = fd;
    w->mask = mask;
    w->fh   = newSVsv(fh);
    w->cb   = newSVsv(cb);
    w->loop = newSVsv(loop);
    w->tag  = newSVsv(tag);
    SV *inner = newSViv(PTR2IV(w));
    SV *ref = newRV_noinc(inner);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
backend_watch_new_watcher(class, fd, fh, watcher, mask, loop, tag=&PL_sv_undef)
    const char *class
    IV fd
    SV *fh
    SV *watcher
    IV mask
    SV *loop
    SV *tag
  CODE:
    if (!SvROK(watcher) || SvTYPE(SvRV(watcher)) != SVt_PVHV) {
      croak("watcher must be a hash-based object");
    }
    le_backend_watch_t *w;
    Newxz(w, 1, le_backend_watch_t);
    w->fd      = fd;
    w->mask    = mask;
    w->fh      = newSVsv(fh);
    w->cb      = newSV(0);
    w->loop    = newSVsv(loop);
    w->tag     = newSVsv(tag);
    w->watcher = newSVsv(watcher);
    SV *inner = newSViv(PTR2IV(w));
    SV *ref = newRV_noinc(inner);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
backend_watch_fh(watch)
    SV *watch
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    RETVAL = newSVsv(w->fh);
  OUTPUT:
    RETVAL

IV
backend_watch_mask(watch)
    SV *watch
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    RETVAL = w->mask;
  OUTPUT:
    RETVAL

void
backend_watch_set_mask(watch, mask)
    SV *watch
    IV mask
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    w->mask = mask;

void
backend_watch_set_loop_tag(watch, loop, tag=&PL_sv_undef)
    SV *watch
    SV *loop
    SV *tag
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    SvREFCNT_dec(w->loop);
    SvREFCNT_dec(w->tag);
    w->loop = newSVsv(loop);
    w->tag  = newSVsv(tag);

void
backend_watch_dispatch(watch, ev)
    SV *watch
    SV *ev
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    IV mask = le_events_to_mask(ev);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVsv(w->loop)));
    XPUSHs(sv_2mortal(newSVsv(w->fh)));
    XPUSHs(sv_2mortal(newSViv(w->fd)));
    XPUSHs(sv_2mortal(newSViv(mask)));
    XPUSHs(sv_2mortal(newSVsv(w->tag)));
    PUTBACK;
    call_sv(w->cb, G_DISCARD);
    FREETMPS;
    LEAVE;

void
backend_watch_dispatch_mask(watch, mask)
    SV *watch
    IV mask
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    if (w->watcher && SvOK(w->watcher)) {
      le_backend_watch_dispatch_direct(w, mask);
    }
    else {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVsv(w->loop)));
      XPUSHs(sv_2mortal(newSVsv(w->fh)));
      XPUSHs(sv_2mortal(newSViv(w->fd)));
      XPUSHs(sv_2mortal(newSViv(mask)));
      XPUSHs(sv_2mortal(newSVsv(w->tag)));
      PUTBACK;
      call_sv(w->cb, G_DISCARD);
      FREETMPS;
      LEAVE;
    }





IV
loop_watch_watcher_fast(loop, fh, fd, watcher, mask)
    SV *loop
    SV *fh
    IV fd
    SV *watcher
    IV mask
  CODE:
    if (!SvROK(loop) || SvTYPE(SvRV(loop)) != SVt_PVHV) {
      croak("loop must be a hash-based object");
    }
    if (!SvROK(watcher) || SvTYPE(SvRV(watcher)) != SVt_PVHV) {
      croak("watcher must be a hash-based object");
    }

    HV *lhv = (HV *)SvRV(loop);
    SV *watchers_sv = le_hv_fetch_required(lhv, "_watchers", 9);
    le_registry_t *watchers = le_registry_from_sv(watchers_sv);

    SV *backend_sv = le_hv_fetch_required(lhv, "backend", 7);
    if (!SvROK(backend_sv) || SvTYPE(SvRV(backend_sv)) != SVt_PVHV) {
      croak("backend must be a hash-based object");
    }
    HV *bhv = (HV *)SvRV(backend_sv);

    SV *breg_sv = le_hv_fetch_required(bhv, "watch", 5);
    le_registry_t *breg = le_registry_from_sv(breg_sv);
    if ((UV)fd < breg->cap && breg->slots[(UV)fd]) {
      croak("fd already watched: %ld", (long)fd);
    }

    IV eff_mask = mask;
    if (le_hv_true_key(bhv, "edge", 4)) eff_mask |= 0x10;
    if (le_hv_true_key(bhv, "oneshot", 7)) eff_mask |= 0x20;

    SV *ep_sv = le_hv_fetch_required(bhv, "ep", 2);
    le_epoll_t *ep = le_epoll_from_sv(ep_sv);
    struct epoll_event ev;
    Zero(&ev, 1, struct epoll_event);
    ev.events = le_mask_to_epoll_events(eff_mask);
    ev.data.fd = (int)fd;
    if (epoll_ctl(ep->epfd, EPOLL_CTL_ADD, (int)fd, &ev) < 0) {
      croak("epoll_ctl add failed for fd %ld: %s", (long)fd, strerror(errno));
    }

    SV *rec = le_backend_watch_make_sv("Linux::Event::XS::BackendWatch", fd, fh, watcher, eff_mask, loop, &PL_sv_undef);

    if ((UV)fd >= watchers->cap) le_registry_grow(watchers, (UV)fd);
    if (watchers->slots[(UV)fd]) SvREFCNT_dec(watchers->slots[(UV)fd]);
    else watchers->count++;
    watchers->slots[(UV)fd] = newSVsv(watcher);

    if ((UV)fd >= breg->cap) le_registry_grow(breg, (UV)fd);
    if (breg->slots[(UV)fd]) SvREFCNT_dec(breg->slots[(UV)fd]);
    else breg->count++;
    breg->slots[(UV)fd] = newSVsv(rec);
    SvREFCNT_dec(rec);

    RETVAL = 1;
  OUTPUT:
    RETVAL

SV *
timer_heap_new(class = "Linux::Event::XS::TimerHeap")
    const char *class
  CODE:
    le_timer_heap_t *h;
    Newxz(h, 1, le_timer_heap_t);
    h->next_id = 1;
    SV *inner = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(inner);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

UV
timer_heap_at_ns(heap, deadline_ns, cb)
    SV *heap
    IV deadline_ns
    SV *cb
  CODE:
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
      croak("callback must be a coderef");
    }
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    UV id = h->next_id++;
    if (id >= h->live_cap) le_timer_live_grow(h, id);
    h->live[id] = 1;
    if (h->size >= h->cap) le_timer_heap_grow(h, h->size);
    UV i = h->size++;
    h->heap[i].deadline_ns = deadline_ns;
    h->heap[i].id = id;
    h->heap[i].cb = newSVsv(cb);
    le_timer_sift_up(h, i);
    RETVAL = id;
  OUTPUT:
    RETVAL

IV
timer_heap_cancel(heap, id)
    SV *heap
    UV id
  CODE:
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    if (id < h->live_cap && h->live[id]) {
      h->live[id] = 0;
      h->cancelled++;
      RETVAL = 1;
    }
    else {
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL

SV *
timer_heap_next_deadline_ns(heap)
    SV *heap
  CODE:
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    le_timer_drop_cancelled_roots(h);
    if (!h->size) {
      RETVAL = &PL_sv_undef;
    }
    else {
      RETVAL = newSViv(h->heap[0].deadline_ns);
    }
  OUTPUT:
    RETVAL

void
timer_heap_pop_expired(heap, now_ns)
    SV *heap
    IV now_ns
  PPCODE:
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    while (h->size) {
      le_timer_drop_cancelled_roots(h);
      if (!h->size) break;
      if (h->heap[0].deadline_ns > now_ns) break;

      UV id = h->heap[0].id;
      IV deadline_ns = h->heap[0].deadline_ns;
      SV *cb = newSVsv(h->heap[0].cb);
      if (id < h->live_cap) h->live[id] = 0;
      le_timer_pop_root(h);

      AV *av = newAV();
      av_push(av, newSVuv(id));
      av_push(av, cb);
      av_push(av, newSViv(deadline_ns));
      XPUSHs(sv_2mortal(newRV_noinc((SV *)av)));
    }

UV
timer_heap_size(heap)
    SV *heap
  CODE:
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    RETVAL = h->size;
  OUTPUT:
    RETVAL

SV *
epoll_new(class = "Linux::Event::XS::Epoll", max_events = 256)
    const char *class
    IV max_events
  CODE:
    if (max_events <= 0) {
      croak("max_events must be positive");
    }
    le_epoll_t *ep;
    Newxz(ep, 1, le_epoll_t);
    ep->epfd = epoll_create1(EPOLL_CLOEXEC);
    if (ep->epfd < 0) {
      Safefree(ep);
      croak("epoll_create1 failed: %s", strerror(errno));
    }
    ep->max_events = (int)max_events;
    Newxz(ep->events, ep->max_events, struct epoll_event);
    SV *inner = newSViv(PTR2IV(ep));
    SV *ref = newRV_noinc(inner);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

void
epoll_add(epobj, fd, mask)
    SV *epobj
    IV fd
    IV mask
  CODE:
    le_epoll_t *ep = le_epoll_from_sv(epobj);
    struct epoll_event ev;
    Zero(&ev, 1, struct epoll_event);
    ev.events = le_mask_to_epoll_events(mask);
    ev.data.fd = (int)fd;
    if (epoll_ctl(ep->epfd, EPOLL_CTL_ADD, (int)fd, &ev) < 0) {
      croak("epoll_ctl add failed for fd %ld: %s", (long)fd, strerror(errno));
    }

void
epoll_modify(epobj, fd, mask)
    SV *epobj
    IV fd
    IV mask
  CODE:
    le_epoll_t *ep = le_epoll_from_sv(epobj);
    struct epoll_event ev;
    Zero(&ev, 1, struct epoll_event);
    ev.events = le_mask_to_epoll_events(mask);
    ev.data.fd = (int)fd;
    if (epoll_ctl(ep->epfd, EPOLL_CTL_MOD, (int)fd, &ev) < 0) {
      croak("epoll_ctl modify failed for fd %ld: %s", (long)fd, strerror(errno));
    }

IV
epoll_delete(epobj, fd)
    SV *epobj
    IV fd
  CODE:
    le_epoll_t *ep = le_epoll_from_sv(epobj);
    int ret = epoll_ctl(ep->epfd, EPOLL_CTL_DEL, (int)fd, NULL);
    if (ret < 0) {
      if (errno == ENOENT || errno == EBADF) {
        RETVAL = 0;
      }
      else {
        croak("epoll_ctl delete failed for fd %ld: %s", (long)fd, strerror(errno));
      }
    }
    else {
      RETVAL = 1;
    }
  OUTPUT:
    RETVAL

IV
epoll_wait_dispatch(epobj, registry, timeout_s=&PL_sv_undef)
    SV *epobj
    SV *registry
    SV *timeout_s
  CODE:
    le_epoll_t *ep = le_epoll_from_sv(epobj);
    le_registry_t *r = le_registry_from_sv(registry);
    int timeout = le_timeout_ms(timeout_s);
    int n;
    do {
      n = epoll_wait(ep->epfd, ep->events, ep->max_events, timeout);
    } while (n < 0 && errno == EINTR);
    if (n < 0) {
      croak("epoll_wait failed: %s", strerror(errno));
    }
    int i;
    for (i = 0; i < n; i++) {
      UV fd = (UV)ep->events[i].data.fd;
      if (fd < r->cap && r->slots[fd]) {
        SV *rec_sv = r->slots[fd];
        SvREFCNT_inc(rec_sv);
        le_backend_watch_t *w = le_backend_watch_from_sv(rec_sv);
        IV mask = le_epoll_events_to_mask(ep->events[i].events);
        if (w->watcher && SvOK(w->watcher)) {
          le_backend_watch_dispatch_direct(w, mask);
        }
        else {
          dSP;
          ENTER;
          SAVETMPS;
          PUSHMARK(SP);
          XPUSHs(sv_2mortal(newSVsv(w->loop)));
          XPUSHs(sv_2mortal(newSVsv(w->fh)));
          XPUSHs(sv_2mortal(newSViv(w->fd)));
          XPUSHs(sv_2mortal(newSViv(mask)));
          XPUSHs(sv_2mortal(newSVsv(w->tag)));
          PUTBACK;
          call_sv(w->cb, G_DISCARD);
          FREETMPS;
          LEAVE;
        }
        SvREFCNT_dec(rec_sv);
      }
    }
    RETVAL = n;
  OUTPUT:
    RETVAL



MODULE = Linux::Event    PACKAGE = Linux::Event::XS::BackendWatch
PROTOTYPES: DISABLE

void
DESTROY(watch)
    SV *watch
  CODE:
    le_backend_watch_t *w = le_backend_watch_from_sv(watch);
    if (w) {
      SvREFCNT_dec(w->fh);
      SvREFCNT_dec(w->cb);
      SvREFCNT_dec(w->loop);
      SvREFCNT_dec(w->tag);
      if (w->watcher) SvREFCNT_dec(w->watcher);
      Safefree(w);
      sv_setiv(SvRV(watch), 0);
    }

MODULE = Linux::Event    PACKAGE = Linux::Event::XS::Epoll
PROTOTYPES: DISABLE

void
DESTROY(epobj)
    SV *epobj
  CODE:
    le_epoll_t *ep = le_epoll_from_sv(epobj);
    if (ep) {
      if (ep->epfd >= 0) {
        close(ep->epfd);
      }
      Safefree(ep->events);
      Safefree(ep);
      sv_setiv(SvRV(epobj), 0);
    }


MODULE = Linux::Event    PACKAGE = Linux::Event::XS::TimerHeap
PROTOTYPES: DISABLE

void
DESTROY(heap)
    SV *heap
  CODE:
    le_timer_heap_t *h = le_timer_heap_from_sv(heap);
    if (h) {
      UV i;
      for (i = 0; i < h->size; i++) {
        if (h->heap[i].cb) SvREFCNT_dec(h->heap[i].cb);
      }
      Safefree(h->heap);
      Safefree(h->live);
      Safefree(h);
      sv_setiv(SvRV(heap), 0);
    }


MODULE = Linux::Event    PACKAGE = Linux::Event::XS::Registry
PROTOTYPES: DISABLE

void
DESTROY(reg)
    SV *reg
  CODE:
    le_registry_t *r = le_registry_from_sv(reg);
    if (r) {
      UV i;
      for (i = 0; i < r->cap; i++) {
        if (r->slots[i]) {
          SvREFCNT_dec(r->slots[i]);
        }
      }
      Safefree(r->slots);
      Safefree(r);
      sv_setiv(SvRV(reg), 0);
    }
