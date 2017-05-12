/* Gearman Perl front end
 * Copyright (C) 2013 Data Differential, http://datadifferential.com/
 * Copyright (C) 2009-2010 Dennis Schoen
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.9 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#include "gearman_xs.h"

typedef struct gearman_worker_st gearman_xs_worker;

/* worker cb_arg to pass our actual perl function */
typedef struct
{
  SV * func;
  const char *cb_arg;
} gearman_worker_cb;

static SV* _create_worker() {
  gearman_worker_st *self;

  self= gearman_worker_create(NULL);
  if (self == NULL) {
      Perl_croak(aTHX_ "gearman_worker_create:NULL\n");
  }

  gearman_worker_set_workload_free_fn(self, _perl_free, NULL);
  gearman_worker_set_workload_malloc_fn(self, _perl_malloc, NULL);

  return _bless("Gearman::XS::Worker", self);
}

/* wrapper function to call our actual perl function,
   passed in through cb_arg */
static void *_perl_worker_function_callback(gearman_job_st *job,
                                     void *cb_arg,
                                     size_t *result_size,
                                     gearman_return_t *ret_ptr)
{
  gearman_worker_cb *worker_cb;
  int count;
  void *result= NULL;
  SV * result_sv;

  dSP;

  ENTER;
  SAVETMPS;

  worker_cb= (gearman_worker_cb *)cb_arg;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(_bless("Gearman::XS::Job", job)));
  if (worker_cb->cb_arg != NULL)
  {
    XPUSHs(sv_2mortal(newSVpv(worker_cb->cb_arg, strlen(worker_cb->cb_arg))));
  }
  PUTBACK;

  count= call_sv(worker_cb->func, G_EVAL|G_SCALAR);

  SPAGAIN;

  if (SvTRUE(ERRSV))
  {
    fprintf(stderr, "Job: '%s' died with: %s",
            gearman_job_function_name(job), SvPV_nolen(ERRSV));
    *ret_ptr= GEARMAN_WORK_FAIL;
    (void)POPs;
  }
  else
  {
    if (count != 1)
      croak("Invalid number of return values.\n");

    result_sv= POPs;
    if (SvOK(result_sv))
    {
      result= _get_string(result_sv, result_size);
    }

    *ret_ptr= GEARMAN_SUCCESS;
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}

static void _perl_log_fn_callback( const char *line,
                            gearman_verbose_t verbose,
                            void *fn)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(line, strlen(line))));
  XPUSHs(sv_2mortal(newSViv(verbose)));
  PUTBACK;

  call_sv(fn, G_VOID);

  FREETMPS;
  LEAVE;
}

MODULE = Gearman::XS::Worker    PACKAGE = Gearman::XS::Worker

PROTOTYPES: ENABLE

SV*
Gearman::XS::Worker::new()
  CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = _create_worker();
  OUTPUT:
    RETVAL

gearman_return_t
add_server(self, ...)
    gearman_xs_worker *self
  PREINIT:
    char *host= NULL;
    in_port_t port= 0;
  CODE:
    if( (items > 1) && SvCUR(ST(1)) )
      host= SvPV_nolen(ST(1));
    if ( items > 2)
      port= (in_port_t)SvIV(ST(2));

    RETVAL= gearman_worker_add_server(self, host, port);
  OUTPUT:
    RETVAL

gearman_return_t
add_servers(self, servers)
    gearman_xs_worker *self
    const char *servers
  CODE:
    RETVAL= gearman_worker_add_servers(self, servers);
  OUTPUT:
    RETVAL

void
remove_servers(self)
    gearman_xs_worker *self
  CODE:
    gearman_worker_remove_servers(self);

gearman_return_t
echo(self, workload)
    gearman_xs_worker *self
    SV * workload
  PREINIT:
    const char *w;
    size_t w_size;
  CODE:
    w= SvPV(workload, w_size);
    RETVAL= gearman_worker_echo(self, w, w_size);
  OUTPUT:
    RETVAL

gearman_return_t
register(self, function_name, ...)
    gearman_xs_worker *self
    const char *function_name
  PREINIT:
    uint32_t timeout= 0;
  CODE:
    if( items > 2 )
      timeout= (uint32_t)SvIV(ST(2));
    RETVAL= gearman_worker_register(self, function_name, timeout);
  OUTPUT:
    RETVAL

gearman_return_t
unregister(self, function_name)
    gearman_xs_worker *self
    const char *function_name
  CODE:
    RETVAL= gearman_worker_unregister(self, function_name);
  OUTPUT:
    RETVAL

gearman_return_t
unregister_all(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_unregister_all(self);
  OUTPUT:
    RETVAL

gearman_return_t
add_function(self, function_name, timeout, worker_fn, context)
    gearman_xs_worker *self
    const char *function_name
    uint32_t timeout
    SV * worker_fn
    const char *context
  INIT:
    gearman_worker_cb *worker_cb;
  CODE:
    Newxz(worker_cb, 1, gearman_worker_cb);
    worker_cb->func= newSVsv(worker_fn);
    worker_cb->cb_arg= context;
    RETVAL= gearman_worker_add_function(self, function_name, timeout,
                                        _perl_worker_function_callback,
                                        (void *)worker_cb );
  OUTPUT:
    RETVAL

gearman_return_t
work(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_work(self);
  OUTPUT:
    RETVAL

const char *
error(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_error(self);
  OUTPUT:
    RETVAL

gearman_worker_options_t
options(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_options(self);
  OUTPUT:
    RETVAL

void
set_options(self, options)
    gearman_xs_worker *self
    gearman_worker_options_t options
  CODE:
    gearman_worker_set_options(self, options);

void
add_options(self, options)
    gearman_xs_worker *self
    gearman_worker_options_t options
  CODE:
    gearman_worker_add_options(self, options);

void
remove_options(self, options)
    gearman_xs_worker *self
    gearman_worker_options_t options
  CODE:
    gearman_worker_remove_options(self, options);

void
grab_job(self)
    gearman_xs_worker *self
  PREINIT:
    gearman_return_t ret;
  PPCODE:
    gearman_job_st *job= gearman_worker_grab_job(self, NULL, &ret);
    XPUSHs(sv_2mortal(newSViv(ret)));
    if (ret == GEARMAN_SUCCESS)
      XPUSHs(sv_2mortal(_bless("Gearman::XS::Job", job)));
    else
      XPUSHs(&PL_sv_undef);

int
timeout(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_timeout(self);
  OUTPUT:
    RETVAL

void
set_timeout(self, timeout)
    gearman_xs_worker *self
    int timeout
  CODE:
    gearman_worker_set_timeout(self, timeout);

gearman_return_t
wait(self)
    gearman_xs_worker *self
  CODE:
    RETVAL= gearman_worker_wait(self);
  OUTPUT:
    RETVAL

void
set_log_fn(self, fn, verbose)
    gearman_xs_worker *self
    SV * fn
    gearman_verbose_t verbose
  CODE:
    gearman_worker_set_log_fn(self, _perl_log_fn_callback, newSVsv(fn), verbose);

void
function_exists(self, function_name)
    gearman_xs_worker *self
    const char *function_name
  PPCODE:
    if (gearman_worker_function_exist(self, function_name, strlen(function_name)))
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
DESTROY(self)
    gearman_xs_worker *self
  CODE:
    gearman_worker_free(self);
