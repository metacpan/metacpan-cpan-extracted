#if defined(HAS_DEVPOLL)
#include <sys/devpoll.h>
    static int dpfd=0;
    static struct pollfd *Pollfd=0;
    static int pollMax=200;
    static int Nfds;

#define MAXFD 65000

    typedef struct _fdToEvent {
        pe_io *ev;
    } FdToEvent;

    static FdToEvent fdToEvent[MAXFD];
#endif /*HAS_DEVPOLL*/

static void boot_devpoll() {
#if defined(HAS_DEVPOLL)
    memset(fdToEvent, 0, MAXFD*sizeof(FdToEvent));

    EvNew(9, Pollfd, pollMax, struct pollfd);

    /* Open /dev/poll driver */
    if (!dpfd) {
        fprintf(stderr, "INIT Open /dev/poll!!!\n");
        if ((dpfd = open("/dev/poll", O_RDWR)) < 0) {
            croak("Event: Can't open /dev/poll!\n");
        }
    }
#endif /*HAS_DEVPOLL*/
}

static int pe_sys_fileno(SV *sv, char *context) {
    IO *io;
    PerlIO *fp;
    
    if (!sv)
	croak("Event %s: no filehandle available", context);
    if (SvGMAGICAL(sv))
	mg_get(sv);
    if (SvIOK(sv)) /* maybe non-portable but nice for unixen */
	return SvIV(sv);
    if (SvROK(sv))
	sv = SvRV(sv);
    if (SvTYPE(sv) == SVt_PVGV) {
	if (!(io=GvIO((GV*)sv)) || !(fp = IoIFP(io))) {
	    croak("Event '%s': GLOB(0x%x) isn't a valid IO", context, sv);
	}
	return PerlIO_fileno(fp);
    }
    sv_dump(sv);
    croak("Event '%s': can't find fileno", context);
    return -1;
}

static void _queue_io(pe_io *wa, int got) {
    pe_ioevent *ev;
    got &= wa->poll;
    if (!got) {
	if (WaDEBUGx(wa) >= 3) {
	    STRLEN n_a;
	    warn("Event: io '%s' queued nothing", SvPV(wa->base.desc, n_a));
	}
	return;
    }
    ev = (pe_ioevent*) (*wa->base.vtbl->new_event)((pe_watcher*) wa);
    ++ev->base.hits;
    ev->got |= got;
    queueEvent((pe_event*) ev);
}

/************************************************* DEVPOLL */
#if defined(HAS_DEVPOLL) && !PE_SYS_IO
#define PE_SYS_IO 1

static void pe_sys_sleep(NV left) {
    int ret;
    NV t0 = NVtime();
    NV t1 = t0 + left;
    while (1) {
        ret = poll(0, 0, (int) (left * 1000)); /* hope zeroes okay */
        if (ret < 0 && errno != EAGAIN && errno != EINTR)
            croak("poll(%.2f) got errno %d", left, errno);
        left = t1 - NVtime();
        if (left > IntervalEpsilon) {
            if (ret==0) ++TimeoutTooEarly;
            continue;
        }
        break;
    }
}

static void pe_sys_io_add (pe_io *ev) {
    struct pollfd tmp_pfd;
    int bits=0;

    if (ev->fd <= 0 || ev->fd > MAXFD) {
        croak("pe_sys_io_add: non-valid fd (%d)", ev->fd);
        return;
    }

    if (ev->poll & PE_R) bits |= (POLLIN | POLLPRI);
    if (ev->poll & PE_W) bits |= POLLOUT;
    if (ev->poll & PE_E) bits |= (POLLRDBAND | POLLPRI);

    tmp_pfd.fd = ev->fd;
    tmp_pfd.events = bits;

    if (write(dpfd, &tmp_pfd, sizeof(struct pollfd)) != 
        sizeof(struct pollfd)) {
        fprintf(stderr, "pe_sys_io_add(fd %d): could not write fd to /dev/poll", 
            dpfd);
        return;
    }

    if (fdToEvent[ev->fd].ev != NULL) {
        fprintf(stderr, "pe_sys_io_add(fd %d): mapping between fd and event already exists!", ev->fd);
    } else {
        fdToEvent[ev->fd].ev = ev;
    }
}

