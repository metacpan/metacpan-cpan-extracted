#ifndef LINUX_EVENT_STREAM_CONSUMER_ABI_H
#define LINUX_EVENT_STREAM_CONSUMER_ABI_H

#include "EXTERN.h"
#include "perl.h"

#include <stddef.h>
#include <stdint.h>

#define LES_CONSUMER_ABI_VERSION 1U

#define LES_CONSUMER_F_START_PAUSED 0x01U
#define LES_CONSUMER_F_WANT_FLUSH   0x02U
#define LES_CONSUMER_F_RAW_INPUT    0x04U

#define LES_CONSUMER_CONTINUE 0
#define LES_CONSUMER_PAUSE    1
#define LES_CONSUMER_CLOSE    2
#define LES_CONSUMER_ERROR    3

#define LES_CONSUMER_EVENT_EOF           1U
#define LES_CONSUMER_EVENT_READ_ERROR    2U
#define LES_CONSUMER_EVENT_FRAMING_ERROR 3U
#define LES_CONSUMER_EVENT_CLOSED        4U
#define LES_CONSUMER_EVENT_DETACHED      5U
#define LES_CONSUMER_EVENT_READ_CLOSED   6U

/* New terminal event codes may be appended without changing the table
 * layout. Providers must treat an unknown event code as terminal and apply
 * the same conservative cleanup used for LES_CONSUMER_EVENT_CLOSED. */

typedef struct les_consumer_host_api_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    int (*resume)(pTHX_ void *host_context);
    int (*pause)(pTHX_ void *host_context);
    SV *(*stream)(pTHX_ void *host_context);
    int (*is_closed)(pTHX_ void *host_context);
    /* Optional append-only ABI-v1 lifetime extension. A provider-owned entry
     * frame retains before a callback-capable host call and releases only
     * after its final provider-context access. release may destroy both the
     * host state and provider context, so it must be the frame's last action. */
    int (*retain)(pTHX_ void *host_context);
    void (*release)(pTHX_ void *host_context);
} les_consumer_host_api_v1_t;

#define LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE \
    (offsetof(les_consumer_host_api_v1_t, release) \
        + sizeof(((les_consumer_host_api_v1_t *)0)->release))

typedef struct les_consumer_ops_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    const char *name;
    uint32_t flags;
    void *(*create)(pTHX_ const les_consumer_host_api_v1_t *host,
        void *host_context, SV *stream);
    int (*message)(pTHX_ void *context, SV *message);
    void (*event)(pTHX_ void *context, uint32_t event, int error,
        const char *message);
    void (*destroy)(pTHX_ void *context);
    /* Optional. Called once after a native input drain that delivered one or
     * more framed messages or invoked raw input. This field was appended to
     * ABI v1; hosts must check struct_size before reading it. */
    int (*flush)(pTHX_ void *context);
    /* Optional raw-input extension. Providers requesting
     * LES_CONSUMER_F_RAW_INPUT receive a borrowed contiguous native input
     * window before any payload SV is created. They report how many leading
     * bytes were consumed; the host retains the unconsumed tail. */
    int (*input)(pTHX_ void *context, const char *data, size_t length,
        size_t *consumed);
} les_consumer_ops_v1_t;

#define LES_CONSUMER_OPS_V1_REQUIRED_SIZE \
    offsetof(les_consumer_ops_v1_t, flush)
#define LES_CONSUMER_OPS_V1_FLUSH_REQUIRED_SIZE \
    offsetof(les_consumer_ops_v1_t, input)
#define LES_CONSUMER_OPS_V1_RAW_INPUT_REQUIRED_SIZE \
    (offsetof(les_consumer_ops_v1_t, input) \
        + sizeof(((les_consumer_ops_v1_t *)0)->input))

#endif
