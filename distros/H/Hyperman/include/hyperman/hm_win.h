#ifndef HM_WIN_H
#define HM_WIN_H

/* hm_win.h - the platform shim for the socket/IO surface.
 *
 * On a POSIX host every entry point below is a macro expanding to the bare
 * system call, so the Unix build is byte-for-byte what it was before this
 * header existed: no wrapper frame, no branch, nothing for the optimiser to
 * undo. On native Windows they map onto Winsock, with every SOCKET wrapped
 * in a C-runtime fd by _open_osfhandle() so the rest of Hyperman keeps its
 * dense "int fd" model - loop->conns[HM_MAXFD], the io watcher arrays and
 * every backend's fd->index table stay exactly as written - and the real
 * SOCKET is recovered with _get_osfhandle() only at the Winsock boundary.
 * That is the same trick Fetch uses (fetch/ft_win.h); it is what makes the
 * port a shim rather than a rewrite.
 *
 * Everything here is prefixed hm_ / HM_ on purpose. perl.h has already
 * pulled the platform headers by the time this is included, and reusing an
 * ambient name it may have defined is how Eshu spent three releases.
 *
 * Included first from hm_core.h, before hm_parse.h / hm_tls.h / the backends.
 */

#ifdef _WIN32

/* select()'s descriptor set is sized at winsock2.h include time; raise it
 * before the first one wins. Nothing here uses select(), but a backend or a
 * consumer might, and the define is free. */
#ifndef FD_SETSIZE
#define FD_SETSIZE 4096
#endif

#include <winsock2.h>
#include <ws2tcpip.h>
#include <mswsock.h>
#include <io.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#ifndef EINPROGRESS
#define EINPROGRESS WSAEINPROGRESS
#endif
#ifndef EWOULDBLOCK
#define EWOULDBLOCK WSAEWOULDBLOCK
#endif

/* Winsock needs an explicit startup, once per process. Lazily from the
 * first socket we make: a process that never listens never pays it, and
 * there is no teardown - the process exiting is the teardown, and a
 * WSACleanup at unload races anything still holding a socket. */
static int hm_win_started = 0;
static void hm_os_init(void) {
    if (!hm_win_started) {
        WSADATA wsa;
        WSAStartup(MAKEWORD(2, 2), &wsa);
        hm_win_started = 1;
    }
}

/* Winsock keeps its error out of errno; the core reads errno everywhere
 * (EAGAIN drives the whole backpressure path), so translate at each call. */
static void hm_os_seterrno(void) {
    switch (WSAGetLastError()) {
        case WSAEWOULDBLOCK:  errno = EWOULDBLOCK;  break;
        case WSAEINPROGRESS:
        case WSAEALREADY:     errno = EINPROGRESS;  break;
        case WSAEINTR:        errno = EINTR;        break;
        case WSAECONNRESET:   errno = ECONNRESET;   break;
        case WSAECONNABORTED: errno = ECONNABORTED; break;
        case WSAECONNREFUSED: errno = ECONNREFUSED; break;
        case WSAETIMEDOUT:    errno = ETIMEDOUT;    break;
        case WSAEMFILE:       errno = EMFILE;       break;
        case WSAENOTSOCK:     errno = EBADF;        break;
        default:              errno = EIO;          break;
    }
}

/* the SOCKET behind one of our fds */
#define HM_SOCK(fd) ((SOCKET)_get_osfhandle(fd))

/* OpenSSL on Windows wants the SOCKET, not the CRT fd. Socket handle
 * values fit in an int in practice, which is the assumption OpenSSL's own
 * API makes. */
#define HM_SSL_FD(fd) ((int)HM_SOCK(fd))

/* wrap a fresh SOCKET in a CRT fd, or -1 */
static int hm_os_wrap(SOCKET s) {
    int fd;
    if (s == INVALID_SOCKET) { hm_os_seterrno(); return -1; }
    fd = _open_osfhandle((intptr_t)s, O_RDWR | O_BINARY);
    if (fd < 0) { closesocket(s); errno = EMFILE; return -1; }
    return fd;
}

static int hm_os_socket(int af, int type, int proto) {
    hm_os_init();
    return hm_os_wrap(socket(af, type, proto));
}

static int hm_os_accept(int fd, struct sockaddr *sa, socklen_t *len) {
    return hm_os_wrap(accept(HM_SOCK(fd), sa, len));
}

static int hm_os_bind(int fd, const struct sockaddr *sa, socklen_t len) {
    if (bind(HM_SOCK(fd), sa, len) == 0) return 0;
    hm_os_seterrno();
    return -1;
}

