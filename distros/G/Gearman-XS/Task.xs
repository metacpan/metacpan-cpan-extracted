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

typedef struct gearman_task_st gearman_xs_task;

MODULE = Gearman::XS::Task    PACKAGE = Gearman::XS::Task

PROTOTYPES: ENABLE

const char *
job_handle(self)
    gearman_xs_task *self
  CODE:
    RETVAL= gearman_task_job_handle(self);
  OUTPUT:
    RETVAL

SV *
data(self)
    gearman_xs_task *self
  CODE:
    RETVAL= newSVpvn(gearman_task_data(self), gearman_task_data_size(self));
  OUTPUT:
    RETVAL

int
data_size(self)
    gearman_xs_task *self
  CODE:
    RETVAL= (int)gearman_task_data_size(self);
  OUTPUT:
    RETVAL

const char *
function_name(self)
    gearman_xs_task *self
  CODE:
    RETVAL= gearman_task_function_name(self);
  OUTPUT:
    RETVAL

uint32_t
numerator(self)
    gearman_xs_task *self
  CODE:
    RETVAL= gearman_task_numerator(self);
  OUTPUT:
    RETVAL

uint32_t
denominator(self)
    gearman_xs_task *self
  CODE:
    RETVAL= gearman_task_denominator(self);
  OUTPUT:
    RETVAL

const char *
unique(self)
    gearman_xs_task *self
  CODE:
    RETVAL= gearman_task_unique(self);
  OUTPUT:
    RETVAL

void
is_known(self)
    gearman_xs_task *self
  PPCODE:
    if (gearman_task_is_known(self))
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
is_running(self)
    gearman_xs_task *self
  PPCODE:
    if (gearman_task_is_running(self))
      XSRETURN_YES;
    else
      XSRETURN_NO;
  
