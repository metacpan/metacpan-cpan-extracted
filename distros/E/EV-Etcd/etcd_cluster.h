#ifndef ETCD_CLUSTER_H
#define ETCD_CLUSTER_H

#include "etcd_common.h"
#include "cluster.pb-c.h"

void process_member_add_response(pTHX_ pending_call_t *pc);
void process_member_remove_response(pTHX_ pending_call_t *pc);
void process_member_update_response(pTHX_ pending_call_t *pc);
void process_member_list_response(pTHX_ pending_call_t *pc);
void process_member_promote_response(pTHX_ pending_call_t *pc);

#endif
