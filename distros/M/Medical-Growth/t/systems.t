#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 9;

require Medical::Growth;

# Load here because test classes don't - tested in base.t
require Medical::Growth::Base;

ok(
    (
        grep { $_ eq 'Medical::Growth::Testme' }
          Medical::Growth->available_systems
    ) == 1,
    'Finds correct measurement system'
);

ok(
    (
        grep { $_ eq 'Medical::Growth::Skipme' }
          Medical::Growth->available_systems
    ) == 0,
    'Skips incorrect measurement system'
);

ok(
    !defined( Medical::Growth->measure_class_for( missing => 'system' ) ),
    'Empty return from measure_class_for with no system argument'
);

is(
    Medical::Growth->measure_class_for( system => 'Testme', measure => 'test' ),
    'Found me! (measure = test)',
    'measure_class_for delegation (hash) - "known" class exists'
);

is(
    Medical::Growth->measure_class_for(
        system  => 'Medical::Growth::Testme',
        measure => 'test'
    ),
    'Found me! (measure = test)',
    'measure_class_for delegation (hash) - "known" class exists (full name)'
);

is(
    Medical::Growth->measure_class_for(
        { system => 'Testme', measure => 'test' }
    ),
    'Found me! (measure = test)',
    'measure_class_for delegation (hash ref) - "known" class exists'
);

my $sts = eval { Medical::Growth->measure_class_for( system => 'Notme' ) };
my $err = $@;
ok( !defined($sts), 'measure_class_for delegation - class does not exist' );
like(
    $err,
    qr[Can't locate Medical/Growth/Notme.pm],
    'delegation error message'
);

is(
    Medical::Growth->measure_class_for( system => 'Skip::Notme' ),
    'Hiding!',
    'measure_class_for delegation - "hidden" class exists'
);
