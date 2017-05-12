#
# check Glib::Object derivation -- make sure that INIT_INSTANCE and
# FINALIZE_INSTANCE are called in the right order, and that objects
# actually go away.  since we're testing execution order, we don't
# use a Test module.
#

print "1..6\n";

use strict;
use warnings;

use Glib;

print "ok 1\n";

# this will set @ISA for Foo, and register the type.
# note that if you aren't going to add properties, signals, or
# virtual overrides, there's no reason to do this rather than
# just re-blessing the object, so this is a rather contrived
# example.

my ($ok1, $ok2);

sub Foo::INIT_INSTANCE {
   print "ok $ok1\n";
}

sub Foo::FINALIZE_INSTANCE {
   print "ok $ok2\n";
}

Glib::Type->register (Glib::Object::, Foo::);

{
	$ok1 = 2; my $bar = new Foo;
	$ok2 = 3; undef $bar;
	$ok1 = 4; $bar = new Foo;
        $ok2 = 5;
}

print "ok 6\n";

$ok1 = $ok2 = -1;


__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
