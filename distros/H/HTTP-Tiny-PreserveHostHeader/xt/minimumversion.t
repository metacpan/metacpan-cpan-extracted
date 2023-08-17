#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

require Test::MinimumVersion;
plan skip_all => "Test::MinimumVersion required for testing minimum version" if $@;

Test::MinimumVersion->import;
all_minimum_version_from_metayml_ok();
