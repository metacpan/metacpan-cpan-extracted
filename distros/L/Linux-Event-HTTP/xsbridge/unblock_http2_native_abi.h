/* Public ABI snapshot from Unblock::HTTP2 0.12, commit
 * 7bc0b6ccd653a74ad1e7399d27aa9d94c941b513. No HTTP2 link dependency.
 * Runtime version and structure size are checked before use.
 *
 * MIT License
 * 
 * Copyright (c) 2026 Joshua S. Day
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#ifndef UNBLOCK_HTTP2_NATIVE_ABI_H
#define UNBLOCK_HTTP2_NATIVE_ABI_H

#include "EXTERN.h"
#include "perl.h"
#include <stddef.h>
#include <stdint.h>

#define UB_HTTP2_NATIVE_ABI_VERSION 1U

#define UB_HTTP2_INPUT_OK      0
#define UB_HTTP2_INPUT_MORE    1
#define UB_HTTP2_INPUT_CLOSED  3

#define UB_HTTP2_OUTPUT_OK      0
#define UB_HTTP2_OUTPUT_CLOSED  3

#define UB_HTTP2_OUTPUT_CONTINUE 0
#define UB_HTTP2_OUTPUT_PAUSE    1
#define UB_HTTP2_OUTPUT_ERROR   -1

typedef int (*ub_http2_output_sink_v1)(
    pTHX_
    void *sink_context,
    const char *data,
    size_t length
);

typedef struct ub_http2_native_ops_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    const char *name;

    void *(*create)(pTHX_ SV *engine);

    int (*input)(
        pTHX_
        void *context,
        const char *data,
        size_t length,
        size_t *consumed
    );

    int (*eof)(pTHX_ void *context);

    void (*destroy)(pTHX_ void *context);

    int (*output)(
        pTHX_
        void *context,
        ub_http2_output_sink_v1 sink,
        void *sink_context,
        size_t *produced
    );

    int (*want_read)(pTHX_ void *context);
    int (*want_write)(pTHX_ void *context);
} ub_http2_native_ops_v1;

#endif
