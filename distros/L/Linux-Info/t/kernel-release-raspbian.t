use strict;
use warnings;
use Test::Most 0.38;

use Linux::Info::KernelSource;

use constant CLASS => 'Linux::Info::KernelRelease::Raspbian';

require_ok(CLASS);
can_ok( CLASS, ( 'get_binutils_version', 'get_build_number', ) );

my $source_dir = 't/samples/kernel/raspbian';
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
    [ 'get_major',            5 ],
    [ 'get_minor',            10 ],
    [ 'get_patch',            103 ],
    [ 'get_compiled_by',      'dom@buildbot' ],
    [ 'get_gcc_version',      '8.4.0' ],
    [ 'get_type',             undef ],
    [ 'get_build_datetime',   'Tue Mar 8 12:19:18 GMT 2022' ],
    [ 'get_binutils_version', '2.34' ],
    [ 'get_build_number',     1529 ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}

done_testing;
