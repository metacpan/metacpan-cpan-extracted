#ifndef FT_WIN_H
#define FT_WIN_H

/* Portability shim for the socket/IO surface. On a POSIX host these are
 * zero-overhead passthroughs, so the Unix build is unchanged. On native
 * Windows they map onto Winsock: every socket is wrapped in a C-runtime fd via
 * _open_osfhandle() so the rest of Fetch keeps its dense "int fd" model (the
 * loop's per-fd callback arrays and the backend all stay as-is), and the real
 * SOCKET is recovered with _get_osfhandle() only at the Winsock call boundary.
 *
 * Included first from ft_core.h, before ft_http.h et al. */

#ifdef _WIN32

/* raise the select() descriptor set before winsock2.h fixes FD_SETSIZE */
#ifndef FD_SETSIZE
#define FD_SETSIZE 4096
#endif
/* rand_s() is gated behind _CRT_RAND_S, which must be set before the FIRST
 * <stdlib.h> - and perl.h already pulled that in long before us. So the real
 * define lives at the very top of Fetch.xs (before any include); this is a
 * guarded backstop that never clashes with it. */
#ifndef _CRT_RAND_S
#define _CRT_RAND_S
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#include <io.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>

#ifndef EINPROGRESS
#define EINPROGRESS WSAEINPROGRESS
#endif
#ifndef EWOULDBLOCK
#define EWOULDBLOCK WSAEWOULDBLOCK
#endif

/* one-time Winsock startup, run lazily from the first socket() */
static int ft_win_started = 0;
static void ft_win_init(void) {
    if (!ft_win_started) {
        WSADATA wsa;
        WSAStartup(MAKEWORD(2, 2), &wsa);
        ft_win_started = 1;
    }
}

/* translate the last Winsock error into the errno value the core checks */
static void ft_win_seterrno(void) {
    switch (WSAGetLastError()) {
        case WSAEWOULDBLOCK: errno = EWOULDBLOCK; break;
        case WSAEINPROGRESS:
        case WSAEALREADY:    errno = EINPROGRESS; break;
        case WSAEINTR:       errno = EINTR;       break;
        case WSAECONNRESET:  errno = ECONNRESET;  break;
        case WSAECONNREFUSED:errno = ECONNREFUSED;break;
        case WSAETIMEDOUT:   errno = ETIMEDOUT;   break;
        default:             errno = EIO;         break;
    }
}

/* the real SOCKET behind a Fetch fd (for Winsock calls / SSL_set_fd) */
#define FT_SOCK(fd) ((SOCKET)_get_osfhandle(fd))

static int ft_os_socket(int af, int type, int proto) {
    SOCKET s;
    int fd;
    ft_win_init();
    s = socket(af, type, proto);
    if (s == INVALID_SOCKET) { ft_win_seterrno(); return -1; }
    fd = _open_osfhandle((intptr_t)s, O_RDWR | O_BINARY);
    if (fd < 0) { closesocket(s); errno = EMFILE; return -1; }
    return fd;
}

static void ft_os_set_nonblock(int fd) {
    u_long on = 1;
    ioctlsocket(FT_SOCK(fd), FIONBIO, &on);
}

static int ft_os_connect(int fd, const struct sockaddr *a, int alen) {
    if (connect(FT_SOCK(fd), a, alen) == 0) return 0;
    ft_win_seterrno();
    return -1;
}

static ssize_t ft_os_recv(int fd, void *buf, size_t n, int flags) {
    int r = recv(FT_SOCK(fd), (char *)buf, (int)n, flags);
    if (r == SOCKET_ERROR) { ft_win_seterrno(); return -1; }
    return r;
}

static ssize_t ft_os_send(int fd, const void *buf, size_t n, int flags) {
    int r = send(FT_SOCK(fd), (const char *)buf, (int)n, flags);
    if (r == SOCKET_ERROR) { ft_win_seterrno(); return -1; }
    return r;
}

static int ft_os_getsockopt(int fd, int lvl, int opt, void *val, socklen_t *len) {
    int r = getsockopt(FT_SOCK(fd), lvl, opt, (char *)val, (int *)len);
    if (r == SOCKET_ERROR) { ft_win_seterrno(); return -1; }
    return r;
}

/* _close releases both the CRT fd slot and (via CloseHandle) the socket */
static int ft_os_close(int fd) { return _close(fd); }

/* OpenSSL on Windows wants the SOCKET, not the CRT fd (socket handle values
 * fit an int in practice, so the cast is safe) */
#define FT_SSL_FD(fd) ((int)FT_SOCK(fd))

/* random bytes (WebSocket key + frame masks) via the CRT's rand_s */
static void ft_os_random(unsigned char *out, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) {
        unsigned int v;
        if (rand_s(&v) != 0) v = (unsigned int)rand();
        out[i] = (unsigned char)v;
    }
}

#else  /* ---- POSIX: exact passthroughs, the Unix build is unchanged ---- */

#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>
#include <time.h>

#define ft_win_init()                       ((void)0)
#define ft_os_socket(af, ty, pr)            socket((af), (ty), (pr))
#define ft_os_connect(fd, a, l)             connect((fd), (a), (l))
#define ft_os_recv(fd, b, n, f)             recv((fd), (b), (n), (f))
#define ft_os_send(fd, b, n, f)             send((fd), (b), (n), (f))
#define ft_os_getsockopt(fd, lv, op, v, l)  getsockopt((fd), (lv), (op), (v), (l))
#define ft_os_close(fd)                     close((fd))
#define FT_SSL_FD(fd)                       (fd)

static void ft_os_set_nonblock(int fd) {
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
}

/* random bytes via /dev/urandom, falling back to a seeded LCG */
static void ft_os_random(unsigned char *out, size_t n) {
    int fd = open("/dev/urandom", O_RDONLY);
    size_t got = 0;
    if (fd >= 0) {
        while (got < n) {
            ssize_t r = read(fd, out + got, n - got);
            if (r <= 0) break;
            got += (size_t)r;
        }
        close(fd);
    }
    if (got < n) {
        static uint32_t seed;
        size_t i;
        if (!seed) seed = (uint32_t)(time(NULL) ^ (uintptr_t)&fd ^ (uintptr_t)getpid());
        for (i = got; i < n; i++) {
            seed = seed * 1103515245u + 12345u;
            out[i] = (unsigned char)(seed >> 16);
        }
    }
}

#endif /* _WIN32 */

/* memmem is a GNU/BSD extension the MinGW CRT lacks; use the C library's where
 * it exists and a plain scan on Windows. The needles here (\r\n, \r\n\r\n) are
 * tiny, so the fallback's O(n*m) is fine. */
#include <string.h>
#if defined(_WIN32)
static void *ft_memmem(const void *hay, size_t hlen, const void *ndl, size_t nlen) {
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
#define ft_memmem memmem
#endif

#endif /* FT_WIN_H */
