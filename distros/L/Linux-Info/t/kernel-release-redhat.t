use strict;
use warnings;
use Test::Most 0.38;

use Linux::Info::KernelSource;

use constant CLASS => 'Linux::Info::KernelRelease::RedHat';
plan tests => 13;

require_ok(CLASS);
can_ok( CLASS, ( 'get_revision', 'get_distro_info', ) );

my $source_dir = 't/samples/kernel/redhat';
my $source     = Linux::Info::KernelSource->new(
    {
        sys_osrelease => "$source_dir/sys_osrelease",
        version       => "$source_dir/version",
    }
);

my $instance = CLASS->new( undef, $source );
isa_ok( $instance, CLASS );

my @fixtures = (
    [ 'get_revision',       92 ],
    [ 'get_distro_info',    'el5' ],
    [ 'get_raw',            $source->get_version ],
    [ 'get_major',          2 ],
    [ 'get_minor',          6 ],
    [ 'get_patch',          18 ],
    [ 'get_compiled_by',    'brewbuilder@ls20-bc2-13.build.redhat.com' ],
    [ 'get_gcc_version',    '4.1.2' ],
    [ 'get_type',           'SMP' ],
    [ 'get_build_datetime', 'Tue Apr 29 13:16:15 EDT 2008' ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}