static int hm_os_listen(int fd, int backlog) {
    if (listen(HM_SOCK(fd), backlog) == 0) return 0;
    hm_os_seterrno();
    return -1;
}

static int hm_os_setsockopt(int fd, int lvl, int opt, const void *v, socklen_t len) {
    if (setsockopt(HM_SOCK(fd), lvl, opt, (const char *)v, (int)len) == 0) return 0;
    hm_os_seterrno();
    return -1;
}

static int hm_os_getsockname(int fd, struct sockaddr *sa, socklen_t *len) {
    if (getsockname(HM_SOCK(fd), sa, len) == 0) return 0;
    hm_os_seterrno();
    return -1;
}

/* _close releases the CRT fd slot and, through it, the socket handle */
static int hm_os_close(int fd) { return _close(fd); }

static void hm_os_set_nonblock(int fd) {
    u_long on = 1;
    ioctlsocket(HM_SOCK(fd), FIONBIO, &on);
}

/* read/write on a CRT-wrapped socket is not portable - the CRT would go
 * through ReadFile/WriteFile, which is not the socket path we want (and
 * not what non-blocking sockets answer to). Always recv/send. */
static ssize_t hm_os_recv(int fd, void *buf, size_t n) {
    int r = recv(HM_SOCK(fd), (char *)buf, (int)n, 0);
    if (r == SOCKET_ERROR) { hm_os_seterrno(); return -1; }
    return r;
}

static ssize_t hm_os_send(int fd, const void *buf, size_t n) {
    int r = send(HM_SOCK(fd), (const char *)buf, (int)n, 0);
    if (r == SOCKET_ERROR) { hm_os_seterrno(); return -1; }
    return r;
}

#include <process.h>
#include <sys/stat.h>
#define hm_os_getpid() ((int)_getpid())

/* Plain FILE descriptors (the access log), as opposed to sockets. MSVC
 * spells these with the underscore; the un-prefixed names are deprecated
 * aliases that a strict build can refuse. */
#define hm_os_open_file(path, flags, mode) _open((path), (flags), (mode))
#define hm_os_write_file(fd, buf, n)       _write((fd), (buf), (unsigned int)(n))

/* Positional read (streaming response bodies). Windows has no pread; the
 * seek-then-read pair is equivalent HERE because a loop owns its fds and
 * this server is single-threaded per process - there is no other reader
 * to race the file position with. */
static ssize_t hm_os_pread(int fd, void *buf, size_t n, __int64 off) {
    if (_lseeki64(fd, off, SEEK_SET) < 0) return -1;
    return (ssize_t)_read(fd, buf, (unsigned int)n);
}

/* One worker on Windows: there is no fork, and perl's emulation of it is
 * ithreads - N interpreters in ONE process, sharing the file-scope state
 * this server keeps per process. So the DEFAULT resolves to a single
 * worker that works, and an explicit workers => N > 1 is refused at boot
 * rather than silently downgraded (hm_run_server). */
#define hm_os_ncpu() (1)

/* Windows has no SIGPIPE (no signal for it to raise) and no SIGUSR1. The
 * numbers exist only so the same add_signal calls compile; the WSAPoll
 * backend accepts them and never delivers them, which is what the POD
 * says. SIGINT/SIGTERM are real there and come from the console handler. */
#ifndef SIGPIPE
#define SIGPIPE 13
#endif
#ifndef SIGUSR1
#define SIGUSR1 30
#endif
#ifndef SIGUSR2
#define SIGUSR2 31
#endif
#ifndef SIGHUP
#define SIGHUP 1
#endif
#ifndef O_CLOEXEC
#define O_CLOEXEC 0        /* no fork to leak into; nothing to close-on-exec */
#endif

/* A self-pipe: two connected fds, the write end pokeable from anywhere to
 * wake a blocked wait. Windows has pipes, but WSAPoll can only poll
 * SOCKETS, so the pair has to be a loopback TCP connection: listen on
 * 127.0.0.1:0, connect to it, accept. Both ends non-blocking. 0 or -1. */
