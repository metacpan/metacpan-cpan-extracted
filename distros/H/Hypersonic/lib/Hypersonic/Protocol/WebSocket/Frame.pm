package Hypersonic::Protocol::WebSocket::Frame;
use strict;
use warnings;
use Hypersonic::JIT::Util;

# Hypersonic::Protocol::WebSocket::Frame - WebSocket frame encoding/decoding
#
# Implements RFC 6455 Section 5 binary frame protocol:
# - Frame encoding (server->client, unmasked)
# - Frame decoding (client->server, masked)
# - Control frame handling (ping/pong/close)
# - Message fragmentation
#
# All C code generated at compile time for JIT compilation.

our $VERSION = '0.12';

# WebSocket opcodes (RFC 6455 Section 5.2)
use constant {
    OP_CONTINUATION => 0x0,
    OP_TEXT         => 0x1,
    OP_BINARY       => 0x2,
    OP_CLOSE        => 0x8,
    OP_PING         => 0x9,
    OP_PONG         => 0xA,
};

# Close codes (RFC 6455 Section 7.4.1)
use constant {
    CLOSE_NORMAL           => 1000,
    CLOSE_GOING_AWAY       => 1001,
    CLOSE_PROTOCOL_ERROR   => 1002,
    CLOSE_UNSUPPORTED_DATA => 1003,
    CLOSE_NO_STATUS        => 1005,
    CLOSE_ABNORMAL         => 1006,
    CLOSE_INVALID_PAYLOAD  => 1007,
    CLOSE_POLICY_VIOLATION => 1008,
    CLOSE_MESSAGE_TOO_BIG  => 1009,
    CLOSE_MANDATORY_EXT    => 1010,
    CLOSE_INTERNAL_ERROR   => 1011,
};

# Export constants
sub opcodes {
    return {
        continuation => OP_CONTINUATION,
        text         => OP_TEXT,
        binary       => OP_BINARY,
        close        => OP_CLOSE,
        ping         => OP_PING,
        pong         => OP_PONG,
    };
}

sub close_codes {
    return {
        normal           => CLOSE_NORMAL,
        going_away       => CLOSE_GOING_AWAY,
        protocol_error   => CLOSE_PROTOCOL_ERROR,
        unsupported_data => CLOSE_UNSUPPORTED_DATA,
        invalid_payload  => CLOSE_INVALID_PAYLOAD,
        policy_violation => CLOSE_POLICY_VIOLATION,
        message_too_big  => CLOSE_MESSAGE_TOO_BIG,
        internal_error   => CLOSE_INTERNAL_ERROR,
    };
}

# Generate C constants and structures
sub gen_frame_constants {
    my ($class, $builder) = @_;
    
    $builder->comment('WebSocket opcodes (RFC 6455 Section 5.2)')
                ->line('#define WS_OP_CONTINUATION 0x0')
                ->line('#define WS_OP_TEXT         0x1')
                ->line('#define WS_OP_BINARY       0x2')
                ->line('#define WS_OP_CLOSE        0x8')
                ->line('#define WS_OP_PING         0x9')
                ->line('#define WS_OP_PONG         0xA')
                ->blank
                ->comment('Frame flags')
                ->line('#define WS_FIN             0x80')
                ->line('#define WS_MASK            0x80')
                ->blank
                ->comment('Payload length markers')
                ->line('#define WS_LEN_16BIT       126')
                ->line('#define WS_LEN_64BIT       127')
                ->line('#define WS_MAX_SMALL_PAYLOAD  125')
                ->line('#define WS_MAX_MEDIUM_PAYLOAD 65535')
                ->blank
                ->comment('Close codes (RFC 6455 Section 7.4.1)')
                ->line('#define WS_CLOSE_NORMAL           1000')
                ->line('#define WS_CLOSE_GOING_AWAY       1001')
                ->line('#define WS_CLOSE_PROTOCOL_ERROR   1002')
                ->line('#define WS_CLOSE_UNSUPPORTED_DATA 1003')
                ->line('#define WS_CLOSE_INVALID_PAYLOAD  1007')
                ->line('#define WS_CLOSE_POLICY_VIOLATION 1008')
                ->line('#define WS_CLOSE_MESSAGE_TOO_BIG  1009')
                ->line('#define WS_CLOSE_INTERNAL_ERROR   1011')
                ->blank
                ->comment('Parsed frame structure')
                ->line('typedef struct {')
                ->line('    uint8_t  fin;')
                ->line('    uint8_t  rsv;')
                ->line('    uint8_t  opcode;')
                ->line('    uint8_t  masked;')
                ->line('    uint64_t payload_length;')
                ->line('    uint8_t  mask_key[4];')
                ->line('    uint8_t* payload;')
                ->line('    size_t   header_size;')
                ->line('    size_t   total_size;')
            ->line('} WSFrame;')
            ->blank;
    
    return $builder;
}