static void pe_sys_io_del (pe_io *ev) {
    struct pollfd tmp_pfd;
    int bits=0;

    if (ev-> fd <= 0) {
        return;
    }

    if (ev->poll & PE_R) bits |= (POLLIN | POLLPRI);
    if (ev->poll & PE_W) bits |= POLLOUT;
    if (ev->poll & PE_E) bits |= (POLLRDBAND | POLLPRI);

    tmp_pfd.fd = ev->fd;
    tmp_pfd.events = POLLREMOVE;

    if (write(dpfd, &tmp_pfd, sizeof(struct pollfd)) != 
        sizeof(struct pollfd)) {
        fprintf(stderr, "pe_sys_io_del(fd %d): could not write fd to /dev/poll", dpfd);
    }

    fdToEvent[ev->fd].ev = NULL;
}

static void pe_sys_multiplex(NV timeout) {
    pe_io *ev;
    int xx, got, mask, fd;
    int ret;
    int err, m_rfds;
    struct dvpoll dopoll;

    if (pollMax < IOWatchCount) {
        if (Pollfd)
            EvFree(9, Pollfd);
        pollMax = IOWatchCount*2;
        EvNew(9, Pollfd, pollMax, struct pollfd);
        IOWatch_OK = 0;
    }


    if (!IOWatch_OK) {
        Nfds = 0;
        Zero(Pollfd, pollMax, struct pollfd);
        ev = (pe_io*) IOWatch.next->self;
        while (ev) {
            int fd = ev->fd;
            ev->xref = -1;
            assert(fd >= 0); {
                int bits=0;
                if (ev->poll & PE_R) bits |= (POLLIN | POLLPRI);
                if (ev->poll & PE_W) bits |= POLLOUT;
                if (ev->poll & PE_E) bits |= (POLLRDBAND | POLLPRI);
                assert(bits); {
                    Pollfd[Nfds].fd = fd;
                    Pollfd[Nfds].events |= bits;
                    Nfds++;
                }
            }
            ev = (pe_io*) ev->ioring.next->self;
        }
        IOWatch_OK = 1;
    }

    for (xx=0; xx < Nfds; xx++)
        Pollfd[xx].revents = 0; /* needed? XXX */

    if (timeout < 0)
        timeout = 0;

    dopoll.dp_timeout = (int) (timeout * 1000);
    dopoll.dp_nfds = pollMax;
    dopoll.dp_fds = Pollfd;

    /* Wait for I/O events the clients are interested in */
    m_rfds = ioctl(dpfd, DP_POLL, &dopoll);
    if (m_rfds == -1) {
        err = errno;
        fprintf(stderr, "pe_sys_multiplex: poll() returned -1, errno %d\n", err);
        return;
    }

    while (m_rfds >= 1) {
        m_rfds--;
        fd = Pollfd[m_rfds].fd;
        ev = fdToEvent[fd].ev;
        got = 0;
        mask = Pollfd[m_rfds].revents;
        if (mask & (POLLIN | POLLPRI | POLLHUP | POLLERR)) got |= PE_R;
        if (mask & (POLLOUT | POLLERR)) got |= PE_W;
        if (mask & (POLLRDBAND | POLLPRI | POLLHUP | POLLERR)) got |= PE_E;
        if (mask & POLLNVAL) {
            STRLEN n_a;
            warn("Event: '%s' was unexpectedly closed",
                 SvPV(ev->base.desc, n_a));
            pe_io_reset_handle((pe_watcher*) ev);
        } else {
            if ((mask & POLLHUP) && (ev->poll & PE_W) && (!(got & PE_W))
                && (!(ev->poll & PE_R)) && (!(ev->poll & PE_E))) {
              /* Must notify about POLLHUP _some_ way - Allen */
              got |= PE_W;
            }
        }

        if (got) _queue_io(ev, got);

    }
}
#endif /*HAS_DEVPOLL*/

