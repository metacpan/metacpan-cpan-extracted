# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

eval 'use Test::CPAN::Meta::JSON';
plan skip_all => "Test::CPAN::Meta::JSON required for testing the meta JSON"
  if $@;

meta_json_ok();
