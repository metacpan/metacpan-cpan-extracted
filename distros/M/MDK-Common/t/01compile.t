#!/usr/bin/perl
# $Id$

use Test::More tests => 3;

use_ok('MDK::Common');
can_ok('MDK::Common', qw(if_ member uniq));

# System
can_ok('MDK::Common::System', qw(arch fuzzy_pidofs list_home));
