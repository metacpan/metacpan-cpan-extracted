#include "stream_internal.h"

static UV
les_decode_prefix(const unsigned char *p, int bytes, int little)
{
    UV value = 0;
    int i;

    if (little) {
        for (i = bytes - 1; i >= 0; i--)
            value = (value << 8) | (UV)p[i];
    } else {
        for (i = 0; i < bytes; i++)
            value = (value << 8) | (UV)p[i];
    }
    return value;
}

int
les_frame_fits_buffer(pTHX_ les_xsstate_t *st, UV prefix_bytes, UV payload_len)
{
    if (st->max_buffer && payload_len > st->max_buffer) {
        char msg[160];
        snprintf(msg, sizeof(msg),
            "declared frame length=%llu exceeds max_buffer=%llu",
            (unsigned long long)payload_len,
            (unsigned long long)st->max_buffer);
        les_call_framing_error(aTHX_ st, msg);
        return 0;
    }
    if (prefix_bytes > (UV)-1 - payload_len) {
        les_call_framing_error(aTHX_ st, "frame length overflow");
        return 0;
    }
    if (st->max_buffer && prefix_bytes + payload_len > st->max_buffer) {
        char msg[160];
        snprintf(msg, sizeof(msg),
            "framed message requires %llu bytes, exceeds max_buffer=%llu",
            (unsigned long long)(prefix_bytes + payload_len),
            (unsigned long long)st->max_buffer);
        les_call_framing_error(aTHX_ st, msg);
        return 0;
    }
    return 1;
}

void
les_process_length(pTHX_ les_xsstate_t *st)
{
    les_descriptor_t *descriptor = st->descriptor;
    const size_t prefix = (size_t)st->descriptor->prefix_bytes;

    while (!st->closed && !LES_INPUT_PAUSED(st)) {
        const char *data;
        UV payload_len;
        UV total_uv;
        size_t total;
        size_t offset;
        size_t msglen;
        SV *message;

        if (st->input_len < prefix)
            return;

        data = les_input_data(st);
        payload_len = les_decode_prefix((const unsigned char *)data,
            st->descriptor->prefix_bytes, st->descriptor->prefix_little);

        if (st->descriptor->has_max_frame
            && payload_len > st->descriptor->max_frame) {
            char msg[128];
            snprintf(msg, sizeof(msg), "frame exceeds max_frame=%llu",
                (unsigned long long)st->descriptor->max_frame);
            les_call_framing_error(aTHX_ st, msg);
            return;
        }
        if (!les_frame_fits_buffer(aTHX_ st, (UV)prefix, payload_len))
            return;

        total_uv = (UV)prefix + payload_len;
        if (total_uv > (UV)(size_t)-1) {
            les_call_framing_error(aTHX_ st, "frame length exceeds native size_t");
            return;
        }
        total = (size_t)total_uv;
        if (st->input_len < total)
            return;

        offset = st->descriptor->include_prefix ? 0 : prefix;
        msglen = st->descriptor->include_prefix ? total : (size_t)payload_len;
        message = sv_2mortal(newSVpvn(data + offset, (STRLEN)msglen));
        les_input_consume(st, total);
        les_emit_message(aTHX_ st, message);
        if (st->descriptor != descriptor)
            return;
    }
}
