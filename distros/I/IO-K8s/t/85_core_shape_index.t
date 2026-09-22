#!/usr/bin/env perl
# k104: IO::K8s::AutoGen::CoreShapes is the precomputed form of the
# core-shape index reuse_core (D5) looks candidates up in. Building it live
# costs ~6.5s per fresh process (839 Module::Runtime loads), and reuse_core
# is default on, so every first add_crd / generate / CRD inflate paid it.
#
# A checked-in artifact derived from lib/ is only worth having while it is
# honest about lib/. This test is the mechanism that keeps it so: it scans
# live through AutoGen's own fallback path and compares the result against
# the checked-in module, so adding, removing or renaming any class under
# IO/K8s/Api or IO/K8s/Apimachinery fails here until
# maint/core-shape-index-gen.pl has been rerun.
#
# Subtest order matters. The first subtest asserts the index actually
# serves lookups WITHOUT the full scan, which is only observable while no
# full scan has happened yet -- the drift subtest below loads all 839
# classes and would make it vacuously true.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Temp;

use lib 'lib';
use IO::K8s::AutoGen;
use IO::K8s::AutoGen::CoreShapes;

sub api_classes_loaded {
    return scalar grep { m{^IO/K8s/(?:Api|Apimachinery)/} } keys %INC;
}

subtest 'lookups are served from the precomputed index, not a full scan' => sub {
    my $before = api_classes_loaded();

    my @c = IO::K8s::AutoGen::core_class_for_shape([qw( key operator values )]);
    is($c[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement',
        'preference order survives the precomputed round trip');
    is(scalar @c, 3, 'all three candidates listed');

    # Every name handed out must be a LOADED class: _core_class_for reads
    # the candidate's attribute registry, which is empty until then. This
    # is the invariant the live scan got for free by loading everything.
    ok($_->can('_k8s_attr_info'), "$_ is loaded, not just named") for @c;

    # The whole point: a lookup costs its own candidates, not the tree.
    # The full scan indexes 822 classes; anything near that here means the
    # precomputed index was bypassed.
    my $loaded = api_classes_loaded() - $before;
    cmp_ok($loaded, '<', 100,
        "only $loaded classes loaded for the lookup (a full scan is 822)");
};

subtest 'checked-in index matches the live scan' => sub {
    my $live       = IO::K8s::AutoGen::_scan_core_shapes();
    my $checked_in = IO::K8s::AutoGen::CoreShapes->shapes;

    # Report the difference as class names rather than as a 453-key struct
    # dump: the answer to "what do I do now" is which class moved.
    my @only_live    = grep { !exists $checked_in->{$_} } sort keys %$live;
    my @only_checked = grep { !exists $live->{$_} }       sort keys %$checked_in;
    my @differing    = grep {
        exists $checked_in->{$_}
            && join(',', @{ $live->{$_} }) ne join(',', @{ $checked_in->{$_} })
    } sort keys %$live;

    my $regen = 'run: perl maint/core-shape-index-gen.pl';
    is(scalar @only_live, 0, 'no shape is missing from the checked-in index')
        or diag("shapes only in lib/:\n  " . join("\n  ", @only_live) . "\n$regen");
    is(scalar @only_checked, 0, 'no shape lingers in the checked-in index')
        or diag("shapes only in the checked-in index:\n  " . join("\n  ", @only_checked) . "\n$regen");
    is(scalar @differing, 0, 'no shape lists different classes')
        or diag(join("\n", map {
                "  $_\n    lib/:       " . join(', ', @{ $live->{$_} })
              . "\n    checked-in: " . join(', ', @{ $checked_in->{$_} })
            } @differing) . "\n$regen");

    # Belt and braces: the three checks above are readable, cmp_deeply is
    # exhaustive. Order inside each list is part of the comparison -- it is
    # the preference order the reuse decision picks its winner by.
    cmp_deeply($checked_in, $live, "index is exactly the live scan ($regen if not)");
};

subtest 'the artifact carries the distribution version' => sub {
    # Every module here needs its own $VERSION for PAUSE indexing, and a
    # generated one is the easy one to forget. The generator reads
    # AutoGen's, so a mismatch means the file was hand-edited or the
    # release bump missed it.
    is($IO::K8s::AutoGen::CoreShapes::VERSION, $IO::K8s::AutoGen::VERSION,
        'CoreShapes $VERSION matches AutoGen $VERSION');
};

subtest 'an unloadable artifact falls back to the live scan' => sub {
    # The fallback is what makes a missing or broken artifact a slow start
    # rather than a broken reuse_core. It needs a process that has not
    # indexed yet (_index_core_shapes memoizes for the life of the
    # process), so this runs out of line -- with _scan_core_shapes stubbed,
    # because what is under test here is the wiring, not the scan, which
    # the drift subtest above already ran for real.
    my $probe = <<'PROBE';
use strict; use warnings;
use IO::K8s::AutoGen;
$IO::K8s::AutoGen::CORE_SHAPE_INDEX = 'IO::K8s::AutoGen::CoreShapes::NoSuchThing';
{
    no warnings 'redefine';
    *IO::K8s::AutoGen::_scan_core_shapes = sub { { 'a,b' => [ 'IO::K8s::Api::Core::V1::Pod' ] } };
}
print join ',', IO::K8s::AutoGen::core_class_for_shape([qw( a b )]);
PROBE
    my $fh = File::Temp->new(SUFFIX => '.pl');
    print $fh $probe;
    close $fh;
    my $out = qx{"$^X" -Ilib "$fh" 2>&1};
    is($?, 0, 'fallback probe exits clean') or diag($out);
    is($out, 'IO::K8s::Api::Core::V1::Pod',
        'a shape the artifact cannot supply is served by the live scan');
};

done_testing;
