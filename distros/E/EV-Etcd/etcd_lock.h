#ifndef ETCD_LOCK_H
#define ETCD_LOCK_H

#include "etcd_common.h"

void process_lock_response(pTHX_ pending_call_t *pc);
void process_unlock_response(pTHX_ pending_call_t *pc);

#endif
