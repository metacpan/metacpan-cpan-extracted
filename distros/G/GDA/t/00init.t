#!/usr/bin/perl -w
#
# 00init.t
#
# $Revision: 1.1.1.1 $
# 
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use strict;

print "1..1\n";

use GDA 'libgda-perl-test-00', $GDA::VERSION, $0;

print "not " if $@;
print "ok 1\n";

exit 0;

