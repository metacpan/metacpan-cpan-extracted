#!/usr/bin/perl -w
#
# 04log.t
#
# $Revision: 1.1.1.1 $
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;

print "1..4\n";

my $prog = 'libgda-perl-test-04';
use GDA $prog, $GDA::VERSION, $0;
use GDA::Log;

print "not " if $@;
print "ok 1\n";

my $save = GDA::Log::is_enabled();
print "Saved state: $save\n";

GDA::Log::enable();
print "not " unless GDA::Log::is_enabled();
print "ok 2\n";

GDA::Log::message("Testing 1-2-3.");
#GDA::Log::clean_all($prog);

GDA::Log::disable();
print "not " if GDA::Log::is_enabled();
print "ok 3\n";

GDA::Log::enable() if ($save);
print "not " if GDA::Log::is_enabled() != $save;
print "ok 4\n";

exit 0;

