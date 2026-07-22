/*
 * etcd_election.h - Election operation handlers for EV::Etcd
 */
#ifndef ETCD_ELECTION_H
#define ETCD_ELECTION_H

#include "etcd_common.h"
#include "election.pb-c.h"

/* Bind this translation unit's EVAPI table (call once from BOOT) */
void election_init_ev_api(pTHX);

/* Election response handlers */
void process_campaign_response(pTHX_ pending_call_t *pc);
void process_proclaim_response(pTHX_ pending_call_t *pc);
void process_leader_response(pTHX_ pending_call_t *pc);
void process_resign_response(pTHX_ pending_call_t *pc);

/* Election observe (streaming) handlers */
void process_observe_response(pTHX_ observe_call_t *oc);
void observe_rearm_recv(pTHX_ observe_call_t *oc);
void cleanup_observe(pTHX_ observe_call_t *oc);
void observe_call_perl_release(pTHX_ observe_call_t *oc);
int try_reconnect_observe(pTHX_ observe_call_t *oc);

/* Helper to convert LeaderKey to hash */
HV *leader_key_to_hv(pTHX_ V3electionpb__LeaderKey *lk);

#endif /* ETCD_ELECTION_H */
