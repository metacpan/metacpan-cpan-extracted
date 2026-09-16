#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# new, prototype and set_prototype are installed into every class by
# Object::Proto::Sugar, and BUILD is the constructor hook it calls: none of the
# four is this distribution's to document. Everything else is covered, and this
# test is never skipped for convenience.
#
# Brought forward from phase 07 during phase 02. The stock Module::Starter
# version failed on Move for those four subs, and an author test that is
# expected to fail is one that hides the next real failure behind it. It has
# already earned the change once: it caught Notation's =head2 naming
# board_to_text twice, which left text_to_board undocumented.
all_pod_coverage_ok(
    { also_private => [qr/^(?:new|prototype|set_prototype|BUILD)$/] },
    'POD coverage, less what Object::Proto::Sugar installs'
);
