#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'tests' => 2 + 4;
use Lib::CPUInfo qw<
    initialize
    deinitialize

    get_current_uarch_index
    get_current_core
    get_current_processor
>;

can_ok(
    main::,
    qw<
        initialize
        deinitialize
        get_current_uarch_index
        get_current_core
        get_current_processor
    >,
);

ok( initialize(), 'Successfully initialized with initialize()' );

my $index = get_current_uarch_index();
like(
    $index,
    qr/^[0-9]+$/xms,
    "get_current_uarch_index() ($index)",
);

my $core = get_current_core();
isa_ok( $core, 'Lib::CPUInfo::Core' );
my $processor_count = $core->processor_count();
like(
    $processor_count,
    qr/^[0-9]+$/xms,
    "get_current_core()->processor_count() ($processor_count)",
);

my $processor = get_current_processor();
isa_ok( $processor, 'Lib::CPUInfo::Processor' );;

deinitialize();

1;
