#include "stream_internal.h"

void
les_process_netstring(pTHX_ les_xsstate_t *st)
{
    les_descriptor_t *descriptor = st->descriptor;

    while (!st->closed && !LES_INPUT_PAUSED(st) && st->input_len > 0) {
        const char *data = les_input_data(st);
        size_t i = 0;
        UV payload_len = 0;
        UV payload_offset_uv;
        UV total_uv;
        size_t payload_offset;
        size_t total;
        SV *message;

        if ((unsigned char)data[0] < '0' || (unsigned char)data[0] > '9') {
            les_call_framing_error(aTHX_ st, "invalid netstring length");
            return;
        }

        while (i < st->input_len && data[i] != ':') {
            unsigned char c = (unsigned char)data[i];
            if (c < '0' || c > '9') {
                les_call_framing_error(aTHX_ st, "invalid netstring length");
                return;
            }
            if (i >= 20) {
                les_call_framing_error(aTHX_ st, "netstring length field too long");
                return;
            }
            if (payload_len > ((UV)-1 - (UV)(c - '0')) / 10) {
                les_call_framing_error(aTHX_ st, "netstring length overflow");
                return;
            }
            payload_len = payload_len * 10 + (UV)(c - '0');
            i++;
        }

        if (i == st->input_len) {
            if (i > 20)
                les_call_framing_error(aTHX_ st, "netstring length field too long");
            return;
        }
        if (i == 0) {
            les_call_framing_error(aTHX_ st, "invalid netstring length");
            return;
        }
        if (i > 1 && data[0] == '0') {
            les_call_framing_error(aTHX_ st, "invalid netstring leading zero");
            return;
        }
        if (st->descriptor->has_max_frame
            && payload_len > st->descriptor->max_frame) {
            char msg[128];
            snprintf(msg, sizeof(msg), "frame exceeds max_frame=%llu",
                (unsigned long long)st->descriptor->max_frame);
            les_call_framing_error(aTHX_ st, msg);
            return;
        }

        payload_offset_uv = (UV)i + 1;
        if (payload_offset_uv > (UV)-1 - payload_len - 1) {
            les_call_framing_error(aTHX_ st, "netstring frame length overflow");
            return;
        }
        total_uv = payload_offset_uv + payload_len + 1;
        if (st->max_buffer && total_uv > st->max_buffer) {
            char msg[160];
            snprintf(msg, sizeof(msg),
                "framed message requires %llu bytes, exceeds max_buffer=%llu",
                (unsigned long long)total_uv,
                (unsigned long long)st->max_buffer);
            les_call_framing_error(aTHX_ st, msg);
            return;
        }
        if (total_uv > (UV)(size_t)-1) {
            les_call_framing_error(aTHX_ st, "netstring frame length exceeds native size_t");
            return;
        }

        total = (size_t)total_uv;
        if (st->input_len < total)
            return;
        if (data[total - 1] != ',') {
            les_call_framing_error(aTHX_ st, "invalid netstring terminator");
            return;
        }

        payload_offset = (size_t)payload_offset_uv;
        message = sv_2mortal(newSVpvn(data + payload_offset, (STRLEN)payload_len));
        les_input_consume(st, total);
        les_emit_message(aTHX_ st, message);
        if (st->descriptor != descriptor)
            return;
    }
}
