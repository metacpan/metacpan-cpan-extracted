#include <errno.h>
#include <limits.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

#define H2O_USE_LIBUV 0
#include <h2o.h>

static h2o_globalconf_t config;
static h2o_context_t ctx;
static h2o_accept_ctx_t accept_ctx;
static const char *response_body;
static size_t response_body_len;

static int on_request(h2o_handler_t *self, h2o_req_t *req)
{
    (void)self;

    req->res.status = 200;
    req->res.reason = "OK";
    req->res.content_length = response_body_len;
    h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_CONTENT_TYPE, NULL,
                   H2O_STRLIT("application/octet-stream"));
    h2o_send_inline(req, response_body, response_body_len);
    return 0;
}

static void on_accept(h2o_socket_t *listener, const char *err)
{
    h2o_socket_t *sock;

    if (err != NULL)
        return;
    if ((sock = h2o_evloop_socket_accept(listener)) == NULL)
        return;
    h2o_accept(&accept_ctx, sock);
}

static int create_listener(unsigned port)
{
    struct sockaddr_in addr;
    int fd;
    int reuseaddr = 1;
    h2o_socket_t *sock;

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(0x7f000001);
    addr.sin_port = htons((uint16_t)port);

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd == -1)
        return -1;
    if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr)) != 0 ||
        bind(fd, (struct sockaddr *)&addr, sizeof(addr)) != 0 ||
        listen(fd, SOMAXCONN) != 0) {
        return -1;
    }

    sock = h2o_evloop_socket_create(ctx.loop, fd, H2O_SOCKET_FLAG_DONT_READ);
    h2o_socket_read_start(sock, on_accept);
    return 0;
}

static unsigned parse_port(void)
{
    const char *value = getenv("BENCH_PORT");
    char *end;
    unsigned long port;

    if (value == NULL || *value == '\0') {
        fprintf(stderr, "BENCH_PORT is required\n");
        exit(2);
    }
    errno = 0;
    port = strtoul(value, &end, 10);
    if (errno != 0 || *end != '\0' || port == 0 || port > 65535) {
        fprintf(stderr, "BENCH_PORT must be an integer from 1 through 65535\n");
        exit(2);
    }
    return (unsigned)port;
}

static size_t parse_response_bytes(void)
{
    const char *value = getenv("BENCH_RESPONSE_BYTES");
    char *end;
    unsigned long long bytes;

    if (value == NULL || *value == '\0')
        return 32;

    errno = 0;
    bytes = strtoull(value, &end, 10);
    if (errno != 0 || *end != '\0' || bytes > SIZE_MAX) {
        fprintf(stderr, "BENCH_RESPONSE_BYTES must be a non-negative integer\n");
        exit(2);
    }
    return (size_t)bytes;
}

int main(void)
{
    unsigned port = parse_port();
    h2o_hostconf_t *hostconf;
    h2o_pathconf_t *pathconf;
    h2o_handler_t *handler;
    char *payload = NULL;

    signal(SIGPIPE, SIG_IGN);

    response_body_len = parse_response_bytes();
    if (response_body_len != 0) {
        payload = malloc(response_body_len);
        if (payload == NULL) {
            perror("malloc");
            return 1;
        }
        memset(payload, 'x', response_body_len);
        response_body = payload;
    } else {
        response_body = "";
    }

    h2o_config_init(&config);
    hostconf = h2o_config_register_host(
        &config, h2o_iovec_init(H2O_STRLIT("benchmark.test")), 65535);
    pathconf = h2o_config_register_path(hostconf, "/", 0);
    handler = h2o_create_handler(pathconf, sizeof(*handler));
    handler->on_req = on_request;

    h2o_context_init(&ctx, h2o_evloop_create(), &config);
    accept_ctx.ctx = &ctx;
    accept_ctx.hosts = config.hosts;

    if (create_listener(port) != 0) {
        fprintf(stderr, "failed to listen to 127.0.0.1:%u: %s\n", port,
                strerror(errno));
        return 1;
    }

    while (h2o_evloop_run(ctx.loop, INT32_MAX) == 0)
        ;

    return 1;
}
