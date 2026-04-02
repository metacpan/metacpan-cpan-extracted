package Hypersonic::UA::WebSocket;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant MAX_WS_CLIENT_CONNS => 1024;

use constant {
    STATE_CONNECTING => 0,
    STATE_OPEN       => 1,
    STATE_CLOSING    => 2,
    STATE_CLOSED     => 3,
};

use constant {
    OP_CONTINUATION => 0x00,
    OP_TEXT         => 0x01,
    OP_BINARY       => 0x02,
    OP_CLOSE        => 0x08,
    OP_PING         => 0x09,
    OP_PONG         => 0x0A,
};

use constant {
    SLOT_FD        => 0,
    SLOT_UA        => 1,
    SLOT_URL       => 2,
    SLOT_CALLBACKS => 3,
    SLOT_PROTOCOLS => 4,
};

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_conns = $opts->{max_ws_client_conns} // MAX_WS_CLIENT_CONNS;

    $builder->line('#include <openssl/ssl.h>')
      ->line('#include <openssl/sha.h>')
      ->line('#include <openssl/rand.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <netdb.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->line('#include <unistd.h>')
      ->line('#include <string.h>')
      ->line('#include <stdlib.h>')
      ->blank;

    $class->gen_websocket_registry($builder, $max_conns);
    $class->gen_base64_codec($builder);
    $class->gen_frame_encoder($builder);
    $class->gen_frame_decoder($builder);
    $class->gen_xs_new($builder);
    $class->gen_xs_connect($builder);
    $class->gen_xs_send($builder);
    $class->gen_xs_send_binary($builder);
    $class->gen_xs_ping($builder);
    $class->gen_xs_pong($builder);
    $class->gen_xs_close($builder);
    $class->gen_xs_recv_frame($builder);
    $class->gen_xs_state($builder);
    $class->gen_xs_is_open($builder);
    $class->gen_xs_fd($builder);
    $class->gen_xs_cleanup($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::WebSocket::new'         => { source => 'xs_ws_client_new', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::connect'     => { source => 'xs_ws_client_connect', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::send'        => { source => 'xs_ws_client_send', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::send_binary' => { source => 'xs_ws_client_send_binary', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::ping'        => { source => 'xs_ws_client_ping', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::pong'        => { source => 'xs_ws_client_pong', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::close'       => { source => 'xs_ws_client_close', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::recv_frame'  => { source => 'xs_ws_client_recv_frame', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::state'       => { source => 'xs_ws_client_state', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::is_open'     => { source => 'xs_ws_client_is_open', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::fd'          => { source => 'xs_ws_client_fd', is_xs_native => 1 },
        'Hypersonic::UA::WebSocket::cleanup'     => { source => 'xs_ws_client_cleanup', is_xs_native => 1 },
    };
}

sub gen_websocket_registry {
    my ($class, $builder, $max_conns) = @_;

    $builder->line("#define MAX_WS_CLIENT_CONNS $max_conns")
      ->line('#define WS_STATE_CONNECTING 0')
      ->line('#define WS_STATE_OPEN 1')
      ->line('#define WS_STATE_CLOSING 2')
      ->line('#define WS_STATE_CLOSED 3')
      ->blank
      ->line('#define WS_OP_CONTINUATION 0x00')
      ->line('#define WS_OP_TEXT 0x01')
      ->line('#define WS_OP_BINARY 0x02')
      ->line('#define WS_OP_CLOSE 0x08')
      ->line('#define WS_OP_PING 0x09')
      ->line('#define WS_OP_PONG 0x0A')
      ->blank
      ->line('#define WS_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int fd;')
      ->line('    SSL *ssl;')
      ->line('    int state;')
      ->line('    uint16_t close_code;')
      ->line('    char *recv_buffer;')
      ->line('    size_t recv_buffer_len;')
      ->line('    size_t recv_buffer_cap;')
      ->line('    int in_use;')
      ->line('} WSClientConnection;')
      ->blank;

    $builder->line("static WSClientConnection ws_client_registry[MAX_WS_CLIENT_CONNS];")
      ->blank;

    $builder->line('static int ws_client_alloc_slot(void) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_WS_CLIENT_CONNS; i++) {')
      ->line('        if (!ws_client_registry[i].in_use) {')
      ->line('            memset(&ws_client_registry[i], 0, sizeof(WSClientConnection));')
      ->line('            ws_client_registry[i].in_use = 1;')
      ->line('            ws_client_registry[i].fd = -1;')
      ->line('            ws_client_registry[i].state = WS_STATE_CONNECTING;')
      ->line('            return i;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank;

    $builder->line('static void ws_client_free_slot(int slot) {')
      ->line('    if (slot < 0 || slot >= MAX_WS_CLIENT_CONNS) return;')
      ->line('    WSClientConnection *conn = &ws_client_registry[slot];')
      ->line('    if (conn->recv_buffer) { free(conn->recv_buffer); conn->recv_buffer = NULL; }')
      ->line('    if (conn->ssl) { SSL_shutdown(conn->ssl); SSL_free(conn->ssl); conn->ssl = NULL; }')
      ->line('    if (conn->fd >= 0) { close(conn->fd); conn->fd = -1; }')
      ->line('    conn->in_use = 0;')
      ->line('}')
      ->blank;
}

sub gen_base64_codec {
    my ($class, $builder) = @_;

    $builder->line('static const char base64_chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";')
      ->blank;

    $builder->line('static size_t ws_base64_encode(const unsigned char *in, size_t in_len, char *out) {')
      ->line('    size_t i, j;')
      ->line('    for (i = 0, j = 0; i < in_len; ) {')
      ->line('        uint32_t octet_a = i < in_len ? in[i++] : 0;')
      ->line('        uint32_t octet_b = i < in_len ? in[i++] : 0;')
      ->line('        uint32_t octet_c = i < in_len ? in[i++] : 0;')
      ->line('        uint32_t triple = (octet_a << 16) | (octet_b << 8) | octet_c;')
      ->line('        out[j++] = base64_chars[(triple >> 18) & 0x3F];')
      ->line('        out[j++] = base64_chars[(triple >> 12) & 0x3F];')
      ->line('        out[j++] = base64_chars[(triple >> 6) & 0x3F];')
      ->line('        out[j++] = base64_chars[triple & 0x3F];')
      ->line('    }')
      ->line('    int mod = in_len % 3;')
      ->line('    if (mod > 0) {')
      ->line('        out[j - 1] = \'=\';')
      ->line('        if (mod == 1) out[j - 2] = \'=\';')
      ->line('    }')
      ->line('    out[j] = \'\\0\';')
      ->line('    return j;')
      ->line('}')
      ->blank;
}

sub gen_frame_encoder {
    my ($class, $builder) = @_;

    $builder->line('static size_t ws_client_encode_frame(unsigned char *out, const unsigned char *data, size_t data_len, int opcode, int fin) {')
      ->line('    size_t offset = 0;')
      ->line('    size_t i;')
      ->blank
      ->line('    out[offset++] = (fin ? 0x80 : 0x00) | (opcode & 0x0F);')
      ->blank
      ->line('    if (data_len < 126) {')
      ->line('        out[offset++] = 0x80 | data_len;')
      ->line('    } else if (data_len < 65536) {')
      ->line('        out[offset++] = 0x80 | 126;')
      ->line('        out[offset++] = (data_len >> 8) & 0xFF;')
      ->line('        out[offset++] = data_len & 0xFF;')
      ->line('    } else {')
      ->line('        out[offset++] = 0x80 | 127;')
      ->line('        out[offset++] = 0; out[offset++] = 0;')
      ->line('        out[offset++] = 0; out[offset++] = 0;')
      ->line('        out[offset++] = (data_len >> 24) & 0xFF;')
      ->line('        out[offset++] = (data_len >> 16) & 0xFF;')
      ->line('        out[offset++] = (data_len >> 8) & 0xFF;')
      ->line('        out[offset++] = data_len & 0xFF;')
      ->line('    }')
      ->blank
      ->line('    unsigned char mask[4];')
      ->line('    RAND_bytes(mask, 4);')
      ->line('    memcpy(out + offset, mask, 4);')
      ->line('    offset += 4;')
      ->blank
      ->line('    for (i = 0; i < data_len; i++) {')
      ->line('        out[offset + i] = data[i] ^ mask[i & 3];')
      ->line('    }')
      ->blank
      ->line('    return offset + data_len;')
      ->line('}')
      ->blank;

    $builder->line('static size_t ws_client_frame_size(size_t data_len) {')
      ->line('    if (data_len < 126) return 2 + 4 + data_len;')
      ->line('    if (data_len < 65536) return 4 + 4 + data_len;')
      ->line('    return 10 + 4 + data_len;')
      ->line('}')
      ->blank;
}

sub gen_frame_decoder {
    my ($class, $builder) = @_;

    $builder->line('typedef struct {')
      ->line('    int fin;')
      ->line('    int opcode;')
      ->line('    unsigned char *payload;')
      ->line('    size_t payload_len;')
      ->line('    size_t consumed;')
      ->line('} WSFrame;')
      ->blank;

    $builder->line('static int ws_client_decode_frame(const unsigned char *buf, size_t buf_len, WSFrame *frame) {')
      ->line('    size_t i;')
      ->line('    if (buf_len < 2) return 0;')
      ->blank
      ->line('    frame->fin = (buf[0] >> 7) & 1;')
      ->line('    frame->opcode = buf[0] & 0x0F;')
      ->line('    int masked = (buf[1] >> 7) & 1;')
      ->line('    size_t payload_len = buf[1] & 0x7F;')
      ->line('    size_t header_len = 2;')
      ->blank
      ->line('    if (payload_len == 126) {')
      ->line('        if (buf_len < 4) return 0;')
      ->line('        payload_len = ((size_t)buf[2] << 8) | buf[3];')
      ->line('        header_len = 4;')
      ->line('    } else if (payload_len == 127) {')
      ->line('        if (buf_len < 10) return 0;')
      ->line('        payload_len = ((size_t)buf[6] << 24) | ((size_t)buf[7] << 16) |')
      ->line('                      ((size_t)buf[8] << 8) | (size_t)buf[9];')
      ->line('        header_len = 10;')
      ->line('    }')
      ->blank
      ->line('    unsigned char *mask_key = NULL;')
      ->line('    if (masked) {')
      ->line('        if (buf_len < header_len + 4) return 0;')
      ->line('        mask_key = (unsigned char *)buf + header_len;')
      ->line('        header_len += 4;')
      ->line('    }')
      ->blank
      ->line('    if (buf_len < header_len + payload_len) return 0;')
      ->blank
      ->line('    frame->payload = (unsigned char *)buf + header_len;')
      ->line('    frame->payload_len = payload_len;')
      ->line('    frame->consumed = header_len + payload_len;')
      ->blank
      ->line('    if (masked && payload_len > 0) {')
      ->line('        for (i = 0; i < payload_len; i++) {')
      ->line('            frame->payload[i] ^= mask_key[i & 3];')
      ->line('        }')
      ->line('    }')
      ->blank
      ->line('    return 1;')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->comment('Create new WebSocket client object')
      ->xs_function('xs_ws_client_new')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: Hypersonic::UA::WebSocket->new(ua, url)");')
      ->blank
      ->line('int slot = ws_client_alloc_slot();')
      ->line('if (slot < 0) croak("Too many WebSocket connections");')
      ->blank
      ->line('AV *self = newAV();')
      ->line('av_extend(self, 4);')
      ->line('av_store(self, 0, newSViv(slot));')
      ->line('av_store(self, 1, SvREFCNT_inc(ST(1)));')
      ->line('av_store(self, 2, SvREFCNT_inc(ST(2)));')
      ->line('av_store(self, 3, (SV *)newHV());')
      ->line('av_store(self, 4, &PL_sv_undef);')
      ->blank
      ->line('SV *rv = newRV_noinc((SV *)self);')
      ->line('sv_bless(rv, gv_stashpv("Hypersonic::UA::WebSocket", GV_ADD));')
      ->line('ST(0) = sv_2mortal(rv);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_connect {
    my ($class, $builder) = @_;

    $builder->comment('Connect WebSocket client')
      ->xs_function('xs_ws_client_connect')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->connect()");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('SV *url_sv = *av_fetch(self, 2, 0);')
      ->line('STRLEN url_len;')
      ->line('const char *url = SvPV(url_sv, url_len);')
      ->blank
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('int tls = 0;')
      ->line('const char *host_start;')
      ->line('if (strncmp(url, "wss://", 6) == 0) { tls = 1; host_start = url + 6; }')
      ->line('else if (strncmp(url, "ws://", 5) == 0) { host_start = url + 5; }')
      ->line('else croak("Invalid WebSocket URL scheme");')
      ->blank
      ->line('char host[256];')
      ->line('int port = tls ? 443 : 80;')
      ->line('char path[1024] = "/";')
      ->blank
      ->line('const char *port_start = strchr(host_start, \':\');')
      ->line('const char *path_start = strchr(host_start, \'/\');')
      ->line('if (!path_start) path_start = host_start + strlen(host_start);')
      ->blank
      ->line('if (port_start && port_start < path_start) {')
      ->line('    size_t host_len = port_start - host_start;')
      ->line('    strncpy(host, host_start, host_len);')
      ->line('    host[host_len] = \'\\0\';')
      ->line('    port = atoi(port_start + 1);')
      ->line('} else {')
      ->line('    size_t host_len = path_start - host_start;')
      ->line('    strncpy(host, host_start, host_len);')
      ->line('    host[host_len] = \'\\0\';')
      ->line('}')
      ->line('if (*path_start == \'/\') strncpy(path, path_start, sizeof(path) - 1);')
      ->blank
      ->line('struct addrinfo hints = {0}, *res;')
      ->line('hints.ai_family = AF_INET;')
      ->line('hints.ai_socktype = SOCK_STREAM;')
      ->line('char port_str[16];')
      ->line('snprintf(port_str, sizeof(port_str), "%d", port);')
      ->blank
      ->line('if (getaddrinfo(host, port_str, &hints, &res) != 0) croak("DNS lookup failed");')
      ->blank
      ->line('int fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);')
      ->line('if (fd < 0) { freeaddrinfo(res); croak("Socket creation failed"); }')
      ->line('if (connect(fd, res->ai_addr, res->ai_addrlen) < 0) { freeaddrinfo(res); close(fd); croak("Connect failed"); }')
      ->line('freeaddrinfo(res);')
      ->line('conn->fd = fd;')
      ->blank
      ->line('if (tls) {')
      ->line('    SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());')
      ->line('    if (!ctx) croak("SSL_CTX_new failed");')
      ->line('    SSL *ssl = SSL_new(ctx);')
      ->line('    SSL_set_fd(ssl, fd);')
      ->line('    SSL_set_tlsext_host_name(ssl, host);')
      ->line('    if (SSL_connect(ssl) != 1) { SSL_free(ssl); SSL_CTX_free(ctx); close(fd); croak("TLS handshake failed"); }')
      ->line('    conn->ssl = ssl;')
      ->line('    SSL_CTX_free(ctx);')
      ->line('}')
      ->blank
      ->line('unsigned char key_bytes[16];')
      ->line('RAND_bytes(key_bytes, 16);')
      ->line('char key_b64[32];')
      ->line('ws_base64_encode(key_bytes, 16, key_b64);')
      ->blank
      ->line('char request[4096];')
      ->line('int len = snprintf(request, sizeof(request),')
      ->line('    "GET %s HTTP/1.1\\r\\nHost: %s\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\nSec-WebSocket-Key: %s\\r\\nSec-WebSocket-Version: 13\\r\\n\\r\\n",')
      ->line('    path, host, key_b64);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, request, len) : send(fd, request, len, 0);')
      ->line('if (sent != len) { ws_client_free_slot(slot); croak("Failed to send handshake"); }')
      ->blank
      ->line('char response[4096];')
      ->line('ssize_t received = conn->ssl ? SSL_read(conn->ssl, response, sizeof(response) - 1) : recv(fd, response, sizeof(response) - 1, 0);')
      ->line('if (received <= 0) { ws_client_free_slot(slot); croak("Failed to receive handshake"); }')
      ->line('response[received] = \'\\0\';')
      ->blank
      ->line('if (strstr(response, "101") == NULL) { ws_client_free_slot(slot); croak("WebSocket handshake failed"); }')
      ->blank
      ->line('conn->recv_buffer_cap = 65536;')
      ->line('conn->recv_buffer = (char *)malloc(conn->recv_buffer_cap);')
      ->line('conn->recv_buffer_len = 0;')
      ->line('conn->state = WS_STATE_OPEN;')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_send {
    my ($class, $builder) = @_;

    $builder->comment('Send text frame')
      ->xs_function('xs_ws_client_send')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: $ws->send(data)");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state != WS_STATE_OPEN) croak("WebSocket not connected");')
      ->blank
      ->line('STRLEN data_len;')
      ->line('const unsigned char *data = (const unsigned char *)SvPV(ST(1), data_len);')
      ->blank
      ->line('size_t frame_size = ws_client_frame_size(data_len);')
      ->line('unsigned char *frame = (unsigned char *)malloc(frame_size);')
      ->line('size_t frame_len = ws_client_encode_frame(frame, data, data_len, WS_OP_TEXT, 1);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, frame, frame_len) : send(conn->fd, frame, frame_len, 0);')
      ->line('free(frame);')
      ->blank
      ->line('if (sent != (ssize_t)frame_len) croak("Failed to send frame");')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_send_binary {
    my ($class, $builder) = @_;

    $builder->comment('Send binary frame')
      ->xs_function('xs_ws_client_send_binary')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: $ws->send_binary(data)");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state != WS_STATE_OPEN) croak("WebSocket not connected");')
      ->blank
      ->line('STRLEN data_len;')
      ->line('const unsigned char *data = (const unsigned char *)SvPV(ST(1), data_len);')
      ->blank
      ->line('size_t frame_size = ws_client_frame_size(data_len);')
      ->line('unsigned char *frame = (unsigned char *)malloc(frame_size);')
      ->line('size_t frame_len = ws_client_encode_frame(frame, data, data_len, WS_OP_BINARY, 1);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, frame, frame_len) : send(conn->fd, frame, frame_len, 0);')
      ->line('free(frame);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(sent == (ssize_t)frame_len ? 1 : 0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_ping {
    my ($class, $builder) = @_;

    $builder->comment('Send ping frame')
      ->xs_function('xs_ws_client_ping')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $ws->ping([data])");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state != WS_STATE_OPEN) croak("WebSocket not connected");')
      ->blank
      ->line('STRLEN data_len = 0;')
      ->line('const unsigned char *data = (const unsigned char *)"";')
      ->line('if (items > 1 && SvOK(ST(1))) data = (const unsigned char *)SvPV(ST(1), data_len);')
      ->blank
      ->line('size_t frame_size = ws_client_frame_size(data_len);')
      ->line('unsigned char *frame = (unsigned char *)malloc(frame_size);')
      ->line('size_t frame_len = ws_client_encode_frame(frame, data, data_len, WS_OP_PING, 1);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, frame, frame_len) : send(conn->fd, frame, frame_len, 0);')
      ->line('free(frame);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(sent == (ssize_t)frame_len ? 1 : 0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_pong {
    my ($class, $builder) = @_;

    $builder->comment('Send pong frame')
      ->xs_function('xs_ws_client_pong')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $ws->pong([data])");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state != WS_STATE_OPEN) croak("WebSocket not connected");')
      ->blank
      ->line('STRLEN data_len = 0;')
      ->line('const unsigned char *data = (const unsigned char *)"";')
      ->line('if (items > 1 && SvOK(ST(1))) data = (const unsigned char *)SvPV(ST(1), data_len);')
      ->blank
      ->line('size_t frame_size = ws_client_frame_size(data_len);')
      ->line('unsigned char *frame = (unsigned char *)malloc(frame_size);')
      ->line('size_t frame_len = ws_client_encode_frame(frame, data, data_len, WS_OP_PONG, 1);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, frame, frame_len) : send(conn->fd, frame, frame_len, 0);')
      ->line('free(frame);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(sent == (ssize_t)frame_len ? 1 : 0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->comment('Send close frame')
      ->xs_function('xs_ws_client_close')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $ws->close([code], [reason])");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state >= WS_STATE_CLOSING) {')
      ->line('    ST(0) = sv_2mortal(newSViv(0));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('conn->state = WS_STATE_CLOSING;')
      ->line('int code = (items > 1) ? SvIV(ST(1)) : 1000;')
      ->line('conn->close_code = code;')
      ->blank
      ->line('unsigned char payload[128];')
      ->line('payload[0] = (code >> 8) & 0xFF;')
      ->line('payload[1] = code & 0xFF;')
      ->line('size_t payload_len = 2;')
      ->blank
      ->line('if (items > 2 && SvOK(ST(2))) {')
      ->line('    STRLEN reason_len;')
      ->line('    const char *reason = SvPV(ST(2), reason_len);')
      ->line('    if (reason_len > 123) reason_len = 123;')
      ->line('    memcpy(payload + 2, reason, reason_len);')
      ->line('    payload_len += reason_len;')
      ->line('}')
      ->blank
      ->line('size_t frame_size = ws_client_frame_size(payload_len);')
      ->line('unsigned char *frame = (unsigned char *)malloc(frame_size);')
      ->line('size_t frame_len = ws_client_encode_frame(frame, payload, payload_len, WS_OP_CLOSE, 1);')
      ->blank
      ->line('ssize_t sent = conn->ssl ? SSL_write(conn->ssl, frame, frame_len) : send(conn->fd, frame, frame_len, 0);')
      ->line('free(frame);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(sent > 0 ? 1 : 0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv_frame {
    my ($class, $builder) = @_;

    $builder->comment('Receive WebSocket frame')
      ->xs_function('xs_ws_client_recv_frame')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->recv_frame()");')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('WSClientConnection *conn = &ws_client_registry[slot];')
      ->blank
      ->line('if (conn->state == WS_STATE_CLOSED) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('if (conn->recv_buffer_len < conn->recv_buffer_cap) {')
      ->line('    ssize_t received = conn->ssl')
      ->line('        ? SSL_read(conn->ssl, conn->recv_buffer + conn->recv_buffer_len, conn->recv_buffer_cap - conn->recv_buffer_len)')
      ->line('        : recv(conn->fd, conn->recv_buffer + conn->recv_buffer_len, conn->recv_buffer_cap - conn->recv_buffer_len, MSG_DONTWAIT);')
      ->line('    if (received > 0) conn->recv_buffer_len += received;')
      ->line('    else if (received == 0) { conn->state = WS_STATE_CLOSED; ST(0) = &PL_sv_undef; XSRETURN(1); }')
      ->line('}')
      ->blank
      ->line('WSFrame frame;')
      ->line('if (!ws_client_decode_frame((unsigned char *)conn->recv_buffer, conn->recv_buffer_len, &frame)) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('memmove(conn->recv_buffer, conn->recv_buffer + frame.consumed, conn->recv_buffer_len - frame.consumed);')
      ->line('conn->recv_buffer_len -= frame.consumed;')
      ->blank
      ->line('HV *result = newHV();')
      ->line('hv_stores(result, "fin", newSViv(frame.fin));')
      ->line('hv_stores(result, "opcode", newSViv(frame.opcode));')
      ->line('hv_stores(result, "payload", newSVpvn((char *)frame.payload, frame.payload_len));')
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV *)result));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_state {
    my ($class, $builder) = @_;

    $builder->comment('Get connection state')
      ->xs_function('xs_ws_client_state')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->state()");')
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('ST(0) = sv_2mortal(newSViv(ws_client_registry[slot].state));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_open {
    my ($class, $builder) = @_;

    $builder->comment('Check if open')
      ->xs_function('xs_ws_client_is_open')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->is_open()");')
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('ST(0) = ws_client_registry[slot].state == WS_STATE_OPEN ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_fd {
    my ($class, $builder) = @_;

    $builder->comment('Get file descriptor')
      ->xs_function('xs_ws_client_fd')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->fd()");')
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('ST(0) = sv_2mortal(newSViv(ws_client_registry[slot].fd));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_cleanup {
    my ($class, $builder) = @_;

    $builder->comment('Cleanup connection')
      ->xs_function('xs_ws_client_cleanup')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $ws->cleanup()");')
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('int slot = SvIV(*av_fetch(self, 0, 0));')
      ->line('ws_client_free_slot(slot);')
      ->line('ST(0) = &PL_sv_yes;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

# Perl callback methods
sub on {
    my ($self, $event, $callback) = @_;
    my $callbacks = $self->[SLOT_CALLBACKS];
    $callbacks->{$event} = $callback;
    return $self;
}

sub _get_callbacks {
    my ($self) = @_;
    return $self->[SLOT_CALLBACKS];
}

1;
