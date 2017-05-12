#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/GLExt.pm,v 1.3 2004/10/29 00:18:43 rwmcfa1 Exp $
#

package Gtk2::GLExt;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.90';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::GLExt $VERSION;

1;

# POD is in the xs files, and will be installed as a separate .pod file.

