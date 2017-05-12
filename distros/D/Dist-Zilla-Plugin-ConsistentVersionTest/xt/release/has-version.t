#!perl
#
# This file is part of Dist-Zilla-Plugin-ConsistentVersionTest
#
# This software is copyright (c) 2010 by Dave Rolsky.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Test::More;

eval "use Test::HasVersion";
plan skip_all => "Test::HasVersion required for testing version numbers"
  if $@;
all_pm_version_ok();
