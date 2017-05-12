#!/usr/bin/perl -w
#
# DSN.pm
#
# $Revision: 1.2 $
#
# NOTE:
#
#   * Mapped 'gda_name' to 'name'
#   * Mapped 'dsn' to 'connect'
#
# TODO:
#
#   * gda_list_datasources()
#   * gda_list_datasources_for_provider()
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;

package GDA::DSN;

use GDA;

use Inline 'C';

use Inline 'C' => Config =>
  INC          => '-I/usr/include/gda -I/usr/include/glib-1.2 -I/usr/lib/glib/include -I/usr/include/gtk-1.2 -I/usr/include/gnome-xml',
  AUTO_INCLUDE => '#include "gda-config.h"',
  LIBS         => '-lgda-common';

sub list
{
  my $class = shift;

  if (@_) {
    return list_some($class, @_);
  } else {
    return list_all($class); # See comment for 'list_all', below
  }
}

sub name
{
  if (@_) {
    set_name(@_);
  } else {
    return get_name();
  }
}

sub provider
{
  if (@_) {
    set_provider(@_);
  } else {
    return get_provider();
  }

}

sub connect
{
  if (@_) {
    set_connect(@_);
  } else {
    return get_connect();
  }
}

sub description
{
  if (@_) {
    set_description(@_);
  } else {
    return get_description();
  }

}

sub username
{
  if (@_) {
    set_username(@_);
  } else {
    return get_username();
  }
}

sub config
{
  if (@_) {
    set_config(@_);
  } else {
    return get_config();
  }
}

sub global
{
  if (@_) {
    set_global(@_);
  } else {
    return get_global();
  }
}

sub remove # See 'remove_dsn' below for explanation.
{
  remove_dsn(@_);
}

1;

=head1 NAME

GDA::DSN - GDA data source Perl bindings

=head1 SYNOPSIS

  use GDA 'my_app', 'my_ver', 'my_prog';
  use GDA::DSN;
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

static SV * objectify_(char * class, GdaDsn * self)
{
  SV * obj_ref;
  SV * obj;

  obj_ref = newSViv(0);
  obj     = newSVrv(obj_ref, class);

  sv_setiv(obj, (IV)self);
  SvREADONLY_on(obj);

  return obj_ref;
}

static SV * clone_(char * class, GdaDsn * self)
{
  self = gda_dsn_copy(self);
  return objectify_(class, self);
}


/*********************************************************************
** CLASS SUBROUTINES                                                **
*********************************************************************/

/* 'list_all' instead of 'list' because maps to Perl_list, which is taken */

void list_all(char * class)
{
  Inline_Stack_Vars;
  GList *  list;
  long     length;
  long     index;
  GdaDsn * data;

  list = gda_dsn_list(); /* TODO: what is gda_list_datasources()? */
  length = g_list_length(list);

  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for (index = 0; index < length; index++) {
    data = (GdaDsn *)g_list_nth_data(list, index);
    Inline_Stack_Push(clone_(class, data));
  }

  gda_dsn_free_list(list);

  Inline_Stack_Done;
}

void list_names(char * class)
{
  Inline_Stack_Vars;
  GList *  list;
  long     length;
  long     index;
  GdaDsn * data;

  list = gda_dsn_list();
  length = g_list_length(list);

  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for (index = 0; index < length; index++) {
    data = (GdaDsn *)g_list_nth_data(list, index);
    Inline_Stack_Push(newSVpv(GDA_DSN_GDA_NAME(data), 0));
  }

  gda_dsn_free_list(list);

  Inline_Stack_Done;
}

SV * find_by_name(char * class, char * name)
{
  GdaProvider * self;

  self = gda_dsn_find_by_name(name);

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
  GdaDsn * self;

  self = gda_dsn_new();

  return objectify_(class, self);
}

void DESTROY(SV * obj)
{
  GdaDsn * self;

  self = (GdaDsn *)SvIV(SvRV(obj));

  gda_dsn_free(self);
}


/*********************************************************************
** ATTRIBUTES                                                       **
*********************************************************************/

char * get_name(SV * obj)
{
  return GDA_DSN_GDA_NAME((GdaDsn *)SvIV(SvRV(obj)));
}

void set_name(SV * obj, char * name)
{
  gda_dsn_set_name((GdaDsn *)SvIV(SvRV(obj)), name);
}

char * get_provider(SV * obj)
{
  return GDA_DSN_PROVIDER((GdaDsn *)SvIV(SvRV(obj)));
}

void set_provider(SV * obj, char * provider)
{
  gda_dsn_set_provider((GdaDsn *)SvIV(SvRV(obj)), provider);
}

char * get_connect(SV * obj)
{
  return GDA_DSN_DSN((GdaDsn *)SvIV(SvRV(obj)));
}

void set_connect(SV * obj, char * connect)
{
  gda_dsn_set_dsn((GdaDsn *)SvIV(SvRV(obj)), connect);
}

char * get_description(SV * obj)
{
  return GDA_DSN_DESCRIPTION((GdaDsn *)SvIV(SvRV(obj)));
}

void set_description(SV * obj, char * description)
{
  gda_dsn_set_description((GdaDsn *)SvIV(SvRV(obj)), description);
}

char * get_username(SV * obj)
{
  return GDA_DSN_USERNAME((GdaDsn *)SvIV(SvRV(obj)));
}

void set_username(SV * obj, char * username)
{
  gda_dsn_set_username((GdaDsn *)SvIV(SvRV(obj)), username);
}

char * get_config(SV * obj)
{
  return GDA_DSN_CONFIG((GdaDsn *)SvIV(SvRV(obj)));
}

void set_config(SV * obj, char * config)
{
  gda_dsn_set_config((GdaDsn *)SvIV(SvRV(obj)), config);
}

long get_global(SV * obj)
{
  return ((GdaDsn *)SvIV(SvRV(obj)))->is_global;
}

void set_global(SV * obj, long global)
{
  gda_dsn_set_global((GdaDsn *)SvIV(SvRV(obj)), global);
}


/*********************************************************************
** UTILITIES                                                        **
*********************************************************************/

long save(SV * obj)
{
  return gda_dsn_save((GdaDsn *)SvIV(SvRV(obj)));
}

/* Name is 'remove_dsn' instead of 'remove' due to stdlib conflict */
long remove_dsn(SV * obj)
{
  return gda_dsn_remove((GdaDsn *)SvIV(SvRV(obj)));
}


/*
** EOF
*/