static int hm_os_selfpipe(int *rfd, int *wfd) {
    int lst = -1, a = -1, b = -1;
    struct sockaddr_in addr;
    socklen_t alen = sizeof(addr);

    hm_os_init();
    lst = hm_os_socket(AF_INET, SOCK_STREAM, 0);
    if (lst < 0) return -1;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0;
    if (hm_os_bind(lst, (struct sockaddr *)&addr, sizeof(addr)) < 0) goto fail;
    if (hm_os_listen(lst, 1) < 0) goto fail;
    if (hm_os_getsockname(lst, (struct sockaddr *)&addr, &alen) < 0) goto fail;

    b = hm_os_socket(AF_INET, SOCK_STREAM, 0);
    if (b < 0) goto fail;
    if (connect(HM_SOCK(b), (struct sockaddr *)&addr, sizeof(addr)) != 0) goto fail;
    a = hm_os_accept(lst, NULL, NULL);
    if (a < 0) goto fail;

    hm_os_close(lst);
    hm_os_set_nonblock(a);
    hm_os_set_nonblock(b);
    *rfd = a; *wfd = b;
    return 0;
fail:
    if (lst >= 0) hm_os_close(lst);
    if (a >= 0)   hm_os_close(a);
    if (b >= 0)   hm_os_close(b);
    return -1;
}

/* scatter/gather: WSABUF is struct iovec with the fields swapped */
typedef WSABUF hm_iovec;
#define HM_IOV_SET(iov, i, base, n) \
    do { (iov)[i].buf = (char *)(base); (iov)[i].len = (ULONG)(n); } while (0)

static ssize_t hm_os_writev(int fd, hm_iovec *iov, int n) {
    DWORD sent = 0;
    if (WSASend(HM_SOCK(fd), iov, (DWORD)n, &sent, 0, NULL, NULL) == SOCKET_ERROR) {
        hm_os_seterrno();
        return -1;
    }
    return (ssize_t)sent;
}

#else  /* ---- POSIX: passthroughs, so the Unix build is unchanged ---- */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#define hm_os_init()                            ((void)0)
#define hm_os_seterrno()                        ((void)0)
#define HM_SOCK(fd)                             (fd)
#define HM_SSL_FD(fd)                           (fd)
#define hm_os_socket(af, ty, pr)                socket((af), (ty), (pr))
#define hm_os_accept(fd, sa, len)               accept((fd), (sa), (len))
#define hm_os_bind(fd, sa, len)                 bind((fd), (sa), (len))
#define hm_os_listen(fd, backlog)               listen((fd), (backlog))
#define hm_os_setsockopt(fd, lv, op, v, len)    setsockopt((fd), (lv), (op), (v), (len))
#define hm_os_getsockname(fd, sa, len)          getsockname((fd), (sa), (len))
#define hm_os_close(fd)                         close((fd))
#define hm_os_recv(fd, b, n)                    read((fd), (b), (n))
#define hm_os_send(fd, b, n)                    write((fd), (b), (n))
#define hm_os_writev(fd, iov, n)                writev((fd), (iov), (n))
#define hm_os_getpid()                          ((int)getpid())
#define hm_os_open_file(path, flags, mode)      open((path), (flags), (mode))
#define hm_os_write_file(fd, buf, n)            write((fd), (buf), (n))
#define hm_os_pread(fd, buf, n, off)            pread((fd), (buf), (n), (off))

/* the same self-pipe, where a pipe is pollable */
static int hm_os_selfpipe(int *rfd, int *wfd) {
    int fds[2];
    if (pipe(fds) < 0) return -1;
    fcntl(fds[0], F_SETFL, fcntl(fds[0], F_GETFL, 0) | O_NONBLOCK);
    fcntl(fds[1], F_SETFL, fcntl(fds[1], F_GETFL, 0) | O_NONBLOCK);
    *rfd = fds[0]; *wfd = fds[1];
    return 0;
}

#include <unistd.h>
/* the default worker count: one per CPU */
static int hm_os_ncpu(void) {
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return n > 0 ? (int)n : 1;
}

typedef struct iovec hm_iovec;
#define HM_IOV_SET(iov, i, base, n) \
    do { (iov)[i].iov_base = (void *)(base); (iov)[i].iov_len = (n); } while (0)

static void hm_os_set_nonblock(int fd) {
    int fl = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, fl | O_NONBLOCK);
}

#endif /* _WIN32 */

/* memmem is a GNU/BSD extension the MinGW and MSVC CRTs lack. The needles
 * here are the request terminators (\r\n\r\n), so the fallback's O(n*m) is
 * bounded by a header block, not by a body. */
#if defined(_WIN32)
static void *hm_memmem(const void *hay, size_t hlen, const void *ndl, size_t nlen) {
    const unsigned char *h = (const unsigned char *)hay;
    const unsigned char *n = (const unsigned char *)ndl;
    size_t i;
    if (nlen == 0) return (void *)hay;
    if (hlen < nlen) return NULL;
    for (i = 0; i + nlen <= hlen; i++)
        if (h[i] == n[0] && memcmp(h + i, n, nlen) == 0) return (void *)(h + i);
    return NULL;
}
#else
#define hm_memmem memmem
#endif

#endif /* HM_WIN_H */
