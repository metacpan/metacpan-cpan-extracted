use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::Arm';

require_ok($class);
can_ok( $class, qw(get_variant get_part get_revision) );

my $source_file = 't/samples/cpu/info6';

my $instance = $class->new($source_file);
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_variant',     '0x3' ],
    [ 'get_part',        '0xd0c' ],
    [ 'get_revision',    '1' ],
    [ 'get_model',       'ARM 0x3 0xd0c 1' ],
    [ 'get_arch',        64 ],
    [ 'get_bogomips',    50.0 ],
    [ 'get_source_file', $source_file ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

done_testing;
