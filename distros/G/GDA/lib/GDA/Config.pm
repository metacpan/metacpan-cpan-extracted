#!/usr/bin/perl -w
#
# Config.pm
#
# $Revision: 1.2 $
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;


package GDA::Config;

use GDA;

use Inline 'C';

use Inline 'C' => Config =>
  INC          => '-I/usr/include/gda -I/usr/include/glib-1.2 -I/usr/lib/glib/include -I/usr/include/gtk-1.2 -I/usr/include/gnome-xml',
  AUTO_INCLUDE => '#include "gda-config.h"',
  LIBS         => '-lgda-common';


1;

=head1 NAME

GDA::Config - GDA configuration database access Perl bindings

=head1 SYNOPSIS

  use GDA 'my_app', 'my_ver', 'my_prog';
  use GDA::Config;
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
** CONSTANTS                                                        **
*********************************************************************/

char * SECTION_DATASOURCES()
{
  return GDA_CONFIG_SECTION_DATASOURCES;
}

char * SECTION_LOG()
{
  return GDA_CONFIG_SECTION_LOG;
}


/*********************************************************************
** STRING VALUES                                                    **
*********************************************************************/

char * get_string(char * path)
{
  return gda_config_get_string(path);
}

void set_string(char * path, char * new_value)
{
  gda_config_set_string(path, new_value);
}


/*********************************************************************
** INTEGER VALUES                                                   **
*********************************************************************/

long get_int(char * path)
{
  return gda_config_get_int(path);
}

void set_int(char * path, long new_value)
{
  gda_config_set_int(path, new_value);
}


/*********************************************************************
** FLOAT VALUES                                                     **
*********************************************************************/

double get_float(char * path)
{
  return gda_config_get_float(path);
}

void set_float(char * path, double new_value)
{
  gda_config_set_float(path, new_value);
}


/*********************************************************************
** BOOLEAN VALUES                                                   **
*********************************************************************/

long get_boolean(char * path)
{
  return gda_config_get_boolean(path);
}

void set_boolean(char * path, long new_value)
{
  gda_config_set_boolean(path, new_value);
}


/*********************************************************************
** SECTIONS                                                         **
*********************************************************************/

int has_section(char * path)
{
  return gda_config_has_section(path);
}

void list_sections(char * path)
{
  Inline_Stack_Vars;
  GList * list;
  long    length;
  long    index;
  char *  data;

  list   = gda_config_list_sections(path);
  length = g_list_length(list);

  if (!length) {
    Inline_Stack_Void;
    return;
  }

  Inline_Stack_Reset;

  for(index = 0; index < length; index++) {
    data = g_list_nth_data(list, index);
    Inline_Stack_Push(newSVpv(data, 0)); /* TODO: sv_2mortal()? */
  }

  gda_config_free_list(list);

  Inline_Stack_Done;
}

void remove_section(char * path)
{
  gda_config_remove_section(path);
}


/*********************************************************************
** KEYS                                                             **
*********************************************************************/

int has_key(char * path)
{
  return gda_config_has_key(path);
}

void list_keys(char * path)
{
  Inline_Stack_Vars;
  GList * list;
  long    length;
  long    index;
  char *  data;

  Inline_Stack_Reset;

  list   = gda_config_list_keys(path);
  length = g_list_length(list);

  for(index = 0; index < length; index++) {
    data = g_list_nth_data(list, index);
    Inline_Stack_Push(newSVpv(data, 0)); /* TODO: sv_2mortal()? */
  }

  gda_config_free_list(list);

  Inline_Stack_Done;
}

void remove_key(char * path)
{
  gda_config_remove_key(path);
}


/*********************************************************************
** TRANSACTIONS                                                     **
*********************************************************************/

void commit()
{
  gda_config_commit();
}

void rollback()
{
  gda_config_rollback();
}


/*
** EOF
*/