/************************************************* POLL */
#if defined(HAS_POLL) && !PE_SYS_IO
#define PE_SYS_IO 1

static struct pollfd *Pollfd=0;
static int pollMax=0;
static int Nfds;

static void pe_sys_sleep(NV left) {
    int ret;
    NV t0 = NVtime();
    NV t1 = t0 + left;
    while (1) {
	ret = poll(0, 0, (int) (left * 1000)); /* hope zeroes okay */
	if (ret < 0 && errno != EAGAIN && errno != EINTR)
	    croak("poll(%.2f) got errno %d", left, errno);
	left = t1 - NVtime();
	if (left > IntervalEpsilon) {
	    if (ret==0) ++TimeoutTooEarly;
	    continue;
	}
	break;
    }
}

static void pe_sys_io_add (pe_io *ev) {}
static void pe_sys_io_del (pe_io *ev) {}

static void pe_sys_multiplex(NV timeout) {
    pe_io *ev;
    int xx;
    int ret;
    if (pollMax < IOWatchCount) {
	if (Pollfd)
	    EvFree(9, Pollfd);
	pollMax = IOWatchCount+5;
	EvNew(9, Pollfd, pollMax, struct pollfd);
	IOWatch_OK = 0;
    }
    if (!IOWatch_OK) {
	Nfds = 0;
	Zero(Pollfd, pollMax, struct pollfd);
	ev = (pe_io*) IOWatch.next->self;
	while (ev) {
	    int fd = ev->fd;
	    ev->xref = -1;
	    assert(fd >= 0); {
		int bits=0;
		if (ev->poll & PE_R) bits |= (POLLIN | POLLPRI);
		if (ev->poll & PE_W) bits |= POLLOUT;
		if (ev->poll & PE_E) bits |= (POLLRDBAND | POLLPRI);
		assert(bits); {
		    int ok=0;;
		    for (xx = 0; xx < Nfds; xx++) {
			if (Pollfd[xx].fd == fd) { ok=1; break; }
		    }
		    if (!ok) xx = Nfds++;
		    Pollfd[xx].fd = fd;
		    Pollfd[xx].events |= bits;
		    ev->xref = xx;
		}
	    }
	    ev = (pe_io*) ev->ioring.next->self;
	}
	IOWatch_OK = 1;
    }
    for (xx=0; xx < Nfds; xx++)
	Pollfd[xx].revents = 0; /* needed? XXX */
    if (timeout < 0)
	timeout = 0;
    ret = poll(Pollfd, Nfds, (int) (timeout * 1000));
  
    if (ret < 0) {
	if (errno == EINTR || errno == EAGAIN)
	    return;
	if (errno == EINVAL) {
	    warn("poll: bad args %d %.2f", Nfds, timeout);
	    return;
	}
	warn("poll got errno %d", errno);
	return;
    }
    ev = (pe_io*) IOWatch.next->self;
    while (ev) {
	pe_io *next_ev = (pe_io*) ev->ioring.next->self;
	STRLEN n_a;
	int xref = ev->xref;
	if (xref >= 0) {
	    int got = 0;
	    int mask = Pollfd[xref].revents;
	    if (mask & (POLLIN | POLLPRI | POLLHUP | POLLERR)) got |= PE_R;
	    if (mask & (POLLOUT | POLLERR)) got |= PE_W;
	    if (mask & (POLLRDBAND | POLLPRI | POLLHUP | POLLERR)) got |= PE_E;
	    if (mask & POLLNVAL) {
		warn("Event: '%s' was unexpectedly closed",
		     SvPV(ev->base.desc, n_a));
		pe_io_reset_handle((pe_watcher*) ev);
	    } else {
	      if ((mask & POLLHUP) && (ev->poll & PE_W) && (!(got & PE_W))
		  && (!(ev->poll & PE_R)) && (!(ev->poll & PE_E))) {
		/* Must notify about POLLHUP _some_ way - Allen */
		got |= PE_W;
	    }

	      if (got) _queue_io(ev, got);
	    /*
	      Can only do this if fd-to-watcher is 1-to-1
	      if (--ret == 0) { ev=0; continue; }
	    */
	    }
	}
	ev = next_ev;
    }
}
#endif /*HAS_POLL*/


