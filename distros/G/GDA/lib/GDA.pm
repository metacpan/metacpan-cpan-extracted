#!/usr/bin/perl -w
#
# GDA.pm
#
# $Revision: 1.3 $
#
# TODO:
#
#   * Don't hardcode the app name, etc. in init().
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;

package GDA;

use Carp;

use vars qw($VERSION);
$VERSION = '0.2';

use Inline 'C';

use Inline 'C' => Config =>
  INC          => '-I/usr/include/gda -I/usr/include/glib-1.2 -I/usr/lib/glib/include -I/usr/include/gtk-1.2 -I/usr/include/gnome-xml',
  AUTO_INCLUDE => '#include "gda-config.h"',
  LIBS         => '-lgda-common';

  Inline->init;

my $imported = 0;

sub import
{
  my $package = shift;

  return if $imported;

  croak "GDA.pm: usage: use GDA <app>, <ver>, ...;\n"
    . "  Caller did: use GDA " . join(', ', map { "'$_'" } @_) . ";\n"
    . "  (If this message is for a GDA::* module, perhaps you forgot to\n"
    . "  'use GDA ...' in your main program?)"  unless @_ >= 2;

  my $app = shift;
  my $ver = shift;

  my $prog;

  if (@_) {
    $prog = shift;
  } else {
    $prog = $0;
  }
 
  # TODO: Why were we getting undefs in the first place ('under make test')?

  $app  = '<undef>' if not defined $app;
  $ver  = '<undef>' if not defined $ver;
  $prog = '<undef>' if not defined $prog;

  init($app, $ver, $prog);
  $imported++;
}

sub imported
{
  return $imported;
}

1;

=head1 NAME

GDA - GNU Data Access library Perl bindings

=head1 SYNOPSIS

  use GDA 'my_app', 'my_version', 'my_progname';

Initializes the underlying C<libgda> library.

See the other B<GDA::*> modules for the real functionality.

=head1 DESCRIPTION

A suite of Perl modules which wrap the C<libgda> library's API.

You must

  use GDA ...;

before using any of the other B<GDA> modules. If you don't, you'll get
complaints from the B<GDA> module (at best), or crashes and core dumps
(at worst).

=head1 SEE ALSO

B<GDA::Config>, B<GDA::DSN>, B<GDA::Log> and B<GDA::Provider>.

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


void init(char * app, char * ver, char * prog)
{
  int argc = 1;
  char * argv [] = { prog, NULL };

  gda_init(app, ver, argc, argv); /* TODO: Who owns these strings? */
}


/*
** EOF
*/

