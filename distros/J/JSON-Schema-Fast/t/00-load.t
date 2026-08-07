#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('JSON::Schema::Fast') || print "Bail out!\n" }
BEGIN { use_ok('JSON::Schema::Fast::Compiled') }

# Not pinned to a literal: XSLoader::load already refuses to bootstrap when
# $VERSION and the XS_VERSION disagree, so what is worth asserting here is that
# the two .pm files stay in step with each other.
ok(defined $JSON::Schema::Fast::VERSION && length $JSON::Schema::Fast::VERSION,
   "VERSION set ($JSON::Schema::Fast::VERSION)");
is($JSON::Schema::Fast::Compiled::VERSION, $JSON::Schema::Fast::VERSION,
   'Compiled.pm carries the same version');

# the XS bootstrapped: compile + the debug shims are present
can_ok('JSON::Schema::Fast', qw/compile _classify _arena_selftest _prehash
                                _node_align_selftest/);

diag("Testing JSON::Schema::Fast $JSON::Schema::Fast::VERSION, Perl $], $^X");