/************************************************* SELECT */
#if defined(HAS_SELECT) && !PE_SYS_IO
#define PE_SYS_IO 1

static int Nfds;
static fd_set Rfds, Wfds, Efds;

static void pe_sys_sleep(NV left) {
    struct timeval tm;
    NV t0 = NVtime();
    NV t1 = t0 + left;
    int ret;
    while (1) {
	tm.tv_sec = left;
	tm.tv_usec = (left - tm.tv_sec) * 1000000;
	ret = select(0, 0, 0, 0, &tm);
	if (ret < 0 && errno != EINTR && errno != EAGAIN)
	    croak("select(%.2f) got errno %d", left, errno);
	left = t1 - NVtime();
	if (left > IntervalEpsilon) {
	    if (ret==0) ++TimeoutTooEarly;
	    continue;
	}
	break;
    }
}

static void pe_sys_io_add (pe_io *ev) {}
static void pe_sys_io_del (pe_io *ev) {}

static void pe_sys_multiplex(NV timeout) {
    struct timeval tm;
    int ret;
    fd_set rfds, wfds, efds;
    pe_io *ev;

    if (!IOWatch_OK) {
	Nfds = -1;
	FD_ZERO(&Rfds);
	FD_ZERO(&Wfds);
	FD_ZERO(&Efds);
	ev = IOWatch.next->self;
	while (ev) {
	    int fd = ev->fd;
	    if (fd >= 0) {
		int bits=0;
		if (ev->poll & PE_R) { FD_SET(fd, &Rfds); ++bits; }
		if (ev->poll & PE_W) { FD_SET(fd, &Wfds); ++bits; }
		if (ev->poll & PE_E) { FD_SET(fd, &Efds); ++bits; }
		if (bits && fd > Nfds) Nfds = fd;
	    }
	    ev = ev->ioring.next->self;
	}
	IOWatch_OK = 1;
    }

    if (timeout < 0)
	timeout = 0;
    tm.tv_sec = timeout;
    tm.tv_usec = (timeout - tm.tv_sec) * 1000000;
    if (Nfds > -1) {
	memcpy(&rfds, &Rfds, sizeof(fd_set));
	memcpy(&wfds, &Wfds, sizeof(fd_set));
	memcpy(&efds, &Efds, sizeof(fd_set));
	ret = select(Nfds+1, &rfds, &wfds, &efds, &tm);
    }
    else
	ret = select(0, 0, 0, 0, &tm);

    if (ret < 0) {
	if (errno == EINTR)
	    return;
	if (errno == EBADF) {
	    STRLEN n_a;
	    ev = IOWatch.next->self;
	    while (ev) {
		int fd = ev->fd;
		struct stat buf;
		if (fd >= 0 && PerlLIO_fstat(fd, &buf) < 0 && errno == EBADF) {
		    warn("Event: '%s' was unexpectedly closed",
			 SvPV(ev->base.desc, n_a));
		    pe_io_reset_handle((pe_watcher*) ev);
		    return;
		}
		ev = ev->ioring.next->self;
	    }
	    warn("select: couldn't find cause of EBADF");
	    return;
	}
	if (errno == EINVAL) {
	    warn("select: bad args %d %.2f", Nfds, timeout);
	    return;
	}
	warn("select got errno %d", errno);
	return;
    }
    ev = IOWatch.next->self;
    while (ev) {
	pe_io *next_ev = (pe_io*) ev->ioring.next->self;
	int fd = ev->fd;
	if (fd >= 0) {
	    int got = 0;
	    if (FD_ISSET(fd, &rfds)) got |= PE_R;
	    if (FD_ISSET(fd, &wfds)) got |= PE_W;
	    if (FD_ISSET(fd, &efds)) got |= PE_E;
	    if (got) _queue_io(ev, got);
	    /*
	      Can only do this if fd-to-watcher is 1-to-1
	  
	      if (--ret == 0) { ev=0; continue; }
	    */
	}
	ev = next_ev;
    }
}
#endif /*HAS_SELECT*/
