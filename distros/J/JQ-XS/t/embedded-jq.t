#!/usr/bin/perl
#
# Checks that the jq compiled into the module is the one vendored in this
# source tree, and that it really is the new engine rather than a system libjq
# that happened to satisfy the link.
use strict;
use warnings;

use Test::More;
use JQ::XS ();

my $version = JQ::XS::jq_version();
plan skip_all => 'built against the OS libjq (JQ_SYSTEM=1)'
    unless defined $version;

# vendor/ is not installed, so this only runs from a source tree.
my ($tarball) = glob 'vendor/jq-*.tar.gz';
plan skip_all => 'not running from a source tree with vendor/'
    unless defined $tarball && -f $tarball;

plan tests => 3;

my ($vendored) = $tarball =~ m{/jq-(.+)\.tar\.gz\z};
is($version, $vendored,
   "the compiled jq ($version) is the one vendored in $tarball");

# jq preserves the literal text of a number it never does arithmetic on, from
# 1.7 onwards.  A jq 1.6 would collapse this to a double and print
# 1.0000000000000002 or similar, so it doubles as proof that the engine in use
# is the modern one and that decNumber is compiled in.
my $big = '1.0000000000000000005';
is_deeply(
    [JQ::XS->new('.a')->process_json(qq[{"a":$big}])],
    [$big],
    'number literals keep their precision (decNumber is compiled in)',
);

# The bundled oniguruma, reached through the module rather than the C API.
is_deeply(
    [JQ::XS->new('[.[] | select(test("^a"))]')->process([qw(ant bee ape)])],
    [['ant', 'ape']],
    'regex builtins work (bundled oniguruma is compiled in)',
);
