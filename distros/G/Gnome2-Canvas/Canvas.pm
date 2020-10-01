#
# $Id$
#

package Gnome2::Canvas;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.004';

sub import {
	my $class = shift;
	$class->VERSION (@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

bootstrap Gnome2::Canvas $VERSION;

# Preloaded methods go here.

1;
__END__

This is not the POD you're looking for.

The documentation for this module is generated from the XS source, and
is stored in separate .pod files.

