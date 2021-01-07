#
# $Id$
#

package Gtk2::GLExt;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.91';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::GLExt $VERSION;

1;

# POD is in the xs files, and will be installed as a separate .pod file.

