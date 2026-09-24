#ifndef ETCD_ELECTION_H
#define ETCD_ELECTION_H

#include "etcd_common.h"
#include "election.pb-c.h"

void election_init_ev_api(pTHX);

void process_campaign_response(pTHX_ pending_call_t *pc);
void process_proclaim_response(pTHX_ pending_call_t *pc);
void process_leader_response(pTHX_ pending_call_t *pc);
void process_resign_response(pTHX_ pending_call_t *pc);

void process_observe_response(pTHX_ observe_call_t *oc);
void observe_rearm_recv(pTHX_ observe_call_t *oc);
void cleanup_observe(pTHX_ observe_call_t *oc);
void observe_call_perl_release(pTHX_ observe_call_t *oc);
int try_reconnect_observe(pTHX_ observe_call_t *oc);

#endif
