#!/usr/bin/perl -w
#
# Provider.pm
#
# $Revision: 1.2 $
#
# TODO:
#
#   * gda_list_datasources_for_provider()
#   * Should we really allow new() to clients, since we don't allow
#     setting attributes?
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
# 


use strict;

package GDA::Provider;

use GDA;

use Inline 'C';

use Inline 'C' => Config =>
  INC          => '-I/usr/include/gda -I/usr/include/glib-1.2 -I/usr/lib/glib/include -I/usr/include/gtk-1.2 -I/usr/include/gnome-xml',
  AUTO_INCLUDE => '#include "gda-config.h"',
  LIBS         => '-lgda-common';

sub list { return list_all(@_); } # See comment for 'list_all', below

1;

=head1 NAME

GDA::Provider - GDA provider Perl bindings

=head1 SYNOPSIS

  use GDA 'my_app', 'my_ver', 'my_prog';
  use GDA::Provider;
  ...

=head1 DESCRIPTION

TODO

=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>

=head1 LICENSE

This program is free software. It may be modified and/or
distributed under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (C) 2001 Gregor N. Purdy. All rights reserved.

=cut

__DATA__
__C__


/*********************************************************************
** SUPPORT                                                          **
*********************************************************************/

static SV * objectify_(char * class, GdaProvider * self)
{
  SV * obj_ref;
  SV * obj;

  obj_ref = newSViv(0);
  obj     = newSVrv(obj_ref, class);

  sv_setiv(obj, (IV)self);
  SvREADONLY_on(obj);

  return obj_ref;
}

static SV * clone_(char * class, GdaProvider * self)
{
  self = gda_provider_copy(self);
  return objectify_(class, self);
}


/*********************************************************************
** CLASS SUBROUTINES                                                **
*********************************************************************/

/* 'list_all' instead of 'list' because maps to Perl_list, which is taken */

void list_all(char * class)
{
  Inline_Stack_Vars;
  GList *       list;
  long          length;
  long          index;
  GdaProvider * data;

  list = gda_provider_list();
  length = g_list_length(list);

  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for (index = 0; index < length; index++) {
    data = (GdaProvider *)g_list_nth_data(list, index);
    Inline_Stack_Push(clone_(class, data));
  }

  gda_provider_free_list(list);

  Inline_Stack_Done;
}

void list_names(char * class)
{
  Inline_Stack_Vars;
  GList *       list;
  long          length;
  long          index;
  GdaProvider * data;

  list = gda_provider_list();
  length = g_list_length(list);

  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for (index = 0; index < length; index++) {
    data = (GdaProvider *)g_list_nth_data(list, index);
    Inline_Stack_Push(newSVpv(GDA_PROVIDER_NAME(data), 0));
  }

  gda_provider_free_list(list);

  Inline_Stack_Done;
}

SV * find_by_name(char * class, char * name)
{
  GdaProvider * self;

  self = gda_provider_find_by_name(name);

  if (!self) {
    return NULL; /* TODO: Is this OK? */
  }

  return objectify_(class, self);
}


/*********************************************************************
** CONSTRUCTOR and DESTRUCTOR                                       **
*********************************************************************/

SV * new(char * class)
{
  GdaProvider * self;

  self = gda_provider_new();

  return objectify_(class, self);
}

void DESTROY(SV * obj)
{
  GdaProvider * self;

  self = (GdaProvider *)SvIV(SvRV(obj));

  gda_provider_free(self);
}


/*********************************************************************
** ATTRIBUTES                                                       **
*********************************************************************/

char * type(SV * obj)
{
  return GDA_PROVIDER_TYPE((GdaProvider *)SvIV(SvRV(obj)));
}

char * name(SV * obj)
{
  return GDA_PROVIDER_NAME((GdaProvider *)SvIV(SvRV(obj)));
}

char * comment(SV * obj)
{
  return GDA_PROVIDER_COMMENT((GdaProvider *)SvIV(SvRV(obj)));
}

char * location(SV * obj)
{
  return GDA_PROVIDER_LOCATION((GdaProvider *)SvIV(SvRV(obj)));
}

char * repo_id(SV * obj)
{
  return GDA_PROVIDER_REPO_ID((GdaProvider *)SvIV(SvRV(obj)));
}

char * username(SV * obj)
{
  return GDA_PROVIDER_USERNAME((GdaProvider *)SvIV(SvRV(obj)));
}

char * hostname(SV * obj)
{
  return GDA_PROVIDER_HOSTNAME((GdaProvider *)SvIV(SvRV(obj)));
}

char * domain(SV * obj)
{
  return GDA_PROVIDER_DOMAIN((GdaProvider *)SvIV(SvRV(obj)));
}

void dsn_params(SV * obj)
{
  Inline_Stack_Vars;
  GList * list;
  long    length;
  long    index;
  char *  data;

  list = GDA_PROVIDER_DSN_PARAMS((GdaProvider *)SvIV(SvRV(obj)));
  length = g_list_length(list);
  
  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for (index = 0; index < length; index++) {
    data = g_list_nth_data(list, index);
    Inline_Stack_Push(newSVpv(data, 0)); /* TODO: sv_2mortal()? */
  }
  
  /* We don't free the list because it is owned by the GdaProvider struct */

  Inline_Stack_Done;
}


/*
** EOF
*/