# Generate frame decoder
sub gen_frame_decoder {
    my ($class, $builder) = @_;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    $builder->comment('Decode WebSocket frame from buffer')
            ->comment('Returns: bytes consumed (>0), 0 if need more data, -1 on error')
            ->line('static int ws_decode_frame(const uint8_t* buf, size_t len, WSFrame* frame) {');
        
        $builder->if('len < 2')
                    ->line('return 0;')
                ->endif
                ->blank
                ->comment('    First byte: FIN + RSV + opcode')
                ->line('    frame->fin = (buf[0] & 0x80) != 0;')
                ->line('    frame->rsv = (buf[0] >> 4) & 0x07;')
                ->line('    frame->opcode = buf[0] & 0x0F;')
                ->blank
                ->comment('    RSV bits must be 0 unless extension negotiated');
        
        $builder->if('frame->rsv != 0')
                    ->line('return -1;')
                ->endif
                ->blank
                ->comment('    Second byte: MASK + payload length')
                ->line('    frame->masked = (buf[1] & 0x80) != 0;')
                ->line('    uint8_t len7 = buf[1] & 0x7F;')
                ->blank
                ->line('    size_t header_size = 2;')
                ->line('    uint64_t payload_len;')
                ->blank;
        
        $builder->if('len7 <= 125')
                    ->line('payload_len = len7;')
                ->elsif('len7 == 126')
                    ->comment('16-bit extended length');
        
        $builder->if('len < 4')
                        ->line('return 0;')
                    ->endif
                    ->line('payload_len = ((uint64_t)buf[2] << 8) | buf[3];')
                    ->line('header_size = 4;')
                ->else
                    ->comment('64-bit extended length');
        
        $builder->if('len < 10')
                        ->line('return 0;')
                    ->endif
                    ->line('payload_len = 0;')
                    ->line('{ int i;')
                    ->for('i = 0', 'i < 8', 'i++')
                        ->line('payload_len = (payload_len << 8) | buf[2 + i];')
                    ->endfor
                    ->line('}')
                    ->line('header_size = 10;')
                    ->blank
                    ->comment('MSB must be 0 per RFC');
        
        $builder->if('payload_len & ((uint64_t)1 << 63)')
                        ->line('return -1;')
                    ->endif
                ->endif
                ->blank
                ->comment('    Masking key (client->server frames must be masked)');
        
        $builder->if('frame->masked')
                    ->if('len < header_size + 4')
                        ->line('return 0;')
                    ->endif
                    ->line('memcpy(frame->mask_key, buf + header_size, 4);')
                    ->line('header_size += 4;')
                ->endif
                ->blank
                ->comment('    Check we have full payload');
        
        $builder->if('len < header_size + payload_len')
                    ->line('return 0;')
                ->endif
                ->blank
                ->line('    frame->payload_length = payload_len;')
                ->line('    frame->header_size = header_size;')
                ->line('    frame->total_size = header_size + payload_len;')
                ->line('    frame->payload = (uint8_t*)(buf + header_size);')
                ->blank
                ->comment('    Unmask payload in place (XOR with rotating key)');
        
        $builder->if('frame->masked && payload_len > 0')
                    ->line('{ size_t i;')
                    ->for('i = 0', 'i < payload_len', 'i++')
                        ->line('frame->payload[i] ^= frame->mask_key[i & 3];')
                    ->endfor
                    ->line('}')
                ->endif
                ->blank
                ->line('    return (int)frame->total_size;')
                ->line('}')
                ->blank;
        
        # Helper functions
        $builder->comment('Check if opcode is a control frame')
                ->line("static $inline int ws_is_control(uint8_t opcode) {")
                ->line('    return (opcode & 0x08) != 0;')
                ->line('}')
                ->blank
                ->comment('Check if opcode is a data frame')
                ->line("static $inline int ws_is_data(uint8_t opcode) {")
                ->line('    return opcode == WS_OP_TEXT || opcode == WS_OP_BINARY || opcode == WS_OP_CONTINUATION;')
                ->line('}')
                ->blank;
    
    return $builder;
}

