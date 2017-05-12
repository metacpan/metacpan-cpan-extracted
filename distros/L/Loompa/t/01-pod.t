# Copyright (C) 2007 Randall Hansen
# This program is free software; you can redistribute it and/or modify it under the terms as Perl itself.
#!/usr/bin/perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
