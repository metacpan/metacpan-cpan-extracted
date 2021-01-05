package # hide from PAUSE indexer / CPAN indexing
    test_setup;

# We haven't set our Import::Base package variables yet
# so we load these pragmas manually because they're
# lexically scoped and should happen prior to
# compilation for proper effect.
use utf8;
use strict;
use warnings;
no indirect "fatal";

our $VERSION = v0.0.1;

use Test::More (); # To use the local $Test::Builder::Level cheat

require Import::Base;
our @ISA = "Import::Base";

my   @pragmata = qw< utf8 strict warnings >; push @pragmata, (
      charnames => [ qw<:full :short latin greek> ],    # \N{EN DASH}, \N{Omega}
      feature   => [ qw<say> ],                         # but not switch, which is deprecated
     -feature   => [ qw<switch> ],                      # smartmatch is a bug, not a feature
     -indirect  => [ qw<fatal> ],                       # forbid "indirect object" syntqctic ambiguity
);                                           push @pragmata,
      feature  => [qw<unicode_strings>]                   if $^V >= v5.11.3;

# So the cpanfile verification tools notice these,
# even though the compiler (mostly) does not.
if (0) {
    require feature;
    require Devel::WatchVars;
    require Test::Warn;
    require Test2::V0;
}

my @modules = (
    "Capture::Tiny" => [qw(:all)],
    qw(
              Devel::WatchVars
        Test::Devel::WatchVars
        Test::Warn
        Test2::V0
    ),
);

# This global variable is used by the import() method
# we inherited from our parent, Import::Base.
our @IMPORT_MODULES = (@pragmata, @modules);

1;