# Generate frame encoder
sub gen_frame_encoder {
    my ($class, $builder) = @_;
    
    # Main encoder function
    $builder->comment('Encode WebSocket frame (server->client, no masking required)')
            ->comment('Returns: total frame size, 0 on error')
            ->line('static size_t ws_encode_frame(uint8_t* buf, size_t buf_size,')
            ->line('                               uint8_t opcode, int fin,')
            ->line('                               const uint8_t* payload, size_t payload_len) {')
            ->line('    size_t header_size;')
            ->line('    size_t total_size;')
            ->blank
            ->comment('    Calculate header size');
    
    $builder->if('payload_len <= 125')
                ->line('header_size = 2;')
            ->elsif('payload_len <= 65535')
                ->line('header_size = 4;')
            ->else
                ->line('header_size = 10;')
            ->endif
            ->blank
            ->line('    total_size = header_size + payload_len;');
    
    $builder->if('total_size > buf_size')
                ->line('return 0;')
            ->endif
            ->blank
            ->comment('    First byte: FIN + opcode')
            ->line('    buf[0] = (fin ? WS_FIN : 0) | (opcode & 0x0F);')
            ->blank
            ->comment('    Second byte: payload length (no mask bit for server)');
    
    $builder->if('payload_len <= 125')
                ->line('buf[1] = (uint8_t)payload_len;')
            ->elsif('payload_len <= 65535')
                ->line('buf[1] = 126;')
                ->line('buf[2] = (payload_len >> 8) & 0xFF;')
                ->line('buf[3] = payload_len & 0xFF;')
            ->else
                ->line('buf[1] = 127;')
                ->line('{ int i;')
                ->for('i = 0', 'i < 8', 'i++')
                    ->line('buf[2 + i] = (payload_len >> (56 - 8*i)) & 0xFF;')
                ->endfor
                ->line('}')
            ->endif
            ->blank
            ->comment('    Copy payload');
    
    $builder->if('payload_len > 0 && payload')
                ->line('memcpy(buf + header_size, payload, payload_len);')
            ->endif
            ->blank
            ->line('    return total_size;')
            ->line('}')
            ->blank;
    
    # Encode text
    $builder->comment('Encode text message frame')
            ->line('static size_t ws_encode_text(uint8_t* buf, size_t buf_size,')
            ->line('                              const char* text, size_t text_len) {')
            ->line('    return ws_encode_frame(buf, buf_size, WS_OP_TEXT, 1,')
            ->line('                           (const uint8_t*)text, text_len);')
            ->line('}')
            ->blank;
    
    # Encode binary
    $builder->comment('Encode binary message frame')
            ->line('static size_t ws_encode_binary(uint8_t* buf, size_t buf_size,')
            ->line('                                const uint8_t* data, size_t data_len) {')
            ->line('    return ws_encode_frame(buf, buf_size, WS_OP_BINARY, 1, data, data_len);')
            ->line('}')
            ->blank;
    
    # Encode close
    $builder->comment('Encode close frame with code and optional reason')
            ->line('static size_t ws_encode_close(uint8_t* buf, size_t buf_size,')
            ->line('                               uint16_t code, const char* reason) {')
            ->line('    uint8_t payload[128];')
            ->line('    size_t payload_len = 0;')
            ->blank;
    
    $builder->if('code')
                ->line('payload[0] = (code >> 8) & 0xFF;')
                ->line('payload[1] = code & 0xFF;')
                ->line('payload_len = 2;')
                ->blank
                ->if('reason && reason[0]')
                    ->line('size_t reason_len = strlen(reason);')
                    ->if('reason_len > 123')
                        ->line('reason_len = 123;')
                    ->endif
                    ->line('memcpy(payload + 2, reason, reason_len);')
                    ->line('payload_len += reason_len;')
                ->endif
            ->endif
            ->blank
            ->line('    return ws_encode_frame(buf, buf_size, WS_OP_CLOSE, 1,')
            ->line('                           payload, payload_len);')
            ->line('}')
            ->blank;
    
    # Encode ping
    $builder->comment('Encode ping frame')
            ->line('static size_t ws_encode_ping(uint8_t* buf, size_t buf_size,')
            ->line('                              const uint8_t* data, size_t data_len) {');
    
    $builder->if('data_len > 125')
                ->line('data_len = 125;')
            ->endif
            ->line('    return ws_encode_frame(buf, buf_size, WS_OP_PING, 1, data, data_len);')
            ->line('}')
            ->blank;
    
    # Encode pong
    $builder->comment('Encode pong frame (must echo ping payload)')
            ->line('static size_t ws_encode_pong(uint8_t* buf, size_t buf_size,')
            ->line('                              const uint8_t* data, size_t data_len) {');
    
    $builder->if('data_len > 125')
                ->line('data_len = 125;')
            ->endif
            ->line('    return ws_encode_frame(buf, buf_size, WS_OP_PONG, 1, data, data_len);')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate control frame handler
sub gen_control_handler {
    my ($class, $builder) = @_;
    
    $builder->comment('Handle control frames (ping/pong/close)')
            ->comment('Returns: 1 = handled, 0 = not control, -1 = close connection')
            ->line('static int ws_handle_control(int fd, WSFrame* frame,')
            ->line('                              uint16_t* close_code, char* close_reason) {')
            ->line('    uint8_t buf[256];')
            ->blank;
    
    # Handle PING
    $builder->if('frame->opcode == WS_OP_PING')
                ->comment('Must respond with pong containing same payload')
                ->line('size_t len = ws_encode_pong(buf, sizeof(buf),')
                ->line('                            frame->payload,')
                ->line('                            frame->payload_length);')
                ->if('len > 0')
                    ->line('send(fd, buf, len, 0);')
                ->endif
                ->line('return 1;')
            ->endif
            ->blank;
    
    # Handle PONG
    $builder->if('frame->opcode == WS_OP_PONG')
                ->comment('Acknowledge only, no response needed')
                ->line('return 1;')
            ->endif
            ->blank;
    
    # Handle CLOSE
    $builder->if('frame->opcode == WS_OP_CLOSE')
                ->comment('Parse close code and reason')
                ->line('uint16_t code = WS_CLOSE_NORMAL;')
                ->blank
                ->if('frame->payload_length >= 2')
                    ->line('code = ((uint16_t)frame->payload[0] << 8) | frame->payload[1];')
                    ->if('frame->payload_length > 2')
                        ->comment('Reason is UTF-8, null-terminate')
                        ->line('size_t reason_len = frame->payload_length - 2;')
                        ->if('reason_len > 123')
                            ->line('reason_len = 123;')
                        ->endif
                        ->if('close_reason')
                            ->line('memcpy(close_reason, frame->payload + 2, reason_len);')
                            ->line('close_reason[reason_len] = \'\\0\';')
                        ->endif
                    ->endif
                ->endif
                ->blank
                ->if('close_code')
                    ->line('*close_code = code;')
                ->endif
                ->blank
                ->comment('Echo close frame back')
                ->line('size_t len = ws_encode_close(buf, sizeof(buf), code, NULL);')
                ->if('len > 0')
                    ->line('send(fd, buf, len, 0);')
                ->endif
                ->line('return -1;')
            ->endif
            ->blank
            ->comment('Not a control frame')
            ->line('    return 0;')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate fragmentation support
sub gen_fragment_handler {
    my ($class, $builder, $max_connections) = @_;
    $max_connections //= 10000;
    
    $builder->comment('Per-connection fragment accumulator')
            ->line('typedef struct {')
            ->line('    uint8_t* buffer;')
            ->line('    size_t   length;')
            ->line('    size_t   capacity;')
            ->line('    uint8_t  opcode;')
            ->line('    int      in_progress;')
            ->line('} WSFragmentBuffer;')
            ->blank
            ->line("static WSFragmentBuffer ws_fragments[$max_connections];")
            ->blank;
    
    # fragment_init
    $builder->comment('Initialize fragment buffer for new message')
            ->line('static int ws_fragment_init(int fd, uint8_t opcode, size_t initial_cap) {');
    
    $builder->if("fd < 0 || fd >= $max_connections")
                ->line('return -1;')
            ->endif
            ->blank
            ->line('    WSFragmentBuffer* frag = &ws_fragments[fd];')
            ->blank;
    
    $builder->if('!frag->buffer')
                ->line('frag->capacity = initial_cap > 0 ? initial_cap : 16384;')
                ->line('frag->buffer = (uint8_t*)malloc(frag->capacity);')
                ->if('!frag->buffer')
                    ->line('return -1;')
                ->endif
            ->endif
            ->blank
            ->line('    frag->length = 0;')
            ->line('    frag->opcode = opcode;')
            ->line('    frag->in_progress = 1;')
            ->blank
            ->line('    return 0;')
            ->line('}')
            ->blank;
    
    # fragment_append
    $builder->comment('Append data to fragment buffer')
            ->line('static int ws_fragment_append(int fd, const uint8_t* data, size_t len) {');
    
    $builder->if("fd < 0 || fd >= $max_connections")
                ->line('return -1;')
            ->endif
            ->blank
            ->line('    WSFragmentBuffer* frag = &ws_fragments[fd];')
            ->blank
            ->comment('    Grow buffer if needed (double capacity)');
    
    $builder->while('frag->length + len > frag->capacity')
                ->line('size_t new_cap = frag->capacity * 2;')
                ->line('uint8_t* new_buf = (uint8_t*)realloc(frag->buffer, new_cap);')
                ->if('!new_buf')
                    ->line('return -1;')
                ->endif
                ->line('frag->buffer = new_buf;')
                ->line('frag->capacity = new_cap;')
            ->endloop
            ->blank
            ->line('    memcpy(frag->buffer + frag->length, data, len);')
            ->line('    frag->length += len;')
            ->blank
            ->line('    return 0;')
            ->line('}')
            ->blank;
    
    # fragment_get
    $builder->comment('Get completed fragment buffer')
            ->line('static WSFragmentBuffer* ws_fragment_get(int fd) {');
    
    $builder->if("fd < 0 || fd >= $max_connections")
                ->line('return NULL;')
            ->endif
            ->line('    return &ws_fragments[fd];')
            ->line('}')
            ->blank;
    
    # fragment_reset
    $builder->comment('Reset fragment buffer after message complete')
            ->line('static void ws_fragment_reset(int fd) {');
    
    $builder->if("fd < 0 || fd >= $max_connections")
                ->line('return;')
            ->endif
            ->line('    ws_fragments[fd].length = 0;')
            ->line('    ws_fragments[fd].in_progress = 0;')
            ->line('}')
            ->blank;
    
    # fragment_free
    $builder->comment('Free fragment buffer on connection close')
            ->line('static void ws_fragment_free(int fd) {');
    
    $builder->if("fd < 0 || fd >= $max_connections")
                ->line('return;')
            ->endif
            ->blank;
    
    $builder->if('ws_fragments[fd].buffer')
                ->line('free(ws_fragments[fd].buffer);')
                ->line('ws_fragments[fd].buffer = NULL;')
            ->endif
            ->line('    ws_fragments[fd].length = 0;')
            ->line('    ws_fragments[fd].capacity = 0;')
            ->line('    ws_fragments[fd].in_progress = 0;')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate main frame processor
sub gen_frame_processor {
    my ($class, $builder) = @_;
    
    # Message callback typedef
    $builder->comment('Message callback type')
            ->line('typedef void (*WSMessageCallback)(int fd, uint8_t opcode,')
            ->line('                                   uint8_t* data, size_t len,')
            ->line('                                   void* userdata);')
            ->blank;
    
    # Main processor function
    $builder->comment('Process incoming WebSocket data')
            ->comment('Returns: bytes consumed, 0 = need more, -1 = error, -2 = close')
            ->line('static int ws_process_data(int fd, uint8_t* buf, size_t len,')
            ->line('                            WSMessageCallback on_message, void* userdata) {')
            ->line('    size_t pos = 0;')
            ->line('    uint16_t close_code = 0;')
            ->line('    char close_reason[128] = {0};')
            ->blank;
    
    $builder->while('pos < len')
                ->line('WSFrame frame;')
                ->line('int consumed = ws_decode_frame(buf + pos, len - pos, &frame);')
                ->blank
                ->if('consumed == 0')
                    ->comment('Need more data')
                    ->line('break;')
                ->endif
                ->if('consumed < 0')
                    ->line('return -1;')
                ->endif
                ->blank
                ->comment('Handle control frames (can interleave with data)')
                ->if('ws_is_control(frame.opcode)')
                    ->line('int ctrl = ws_handle_control(fd, &frame, &close_code, close_reason);')
                    ->if('ctrl == -1')
                        ->line('return -2;')
                    ->endif
                    ->line('pos += consumed;')
                    ->line('continue;')
                ->endif
                ->blank
                ->comment('Data frame processing')
                ->if('frame.opcode != WS_OP_CONTINUATION')
                    ->comment('Start of new message')
                    ->if('!frame.fin')
                        ->comment('First fragment of multi-frame message')
                        ->if('ws_fragment_init(fd, frame.opcode, frame.payload_length * 2) < 0')
                            ->line('return -1;')
                        ->endif
                        ->line('ws_fragment_append(fd, frame.payload, frame.payload_length);')
                    ->else
                        ->comment('Complete message in single frame')
                        ->if('on_message')
                            ->line('on_message(fd, frame.opcode, frame.payload,')
                            ->line('           frame.payload_length, userdata);')
                        ->endif
                    ->endif
                ->else
                    ->comment('Continuation frame')
                    ->line('WSFragmentBuffer* frag = ws_fragment_get(fd);')
                    ->if('!frag || !frag->in_progress')
                        ->line('return -1;')
                    ->endif
                    ->blank
                    ->line('ws_fragment_append(fd, frame.payload, frame.payload_length);')
                    ->blank
                    ->if('frame.fin')
                        ->comment('Message complete')
                        ->if('on_message')
                            ->line('on_message(fd, frag->opcode, frag->buffer,')
                            ->line('           frag->length, userdata);')
                        ->endif
                        ->line('ws_fragment_reset(fd);')
                    ->endif
                ->endif
                ->blank
                ->line('pos += consumed;')
            ->endloop
            ->blank
            ->line('    return (int)pos;')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate all frame handling C code
sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    
    $class->gen_frame_constants($builder);
    $class->gen_frame_decoder($builder);
    $class->gen_frame_encoder($builder);
    $class->gen_control_handler($builder);
    $class->gen_fragment_handler($builder, $opts->{max_connections});
    $class->gen_frame_processor($builder);
    
    return $builder;
}

#
# Perl-side helpers for testing and fallback
#

# Encode a frame in pure Perl
sub encode_frame {
    my ($class, %args) = @_;
    
    my $opcode = $args{opcode} // OP_TEXT;
    my $fin    = $args{fin} // 1;
    my $data   = $args{data} // '';
    my $mask   = $args{mask};  # Optional 4-byte mask key
    
    my $payload = ref($data) ? $data : [unpack('C*', $data)];
    my $len = scalar(@$payload);
    
    my @frame;
    
    # First byte: FIN + opcode
    push @frame, ($fin ? 0x80 : 0x00) | ($opcode & 0x0F);
    
    # Second byte: MASK + length
    my $mask_bit = $mask ? 0x80 : 0x00;
    
    if ($len <= 125) {
        push @frame, $mask_bit | $len;
    } elsif ($len <= 65535) {
        push @frame, $mask_bit | 126;
        push @frame, ($len >> 8) & 0xFF;
        push @frame, $len & 0xFF;
    } else {
        push @frame, $mask_bit | 127;
        for my $i (0..7) {
            push @frame, ($len >> (56 - 8*$i)) & 0xFF;
        }
    }
    
    # Mask key
    if ($mask) {
        push @frame, @$mask;
        # XOR payload with mask
        for my $i (0..$#$payload) {
            $payload->[$i] ^= $mask->[$i % 4];
        }
    }
    
    # Payload
    push @frame, @$payload;
    
    return pack('C*', @frame);
}

# Decode a frame in pure Perl
sub decode_frame {
    my ($class, $data) = @_;
    
    my @bytes = unpack('C*', $data);
    return undef if @bytes < 2;
    
    my %frame;
    
    # First byte
    $frame{fin}    = ($bytes[0] & 0x80) ? 1 : 0;
    $frame{rsv}    = ($bytes[0] >> 4) & 0x07;
    $frame{opcode} = $bytes[0] & 0x0F;
    
    # Second byte
    $frame{masked} = ($bytes[1] & 0x80) ? 1 : 0;
    my $len = $bytes[1] & 0x7F;
    
    my $pos = 2;
    
    if ($len == 126) {
        return undef if @bytes < 4;
        $len = ($bytes[2] << 8) | $bytes[3];
        $pos = 4;
    } elsif ($len == 127) {
        return undef if @bytes < 10;
        $len = 0;
        for my $i (0..7) {
            $len = ($len << 8) | $bytes[2 + $i];
        }
        $pos = 10;
    }
    
    $frame{payload_length} = $len;
    
    # Mask key
    if ($frame{masked}) {
        return undef if @bytes < $pos + 4;
        $frame{mask_key} = [@bytes[$pos..$pos+3]];
        $pos += 4;
    }
    
    # Payload
    return undef if @bytes < $pos + $len;
    
    my @payload = @bytes[$pos..$pos+$len-1];
    
    # Unmask
    if ($frame{masked}) {
        for my $i (0..$#payload) {
            $payload[$i] ^= $frame{mask_key}[$i % 4];
        }
    }
    
    $frame{payload} = pack('C*', @payload);
    $frame{header_size} = $pos;
    $frame{total_size} = $pos + $len;
    
    return \%frame;
}

# Encode close frame with code
sub encode_close {
    my ($class, $code, $reason) = @_;
    $code //= CLOSE_NORMAL;
    $reason //= '';
    
    my @payload;
    push @payload, ($code >> 8) & 0xFF;
    push @payload, $code & 0xFF;
    push @payload, unpack('C*', substr($reason, 0, 123));
    
    return $class->encode_frame(
        opcode => OP_CLOSE,
        fin    => 1,
        data   => \@payload,
    );
}

# Parse close frame payload
sub parse_close {
    my ($class, $payload) = @_;
    
    my @bytes = unpack('C*', $payload);
    
    my $code = CLOSE_NO_STATUS;
    my $reason = '';
    
    if (@bytes >= 2) {
        $code = ($bytes[0] << 8) | $bytes[1];
        if (@bytes > 2) {
            $reason = pack('C*', @bytes[2..$#bytes]);
        }
    }
    
    return ($code, $reason);
}

1;

__END__

=head1 NAME

Hypersonic::Protocol::WebSocket::Frame - WebSocket frame encoding/decoding

=head1 SYNOPSIS

    use Hypersonic::Protocol::WebSocket::Frame;
    
    # Generate C code for JIT
    my $code = Hypersonic::Protocol::WebSocket::Frame->generate_c_code($builder);
    
    # Perl-side frame creation (for testing)
    my $frame = Hypersonic::Protocol::WebSocket::Frame->encode_frame(
        opcode => 0x1,  # text
        fin    => 1,
        data   => 'Hello',
        mask   => [0x12, 0x34, 0x56, 0x78],  # client must mask
    );

=head1 DESCRIPTION

Implements RFC 6455 Section 5 binary frame protocol for WebSocket.
All C code is generated at compile time for JIT compilation.

=head1 FRAME FORMAT

    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-------+-+-------------+-------------------------------+
   |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
   |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
   |N|V|V|V|       |S|             |                               |
   | |1|2|3|       |K|             |                               |
   +-+-+-+-+-------+-+-------------+-------------------------------+

=head1 OPCODES

=over 4

=item 0x0 - Continuation

=item 0x1 - Text

=item 0x2 - Binary

=item 0x8 - Close

=item 0x9 - Ping

=item 0xA - Pong

=back

=cut
