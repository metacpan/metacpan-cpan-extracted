# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-11-25 22:31:26 +0000 (Mon, 25 Nov 2013) $
# Id:            $Id: 00-podcoverage.t 271 2013-11-25 22:31:26Z rmp $
# $HeadURL$
#
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok();
