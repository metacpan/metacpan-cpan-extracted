/*
 * etcd_lease.h - Lease operation handlers for EV::Etcd
 */
#ifndef ETCD_LEASE_H
#define ETCD_LEASE_H

#include "etcd_common.h"

/* Lease response handlers */
void process_lease_grant_response(pTHX_ pending_call_t *pc);
void process_lease_revoke_response(pTHX_ pending_call_t *pc);
void process_lease_time_to_live_response(pTHX_ pending_call_t *pc);
void process_lease_leases_response(pTHX_ pending_call_t *pc);

/* Bind this translation unit's EVAPI table (call once from BOOT) */
void lease_init_ev_api(pTHX);

/* Keepalive handlers */
void process_keepalive_response(pTHX_ keepalive_call_t *kc);
void keepalive_rearm_recv(pTHX_ keepalive_call_t *kc);
void cleanup_keepalive(pTHX_ keepalive_call_t *kc);
void keepalive_call_perl_release(pTHX_ keepalive_call_t *kc);
int try_reconnect_keepalive(pTHX_ keepalive_call_t *kc);

#endif /* ETCD_LEASE_H */
