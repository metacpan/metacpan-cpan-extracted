#!/usr/bin/perl -w
#
# 01config.t
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

use GDA 'libgda-perl-test-01', $GDA::VERSION, $0;
use GDA::Config;

print "not " if $@;
print "ok 1\n";

print GDA::Config::SECTION_DATASOURCES(), "\n";
print "ok 2\n";

print GDA::Config::SECTION_LOG(), "\n";
print "ok 3\n";

my @x = GDA::Config::list_sections('/');
printf "x: %d: %s\n", scalar(@x), join(', ', @x);
print "ok 4\n";

exit 0;

