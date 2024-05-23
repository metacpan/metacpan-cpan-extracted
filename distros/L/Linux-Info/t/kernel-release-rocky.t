use strict;
use warnings;
use Test::Most 0.38;

use Linux::Info::KernelSource;

use constant CLASS => 'Linux::Info::KernelRelease::Rocky';

plan tests => 14;

require_ok(CLASS);
can_ok( CLASS, ( 'get_revision', 'get_distro_info', 'get_architecture' ) );

my $source_dir = 't/samples/kernel/rocky';
my $source     = Linux::Info::KernelSource->new(
    {
        sys_osrelease => "$source_dir/sys_osrelease",
        version       => "$source_dir/version",
    }
);

my $instance = CLASS->new( undef, $source );
isa_ok( $instance, CLASS );

my @fixtures = (
    [ 'get_revision',     '513.5.1' ],
    [ 'get_distro_info',  'el8_9' ],
    [ 'get_architecture', 'x86_64' ],
    [ 'get_raw',          $source->get_version ],
    [ 'get_major',        4 ],
    [ 'get_minor',        18 ],
    [ 'get_patch',        0 ],
    [
        'get_compiled_by',
        'mockbuild@iad1-prod-build001.bld.equ.rockylinux.org'
    ],
    [ 'get_gcc_version',    '8.5.0' ],
    [ 'get_type',           'SMP' ],
    [ 'get_build_datetime', 'Fri Nov 17 03:31:10 UTC 2023' ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}
