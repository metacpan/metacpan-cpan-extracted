#!/usr/bin/perl -w
#
# Log.pm
#
# $Revision: 1.2 $
#
# TODO:
#
#   * gda_log_clean_between() and gda_log_clean_entry are in the API docs, but
#     are not found when running strings on the libgda-common.a file. Therefore
#     they are not included here.
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;

package GDA::Log;

use GDA;

use Inline 'C';

use Inline 'C' => Config =>
  INC          => '-I/usr/include/gda -I/usr/include/glib-1.2 -I/usr/lib/glib/include -I/usr/include/gtk-1.2 -I/usr/include/gnome-xml',
  AUTO_INCLUDE => '#include "gda-config.h"',
  LIBS         => '-lgda-common';

sub message
{
  my $message = sprintf(@_);

  $message =~ s/\\/\\\\/; # Double any backslashes
  $message =~ s/%/\\%/;   # Escape any fields

  message_impl($message);
}

sub error
{
  my $message = sprintf(@_);

  $message =~ s/\\/\\\\/; # Double any backslashes
  $message =~ s/%/\\%/;   # Escape any fields

  error_impl($message);
}

1;

=head1 NAME

GDA::Log - GDA logging Perl bindings

=head1 SYNOPSIS

  use GDA 'my_app', 'my_ver', 'my_prog';
  use GDA::Log;
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


void enable()
{
  gda_log_enable();
}

void disable()
{
  gda_log_disable();
}

long is_enabled()
{
  return gda_log_is_enabled();
}

/* Perl hooks do formatting */
void message_impl(char * message)
{
  gda_log_message(message);
}

/* Perl hooks do formatting */
void error_impl(char * message)
{
  gda_log_error(message);
}

void clean_all(char * program)
{
  gda_log_clean_all(program);
}


/*
** EOF
*/

