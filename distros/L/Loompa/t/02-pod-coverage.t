# Copyright (C) 2007 Randall Hansen
# This program is free software; you can redistribute it and/or modify it under the terms as Perl itself.
#!/usr/bin/perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
