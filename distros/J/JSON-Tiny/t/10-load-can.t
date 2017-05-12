#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'JSON::Tiny' or BAIL_OUT(); }

diag "Testing JSON::Tiny $JSON::Tiny::VERSION, Perl $], $^X";
can_ok 'JSON::Tiny',
  qw( decode_json encode_json false from_json j to_json true );
