#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('JSON::Schema::Fast') || print "Bail out!\n" }
BEGIN { use_ok('JSON::Schema::Fast::Compiled') }

is($JSON::Schema::Fast::VERSION, '0.03', 'VERSION set');

# the XS bootstrapped: compile + the debug shims are present
can_ok('JSON::Schema::Fast', qw/compile _classify _arena_selftest _prehash/);

diag("Testing JSON::Schema::Fast $JSON::Schema::Fast::VERSION, Perl $], $^X");
