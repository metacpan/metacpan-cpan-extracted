#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#include "util.h"

void dump_value(pTHX_ SV* val, Buffer* buf)
{
    if (!val) {
      return;
    }

    if (SvIOK(val)) {
        char str[50];
        int len = sprintf(str, "%ld", (long) SvIV(val));
        buffer_append(buf, str, len);
    } else if (SvNOK(val)) {
        char str[50];
        int len = sprintf(str, "%lf", (double) SvNV(val));
        buffer_append(buf, str, len);
    } else if (SvPOK(val)) {
        STRLEN len;
        char* str = SvPV(val, len);
        buffer_append(buf, "\"", 1);
        buffer_append(buf, str, len);
        buffer_append(buf, "\"", 1);
    } else if (SvROK(val)) {
        SV* rv = SvRV(val);
        if (SvTYPE(rv) == SVt_PVAV) {
            dump_array(aTHX_ (AV*) rv, buf);
        } else if (SvTYPE(rv) == SVt_PVHV) {
            dump_hash(aTHX_ (HV*) rv, buf);
        }
    }
}

void dump_hash(pTHX_ HV* hash, Buffer* buf)
{
    int count = 0;
    if (!hash) {
        return;
    }

    buffer_append(buf, "{", 1);

    hv_iterinit(hash);
    while (1) {
        I32 len = 0;
        char* key = 0;
        SV* val = 0;
        HE* entry = hv_iternext(hash);
        if (!entry) {
            break;
        }

        if (count++) {
            buffer_append(buf, ",", 1);
        }

        key = hv_iterkey(entry, &len);
        val = hv_iterval(hash, entry);

        buffer_append(buf, "\"", 1);
        buffer_append(buf, key, len);
        buffer_append(buf, "\":", 2);
        dump_value(aTHX_ val, buf);
    }

    buffer_append(buf, "}", 1);
}

void dump_array(pTHX_ AV* array, Buffer* buf)
{
    SSize_t top = 0;
    int j = 0;
    if (!array) {
        return;
    }

    buffer_append(buf, "[", 1);

    top = av_len(array);
    for (j = 0; j <= top; ++j) {
        SV** elem = av_fetch(array, j, 0);
        if (j) {
            buffer_append(buf, ",", 1);
        }
        dump_value(aTHX_ *elem, buf);
    }

    buffer_append(buf, "]", 1);
}
