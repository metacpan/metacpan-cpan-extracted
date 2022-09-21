# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

eval 'use Test::CPAN::Changes';
plan skip_all => "Test::CPAN::Changes required for testing CPAN Changes"
  if $@;

changes_ok();
