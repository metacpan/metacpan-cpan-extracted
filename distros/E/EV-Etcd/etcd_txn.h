#ifndef ETCD_TXN_H
#define ETCD_TXN_H

#include "etcd_common.h"

/* Frees what parse_request_ops allocated; key/value data borrows Perl SV buffers */
#define FREE_REQUEST_OPS(ops, n_ops) \
    do { \
        if ((ops)) { \
            for (size_t _i = 0; _i < (n_ops); _i++) { \
                if ((ops)[_i]) { \
                    switch ((ops)[_i]->request_case) { \
                        case ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_RANGE: \
                            Safefree((ops)[_i]->request_range); \
                            break; \
                        case ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_PUT: \
                            Safefree((ops)[_i]->request_put); \
                            break; \
                        case ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_DELETE_RANGE: \
                            Safefree((ops)[_i]->request_delete_range); \
                            break; \
                        default: \
                            break; \
                    } \
                    Safefree((ops)[_i]); \
                } \
            } \
            Safefree((ops)); \
        } \
    } while (0)

#endif
