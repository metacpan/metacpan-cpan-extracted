/*
 * Copyright (c) 2015, Circonus, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
#ifndef _REENTRANT
#define _REENTRANT
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fq.h"

struct logger_fq_struct {
  fq_client client;
  char *host;
  int port;
  char *user;
  char *password;
  char *exchange;
  int heartbeat;
  int backlog;
  int connected;
};
typedef struct logger_fq_struct * Logger__Fq;

#define GLOBAL_LOGGER_FQS_MAX 16
static int GLOBAL_LOGGER_FQS_CNT = 0;
static Logger__Fq GLOBAL_LOGGER_FQS[GLOBAL_LOGGER_FQS_MAX];

#define int_from_hv(hv,name) \
 do { SV **v; if(NULL != (v = hv_fetch(hv, #name, strlen(#name), 0))) name = SvIV(*v); } while(0)
#define double_from_hv(hv,name) \
 do { SV **v; if(NULL != (v = hv_fetch(hv, #name, strlen(#name), 0))) name = SvNV(*v); } while(0)
#define str_from_hv(hv,name) \
 do { SV **v; if(NULL != (v = hv_fetch(hv, #name, strlen(#name), 0))) name = SvPV_nolen(*v); } while(0)

MODULE = Logger::Fq PACKAGE = Logger::Fq PREFIX = logger_fq_

REQUIRE:        1.9505
PROTOTYPES:     DISABLE

void
logger_fq_debug(flags)
  int flags
  CODE:
    fq_debug_set_bits(flags);

Logger::Fq
logger_fq_new(clazz, ...)
  char *clazz
  PREINIT:
    int i;
    HV *options;
    char *user = "guest";
    char *password = "guest";
    char *host = "127.0.0.1";
    int port = 8765;
    double heartbeat = 1.0;
    int backlog = 10000;
    char *exchange = "logging";
  CODE:
    Logger__Fq logger;
    if(GLOBAL_LOGGER_FQS_CNT >= GLOBAL_LOGGER_FQS_MAX) {
      Perl_croak(aTHX_ "Too many Logger::Fq instances...");
    }
    if(items > 1) {
      if(SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
        options = (HV*)SvRV(ST(1));
        str_from_hv(options, user);
        str_from_hv(options, password);
        str_from_hv(options, host);
        str_from_hv(options, exchange);
        int_from_hv(options, port);
        int_from_hv(options, backlog);
        double_from_hv(options, heartbeat);
      } else {
        Perl_croak(aTHX_ "optional parameter to Logger::Fq->new must be hashref");
      }
    }

    logger = NULL;
    for(i=0;i<GLOBAL_LOGGER_FQS_CNT;i++) {
      logger = GLOBAL_LOGGER_FQS[i];
      if(!strcmp(user, logger->user) &&
         !strcmp(password, logger->password) &&
         !strcmp(exchange, logger->exchange) &&
         port == logger->port) {
        RETVAL = logger;
        break;
      }
      logger = NULL;
    }

    if(!logger) {
      logger = calloc(1, sizeof(*logger));
      GLOBAL_LOGGER_FQS[GLOBAL_LOGGER_FQS_CNT++] = logger;

      logger->user = strdup(user);
      logger->password = strdup(password);
      logger->host = strdup(host);
      logger->exchange = strdup(exchange);
      logger->port = port;
      logger->backlog = backlog;
      logger->heartbeat = (int)(heartbeat * 1000.0);
      fq_client_init(&logger->client, 0, NULL);
      fq_client_creds(logger->client, logger->host, logger->port,
                      logger->user, logger->password);
      fq_client_heartbeat(logger->client, logger->heartbeat);
      fq_client_set_backlog(logger->client, logger->backlog, 0);
      fq_client_set_nonblock(logger->client, 1);
      RETVAL = logger;
    }
  OUTPUT:
    RETVAL

int
logger_fq_DESTROY(logger)
  Logger::Fq logger
  PREINIT:
    int i;
  CODE:
    for(i=0;i<GLOBAL_LOGGER_FQS_CNT;i++) {
      if(logger == GLOBAL_LOGGER_FQS[i]) {
        GLOBAL_LOGGER_FQS[i] = NULL;
        fq_client_destroy(logger->client);
        if(logger->user) free(logger->user);
        if(logger->password) free(logger->password);
        if(logger->host) free(logger->host);
        if(logger->exchange) free(logger->exchange);
        break;
      }
    }

int
logger_fq_log(logger, routing_key, body, ...)
  Logger::Fq logger
  char *routing_key
  SV *body
  PREINIT:
    fq_msg *msg;
    STRLEN len;
    void *body_buf;
    char *exchange;
    int rv;
  CODE:
    if(!logger->connected) {
      logger->connected = 1;
      fq_client_connect(logger->client);
    }
    body_buf = SvPV(body, len);
    msg = fq_msg_alloc(body_buf, len);
    fq_msg_id(msg, NULL);
    exchange = logger->exchange;
    if(items > 3) {
      exchange = SvPV_nolen(ST(3));
    }
    fq_msg_exchange(msg, exchange, strlen(exchange));
    fq_msg_route(msg, routing_key, strlen(routing_key));
    rv = fq_client_publish(logger->client, msg);
    fq_msg_free(msg);
    RETVAL = rv;
  OUTPUT:
    RETVAL

int
logger_fq_backlog()
  PREINIT:
    int msgs = 0;
    int i;
  CODE:
    for(i=0; i<GLOBAL_LOGGER_FQS_CNT; i++)
      msgs += fq_client_data_backlog(GLOBAL_LOGGER_FQS[i]->client);
    RETVAL = msgs;
  OUTPUT:
    RETVAL

int
logger_fq_drain(timeout_ms)
  int timeout_ms
  PREINIT:
    int msgs;
    int initial = 0;
    int i;
  CODE:
    while(timeout_ms > 0) {
      msgs = 0;
      for(i=0; i<GLOBAL_LOGGER_FQS_CNT; i++)
        msgs += fq_client_data_backlog(GLOBAL_LOGGER_FQS[i]->client);
      if(!initial) initial = msgs;
      if(msgs == 0) break;
      usleep((timeout_ms < 10000) ? timeout_ms : 10000);
      timeout_ms -= 10000;
    }
    RETVAL = (initial - msgs);
  OUTPUT:
    RETVAL
