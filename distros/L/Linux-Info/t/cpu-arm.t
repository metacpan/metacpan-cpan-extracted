use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::Arm';

require_ok($class);
can_ok(
    $class,
    (
        'get_variant',  'get_part', 'get_revision', 'get_model_name',
        'get_hardware', 'get_serial',
    )
);

my $source_file = 't/samples/cpu/info6';
note("Testing with $source_file");
my $instance = $class->new($source_file);
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_variant',      '0x3' ],
    [ 'get_part',         '0xd0c' ],
    [ 'get_cpu_revision', '1' ],
    [ 'get_revision',     undef ],
    [ 'get_model',        'ARM 0x3 0xd0c 1' ],
    [ 'get_arch',         64 ],
    [ 'get_bogomips',     50.0 ],
    [ 'get_source_file',  $source_file ],
    [ 'get_model_name',   undef ],
    [ 'get_hardware',     undef ],
    [ 'get_revision',     undef ],
    [ 'get_serial',       undef ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

$source_file = 't/samples/cpu/info9';
note("Testing with $source_file");
my $other = $class->new($source_file);
isa_ok( $other, $class );

@fixtures = (
    [ 'get_variant',      '0x0' ],
    [ 'get_part',         '0xb76' ],
    [ 'get_cpu_revision', 7 ],
    [ 'get_revision',     '000d' ],
    [ 'get_model',        'Raspberry Pi Model B Rev 2' ],
    [ 'get_arch',         32 ],
    [ 'get_bogomips',     697.95 ],
    [ 'get_source_file',  $source_file ],
    [ 'get_model_name',   'ARMv6-compatible processor rev 7 (v6l)' ],
    [ 'get_hardware',     'BCM2835' ],
    [ 'get_revision',     '000d' ],
    [ 'get_serial',       '00000000a5126eb6' ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $other->$method, $fixture_ref->[1], "$method works" );
}

done_testing;
