################################################################################
#
#  $Revision: 3 $
#  $Author: mhx $
#  $Date: 2008/04/20 17:31:39 +0200 $
#
################################################################################
# 
# Copyright (c) 2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use strict;
use Test::More;

my @modules = qw(
  MP4::File
);

eval 'use Pod::Coverage 0.10';
plan skip_all => "testing pod coverage requires Pod::Coverage 0.10" if $@;

eval 'use Test::Pod::Coverage 1.08';
plan skip_all => "testing pod coverage requires Test::Pod::Coverage 1.08" if $@;

plan tests => scalar @modules;

for my $mod (@modules) {
  pod_coverage_ok($mod, "$mod is covered");
}
