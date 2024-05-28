use strict;
use warnings;
use Test::Most 0.38;

use Linux::Info::KernelSource;

use constant CLASS => 'Linux::Info::KernelRelease::Alpine';

plan tests => 14;

require_ok(CLASS);
can_ok( CLASS, ( 'get_binutils_version', 'get_alpine_patch', 'is_lts' ) );

my $source_dir = 't/samples/kernel/alpine';
my $source     = Linux::Info::KernelSource->new(
    {
        sys_osrelease => "$source_dir/sys_osrelease",
        version       => "$source_dir/version",
    }
);

my $instance = CLASS->new( undef, $source );
isa_ok( $instance, CLASS );

my @fixtures = (
    [ 'get_raw',              $source->get_version ],
    [ 'get_major',            6 ],
    [ 'get_minor',            6 ],
    [ 'get_patch',            31 ],
    [ 'get_compiled_by',      'buildozer@build-3-19-x86_64' ],
    [ 'get_gcc_version',      '13.2.1' ],
    [ 'get_type',             'SMP PREEMPT_DYNAMIC' ],
    [ 'get_build_datetime',   'Fri, 17 May 2024 12:37:38 +0000' ],
    [ 'get_binutils_version', '2.41' ],
    [ 'get_alpine_patch',     0 ],
    [ 'is_lts',               1 ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}
