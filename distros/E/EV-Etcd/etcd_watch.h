/*
 * etcd_watch.h - Watch operation handlers for EV::Etcd
 */
#ifndef ETCD_WATCH_H
#define ETCD_WATCH_H

#include "etcd_common.h"

/* Watch operation handlers */
void process_watch_response(pTHX_ watch_call_t *wc);
void watch_rearm_recv(pTHX_ watch_call_t *wc);
void cleanup_watch(pTHX_ watch_call_t *wc);
void watch_call_perl_release(pTHX_ watch_call_t *wc);
int try_reconnect_watch(pTHX_ watch_call_t *wc);

#endif /* ETCD_WATCH_H */
